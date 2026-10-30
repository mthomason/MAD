---
layout: default
lang: zh-CN
---

# `mad`——MAD Designer 命令行界面

本文定义一个命令行工具，无需用户界面即可打开、检查、刷新和导出 `.mad` 文档。

它之所以存在，是因为应用无法到达它需要去往的两个地方。它无法作为 Mac 应用在 Mac 上运行，也完全无法在 Windows 上运行，因为它的整个呈现层都是 UIKit。CLI 这些都不需要：数据路径——打开文档、运行查询、填充缓存、渲染报表——已经几乎完全不依赖 UIKit（参见 §4）。因此先构建 CLI 并不是绕开平台工作的弯路；它**就是**平台工作，只是按每一步都能产出可用成果的顺序来做。

---

## 1. 范围

**范围内。** 单个二进制文件 `mad`，它可以：

- 打开 `.mad` 文档并报告其中有什么
- 打印文档所依据的数据库架构
- 以 SQL 形式打印文档定义的查询
- 连接源数据库，运行查询并填充行缓存
- 导出渲染后的报表

**刻意排除在范围之外。** 任何编辑文档的功能。CLI 读取并运行文档，但不设计它们。参数解析、动词和退出码就是全部接口。

---

## 2. 为什么先做 CLI

| | CLI | Mac 应用 |
|---|---|---|
| 需要 UI 工具包 | 否 | AppKit（重写）或 Catalyst（已否决） |
| 需要框架可移植 | **是** | 是 |
| 需要行缓存可移植 | **是** | 是 |
| 需要定义 `.mad` | **是** | 是 |
| 交付你要求的东西 | 是 | 是 |
| 格式变化时会白费的工作 | 无 | UI |

Mac 应用要想存在所需的一切——可移植的框架、已定义的文件格式、为多个平台构建的库——CLI 都需要先具备。先做 UI 移植，只会是以昂贵的方式再发现同样的问题。Mac 应用仍是日后另行决定的事项，届时框架已经可移植。

---

## 3. 命令接口

```
mad <command> [options] <document.mad>
```

### `mad inspect <doc.mad>`

仅读取容器。不连接数据库，不使用 Core Data。

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

这是证明 `MAD_FORMAT.md` §7 已实现的动词：它必须能在 v0 样本上工作。它也是让格式隐患可见的动词——H2（未做检查点的 WAL）会被报告出来，而不是被默默忍受。

### `mad schema <doc.mad>`

打印文档定义中捕获的数据库架构：驱动、按名称排序的表，以及每个表的字段及其显示类型和 `pk` 标记。它读取创建时存储的快照，因此不需要凭据，也不需要源数据库。（这里最初的计划是输出 SQL `CREATE TABLE`；快照存储的是 `MADDataType` 抽象，而不是每种源方言的类型名，因此忠实的 `CREATE TABLE` 需要一套按方言的映射，而这目前还不存在。在那之前，工具产出的是这份可读的列表。）

### `mad query <doc.mad>`

打印文档查询生成的 SQL，但不运行它。这是应用赖以构建的核心功能——用户组装表、连接和筛选条件，软件写出 SQL——因此把它暴露出来是自然的第一个非平凡动词。

```
$ mad query London.mad --format sql
SELECT ... FROM ... WHERE ...
```

### `mad refresh <doc.mad>`

连接源数据库，运行查询并填充行缓存。这是数据路径，也是其余一切所依赖的动词。

```
$ mad refresh London.mad --credentials user:pass
refreshed 148,392 rows in 1.21 s (122,638 rows/s)
cache  ~/Library/Caches/MADDesigner/<id>/<tag>.maddb
```

选项：`--credentials`、`--host`、`--port`、`--database`、`--no-cache`（运行但不持久化）、`--rows N`（在 N 行后停止，用于冒烟测试）。

`--rows` 之所以存在，是因为它让该动词可以在 CI 中针对在线服务器测试，而不必拉取上百万行；也因为 `MADDataTableFastBenchmarkTests` 中的基准测试已经证明该路径在大规模下是可度量的。

### `mad export <doc.mad>`

渲染报表并将其写出。

```
$ mad export London.mad --format pdf  --out London.pdf
$ mad export London.mad --format json --out -          # to the standard output
```

这些格式属于导出接缝（§5.3）：每个格式都是一个向 `MADReportExporterRegistry` 注册的类，而用法文本会列出该构建所具备的格式。

| 格式 | 写入内容 | 运行位置 |
|---|---|---|
| `pdf` | 渲染后的报表（页面，已绘制） | Apple：UIKit 的 `UIPrintPageRenderer`、Core Graphics；Linux 会说明为何不能 |
| `html` | 渲染后的报表输出为一个 HTML 文件，每页一个页面盒，由浏览器打印 | 两个平台 |
| `html-flow` | 渲染后的报表输出为可重排的 HTML，每个区段一个表 | 两个平台 |
| `text` | 行输出为定宽表格 | 两个平台 |
| `csv` | 行输出为 RFC 4180 CSV | 两个平台 |
| `json` | 架构和行输出为 JSON（§8.3） | 两个平台 |
| `json-report` | `json` 加上渲染报表的各个区段 | 两个平台 |

对于 Foundation 格式，`--out` 是可选的——缺省或为 `-` 时写入标准输出——而对 `pdf` 则是必需的。对于同一文档，Foundation 格式在 Apple 和 Linux 上写出相同的字节（`Linux/README.md`；两个平台对 London 测试夹具的导出的摘要相等）。

**已定义的顺序。** 导出的分组顺序是该契约的一部分，因此它是已定义的顺序，而不是平台自身的顺序：文本键先按大小写不敏感比较，再按 UTF-8 字节的码点顺序比较。大小写折叠采用 Unicode 17.0.0 的简单（一对一）大小写折叠，以一张签入的表保存（`MADFoundation/Source/NSString+Comparison.m` 中的 `MADStringOrderingTable`，由 UCD 的 `CaseFolding.txt` 中状态为 C/S 的条目生成）——ASCII 和表中所映射的每个 Unicode 对都会折叠；其他一切，包括变音符号，都按自身的码点比较。由于折叠会把每个字母送入小写范围，而该范围排在每个 ASCII 标点字节之后，以标点开头的键（`[1997] Black Light Syndrome`）会排在以字母开头的键（`Core`）之前——与 SQLite 的 `NOCASE` 把它们放在同一位置。UTF-8 保持码点顺序，因此字节比较就是码点比较。一个比较器（`-[NSString mad_orderedCompare:]` 及其 C 核心 `MADStringOrderedCompareUTF8`）驱动全部三处：缓存的 `LSASC` 排序规则、内存中的排序描述符（`MADDataTypeSelectorForSorting`），以及报表格式化器的分组边界比较。该顺序跨平台、跨操作系统版本和跨区域设置都是确定性的；它在 2026-10-25 从本地化顺序改为现在的顺序，因此该日期之前的导出与该日期之后的导出不相等。

**`json-report`**（`MAD_LINUX.md` §10.1、§9 阶段 E）是同样的架构，外加渲染后的报表作为 `report` 成员：页面、每个页面的区段按绘制顺序（类型、分组层级、可见性）、每个区段的行，以及每一行的元素种类、位置框和解析后的文本。它是测试和渲染器所读取的内容，而且它就是渲染器自身的结构——不做任何绘制的页面遍历——因此它不会偏离 PDF 所显示的内容。位置框是这一行**在页面上**所在之处（元素的位置框按其区段偏移），这正是渲染器或浏览器所需要的。渲染那一半现在已在 Linux 上编译，因此该格式在两个平台上都能运行。

**`html`** 是可供浏览器打印的页面形态产物：每个遍历到的页面一个 CSS 页面盒，每个元素绝对定位在其位置框处，其解析后的文本使用元素自身的字体、字号、字重、倾斜、装饰和对齐。换行规则采用渲染器的规则（`NSLineBreakByTruncatingTail` -> `white-space: pre; overflow: hidden; text-overflow: ellipsis`）。它是一个 UTF-8 文件，内嵌样式块，不含脚本。**`html-flow`** 是同一份报表去掉分页：每个报表区段一个 `<section>`，每个区段一个 `<table>`，每个元素一个 `<td>`，页面附属物只输出一次，并为每种不同的元素样式生成一个类。它是阅读视图；`json` 才是数据契约。两者都不携带颜色（存储的颜色列目前在两个平台上都没有读取方），在 Linux 上也不携带图像（Apple 路径从 `UIImage` 绘制图像；Linux 导出会放置空框）。

渲染为 PDF 经由 `MADPrintPageRenderer`；分享面板包装 `MADActivityItemProviderPdf` 是它的另一个调用方，`MADActivityItemProviderDelegate.h` 是它与外界通信的协议。三者都位于 `MAD` 框架中，而不是应用中。PDF 所不具备的，是**无头**能力：它是 UIKit 的 `UIPrintPageRenderer`，这就是为什么它是唯一仍实现在 CLI 一侧的格式（参见 §5.3）。

### `mad write <doc.mad> --out <copy.mad>`

将文档作为 `.mad` 写出——是一份*副本*：文档读入时所用的 guts 目录，再次以 v1 文件头归档。它不会编辑所读取的文档，CLI 也仍然不设计文档（§1）；这个动词的用途是字节一致性要求——同一文档在两个平台上写出必须是同一个文件——以及 §6.1 的往返测试夹具，后者需要一个脚本能运行的写入器。

```
$ mad write London.portable.mad --out copy.mad --reproducible
wrote /tmp/copy.mad (16261 bytes, reproducible)
```

`--reproducible` 固定了那些否则会被时钟和文件系统烙进归档的东西：固定的修改时间（2001-01-12T00:00:00Z，即 PDF 导出固定其日期的那个时刻）、所有者和组为 0，以及按序排列的成员遍历（`MADArchiveManager.reproducible`）。不使用它时，写出的是普通保存，带有成员的真实元数据。两个平台都以无头方式打开文档（`MADHeadlessDocument`），因此比较的双方运行同一个写入器，同一文档在那里写出相同的字节（London 夹具为 16,261 字节，`Linux/README.md`）。

### 全局选项

| 选项 | 含义 |
|---|---|
| `--verbose` | 在每个阶段记录数据路径日志 |
| `--quiet` | 除结果外抑制一切输出 |
| `--credentials user:pass` | 源数据库凭据；否则使用钥匙串 |
| `--host <name>` | 源数据库主机覆盖（refresh、export） |
| `--port <n>` | 源数据库端口覆盖，1-65535（refresh、export） |
| `--database <name>` | 源数据库名称覆盖（refresh、export） |
| `--no-keychain` | 从不访问钥匙串 |
| `--format <name>` | 输出格式 |
| `--out <path>` | 输出路径；默认标准输出 |
| `--deterministic` | 固定导出的日期和标识符，使对未变更数据的两次运行字节相同 |
| `--reproducible` | 固定 `.mad` 归档的输入——时间、所有权、成员顺序（`write`） |

连接定义——主机、端口和数据库名——是文档可移植存储的一部分；用户名和密码则从来不是。`--host`、`--port` 和 `--database` 仅本次运行覆盖所存储的连接，因此一份签入的文档无需改写即可针对 CI 服务容器运行。未给出的项保持其存储值。对于连接本身是一个文件的 Sqlite3 文档，它们会被拒绝；在不连接数据库的动词（`inspect`、`schema`、`query`、`write`）上，它们只是不被使用。凭据始终走 `--credentials`；存储中不保存用户名或密码。

### 退出码

| 代码 | 含义 |
|---|---|
| 0 | 成功 |
| 1 | 用法错误 |
| 2 | 文档无法读取，或不是 `.mad` |
| 3 | 源数据库不可达，或凭据被拒绝 |
| 4 | 查询在服务器上失败 |
| 5 | 导出失败 |

不同的代码很重要，因为这个工具的第一个真实用途是脚本，而脚本需要区分“文档有问题”和“服务器宕机”。

---

## 4. 构建 CLI 之前必须存在什么

数据路径已经几乎不依赖 UIKit。这是实测，不是估算：

| 框架 | 导入 UIKit 的文件 | CLI 所需 |
|---|---|---|
| `MADDataStructures` | 0 / 37 | 是 |
| `MADFileManager` | 0 / 31 | 是 |
| `MADSqlite3` | 0 / 65 | 是 |
| `MADMySQL` | 0 / 42 | 是 |
| `MADTds` / `MADTdsClient` | 0 / 3, 0 / 9 | 是 |
| `Scrimpter` | 0 / 48 | 否 |
| `MADFoundation` | 4 / 66 | 是 |
| `MADAPI` | 3 / 34 | 部分 |
| `MAD` | 28 / 464 | 部分 |

`MADFoundation` 中四个文件承载了基础框架的全部 UIKit 依赖：

| 文件 | UIKit 用途 | 处置 |
|---|---|---|
| `MADApplication.{h,m}` | 一个 `UIApplication` 包装 | CLI 不需要；从无头目标中排除 |
| `MADURLFactory.m:32` | `UIScreen.mainScreen.scale > 1.0` | 一处调用；非 iOS 时返回 2.0 |
| `MADOperation.m:550-563` | `beginBackgroundTaskWithName:` | 一项功能，由 `#if TARGET_OS_IPHONE` 保护 |

作者已经标记了最后一处（`MADOperation.m:21`）：*“但愿我不必在这里导入 UIApplication，但这确实是最干净的方式。”* 对无头构建来说，这并不是最干净的方式，而这也是基础框架中唯一出现这种情况的地方。

`MADAPI` 的三个 UIKit 文件是连接的*视图控制器*，完全不属于无头目标。

### 4.1 刷新核心必须迁移

唯一实质性的工作就是这一项。刷新编排**位于应用目标中，而不在框架中**：

| 文件 | 行数 | UIKit 符号 | 作用 |
|---|---|---|---|
| `MADDesigner/Source/MADOperationRefresh.m` | 131 | **0** | 构建 SQL、运行 SQL、写入缓存 |
| `MADDesigner/Source/MADOperationRefreshReload.m` | 196 | 3 | UI 侧重载 |
| `MADDesigner/Source/MADRefreshOperationReload.m` | 132 | 1 | UI 侧重载 |

`MADOperationRefresh.m` 只导入 `MADAPI`、`MADFoundation` 和 `MAD`，不涉及任何 UIKit。它已经是 CLI 的 refresh 动词；只是待在了错误的目标中。它迁移到 `MAD` 框架，而两个 `Reload` 操作留在应用中，这正是它们的名称一直所表明的。

### 4.2 无头目标

一种 `MADFoundation`、`MADAPI` 和 `MAD` 的构建配置，可在没有 UIKit 的情况下编译，外加 CLI 目标本身。从机制上说，就是把 `SUPPORTED_PLATFORMS` 扩展到包含 `macosx`、采用 `LIBRARIES.md` §6 中按 SDK 的库搜索路径，以及上文的三处文件级排除。

**2026-10-16 在 Linux 上完成**（`MAD_LINUX.md` §9 阶段 D），并且是这样完成的：无头目标就是由 `Linux/CMakeLists.txt` 针对 GNUstep 编译的十个框架，CLI 是它们旁边的一个目标。§4.1 指派给 `MAD` 框架的部分——刷新链——迁移到了那里；而它没有预料到的部分——`MADocument`，一个 `UIDocument`，`MADCLIDocument` 正是建立在它之上——由 `MADDocumentDataProtocol` 背后的 `MADHeadlessDocument` 作答：同样的数据那一半，没有文档生命周期，也没有任何需要渲染的东西。`inspect`、`schema`、`query` 和 `refresh` 在两个平台上使用相同的源代码；`export` 是 PDF，留在 Apple 上（§5.2，§9 的分阶段）。macOS 目标仍属于 Track 5.1 的任务，但它现在有了此前缺失的接缝和文档类。

---

## 5. 设计

### 5.1 单一二进制，框架不挡路

`mad` 直接链接无头框架。它不加载应用包，也绝不能要求在构建阶段存在 Core Data 模型——测试套件已经撞上过这一约束（见项目记忆中关于 `MADTestReportFormatter` 的说明）。

### 5.2 refresh 动词复用已度量的路径

`mad refresh` 必须调用应用所调用的同一份代码：`MADOperationRefresh` → `MADDatabase executeSQL:fieldKeys:onConnection:intoResultTable:` → `<MADDataTableWriting>`。它不得重新实现。`MADDataTableFastBenchmarkTests` 中加入的基准测试正是以 200,000 行度量这条路径（1.16 s 摄取，2.5 MB 瞬时内存），因此让它退化的 CLI 会表现为失败的测试，而不是用户的抱怨。

### 5.3 导出是协议，不是 switch

`MAD_FORMAT.md` 描述文档；文档包含报表元素。导出应当是一个可扩展点，与项目所声明的目标相符，即开发者“创建新的文档导出格式（例如导出到 PDF 和 JSON）”。定义一个只有一个方法的 `<MADReportExporting>` 并注册实现，这样 `--format json` 就是一个新类，而不是 switch 中的一个新分支。

**2026-10-16 完成**，形态与 §5.1 的驱动注册表已有的形态一致：`MADReportExporting.h` 是协议（格式名、扩展名、是否需要 `--out`、当前构建能否产出该格式，以及一个导出方法），`MADReportExporterRegistry` 负责查找，每个导出器在 `+load` 中自我注册——因此一个进程具备哪些格式取决于它链接了什么，而 CLI 按名称请求其中之一。`text`、`csv` 和 `json` 是框架自带的（`MADReportExporterText/CSV/JSON`，纯 Foundation，两个平台）；`MADReportExportSource` 是把文档读成列和行的唯一一处，因此各格式不可能对“文档是什么”产生分歧；`MADReportExportWriter` 是把字节写到文件或标准输出的唯一一处。

`json-report`、`html` 和 `html-flow` 也在接缝上，建立在渲染那一半的协议（`MADDocumentRenderProtocol`：一个能准备好其行、格式化并交出格式化器的文档）和同一个页面遍历（`MADReportPageBuilder`）之上。**`pdf` 现在也在接缝上**：`MADReportExporterPDF` 在所有平台注册，其主体是 Core Graphics 的（Apple 的），在非 Apple 平台上它以原因回答 `+isAvailable NO`（`MAD_LINUX.md` §10.2：Linux 写入器是下一步）。CLI 已不剩任何本地分支；每个格式，包括 `pdf`，都在注册表中查找。

### 5.4 凭据

CLI 绝不能提示输入。它接受 `--credentials`，或读取应用写入的钥匙串，否则以退出码 3 失败。`--no-keychain` 的存在是为了让测试运行无法读写开发者的真实凭据。

### 5.5 运行它：Linux 镜像

`Linux/build.sh --runtime` 构建 `mad-cli:latest`，一个仅含运行时的层，其中 CLI 位于 PATH 上，带有它链接的共享库和 Sqlite3 示例数据库——没有编译器、源代码或测试二进制文件（磁盘上 283 MB；内容见 `Linux/README.md`）。文档是挂载的，不是存储的：

	docker run --rm -v "$PWD/CLI/Fixtures":/docs:ro mad-cli:latest \
		mad inspect /docs/London.portable.mad
	docker run --rm -v "$PWD/CLI/Fixtures":/docs:ro mad-cli:latest \
		mad refresh /docs/MySQL.employees.mad --credentials root:root --rows 50

该镜像已发布（2026-10-26，推翻了早先“不发布”的决定），名称为 `ghcr.io/mthomason/mad`，标签为 `latest` 和提交的短 SHA，由 `.github/workflows/publish-image.yml` 在每次推送到 master 时推送（外加 `workflow_dispatch`）。发布的标签是 **linux/amd64**，由 CI 在 ubuntu-latest 上构建；Mac 本地的 `mad-cli:latest` 是 arm64，在 Apple silicon 上使用已发布标签需要 `--platform linux/amd64`（在模拟下运行；不带该标志时拉取会失败并报 `no matching manifest`）。同样的动词在已发布镜像上：

	docker run --rm --platform linux/amd64 -v "$PWD/CLI/Fixtures":/docs:ro \
		ghcr.io/mthomason/mad mad inspect /docs/London.portable.mad

Sqlite3 文档会依据每用户的 Application Support 目录解析其存储的数据库名，在镜像中该目录是 `/root/GNUstep/Library/ApplicationSupport`；`chinook.sqlite3` 就在那里，因此 London 和 Music 夹具无需额外设置即可刷新。行缓存位于同一个 home 目录之下，且是每容器各自的；每次导出都会刷新文档本身，因此缓存不必在多次运行之间持久保留。已发布镜像中的 LGPL 组件负有提供重链接要约的义务；`ThirdParty/Licenses/README.md` 中的书面要约点名了该镜像（`THIRD_PARTY_LICENSES.md` §9 是登记条目）。

`Linux/build.sh --verify` 重建镜像并运行可重复的检查：在夹具上运行全部六个动词、每个格式固定的摘要、`pdf` 的拒绝、写入器的字节以及退出码（`Linux/verify-cli.sh`；`--live` 增加三个在线数据库）。

---

## 6. 测试

格式和 CLI 由**往返测试夹具**固定，而不是靠文字描述：

1. **容器保真。** 解包 `Music.mad` 和 `London.mad`，重新打包，并断言成员列表和每个成员的字节均未改变。这固定了 `MAD_FORMAT.md` §2，并立刻捕获 H4（隐藏文件）。**2026-10-16 落地**，即 `Linux/Tests/MADArchiveManagerTests.m` 的往返测试——`mad write` 现在在两个平台上写出容器——可重现模式的字节以 Mac 的为准固定。
2. **v0 可读性。** 对两个随附样本运行 `mad inspect` 必须成功，并报告 `MAD_FORMAT.md` §2 中的值——包括未做检查点的 WAL，这正是证明 WAL 隐患被报告而不是被忽略的断言。
3. **无缓存往返。** 打开文档、刷新、导出、关闭、重新打开。第二次打开必须不需要网络。这固定了格式文档的 §5——缓存是派生的且外部的。
4. **规模。** 针对本地 SQLite 源运行 `mad refresh --rows 200000`，按基准测试所用的同一上限断言，这样 CLI 就不会悄悄变成慢路径。
5. **退出码。** §3 表格的每一行一个测试，由刻意损坏的输入驱动。

夹具放在它们所测试的样本旁边。需要在线 MySQL、SQL Server 或 PostgreSQL 服务器的测试在无法连接时**跳过**，遵循 `MADMySQLLiveTests.m`、`MADTdsClientLiveTests.m` 和 `MADPostgresLiveTests.m` 中的既有惯例。

---

## 7. 分阶段

| 阶段 | 交付物 | 依赖 |
|---|---|---|
| 0 | `MAD_FORMAT.md`、`MAD_CLI.md`、`LIBRARIES.md` | 无 |
| 1 | 库构建系统，固定 sqlite 标志 | 阶段 0 |
| 2 | 按 SDK 的搜索路径；接通 macOS 切片 | 阶段 1 |
| 3 | 无头子集；`MADOperationRefresh` 迁移到 `MAD` | 阶段 2 |
| 4 | `mad` 目标：`inspect`、`schema`、`query` | 阶段 3 |
| 5 | `mad refresh` | 阶段 4 |
| 6 | `mad export`（PDF 优先） | 阶段 5 |
| 7 | 往返测试夹具接入测试矩阵 | 阶段 6 |

阶段 4-6 按依赖排序，而不是按难度：`inspect` 只需要容器，`query` 需要文档模型，而 `refresh` 需要数据库连接。

---

## 8. 未决问题

1. **CLI 是随产品发布，还是开发者工具？** 这决定了它是否需要代码签名、公证和安装器，以及 `--credentials` 是否可以接受明文参数，还是必须接收文件描述符。
2. **`mad` 是否应接受来自外部文件的行缓存？** 打包的 `.mad`（格式文档的 §8.3）将使离线导出成为可能。目前还没有任何东西需要它。
3. **JSON 导出的形态是什么？——2026-10-16 已作答：两者都有，报表那一半作为独立格式。** `--format json` 是数据契约，`--format json-report` 把渲染后的报表作为额外成员加入。形态见 `MADReportExporterJSON.h`，由 `MADReportExporterJSON`（数据那一半，两个平台）和 `MADReportExporterJSONReport`（报表成员，渲染那一半所在之处）实现。其列就是查询自身的列，按 SELECT 列表所定义的顺序——按列别名排序（`BUGS.md`，SELECT 列表条目）——而值保持其 JSON 类型：数字是数字，NULL 是 `null`，日期是 ISO 8601，二进制是 base64。
