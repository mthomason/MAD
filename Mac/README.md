# Mac — the native macOS (`AppKit`) application

`Mac/` contains the native macOS (`AppKit`, `macosx` SDK, `MACOSX_DEPLOYMENT_TARGET = 12.0`) frontend for **MAD Designer**, built over the twelve multiplatform MAD frameworks (`MADFoundation`, `MADDataStructures`, `MADCocoaExtensions`, `MADFileManager`, `MADAPI`, `MADSqlite3`, `MADTds`, `MADTdsClient`, `MADMySQL`, `MADPostgres`, `MADBarcodes`, and `MAD`) and the ten universal (`arm64` + `x86_64`) static C libraries built by `Compressor`.

For the user-facing workspace overview and screenshots, see [`docs/macos.md`](../docs/macos.md). For the framework-by-framework portability audit and architecture record, see [`docs/project/MAD_MACOS.md`](../docs/project/MAD_MACOS.md).

## Running it

```sh
./Mac/build.sh                     # build 12 macOS frameworks + Mac/build/MAD Designer.app
./Mac/build.sh --no-frameworks     # rebuild only MAD Designer.app (fast iteration)
./Mac/build.sh --smoke-test        # build and run the end-to-end macOS smoke suite
./Mac/build.sh --package           # create Mac/build/MAD-Designer-macOS.zip and .dmg
```

You can also build, run, and debug the application directly in Xcode by opening `Reports.xcworkspace`, selecting the **`MAD Designer Mac`** shared scheme, and choosing the **My Mac** destination.

## Layout

* `Mac/Source/` — `AppKit` application, `NSDocument` architecture, and the three workspaces:
  * `MADMacAppDelegate.{h,m}` — application lifecycle, driver/converter registration, and main menu bar (`MAD Designer`, `File`, `Edit`, `View`, `Report`, `Window`, `Help`).
  * `MADMacAboutWindowController.{h,m}` — native **About MAD Designer** window (`Overview`, `License & Notice`, and `Acknowledgements` with component sidebar and bundled third-party license texts).
  * `MADMacDocumentController.{h,m}` — `NSDocumentController` subclass configuring the standard Open Panel with `.mad` `UTType` filters (`com.everydayapps.productivity.mad` and `com.thomason.report.mad`) and a primary **New Document** button.
  * `MADMacDocument.{h,m}` — `NSDocument` wrapper over `MADHeadlessDocument`, `MADDesignerLayout` (`NSUndoManager`), `MADSectionsLayout`, asynchronous refresh (`MADOperationQueue`), and export.
  * `MADMacWindowController.{h,m}` — main document window with the centered **Workspace** segmented control (`MAD Query`, `MAD Designer`, `MAD Viewer`).
  * `MADMacConnectionWindowController.{h,m}` — database connection and schema import assistant supporting SQLite, MySQL, Microsoft SQL Server, and PostgreSQL with `MADKeyChain` credential storage.
  * `MADMacQueryViewController.{h,m}` — **MAD Query** workspace with the visual table/join canvas (`MADMacQueryCanvasView`, `MADMacQueryTableCardView`, `MADMacQueryLinksOverlayView`), filter/grouping popovers, and the full-width SQL Query editor (`MADSQLParser` / `MADSQLQueryCompiler`).
  * `MADMacDesignerViewController.{h,m}` & `MADMacDesignerCanvasView.{h,m}` — **MAD Designer** workspace with the element palette, interactive Page & Section Minimap (`MADMacDesignerMinimapView`), Report Bands outline, Query Fields drag source, zoomable/ruled design canvas, and dual-card right inspector.
  * `MADMacViewerViewController.{h,m}` — **MAD Viewer** workspace with paper size selection (`MTPaper`), refresh, zoom/page navigation, framed `PDFView` rendering, status bar, `NSPrintOperation` printing, and 7-format export (`PDF`, `HTML`, `HTML Flow`, `CSV`, `JSON`, `JSON Report`, `Plain Text`).
* `Mac/Resources/Info.plist` — bundle metadata and `.mad` document type / UTI declarations.
* `Mac/Tests/MADMacSmokeTest.m` — end-to-end verification executable exercising bundle structure, schema import, visual query design, SQL entry, designer canvas/minimap/inspector mutations, undo/redo, data refresh, and all seven export formats.
