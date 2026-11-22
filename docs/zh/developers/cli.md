---
layout: default
title: "`mad` 命令行工具"
description: "无需界面即可打开、检查、查询、刷新和导出 `.mad` 文档。"
lang: zh-CN
---

# `mad`——MAD Designer 命令行界面

本页介绍 `mad` 命令行工具：引擎的嵌入接口，也是在不用应用的情况下使用 `.mad` 文档最快的方式。如果你对容器和存储还不熟悉，请先阅读格式规范。

本文档定义了一个命令行工具，它无需用户界面即可打开、检查、刷新和导出
`.mad` 文档。

这份记录撰写于 Apple 应用的表现层仍完全基于 UIKit 的时期，因此它无法作为原生 macOS 或 Windows 应用运行。现在已有原生 macOS（AppKit）和 Windows（WPF）应用；`mad` CLI 仍是无需 UI 即可运行同一引擎的无头路径。数据路径——打开文档、运行查询、填充缓存、渲染报表——几乎完全摆脱了 UIKit（见 §4），这正是 CLI 具备可移植性的原因。

---

## 1. 范围

**范围内。** 一个单一二进制文件 `mad`，它可以：

- 打开一份 `.mad` 文档并报告其中有什么
- 打印文档所依据的数据库架构
- 把文档定义的查询以 SQL 形式打印出来
- 连接到源数据库，运行查询并填充行缓存
- 导出渲染后的报表

**刻意排除。** 任何编辑文档的功能。CLI 读取并运行文档；它不设计文档。
参数解析、动词和退出码就是全部接口面。

---

## 2. 为什么先做 CLI

| | CLI | Mac 应用 |
|---|---|---|
| 需要 UI 工具包 | 否 | AppKit（重写）或 Catalyst（已否决） |
| 需要框架可移植 | **是** | 是 |
| 需要行缓存可移植 | **是** | 是 |
| 需要 `.mad` 被定义 | **是** | 是 |
| 交付你要求的东西 | 是 | 是 |
| 格式变化时被丢弃的工作 | 无 | UI |

Mac 应用为了存在所需的一切——可移植的框架、已定义的文件格式、为不止一个平台构建的库——
CLI 都需要先具备。先做 UI 移植会是以昂贵的方式发现同样的问题。Mac 应用仍是
另行做出的决定，稍后进行，届时框架已经可移植。

---

## 3. 命令接口

```
mad <command> [options] <document.mad>
```

### `mad inspect <doc.mad>`

仅读取容器。无数据库连接，无 Core Data。

```
$ mad inspect London.mad
London.mad
  format      v0 (bzip2 tar, no magic header)
  generator   MAD Designer
  version     1
  store       StoreContent/analyitics (SQLite 3.43.2, 126 pages)
  wal         present, 313152 bytes (not checkpointed)
  thumbnail   none
  elements    14 sections, 63 elements
```

这个动词证明 `MAD_FORMAT.md` §7 已被实现：它必须在 v0 样本上工作。
它也是让格式隐患可见的动词——H2（未检查点的 WAL）会被报告，
而不是被默默承受。

### `mad schema <doc.mad>`

打印文档定义中捕获的数据库架构：驱动、按名称排序的表，
以及每个表字段的显示类型和 `pk` 标记。它读取创建时存储的快照，
因此不需要凭据，也不需要源数据库。（这里的原始计划是输出 SQL `CREATE TABLE`；
快照存储的是 `MADDataType` 抽象，而不是每种源方言的类型名，
因此若要忠实地生成 `CREATE TABLE`，还需要一个尚不存在的按方言映射。
在那之前，工具产出的是可读列表。）

### `mad query <doc.mad>`

打印文档查询生成的 SQL，但不运行它。这是应用所围绕的核心功能——用户组装表、联接和
筛选器，软件写出 SQL——因此暴露它是自然的第一个
非平凡动词。

```
$ mad query London.mad --format sql
SELECT ... FROM ... WHERE ...
```

### `mad refresh <doc.mad>`

连接到源数据库，运行查询并填充行缓存。这就是
数据路径，也是其余功能所依赖的动词。

```
$ mad refresh London.mad --credentials user:pass
refreshed 148,392 rows in 1.21 s (122,638 rows/s)
cache  ~/Library/Caches/MADDesigner/<id>/<tag>.maddb
```

选项：`--credentials`、`--host`、`--port`、`--database`、`--no-cache`（运行
但不持久化）、`--rows N`（在 N 行后停止，用于冒烟测试）。

`--rows` 之所以存在，是因为它让该动词可以在 CI 中针对实时
服务器进行测试，而不必拉取上百万行，也因为
`MADDataTableFastBenchmarkTests` 中的基准已经证明该路径在大规模下可度量。

### `mad export <doc.mad>`

渲染报表并写出。

```
$ mad export London.mad --format pdf  --out London.pdf
$ mad export London.mad --format json --out -          # to the standard output
```

这些格式就是导出接缝的格式（§5.3）：每一个都是向
`MADReportExporterRegistry` 注册的类，用法文本会列出构建中已有的格式。

| 格式 | 写出内容 | 运行位置 |
|---|---|---|
| `pdf` | 渲染后的报表（页面，已绘制） | Apple：UIKit 的 `UIPrintPageRenderer`、Core Graphics；Linux 会说明为何不可 |
| `html` | 渲染后的报表作为单个 HTML 文件，每页一个页面框，从浏览器打印 | 两个平台 |
| `html-flow` | 渲染后的报表作为可重排 HTML，每个带区一张表 | 两个平台 |
| `text` | 行作为定宽表 | 两个平台 |
| `csv` | 行作为 RFC 4180 CSV | 两个平台 |
| `json` | 架构和行作为 JSON（§8.3） | 两个平台 |
| `json-report` | `json` 加上渲染后报表的各带区 | 两个平台 |

对 Foundation 格式而言 `--out` 是可选的——缺省或 `-` 写出标准
输出——而对 `pdf` 是必需的。同一文档在 Apple 和 Linux 上，Foundation 格式写出相同字节
（`Linux/README.md`；两个平台对 London fixture 的导出按摘要比较相等）。

**已定义的顺序。** 导出的分组顺序是契约的一部分，因此它是
已定义的顺序，而非平台的顺序：文本键不区分大小写比较，然后按
UTF-8 字节上的码点顺序。大小写折叠是 Unicode 17.0.0 的简单（一对一）大小写
折叠，保存为签入的表（`MADFoundation/Source/NSString+Comparison.m` 中的
`MADStringOrderingTable`，由 UCD 的
`CaseFolding.txt` status-C/S 条目生成）——ASCII 和表中映射的每一对 Unicode
都会折叠；其他一切，包括变音符号，都按其自身码点比较。由于
折叠把每个字母送入小写区，而小写区位于每个 ASCII
标点字节之后，以标点开头的键（`[1997] Black Light Syndrome`）会排在
以单词开头的键（`Core`）之前——与 SQLite 的 `NOCASE` 放置它的位置相同。UTF-8 保持
码点顺序，因此字节比较就是码点比较。一个
比较器（`-[NSString mad_orderedCompare:]` 及其 C 核心
`MADStringOrderedCompareUTF8`）驱动全部三个位置：缓存的 `LSASC` 排序规则、
内存排序描述符（`MADDataTypeSelectorForSorting`）以及报表
格式化器的分组边界比较。该顺序跨平台、
操作系统版本和区域设置都是确定性的；它于 2026-10-25 从本地化顺序改变，因此
该日期之前的导出与之后的导出比较不相等。

**`json-report`**（`MAD_LINUX.md` §10.1、§9 Phase E）是同一架构，外加
渲染后的报表作为 `report` 成员：页面、每页按绘制顺序的带区（类型、
分组级别、可见性）、每个带区的行，以及每行元素的种类、框架和
解析后的文本。它是测试和渲染器所读取的内容，也是渲染器自身的
结构——未绘制任何东西的页面遍历——因此它不会偏离 PDF
所显示的内容。框架是行**在页面上**的位置（元素的框架按其
带区偏移），这是渲染器或浏览器所需要的。渲染那一半现在已在 Linux 上编译，
因此该格式在两个平台上都能运行。

**`html`** 是浏览器打印的页面形态产物：每个已遍历
页面一个 CSS 页面框，每个元素绝对定位在其框架处，其解析后的文本使用
元素自身的字体、字号、字重、倾斜、装饰和对齐。换行规则
是渲染器的（`NSLineBreakByTruncatingTail` -> `white-space: pre; overflow:
hidden; text-overflow: ellipsis`）。它是一个 UTF-8 文件，内嵌样式块
且无脚本。**`html-flow`** 是去掉页面的同一份报表：每个报表带区一个 `<section>`，
每个带区一张 `<table>`，每个元素一个 `<td>`，页面装饰只发出一次，
每个不同的元素样式生成一个类。它是阅读视图；
`json` 是数据契约。两者都不携带颜色（存储的颜色列目前在两个平台上
都没有读取者），在 Linux 上也不携带图片（Apple 路径从
`UIImage` 绘制它们；Linux 导出放置空框）。

渲染为 PDF 经由 `MADPrintPageRenderer`；分享面板包装器
`MADActivityItemProviderPdf` 是它的另一个调用者，`MADActivityItemProviderDelegate.h`
是它与之对话的协议。三者都位于 `MAD` 框架中，而非
应用中。PDF 所**不是**的是**无头**：它是 UIKit 的 `UIPrintPageRenderer`，这也是
它仍是唯一一个在 CLI 侧实现的格式的原因（见 §5.3）。

### `mad write <doc.mad> --out <copy.mad>`

把文档写为 `.mad`——一份*副本*：文档被读入的 guts 目录，再次
用 v1 头归档。它不会编辑它所读取的文档，
CLI 仍然不设计文档（§1）；这个动词的用途是
字节一致性要求——在两个平台上写出的同一份文档必须是
同一个文件——以及 §6.1 的往返 fixture，它需要一个脚本能运行的写出器。

```
$ mad write London.portable.mad --out copy.mad --reproducible
wrote /tmp/copy.mad (16261 bytes, reproducible)
```

`--reproducible` 固定了时钟和文件系统原本会盖入
归档的内容：固定的修改时间（2001-01-12T00:00:00Z，即 PDF 导出
固定其日期的时刻）、所有者和组为 0，以及排序的成员遍历
（`MADArchiveManager.reproducible`）。没有它，则写出普通保存，使用
成员的真实元数据。文档在两个平台上都无头打开
（`MADHeadlessDocument`），因此比较的两侧运行同一个写出器，
同一份文档在那里写出相同字节（London fixture 上为 16,261 字节，
`Linux/README.md`）。

### 全局选项

| 选项 | 含义 |
|---|---|
| `--verbose` | 记录每个阶段的数据路径 |
| `--quiet` | 除结果外一律抑制 |
| `--credentials user:pass` | 源数据库凭据；否则使用钥匙串 |
| `--host <name>` | 源数据库主机覆盖（refresh、export） |
| `--port <n>` | 源数据库端口覆盖，1-65535（refresh、export） |
| `--database <name>` | 源数据库名称覆盖（refresh、export） |
| `--no-keychain` | 绝不触碰钥匙串 |
| `--format <name>` | 输出格式 |
| `--out <path>` | 输出路径；默认标准输出 |
| `--deterministic` | 固定导出的日期和标识符，使对未变数据的两次运行字节相同 |
| `--reproducible` | 固定 `.mad` 归档的输入——时间、所有权、成员顺序（`write`） |

连接定义——主机、端口和数据库名——是文档可移植存储的一部分；
用户名和密码则从不是。`--host`、`--port` 和 `--database` 仅覆盖本次运行的存储连接，
因此一份签入的文档可以针对 CI 服务容器运行，而无需
被重写。未给出的部分保留其存储值。在连接为文件的 Sqlite3 文档上，
以及在不连接的动词（`inspect`、`schema`、`query`、`write`）上，它们会被拒绝，
或干脆不被使用。凭据仍用 `--credentials`；存储不保存用户名或密码。

### 退出码

| 代码 | 含义 |
|---|---|
| 0 | 成功 |
| 1 | 用法错误 |
| 2 | 文档无法读取或不是 `.mad` |
| 3 | 源数据库不可达，或凭据被拒绝 |
| 4 | 查询在服务器上失败 |
| 5 | 导出失败 |

不同的代码很重要，因为这个工具的第一个真实用途是脚本，而
脚本需要区分“文档有问题”和“服务器宕机”。

---

## 4. CLI 构建之前必须具备什么

数据路径已经几乎不依赖 UIKit。这是实测的，不是估计的：

| 框架 | 导入 UIKit 的文件 | CLI 是否需要 |
|---|---|---|
| `MADDataStructures` | 0 / 37 | 是 |
| `MADFileManager` | 0 / 31 | 是 |
| `MADSqlite3` | 0 / 65 | 是 |
| `MADMySQL` | 0 / 42 | 是 |
| `MADTds` / `MADTdsClient` | 0 / 3、0 / 9 | 是 |
| `Scrimpter` | 0 / 48 | 否 |
| `MADFoundation` | 4 / 66 | 是 |
| `MADAPI` | 3 / 34 | 部分 |
| `MAD` | 28 / 464 | 部分 |

`MADFoundation` 中的四个文件承载了基础框架的全部 UIKit 依赖：

| 文件 | UIKit 用途 | 处置 |
|---|---|---|
| `MADApplication.{h,m}` | 一个 `UIApplication` 包装器 | CLI 不需要；从无头目标中排除 |
| `MADURLFactory.m:32` | `UIScreen.mainScreen.scale > 1.0` | 一处调用；非 iOS 返回 2.0 |
| `MADOperation.m:550-563` | `beginBackgroundTaskWithName:` | 一项功能，由 `#if TARGET_OS_IPHONE` 保护 |

作者已经在 `MADOperation.m:21` 标记了最后一项：*"Wish I didn't have to
import UIApplication here, but it's really the cleanest way."* 对于无头构建，
它不是最干净的方式，而这也是基础框架中唯一如此的地方。

`MADAPI` 的三个 UIKit 文件是连接*视图控制器*，完全不
属于无头目标。

### 4.1 刷新核心必须迁移

唯一实质性的工作就是这一点。刷新编排**位于应用
目标中，而不是框架中**：

| 文件 | 行数 | UIKit 符号 | 角色 |
|---|---|---|---|
| `MADDesigner/Source/MADOperationRefresh.m` | 131 | **0** | 构建 SQL、运行它、写入缓存 |
| `MADDesigner/Source/MADOperationRefreshReload.m` | 196 | 3 | UI 侧重载 |
| `MADDesigner/Source/MADRefreshOperationReload.m` | 132 | 1 | UI 侧重载 |

`MADOperationRefresh.m` 只导入 `MADAPI`、`MADFoundation` 和 `MAD`，不触碰
任何 UIKit。它已经是 CLI 的刷新动词；只是位于错误的目标中。它
移到 `MAD` 框架，两个 `Reload` 操作留在应用中，
这正是它们的名字一直以来所表达的意思。

### 4.2 无头目标

一个 `MADFoundation`、`MADAPI` 和 `MAD` 的构建配置，可在无
UIKit 的情况下编译，再加上 CLI 目标本身。从机制上说，这就是扩展
`SUPPORTED_PLATFORMS` 加入 `macosx`、`LIBRARIES.md` §6 中的按 SDK 库搜索路径，
以及上面的三处文件级排除。

**已于 2026-10-16 在 Linux 上完成**（`MAD_LINUX.md` §9 Phase D），方式如下：
无头目标是由 `Linux/CMakeLists.txt` 针对 GNUstep 编译的十二个框架，
CLI 是它们旁边的一个目标。§4.1 交给 `MAD`
框架的部分——刷新链——已移到那里，而它未预见到的部分——
`MADocument`，一个 `UIDocument`，`MADCLIDocument` 曾建于其上——由
`MADDocumentDataProtocol` 背后的 `MADHeadlessDocument` 回答：同样的数据那一半，没有
文档生命周期，也没有任何要渲染的东西。`inspect`、`schema`、`query` 和 `refresh`
在两个平台上都是同样的源码；`export` 是 PDF，留在 Apple（§5.2、
§9 的分阶段）。macOS 目标仍属于 Track 5.1，但它现在拥有了曾经缺失的接缝和
文档类。

---

## 5. 设计

### 5.1 一个二进制文件，没有框架挡路

`mad` 直接链接无头框架。它不加载应用
包，也绝不能要求在构建阶段存在 Core Data 模型——
测试套件已经撞上过这一约束（参见项目记忆中关于
`MADTestReportFormatter` 的注释）。

### 5.2 刷新动词复用已度量的路径

`mad refresh` 必须调用应用所调用的同一份代码：
`MADOperationRefresh` → `MADDatabase executeSQL:fieldKeys:onConnection:intoResultTable:`
→ `<MADDataTableWriting>`。它绝不能重新实现它。在
`MADDataTableFastBenchmarkTests` 中添加的基准在 200,000 行时正是度量这条路径
（1.16 秒摄入，2.5 MB 瞬时内存），因此使其退化的 CLI 会表现为
失败的测试，而不是用户投诉。

### 5.3 导出是协议，不是 switch

`MAD_FORMAT.md` 描述文档；文档包含报表元素。导出应该
是一个可扩展点，符合项目所声明的目标——开发者“创建新的
文档导出格式（例如导出为 PDF 和 JSON）”。定义
`<MADReportExporting>` 及一个方法并注册实现，这样 `--format json`
就是一个新类，而不是 switch 中的一个新分支。

**已于 2026-10-16 完成**，形式与 §5.1 的驱动注册表已有的一致：`MADReportExporting.h` 是
协议（格式名、扩展名、是否需要 `--out`、此构建能否
产出它，以及一个导出方法），`MADReportExporterRegistry` 是查找表，每个
导出器在 `+load` 中注册自身——因此一个进程有哪些格式取决于它链接了什么，
而 CLI 按名称请求其中一个。`text`、`csv` 和 `json` 是框架自有的
（`MADReportExporterText/CSV/JSON`，纯 Foundation，两个平台）；
`MADReportExportSource` 是把文档作为列和行读取的唯一位置，因此各
格式不能对“文档是什么”有分歧；`MADReportExportWriter` 是字节到达文件或标准输出的
唯一位置。

`json-report`、`html` 和 `html-flow` 也在接缝上，构建于渲染那一半的
协议（`MADDocumentRenderProtocol`：一个能准备其行、格式化并
交出格式化器的文档）之上，以及同一次页面遍历（`MADReportPageBuilder`）之上。**`pdf` 现在也在
接缝上**：`MADReportExporterPDF` 在每个平台注册，其主体是
Core Graphics 的（Apple 的），在非 Apple 上它返回 `+isAvailable NO` 并给出原因
（`MAD_LINUX.md` §10.2：Linux 写出器是下一步）。CLI 已没有本地分支；
每个格式，包括 `pdf`，都在注册表中查找。

### 5.4 凭据

CLI 绝不能提示。它接受 `--credentials`，或读取应用写入的钥匙串，
或失败并返回退出码 3。`--no-keychain` 的存在是为了让测试
运行无法读取或写入开发者的真实凭据。

### 5.5 运行它：Linux 镜像

`Linux/build.sh --runtime` 构建 `mad-cli:latest`，一个仅运行时层，其中包含
PATH 上的 CLI、它链接的共享库，以及 Sqlite3 样本数据库——没有
编译器、源码或测试二进制文件（磁盘上 283 MB；`Linux/README.md` 有
内容清单）。文档是挂载的，不是存储的：

	docker run --rm -v "$PWD/CLI/Fixtures":/docs:ro mad-cli:latest \
		mad inspect /docs/London.portable.mad
	docker run --rm -v "$PWD/CLI/Fixtures":/docs:ro mad-cli:latest \
		mad refresh /docs/MySQL.employees.mad --credentials root:root --rows 50

该镜像已发布（2026-10-26，推翻了早先不发布的
决定），名称为 `ghcr.io/mthomason/mad`，标签为 `latest` 和提交的短
SHA，由 `.github/workflows/publish-image.yml` 在每次推送到 master 时推送
（外加 `workflow_dispatch`）。已发布的标签是 **linux/amd64**，由
CI 在 ubuntu-latest 上构建；Mac 本地的 `mad-cli:latest` 是 arm64，在
Apple silicon 上使用已发布标签需要 `--platform linux/amd64`（在
模拟下运行；不加该标志拉取会失败并提示 `no matching manifest`）。
通过已发布镜像执行同样的动词：

	docker run --rm --platform linux/amd64 -v "$PWD/CLI/Fixtures":/docs:ro \
		ghcr.io/mthomason/mad mad inspect /docs/London.portable.mad

Sqlite3 文档会针对每用户
Application Support 目录解析其存储的数据库名，在镜像中该目录是
`/root/GNUstep/Library/ApplicationSupport`；`chinook.sqlite3` 就在那里，
因此 London 和 Music fixture 无需设置即可刷新。行缓存
位于同一主目录下且每容器独立；每次导出都会刷新
文档本身，因此缓存无需在运行之间持久化。已发布镜像中的 LGPL
组件要求提供重新链接要约；`ThirdParty/Licenses/README.md` 中的书面要约
点明了该镜像（`THIRD_PARTY_LICENSES.md`
§9 是登记条目）。

`Linux/build.sh --verify` 重建镜像并运行可重复检查：对 fixture 执行全部
六个动词、每个格式的锁定摘要、`pdf` 的拒绝、写出器的字节
和退出码（`Linux/verify-cli.sh`；`--live` 增加三个
实时数据库）。

---

## 6. 测试

格式和 CLI 由**往返 fixture** 锁定，而非依赖文字叙述：

1. **容器保真。** 解包 `Music.mad` 和 `London.mad`，重新打包，并
   断言成员列表和每个成员的字节不变。这锁定
   `MAD_FORMAT.md` §2 并立即捕获 H4（隐藏文件）。**已于
   2026-10-16 落地**，即 `Linux/Tests/MADArchiveManagerTests.m` 的往返——`mad write`
   现在在两个平台上写出容器——其中可复现模式的字节
   与 Mac 的锁定。
2. **v0 可读性。** 对两个随附样本执行 `mad inspect` 必须成功并报告
   `MAD_FORMAT.md` §2 中的值——包括未检查点的 WAL，这正是
   证明 WAL 隐患被报告而非被忽略的断言。
3. **无缓存往返。** 打开文档、刷新、导出、关闭、重新打开。第二次
   打开必须不需要网络。这锁定格式文档的 §5——即
   缓存是派生的且外部的。
4. **规模。** 针对本地 SQLite 来源执行 `mad refresh --rows 200000`，断言
   基准所用的同样上限，因此 CLI 无法悄悄变成
   慢路径。
5. **退出码。** §3 表每一行一个测试，由刻意破坏的
   输入驱动。

fixture 与它们所测试的样本放在一起。需要实时 MySQL、SQL Server
或 PostgreSQL 服务器的测试在不可达时会**跳过**，遵循
`MADMySQLLiveTests.m`、`MADTdsClientLiveTests.m` 和
`MADPostgresLiveTests.m` 中的既有约定。

---

## 7. 分阶段

| 阶段 | 交付物 | 依赖 |
|---|---|---|
| 0 | `MAD_FORMAT.md`、`MAD_CLI.md`、`LIBRARIES.md` | -- |
| 1 | 库构建系统，固定 sqlite 标志 | Phase 0 |
| 2 | 按 SDK 搜索路径；接线 macOS 切片 | Phase 1 |
| 3 | 无头子集；`MADOperationRefresh` 移到 `MAD` | Phase 2 |
| 4 | `mad` 目标：`inspect`、`schema`、`query` | Phase 3 |
| 5 | `mad refresh` | Phase 4 |
| 6 | `mad export`（先 PDF） | Phase 5 |
| 7 | 将往返 fixture 接入测试矩阵 | Phase 6 |

Phase 4-6 按依赖排序，而非按难度：`inspect` 只需要
容器，`query` 需要文档模型，而 `refresh` 需要数据库
连接。

---

## 8. 未决问题

1. **CLI 会发布吗，还是开发者工具？** 这决定它是否需要
   代码签名、公证和安装器，以及 `--credentials` 是否可以
   接受明文参数，还是必须接受文件描述符。
2. **`mad` 是否应接受来自外部文件的行缓存？** 打包的 `.mad`
   （格式文档 §8.3）将使离线导出成为可能。目前还没有任何东西需要它。
3. **JSON 导出形态是什么？——已于 2026-10-16 回答：两者都要，报表那一半作为
   自己的格式。** `--format json` 是数据契约，`--format json-report`
   把渲染后的报表作为额外成员加入。形态在
   `MADReportExporterJSON.h`，由 `MADReportExporterJSON`（数据那一半，
   两个平台）和 `MADReportExporterJSONReport`（报表成员，即
   渲染那一半所在）实现。其列就是查询自身的列，按 SELECT
   列表定义的顺序——列别名，排序后（`BUGS.md`，SELECT 列表条目）——
   而值保留其 JSON 类型：数字是数字，NULL 是 `null`，日期是
   ISO 8601，二进制是 base64。
