---
layout: default
title: "可移植性与原生 macOS 应用"
description: "框架可移植性审计与 AppKit 应用架构。"
lang: zh-CN
---

# `MAD_MACOS.md`——多平台框架与原生 macOS 应用

本页记录多平台框架审计与原生 macOS 应用架构。面向用户的指南位于 `/macos.html`。

*撰写于原定日期；当前状态事实已于 2026-11-22 核实。*

本文档记录架构决策、逐框架的可移植性审计，以及分阶段的迁移与实现计划——让 MAD 框架
真正多平台（`iphoneos`、`iphonesimulator`、`macosx` 和无头 Linux），
并为 **MAD Designer** 构建原生 macOS（`AppKit`）前端。

---

## 1. 决策：原生 macOS（`AppKit`）还是 Mac Catalyst

**决策：** 在共享的多平台框架之上构建**原生 macOS 应用（`macosx` SDK、`AppKit`）**
（`MACOSX_DEPLOYMENT_TARGET = 12.0`，支持所有 Apple
Silicon Mac 以及运行 Monterey 或更新版本的 Intel Mac）。**否决 Mac Catalyst。**

### 原生 macOS 胜出的原因

| 维度 | 原生 macOS（`macosx` / `AppKit`） | Mac Catalyst（`maccatalyst` / `UIKit`） |
|---|---|---|
| **静态 C 库（`Compressor`）** | **已构建。** `Compressor/library/` 中全部 10 个 `.xcframework` 包都带有通用 `macosx`（`arm64` + `x86_64`、`-mmacosx-version-min=11.0`）切片，已由 `./Compressor/build.sh --verify --all --platforms ios,simulator,macosx` 验证。 | **缺失。** 不存在任何 `maccatalyst` 切片（`-target <arch>-apple-ios15.0-macabi`）。Mach-O 链接器拒绝把 `MACOS` 归档链接进 `MACCATALYST` 二进制文件；Catalyst 需要给 `Compressor` 增加第 4 个平台并重新构建全部 10 个 C 库（`openssl`、`mariadb`、`postgres`、`freetds`、`libarchive`、`sqlite3`、`zint`、`libpng`、`bzip2`、`zlib`）。 |
| **核心引擎可移植性** | **已完成 90%。** Linux 无头移植（`MAD_LINUX.md`）已从 `MAD.framework` 移除 Core Data，解耦了数据库驱动（`MADDatabaseDriverRegistry`）和报表导出器（`MADReportExporterRegistry`），并引入了 `MADHeadlessDocument`、`MADSQLQueryCompiler` 和 `MADDesignerLayout`。 | 同样的引擎，但受 `UIDocument` 和 iOS 后台任务生命周期束缚。 |
| **桌面人体工学** | 原生 `NSDocument` / `NSDocumentController`（Finder 双击、`Cmd+N`、`Cmd+O`、`Cmd+S`、`Cmd+Shift+S`、最近文档、窗口恢复、`NSUndoManager`）、原生分栏视图、原生表/大纲视图、原生 `PDFView` / `WKWebView`，以及标准 macOS 菜单。 | 嵌套缩放的 `UIScrollView` + `UICollectionView` 带区、iOS 标签/导航栏、`UIPickerView` 滚轮，以及 iOS 沙盒文档浏览器（`MADExplorer`）。Apple Silicon Mac 已通过 *Designed for iPad* 运行 iPad 构建。 |
| **通过 GitHub 分发** | 干净的独立 `.app` 包，打包为 GitHub Releases 上可下载的 `.dmg` 和 `.zip`（`arm64` + `x86_64`）。 | 需要 Catalyst 描述文件和 entitlement，与 App Store 之外的分发人体工学不匹配。 |

---

## 2. 静态库审计（`Compressor`）

`Compressor` 中全部十个 vendored C 库都用 `-mmacosx-version-min=11.0` 构建通用 `macosx`（`arm64` + `x86_64`）
切片：

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

## 3. 逐框架的多平台审计

十二个框架构成多平台技术栈（`iphoneos`、`iphonesimulator`、`macosx`，
外加 Linux 作为十二个无头框架的第十二个平台）：

1. **`MADFoundation`**（28 个 `.m` 文件）：
   - `MADApplication.h`：用 `#if TARGET_OS_IPHONE` 而不是 `#if __APPLE__` 保护 `<UIKit/UIApplication.h>`
     （`MADApplication.m` 已有
     `#elif TARGET_OS_OSX #import <AppKit/NSApplication.h>`）。
   - `MADURLFactory.m`：用 `#if TARGET_OS_IPHONE` 保护 `<UIKit/UIScreen.h>`，并在
     `TARGET_OS_OSX` 上使用 `NSScreen.mainScreen.backingScaleFactor > 1.0`。
   - `MADKeyChain.m`：使用 `Security.framework`，它在 iOS 和 macOS 上都是原生的。
2. **`MADDataStructures`**（17 个 `.m` 文件）：
   - 纯 Foundation + C++。无需源码改动。
3. **`MADFileManager`**（11 个 `.m` 文件）：
   - 移除 `MADMetaDataLocal.m:16` 中未使用的 `#import <MobileCoreServices/UTType.h>`
     （第 17 行已导入 `<UniformTypeIdentifiers/UTType.h>`）。
4. **`MADCocoaExtensions`**（17 个 `.m` 文件）：
   - `CGGeometry+Extras.h`：在 `TARGET_OS_OSX` 上提供 `UIEdgeInsets`（与 `NSEdgeInsets` 兼容的布局
     结构体 + `UIEdgeInsetsMake` / `UIEdgeInsetsZero` / `UIEdgeInsetsEqualToEdgeInsets`）、
     `NSStringFromCGPoint` / `NSStringFromCGSize` / `NSStringFromCGRect`，以及
     `NSValue (MADCGGeometryExtensions)`（`valueWithCGPoint:`、`CGPointValue`、
     `valueWithCGRect:`、`CGRectValue`、`valueWithCGSize:`、`CGSizeValue`）。
   - `MADColor.h` / `MADColor.m`：在 `TARGET_OS_OSX` 上把 `MADColor` 桥接到 `NSColor`，同时
     在 `TARGET_OS_IPHONE` 上保留 `UIColor`。
   - 用 `#if TARGET_OS_IPHONE` 保护仅 iOS 的 `UIView`、`UIAlertController`、`UITextField` 和 `UIColor`
     category。
5. **`MADAPI`**（11 个 `.m` 文件）：
   - 9 个核心数据库、查询和驱动注册表文件是纯 Foundation。
   - 用 `#if TARGET_OS_IPHONE` 保护 `MADConnectionViewController` 和 `MADConnectionSQLGenericViewController`。
6. **`MADSqlite3`**（26 个 `.m` 文件）：
   - 纯 Foundation + `sqlite3.xcframework`。无需源码改动。
7. **`MADTds`**（1 个 `.m` 文件）：
   - 纯 Foundation + `freetds.xcframework` + `openssl.xcframework`。无需源码
     改动。
8. **`MADTdsClient`**（4 个 `.m` 文件）：
   - `MADDatabaseSQLServer`、`MADTdsConnection` 和 `MADDataTypeSQLServer` 是纯
     Foundation。用 `#if TARGET_OS_IPHONE` 保护 `MADTdsConnectionViewController`。
9. **`MADMySQL`**（19 个 `.m` 文件）：
   - 18 个驱动文件是纯 Foundation + `mariadb.xcframework`。用
     `#if TARGET_OS_IPHONE` 保护 `MADMySQLConnectionViewController`。
10. **`MADPostgres`**（5 个 `.m` 文件）：
    - 4 个驱动文件是纯 Foundation + `postgres.xcframework`。用
      `#if TARGET_OS_IPHONE` 保护 `MADPostgresConnectionViewController`。
11. **`MADBarcodes`**（70 个 `.m` 文件）：
    - 67 个符号学类是纯 Foundation + `zint.xcframework`。
    - `MADBarcode`、`MADBarcodeCache` 和 `MADBarcodeView`：在 `TARGET_OS_OSX` 上
      基于既有的 `CGImageRef` `MADBarcodeImageFromZintBitmap` 管线桥接 `UIImage` / `NSImage`
      和 `UIView` / `NSView`。
12. **`MAD`**（199 个 `.m` 文件）：
    - 在 9 个共享模型/渲染文件（`RptqObject.m`、
      `RptqDocumentElementImage+Extras.m`、`RptqDocument+Extras.m`、
      `RptqDocumentSection+Extras.m`、`RptqDocumentElement+Extras.m`、
      `MADPrintPageElement.m`、`MADElementStylizedText.m`、`MADFonts.m` 和
      `MADReportExporterPDF.m`）中，把 `#if __APPLE__` 替换为 `#if TARGET_OS_IPHONE`，并用 `#elif TARGET_OS_OSX`
      AppKit 桥接。
    - 在 `MADReportExporterPDF.m` 中，在 `TARGET_OS_OSX` 上使用
      `CGPDFContextCreateWithURL` / `CGPDFConsumerCreateWithCFData` 和
      `NSGraphicsContext`（`+graphicsContextWithCGContext:flipped:YES`）渲染分页 PDF，使
      `MADPrintPageRenderer` 和 `MADPrintPageElement` 在 macOS 上原生绘制。
    - 用 `#if TARGET_OS_IPHONE` 保护 22 个仅 iOS 的 `UIDocument`（`MADocument`）、`UIView` 和
      `UICollectionViewLayout` 文件。

`MADExplorer` 仍仅限 iOS（macOS 使用 `NSDocumentController`、Finder 和 `NSOpenPanel`，并带一个主 **New Document** 按钮）。`MADFeedback` 和 `Scrimpter` 按
`AGENTS.md` 保持未使用。

---

## 4. 分阶段实现计划

### 阶段 1：缺陷修复与多平台框架启用（已完成）

1. **修复了 macOS 审计与移植期间浮现的 6 个缺陷**，并连同单元测试把它们从
   `docs/project/BUGS.md` 归档到 `docs/project/BUGS_FIXED.md`：
   - `MADKeyChain`（`MADFoundation/Source/MADKeyChain.m`）：在
     `+credentialsExist:`、`+saveToken:forKey:withDescription:`、`+deleteKey:` 和
     `+deleteSavedPasswordForKey:error:` 中停止请求 `kSecReturnData : @YES`（并停止泄漏返回的 `CFDataRef`）。
   - `MADURLFactory`（`MADFoundation/Source/MADURLFactory.m`）：在 `[NSBundle mainBundle].bundleIdentifier`
     为 `nil` 时保护 `+newURLForLocalApplicationSupportDirectory`
     （回退到 `[MADApplication groupIdentifier]`），并用
     `#if defined(__APPLE__) && TARGET_OS_IPHONE` 保护
     `containerURLForSecurityApplicationGroupIdentifier:`，使无 entitlement 的 macOS 进程使用
     标准的每用户目录，而不是在
     `~/Library/Group Containers/` 上触发 TCC 提示。
   - `MADDataTable`（`MADFoundation/Source/MADDataTable.m`）：用
     `#if defined(__APPLE__) && TARGET_OS_IPHONE` 保护
     `NSDataWritingFileProtectionCompleteUnlessOpen`，使无 entitlement 的 macOS 缓存写入成功。
   - `MADDatabaseSqlite3`（`MADSqlite3/Source/MADDatabaseSqlite3.m`）：用
     `if (rowCounter > 0)` 保护 `[dataTable endBulkInsert]`，使零行的 `SELECT` 查询
     在 `[dataTable beginBulkInsert]` 从未被调用时不执行 `COMMIT TRANSACTION`。
   - `MADBarcode`（`MADBarcodes/MADBarcodes/MADBarcodes/MADBarcode.m`）：修复了
     `-drawInRect:` 在 `self.center == YES` 时把 `rect.origin` 加倍的问题。
   - `MADDesignerLayout`（`MAD/Source/MADDesignerLayout.m`）：在所有
     批量更新方法（`setFontsize:`、`setFontname:`、`setVerticalAlignment:`、
     `setHorizontalAlignment:`、`setSizeWidth:`、`setSizeHeight:`、`setMargin*`、
     `setPadding*`、`setBorder*`）中注册撤销操作时，把每个选中元素自身的先前值保留在字典中。
2. **在 12 个框架 Xcode 项目中启用 `macosx`：**
   - 设置 `SUPPORTED_PLATFORMS = "iphoneos iphonesimulator macosx"` 和
     `MACOSX_DEPLOYMENT_TARGET = 12.0`。
   - 在 `UIKit.framework` 引用上添加 `platformFilters = (ios, maccatalyst, );`，并在需要处
     以 `platformFilters = (macos, );` 链接 `AppKit.framework`。
   - 更新 `Ensure Libraries` 构建阶段以传入
     `--platforms ios,simulator,macosx`。
3. **在原生 macOS 上验证全部 12 个框架（`-destination 'platform=macOS,arch=arm64'`）：**
   - `MADFoundation`：**199 个测试通过，0 个失败**
   - `MADDataStructures`：**72 个测试通过，0 个失败**
   - `MADCocoaExtensions`：**80 个测试通过，0 个失败**
   - `MADFileManager`：**85 个测试通过，0 个失败**
   - `MADAPI`：**106 个测试通过，0 个失败**
   - `MADSqlite3`：**118 个测试通过（5 个基准跳过），0 个失败**
   - `MADTds`：**为 `macosx` 干净构建**
   - `MADTdsClient`：**77 个测试通过（包括实时 SQL Server 套件），0 个失败**
   - `MADMySQL`：**所有离线和实时 MariaDB/MySQL 测试通过，0 个失败**
   - `MADPostgres`：**31 个测试通过（包括实时 PostgreSQL 套件），0 个失败**
   - `MADBarcodes`：**30 个测试通过，0 个失败**
   - `MAD`：**650 个测试通过，0 个失败**

### 阶段 2：多平台架构导入与 `NSDocument` 层（已完成）

1. **多平台文档创建与架构导入（`MADHeadlessDocument`）：**
   - 在 `MADHeadlessDocument`（`MAD/Source/MADHeadlessDocument.h`、`.m`）上添加了
     `+createDocumentAtURL:withDatabaseConnection:credentials:error:`，它连接到
     任何已注册驱动（`SQLite3`、`MySQL`、`SQL Server`、`PostgreSQL`），把所有
     数据库表（`-getTablesFromConnection:error:`）和列
     （`-fieldsForTable:connection:error:`）导入 `RptqDatabaseSchemaTable` /
     `RptqDatabaseSchemaField`，初始化标准报表带区（`Report Header`、
     `Page Header`、`Report Detail`、`Page Footer`、`Report Footer`），并写出
     可移植的 `.mad` 容器。
2. **`MADMacDocument`（`Mac/Source/MADMacDocument.m` 中的 `NSDocument` 子类）：**
   - 包装 `MADHeadlessDocument`（需要时通过
     `MADStoreConverter` 自动转换遗留 Core Data `.mad`），遵循 `MADocumentDesignerProtocol`，使
     `MADDesignerLayout` 把撤销/重做直接记录到 `NSDocument.undoManager`，并
     支持 `readFromURL:ofType:error:`、
     `writeToURL:ofType:forSaveOperation:originalContentsURL:error:` 以及异步
     `refreshWithCredentials:maxRows:completion:`。

### 阶段 3：原生 macOS 应用（`Mac/`）（已完成）

构建于 `Mac/` 下（`Mac/Source/`、`Mac/Resources/`、`Mac/Tests/`、`Mac/build.sh`），并通过 **`MAD Designer Mac`** 目标与共享 scheme 集成进 `MAD Designer.xcodeproj`：

1. **应用生命周期、关于窗口与文档控制器（`MADMacAppDelegate`、`MADMacAboutWindowController` 和 `MADMacDocumentController`）：**
   - 注册全部四个数据库驱动和 `MADStoreLegacyConverter`，构建原生 macOS 主菜单（`MAD Designer`、`File`、带 `Undo`/`Redo` 的 `Edit`、切换工作区的 `View` `Cmd+1`/`Cmd+2`/`Cmd+3`、刷新报表的 `Report` `Cmd+R`、`Window`、`Help`），并在启动时若无打开文档则呈现标准 `NSOpenPanel`。
   - `MADMacAboutWindowController` 呈现原生 **About MAD Designer** 窗口（`MAD Designer → About MAD Designer` 和 `Help` 菜单项），分别显示引擎版本/构建（`MADMeta.plist`）和 macOS 应用版本（`CFBundleShortVersionString`），以及版权和保留的品牌/美术资源声明、**Source Code on GitHub** 操作，以及三个标签页：**Overview**（MAD 是什么、4 步报表工作流，以及支持的驱动/带区/导出器）、**License & Notice**（MIT License、`NOTICE`，以及针对 FreeTDS 和 MariaDB Connector/C 的 LGPL-3.0 书面重新链接要约）和 **Acknowledgements**（全部 16 个第三方开源组件的交互式侧栏，配有其归属说明，以及打包在 `Contents/Resources/Licenses/` 下的 12 份完整许可证文本）。
   - `MADMacDocumentController` 为 `NSOpenPanel` 配置全部 `.mad` `UTType` 标识符（`com.everydayapps.productivity.mad` 和 `com.thomason.report.mad`），使已有 `.mad` 文件永不被置灰，并在打开面板左下栏直接放置一个主 **New Document** 按钮。
2. **数据库连接与架构导入助手（`MADMacConnectionWindowController`）：**
   - 支持 **SQLite**（通过 `NSOpenPanel` 选择自定义 `.sqlite3`/`.db` 文件）、**MySQL**、**Microsoft SQL Server** 和 **PostgreSQL**，带 **Test Connection**、`MADKeyChain` 密码存储，以及 **Create Document…**（`NSSavePanel`）。
3. **主文档窗口（`MADMacWindowController`）：**
   - 把 **Workspace** 分段控件（**MAD Query**、**MAD Designer**、**MAD Viewer**）置于窗口工具栏中央。
4. **MAD Query 工作区（`MADMacQueryViewController`）：**
   - 互斥的 **Query Designer** 与 **SQL Query** 工作区模式（在工作区头部栏中切换，因此可视化查询设计与手动 SQL 输入绝不会
     同时显示）。
   - **Query Designer 模式**：一个 `200px` 的左侧 **Database Tables** 列表（可通过 `NSSplitViewDelegate` 由用户调整大小且不会回弹，且在调整窗口大小时保持固定宽度，使可视化画布随之缩放），配以一个交互式
     右侧可视化画布（`MADMacQueryCanvasView`）。双击架构表
     把它加入查询（填充所有 `RptqQueryField` 行），并将其显示为
     可拖动、可调整大小的浮动 AppKit 表卡片（`MADMacQueryTableCardView` +
     `MADMacQueryFieldTableView`），以拓扑根/子头部（`MTGraph`）样式呈现，
     且从一张表卡片的字段拖到另一张表卡片的字段会创建默认的
     **Left Outer Join**（`MADLinkTypeLeftOuterJoin`），经由 Bezier 连接线和
     联接类型徽标绘制（`MADMacQueryLinksOverlayView`，与 iPad 的 `MADConnectorView` 一致）。
     单击或右键单击可视化联接连接线会打开联接检查器浮出或
     上下文菜单，以更改联接类型、交换方向或删除联接；头部
     浮出提供 **Filters (WHERE)**、**Groupings (GROUP BY)** 和 **Arrange Tables**。
   - **SQL Query 模式**：全宽 SQL 语句编辑器，显示生成或输入的
     SQL，并支持校验、编译和应用（`MADSQLParser` +
     `MADSQLStatementResolver` + `MADSQLQueryCompiler`）。
5. **MAD Designer 工作区（`MADMacDesignerViewController` + `MADMacDesignerCanvasView` + `MADMacDesignerMinimapView`）：**
   - **顶部工作区栏（`38pt` 高）：** 提供可单击且可拖动的 SF Symbol
     元素调色板项（**Label**、**Data Field**、**Aggregate**、**Barcode**、
     **Image**、**Line**）、快速多元素对齐控件（`Left`、`Center`、
     `Right`、`Top`、`Middle`、`Bottom`）、**Size to Fit**、**Grid** / **Snap** /
     **Rulers** 开关，以及带一键 `100%` 复位的 **Zoom** 滑块。
   - **用户可调整的三窗格分栏视图（`NSSplitViewDelegate`）：** 左导航侧栏
     默认 `220pt`（`180–340pt`），右检查器默认 `260pt`
     （`220–380pt`），两个侧栏在窗口调整大小时保持宽度，同时
     保留用户的分隔条调整。
   - **左侧栏（缩略图 + 带区 + 查询字段浏览器）：**
     - **交互式页面与带区缩略图（`MADMacDesignerMinimapView`）：** 按比例绘制
       报表带区，带颜色编码条纹、实时微型元素块，
       以及一个蓝色视口矩形；单击或拖动会跳转并选中该带区。
     - **报表带区大纲：** 列出所有报表和分组带区，带元素数量、
       高度和分页指示符；双击切换带区可见性。
     - **查询字段浏览器：** 所有 `RptqQueryField`
       列的可过滤列表（`NSSearchField`）；把字段拖到画布上任何带区带（或双击）
       会插入一个绑定的 `RptqDocumentElementLabelDataField`。
   - **中央交互式画布（`MADMacDesignerCanvasView`）：** 翻转、可缩放的
     `NSView` 画布，带水平/垂直标尺、纸张边距、颜色编码的带区
     带、带区高度拖动手柄、智能对齐参考线、网格吸附、框选
     选择、`Shift`-单击多选、8 点调整大小手柄、内联双击
     标签编辑、智能非重叠元素放置
     （`-nextAvailableOriginInSection:forElementSize:`），以及跨带区拖放
     （`-moveElement:toSection:atOrigin:`），带实时目标带区高亮和完整
     `NSUndoManager` 集成。
   - **右侧检查器侧栏（清晰分隔且可滚动）：**
     - **卡片 1（`1 · PAGE & SELECTED SECTION`）：** 纸张尺寸、选中带区徽标、
       带区高度（`pt`）及 **Fit Height** 按钮、**Section Visible**，以及 **Page Break
       After**。
     - **醒目的可视分隔线 + 第 2 节（`2 · SELECTED ELEMENT INSPECTOR`）：**
       4 张分组检查器卡片（**Element & Band Assignment**，带跨带区移动
       弹出、**Duplicate** 和 **Delete**；**Content & Data Binding**，带静态文本、
       查询字段绑定、聚合函数与范围、货币格式和条形码
       选项；**Typography & Appearance**，带字族/字号、粗体/斜体/下划线/
       删除线、水平/垂直对齐和文本/背景颜色；以及
       **Position, Size & Box Model**，带 `X`、`Y`、`W`、`H`，在
       `rect.origin` 和 `dropPoint` 间同步，另有边框、内边距和外边距）。
6. **MAD Viewer 工作区（`MADMacViewerViewController`）：**
   - **顶部查看器工具栏（`40pt` 高）：** **Page Size** 弹出（`MTPaper` 标准纸张类型：`US Letter`、`US Legal`、`US Tabloid`、`A3`、`A4`、`A5`、`B4`、`B5`、`JIS B4`、`JIS B5`）、**Refresh**（`Cmd+R`）、**Zoom** 控件（`-`、`100%`、`+`）、**Page Navigation**（`Previous`、`Page N of M`、`Next`）、**Print…**（`Cmd+P`，经由 `NSPrintOperation`）和 **Export…**（`Cmd+E`）。
   - **带框的分页预览（`PDFView`）：** 从本地 SQLite 表缓存（`MADDataTableFast`）按选定纸张尺寸渲染分页 PDF 页面，带页面阴影和底部状态栏（`statusBarView`），显示已渲染页数、缓存行数和纸张尺寸。
   - **多格式导出（`NSSavePanel`）：** 配置一个附件格式弹出，支持全部 7 个已注册导出器（`PDF`、`HTML`、`HTML Flow`、`CSV`、`JSON`、`JSON Report`、`Plain Text`），并动态更新保存面板的允许文件扩展名。

### 阶段 4：构建、冒烟验证与 GitHub Release 打包（已完成）

```sh
./Mac/build.sh --smoke-test --package
```

产出：
- `Mac/build/MAD Designer.app`（独立原生 macOS 应用包，内嵌并签名全部 12 个
  框架和遗留 Core Data `.momd` 模型）
- `Mac/build/MAD-Designer-macOS.zip`
- `Mac/build/MAD-Designer-macOS.dmg`

原生 macOS 应用的公开用户与开发者文档发布在 [`docs/macos.md`](../../macos.md)（截图位于 `docs/assets/macos-native-mad-query.png` 和 `docs/assets/macos-native-mad-designer.png`）以及 [`Mac/README.md`](../../../Mac/README.md)。

### 持续集成（已完成）

`.github/workflows/macos.yml` 在每次拉取请求和推送到 `master` 时运行。
它构建（并缓存）Compressor 静态库，然后在从
运行器发现的 iPhone 模拟器上运行 `MADBarcodes` 和 `MAD` 套件，构建 iOS `MAD Designer` scheme，并运行
`./Mac/build.sh --smoke-test`。“关于”窗口把引擎版本
（`MADMeta.plist`，`v9.0 (r4433)`）和 macOS 应用版本
（`CFBundleShortVersionString`，`v0.7`）作为不同的值分别报告，与
Windows“关于”窗口在 Phase-6f 之后的呈现一致。

`macos-latest` 是 arm64 运行器，`Mac/build.sh` 为
`platform=macOS,arch=arm64` 构建框架。首次运行会下载并编译每个锁定的
第三方来源（针对三个平台，约 15–40 分钟）；之后的运行
从 Actions 缓存恢复 `Compressor/library`，ensure 步骤则空操作。
freetds 配方从 Savannah 获取 `config.guess`/`config.sub` 一次且
不重试，因此工作流会先播种 `Compressor/media`（参见该工作流的
注释）。一处残余，而非构建失败：libarchive 的 configure 步骤找到的是
SDK 的 `libbz2.tbd`，而非 Compressor 的 bzip2 安装，因为
`BZIP2_LIBRARY` 不是现代 CMake 的 `FindBZIP2` 所读取的提示；SDK
库存在，应用处理 bzip2 xcframework。
