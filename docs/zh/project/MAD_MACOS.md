---
layout: default
lang: zh-CN
---

# `MAD_MACOS.md` -- 多平台框架与原生 macOS 应用程序

本文档记录了架构决策、逐框架的可移植性审计，以及分阶段的迁移与实施计划，目标是让 MAD 框架真正实现多平台化（`iphoneos`、`iphonesimulator`、`macosx` 以及无头 Linux），并为 **MAD Designer** 构建原生 macOS（`AppKit`）前端。

---

## 1. 决策：原生 macOS（`AppKit`）对比 Mac Catalyst

**决策：** 构建**原生 macOS 应用程序（`macosx` SDK、`AppKit`）**，基于共享的多平台框架（`MACOSX_DEPLOYMENT_TARGET = 12.0`，支持所有 Apple Silicon Mac 以及运行 Monterey 或更新版本的 Intel Mac）。**拒绝 Mac Catalyst。**

### 原生 macOS 胜出的原因

| 维度 | 原生 macOS（`macosx` / `AppKit`） | Mac Catalyst（`maccatalyst` / `UIKit`） |
|---|---|---|
| **静态 C 库（`Compressor`）** | **已构建。** `Compressor/library/` 中全部 10 个 `.xcframework` 捆绑包都带有通用的 `macosx`（`arm64` + `x86_64`，`-mmacosx-version-min=11.0`）切片，并已通过 `./Compressor/build.sh --verify --all --platforms ios,simulator,macosx` 验证。 | **缺失。** 不存在任何 `maccatalyst` 切片（`-target <arch>-apple-ios15.0-macabi`）。Mach-O 链接器拒绝将 `MACOS` 归档链接进 `MACCATALYST` 二进制文件；Catalyst 需要向 `Compressor` 增加第 4 个平台，并重新构建全部 10 个 C 库（`openssl`、`mariadb`、`postgres`、`freetds`、`libarchive`、`sqlite3`、`zint`、`libpng`、`bzip2`、`zlib`）。 |
| **核心引擎可移植性** | **已完成 90%。** Linux 无头移植（`MAD_LINUX.md`）已从 `MAD.framework` 中移除 Core Data，解耦了数据库驱动（`MADDatabaseDriverRegistry`）和报表导出器（`MADReportExporterRegistry`），并引入了 `MADHeadlessDocument`、`MADSQLQueryCompiler` 和 `MADDesignerLayout`。 | 引擎相同，但绑定于 `UIDocument` 和 iOS 后台任务生命周期。 |
| **桌面交互体验** | 原生 `NSDocument` / `NSDocumentController`（Finder 双击、`Cmd+N`、`Cmd+O`、`Cmd+S`、`Cmd+Shift+S`、最近使用的文档、窗口恢复、`NSUndoManager`）、原生分栏视图、原生表格/大纲视图、原生 `PDFView` / `WKWebView`，以及标准 macOS 菜单。 | 嵌套缩放的 `UIScrollView` + `UICollectionView` 分区、iOS 标签栏/导航栏、`UIPickerView` 滚轮，以及 iOS 沙盒文档浏览器（`MADExplorer`）。Apple Silicon Mac 已经可以通过 *Designed for iPad* 运行 iPad 构建。 |
| **通过 GitHub 分发** | 干净的独立 `.app` 包，打包为可下载的 `.dmg` 和 `.zip`，发布在 GitHub Releases 上（`arm64` + `x86_64`）。 | 需要 Catalyst 描述文件和授权，这与 App Store 之外的分发方式不匹配。 |

---

## 2. 静态库审计（`Compressor`）

`Compressor` 中全部十个随附的 C 库都使用 `-mmacosx-version-min=11.0` 构建通用的 `macosx`（`arm64` + `x86_64`）切片：

| 库 | 版本 | `ios`（`arm64`） | `simulator`（`arm64` + `x86_64`） | `macosx`（`arm64` + `x86_64`） | 使用者 |
|---|---|:---:|:---:|:---:|---|
| `sqlite3` | 3.53.3 | 是 | 是 | 是 | `MADSqlite3`、`MAD` |
| `zlib` | 1.3.2 | 是 | 是 | 是 | `MAD`、`MADMySQL`、`MADPostgres`、`MADBarcodes` |
| `openssl` | 3.5.9 | 是 | 是 | 是 | `MADTds`、`MADMySQL`、`MADPostgres` |
| `bzip2` | 1.0.8 | 是 | 是 | 是 | `MAD` |
| `libpng` | 1.6.59 | 是 | 是 | 是 | `MADBarcodes` |
| `libarchive` | 3.8.9 | 是 | 是 | 是 | `MAD` |
| `freetds` | 1.4.27 | 是 | 是 | 是 | `MADTds`、`MADTdsClient` |
| `mariadb` | 3.4.11 | 是 | 是 | 是 | `MADMySQL` |
| `postgres` | 17.11 | 是 | 是 | 是 | `MADPostgres` |
| `zint` | 2.16.0 | 是 | 是 | 是 | `MADBarcodes` |

验证命令：

```sh
./Compressor/build.sh --verify --all --platforms ios,simulator,macosx
```

---

## 3. 逐框架多平台审计

十二个框架构成多平台栈（`iphoneos`、`iphonesimulator`、`macosx`，十一个无头框架还包括 Linux）：

1. **`MADFoundation`**（28 个 `.m` 文件）：
   - `MADApplication.h`：用 `#if TARGET_OS_IPHONE` 而不是 `#if __APPLE__` 来保护 `<UIKit/UIApplication.h>`（`MADApplication.m` 已经有 `#elif TARGET_OS_OSX #import <AppKit/NSApplication.h>`）。
   - `MADURLFactory.m`：用 `#if TARGET_OS_IPHONE` 保护 `<UIKit/UIScreen.h>`，并在 `TARGET_OS_OSX` 上使用 `NSScreen.mainScreen.backingScaleFactor > 1.0`。
   - `MADKeyChain.m`：使用 `Security.framework`，它在 iOS 和 macOS 上都是原生的。
2. **`MADDataStructures`**（17 个 `.m` 文件）：
   - 纯 Foundation + C++。无需修改源码。
3. **`MADFileManager`**（11 个 `.m` 文件）：
   - 删除 `MADMetaDataLocal.m:16` 中未使用的 `#import <MobileCoreServices/UTType.h>`（第 17 行已经导入了 `<UniformTypeIdentifiers/UTType.h>`）。
4. **`MADCocoaExtensions`**（17 个 `.m` 文件）：
   - `CGGeometry+Extras.h`：在 `TARGET_OS_OSX` 上提供 `UIEdgeInsets`（与 `NSEdgeInsets` 兼容的布局结构体 + `UIEdgeInsetsMake` / `UIEdgeInsetsZero` / `UIEdgeInsetsEqualToEdgeInsets`）、`NSStringFromCGPoint` / `NSStringFromCGSize` / `NSStringFromCGRect`，以及 `NSValue (MADCGGeometryExtensions)`（`valueWithCGPoint:`、`CGPointValue`、`valueWithCGRect:`、`CGRectValue`、`valueWithCGSize:`、`CGSizeValue`）。
   - `MADColor.h` / `MADColor.m`：在 `TARGET_OS_OSX` 上将 `MADColor` 桥接到 `NSColor`，同时在 `TARGET_OS_IPHONE` 上保留 `UIColor`。
   - 用 `#if TARGET_OS_IPHONE` 保护仅限 iOS 的 `UIView`、`UIAlertController`、`UITextField` 和 `UIColor` category。
5. **`MADAPI`**（11 个 `.m` 文件）：
   - 9 个核心数据库、查询和驱动注册文件是纯 Foundation。
   - 用 `#if TARGET_OS_IPHONE` 保护 `MADConnectionViewController` 和 `MADConnectionSQLGenericViewController`。
6. **`MADSqlite3`**（26 个 `.m` 文件）：
   - 纯 Foundation + `sqlite3.xcframework`。无需修改源码。
7. **`MADTds`**（1 个 `.m` 文件）：
   - 纯 Foundation + `freetds.xcframework` + `openssl.xcframework`。无需修改源码。
8. **`MADTdsClient`**（4 个 `.m` 文件）：
   - `MADDatabaseSQLServer`、`MADTdsConnection` 和 `MADDataTypeSQLServer` 是纯 Foundation。用 `#if TARGET_OS_IPHONE` 保护 `MADTdsConnectionViewController`。
9. **`MADMySQL`**（19 个 `.m` 文件）：
   - 18 个驱动文件是纯 Foundation + `mariadb.xcframework`。用 `#if TARGET_OS_IPHONE` 保护 `MADMySQLConnectionViewController`。
10. **`MADPostgres`**（5 个 `.m` 文件）：
    - 4 个驱动文件是纯 Foundation + `postgres.xcframework`。用 `#if TARGET_OS_IPHONE` 保护 `MADPostgresConnectionViewController`。
11. **`MADBarcodes`**（70 个 `.m` 文件）：
    - 67 个符号类（symbology classes）是纯 Foundation + `zint.xcframework`。
    - `MADBarcode`、`MADBarcodeCache` 和 `MADBarcodeView`：在现有 `CGImageRef` 的 `MADBarcodeImageFromZintBitmap` 管线之上，在 `TARGET_OS_OSX` 上桥接 `UIImage` / `NSImage` 和 `UIView` / `NSView`。
12. **`MAD`**（199 个 `.m` 文件）：
    - 在 9 个共享模型/渲染文件中，将 `#if __APPLE__` 替换为 `#if TARGET_OS_IPHONE` 和 `#elif TARGET_OS_OSX` AppKit 桥接（`RptqObject.m`、`RptqDocumentElementImage+Extras.m`、`RptqDocument+Extras.m`、`RptqDocumentSection+Extras.m`、`RptqDocumentElement+Extras.m`、`MADPrintPageElement.m`、`MADElementStylizedText.m`、`MADFonts.m` 和 `MADReportExporterPDF.m`）。
    - 在 `MADReportExporterPDF.m` 中，在 `TARGET_OS_OSX` 上使用 `CGPDFContextCreateWithURL` / `CGPDFConsumerCreateWithCFData` 和 `NSGraphicsContext`（`+graphicsContextWithCGContext:flipped:YES`）渲染分页 PDF，使 `MADPrintPageRenderer` 和 `MADPrintPageElement` 在 macOS 上原生绘制。
    - 用 `#if TARGET_OS_IPHONE` 保护 22 个仅限 iOS 的 `UIDocument`（`MADocument`）、`UIView` 和 `UICollectionViewLayout` 文件。

`MADExplorer` 仍然仅限 iOS（macOS 使用 `NSDocumentController`、Finder 和带主 **新建文档** 按钮的 `NSOpenPanel`）。根据
`AGENTS.md`，`MADFeedback` 和 `Scrimpter` 仍未使用。

---

## 4. 分阶段实施计划

### 阶段 1：缺陷修复与多平台框架启用（已完成）

1. **修复了 macOS 审计与移植期间暴露的 6 个缺陷**，并附带单元测试将它们从
   `docs/project/BUGS.md` 归档到 `docs/project/BUGS_FIXED.md`：
   - `MADKeyChain`（`MADFoundation/Source/MADKeyChain.m`）：在
     `+credentialsExist:`、`+saveToken:forKey:withDescription:`、`+deleteKey:` 和
     `+deleteSavedPasswordForKey:error:` 中，不再请求 `kSecReturnData : @YES`（也不再泄漏返回的 `CFDataRef`）。
   - `MADURLFactory`（`MADFoundation/Source/MADURLFactory.m`）：当
     `[NSBundle mainBundle].bundleIdentifier` 为 `nil` 时，保护
     `+newURLForLocalApplicationSupportDirectory`（回退到 `[MADApplication groupIdentifier]`），并用
     `#if defined(__APPLE__) && TARGET_OS_IPHONE` 保护
     `containerURLForSecurityApplicationGroupIdentifier:`，使无授权的 macOS 进程使用标准的每用户目录，而不会在
     `~/Library/Group Containers/` 上触发 TCC 提示。
   - `MADDataTable`（`MADFoundation/Source/MADDataTable.m`）：用
     `#if defined(__APPLE__) && TARGET_OS_IPHONE` 保护
     `NSDataWritingFileProtectionCompleteUnlessOpen`，使无授权的 macOS 缓存写入成功。
   - `MADDatabaseSqlite3`（`MADSqlite3/Source/MADDatabaseSqlite3.m`）：用
     `if (rowCounter > 0)` 保护 `[dataTable endBulkInsert]`，这样在从未调用
     `[dataTable beginBulkInsert]` 时，零行的 `SELECT` 查询不会执行 `COMMIT TRANSACTION`。
   - `MADBarcode`（`MADBarcodes/MADBarcodes/MADBarcodes/MADBarcode.m`）：修复了
     `-drawInRect:` 在 `self.center == YES` 时使 `rect.origin` 加倍偏移的问题。
   - `MADDesignerLayout`（`MAD/Source/MADDesignerLayout.m`）：在所有批量更新方法
     （`setFontsize:`、`setFontname:`、`setVerticalAlignment:`、
     `setHorizontalAlignment:`、`setSizeWidth:`、`setSizeHeight:`、`setMargin*`、
     `setPadding*`、`setBorder*`）中注册撤销操作时，将每个选中元素自身的先前值保存在一个字典中。
2. **在 12 个框架 Xcode 项目中启用 `macosx`：**
   - 设置 `SUPPORTED_PLATFORMS = "iphoneos iphonesimulator macosx"` 和
     `MACOSX_DEPLOYMENT_TARGET = 12.0`。
   - 在 `UIKit.framework` 引用上添加 `platformFilters = (ios, maccatalyst, );`，并在需要处以
     `platformFilters = (macos, );` 链接 `AppKit.framework`。
   - 更新 `Ensure Libraries` 构建阶段，传入
     `--platforms ios,simulator,macosx`。
3. **在原生 macOS 上验证全部 12 个框架（`-destination 'platform=macOS,arch=arm64'`）：**
   - `MADFoundation`：**199 个测试通过，0 个失败**
   - `MADDataStructures`：**72 个测试通过，0 个失败**
   - `MADCocoaExtensions`：**80 个测试通过，0 个失败**
   - `MADFileManager`：**85 个测试通过，0 个失败**
   - `MADAPI`：**106 个测试通过，0 个失败**
   - `MADSqlite3`：**118 个测试通过（跳过 5 个基准测试），0 个失败**
   - `MADTds`：**已为 `macosx` 干净构建**
   - `MADTdsClient`：**77 个测试通过（包括实时 SQL Server 套件），0 个失败**
   - `MADMySQL`：**所有离线和实时 MariaDB/MySQL 测试通过，0 个失败**
   - `MADPostgres`：**31 个测试通过（包括实时 PostgreSQL 套件），0 个失败**
   - `MADBarcodes`：**30 个测试通过，0 个失败**
   - `MAD`：**650 个测试通过，0 个失败**

### 阶段 2：多平台架构导入与 `NSDocument` 层（已完成）

1. **多平台文档创建与架构导入（`MADHeadlessDocument`）：**
   - 在 `MADHeadlessDocument`（`MAD/Source/MADHeadlessDocument.h`、`.m`）上新增
     `+createDocumentAtURL:withDatabaseConnection:credentials:error:`，它会连接任何已注册的驱动
     （`SQLite3`、`MySQL`、`SQL Server`、`PostgreSQL`），将所有数据库表
     （`-getTablesFromConnection:error:`）和列（`-fieldsForTable:connection:error:`）导入
     `RptqDatabaseSchemaTable` / `RptqDatabaseSchemaField`，初始化标准报表带区
     （`Report Header`、`Page Header`、`Report Detail`、`Page Footer`、`Report Footer`），并写入可移植
     `.mad` 容器。
2. **`MADMacDocument`（`Mac/Source/MADMacDocument.m` 中的 `NSDocument` 子类）：**
   - 封装 `MADHeadlessDocument`（需要时通过 `MADStoreConverter` 自动转换旧版 Core Data `.mad`），
     遵循 `MADocumentDesignerProtocol`，使 `MADDesignerLayout` 直接将撤销/重做记录到
     `NSDocument.undoManager`，并支持 `readFromURL:ofType:error:`、
     `writeToURL:ofType:forSaveOperation:originalContentsURL:error:` 以及异步
     `refreshWithCredentials:maxRows:completion:`。

### 阶段 3：原生 macOS 应用程序（`Mac/`）（已完成）

在 `Mac/`（`Mac/Source/`、`Mac/Resources/`、`Mac/Tests/`、`Mac/build.sh`）下构建，并通过 **`MAD Designer Mac`** target 和共享 scheme 集成到 `MAD Designer.xcodeproj`：

1. **应用程序生命周期、关于窗口与文档控制器（`MADMacAppDelegate`、`MADMacAboutWindowController` 与 `MADMacDocumentController`）：**
   - 注册全部四个数据库驱动和 `MADStoreLegacyConverter`，构建原生 macOS 主菜单（`MAD Designer`、`File`、含 `Undo`/`Redo` 的 `Edit`、用 `Cmd+1`/`Cmd+2`/`Cmd+3` 切换工作区的 `View`、用 `Cmd+R` 刷新的 `Report`、`Window`、`Help`），并在启动时若没有打开的文档则显示标准 `NSOpenPanel`。
   - `MADMacAboutWindowController` 显示原生 **关于 MAD Designer** 窗口（`MAD Designer → About MAD Designer` 和 `Help` 菜单项），包含版本/构建元数据（`MADMeta.plist`）、版权与保留品牌/美术素材声明、**在 GitHub 上查看源代码** 操作，以及三个标签页：**概述**（MAD 是什么、4 步报表工作流，以及支持的驱动/带区/导出器）、**许可证与声明**（MIT License、`NOTICE`，以及针对 FreeTDS 和 MariaDB Connector/C 的书面 LGPL-3.0 重新链接要约）、**致谢**（全部 16 个第三方开源组件的交互式侧边栏及其署名，以及 `Contents/Resources/Licenses/` 下捆绑的 12 份完整许可证文本）。
   - `MADMacDocumentController` 配置 `NSOpenPanel` 使用所有 `.mad` `UTType` 标识符（`com.everydayapps.productivity.mad` 和 `com.thomason.report.mad`），使现有 `.mad` 文件永远不会被置灰，并将主 **新建文档** 按钮直接放在打开面板左下角的栏中。
2. **数据库连接与架构导入助理（`MADMacConnectionWindowController`）：**
   - 支持 **SQLite**（通过 `NSOpenPanel` 选择自定义 `.sqlite3`/`.db` 文件）、**MySQL**、**Microsoft SQL Server** 和 **PostgreSQL**，提供 **测试连接**、`MADKeyChain` 密码存储，以及 **创建文档…**（`NSSavePanel`）。
3. **主文档窗口（`MADMacWindowController`）：**
   - 将 **工作区** 分段控件（**MAD Query**、**MAD Designer**、**MAD Viewer**）置于窗口工具栏中央。
4. **MAD Query 工作区（`MADMacQueryViewController`）：**
   - 互斥的 **查询设计器** 和 **SQL 查询** 工作区模式（在工作区标题栏中切换，使可视化查询设计与手动 SQL 输入永远不会同时显示）。
   - **查询设计器模式**：左侧 `200px` 的 **数据库表** 列表（用户可通过 `NSSplitViewDelegate` 调整大小且不会弹回；窗口大小改变时保持固定宽度，使可视化画布改为调整大小），配合右侧交互式可视化画布（`MADMacQueryCanvasView`）。双击架构表将其添加到查询（填充所有 `RptqQueryField` 行），并将其显示为可拖拽、可调整大小的浮动 AppKit 表卡片（`MADMacQueryTableCardView` + `MADMacQueryFieldTableView`），表头按拓扑根/子级样式（`MTGraph`）呈现；从一张表卡片的字段拖到另一张表卡片的字段，会创建一个默认的 **左外连接**（`MADLinkTypeLeftOuterJoin`），通过 Bezier 连接线和连接类型徽章绘制（`MADMacQueryLinksOverlayView`，与 iPad 的 `MADConnectorView` 一致）。点击或右键点击可视化连接线会打开连接检查器浮层或上下文菜单，以更改连接类型、交换方向或删除连接；表头浮层提供 **筛选（WHERE）**、**分组（GROUP BY）** 和 **排列表**。
   - **SQL 查询模式**：全宽 SQL 语句编辑器，显示生成或输入的 SQL，并支持校验、编译和应用（`MADSQLParser` + `MADSQLStatementResolver` + `MADSQLQueryCompiler`）。
5. **MAD Designer 工作区（`MADMacDesignerViewController` + `MADMacDesignerCanvasView` + `MADMacDesignerMinimapView`）：**
   - **顶部工作区栏（高 `38pt`）：** 提供可点击、可拖拽的 SF Symbol 元素面板项（**标签**、**数据字段**、**聚合**、**条码**、**图像**、**线条**）、快速多元素对齐控件（`Left`、`Center`、`Right`、`Top`、`Middle`、`Bottom`）、**适应大小**、**网格** / **吸附** / **标尺** 开关，以及一键重置为 `100%` 的 **缩放** 滑块。
   - **用户可调整大小的三栏分割视图（`NSSplitViewDelegate`）：** 左侧导航侧边栏默认 `220pt`（`180–340pt`），右侧检查器默认 `260pt`（`220–380pt`），两侧边栏在窗口大小改变时保持各自的宽度，同时保留用户的分隔条调整。
   - **左侧边栏（缩略图 + 带区 + 查询字段浏览器）：**
     - **交互式页面与带区缩略图（`MADMacDesignerMinimapView`）：** 按比例绘制报表带区，带彩色编码条纹、实时微缩元素块和蓝色视口矩形；点击或拖拽可跳转并选中带区。
     - **报表带区大纲：** 列出所有报表带区和分组带区，包含元素数量、高度和分页指示；双击可切换带区可见性。
     - **查询字段浏览器：** 所有 `RptqQueryField` 列的可过滤列表（`NSSearchField`）；将字段拖到画布上任意带区（或双击）会插入一个绑定的 `RptqDocumentElementLabelDataField`。
   - **中央交互式画布（`MADMacDesignerCanvasView`）：** 翻转的、可缩放的 `NSView` 画布，带有水平/垂直标尺、纸张边距、按颜色编码的带区、带区高度拖拽手柄、智能对齐参考线、网格吸附、框选、按住 `Shift` 点击多选、8 点调整大小手柄、双击内联编辑标签、智能不重叠元素放置（`-nextAvailableOriginInSection:forElementSize:`），以及带实时目标带区高亮和完整 `NSUndoManager` 集成的跨带区拖放（`-moveElement:toSection:atOrigin:`）。
   - **右侧检查器侧边栏（分区清晰且可滚动）：**
     - **卡片 1（`1 · PAGE & SELECTED SECTION`）：** 纸张大小、选中带区徽章、带区高度（`pt`）及 **适应高度** 按钮、**带区可见** 和 **之后分页**。
     - **醒目的视觉分隔线 + 第 2 部分（`2 · SELECTED ELEMENT INSPECTOR`）：** 4 张分组检查器卡片（**元素与带区分配**，含跨带区移动弹出菜单、**复制** 和 **删除**；**内容与数据绑定**，含静态文本、查询字段绑定、聚合函数与作用域、货币格式和条码选项；**排版与外观**，含字体族/字号、粗体/斜体/下划线/删除线、水平/垂直对齐和文本/背景颜色；以及 **位置、大小与盒模型**，含在 `rect.origin` 与 `dropPoint` 之间同步的 `X`、`Y`、`W`、`H`，外加边框、内边距和外边距）。
6. **MAD Viewer 工作区（`MADMacViewerViewController`）：**
   - **顶部查看器工具栏（高 `40pt`）：** **纸张大小** 弹出菜单（`MTPaper` 标准纸张类型：`US Letter`、`US Legal`、`US Tabloid`、`A3`、`A4`、`A5`、`B4`、`B5`、`JIS B4`、`JIS B5`）、**刷新**（`Cmd+R`）、**缩放** 控件（`-`、`100%`、`+`）、**页面导航**（`Previous`、`Page N of M`、`Next`）、**打印…**（通过 `NSPrintOperation` 的 `Cmd+P`）和 **导出…**（`Cmd+E`）。
   - **带边框的分页预览（`PDFView`）：** 从本地 SQLite 表缓存（`MADDataTableFast`）按所选纸张大小渲染分页 PDF 页面，带页面阴影和底部状态栏（`statusBarView`），显示已渲染页数、缓存行数和纸张尺寸。
   - **多格式导出（`NSSavePanel`）：** 配置一个附件视图格式弹出菜单，支持全部 7 个已注册导出器（`PDF`、`HTML`、`HTML Flow`、`CSV`、`JSON`、`JSON Report`、`Plain Text`），并动态更新保存面板允许的文件扩展名。

### 阶段 4：构建、冒烟验证与 GitHub Release 打包（已完成）

```sh
./Mac/build.sh --smoke-test --package
```

生成：
- `Mac/build/MAD Designer.app`（独立原生 macOS 应用包，内嵌并签名了全部 12 个框架和旧版 Core Data `.momd` 模型）
- `Mac/build/MAD-Designer-macOS.zip`
- `Mac/build/MAD-Designer-macOS.dmg`

关于原生 macOS 应用程序的公开用户与开发者文档发布在 [`docs/macos.md`](../macos.md)（截图位于 `docs/assets/macos-native-mad-query.png` 和 `docs/assets/macos-native-mad-designer.png`）以及 [`Mac/README.md`](../../../Mac/README.md) 中。
