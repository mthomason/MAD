[English](README.md) | **简体中文** | [日本語](README_ja.md) | [Português (Brasil)](README_pt-BR.md)

# <a href="../StaticResources/Images/icons/document/Designer%20Icon@3x.png"><img src="../docs/assets/mad-designer-macos-icon-256.png" alt="MAD Designer 图标" width="44" height="44" align="absmiddle" /></a> Mac —— 原生 macOS（`AppKit`）应用

`Mac/` 包含 **MAD Designer** 的原生 macOS 前端（`AppKit`、`macosx` SDK、`MACOSX_DEPLOYMENT_TARGET = 12.0`），它构建在十二个多平台 MAD 框架（`MADFoundation`、`MADDataStructures`、`MADCocoaExtensions`、`MADFileManager`、`MADAPI`、`MADSqlite3`、`MADTds`、`MADTdsClient`、`MADMySQL`、`MADPostgres`、`MADBarcodes` 和 `MAD`）以及由 `Compressor` 构建的十个通用（`arm64` + `x86_64`）静态 C 库之上。

面向用户的工作区概览和截图参见 [`docs/macos.md`](../docs/zh/macos.md)。逐框架的可移植性审计和架构记录参见 [`docs/project/MAD_MACOS.md`](../docs/zh/project/MAD_MACOS.md)。

## 运行

```sh
./Mac/build.sh                     # build 12 macOS frameworks + Mac/build/MAD Designer.app
./Mac/build.sh --no-frameworks     # rebuild only MAD Designer.app (fast iteration)
./Mac/build.sh --smoke-test        # build and run the end-to-end macOS smoke suite
./Mac/build.sh --package           # create Mac/build/MAD-Designer-macOS.zip and .dmg
```

你也可以直接在 Xcode 中构建、运行和调试该应用：打开 `Reports.xcworkspace`，选择 **`MAD Designer Mac`** 共享方案，并选择 **My Mac** 作为目标。

## 布局

* `Mac/Source/` —— `AppKit` 应用、`NSDocument` 架构，以及三个工作区：
  * `MADMacAppDelegate.{h,m}` —— 应用生命周期、驱动/转换器注册，以及主菜单栏（`MAD Designer`、`File`、`Edit`、`View`、`Report`、`Window`、`Help`）。
  * `MADMacAboutWindowController.{h,m}` —— 原生的 **About MAD Designer** 窗口（`Overview`、`License & Notice`，以及带组件侧边栏和随附第三方许可证文本的 `Acknowledgements`）。
  * `MADMacDocumentController.{h,m}` —— `NSDocumentController` 子类，配置标准打开面板，带 `.mad` `UTType` 过滤器（`com.everydayapps.productivity.mad` 和 `com.thomason.report.mad`）以及主 **New Document** 按钮。
  * `MADMacDocument.{h,m}` —— 对 `MADHeadlessDocument`、`MADDesignerLayout`（`NSUndoManager`）、`MADSectionsLayout`、异步刷新（`MADOperationQueue`）和导出的 `NSDocument` 封装。
  * `MADMacWindowController.{h,m}` —— 主文档窗口，带有居中的 **Workspace** 分段控件（`MAD Query`、`MAD Designer`、`MAD Viewer`）。
  * `MADMacConnectionWindowController.{h,m}` —— 数据库连接和架构导入助手，支持 SQLite、MySQL、Microsoft SQL Server 和 PostgreSQL，使用 `MADKeyChain` 存储凭据。
  * `MADMacQueryViewController.{h,m}` —— **MAD Query** 工作区，包含可视化表/连接画布（`MADMacQueryCanvasView`、`MADMacQueryTableCardView`、`MADMacQueryLinksOverlayView`）、过滤/分组弹出框，以及全宽 SQL 查询编辑器（`MADSQLParser` / `MADSQLQueryCompiler`）。
  * `MADMacDesignerViewController.{h,m}` & `MADMacDesignerCanvasView.{h,m}` —— **MAD Designer** 工作区，包含元素面板、交互式页面与节区缩略图（`MADMacDesignerMinimapView`）、报表带区大纲、查询字段拖放源、可缩放/带标尺的设计画布，以及双卡片式右侧检查器。
  * `MADMacViewerViewController.{h,m}` —— **MAD Viewer** 工作区，包含纸张大小选择（`MTPaper`）、刷新、缩放/页面导航、带框的 `PDFView` 渲染、状态栏、`NSPrintOperation` 打印，以及 7 种格式导出（`PDF`、`HTML`、`HTML Flow`、`CSV`、`JSON`、`JSON Report`、`Plain Text`）。
* `Mac/Resources/Info.plist` —— 捆绑包元数据以及 `.mad` 文档类型/UTI 声明。
* `Mac/Tests/MADMacSmokeTest.m` —— 端到端验证可执行文件，覆盖捆绑包结构、架构导入、可视化查询设计、SQL 输入、设计器画布/缩略图/检查器的变更、撤销/重做、数据刷新，以及全部七种导出格式。
