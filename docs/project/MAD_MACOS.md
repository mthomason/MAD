# `MAD_MACOS.md` -- Multiplatform Frameworks and the Native macOS Application

This document records the architecture decision, the framework-by-framework portability
audit, and the phased migration and implementation plan for making the MAD frameworks
genuinely multiplatform (`iphoneos`, `iphonesimulator`, `macosx`, and headless Linux)
and building the native macOS (`AppKit`) frontend for **MAD Designer**.

---

## 1. Decision: Native macOS (`AppKit`) vs. Mac Catalyst

**Decision:** Build a **native macOS application (`macosx` SDK, `AppKit`)** over shared
multiplatform frameworks (`MACOSX_DEPLOYMENT_TARGET = 12.0`, supporting every Apple
Silicon Mac and Intel Macs on Monterey or newer). **Mac Catalyst is rejected.**

### Why Native macOS Wins

| Dimension | Native macOS (`macosx` / `AppKit`) | Mac Catalyst (`maccatalyst` / `UIKit`) |
|---|---|---|
| **Static C libraries (`Compressor`)** | **Already built.** All 10 `.xcframework` bundles in `Compressor/library/` carry universal `macosx` (`arm64` + `x86_64`, `-mmacosx-version-min=11.0`) slices verified by `./Compressor/build.sh --verify --all --platforms ios,simulator,macosx`. | **Missing.** Zero `maccatalyst` slices (`-target <arch>-apple-ios15.0-macabi`) exist. The Mach-O linker rejects linking `MACOS` archives into `MACCATALYST` binaries; Catalyst would require adding a 4th platform to `Compressor` and rebuilding all 10 C libraries (`openssl`, `mariadb`, `postgres`, `freetds`, `libarchive`, `sqlite3`, `zint`, `libpng`, `bzip2`, `zlib`). |
| **Core engine portability** | **90% complete.** The Linux headless port (`MAD_LINUX.md`) already removed Core Data from `MAD.framework`, decoupled database drivers (`MADDatabaseDriverRegistry`) and report exporters (`MADReportExporterRegistry`), and introduced `MADHeadlessDocument`, `MADSQLQueryCompiler`, and `MADDesignerLayout`. | Same engine, but tied to `UIDocument` and iOS background task lifecycles. |
| **Desktop ergonomics** | Native `NSDocument` / `NSDocumentController` (Finder double-click, `Cmd+N`, `Cmd+O`, `Cmd+S`, `Cmd+Shift+S`, Recent Documents, window restoration, `NSUndoManager`), native split views, native table/outline views, native `PDFView` / `WKWebView`, and standard macOS menus. | Nested zooming `UIScrollView` + `UICollectionView` sections, iOS tab/navigation bars, `UIPickerView` wheels, and iOS sandboxed document browser (`MADExplorer`). Apple Silicon Macs already run the iPad build via *Designed for iPad*. |
| **Distribution via GitHub** | Clean standalone `.app` bundle packaged as a downloadable `.dmg` and `.zip` on GitHub Releases (`arm64` + `x86_64`). | Requires Catalyst provisioning profile and entitlements mismatching outside-the-App-Store distribution ergonomics. |

---

## 2. Static Library Audit (`Compressor`)

All ten vendored C libraries in `Compressor` build universal `macosx` (`arm64` + `x86_64`)
slices with `-mmacosx-version-min=11.0`:

| Library | Version | `ios` (`arm64`) | `simulator` (`arm64` + `x86_64`) | `macosx` (`arm64` + `x86_64`) | Used By |
|---|---|:---:|:---:|:---:|---|
| `sqlite3` | 3.53.3 | Yes | Yes | Yes | `MADSqlite3`, `MAD` |
| `zlib` | 1.3.2 | Yes | Yes | Yes | `MAD`, `MADMySQL`, `MADPostgres`, `MADBarcodes` |
| `openssl` | 3.5.9 | Yes | Yes | Yes | `MADTds`, `MADMySQL`, `MADPostgres` |
| `bzip2` | 1.0.8 | Yes | Yes | Yes | `MAD` |
| `libpng` | 1.6.59 | Yes | Yes | Yes | `MADBarcodes` |
| `libarchive` | 3.8.9 | Yes | Yes | Yes | `MAD` |
| `freetds` | 1.4.27 | Yes | Yes | Yes | `MADTds`, `MADTdsClient` |
| `mariadb` | 3.4.11 | Yes | Yes | Yes | `MADMySQL` |
| `postgres` | 17.11 | Yes | Yes | Yes | `MADPostgres` |
| `zint` | 2.16.0 | Yes | Yes | Yes | `MADBarcodes` |

Verification command:

```sh
./Compressor/build.sh --verify --all --platforms ios,simulator,macosx
```

---

## 3. Framework-by-Framework Multiplatform Audit

Twelve frameworks form the multiplatform stack (`iphoneos`, `iphonesimulator`, `macosx`,
plus Linux for the eleven headless frameworks):

1. **`MADFoundation`** (28 `.m` files):
   - `MADApplication.h`: guard `<UIKit/UIApplication.h>` with `#if TARGET_OS_IPHONE`
     instead of `#if __APPLE__` (`MADApplication.m` already has
     `#elif TARGET_OS_OSX #import <AppKit/NSApplication.h>`).
   - `MADURLFactory.m`: guard `<UIKit/UIScreen.h>` with `#if TARGET_OS_IPHONE` and use
     `NSScreen.mainScreen.backingScaleFactor > 1.0` on `TARGET_OS_OSX`.
   - `MADKeyChain.m`: uses `Security.framework`, which is native on both iOS and macOS.
2. **`MADDataStructures`** (17 `.m` files):
   - Pure Foundation + C++. Zero source changes required.
3. **`MADFileManager`** (11 `.m` files):
   - Remove the unused `#import <MobileCoreServices/UTType.h>` in
     `MADMetaDataLocal.m:16` (`<UniformTypeIdentifiers/UTType.h>` is already imported on
     line 17).
4. **`MADCocoaExtensions`** (17 `.m` files):
   - `CGGeometry+Extras.h`: provide `UIEdgeInsets` (`NSEdgeInsets`-compatible layout
     struct + `UIEdgeInsetsMake` / `UIEdgeInsetsZero` / `UIEdgeInsetsEqualToEdgeInsets`),
     `NSStringFromCGPoint` / `NSStringFromCGSize` / `NSStringFromCGRect`, and
     `NSValue (MADCGGeometryExtensions)` (`valueWithCGPoint:`, `CGPointValue`,
     `valueWithCGRect:`, `CGRectValue`, `valueWithCGSize:`, `CGSizeValue`) on
     `TARGET_OS_OSX`.
   - `MADColor.h` / `MADColor.m`: bridge `MADColor` to `NSColor` on `TARGET_OS_OSX` while
     keeping `UIColor` on `TARGET_OS_IPHONE`.
   - Guard the iOS-only `UIView`, `UIAlertController`, `UITextField`, and `UIColor`
     categories with `#if TARGET_OS_IPHONE`.
5. **`MADAPI`** (11 `.m` files):
   - 9 core database, query, and driver-registry files are pure Foundation.
   - Guard `MADConnectionViewController` and `MADConnectionSQLGenericViewController`
     with `#if TARGET_OS_IPHONE`.
6. **`MADSqlite3`** (26 `.m` files):
   - Pure Foundation + `sqlite3.xcframework`. Zero source changes required.
7. **`MADTds`** (1 `.m` file):
   - Pure Foundation + `freetds.xcframework` + `openssl.xcframework`. Zero source
     changes required.
8. **`MADTdsClient`** (4 `.m` files):
   - `MADDatabaseSQLServer`, `MADTdsConnection`, and `MADDataTypeSQLServer` are pure
     Foundation. Guard `MADTdsConnectionViewController` with `#if TARGET_OS_IPHONE`.
9. **`MADMySQL`** (19 `.m` files):
   - 18 driver files are pure Foundation + `mariadb.xcframework`. Guard
     `MADMySQLConnectionViewController` with `#if TARGET_OS_IPHONE`.
10. **`MADPostgres`** (5 `.m` files):
    - 4 driver files are pure Foundation + `postgres.xcframework`. Guard
      `MADPostgresConnectionViewController` with `#if TARGET_OS_IPHONE`.
11. **`MADBarcodes`** (70 `.m` files):
    - 67 symbology classes are pure Foundation + `zint.xcframework`.
    - `MADBarcode`, `MADBarcodeCache`, and `MADBarcodeView`: bridge `UIImage` / `NSImage`
      and `UIView` / `NSView` on `TARGET_OS_OSX` over the existing `CGImageRef`
      `MADBarcodeImageFromZintBitmap` pipeline.
12. **`MAD`** (199 `.m` files):
    - Replace `#if __APPLE__` with `#if TARGET_OS_IPHONE` and `#elif TARGET_OS_OSX`
      AppKit bridges across the 9 shared model/rendering files (`RptqObject.m`,
      `RptqDocumentElementImage+Extras.m`, `RptqDocument+Extras.m`,
      `RptqDocumentSection+Extras.m`, `RptqDocumentElement+Extras.m`,
      `MADPrintPageElement.m`, `MADElementStylizedText.m`, `MADFonts.m`, and
      `MADReportExporterPDF.m`).
    - In `MADReportExporterPDF.m`, render paginated PDFs on `TARGET_OS_OSX` using
      `CGPDFContextCreateWithURL` / `CGPDFConsumerCreateWithCFData` and
      `NSGraphicsContext` (`+graphicsContextWithCGContext:flipped:YES`), so
      `MADPrintPageRenderer` and `MADPrintPageElement` draw natively on macOS.
    - Guard the 22 iOS-only `UIDocument` (`MADocument`), `UIView`, and
      `UICollectionViewLayout` files with `#if TARGET_OS_IPHONE`.

`MADExplorer` remains iOS-only (macOS uses `NSDocumentController`, Finder, `NSOpenPanel`,
and a native Welcome window). `MADFeedback` and `Scrimpter` remain unused per
`AGENTS.md`.

---

## 4. Phased Implementation Plan

### Phase 1: Bug Fixes & Multiplatform Framework Enablement (Completed)

1. **Fixed 6 defects surfaced during the macOS audit & port** and archived them from
   `docs/project/BUGS.md` to `docs/project/BUGS_FIXED.md` with unit tests:
   - `MADKeyChain` (`MADFoundation/Source/MADKeyChain.m`): stopped requesting
     `kSecReturnData : @YES` (and leaking the returned `CFDataRef`) in
     `+credentialsExist:`, `+saveToken:forKey:withDescription:`, `+deleteKey:`, and
     `+deleteSavedPasswordForKey:error:`.
   - `MADURLFactory` (`MADFoundation/Source/MADURLFactory.m`): guarded
     `+newURLForLocalApplicationSupportDirectory` when `[NSBundle mainBundle].bundleIdentifier`
     is `nil` (falling back to `[MADApplication groupIdentifier]`), and guarded
     `containerURLForSecurityApplicationGroupIdentifier:` with
     `#if defined(__APPLE__) && TARGET_OS_IPHONE` so unentitled macOS processes use
     standard per-user directories instead of triggering TCC prompts on
     `~/Library/Group Containers/`.
   - `MADDataTable` (`MADFoundation/Source/MADDataTable.m`): guarded
     `NSDataWritingFileProtectionCompleteUnlessOpen` with
     `#if defined(__APPLE__) && TARGET_OS_IPHONE` so unentitled macOS cache writes succeed.
   - `MADDatabaseSqlite3` (`MADSqlite3/Source/MADDatabaseSqlite3.m`): guarded
     `[dataTable endBulkInsert]` with `if (rowCounter > 0)` so zero-row `SELECT` queries
     do not execute `COMMIT TRANSACTION` when `[dataTable beginBulkInsert]` was never
     called.
   - `MADBarcode` (`MADBarcodes/MADBarcodes/MADBarcodes/MADBarcode.m`): fixed
     `-drawInRect:` doubling `rect.origin` when `self.center == YES`.
   - `MADDesignerLayout` (`MAD/Source/MADDesignerLayout.m`): preserved each selected
     element's own prior value in a dictionary when registering undo actions across all
     bulk-update methods (`setFontsize:`, `setFontname:`, `setVerticalAlignment:`,
     `setHorizontalAlignment:`, `setSizeWidth:`, `setSizeHeight:`, `setMargin*`,
     `setPadding*`, `setBorder*`).
2. **Enabled `macosx` across the 12 framework Xcode projects:**
   - Set `SUPPORTED_PLATFORMS = "iphoneos iphonesimulator macosx"` and
     `MACOSX_DEPLOYMENT_TARGET = 12.0`.
   - Added `platformFilters = (ios, maccatalyst, );` on `UIKit.framework` references and
     linked `AppKit.framework` with `platformFilters = (macos, );` where needed.
   - Updated `Ensure Libraries` build phases to pass
     `--platforms ios,simulator,macosx`.
3. **Verified all 12 frameworks on native macOS (`-destination 'platform=macOS,arch=arm64'`):**
   - `MADFoundation`: **199 tests passed, 0 failures**
   - `MADDataStructures`: **72 tests passed, 0 failures**
   - `MADCocoaExtensions`: **80 tests passed, 0 failures**
   - `MADFileManager`: **85 tests passed, 0 failures**
   - `MADAPI`: **106 tests passed, 0 failures**
   - `MADSqlite3`: **118 tests passed (5 benchmarks skipped), 0 failures**
   - `MADTds`: **Built cleanly for `macosx`**
   - `MADTdsClient`: **77 tests passed (including live SQL Server suite), 0 failures**
   - `MADMySQL`: **All offline & live MariaDB/MySQL tests passed, 0 failures**
   - `MADPostgres`: **31 tests passed (including live PostgreSQL suite), 0 failures**
   - `MADBarcodes`: **30 tests passed, 0 failures**
   - `MAD`: **650 tests passed, 0 failures**

### Phase 2: Multiplatform Schema-Import & `NSDocument` Layer (Completed)

1. **Multiplatform Document Creation & Schema Import (`MADHeadlessDocument`):**
   - Added `+createDocumentAtURL:withDatabaseConnection:credentials:error:` on
     `MADHeadlessDocument` (`MAD/Source/MADHeadlessDocument.h`, `.m`), which connects to
     any registered driver (`SQLite3`, `MySQL`, `SQL Server`, `PostgreSQL`), imports all
     database tables (`-getTablesFromConnection:error:`) and columns
     (`-fieldsForTable:connection:error:`) into `RptqDatabaseSchemaTable` /
     `RptqDatabaseSchemaField`, initializes the standard report sections (`Report Header`,
     `Page Header`, `Report Detail`, `Page Footer`, `Report Footer`), and writes the
     portable `.mad` container.
2. **`MADMacDocument` (`NSDocument` subclass in `Mac/Source/MADMacDocument.m`):**
   - Wraps `MADHeadlessDocument` (with automatic legacy Core Data `.mad` conversion via
     `MADStoreConverter` when needed), conforms to `MADocumentDesignerProtocol` so
     `MADDesignerLayout` records undo/redo directly onto `NSDocument.undoManager`, and
     supports `readFromURL:ofType:error:`,
     `writeToURL:ofType:forSaveOperation:originalContentsURL:error:`, and asynchronous
     `refreshWithCredentials:maxRows:completion:`.

### Phase 3: Native macOS Application (`Mac/`) (Completed)

Built under `Mac/` (`Mac/Source/`, `Mac/Resources/`, `Mac/Tests/`, `Mac/build.sh`):

1. **Application Lifecycle & Sample Reports (`MADMacAppDelegate`):**
   - Installs bundled `chinook.sqlite3`, `London.mad`, and `Music.mad` into
     `~/Library/Application Support/group.com.thomason.report.local/`, provides a native
     macOS main menu (`File`, `Edit` with `Undo`/`Redo`, `View` workspace switching,
     `Window`, `Help`), **Open Sample Report** (`London.mad`, `Music.mad`), and a
     **New Report from Database Connection…** (`Cmd+Shift+N`) assistant.
2. **Database Connection & Schema Import Assistant (`MADMacConnectionWindowController`):**
   - Supports **SQLite3** (bundled Chinook database or custom `.sqlite3`/`.db` file via
     `NSOpenPanel`), **MySQL / MariaDB**, **Microsoft SQL Server**, and **PostgreSQL**,
     with **Test Connection**, `MADKeyChain` password storage, and **Create Report…**
     (`NSSavePanel`).
3. **MAD Query Workspace (`MADMacQueryViewController`):**
   - Mutually exclusive **Query Designer** and **SQL Query** workspace modes (toggled in
     the workspace header bar so visual query design and manual SQL entry are never
     shown simultaneously).
   - **Query Designer mode**: A `200px` left-hand **Database Tables** list (user-resizable
     via `NSSplitViewDelegate` without snapping back, and held at a fixed width when the
     window is resized so the visual canvas resizes instead) paired with an interactive
     right-hand visual canvas (`MADMacQueryCanvasView`). Double-clicking a schema table
     adds it to the query (populating all `RptqQueryField` rows) and displays it as a
     draggable, resizable floating AppKit table card (`MADMacQueryTableCardView` +
     `MADMacQueryFieldTableView`) styled with topological root/child headers (`MTGraph`),
     and dragging from a field in one table card to a field in another creates a default
     **Left Outer Join** (`MADLinkTypeLeftOuterJoin`) drawn via Bezier connectors and
     join-type badges (`MADMacQueryLinksOverlayView`, matching iPad's `MADConnectorView`).
     Clicking or right-clicking a visual join connector opens a join inspector popover or
     context menu to change the link type, swap direction, or delete the link; header
     popovers provide **Filters (WHERE)** and **Groupings (GROUP BY)** editors.
   - **SQL Query mode**: Full-width SQL statement editor displaying generated or entered
     SQL and supporting validation, compilation, and application (`MADSQLParser` +
     `MADSQLStatementResolver` + `MADSQLQueryCompiler`).
4. **MAD Designer Workspace (`MADMacDesignerViewController` + `MADMacDesignerCanvasView` + `MADMacDesignerMinimapView`):**
   - **Top Workspace Bar (`38pt` height):** Provides clickable and draggable SF Symbol
     element palette items (**Label**, **Data Field**, **Aggregate**, **Barcode**,
     **Image**, **Line**), quick multi-element alignment controls (`Left`, `Center`,
     `Right`, `Top`, `Middle`, `Bottom`), **Size to Fit**, **Grid** / **Snap** /
     **Rulers** toggles, and a **Zoom** slider with one-click `100%` reset.
   - **User-Resizable 3-Pane Split View (`NSSplitViewDelegate`):** Left navigator sidebar
     defaults to `220pt` (`180–340pt`), right inspector defaults to `260pt`
     (`220–380pt`), and both sidebars hold their widths across window resizes while
     preserving user divider adjustments.
   - **Left Sidebar (Minimap + Bands + Query Fields Browser):**
     - **Interactive Page & Section Minimap (`MADMacDesignerMinimapView`):** Draws
       proportional report bands with color-coded stripes, live miniature element blocks,
       and a blue viewport rectangle; clicking or dragging jumps to and selects the band.
     - **Report Bands Outline:** Lists all report and group sections with element counts,
       heights, and page-break indicators; double-clicking toggles band visibility.
     - **Query Fields Browser:** Filterable list (`NSSearchField`) of all `RptqQueryField`
       columns; dragging a field onto any section band on the canvas (or double-clicking)
       inserts a bound `RptqDocumentElementLabelDataField`.
   - **Center Interactive Canvas (`MADMacDesignerCanvasView`):** Flipped, zoomable
     `NSView` canvas with horizontal/vertical rulers, paper margins, color-coded section
     bands, section height drag handles, smart alignment guides, grid snapping, marquee
     selection, `Shift`-click multi-selection, 8-point resize handles, inline double-click
     label editing, smart non-overlapping element placement
     (`-nextAvailableOriginInSection:forElementSize:`), and cross-section drag-and-drop
     (`-moveElement:toSection:atOrigin:`) with live target band highlighting and full
     `NSUndoManager` integration.
   - **Right Inspector Sidebar (Clearly Divided & Scrollable):**
     - **Card 1 (`1 · PAGE & SELECTED SECTION`):** Paper size, selected band badge,
       band height (`pt`) with **Fit** button, **Visible in Report**, and **Page Break
       After Section**.
     - **Prominent Visual Divider + Section 2 (`2 · SELECTED ELEMENT INSPECTOR`):**
       4 grouped inspector cards (**Element & Band Assignment** with cross-section move
       popup, **Duplicate**, and **Delete**; **Content & Data Binding** with static text,
       query field binding, aggregate function & scope, currency formatting, and barcode
       options; **Typography & Appearance** with font family/size, bold/italic/underline/
       strikethrough, horizontal/vertical alignment, and text/background colors; and
       **Position, Size & Box Model** with `X`, `Y`, `W`, `H` synchronized across both
       `rect.origin` and `dropPoint`, plus borders, padding, and margin).
5. **MAD Viewer Workspace (`MADMacViewerViewController`):**
   - Three preview tabs: **Paginated Report (PDF)** (`PDFView`), **HTML Preview**
     (`WKWebView`), and **Cached Data Grid** (`NSTableView`), plus one-click export to all
     7 registered formats (`PDF`, `HTML`, `HTML Flow`, `CSV`, `JSON`, `JSON Report`,
     `Plain Text`) and native `NSPrintOperation` printing (`Cmd+P`).

### Phase 4: Build, Smoke Verification & GitHub Release Packaging (Completed)

```sh
./Mac/build.sh --smoke-test --package
```

Produces:
- `Mac/build/MAD Designer.app` (standalone native macOS app bundle with all 12
  frameworks, legacy Core Data `.momd` models, and sample reports embedded and signed)
- `Mac/build/MAD-Designer-macOS.zip`
- `Mac/build/MAD-Designer-macOS.dmg`
