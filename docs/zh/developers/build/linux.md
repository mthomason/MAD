---
layout: default
title: "在 Linux 上构建引擎"
description: "Docker 构建、十二个无头框架及其测试套件。"
lang: zh-CN
---

# 在 Linux 上编译 MAD 引擎——技术评估

本页记录 Linux 构建：Docker 镜像、锁定版本的工具链、十二个无头框架，以及它们运行的套件。`Linux/README.md` 有日常命令。

*撰写于原定日期；当前状态事实已于 2026-11-22 核实。*

撰写于 2026-10-04，针对 `c807eeb4d` 处的 `master`。本文档所依据的依赖审计（§4）和
生态研究（§5-6）都在同一天产出：
审计通过 grep 每个框架的源码目录完成，研究来自原始
来源（发行说明、包仓库、项目邮件列表）。证据薄弱之处会
明说。本文档是 `MAD_FUTURE.md`
§5.1 的技术伴侣，后者勾画了平台矩阵；这里是深入篇。

---

## 1. 问题，已回答

这能在 Linux 上编译吗？**能，但有条件——两个意义上的条件。**

- 必须编译的代码——无头引擎——按测量已
  几乎不依赖 Apple。剩余的两项（Core Data 和
  UIKit/CoreGraphics）要么正在迁移，要么逐文件枚举，且
  都不在刷新路径上。
- 必须承载它的生态——Linux 上的 Objective-C 加 Foundation——存在，
  在每个主要发行版中打包，且今天运行着一个生产级群件服务器
  （SOGo，Debian 打包，针对 GNUstep Base 1.31.1）。它是小众的，其
  现代 API 覆盖率在边缘处未经核实，其 UIKit 故事并不
  存在——但本代码库在 Linux 上不需要 UIKit。它需要引擎。

两个星号：**GNUstep 的 Foundation 存在但未经核实**，针对本代码最重度依赖的
确切 API（`NSPredicate`/`NSExpression`、键值归档、
`NSURLSession`），且**Linux 上没有现实的 UIKit**——这没关系，
因为审计表明代码已把 UIKit 限制在具名文件中，而
渲染计划反正要离开 UIKit。

---

## 2. 两产品问题：重写，还是编译并调用

用户提出的选择：用 Python 重写一切并维护两个产品，
还是编译一次并让 Python 调用引擎。审计解决了它。

**引擎很大。** 无头框架集——`MADFoundation`（65 个 h+m 文件）、
`MADCocoaExtensions`（44）、`MADDataStructures`（36）、`MADFileManager`（30）、`MADAPI`
（33）、`MAD`（403）、`MADSqlite3`（64）、`MADMySQL`（41）、`MADTds`（3）、`MADTdsClient`
（8）——约 727 个文件。Python 重写重复的不只是体量，还有
*由测试锁定且来之不易的行为*：SQL 生成器、
`MADDataTableFast` 摄入路径（200,000 行用时 1.16 秒，已基准测试）、驱动的
类型映射（SQL Server 的现代日期/时间处理之所以存在，只因实时测试
两次捕获了它）、空哨兵家族、存储读取器。这样的两份实现
会漂移；套件只锁定一份。那不是“两个产品”，而是一个产品
和一个负债。

**集成面已存在。** CLI *就是*契约：`mad inspect` → 元数据、`mad query` → SQL、`mad refresh` → 行、`mad export` → 格式，且
退出码区分坏文档（2）、不可达服务器（3）和失败
查询（4）。Python 服务以子进程调用它、带 `--format json`，就得到
报表。子进程开销在刷新时间尺度上无关紧要（样本
刷新 0.02-1.2 秒；进程启动约 10 毫秒）。若曾测量到进程内嵌入确实重要，
同一份源码可以为 ctypes/CFFI 构建一个小的 C ABI 库——但那是可选的，而非前提
条件。

**关于偏好 Python 的既定理由——驱动接入。** Python 的
连接器生态确实广，一次 `pip install` 就能到达本项目
没有驱动的数据库。但对今天存在的来源，接入已经
语言中立：MAD 驱动位于 freetds 和 MariaDB Connector/C 之上——Python 或 C 程序
同样会链接的 C 库——且两者在 Linux 上原生构建（§7）。
编译引擎把这一接入不变地移到 Linux。Python 真正
有优势之处是*新*来源类型（Postgres、BigQuery、REST），那里的正确
答案是项目已承诺的扩展接缝：一个返回架构和行的 `MADDatabase`
子类。说 HTTP 的驱动在 Objective-C 和 Python 中行为
相同；Python 买到更多预写连接器，而非更简单的核心。

**诚实的权衡，直白地说：** 这是在维护*两份
实现*（Python + Objective-C）、有永久漂移风险，与维护
*一份在小众工具链上的实现*（clang + libobjc2 + GNUstep）、有
生态风险之间选择。本文档推荐后者，并给出可测量的触发点
以重新审视：§9 命名了检查点。使建议具有约束力的一件事是 **JSON 导出形态**——Python 契约只与其
架构一样好，而定义它是 §10 中的决策 1。

而且若真有重写，正确的语言是 Linux 上的 Swift——而非 Python
——因为可移植 SQLite 存储（Phase C 工作）已是语言中立的
契约：无论哪一侧写存储，另一侧都能读。

---

## 3. 什么必须编译，什么绝不能

| 框架 | 无头所需 | 为何 / 为何不 |
|---|---|---|
| `MADFoundation` | 是 | 基础：操作、URL 工厂、钥匙串（可排除）、日志 |
| `MADCocoaExtensions` | 是 | 各处使用的辅助（11 个 UIKit 文件，但可排除） |
| `MADDataStructures` | 是 | 0 个 Apple 导入；3 个 C++ 文件（需要 libc++） |
| `MADFileManager` | 是 | 0 个 Apple 导入；云协调器排除（iCloud 反正会在 Phase D 删除） |
| `MADAPI` | 是 | 连接层；3 个 UIKit 文件是视图控制器，非无头 |
| `MAD` | 是 | 困难的那个：403 个文件中 29 个 UIKit、34 个 CoreData、15 个 CoreGraphics |
| `MADSqlite3` | 是 | 0 个 Apple 导入；`MADArrayCaching`（`.madac` 存储）100% 干净 |
| `MADMySQL` | 是 | 0 个 Apple 导入 |
| `MADTds` / `MADTdsClient` | 是 | 0 个 Apple 导入 |
| `MADExplorer` | 否 | 文件浏览器 UI（32 个文件中 19 个导入 UIKit） |
| `MADBarcodes` | 是 | 编码 + PNG 核心可移植（zint + libpng）；只有 `MADBarcodeView` 和 `MADBarcodeCache` 留在 Apple 侧 |
| `MADFeedback` | 否 | 未使用且未维护 |
| `Scrimpter` | 否 | 0 个 Apple 导入，但未使用 |
| `MADDesigner`（应用） | 否 | 302 个 UIKit 文件；UI 留在 Apple 平台 |

依赖方向：一切位于 `MADFoundation` 之上；驱动在 `MAD` 中子类化
`MADDatabase`，而 `MAD` 的 `Constructor` 文件导入驱动——即
已知的循环（`ROADMAP.md` §3.4）。驱动注册表（`ROADMAP.md` §5.1）对
Linux 有两重意义：它打破该循环，且它让 Linux 构建能把
驱动作为插件链接，而非硬导入的一堆。

---

## 4. 实测审计

按框架源码目录统计导入每个 Apple 框架的文件（一个文件
导入多个 UIKit 头文件只计一次）：

| 框架 | 总计 | UIKit | CoreData | CoreGraphics | Security | os/log | CoreFoundation | dispatch |
|---|---|---|---|---|---|---|---|---|
| MADFoundation | 65 | 4 | 0 | 0 | 1 | 9 | 3 | 1 |
| MADCocoaExtensions | 44 | 11 | 0 | 3 | 0 | 1 | 0 | 0 |
| MADDataStructures | 36 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| MADFileManager | 30 | 0 | 0 | 0 | 0 | 2 | 0 | 5 |
| MADAPI | 33 | 3 | 0 | 0 | 0 | 4 | 0 | 2 |
| MAD | 403 | 29 | 34 | 15 | 1 | 15 | ~19 | 3 |
| MADSqlite3 | 64 | 0 | 0 | 0 | 0 | 4 | 3 | 5 |
| MADMySQL | 41 | 0 | 0 | 0 | 0 | 2 | 0 | 1 |
| MADTds | 3 | 0 | 0 | 0 | 0 | 1 | 0 | 0 |
| MADTdsClient | 8 | 0 | 0 | 0 | 0 | 0 | 0 | 3 |

支柱之外的长尾，每项都有处置：

| 项目 | 位置 | 处置 |
|---|---|---|
| `os_log`（一切都汇入 `madlog.h`，两份副本） | 9+15+4+2+… 个文件导入该 shim | 针对 syslog/printf 重写一个约 20 行的头文件；其他调用点不变 |
| `asl.h`（已弃用的 Apple System Log） | `MADocument.m:107`、`RptqDocumentElement+Extras.m:60` | 换成 madlog shim |
| `copyfile.h` | `MADArchiveManager.m:14`、`madtar.m:18` | POSIX rename/link |
| `mach/machine/vm_param.h`（页面大小） | `MADocument.m:108` | `getpagesize()` |
| `CFNetwork`/`CFHost` 反向 DNS | `BDHost.m`（1 个文件） | `getaddrinfo` |
| `NSMetadataQuery` 云协调器 | `MADFileManager`（3 个文件） | 排除——iCloud 在 Phase D 删除 |
| `Security.framework` / `SecItem` | `MADKeyChain.m`、`MADOperationKeyChainGet.m` + 测试 | 排除——刷新路径从操作依赖取得凭据，从不使用钥匙串；CLI 已用 `--credentials` 替代 |
| `MADApplication.m` 中的 `AppKit` 守卫 | 1 个文件 | 添加 `TARGET_OS_LINUX` 分支 |
| `MADURLFactory.m:32` 中的 `UIScreen` 缩放 | 1 行 | 返回 2.0 |
| `MADOperation.m:549-563` 中的 `UIApplication` 后台任务 | 1 个受保护功能 | `#if` 掉 |
| CoreFoundation（`CFNumber`/`CFData`/`CFString`、toll-free bridging） | MAD、MADFoundation、MADSqlite3 中约 25 处 | GNUstep 等价物 / 机械重写；CoreBase（GNUstep 的 CF 克隆）不成熟，不要依赖它 |
| UIKit 值转换器（`MADColorTransformer`、`MADLocaleTransformer`、`MADPngImageTransformer`） | 3 个文件，目前被拖过 CLI 的目标边界 | **随 Phase D 消亡**——存储迁移把可转换对象转为可移植标量 |

SystemConfiguration：零出现。CommonCrypto：框架中为零（仅应用、
收据验证）。`@import`：零——一切都是 `#import`，这正是
GNUstep 所需的。

---

## 5. 三大支柱

### 5.1 Core Data——进行中的迁移就是杠杆

34 个 MAD 文件导入 Core Data；`MADocument` 是 `UIManagedDocument`；存储是
编译后的 `MAD.momd`；`MADAtomicStore` 位于其下。这些在 Linux 上都不存在，
也都不需要——因为项目已在替换它：`MAD_STORE_MIGRATION.md`
Phase C 于 2026-10-03 落地，且 `RptqStoreContext.h` 声明“Nothing here imports
Core Data.” Phase D 删除 `UIManagedDocument`、值转换器、
`.xcdatamodel` 和 iCloud 机制——这同时消掉几个 §4
项目（值转换器、云协调器、CLI 目前从应用包复制出的 `MAD.momd`）。

**完成 Phase C 和 D 是迈向 Linux 的单项最高杠杆步骤**，且它是项目
已为可移植性而拥有的工作，而非 Linux 专属努力。迁移计划的一处注释：iCloud 时代的旧文档由用户通过 iOS Files 应用获取并在打开时转换
（`MADStoreConverter`）——获取它们不需要 iCloud 机制，因此
Phase D 对它的删除不会搁浅任何东西。

### 5.2 UIKit / CoreGraphics——29 个文件，多数微不足道

29 个 MAD UIKit 文件分解为：

| 种类 | 数量 | 处置 |
|---|---|---|
| `CGGeometry` 结构体（`CGRect`/`CGSize`/`CGPoint`） | 15 个文件 | 普通结构体——复制定义；零绘制 |
| 格式化器中的 `UIEdgeInsets` | 约 3 个文件 | 换成结构体运算 |
| 模型/布局代码中的 `UIFont`/`UIColor`/`UIImage` | 若干 | 用于度量和存储样式的轻量等价物 |
| `UIActivityItemProvider` / 分享面板 | 2 个文件 | 非无头——排除 |
| `UIScreen`/`UIApplication` | 2 个文件 | 单行改动，§4 |
| `MADPrintPageRenderer` + `UIGraphics` PDF 上下文 | 导出接缝 | **真正的工作**——见下 |
| `MADocument` 的 `UIManagedDocument` 基类 | 文档类 | 随 Phase D 消亡 |

值得注意的好消息：`MADReportFormatter.m` 的 UIKit 使用实际上已残留
（一个 `UIEdgeInsetsMake`、一个未使用的 `UIPrintInteractionController` 导入），且
`MADArrayCaching`——`.madac` 渲染页存储——已达 100% 无 UIKit/CoreData。
它今天能在任何 ObjC Foundation 上编译。

**渲染器决策。** CoreGraphics PDF 上下文没有 Linux 等价物。成本最低的
分阶段：数据路径动词先通过；接下来 `export --format json` /
`--format csv`（纯 Foundation——而这些正是 Python 调用方
想要的格式）；然后是 HTML/SVG 页面（无原生依赖）；PDF 最后，把 cairo 或 libharu 写出器放在同一个 `MADPrintPageRenderer` 绘制循环之后，或把 PDF 渲染留在 macOS 工作进程上，而 Linux 提供数据和页面。
CLI 已字节补丁进 PDF 的 `--deterministic` 标志是跨平台渲染器测试的种子。

### 5.3 GNUstep 上的 Foundation——存在，部分已验证，边缘有风险

研究从原始来源核实的内容：

- **GNUstep Base 1.31.1**（2025-02-28）是当前版本；master 活跃（值得注意的
  NSURLSession 工作于 2026-08 合并）。发布节奏慢——约每年一次。
- 存在且可用：`NSJSONSerialization`、`NSUUID`、`NSRegularExpression`
  （ICU）、`NSISO8601DateFormatter`、`NSDateFormatter`（ICU 支撑——`libicu-dev` 是
  必需构建依赖）、`NSOperationQueue`、属性列表、`NSXML*`
  （libxml2）、旨在与 Apple XML 兼容的键值归档。
- **`NSURLSession` 是弱点**：1.31.0 作为“新的实验性
  实现”发布，明确不是受支持的类；2026 年的去 block 工作
  （无 block 构建）已合并但稳定化未完成。不要在它之上构建
  Linux 产品——优先直接驱动连接（刷新反正做的就是这件事）或 libcurl。
- **`libdispatch` 按 GNUstep 自己的政策是可选的**——基础维护者称其
  “not in a state where it's portable/reliable enough”以依赖。本
  代码库广泛使用 dispatch（`dispatch_once`、`dispatch_sync`、信号量）。
  swift-corelibs-libdispatch 是 C，可从 ObjC 调用（带
  `OS_OBJECT_HAVE_OBJC_SUPPORT=1`），且此处用到的*核心*是稳定部分——
  但应把 dispatch 视为可 shim 的层，而非既定。
- **CoreBase**（GNUstep 的 CoreFoundation 克隆）不成熟——构建指南说
  不要依赖它。约 25 处 CF 站点改为 GNUstep 等价物。
- **边缘未核实，且此处关键承载：** `NSPredicate`/`NSExpression`
  （MAD 中 13+ 个导入点）、`unarchivedObjectOfClass:`（iOS 11+ API——GNUstep
  覆盖不一）、`NSOperation`+KVO 行为。存在性有证明；行为
  对等没有。这是诚实的风险，也正是 §8 的 fixture
  存在的意义。

**存在性证明：** SOGo，一个 Objective-C 群件服务器，在 Debian
sid 中发布，硬依赖 `gnustep-base-runtime (>= 1.31.1)`——GNUstep Foundation
作为生产守护进程大规模运行。Darling 驱动 libobjc2。Linux 上的非 GUI ObjC
工具是常态，而非异类。

---

## 6. 工具链与生态

- **运行时：libobjc2 2.3**（2025-09-16）——在 Linux 上获得现代 Objective-C
  的唯一方式。ARC、blocks、弱引用、`@synchronized`、非脆弱 ivar、
  gnustep-2.0 ABI。**ARC 需要 clang + libobjc2**，而主流发行版的包
  在无 ARC 下针对 GCC 运行时构建 GNUstep——因此构建
  环境从源码组装（或 Fedora 的 libobjc2 打包），而非 Debian 默认。
  这是真实的运营承诺。
- **Blocks**：libobjc2 2.3 可消费 swift-corelibs-libdispatch 的 BlocksRuntime；
  `libblocksruntime-dev` 也有打包。代码的 blocks 是标准的。
- **异常**：clang + libobjc2 给出基于原生 unwinder 的异常；GNUstep 的
  两套异常机制不得在同一可执行文件中混用——用原生路径构建一切。
- **无 clang modules / `@import` 支持**——且代码库已在各处使用 `#import`，
  因此这毫无代价。
- **Linux 上的 UIKit：确认不存在。** 用户对微软的记忆是 WinObjC——
  Windows Bridge for iOS，一个刻意局部的 UIKit 子集在 Windows 上，最后
  推进于 2022，2025-05-28 归档。Chameleon（macOS 上的 UIKit）2015 年消亡。
  `gnustep/libs-uikit`（2026 年 6 月）是 26 次提交、一个 star 的实验。从
  连微软都放弃这想法中该吸取的教训：**不要移植 UIKit。**
  审计表明本项目为何不必如此——UIKit 已被限制在
  具名文件中，且一切无头的东西都通过数据渲染，而非视图。
- **测试：Linux 上没有 ObjC 的 XCTest**（swift-corelibs-xctest 仅 Swift）。
  GNUstep 自己的 `gnustep-tests` + `Testing.h` 是零依赖单元运行器；
  UnitKit 已归档。真正的验收层是 §8 的 fixture，而非单元测试。
- **加密与秘密**：无 CommonCrypto 移植（GNUstep 项目自己的建议是
  `#ifdef` 到 OpenSSL 或 GnuTLS）；无钥匙串（功能类似物是
  libsecret/Secret Service，或用于会话秘密的 keyutils）——且按 §4
  无头引擎两者都不需要。

---

## 7. C 库——容易的部分，有一个许可证阻塞项

每个 vendored 库都是可移植 C，带上游 autoconf/cmake 构建：

| 库 | 版本 | 许可证 | Linux 构建 |
|---|---|---|---|
| sqlite3 | 3.53.3 | public domain | 原生；格式锁定标志已在 `Compressor/sqlite3.xcconfig` 中 |
| zlib | 1.3.2 | Zlib | 原生 |
| openssl | 3.5.9 | Apache-2.0 | 原生 |
| bzip2 | 1.0.8 | BSD-like | 原生 |
| libpng | 1.6.59 | PNG Reference v2 | 原生 |
| libarchive | 3.8.9 | BSD-2 | 原生 |
| freetds | 1.4.27 | LGPL-2.0+ | 原生（配方有一个 BSD `sed -i ''` 小问题要修） |
| mysqlclient | 8.4.10 | **GPL-2.0 + FOSS exception** | 原生——**但 GPL 对专有二进制是发布阻塞项**；MariaDB Connector/C（LGPL-2.1）是 `LICENSE_COMPLIANCE_PLAN.md` 中已命名的替代品 |
| zint | 2.16.0 | BSD-3 | 原生；MADBarcodes 的 PNG 核心所链接的条形码后端（连同上面的 libpng） |

加上树内 C（`miniz`、`madmath`、`madpng`、`madtar`、`madlib`——全部可移植，
全部宽松许可）。只有 Compressor 的*打包*层是 Apple 特有的
（`xcrun`、`-isysroot`、`lipo`、`xcodebuild -create-xcframework`）；Linux 驱动
丢掉全部这些，原生运行同样的上游构建，并以普通
`ar` + include 安装收尾。iOS 特有的复杂性（mysqlclient 的两阶段
宿主工具构建、freetds 的按平台生成头文件）在原生
构建上*消失*。审计中的一个标志：Karl Kraft MySQL 连接器无许可证——
随 MariaDB 迁移替换它，不要发布它。

---

## 8. 构建与测试计划

- **构建系统**：为十二个无头框架加 CLI 使用 CMake——一套标志
  （`clang`、`-fobjc-arc`、`-fblocks`、GNUstep 的 `gnustep-config --objc-flags`）。
  `CLI/build.sh` 中复制 `.momd` 的舞步随 Phase D 消失，且
  `REFRESH_SOURCES` 跨目标边界的触达随 `MADOperationRefresh` 的迁移消失（`ROADMAP.md` §3.4）。
- **验收层**：`MAD_CLI.md` §6 的往返 fixture，在 Linux 上运行
  并与 macOS/模拟器运行做字节比较——容器保真、v0
  可读性、无缓存往返、退出码。行缓存和 JSON/CSV 输出
  可字节比较；在一个渲染器存在之前，PDF 仅结构可比。这些 fixture 也是 *GNUstep Foundation 的覆盖测试*：尽早运行
  它们、分类每个失败，§5.3 的未知就会凭经验解决
  而非靠阅读 API 索引。
- **CI**：测试矩阵中的 Linux 作业运行 fixture；套件仍是
  今天的模拟器套件。

### 8.1 部署路径：容器，而非交叉编译

这实际上如何构建和发布？

- **不要从 macOS 交叉编译。** Objective-C 运行时加 GNUstep Base 是
  宿主耦合的——从 Mac 针对 Linux sysroot 交叉编译它是研究
  项目，而非构建步骤。iOS 应用仍由 Mac 上的 Xcode 构建；Linux
  引擎*在 Linux 上构建*。
- **Docker 是构建环境。** 一个 Dockerfile，两个阶段：一个从源码构建 clang + libobjc2 2.3 + GNUstep Base（ARC 所需——§6）的工具链阶段，以及
  一个运行 Compressor Linux 驱动以构建 C 库（§7）、然后用
  CMake 构建十二个框架和 CLI 的构建阶段。同一镜像兼作 CI
  环境和部署产物。
- **支持哪个 Linux：一条基线，在容器中。** 选择单一基线——
  Debian stable 或 Ubuntu LTS——并在那里构建，因为真正的兼容性
  约束是 glibc：所有链接之物都从源码构建，唯独 libc 不是，因此
  “受支持的 Linux”意味着“我们所发布镜像的 glibc”。在你接受的最旧
  glibc 上构建是规则。发布容器意味着任何支持 Docker 的宿主
  都能运行产品，无需发行版矩阵。
- **工作流是你已习惯的脚本加编译，自动化。** Linux 构建器上的
  `git clone` → Compressor 配方从源码构建 sqlite、zlib、openssl、
  bzip2、libpng、libarchive、freetds 和 MariaDB → CMake 用一套标志编译
  框架 → 链接 `mad` → 运行往返 fixture（上述）→
  给镜像打标签。GitHub Actions ubuntu 运行器是这一切在每个提交上发生的标准场所。
- **macOS 的角色。** Mac 仍是应用、模拟器
  CLI 和参考 fixture 输出的开发宿主。两个平台由 git 和
  fixture 的字节比较连接——Linux 构建被*对照* Mac 的
  输出检查，这是使可移植性保证可执行。

---

## 9. 工作量与分阶段

桶，按应采取的次序：

| 阶段 | 工作 | 性质 |
|---|---|---|
| A | 完成存储迁移的 Phase C + D | 已拥有的可移植性工作；移除 Core Data、iCloud、值转换器、`.momd`——最大的 Linux 杠杆 |
| B | 工具链试验：一个从源码构建 clang + libobjc2 + GNUstep Base 的 Dockerfile；编译一个 MADFoundation 子集 | 证明环境并成为构建/CI 镜像；数天 |
| C | §4 shim 列表 | 有界且已枚举——madlog、asl、copyfile、vm_param、CFHost、MADApplication、UIScreen、后台任务、约 25 处 CF 站点、排除 |
| D | **检查点**：数据路径动词在 Linux 上通过——`inspect`、`schema`、`query`、`refresh` 针对两个样本，fixture 字节比较 | 若在 C 之后这不通过，GNUstep Foundation 的长尾比估计的大，*那*才是重新审视重写问题的时刻——不是之前 |
| E | 导出：JSON/CSV（Python 契约），然后 HTML/SVG 页面，然后 PDF 决策（cairo/libharu vs macOS 侧渲染） | 先纯 Foundation；渲染器最后 |
| F | Compressor Linux 驱动（原生构建、矩阵列、MariaDB 替换、freetds sed 修复）+ CMake 打磨 + CI 行 + 可部署镜像 | 机械，受许可证门控 |

排序理由：A 是已拥有的工作，B 便宜且为一切降风险，C 可枚举，
D 是诚实的 go/no-go。E 或 F 中没有东西是*回答*问题所需；
它们只在*发布*时需要。

**Phase A 状态（2026-10-06）。** Core Data 已出 MAD 框架：`MADocument` 是
`UIDocument`，遗留转换器和编译模型位于应用目标中、
在 `MADLegacyStoreConversion` 之后，转换后的文档会清理其 Core Data 文件，且
框架/MADDesigner 清扫移除了剩余的导入、类型和死代码。值
转换器、浏览器的云窗格和 iCloud entitlement 按用户
决定保留——它们在应用侧，因此不阻塞无头构建；文件管理器的
云代码留在原处，未使用（用户称：无头模式不需要）。B 之前剩下的
是工具链试验证明必要的 §4 文件级排除。

**Phase B 状态（2026-10-06）。** 工具链试验在
`linux-port` 分支上通过，2026-10-16 合并到 `master`（`524e0d86e`）：
`Linux/` 构建一个 Docker 镜像——Ubuntu 24.04 加发行版
clang 18（§6 的“从源码”要求是关于 GNUstep 针对
libobjc2 构建，而非关于 LLVM），加上从源码构建的 libobjc2 2.3、libdispatch 6.1.3、
gnustep-make 2.9.3 和 gnustep-base 1.31.1，锁定在 `Linux/toolchain.conf`——
针对 GNUstep 编译 MADFoundation 27 个实现文件中的 23 个和 `madlib.c`，
并在其中运行 15 个测试可执行文件（14 个移植套件和一个工具链探针）：全部通过，带 5 个已记录需求和 10 个探针报告项。
`./Linux/build.sh` 是入口点；iOS 套件保持通过（118 个测试），作为
证明这项工作所需的六个小型平台守卫在 Apple 上行为中立的证据。

探针为引擎实际使用的 Foundation 退役了 §5.3 风险列表的大部分：
ARC 和弱归零、blocks、异常、`@synchronized`、KVO（手动和
依赖键）、`NSOperation` 状态机 KVO、`NSPredicate
predicateWithFormat:@"error != nil"`（MAD 的确切谓词）、dispatch 包括
普通可执行文件下主队列排空、JSON、日期、plist、排序
描述符、流以及宽松路径上的键值归档全部通过。两个缺口
被记录而非隐藏：GNUstep 的归档器没有安全编码支持
（`requiringSecureCoding:YES` 返回 nil；宽松路径往返），且
GNUstep 的 `NSOperationQueue` 在每次通知时移除其 `isReady` 观察，
而 MADOperation 的状态机过去在每次入队时多次通知 `isReady`——第二次移除会抛异常，因此 MADOperation 无法
在 Linux 上入队。这已解决（2026-10-06，`linux-port`，现已在 `master`）：
MADOperation 从 `-willEnqueue` 显式驱动状态推进，且只在真实值变化时发送
`isReady`/`isExecuting`/`isFinished` 的 KVO，使队列
像 Apple 上一样只看到一次通知；Linux 测试在两个平台上直白断言它，
需求降至 3。该机制连同排除的文件和更小的 shim
写在 `Linux/README.md` 中（`NSOperation.name`、`qualityOfService`、`NSDataWritingFileProtection*`、
`QOS_CLASS_DEFAULT`、应用组容器）。Phase A 预料的文件级排除最终恰好
是 §4 的四个文件（`BDHost`、`MADApplication`、`MADKeyChain`、`MADURLFactory`）；
序言过去用来掩盖的自包含头文件清理已完成（2026-10-06）：
Linux 构建中的每个头文件和源文件都导入其所用，且
`Linux/Compat/MADCompat.h` 降到一个真实的平台缺口——`NSOperation` 的
`name` 属性。

**Phase C 状态（2026-10-06）。** §4 shim 列表已清空，构建不再
是试验：§3 表中的全部十二个无头框架在镜像内编译并链接——
MADFoundation 27 个文件中的 26、MADDataStructures 17、
MADFileManager 11 中的 10、MADCocoaExtensions 17 中的 7、MADAPI 11 中的 8、
MADSqlite3 26、MADTds 1、MADTdsClient 5 中的 4、MADMySQL 19 中的 18、MAD 181 个中的
150——且它们的套件在 ctest 下运行：114 个可执行文件（1098 个测试），全部
通过，带 6 个已记录需求，每个都是仅 Apple 的机制（Core Data、
编译模型、`MADocument`、转换器），在 `Linux/README.md` 中命名。2026-10-10 合并的
覆盖率主干（约 100 个 Xcode 测试文件）已完整移植——55 个新可执行文件，逐套件——
且合并发现两个 Apple 侧缺陷，均已修复并进入 `BUGS.md`：框架目标曾从预处理器定义中丢掉
`$(inherited)`（DEBUG 在每个框架 Debug 构建中都是死的），且 MAD 的文档 fixture 多次运行共享一个存储。一个库
层（`Linux/libraries.conf`、`Linux/lib/libraries.sh`）把 sqlite3、
openssl、freetds、zlib、bzip2、libarchive、libpng、zint 和 mysqlclient 原生构建
进镜像（§7 的 C 库；不发布）。长尾项如 §4
所预测——`asl.h`/`vm_param.h` 导入已残留、`copyfile(3)`
变为 POSIX、`CFHost` 变为 `getaddrinfo`、CF 站点变为一个
`CFNumberGetValue` shim——且 UIKit/CoreGraphics 长尾按文件排除
并附原因，而非移植（§5.2 的处置；`MADocument`，一个
UIDocument，以及 `MADReportFormatter` 等待 Phase D，那既是平台的问题也是 CLI 的
问题）。MAD 的套件又发现三处分歧，
全部已修复或 shim 并写在 `Linux/README.md`：运行时的 BOOL
编码（非 Apple 上的 `'C'`）、`class_getProperty()` 缺失的父类遍历
（两者在 `RptqObject` 中修复）、以及一个存根 `+propertyListWithStream:`
（已 shim）。测试覆盖移植又增加三处，同样已修复或 shim：
`NSOperation.asynchronous`/`-isConcurrent`（一个 Compat category——没有它，一个
完成的异步操作会从 `-dealloc` 抛出）、`-coordinateAccessWithIntents:`
（其 GNUstep 实现故障；Compat category 在队列上调用访问器）、以及来自 `MADURLFactory` 的无 scheme URL（现为
`+fileURLWithPath:`，解除了五个协调器测试的挂起）。钉住最久的
一处分歧——GNUstep 的 `-localizedCaseInsensitiveCompare:` 区分大小写，使 MADSqlite3 注册的排序规则对文本的排序
与 Apple 上不同——现已修复（2026-10-25）：排序规则、内存排序
选择器和格式化器的比较器都经由一个第一方
定义顺序（`NSString+Comparison.h`），锁定变为定义顺序测试，
在两个平台上同样成立。实时
`MADTdsClientLiveTests` 套件在镜像内针对 SQL Server 容器运行通过（29/29），因此驱动路径在 Linux 上被
实际使用，而非仅编译。Phase D——CLI 和数据路径
动词——是下一步和 go/no-go。

**Phase D 状态（2026-10-16）。** 检查点已达成：`mad` 在
镜像内从 `CLI/Source`（构建 iOS 模拟器工具的同一份源码）构建，
链接十二个框架，并在那里运行数据路径。`inspect` 报告遗留 v0 样本和可移植 v1 fixture；
`schema` 和 `query` 产生与 Mac 工具相同的
答案（`schema` 字节相同）；`refresh` 在 Sqlite3 样本上填充行
缓存，按字段名比较与 Mac 缓存字节相同
（76 行、21 列）；且从镜像内针对实时服务器，`mad refresh` 从 MySQL 8.4 拉了 50 行
（`employees`，预编译语句抓取），从 SQL Server 2022 拉了 20 行
（`AdventureWorksLT2022`，经 freetds）。实时套件一致——
`MADMySQLLiveTests` 44/44 和 `MADTdsClientLiveTests` 29/29 在同一镜像中——且 ctest 运行是 117 个
可执行文件、1153 个测试、6 个需求，全部通过。

到达那里必须解决两件事，均记录在 `Linux/README.md`：

1. **文档问题（§5.1、§9 Phase D）。** `MADocument` 是 `UIDocument`，
   因此无法同行。用户的选择（2026-10-16）是无头文档
   路径，而非 `Compat` 中的 `UIDocument` shim，也非拆分 `MADocument`：
   文档的数据那一半现在是一个协议 `MADDocumentDataProtocol`，`MADocument` 遵循它
   （每个成员本来都是其访问器之一），且
   `MADHeadlessDocument` 在应用文档所用的同一 `MADDocumentStore` 上实现它。
   刷新链——随驱动注册表移到 `MAD`（`ROADMAP.md` §3.4、§5.1）——采用该协议，
   因此两个平台运行同一个 `MADOperationRefresh`；其唯一渲染侧分支是 `#if __APPLE__`，
   且 `mad export`（PDF、Core Graphics）留在 Apple，即 §5.2 的分阶段。
2. **驱动注册表（§3、§5.1）。** 构造器不再导入 MySQL
   和 TDS：每个驱动在 `+load` 中注册自身，构造器按类型查找它。
   在 Linux 上驱动归档以 whole-archive 处理，因为驱动的工作是通过*category*到达的，
   而 category 是链接器看不见的消息发送——CLI 曾在中止于 MySQL，直到修复（参见
   `Linux/README.md` 中的 compat-archive 注释）。

CLI 新增的 GNUstep 分歧：目录枚举器
（`-enumeratorAtURL:…` 产出剥离了所在目录的 URL——
实测，且 CLI 的成员列表改用 `-subpathsAtPath:`），以及
SELECT 列表列顺序，它曾是集合顺序因而与 Apple 不同
（同字段、同行；记录于 `Linux/README.md`）。**已于 2026-10-16 解决**，随
JSON 导出形态决策（下文 §10.1）：顺序在两个 SQL 构建器中都定义为列
别名，因此生成的 SQL、行缓存和每个导出
在两个平台上一致（docs/project/BUGS.md，SELECT 列表条目；
`Linux/Tests/MADQuerySelectExpressionTests.m` 中的顺序测试）。

**Phase E 状态（2026-10-16，前半）。** 导出接缝是真实的，Foundation 格式在此运行。
`MADReportExporting` + `MADReportExporterRegistry` 是
驱动注册表的形态（实现协议、`+load` 注册、
按名称查找），且 `mad export` 经由它们选择格式，因此新格式就是
新类（`MAD_CLI.md` §5.3、ROADMAP.md §5.2）。`text`、`csv` 和 `json` 是纯
Foundation，对 London fixture 在 **Linux 和 Apple 上产出字节相同的输出**——在 Mac 工具和镜像上
用 `sha256sum` 测量（§ `Linux/README.md` 的 CLI
部分；`Linux/Tests/MADReportExporterTests.m` 用 FNV-1a 校验和锁定同样的
字节）。JSON 形态已决定（§10.1）：`json` 是数据
契约——查询的列按别名顺序、行、SQL、驱动——而
`json-report` 是同一文档加上渲染后报表的带区作为额外
成员，用户于 2026-10-16 的选择：页面、按绘制顺序的带区，以及每
行的种类、框架和解析文本，构建自渲染器自身的页面遍历且
不绘制任何东西——因此它不会偏离 PDF 所显示的内容。它需要渲染那一半，
因此它在每个平台注册并报告为何不能在此运行。该遍历是
`MADPrintPageRenderer -buildPageAtIndex:context:inPageRect:`，它接受可空
上下文：PDF 路径传自己的并照旧绘制，json-report 传 NULL；
渲染那一半的第一个协议 `MADDocumentRenderProtocol`，是格式向文档
索取的东西。Phase E 剩余的一半——Linux 上的报表成员和
HTML/SVG——是渲染那一半向 Linux 的迁移，用户的渲染器决策
（HTML/SVG 次之，PDF 最后，§10.2）把它放在 HTML 步骤。`pdf` 仍是 CLI 自己的
分支；它随同一步骤成为导出器。

---

**Phase E 状态（2026-10-16，后半：写出器）。** `.mad` 写出器在
Linux 上运行，且两个平台写出相同字节。`MADArchiveManager.reproducible` 是
用户选择的选入模式（固定时间 2001-01-12T00:00:00Z、uid/gid 0、排序成员
遍历；普通保存保留文件系统的元数据），`MADHeadlessDocument` 长出
`-writeToURL:reproducible:error:`（应用的保存，去掉 UIDocument 部分），且
`mad write` 是在两个平台上到达它的动词。实测：London
fixture 在 Mac 和镜像中写出的是同一个 16,261 字节文件，sha256
`09815b24…`（SQL 录入 Phase A 的存储迁移改变了写出的字节；
fixture 本身仍是版本 1 存储）；`Linux/Tests/MADArchiveManagerTests.m` 锁定
字节、往返和模式。两个 Linux 专属缺陷曾挡路，已修复（`BUGS.md`，
字节一致性条目）：永不终止的遍历，以及 `dirname(3)`/`basename(3)`
在 glibc 上截断调用方的归档路径。比较覆盖的是
容器：成员是 fixture 自己的字节。一个*创建*存储的 Linux 写出器会把它
扩展到存储层。

**Phase E 状态（2026-10-16，第三部分：渲染那一半与 HTML）。** 渲染
那一半移到 Linux，且它是以一致性而非分叉的方式移动的。用户
对形态的回答是“一个格式化器，而非两条路径，且它们应渲染
相同”，因此：

* `MADReportFormatter` 接受 `id <MADDocumentRenderProtocol>`；协议长出
  格式化器读取的四个成员（`filename`、`storeContext`——它过去向
  MADocument 的 `-managedObjectContext` 索取——`database`、`resetSectionLayoutManagers`）
  并继承格式化器从文档赋值的 data、cache 和 report-data-source 协议。
* 页面遍历从 `MADPrintPageRenderer` 移到 `MADReportPageBuilder`，一个
  普通 Foundation 类：每页同样的读事务、同样的元素
  引用、每个元素同样的一个行表示，绘制现在是调用方传入的 block
  （渲染器传一个会绘制的；格式不传）。构建器还拥有渲染侧的几何
  （US Letter、1pt 裁切）和准备序列（排序行、定尺寸格式化器、格式化），
  这些曾被复制在 CLI 的 PDF 分支和 json-report 中。
* `MADDocumentRenderDataSource` 是渲染那一半读取的唯一实现——
  `MADPrintPageRendererDataSourceProtocol` 和 `MADReportFormatterDataSource` 在
  文档之上——`MADocument` 和 `MADHeadlessDocument` 都通过询问它来回答。
  主体是 MADocument 的，只是移动；应用的页面读取的与之前完全一样。
* `MADHeadlessDocument` 遵循 `MADDocumentRenderProtocol`，因此一个没有
  窗口的文档现在能格式化和遍历。`MADOperationRefreshInitialize` 的渲染分支
  以协议为键，而非 `[doc isKindOfClass: [MADocument class]]`。
* 元素家族可无头编译：`MADPrintPageElement` 的初始化器是
  Foundation（文本在那里解析），只有 `-drawInRect:` 主体是
  `#if __APPLE__`。非 Apple 上图像元素的图片是存储的 PNG 字节
  （`MADElementImage` 是 `NSData`），且 `-renderedImageData` 把它们交给
  导出器所读的行表示。`MADElementStylizedText` 留在 Apple——它是
  绘制，不是布局。

**分页不需要文本引擎**，这是实测而非假定：一个带区的显示
高度来自 `MADSectionLayout`（存储矩形 + 边距 + 内边距 + 边框），它在
Linux 构建中且自 Phase C 起就在，因此分页在各处相同。
文本度量只在元素被*绘制*时进入，且渲染器
以 `NSLineBreakByTruncatingTail` 绘制——一行、裁切——CSS 拼作
`white-space: pre; overflow: hidden; text-overflow: ellipsis`。什么都不换行，因此
没有要移植的换行模型；未添加字体引擎。

**`mad export --format json-report` 在此运行**，走同一遍历，且它
报告的框架现在是*页面*坐标（元素的框架按其带区偏移），正是
渲染器或浏览器所需。

**两个新格式，均在两个平台上**（用户两者都选）：`html` 是
摹本——每个已遍历页面一个 CSS 页面框，每个元素绝对定位在
其框架处，带其解析文本和其存储的字体、字号、字形特征和对齐；浏览器把它打印为
与 PDF 相同的页面。`html-flow` 是同一报表的可重排版——`<section>`、
每带区一张 `<table>`、每元素一个 `<td>`、页面装饰只发出一次；一个阅读视图，
而 `--format json` 仍为数据契约。两者都是一个 UTF-8 文件，内嵌 `<style>`、
无脚本；摹本的 CSS 是上文 20 行加一条定位规则，而流文件的样式是一张
生成的类表（London fixture 九个类）。

**`pdf` 在接缝上**：`MADReportExporterPDF` 在每个平台注册。在 Apple 上其
主体是 Core Graphics + `MADPrintPageRenderer`，不变；非 Apple 上它把同样的
已遍历页面交给 `MADReportExporterPDFCairo`，后者把它们绘制进一个 Cairo PDF surface，
字形用 FreeType、来自随附的 Liberation 字面（docs/project/MAD_PDF_LINUX.md）。CLI
已无本地分支。Apple 的移动是字节中立的：London 样本的确定性导出
前后是同一个 43,177 字节、5 页 PDF
（两者 `sha256 3eb2f1c4…`），通过构建前一提交的 CLI 并
比较来测量。无头写出器瞄准结构对等，而非字节对等。

**跨平台比较说明什么。** 每行文本、每个框架、
每个字体、页数和文件结构在 Apple 与 Linux 上对
London fixture 完全相同，字节也相同：`html`、`html-flow` 和 `json-report` 在两个平台上
有相同 sha256（`Linux/README.md` 有摘要）。到达那里经历了
一个发现及其修复：渲染货币过去依赖机器。报表
现在从文档的数字格式取*区域设置*和*小数位数*（存储两者都保留；
未声明的文档回退到 `en_US`，而非机器的区域设置），元素工厂在新元素上记录设计区域设置，且
货币符号显式写出并正规化日元符号（GNUstep 把它拼作全角）。跨六个区域设置的
60 例比较字节相同；完整条目在 `BUGS.md` 的归档中。

**Phase F 状态（2026-10-17，部分）。** CLI 是作为运行时
镜像的交付物，而非构建树中的二进制。`Linux/Dockerfile` 在
`ubuntu:24.04` 上长出一个 `runtime` 阶段，携带 `/usr/local/bin/mad`（CMake 的安装规则）、
CLI 链接的共享对象（GNUstep Base、libobjc2、libdispatch、
libBlocksRuntime、mysqlclient）、GNUstep 的运行时目录、mysqlclient 的
消息和字符集文件，以及应用支持路径上的 `chinook.sqlite3`；它
留下编译器、源码、测试、头文件和静态归档。它在磁盘上
283 MB（压缩 66.5 MB），对比 6.65 GB 构建镜像。
`./Linux/build.sh --runtime` 构建它，`--verify` 在其中运行
`Linux/verify-cli.sh`：30 项检查——六个动词、每个离线
格式的锁定摘要、`pdf` 的拒绝、可复现写出器的字节、退出码，以及镜像自身的形态（无 clang、cmake、git 或构建树）。
2026-10-17 通过；`--live` 增加 MySQL 和 TDS 刷新（32/32）。套件
还在共享 London fixture 和样本数据库的两个测试二进制之间获得一个 `RESOURCE_LOCK`——ctest 的并行曾使那一对
间歇失败（加锁后连续 35 次并行运行通过）。

用户同一天的决定：**无 CI**（Linux 移植是概念验证和可重复测试，
而非发布；`./Linux/build.sh --verify` 是检查）和**不发布**（不从注册表拉取任何东西，
因此 GPL 问题停在 §10.3 所留之处）。Compressor Linux 驱动是
Phase F 唯一未完成的部分，且 CLI 不需要它：镜像
原生构建 C 库。

## 10. 留给用户的决策

1. **JSON 导出形态**（`MAD_CLI.md` §8.3、`MAD_FUTURE.md` §10.5）——这是
   Python 契约；先决定它，因为 §2 的一切都挂着它。
   **2026-10-16 已决定：两者都要，报表那一半作为自己的格式。** `--format json`
   是数据契约——一个信封（格式 id、文档/驱动、SQL、行
   数）、`columns`（键、名称、表、类型），以及 `rows` 作为每行一个对象、值带
   JSON 类型——而 `--format json-report` 是该文档加一个 `report`
   成员（渲染后的带区）。有了它，SELECT 列表的顺序定义为列
   别名、排序后，因此生成的 SQL、行缓存和每个导出在两个平台上一致
   （docs/project/BUGS.md，SELECT 列表条目——此前是集合顺序）。数据
   那一半已构建（`MADReportExporterJSON`，两个平台）；报表成员等待
   渲染那一半。
2. **渲染器分阶段**——HTML/SVG 先，PDF 最后，还是 macOS 侧 PDF 工作进程？
   **2026-10-16 已决定：HTML/SVG 次之，PDF 最后。** 无 Linux PDF 渲染器、无
   macOS 侧工作进程：HTML 步骤也是渲染那一半
   （`MADReportFormatter`）移到 Linux 之处，`json-report` 和测试也想要它。
   `pdf` 在那之前仍是 CLI 的 Apple 侧分支。
   **2026-10-16 已完成（HTML 步骤）。** 渲染那一半在 Linux 上，`mad export`
   已无本地分支：`pdf` 是一个已注册导出器，其主体是 Apple 的，且在非 Apple 上
   说明原因。用户同一天的进一步决定：Linux PDF 写出器
   是*下一个*步骤，不是本步骤的一部分，因为 HTML 摹本的页面框正是
   Linux 写出器必须复现并用于测试的几何。写出器的形态
   为此记录在此：**Cairo（绘制、PDF surface）+ Pango（布局、
   换行）+ FreeType/HarfBuzz**，GTK/WebKit/Firefox 所用的技术栈，也是 Linux 最接近
   Core Graphics + Core Text 的东西——从 Objective-C 调用的 C API，就像
   freetds 和 sqlite3 已经那样，因此无需 Impl 包装器。许可证：Cairo
   LGPL-2.1/MPL-1.1 双许可、Pango LGPL-2.1、HarfBuzz MIT、FreeType FTL/GPLv2 双许可；项目
   已随附 LGPL（FreeTDS，`LICENSE_COMPLIANCE_PLAN.md` §4），且 Linux
   镜像是服务器构建，因此这是已知的义务类别。`libharu` 是
   宽松的替代品但无布局引擎；Skia 能力最接近但构建繁重。**无法实现：跨平台字节相同的 PDF**——
   Core Graphics 的写出器无法复现——因此目标是同样的页面、框、
   文本和字体，用 Apple 字体的度量兼容替代品
   （`MADFont` 的默认字族是 Helvetica Neue，Linux 没有）。
   **2026-11-20 已完成（PDF 收尾）。** 技术栈是 Cairo（PDF surface）+
   FreeType，无 Pango：遍历把每个行的框架、文本、字体、字号、
   字形特征和对齐都交给它，因此没有布局要做——只有字形步进和
   字面自身的 `kern` 表，由 FreeType 提供。Cairo 1.18.6（MPL-1.1）和
   pixman 0.46.4（MIT）静态构建；Liberation 字面（SIL OFL 1.1）是
   Apple 字体的替代品。`MAD_PDF_LINUX.md` 记录落地了什么、
   字体映射策略和实测残余。目标仍是结构性的：
   Core Graphics 的字节不可复现。
3. **mysqlclient → MariaDB Connector/C 时机**——GPL 阻塞项门控任何已发布的
   二进制；替代品已在 `LICENSE_COMPLIANCE_PLAN.md` 中命名。
4. **工具链政策**——从源码构建的 clang/libobjc2/GNUstep（ARC 所需）是一项
   维护承诺；接受它，或留在 macOS 宿主上。
5. **重写触发点**——§9 的 phase D 是可测量的检查点；在它
   失败之前，建议维持：一个 Objective-C 引擎，从 Python
   跨 CLI 边界调用。
6. **构建基线**——在 Debian-stable 或 Ubuntu-LTS 基础上用 Docker，在
   Linux 上构建而非从 macOS 交叉编译（§8.1）。该选择设定受支持的
   glibc 下限，因此一次且刻意地做出它。
