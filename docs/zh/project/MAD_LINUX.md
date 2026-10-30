---
layout: default
lang: zh-CN
---

# 在 Linux 上编译 MAD 引擎 —— 技术评估

写于 2026-10-04，基于 `master` 的 `c807eeb4d`。本文所依据的依赖审计（§4）和
生态系统调研（§5-6）都是同日完成的：审计是对每个框架的源代码目录逐一 grep，
调研来自一手来源（发行说明、软件包仓库、项目邮件列表）。证据薄弱处会明说。
本文是 `MAD_FUTURE.md` §5.1 的技术姊妹篇，那里勾勒了平台矩阵；这里是深入。

---

## 1. 问题，已作答

这能在 Linux 上编译吗？**能，有条件地——两种意义上都是。**

- 必须编译的代码——无头引擎——按测量已经几乎不含 Apple 依赖。剩下的两个（Core Data
  和 UIKit/CoreGraphics）要么正在迁移中，要么已逐文件枚举，且两者都不在刷新路径上。
- 必须承载它的生态系统——Linux 上带 Foundation 的 Objective-C——存在，
  打包在每个主要发行版中，且今天在运行一个生产级群件服务器
  （SOGo，Debian 打包，依赖 GNUstep Base 1.31.1）。它小众，其
  现代 API 覆盖率在边缘未经证实，且它的 UIKit 故事并不存在——但本代码库在
  Linux 上不需要 UIKit。它需要引擎。

两个星号：**GNUstep 的 Foundation 属于存在但未验证**，针对本代码最依赖的那些
精确 API（`NSPredicate`/`NSExpression`、键控归档、
`NSURLSession`），并且 **Linux 上不存在现实的 UIKit**——这没关系，
因为审计显示代码已把 UIKit 限制在具名文件中，而渲染计划无论如何都要离开
UIKit。

---

## 2. 双产品问题：重写，还是编译并调用

用户提出的选择：用 Python 重写一切并维护两个产品，
还是编译一次并让 Python 调用引擎。审计给出了定论。

**引擎很大。** 无头框架集——`MADFoundation`（65 个 h+m 文件）、
`MADCocoaExtensions`（44）、`MADDataStructures`（36）、`MADFileManager`（30）、`MADAPI`
（33）、`MAD`（403）、`MADSqlite3`（64）、`MADMySQL`（41）、`MADTds`（3）、`MADTdsClient`
（8）——大约 727 个文件。Python 重写复制的不仅是体量，还有
*被测试钉住且来之不易的行为*：SQL 生成器、
`MADDataTableFast` 摄取路径（200,000 行 1.16 秒，已基准测试）、驱动的
类型映射（SQL Server 的现代日期/时间处理之所以存在，是因为实时测试
两次抓到了它）、null 哨兵一族、存储读取器。这样的两个实现
会漂移；测试套件只钉住一个。那不是“两个产品”，而是一个产品
加一个包袱。

**集成面已经存在。** CLI *就是*契约：`mad inspect` → 元数据，`mad query` → SQL，`mad refresh` → 行，`mad export` → 格式，退出码
区分坏文档（2）、不可达服务器（3）和失败查询（4）。Python 服务以子进程方式
调用它并加 `--format json`，就得到报表。子进程开销在
刷新的时间尺度上无关紧要（样例刷新耗时 0.02-1.2 秒；进程启动约 10 毫秒）。如果将来测量到
进程内嵌确实重要，同样的源码可以构建一个小型 C ABI 库供
ctypes/CFFI 使用——但那是可选的，不是前提条件。

**关于偏好 Python 的既定理由——驱动接入。** 确实，Python 的
连接器生态很广，一次 `pip install` 就能触及本项目
没有驱动的数据库。但对于今天已有的源，接入
已经是语言中立的：MAD 的驱动坐落在 freetds 和 MariaDB Connector/C 之上——与
Python 或 C 程序会链接的同一批 C 库——而且两者都能在 Linux 上原生构建（§7）。
编译引擎把这种接入原样搬到 Linux。Python 真正占优的地方是*新的*源类型
（Postgres、BigQuery、REST），而那里正确的答案
是项目已经承诺的可扩展性接缝：一个返回架构和行的 `MADDatabase`
子类。通过 HTTP 通信的驱动在 Objective-C 和 Python 中行为
相同；Python 买到的是更多现成连接器，而不是
更简单的核心。

**诚实的权衡，直说：** 这是在维护*两个
实现*（Python + Objective-C）并承担永久漂移风险，与维护
*一个实现但位于小众工具链上*（clang + libobjc2 + GNUstep）并承担
生态系统风险之间做选择。本文推荐后者，并给出一个可度量的重审触发点：
§9 点名了那个检查点。让这一建议具有约束力的一件事是 **JSON 导出形态**
——Python 契约的好坏取决于其架构，而定义它正是 §10 中的决策 1。

如果重写真的发生，正确的语言是 Linux 上的 Swift——而不是 Python
——因为可移植 SQLite 存储（Phase C 的工作）已经是语言中立的
契约：无论哪一侧写存储，另一侧都能读。

---

## 3. 什么必须编译，什么不能

| 框架 | 无头需要 | 原因 / 为何不需要 |
|---|---|---|
| `MADFoundation` | 是 | 基础：操作、URL 工厂、钥匙串（可排除）、日志 |
| `MADCocoaExtensions` | 是 | 到处使用的辅助函数（11 个 UIKit 文件，但都是可排除的） |
| `MADDataStructures` | 是 | 0 个 Apple 导入；3 个 C++ 文件（需要 libc++） |
| `MADFileManager` | 是 | 0 个 Apple 导入；排除云协调器（iCloud 在 Phase D 中本来就会被删除） |
| `MADAPI` | 是 | 连接层；3 个 UIKit 文件是视图控制器，不是无头 |
| `MAD` | 是 | 最难的一个：403 个中 29 个 UIKit、34 个 CoreData、15 个 CoreGraphics |
| `MADSqlite3` | 是 | 0 个 Apple 导入；`MADArrayCaching`（`.madac` 存储）100% 干净 |
| `MADMySQL` | 是 | 0 个 Apple 导入 |
| `MADTds` / `MADTdsClient` | 是 | 0 个 Apple 导入 |
| `MADExplorer` | 否 | 文件浏览器 UI（32 个文件中有 19 个导入 UIKit） |
| `MADBarcodes` | 否 | 仅 Apple：UIKit 渲染路径加 zint，镜像不携带它；该元素类型在无头下仅保留模型 |
| `MADFeedback` | 否 | 未使用且未维护 |
| `Scrimpter` | 否 | 0 个 Apple 导入，但未使用 |
| `MADDesigner`（应用） | 否 | 302 个 UIKit 文件；UI 留在 Apple 平台 |

依赖方向：一切都建立在 `MADFoundation` 上；驱动继承
`MAD` 中的 `MADDatabase`，而 `MAD` 的 `Constructor` 文件又导入驱动——这就是
已知的循环（`ROADMAP.md` §3.4）。驱动注册表（`ROADMAP.md` §5.1）对
Linux 有双重意义：它打破那个循环，并且它让 Linux 构建能把驱动
作为插件链接，而不是当作一堆硬导入的代码。

---

## 4. 测得的审计

每个框架源代码目录中导入各 Apple 框架的文件（一个导入多个 UIKit
头文件的文件只计一次）：

| 框架 | 总数 | UIKit | CoreData | CoreGraphics | Security | os/log | CoreFoundation | dispatch |
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

支柱之外的长尾，每一项都给出了处置：

| 项目 | 位置 | 处置 |
|---|---|---|
| `os_log`（一切汇入 `madlog.h`，两份副本） | 9+15+4+2+… 个文件导入该垫片 | 针对 syslog/printf 重写一个约 20 行的头文件；其他调用点不变 |
| `asl.h`（已弃用的 Apple System Log） | `MADocument.m:107`、`RptqDocumentElement+Extras.m:60` | 换成 madlog 垫片 |
| `copyfile.h` | `MADArchiveManager.m:14`、`madtar.m:18` | POSIX rename/link |
| `mach/machine/vm_param.h`（页大小） | `MADocument.m:108` | `getpagesize()` |
| `CFNetwork`/`CFHost` 反向 DNS | `BDHost.m`（1 个文件） | `getaddrinfo` |
| `NSMetadataQuery` 云协调器 | `MADFileManager`（3 个文件） | 排除——iCloud 在 Phase D 中删除 |
| `Security.framework` / `SecItem` | `MADKeyChain.m`、`MADOperationKeyChainGet.m` + 测试 | 排除——刷新路径从操作依赖取凭据，从不从钥匙串取；CLI 已用 `--credentials` 替代 |
| `MADApplication.m` 中的 `AppKit` 保护 | 1 个文件 | 加一个 `TARGET_OS_LINUX` 分支 |
| `MADURLFactory.m:32` 中的 `UIScreen` 缩放 | 1 行 | 返回 2.0 |
| `MADOperation.m:549-563` 中的 `UIApplication` 后台任务 | 1 个受保护特性 | 用 `#if` 排除 |
| CoreFoundation（`CFNumber`/`CFData`/`CFString`，toll-free bridging） | MAD、MADFoundation、MADSqlite3 中约 25 处 | GNUstep 等价物 / 机械重写；CoreBase（GNUstep 的 CF 克隆）不成熟，不要依赖 |
| UIKit 值转换器（`MADColorTransformer`、`MADLocaleTransformer`、`MADPngImageTransformer`） | 3 个文件，目前被拖过 CLI 的 target 边界 | **随 Phase D 消亡**——存储迁移把可转换值转为可移植标量 |

SystemConfiguration：零出现。CommonCrypto：框架中为零（仅应用，用于
收据验证）。`@import`：零——一切都是 `#import`，这正是
GNUstep 想要的。

---

## 5. 三个支柱

### 5.1 Core Data —— 在飞的迁移就是杠杆

34 个 MAD 文件导入 Core Data；`MADocument` 是一个 `UIManagedDocument`；存储是一个
编译过的 `MAD.momd`；底下坐着 `MADAtomicStore`。这些在 Linux 上都不存在，
也都不需要存在——因为项目已经在替换它：`MAD_STORE_MIGRATION.md`
的 Phase C 于 2026-10-03 落地，且 `RptqStoreContext.h` 声明“这里没有任何东西导入
Core Data。”Phase D 删除 `UIManagedDocument`、值转换器、
`.xcdatamodel` 和 iCloud 机制——这同时消灭了 §4 中的若干项（值转换器、云协调器、
CLI 目前从应用 bundle 中拷出的 `MAD.momd`）。

**完成 Phase C 和 D 是迈向 Linux 的单一最高杠杆步骤**，而它
是项目为可移植性已经拥有的工作，不是 Linux 特有的努力。迁移计划中有一条
注记：iCloud 时代的旧文档由用户通过 iOS 文件 app 取回并在打开时转换
（`MADStoreConverter`）——取回它们不需要 iCloud 机制，所以
Phase D 对它的删除不会搁浅任何东西。

### 5.2 UIKit / CoreGraphics —— 29 个文件，大多数微不足道

29 个 MAD UIKit 文件分解如下：

| 种类 | 数量 | 处置 |
|---|---|---|
| `CGGeometry` 结构体（`CGRect`/`CGSize`/`CGPoint`） | 15 个文件 | 普通结构体——复制定义；零绘制 |
| 格式化器中的 `UIEdgeInsets` | 约 3 个文件 | 换成结构体运算 |
| 模型/布局代码中的 `UIFont`/`UIColor`/`UIImage` | 若干 | 用于度量和存储样式的轻量等价物 |
| `UIActivityItemProvider` / 分享面板 | 2 个文件 | 非无头——排除 |
| `UIScreen`/`UIApplication` | 2 个文件 | 一行式，§4 |
| `MADPrintPageRenderer` + `UIGraphics` PDF 上下文 | 导出接缝 | **真正的工作**——见下文 |
| `MADocument` 的 `UIManagedDocument` 基类 | 文档类 | 随 Phase D 消亡 |

值得注意的好消息：`MADReportFormatter.m` 对 UIKit 的使用实际上是残留的
（一个 `UIEdgeInsetsMake`，一个未使用的 `UIPrintInteractionController` 导入），而
`MADArrayCaching`——`.madac` 渲染页存储——已经 100% 不依赖 UIKit/CoreData。
它今天能在任何 ObjC Foundation 上编译。

**渲染器决策。** CoreGraphics PDF 上下文没有 Linux 等价物。成本最低的
分阶段：先让数据路径动词变绿；接着 `export --format json` /
`--format csv`（纯 Foundation——而且这些正是 Python 调用方本来就想要的
格式）；再是 HTML/SVG 页面（无原生依赖）；最后 PDF，办法是把
cairo 或 libharu 写入器放在同一个 `MADPrintPageRenderer` 绘制循环之后，或者把
PDF 渲染留在 macOS 工作进程上，而 Linux 提供数据和页面。CLI 已经把
`--deterministic` 标志字节补丁进 PDF，这正是跨平台渲染器测试的种子。

### 5.3 GNUstep 上的 Foundation —— 存在，部分验证，边缘有风险

研究从一手来源验证的：

- **GNUstep Base 1.31.1**（2025-02-28）是当前版本；master 活跃（值得注意的
  NSURLSession 工作于 2026-08 合并）。发布节奏缓慢——大约每年一次。
- 存在且可用：`NSJSONSerialization`、`NSUUID`、`NSRegularExpression`
  （ICU）、`NSISO8601DateFormatter`、`NSDateFormatter`（ICU 支持——`libicu-dev` 是
  必需的构建依赖）、`NSOperationQueue`、属性列表、`NSXML*`
  （libxml2）、旨在兼容 Apple XML 的键控归档。
- **`NSURLSession` 是薄弱点**：1.31.0 作为“新的实验性
  实现”发布，明确不是受支持的类；2026 年的去 block 化工作
  （在无 blocks 情况下构建）已合并，但稳定化尚未完成。不要在它上面构建
  Linux 产品——优先直接驱动连接（刷新本来就是这样做的）或 libcurl。
- **按 GNUstep 自己的政策，`libdispatch` 是可选的**——基础维护者称它
  “尚未达到足够可移植/可靠的依赖状态”。本代码库
  广泛使用 dispatch（`dispatch_once`、`dispatch_sync`、信号量）。
  swift-corelibs-libdispatch 是 C，可从 ObjC 调用（配合
  `OS_OBJECT_HAVE_OBJC_SUPPORT=1`），而这里用到的*核心*是稳定的部分
  ——但要把 dispatch 当作可垫片化的层，而不是理所当然。
- **CoreBase**（GNUstep 的 CoreFoundation 克隆）不成熟——构建指南说
  不要依赖它。那约 25 处 CF 位置改用 GNUstep 等价物。
- **边缘未验证，且在这里承重：** `NSPredicate`/`NSExpression`
  （MAD 中 13+ 个导入位置）、`unarchivedObjectOfClass:`（iOS 11+ API——GNUstep
  覆盖程度不一）、`NSOperation`+KVO 行为。存在性已被证明；
  行为对等没有。这是诚实的风险，也正是 §8 中测试夹具
  存在的目的。

**存在性证明：** SOGo，一个 Objective-C 群件服务器，在 Debian
sid 中发布并硬依赖 `gnustep-base-runtime (>= 1.31.1)`——GNUstep Foundation
作为生产守护进程大规模运行。Darling 用的就是 libobjc2。Linux 上的非 GUI ObjC
工具链是正常的，不是奇异的。

---

## 6. 工具链与生态系统

- **运行时：libobjc2 2.3**（2025-09-16）——在 Linux 上获得现代 Objective-C
  的唯一途径。ARC、blocks、弱引用、`@synchronized`、非脆弱实例变量、
  gnustep-2.0 ABI。**ARC 需要 clang + libobjc2**，而主流发行版的
  打包是针对 GCC 运行时且不带 ARC 构建 GNUstep——所以构建环境
  要从源码组装（或用 Fedora 的 libobjc2 打包），而不是用
  Debian 的默认值。这是真实的运维承诺。
- **Blocks**：libobjc2 2.3 可以消费 swift-corelibs-libdispatch 的 BlocksRuntime；
  `libblocksruntime-dev` 也有打包。代码中的 blocks 是标准的。
- **异常**：clang + libobjc2 给出基于原生 unwinder 的异常；GNUstep 的
  两种异常机制不能在一个可执行文件中混用——全部用原生
  路径构建。
- **不支持 clang modules / `@import`**——而代码库本来就处处用
  `#import`，所以这没有代价。
- **Linux 上的 UIKit：确认缺席。** 用户记忆中的 Microsoft 是 WinObjC——
  Windows Bridge for iOS，一个在 Windows 上有意残缺的 UIKit 子集，最后
  推送 2022 年，2025-05-28 归档。Chameleon（macOS 上的 UIKit）2015 年
  就死了。`gnustep/libs-uikit`（2026 年 6 月）是一个 26 次提交、一个 star 的
  实验。连 Microsoft 都放弃这个想法，应得的教训是：**不要移植 UIKit。**
  审计显示了为什么本项目不必——UIKit 已经被限制在
  具名文件中，而无头的一切都通过数据而非视图渲染。
- **测试：Linux 上没有 ObjC 的 XCTest**（swift-corelibs-xctest 仅限 Swift）。
  GNUstep 自己的 `gnustep-tests` + `Testing.h` 是零依赖的单元运行器；
  UnitKit 已归档。真正的验收层是 §8 的夹具，不是单元测试。
- **加密与机密**：没有 CommonCrypto 移植（GNUstep 项目自己的建议是
  用 `#ifdef` 切到 OpenSSL 或 GnuTLS）；没有钥匙串（功能性对应物是
  libsecret/Secret Service，或用于会话机密的 keyutils）——而按 §4，
  无头引擎两者都不需要。

---

## 7. C 库 —— 容易的部分，有一个许可证阻碍

每个内置库都是可移植 C，带上游 autoconf/cmake 构建：

| 库 | 版本 | 许可证 | Linux 构建 |
|---|---|---|---|
| sqlite3 | 3.53.3 | public domain | 原生；固定格式用的标志已在 `Compressor/sqlite3.xcconfig` 中 |
| zlib | 1.3.2 | Zlib | 原生 |
| openssl | 3.5.9 | Apache-2.0 | 原生 |
| bzip2 | 1.0.8 | BSD-like | 原生 |
| libpng | 1.6.59 | PNG Reference v2 | 原生 |
| libarchive | 3.8.9 | BSD-2 | 原生 |
| freetds | 1.4.27 | LGPL-2.0+ | 原生（配方有一个 BSD `sed -i ''` 的小问题要修） |
| mysqlclient | 8.4.10 | **GPL-2.0 + FOSS exception** | 原生——**但 GPL 对专有二进制是发布阻碍**；MariaDB Connector/C（LGPL-2.1）是 `LICENSE_COMPLIANCE_PLAN.md` 中已点名的替代品 |
| zint | 2.16.0 | BSD-3 | 原生（未使用的条码后端） |

再加上树内 C（`miniz`、`madmath`、`madpng`、`madtar`、`madlib`——都是
可移植的，都是宽松许可证）。只有 Compressor 的*打包*层是 Apple 特有的
（`xcrun`、`-isysroot`、`lipo`、`xcodebuild -create-xcframework`）；一个 Linux 驱动
丢掉所有这些，原生运行同样的上游构建，最后用普通
`ar` + include 安装收尾。iOS 特有的复杂性（mysqlclient 的两阶段
主机工具构建、freetds 的按平台生成的头文件）在原生构建上*消失*。审计中的
一个标志：Karl Kraft MySQL 连接器没有许可证——
随 MariaDB 迁移替换它，不要发布它。

---

## 8. 构建与测试计划

- **构建系统**：CMake 用于十个无头框架加 CLI——一套
  标志（`clang`、`-fobjc-arc`、`-fblocks`、GNUstep 的 `gnustep-config --objc-flags`）。
  `CLI/build.sh` 中复制 `.momd` 的那套把戏随 Phase D 消失，而
  `REFRESH_SOURCES` 跨 target 边界取材的做法随 `MADOperationRefresh` 的移动
  （`ROADMAP.md` §3.4）消失。
- **验收层**：`MAD_CLI.md` §6 中的往返夹具，在 Linux 上运行
  并与 macOS/模拟器运行做字节比较——容器保真度、v0
  可读性、无缓存往返、退出码。行缓存和 JSON/CSV 输出是
  字节可比的；PDF 在一个渲染器存在之前只能是结构可比。这些夹具也是
  *GNUstep Foundation 的覆盖率测试*：尽早运行它们，逐一分类每个失败，
  §5.3 的未知项会经验性地自行解决，而不是靠读 API 索引。
- **CI**：测试矩阵中一个运行夹具的 Linux 作业；套件仍然是今天的
  模拟器套件。

### 8.1 部署路径：容器，而非交叉编译

这实际上如何构建和发布？

- **不要从 macOS 交叉编译。** 一个 Objective-C 运行时加上 GNUstep Base 是
  宿主耦合的——从 Mac 上针对 Linux sysroot 交叉编译它是一个研究
  项目，不是一个构建步骤。iOS 应用仍由 Mac 上的 Xcode 构建；Linux
  引擎*在 Linux 上构建*。
- **Docker 是构建环境。** 一个 Dockerfile，两个阶段：一个工具链阶段
  从源码构建 clang + libobjc2 2.3 + GNUstep Base（ARC 所必需——§6）；
  一个构建阶段为 C 库运行 Compressor Linux 驱动（§7），然后
  为十个框架和 CLI 运行 CMake。同一个镜像兼作 CI
  环境和部署产物。
- **支持哪个 Linux：一个基线，放在容器里。** 选一个单一基线——
  Debian stable 或某个 Ubuntu LTS——并在那里构建，因为真正的兼容性
  约束是 glibc：所有链接的东西都从源码构建，除了 libc，所以
  “支持的 Linux”意味着“我们发布的镜像的 glibc”。在你接受的
  最老 glibc 上构建是规则。发布容器意味着任何具备 Docker 能力的宿主机
  都能运行产品，无需发行版矩阵。
- **工作流就是你已经习惯的脚本加编译，只是自动化了。**
  Linux 构建机上的 `git clone` → Compressor 配方从源码构建 sqlite、zlib、openssl、
  bzip2、libpng、libarchive、freetds 和 MariaDB → CMake 用一套标志
  编译框架 → 链接 `mad` → 运行往返夹具（见上）→
  给镜像打标签。一个 GitHub Actions ubuntu runner 是每次
  提交都发生这件事的标准场所。
- **macOS 的角色。** Mac 仍是应用、模拟器
  CLI 和参考夹具输出的开发宿主。两个平台由 git 和
  夹具的字节比较连接——Linux 构建*对照* Mac 的
  输出来检查，这就是可移植性保证的可执行形式。

---

## 9. 工作量与阶段

按应采用的顺序排列的桶（bucket）：

| 阶段 | 工作 | 性质 |
|---|---|---|
| A | 完成存储迁移的 Phase C + D | 已拥有的可移植性工作；移除 Core Data、iCloud、值转换器、`.momd`——最大的单一 Linux 杠杆 |
| B | 工具链探针：一个从源码构建 clang + libobjc2 + GNUstep Base 的 Dockerfile；编译一个 MADFoundation 子集 | 证明环境并成为构建/CI 镜像；数天 |
| C | §4 的垫片清单 | 有界且已枚举——madlog、asl、copyfile、vm_param、CFHost、MADApplication、UIScreen、后台任务、约 25 处 CF 位置、排除项 |
| D | **检查点**：数据路径动词在 Linux 上变绿——`inspect`、`schema`、`query`、`refresh` 对两个样例，夹具做字节比较 | 如果 C 之后这还不绿，GNUstep Foundation 的长尾比估计的更大，而那才是重审重写问题的时刻——不是之前 |
| E | 导出：JSON/CSV（Python 契约），然后 HTML/SVG 页面，然后 PDF 决策（cairo/libharu 对比 macOS 侧渲染） | 先纯 Foundation；渲染器最后 |
| F | Compressor Linux 驱动（原生构建、矩阵列、MariaDB 替换、freetds sed 修复）+ CMake 打磨 + CI 行 + 可部署镜像 | 机械性，受许可证门槛 |

排序理由：A 是已拥有的工作，B 便宜且为一切消除风险，C 可枚举，
D 是诚实的 go/no-go。E 或 F 中没有任何东西是*回答*
问题所需的；它们只在*发布*时所需。

**Phase A 状态（2026-10-06）。** Core Data 已移出 MAD 框架：`MADocument` 是一个
`UIDocument`，遗留转换器和编译过的模型位于应用 target 内、
在 `MADLegacyStoreConversion` 之后，转换后的文档会修剪其 Core Data 文件，
框架/MADDesigner 的清扫移除了剩余的导入、类型和死代码。值
转换器、文件浏览器的云面板和 iCloud 资格由用户决定保留——
它们在应用侧，所以不阻碍无头构建；文件管理器的
云代码保持原地，未使用（据用户：无头模式不需要）。在 B 之前剩下的，
是工具链探针证明必要的任何 §4 文件级排除项。

**Phase B 状态（2026-10-06）。** 工具链探针在
`linux-port` 分支上是绿的，2026-10-16 合并到 `master`（`524e0d86e`）：
`Linux/` 构建一个 Docker 镜像——Ubuntu 24.04 加发行版
clang 18（§6 中“从源码”的要求是关于 GNUstep 针对 libobjc2 构建，
而不是关于 LLVM），加上源码构建的 libobjc2 2.3、libdispatch 6.1.3、
gnustep-make 2.9.3 和 gnustep-base 1.31.1，固定在 `Linux/toolchain.conf`——
针对 GNUstep 编译 MADFoundation 27 个实现文件中的 23 个和 `madlib.c`，
并在其中运行 15 个测试可执行文件（14 个移植套件和一个工具链探针）：
全部通过，带 5 条记录的需求和 10 条探针报告项。
`./Linux/build.sh` 是入口点；iOS 套件保持绿色（118 个测试），
作为这项工作要求的六个小型平台保护在 Apple 上行为中立的
证明。

探针消解了 §5.3 风险清单的大部分，针对引擎实际使用的 Foundation：
ARC 和弱引用清零、blocks、异常、`@synchronized`、KVO（手动和
依赖键）、`NSOperation` 状态机 KVO、`NSPredicate
predicateWithFormat:@"error != nil"`（MAD 的精确谓词）、dispatch（包括
主队列在普通可执行文件下排空）、JSON、日期、plist、排序
描述符、流和宽松路径上的键控归档全部通过。两个缺口
被记录而非隐瞒：GNUstep 的归档器不支持安全编码
（`requiringSecureCoding:YES` 返回 nil；宽松路径可往返），以及
GNUstep 的 `NSOperationQueue` 在每次通知时移除其 `isReady` 观察，
而 MADOperation 的状态机过去每次入队会通知 `isReady`
不止一次——第二次移除会抛出异常，于是 MADOperation 无法
在 Linux 上入队。这已解决（2026-10-06，`linux-port`，现在在 `master` 中）：
MADOperation 从 `-willEnqueue` 显式驱动状态推进，并且只在真实值变化时
发送 `isReady`/`isExecuting`/`isFinished` 的 KVO，于是
队列只看到一次通知，与 Apple 上一样；Linux 测试在两个平台上
直白地断言它，需求降到 3 条。机制与
排除的文件和较小的垫片（`NSOperation.name`、`qualityOfService`、`NSDataWritingFileProtection*`、
`QOS_CLASS_DEFAULT`、app-group 容器）一起写在 `Linux/README.md` 中。Phase A 预期的文件级排除项
恰好就是 §4 的四个文件（`BDHost`、`MADApplication`、`MADKeyChain`、`MADURLFactory`）；
prelude 过去用来遮掩的自包含头文件清理已完成（2026-10-06）：
Linux 构建中的每个头文件和源文件都导入它所用的东西，而
`Linux/Compat/MADCompat.h` 已缩减到唯一真正的平台缺口——`NSOperation` 的
`name` 属性。

**Phase C 状态（2026-10-06）。** §4 的垫片清单已清空，构建不再
是探针：§3 表中的全部十个无头框架都在镜像内编译并链接——
MADFoundation 27 个文件中的 26 个、MADDataStructures 17、
MADFileManager 11 个中的 10 个、MADCocoaExtensions 17 个中的 7 个、MADAPI 11 个中的 8 个、
MADSqlite3 26、MADTds 1、MADTdsClient 5 个中的 4 个、MADMySQL 19 个中的 18 个、MAD 181 个中
的 150 个——其套件在 ctest 下运行：114 个可执行文件（1098 个测试），全
绿，带 6 条记录的需求，每条都是 Apple 专有的机制（Core Data、编译过的
模型、`MADocument`、转换器），在 `Linux/README.md` 中点名。2026-10-10 合并的
覆盖率主干（约 100 个 Xcode 测试文件）被完整移植——55 个新可执行文件，套件对套件
——而那次合并发现两个 Apple 侧缺陷，都已修复并记入 `BUGS.md`：框架 target 从其
预处理器定义中丢掉了 `$(inherited)`（每个框架 Debug 构建中 DEBUG 都是死的），
以及 MAD 的文档夹具在多次运行间共享一个存储。一个库
层（`Linux/libraries.conf`、`Linux/lib/libraries.sh`）在镜像内原生构建 sqlite3、
openssl、freetds、zlib、bzip2、libarchive 和 mysqlclient（§7 的 C 库；不随产品发布）。
长尾项按 §4 的预测发展——`asl.h`/`vm_param.h` 导入是残留的，`copyfile(3)`
变成 POSIX，`CFHost` 变成 `getaddrinfo`，CF 位置变成一个
`CFNumberGetValue` 垫片——而 UIKit/CoreGraphics 的长尾逐文件
排除并给出理由，而不是移植（§5.2 的处置；`MADocument`（一个
UIDocument）和 `MADReportFormatter` 等待 Phase D，这既是 CLI 的
问题也是平台的问题）。MAD 的套件又发现三处分歧，
全部修复或垫片化并写入 `Linux/README.md`：运行时的 BOOL
编码（Apple 之外为 `'C'`）、`class_getProperty()` 缺少超类遍历
（两者都在 `RptqObject` 中修复）、以及一个桩 `+propertyListWithStream:`
（已垫片化）。测试覆盖率的移植又添三处，同样修复或垫片化：
`NSOperation.asynchronous`/`-isConcurrent`（一个 Compat 类别——没有它，正在收尾的
异步操作会从 `-dealloc` 抛出）、`-coordinateAccessWithIntents:`
（其 GNUstep 实现出故障；Compat 类别改为在队列上调用访问器）、
以及来自 `MADURLFactory` 的无 scheme URL（现在是
`+fileURLWithPath:`，它解除了五个协调器测试的搁置）。钉得最久的
那处分歧——GNUstep 的 `-localizedCaseInsensitiveCompare:` 是
区分大小写的，所以 MADSqlite3 注册的排序规则对文本的排序与
Apple 上不同——现在已修复（2026-10-25）：排序规则、内存排序
选择器和格式化器的比较器都经由一个第一方定义顺序
（`NSString+Comparison.h`）路由，而那个钉住它的测试变成了在两个平台上行为一致的
已定义顺序测试。实时
`MADTdsClientLiveTests` 套件从镜像内部对 SQL Server 容器跑绿（29/29），
所以驱动路径在 Linux 上被演练，而不只是被编译。Phase D——CLI 和
数据路径动词——是下一步，也是 go/no-go。

**Phase D 状态（2026-10-16）。** 检查点已达成：`mad` 从
`CLI/Source` 在镜像内构建（与构建 iOS Simulator 工具所用的同一批源码），
链接十个框架，并在那里运行数据路径。`inspect` 报告一个
遗留 v0 样例和一个可移植 v1 夹具；`schema` 和 `query` 产生与
Mac 工具相同的答案（`schema` 字节完全一致）；`refresh` 在 Sqlite3 样例上填充行
缓存，按字段名比较时与 Mac 的缓存字节完全一致（76 行、21 列）；
而对镜像内的实时服务器，`mad refresh` 从 MySQL 8.4 拉了 50 行
（`employees`，一次预备语句抓取），从 SQL Server 2022 拉了 20 行
（`AdventureWorksLT2022`，经 freetds）。实时套件一致——
`MADMySQLLiveTests` 44/44 和
`MADTdsClientLiveTests` 29/29 在同一镜像中——而 ctest 运行为 117
个可执行文件、1153 个测试、6 条需求，全绿。

为到达那里必须解决两件事，都记录在 `Linux/README.md`：

1. **文档问题（§5.1、§9 Phase D）。** `MADocument` 是一个 `UIDocument`，
   所以它不能一起过来。用户的选择（2026-10-16）是无头文档
   路径，不是 `Compat` 中的 `UIDocument` 垫片，也不是拆分 `MADocument`：
   文档的数据那一半现在是一个协议，`MADDocumentDataProtocol`，
   `MADocument` 遵循它（每个成员本来就是它的某个访问器），而
   `MADHeadlessDocument` 在应用文档所用的同一个 `MADDocumentStore` 上实现它。
   刷新链——随驱动注册表移入 `MAD`
   （`ROADMAP.md` §3.4、§5.1）——接受该协议，所以两个平台运行同一个
   `MADOperationRefresh`；它唯一一个渲染侧分支是 `#if __APPLE__`，而
   `mad export`（PDF、Core Graphics）留在 Apple，这就是 §5.2 的分阶段。
2. **驱动注册表（§3、§5.1）。** 构造函数不再导入 MySQL
   和 TDS：每个驱动在 `+load` 中注册自己，构造函数按类型查找它。
   在 Linux 上驱动归档被整档链接（whole-archive），因为驱动的工作
   是通过*类别*到达的，而类别是链接器看不见的一次消息发送——
   在修好之前 CLI 在 MySQL 上中止（见 `Linux/README.md` 的
   兼容归档注记）。

CLI 又添的 GNUstep 分歧：目录枚举器
（`-enumeratorAtURL:…` 产出的 URL 剥掉了包含目录——
已测量，而 CLI 的成员列表改用 `-subpathsAtPath:`），以及
SELECT 列表的列顺序，它原先是集合顺序因而与 Apple 不同
（同样的字段、同样的行；记在 `Linux/README.md`）。**2026-10-16 敲定**，随
JSON 导出形态决策（下面的 §10.1）一起：顺序在两个 SQL 构建器中
都定义为列别名，所以生成的 SQL、行缓存和每次导出在两个平台上
一致（docs/project/BUGS.md，SELECT 列表条目；`Linux/Tests/MADQuerySelectExpressionTests.m` 中的
顺序测试）。

**Phase E 状态（2026-10-16，前半）。** 导出接缝是真的，Foundation
格式在这里运行。`MADReportExporting` + `MADReportExporterRegistry` 是
驱动注册表的形态（一个实现协议、`+load` 注册、
按名称查找），而 `mad export` 通过它们挑选格式，所以新格式就是一个
新类（`MAD_CLI.md` §5.3、ROADMAP.md §5.2）。`text`、`csv` 和 `json` 是纯
Foundation，为 London 夹具在 **Linux 和 Apple 上产出字节完全一致的输出**
——用 `sha256sum` 在 Mac 的工具和镜像的工具上测量（见
`Linux/README.md` 的 CLI 一节；`Linux/Tests/MADReportExporterTests.m` 用 FNV-1a 校验和
钉住同样的字节）。JSON 形态已决定（§10.1）：`json` 是数据
契约——查询的列按别名顺序、行、SQL、驱动——而
`json-report` 是同一份文档加上渲染报表的 section 作为额外
成员，这是用户在 2026-10-16 的选择：页面、按绘制顺序的 section，以及每一行的
种类、frame 和解析后的文本，由渲染器自己的页面遍历构建而
不绘制任何东西——所以它不会偏离 PDF 所显示的内容。它需要渲染
那一半，所以它在各处注册并报告为何在此无法运行。那次遍历是
`MADPrintPageRenderer -buildPageAtIndex:context:inPageRect:`，它接受一个可为 nil 的
上下文：PDF 路径传入自己的上下文并照旧绘制，而 json-report 传入 NULL；
渲染那一半的第一个协议 `MADDocumentRenderProtocol`，就是该格式
向文档索取的东西。Phase E 剩下的另一半——Linux 上的 report 成员和
HTML/SVG——是渲染那一半迁往 Linux，而用户的渲染器决策
（先 HTML/SVG，PDF 最后，§10.2）把它放在 HTML 那一步。`pdf` 仍然是 CLI
自己的分支；它在同一步变成导出器。

---

**Phase E 状态（2026-10-16，后半：写入器）。** `.mad` 写入器在
Linux 上运行，两个平台写出相同的字节。`MADArchiveManager.reproducible` 是
用户选择的可选模式（固定时间 2001-01-12T00:00:00Z、uid/gid 0、排序的成员
遍历；普通保存保留文件系统的元数据），`MADHeadlessDocument` 长出了
`-writeToURL:reproducible:error:`（去掉 UIDocument 部分的应用保存），而
`mad write` 是在两个平台上到达它的动词。测量结果：在 Mac 上和
镜像中写出的 London 夹具是同一个 16,261 字节的文件，sha256
`09815b24…`（SQL 录入 Phase A 的存储迁移改变了所写的字节；
夹具本身保持为版本 1 的存储）；`Linux/Tests/MADArchiveManagerTests.m` 钉住
字节、往返和模式。有两个仅 Linux 的缺陷挡在路上，已修复（`BUGS.md`，
字节一致条目）：永不终止的遍历，以及 `dirname(3)`/`basename(3)`
在 glibc 上截断调用方的归档路径。比较覆盖的是
容器：成员是夹具自己的字节。一个*创建*存储的 Linux 写入器
会把它扩展到存储层。

**Phase E 状态（2026-10-16，第三部分：渲染那一半，以及 HTML）。** 渲染
那一半搬到了 Linux，而且它是作为一次一致性（conformance）而非分叉搬过去的。
用户对形态的回答是“一个格式化器，不是两条路径，而且它们应该渲染得
一样”，所以：

* `MADReportFormatter` 接受 `id <MADDocumentRenderProtocol>`；该协议长出了
  格式化器读取的四个成员（`filename`、`storeContext`——它过去索取
  MADocument 的 `-managedObjectContext`——`database`、`resetSectionLayoutManagers`），
  并继承格式化器从文档赋值的那些数据、缓存和报表数据源协议。
* 页面遍历从 `MADPrintPageRenderer` 移入 `MADReportPageBuilder`，一个
  纯 Foundation 类：每页同样的读取事务、同样的元素
  引用、每个元素同样的单行表示，绘制现在变成
  调用方传入的一个 block（渲染器传入一个会绘制的；格式不传入）。
  构建器还拥有渲染侧的几何（US Letter、1pt 裁切）和
  准备顺序（排序行、设置格式化器尺寸、格式化），这些原先被抄在
  CLI 的 PDF 分支和 json-report 里。
* `MADDocumentRenderDataSource` 是渲染那一半读取的唯一实现——
  `MADPrintPageRendererDataSourceProtocol` 和 `MADReportFormatterDataSource` 建立在
  文档之上——`MADocument` 和 `MADHeadlessDocument` 都通过询问它来作答。
  主体是 MADocument 的，被移动了过来；应用的页面读到的与之前完全一样。
* `MADHeadlessDocument` 遵循 `MADDocumentRenderProtocol`，所以没有
  窗口的文档现在也能格式化和遍历。`MADOperationRefreshInitialize` 的渲染分支
  改为以该协议为键，而不是以 `[doc isKindOfClass: [MADocument class]]` 为键。
* 元素一族可在无头下编译：`MADPrintPageElement` 的初始化器是
  Foundation 的（文本在那里解析），只有 `-drawInRect:` 的主体和
  图像的 `UIImage` 是 `#if __APPLE__`。`MADElementStylizedText` 仍归 Apple——
  它是绘制，不是布局。

**分页不需要文本引擎**，这是测量出来的而非假设的：一个 section 的显示
高度来自 `MADSectionLayout`（存储的 rect + 外边距 + 内边距 + 边框），它
自 Phase C 起就在 Linux 构建里，所以分页在各处都一样。
文本度量只在元素被*绘制*时才介入，而渲染器用
`NSLineBreakByTruncatingTail` 绘制——一行、裁剪——对应的 CSS 是
`white-space: pre; overflow: hidden; text-overflow: ellipsis`。没有任何换行，所以
没有换行模型要移植；没有添加字体引擎。

**`mad export --format json-report` 在这里运行**，走同样的遍历，它
报告的 frame 现在是*页面*坐标（元素的 frame 加上其 section 的偏移），这正是
渲染器或浏览器所需的。

**两个新格式，两个平台都有**（用户两个都选了）：`html` 是
摹本——每个遍历到的页面一个 CSS page box，每个元素绝对定位在其 frame 处，
带其解析文本和其存储的字体、字号、特征和对齐；浏览器把它打印成与 PDF 相同的
页面。`html-flow` 是同一报表的可重排版——
`<section>`、每个 section 一个 `<table>`、每个元素一个 `<td>`、页面
附属元素（page furniture）只输出一次；一个阅读视图，而 `--format json` 仍是数据契约。
两者都是一个 UTF-8 文件，内嵌 `<style>`，无脚本；摹本的 CSS
是上面那 20 行加一条定位规则，而 flow 文件的样式是一张
生成的类表（London 夹具九个类）。

**`pdf` 在接缝上**：`MADReportExporterPDF` 处处注册，其主体是
Apple 的（Core Graphics + `MADPrintPageRenderer`），在 Apple 之外它回答
`+isAvailable NO` 并给出理由。CLI 不再有任何本地分支。这次移动是
字节中立的：London 样例的确定性导出在前后是同一个 43,177 字节、
5 页的 PDF（两个平台上 `sha256 3eb2f1c4…`），通过构建
前一个提交的 CLI 并比较来测量。

**跨平台比较说明了什么。** 每一行文本、每个 frame、
每种字体、页数和文件结构在 Apple 和 Linux 上对 London 夹具完全
一致，字节也一样：`html`、`html-flow` 和 `json-report` 在两个平台上
sha256 相同（`Linux/README.md` 有摘要）。走到这一步需要
一项发现及其修复：渲染出的货币过去依赖机器。报表
现在从文档的数字格式取得其区域*和*小数位数（存储两者都保留；
不说明的文档回退到 `en_US`，而不是机器的区域设置），元素工厂
在新元素上记录设计时的区域，而货币符号显式写出并归一化
日元符号（GNUstep 会写成全角）。跨六个区域设置的 60 例比较字节完全
一致；完整条目在 `BUGS.md` 的存档中。

**Phase F 状态（2026-10-17，部分）。** CLI 是作为运行时镜像的可交付物，
而不是构建树中的二进制。`Linux/Dockerfile` 长出了基于 `ubuntu:24.04` 的 `runtime` 阶段，
携带 `/usr/local/bin/mad`（CMake 的安装规则）、
CLI 链接的共享对象（GNUstep Base、libobjc2、libdispatch、
libBlocksRuntime、mysqlclient）、GNUstep 的运行时目录、mysqlclient 的
消息和字符集文件，以及位于应用支持路径的 `chinook.sqlite3`；它
把编译器、源码、测试、头文件和静态归档留在身后。它在磁盘上是
283 MB（压缩后 66.5 MB），而构建镜像是 6.65 GB。
`./Linux/build.sh --runtime` 构建它，而 `--verify` 在其中运行
`Linux/verify-cli.sh`：30 项检查——六个动词、每个离线
格式的钉住摘要、`pdf` 的拒绝、可复现写入器的字节、
退出码，以及镜像自身的形态（没有 clang、cmake、git 或构建树）。
2026-10-17 绿；`--live` 加上 MySQL 和 TDS 刷新（32/32）。套件
还在共享 London 夹具和样例数据库的两个测试二进制之间获得了 `RESOURCE_LOCK`
——ctest 的并行性曾使那一对间歇性失败（加锁后连续 35 次
并行运行全绿）。

用户同一天的决定：**不做 CI**（Linux 移植是概念验证
和可重复的测试，不是发布；`./Linux/build.sh --verify` 就是检查）
以及**不发布**（没有从注册表拉取任何东西，所以 GPL 问题停留在 §10.3 留下的地方）。
Compressor Linux 驱动是 Phase F 唯一没做完的部分，而 CLI 并不需要它：
镜像原生构建 C 库。

## 10. 用户的决策

1. **JSON 导出形态**（`MAD_CLI.md` §8.3、`MAD_FUTURE.md` §10.5）——这是
   Python 契约；先决定它，因为 §2 中的一切都挂在它上面。
   **2026-10-16 决定：两者都要，报表那一半作为独立格式。** `--format json`
   是数据契约——一个信封（格式 id、文档/驱动、SQL、行
   数）、`columns`（key、name、table、type），以及 `rows` 为每行一个对象，
   值为 JSON 类型——而 `--format json-report` 是那份文档加上一个 `report`
   成员（渲染后的 section）。随之，SELECT 列表的顺序定义为
   列别名，已排序，所以生成的 SQL、行缓存和每次导出在两个平台上
   一致（docs/project/BUGS.md，SELECT 列表条目——此前是集合顺序）。数据
   那一半已建成（`MADReportExporterJSON`，两个平台）；report 成员等待
   渲染那一半。
2. **渲染器分阶段**——先 HTML/SVG、最后 PDF，还是 macOS 侧 PDF 工作进程？
   **2026-10-16 决定：先 HTML/SVG，最后 PDF。** 不做 Linux PDF 渲染器，不做
   macOS 侧工作进程：HTML 这一步也是渲染那一半
   （`MADReportFormatter`）迁往 Linux 的地方，`json-report` 和测试也都需要它。
   `pdf` 在此之前仍是 CLI 的 Apple 侧分支。
   **2026-10-16 完成（HTML 这一步）。** 渲染那一半在 Linux 上，而 `mad export`
   没有本地分支：`pdf` 是一个已注册的导出器，其主体是 Apple 的，在 Apple 之外
   会说明原因。用户同一天的进一步决定：Linux PDF 写入器是
   *下一个*步骤，不属于这一步，因为 HTML 摹本的 page box 正是
   Linux 写入器必须复现并作为其测试的几何。写入器的形态在此
   为该步骤记录：**Cairo（绘制，PDF surface）+ Pango（布局，
   换行）+ FreeType/HarfBuzz**，GTK/WebKit/Firefox 所用的栈，也是 Linux 上最接近
   Core Graphics + Core Text 的东西——从 Objective-C 调用 C API，就像
   freetds 和 sqlite3 已经那样，所以不需要 Impl 包装。许可证：Cairo
   LGPL-2.1/MPL-1.1 双许可、Pango LGPL-2.1、HarfBuzz MIT、FreeType FTL/GPLv2
   双许可；项目已经发布 LGPL（FreeTDS，`LICENSE_COMPLIANCE_PLAN.md` §4），而 Linux
   镜像是服务器构建，所以这是一类已知的义务。`libharu` 是
   宽松许可证的替代品但没有布局引擎；Skia 在能力上最接近，
   但构建是沉重的 C++。**不可达成：跨平台字节完全一致的 PDF**——
   Core Graphics 的写入器无法复现——所以目标是相同的页面、框、
   文本和字体，用度量兼容的替代字体替换 Apple 的字体
   （`MADFont` 的默认字族是 Helvetica Neue，Linux 没有）。
   **状态 2026-10-17：延期，阻塞在用户的研究上——未经他们的决定
   不要开始。** `MAD_PDF_LINUX.md` 是交接文件：有什么、缺什么、
   候选栈及其许可证、开放问题和验收测试。目前没有东西需要它：
   HTML 摹本从浏览器打印，而应用的 PDF 未被触及。
3. **mysqlclient → MariaDB Connector/C 的时机**——GPL 阻碍为任何已发布的
   二进制设槛；替代品已在 `LICENSE_COMPLIANCE_PLAN.md` 中点名。
4. **工具链政策**——从源码构建的 clang/libobjc2/GNUstep（ARC 所需）是一项
   维护承诺；接受它，或留在 macOS 宿主上。
5. **重写触发点**——§9 的 phase D 是可度量的检查点；在它
   失败之前，建议维持不变：一个 Objective-C 引擎，由 Python 跨 CLI 边界调用。
6. **构建基线**——Docker 基于 Debian stable 或 Ubuntu LTS，在 Linux 上构建
   而不是从 macOS 交叉编译（§8.1）。这个选择设定了支持的
   glibc 下限，所以只做一次，且要有意识地做。
