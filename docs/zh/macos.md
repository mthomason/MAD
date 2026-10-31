---
layout: default
title: 适用于 macOS 的 MAD Designer
description: >-
  适用于 SQLite、MySQL、MariaDB、PostgreSQL 和 SQL Server 的原生 macOS（AppKit）关系型报表设计器与查看器——可视化查询画布、带缩略图的带区报表设计器，以及 PDF/HTML/CSV/JSON 导出。
image: /assets/macos-native-mad-designer.png
lang: zh-CN
---

# <a href="https://raw.githubusercontent.com/mthomason/MAD/master/StaticResources/Images/icons/document/Designer%20Icon@3x.png"><img src="../assets/mad-designer-macos-icon-256.png" alt="适用于 macOS 的 MAD Designer 图标" width="48" height="48" style="vertical-align: middle; margin-right: 10px;" /></a>适用于 macOS 的 MAD Designer

**MAD Designer for macOS** 是一款原生 `AppKit` 桌面应用（`macosx` SDK，`MACOSX_DEPLOYMENT_TARGET = 12.0`），用于创建、查询、布局、刷新、打印和导出移动分析文档（`.mad`）。它链接与 iOS 应用和无头引擎相同的第一方 Objective-C 框架和通用静态 C 库（`Compressor`）。

在 macOS 上创建或编辑的每个 `.mad` 文件，都与 iPad/iPhone 应用、Linux 上的 `mad` CLI 以及 [`mad-action`](https://github.com/mthomason/mad-action) GitHub Action 字节兼容。

---

## 工作区

每个打开的 `.mad` 文档都运行在一个原生 `NSDocument` 窗口（`MADMacDocument` / `MADMacWindowController`）中，窗口工具栏中央有一个 **Workspace** 分段控件（`Cmd+1`、`Cmd+2`、`Cmd+3`），用于在三个报表阶段之间切换：

### 1. MAD Query（`Cmd+1`）

![macOS 上的 MAD Query 工作区，显示数据库表列表、可视化表卡片和 LEFT OUTER 连接线](../assets/macos-native-mad-query.png)

**MAD Query** 工作区（`MADMacQueryViewController`）构建存储在 `RptqQuery` 中的关系查询图。工作区栏中的切换开关在查询的两种互斥视图之间切换：

* **查询设计器（可视化图）：**
  * **数据库表侧边栏：** 显示导入到文档架构快照（`RptqDatabaseSchemaTable`）中的每一张表，并标出列数，以及当前参与查询的表的勾选标记。双击任意表（或点击 **+ Add Table to Query**）即可将其添加到画布。
  * **交互式关系画布（`MADMacQueryCanvasView`）：** 将每张查询表渲染为点阵画布上可拖动、可调整大小的卡片（`MADMacQueryTableCardView`），其样式使用由 `MTGraph` 计算出的拓扑根/子节点头部颜色。
  * **可视化连接线（`MADMacQueryLinksOverlayView`）：** 从一张表卡片中的列拖到另一张表卡片中的列会创建连接（默认为 `LEFT OUTER`），以平滑的三次贝塞尔曲线、方向箭头和胶囊徽标绘制。点击或右键点击连接徽标会打开连接检查器弹出框或上下文菜单，用于更改连接类型（`INNER`、`LEFT OUTER`、`RIGHT OUTER`、`FULL OUTER`、`CROSS`）、反转连接方向或删除该连接。
  * **筛选、分组与自动布局：** 标题栏弹出框用于编辑 **`WHERE` 谓词**（`Filters (WHERE)`）、**`GROUP BY` / 排序顺序**（`Groupings (GROUP BY)`——它会自动配置匹配的 `Group Header` 和 `Group Footer` 布局带区），以及用于自动拓扑排列卡片的 **Arrange Tables**。
* **SQL 查询（直接输入与检查 SQL）：**
  * 显示从可视化图生成的目标方言确定性 SQL，并允许直接粘贴或编辑 `SELECT` 语句。
  * 通过 `MADSQLParser`、`MADSQLStatementResolver` 和 `MADSQLQueryCompiler` 校验输入的 SQL 并将其编译回可移植的 `RptqQuery` 对象图，同时把该语句保存在 `RptqQuery.sqlSourceText` 中。

---

### 2. MAD Designer（`Cmd+2`）

![macOS 上的 MAD Designer 工作区，显示页面与节区缩略图、报表带区、查询字段、带区设计画布和检查器](../assets/macos-native-mad-designer.png)

**MAD Designer** 工作区（`MADMacDesignerViewController`）在用户可调整大小的三栏分割视图中布置报表的参数化带区和元素：

* **设计器顶部工具栏：**
  * **元素面板：** 点击或拖放到任意节区带区上，以插入 **Label**、**Data Field**、**Aggregate**、**Barcode**、**Image** 或 **Line**。
  * **对齐与尺寸：** 多元素对齐按钮（`Align Left`、`Center`、`Right`、`Top`、`Middle`、`Bottom`）以及 **Size to Fit**。
  * **画布控件：** **Grid**、**Snap** 和 **Rulers** 的独立开关，以及带一键 `100%` 复位的连续 **Zoom** 滑块（`50%–250%`）。
* **左侧导航侧边栏：**
  * **页面与节区缩略图（`MADMacDesignerMinimapView`）：** 实时、按比例的鸟瞰图，显示所有报表带区、元素缩略块和当前滚动视口矩形。在缩略图内点击或拖动可跳转到并选择任意带区。
  * **报表带区大纲：** 列出 `Report Header`、`Page Header`、任意 `Group Header` / `Group Footer` 带区、`Report Detail`、`Page Footer` 和 `Report Footer`，并显示元素数量、点高度和分页指示器。双击某一行可切换该节区的可见性。
  * **查询字段浏览器：** 查询中所有 `RptqQueryField` 列的可筛选列表。将任意字段直接拖到画布上的节区带区（或双击），即可创建绑定的数据字段元素（`RptqDocumentElementLabelDataField`）。
* **中央交互式画布（`MADMacDesignerCanvasView`）：**
  * 翻转、可缩放的 `NSView` 画布，带有水平和垂直点标尺、纸张边距参考线、按颜色区分的节区标题（`RH`、`PH`、`GH`、`DTL`、`GF`、`PF`、`RF`），以及用于调整节区高度的底部拖动手柄。
  * 支持框选、按住 `Shift` 点击多选、8 点缩放手柄、智能对齐参考线、网格吸附、行内双击文本编辑、跨节区拖放（`-moveElement:toSection:atOrigin:`），以及跨单个和批量属性编辑的完整 `NSUndoManager`（`Cmd+Z` / `Cmd+Shift+Z`）撤销/重做。
* **右侧检查器侧边栏：**
  * **`1 · PAGE & SELECTED SECTION`：** 配置目标 **Paper** 大小，显示当前带区徽标，编辑节区 **Height (pt)** 并提供 **Fit Height** 按钮，以及切换 **Section Visible** 和 **Page Break After**。
  * **`2 · SELECTED ELEMENT INSPECTOR`：** 选中元素时显示四张上下文卡片：
    1. **元素与带区分配：** 将元素重新分配到另一个节区带区、复制（`Cmd+D`）或删除（`Delete`）。
    2. **内容与数据绑定：** 静态文本、绑定的查询列（`table.column`）、聚合函数（`SUM`、`COUNT`、`AVG`、`MIN`、`MAX`、`STDDEV`、`VARIANCE`）和作用域（`Report` 或 `Group`）、货币格式或条形码符号体系（`zint`）。
    3. **排版与外观：** 字体家族、点大小、粗体 / 斜体 / 下划线 / 删除线特征、水平和垂直文本对齐、前景色和背景填充。
    4. **位置、尺寸与盒模型：** 精确的点坐标（`X`、`Y`、`W`、`H`）、边框宽度/颜色、内边距和外边距。

---

### 3. MAD Viewer（`Cmd+3`）

**MAD Viewer** 工作区（`MADMacViewerViewController`）针对实时数据源刷新查询，把结果集物化到本地 SQLite 表缓存（`MADDataTableFast`）中，并渲染分页页面：

* **查看器工具栏：**
  * **页面大小选择器（`MTPaper`）：** 立即为 **US Letter**、**US Legal**、**US Tabloid**、**A3**、**A4**、**A5**、**B4**、**B5**、**JIS B4** 或 **JIS B5** 重新分页并重新渲染报表。
  * **刷新（`Cmd+R`）：** 通过文档注册的数据库驱动执行查询，填充 `.maddb` / `.mdcache` 伴随 SQLite 缓存，计算两趟分组和聚合，并重建页面缓存。
  * **缩放与页面导航：** 缩小、复位到 `100%`、放大，以及逐页前进（`Previous`、`Page N of M`、`Next`）。
  * **打印（`Cmd+P`）与导出（`Cmd+E`）：** 通过 `NSPrintOperation` 原生打印，或打开带格式选择器的 `NSSavePanel`，覆盖全部七个已注册导出器：
    * **PDF 文档（`.pdf`）**——通过 `MADReportExporterPDF` 生成原生 CoreGraphics / AppKit 矢量 PDF
    * **HTML 页面（`.html`）**——定位式页面复制（`MADReportExporterHTML`）
    * **HTML 流式（`.html`）**——响应式、可重排的语义 HTML（`MADReportExporterHTMLFlow`）
    * **CSV 表格（`.csv`）**——符合 RFC 4180 的明细行导出（`MADReportExporterCSV`）
    * **JSON 数据（`.json`）**——架构契约 + 明细行（`MADReportExporterJSON`）
    * **JSON 完整报表（`.json`）**——层级化的节区、分组和求值后的元素（`MADReportExporterJSONReport`）
    * **纯文本（`.txt`）**——等宽文本表格（`MADReportExporterText`）
* **带框页面预览与状态栏：** 在原生 `PDFView` 中渲染清晰、带投影的页面，并在底部状态栏中报告已渲染页数、缓存行数和纸张尺寸。

---

## 打开与创建文档

* **启动与打开面板（`MADMacDocumentController`）：** 启动应用时若未打开文件，会显示 macOS 的 **Open Report** 面板，过滤 `.mad` 文档（`com.everydayapps.productivity.mad` 和 `com.thomason.report.mad`），左下角栏中有一个主 **New Document** 按钮。在 Finder 中双击任意 `.mad` 文件，会直接在其工作区窗口中打开。
* **旧版文档迁移：** 打开较早的 Core Data `.mad` 归档时，会通过 `MADStoreConverter` 就地将其存储转换为可移植的 SQLite 架构（`MADStoreSchema`）。
* **从数据库连接新建报表（`Cmd+N`）：** 点击 **New Document**（或选择 **File → New Document…**）会打开数据库连接助手（`MADMacConnectionWindowController`）：
  * 选择 **SQLite**、**MySQL**、**Microsoft SQL Server** 或 **PostgreSQL**。
  * 浏览本地 `.sqlite3` / `.db` 数据库，或输入服务器主机、端口、可选的 SQL Server 实例、数据库名、用户名和密码。
  * 点击 **Test Connection** 验证连接性并查看发现的表数量。
  * 点击 **Create Document…** 将数据库的表和列架构导入新的 `.mad` 文件，并在 **MAD Query** 工作区中打开它。凭据通过 `MADKeyChain` 存储在 macOS 钥匙串中。

---

## 架构：基于多平台框架的原生 `AppKit`

MAD 没有用 Mac Catalyst 包装 iOS UI，而是将十四个框架中的十二个原生编译为 `macosx`（`SUPPORTED_PLATFORMS = "iphoneos iphonesimulator macosx"`，`MACOSX_DEPLOYMENT_TARGET = 12.0`），并在其上放置专门构建的 `AppKit` 文档架构（`Mac/Source/`）：

| 层 | 组件 | 在 macOS 上的角色 |
|---|---|---|
| **静态 C 库（`Compressor`）** | `sqlite3`、`zlib`、`openssl`、`bzip2`、`libpng`、`libarchive`、`freetds`、`mariadb`、`postgres`、`zint` | `.xcframework` 包内的通用（`arm64` + `x86_64`）`macosx` 切片，由 `./Compressor/build.sh --verify --all --platforms ios,simulator,macosx` 验证。 |
| **核心与驱动框架** | `MADFoundation`、`MADDataStructures`、`MADCocoaExtensions`、`MADFileManager`、`MADAPI`、`MADSqlite3`、`MADTds`、`MADTdsClient`、`MADMySQL`、`MADPostgres`、`MADBarcodes`、`MAD` | 共享的 Objective-C 模型、可移植 SQLite 存储（`Rptq*`）、SQL 解析器/编译器、数据库线路驱动、zint 条形码渲染器、`MADDesignerLayout` 撤销/重做引擎，以及 `MADPrintPageRenderer` / `MADReportExporterPDF`。 |
| **原生 `AppKit` 前端（`Mac/`）** | `MADMacAppDelegate`、`MADMacAboutWindowController`、`MADMacDocumentController`、`MADMacDocument`、`MADMacWindowController`、`MADMacConnectionWindowController`、`MADMacQueryViewController`、`MADMacDesignerViewController`、`MADMacDesignerCanvasView`、`MADMacViewerViewController` | 原生 `NSDocument` 生命周期、关于 / 概览 / 致谢窗口、工具栏与菜单栏、可视化查询画布、带缩略图和检查器的三栏报表设计器，以及 `PDFView` 报表查看器。 |

多平台移植的完整架构审计和缺陷日志记录在 [`docs/project/MAD_MACOS.md`](https://github.com/mthomason/MAD/blob/master/docs/zh/project/MAD_MACOS.md)。

---

## 构建、测试与打包

### 在 Xcode 中

打开 `Reports.xcworkspace`，选择 **`MAD Designer Mac`** 共享方案，目标选择 **My Mac**，然后按 **Run（`Cmd+R`）** 以交互方式构建并调试原生 macOS 应用。

要在 macOS 上原生运行任意框架的单元测试套件：

```sh
xcodebuild test -workspace Reports.xcworkspace -scheme MAD \
	-destination 'platform=macOS,arch=arm64' \
	-derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci
```

### 命令行构建、冒烟测试套件与发布打包

独立脚本 `Mac/build.sh` 编译全部十二个 macOS 框架，组装并签名 `Mac/build/MAD Designer.app`，运行端到端无头 + AppKit 冒烟测试套件（`Mac/Tests/MADMacSmokeTest.m`），并打包可分发的 `.zip` 和 `.dmg` 归档：

```sh
./Mac/build.sh                     # build 12 macOS frameworks + MAD Designer.app
./Mac/build.sh --no-frameworks     # rebuild only MAD Designer.app (fast iteration)
./Mac/build.sh --smoke-test        # build and run the end-to-end macOS smoke suite
./Mac/build.sh --package           # package MAD-Designer-macOS.zip and MAD-Designer-macOS.dmg
```
