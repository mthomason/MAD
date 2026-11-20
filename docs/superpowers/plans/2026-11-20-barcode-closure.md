# Barcode Closure Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make barcode elements render headlessly on Linux and Windows (HTML/JSON exports embed a data-URI PNG), and give the Windows WPF designer the same barcode creation and editing capabilities as iOS and macOS.

**Architecture:** `MADBarcodes` grows a UIKit-free render core: `MADBarcode` keeps one zint encode path and gains `-renderedPNGData` (libpng's simplified write API over zint's RGB bitmap), while every UIKit/AppKit draw path stays behind `#if __APPLE__`. The framework, libpng and zint join the Linux and Windows builds; `MAD` links the framework, and `MADPrintPageElementBarcode` exposes the PNG to the page walk so the exporters can embed it. `mad serve` grows a barcode element kind, barcode content editing and a symbology catalogue; the WPF designer consumes them for palette insert, canvas preview and inspector options.

**Tech Stack:** Objective-C (ARC), zint 2.16.0 (BSD-3-Clause), libpng 1.6.59, CMake (Linux), PowerShell + clang (Windows engine), WPF/.NET 10 (Windows app), GNUstep Testing.h (headless suites), xUnit (WPF suites).

**Spec:** `C:\dev\MAD-Windows-DevEnv\BARCODE_CLOSURE.md` (with `docs/archive/MAD_BARCODES.md` §1 and §5 as background).

## Global Constraints

- Tabs for indentation in all Objective-C/C/CMake/shell sources; 4-space C# per the existing files.
- No `stringWithFormat:`; use `initWithFormat:` / `appendFormat:` / `stringWithFormat:` only where the file already does (the house rule applies to new code).
- Every Apple-only drawing path stays behind `#if __APPLE__`; never introduce `TARGET_OS_*` where the GNUstep shim is absent.
- zint is pinned at 2.16.0 (sha256 `e1077fd5846bdd0128fef3ab8c3c28e93e450d2efaf1424d0aa96e0c9e514591`); libpng at 1.6.59 (sha256 `86a3e4b501f7f50e392c4e456ea158893e9a595b1c63eb88c7bb9f6cf8772dad`). Do not reimplement a barcode encoder.
- Element type is `MADPrintPageElementTypeBarcode = 9`; the store schema already has every barcode column (no migration).
- A document without barcodes must export byte-for-byte the same HTML/JSON as before: the London pins in `Windows/App/Mad.Designer.Windows.Tests/SmokeTests.cs` and the FNV checksums in `Linux/Tests/MADReportExporterTests.m` are the guard.
- Branch `barcode-closure` from `master`; every commit `-s` (DCO). Push and open a ready PR only after the approval described in `AGENTS.md` (the task document supplies it).
- Apple XCTest suites cannot be run on this Windows workstation; the Apple code must remain compile-correct by inspection and by keeping changes inside the existing `#if __APPLE__` shapes.

## Review Focus

1. A barcode element with a **static input and no query field** must render its static text and export it, not crash on a nil dictionary key (existing `MADPrintPageElementBarcode` reads `rowData[fieldKey]` unconditionally).
2. A barcode whose zint encode **fails** (invalid data for the symbology) must export the line's text and no `<img>`, not a corrupt PNG or a crash.
3. A **long/UTF-8 input** must not overflow zint's fixed `primary[128]` buffer on the second input.
4. Documents **without barcodes** must keep the pinned London export bytes exactly (no unconditional JSON member, no shared CSS change).
5. The **Apple** `drawInRect:` / `MADBarcodeCache` path must keep its current behaviour: same zint options, same error messages, same image type.
6. The Windows designer must survive a barcode element whose **preview PNG is absent** (zint failure) — text fallback, no null dereference.

---

### Task 1: Pin zint and libpng in the Linux and Windows library builds

**Files:**
- Modify: `Linux/libraries.conf`
- Modify: `Linux/lib/libraries.sh` (add `build_libpng`, `build_zint`)
- Modify: `Windows/Engine/libraries.conf`
- Modify: `Windows/Engine/build.ps1` (build libpng + zint; add their archives to `$archiveLibs`)

**Interfaces:**
- Produces: `/usr/local/lib/libpng.a`, `/usr/local/lib/libzint.a`, `/usr/local/include/{png.h,pngconf.h,pnglibconf.h,zint.h}` on Linux; `$BuildDir\libs\libpng-install` and `$BuildDir\libs\zint-install` (or equivalent vars `$libpngLib`, `$libpngInclude`, `$zintLib`, `$zintInclude`) on Windows.

- [ ] **Step 1: Add the pins.** Append to both `libraries.conf` files, matching the existing column alignment:

```
libpng   1.6.59  -  -  86a3e4b501f7f50e392c4e456ea158893e9a595b1c63eb88c7bb9f6cf8772dad  https://download.sourceforge.net/libpng/libpng-1.6.59.tar.gz
zint     2.16.0  -  -  e1077fd5846bdd0128fef3ab8c3c28e93e450d2efaf1424d0aa96e0c9e514591  https://github.com/zint/zint/archive/refs/tags/2.16.0.tar.gz
```

Order matters: both are appended after `zlib` (already present) and `libpng` before `zint`.

- [ ] **Step 2: Implement `build_libpng` and `build_zint` in `Linux/lib/libraries.sh`.** `build_libpng` runs `./configure --prefix="${PREFIX}" --disable-shared --enable-static` with `CPPFLAGS="-I${PREFIX}/include" LDFLAGS="-L${PREFIX}/lib"`, then `make`/`make install`. `build_zint` mirrors `Compressor/lib/recipes/zint.sh`: CMake with `-DCMAKE_POLICY_VERSION_MINIMUM=3.5 -DZINT_SHARED=OFF -DZINT_STATIC=ON -DZINT_FRONTEND=OFF -DZINT_USE_PNG=ON -DPNG_INCLUDE_DIR="${PREFIX}/include" -DPNG_LIBRARY="${PREFIX}/lib/libpng.a" -DZLIB_INCLUDE_DIR="${PREFIX}/include" -DZLIB_LIBRARY="${PREFIX}/lib/libz.a"`, builds target `zint-static`, installs, and ensures `${PREFIX}/include/zint.h` exists (copy `backend/zint.h` if the install does not place it).

- [ ] **Step 3: Add the Windows builds.** After the zlib block, build libpng with `cmake -G Ninja -DCMAKE_C_COMPILER=clang-cl -DCMAKE_BUILD_TYPE=Release -DPNG_SHARED=OFF -DPNG_STATIC=ON -DPNG_TESTS=OFF -DPNG_TOOLS=OFF -DZLIB_LIBRARY=$zlibLib -DZLIB_INCLUDE_DIR=$zlibDir -DCMAKE_INSTALL_PREFIX=<libpng-install>` and `cmake --build ... --target png_static_static` (fall back to the default target if that name is absent) then `cmake --install`. After it, build zint the same way the Apple recipe does with `clang-cl`, installing into `<zint-install>`. Set `$libpngLib`/`$zintLib` to the installed static archives and `$libpngInclude`/`$zintInclude`. Add `$libpngLib, $zintLib` to `$archiveLibs` immediately before `$zlibLib`.

- [ ] **Step 4: Verify the libraries build.** Linux: `./Linux/build.sh --probe` (or, in the image, `Linux/lib/libraries.sh --build`) must end with `OK libraries: ... libpng ... zint`. Windows: `pwsh -File .\Windows\Engine\build.ps1 -SkipToolchain -LibrariesOnly` must print both libraries built and exit 0.

- [ ] **Step 5: Commit.**

```bash
git add Linux/libraries.conf Linux/lib/libraries.sh Windows/Engine/libraries.conf Windows/Engine/build.ps1
git commit -s -m "build: pin zint 2.16.0 and libpng 1.6.59 for the Linux and Windows builds"
```

---

### Task 2: The portable render core, and MADBarcodes in the headless builds

**Files:**
- Modify: `MADBarcodes/MADBarcodes/MADBarcodes/MADBarcode.h`
- Modify: `MADBarcodes/MADBarcodes/MADBarcodes/MADBarcode.m`
- Modify: `MADBarcodes/MADBarcodes/MADBarcodes/MADBarcodeCache.h`
- Modify: `MADBarcodes/MADBarcodes/MADBarcodes/MADBarcodeView.h`
- Create: `Linux/cmake/MADBarcodesSources.cmake`
- Create: `Windows/Engine/cmake/MADBarcodesSources.cmake`
- Modify: `Linux/CMakeLists.txt`
- Modify: `Windows/Engine/build.ps1`
- Create: `Linux/Tests/MADBarcodesTests.m`
- Modify: `MADBarcodes/MADBarcodesTests/MADBarcodeTests.m` (one Apple test for the new API)

**Interfaces:**
- Produces: `- (NSData *)renderedPNGData` and `- (NSData *)renderedPNGDataWithErrorMessage:(NSString * __autoreleasing *)errorMessage` on `MADBarcode` (available on every platform). Off Apple `MADBarcodeImage` is `NSData` and `-renderedImage` answers the same PNG bytes. On Apple the existing `-renderedImage`/`MADBarcodeCache`/`drawInRect:` behaviour is unchanged.
- Produces: CMake target `madbarcodes` and Windows objects prefixed `bc_`; the headless suite `MADBarcodesTests`.

- [ ] **Step 1: Write the failing headless suite.** Create `Linux/Tests/MADBarcodesTests.m`:

```objc
static void testFactoryBuildsCode128(void) {
    MADBarcode *barcode = [MADBarcode newBarcodeWithType: MADBarcodeTypeCODE128];
    MAD_PASS(barcode != nil, "the factory builds Code 128");
    MAD_PASS_EQUAL(barcode.name, @"Code 128 (ISO 15417)", "the name table answers the type's name");
}
static void testRenderedPNGDataIsAPNG(void) {
    MADBarcode *barcode = [MADBarcode newBarcodeWithType: MADBarcodeTypeCODE128];
    barcode.input = @"MAD-2026"; barcode.humanReadable = YES; barcode.barcodeHeight = 40;
    NSData *png = [barcode renderedPNGData];
    MAD_PASS(png.length > 8, "the render produced bytes");
    const uint8_t *bytes = png.bytes;
    MAD_PASS(bytes[0] == 0x89 && bytes[1] == 'P' && bytes[2] == 'N' && bytes[3] == 'G',
             "the bytes carry the PNG signature");
}
static void testInvalidInputReportsTheMessage(void) {
    MADBarcode *barcode = [MADBarcode newBarcodeWithType: MADBarcodeTypeCODE128];
    barcode.input = @"";
    NSString *message = nil;
    NSData *png = [barcode renderedPNGDataWithErrorMessage: &message];
    MAD_PASS(png == nil, "empty input does not render");
    MAD_PASS(message.length > 0, "the failed pass reports a message");
}
```

End with `MAD_TEST_MAIN("MADBarcodesTests", MAD_TEST(testFactoryBuildsCode128), MAD_TEST(testRenderedPNGDataIsAPNG), MAD_TEST(testInvalidInputReportsTheMessage));`.

- [ ] **Step 2: Add the API and the guards.**
  - `MADBarcode.h`: import `<Foundation/NSData.h>`; add the `#else typedef NSData MADBarcodeImage;` arm; declare `-renderedPNGData` and `-renderedPNGDataWithErrorMessage:`.
  - `MADBarcode.m`: `#import <MADBarcodes/png.h>`; guard the UIKit/AppKit imports and `MADBarcodeCache` import with `#if __APPLE__`; wrap `MADBarcodeImageFromZintBitmap` in `#if __APPLE__`; add `static NSData *MADBarcodePNGDataFromZintBitmap(const struct zint_symbol *)` using `png_image` + `png_image_write_to_memory` (sizing call with `NULL`, then allocate and write; `image.format = PNG_FORMAT_RGB`); split the encode body of `renderedImageWithErrorMessage:` into a private `- (BOOL)encodeSymbol:(struct zint_symbol **)outSymbol errorMessage:(NSString * __autoreleasing *)errorMessage` that preserves every option assignment, the 128-byte primary guard and the error-message switch verbatim; `renderedImageWithErrorMessage:` calls it then converts to `MADBarcodeImage` (CGImage on Apple, PNG bytes otherwise); `renderedPNGDataWithErrorMessage:` calls it then converts to PNG bytes on every platform, caching successes and failures in a static `NSCache` keyed by `renderCacheKey`; `drawInRect:` body goes behind `#if __APPLE__` with an empty `#else`.
  - `MADBarcodeCache.h`: mirror the `#else typedef NSData MADBarcodeImage;` arm.
  - `MADBarcodeView.h`: wrap the whole `@interface` in `#if TARGET_OS_IPHONE || TARGET_OS_OSX` (the umbrella imports it headlessly).

- [ ] **Step 3: Create the headless source lists.** `Linux/cmake/MADBarcodesSources.cmake` enumerates every `MADBarcode*.m` under `MADBarcodes/MADBarcodes/MADBarcodes/` **except** `MADBarcodeCache.m` (NSCache + UIKit image cost) and `MADBarcodeView.m` (UIView subclass), with a comment naming both exclusions and their reasons. `Windows/Engine/cmake/MADBarcodesSources.cmake` holds the same list (the Windows build reads it back with `Get-SourceFiles`).

- [ ] **Step 4: Register the Linux target.** In `Linux/CMakeLists.txt`, before the `MAD` block: `find_library(ZINT_LIBRARY zint REQUIRED)` and `find_library(PNG_LIBRARY png REQUIRED)` near the other `find_library` calls; then a flattened shim directory `SHIM_DIR/MADBarcodes` with a symlink to every header in the source directory plus symlinks to `${PREFIX}/include/zint.h`, `png.h`, `pngconf.h`, `pnglibconf.h`; then `include(cmake/MADBarcodesSources.cmake)`, `mad_add_framework(madbarcodes MADBARCODES_SOURCES MADBarcodesTests)` and `target_link_libraries(madbarcodes PUBLIC ${ZINT_LIBRARY} ${PNG_LIBRARY} ${ZLIB_LIBRARY})`.

- [ ] **Step 5: Register the Windows build.** Extend `New-Shim` so `MADBarcodes` becomes a directory of copies (framework headers + `zint.h` + the three png headers), like `MAD`; compile it with `Compile-FrameworkSources "MADBarcodes" "bc_" $barcodeSource ... $arcFlags` immediately before the `MAD` compile; add `"MADBarcodesTests"` to `$testNames`.

- [ ] **Step 6: Add the Apple regression test.** In `MADBarcodes/MADBarcodesTests/MADBarcodeTests.m`, add `testRenderedPNGDataIsAPNG` mirroring the headless assertion (Code 128, `MAD-2026`, PNG signature), so the new API is pinned on Apple too.

- [ ] **Step 7: Run both gates.** Windows: `pwsh -File .\Windows\Engine\build.ps1 -SkipToolchain` must print `MADTEST MADBarcodesTests tests=… failed=0` and end with the smoke result. Linux: `./Linux/build.sh` must build `madbarcodes` and pass `MADBarcodesTests` (Docker required; if unavailable, record that in the summary and rely on the Windows compile as the proof for the shared code).

- [ ] **Step 8: Commit.**

```bash
git add MADBarcodes Linux/cmake/MADBarcodesSources.cmake Windows/Engine/cmake/MADBarcodesSources.cmake Linux/CMakeLists.txt Windows/Engine/build.ps1 Linux/Tests/MADBarcodesTests.m
git commit -s -m "feat(barcodes): add the PNG render core and build MADBarcodes headlessly"
```

---

### Task 3: Engine integration — barcode elements render and export

**Files:**
- Modify: `Linux/cmake/MADSources.cmake`, `Windows/Engine/cmake/MADSources.cmake`
- Modify: `MAD/Source/MADPrintPageElement+Constructor.m`
- Modify: `MAD/Source/MADDocumentObjectDataReference.m`
- Modify: `MAD/Source/rptq/RptqDocument+Extras.m`
- Modify: `MAD/Source/rptq/RptqDocumentElementBarcode+Extras.m` (guard the two colour writes)
- Modify: `MAD/Source/MADDocumentObjectDataReferenceBarcode.h/.m`
- Modify: `MAD/Source/MADPrintPageElementBarcode.h/.m`
- Modify: `MAD/Source/MADReportLineRepresentation.h/.m`
- Modify: `MAD/Source/MADReportPageBuilder.m`
- Modify: `MAD/Source/MADReportExporterHTML.m`
- Modify: `MAD/Source/MADReportExporterJSONReport.m`
- Create: `Linux/Tests/MADBarcodeExportTests.m`
- Modify: `Linux/CMakeLists.txt` (register the new test), `Windows/Engine/build.ps1` (`$testNames`)

**Interfaces:**
- Consumes: `-renderedPNGData` from Task 2.
- Produces: `MADReportLineRepresentation.imageData` (`NSData *`, nullable, PNG); `MADPrintPageElementBarcode -renderedImageData`; `MADDocumentObjectDataReferenceBarcode` properties `usesStaticInput1`, `usesStaticInput2`, `staticInput1`, `staticInput2`.

- [ ] **Step 1: Write the failing exporter test.** Create `Linux/Tests/MADBarcodeExportTests.m` (a stand-alone suite, one process, one document): copy `CLI/Fixtures/London.portable.mad` to a temp file, open it with `MADHeadlessDocument`, run the same initialize+refresh operation chain `MADReportExporterTests.m` uses, then insert a `RptqDocumentElementBarcode` into `doc.hasDetailSection` with `type = 9`, `barcodeType = MADBarcodeTypeCODE128`, `useStaticInput1 = YES`, `inputStatic1 = @"UK-CUST"`, size 160×48, via `addDocumentObject:withDropPoint:managedObjectContext:`; export `html` and `json-report`, and assert:
  - HTML contains `data:image/png;base64,`;
  - HTML contains `alt="UK-CUST"`;
  - JSON contains `"kind": "Barcode"` and `"text": "UK-CUST"`.
  End with `MAD_TEST_MAIN("MADBarcodeExportTests", MAD_TEST(testBarcodeExportsAsAPNGAndText));`.

- [ ] **Step 2: Build the static input path.** In `MADDocumentObjectDataReferenceBarcode.h/.m` add the four properties: `usesStaticInput1` is `item.useStaticInput1 || item.referencesField1 == nil`, `staticInput1` is `item.inputStatic1 ?: @""`, and the same pair for input 2. In `MADPrintPageElementBarcode.m` replace the two unconditional row lookups with: static value when `usesStaticInputN`, otherwise `[definition formattedStringForValueN: rowData[definition.fieldKeyN]]` only when the corresponding reference exists. Keep `text = input1 + input2` and keep `_drawingObject` construction.

- [ ] **Step 3: Expose the PNG to the walk and the exporters.** `MADPrintPageElementBarcode.m`: implement `- (NSData *)renderedImageData { return [_drawingObject renderedPNGData]; }` and declare it in the `.h`. `MADReportLineRepresentation.h/.m`: add a nullable `NSData *imageData` property. `MADReportPageBuilder.m`: after `line.style`, fill `line.imageData` when the drawing object responds to `renderedImageData` (declare a private `@protocol MADReportLineImageElement` in the builder the way `MADReportLineTextElement` is declared in the representation). `MADReportExporterHTML.m`: when `line.imageData` is non-nil emit `<img src="data:image/png;base64,…" alt="…" style="width:100%;height:100%;object-fit:contain">` inside the existing line div (base64 via `-base64EncodedStringWithOptions: 0`; import `<Foundation/NSData.h>`), and when it is nil keep emitting the text. `MADReportExporterJSONReport.m`: when `line.imageData` is non-nil append `, "image": true` after the text member.

- [ ] **Step 4: Add the three files to the headless MAD build and remove the guards.** Add `MADPrintPageElementBarcode.m`, `rptq/RptqDocumentElementBarcode+Extras.m` and `MADDocumentObjectDataReferenceBarcode.m` to both `MADSources.cmake` lists and delete their lines/reasons from the exclusion comments (update the group heading). Remove the `#if __APPLE__`/`#else` guards in `MADPrintPageElement+Constructor.m`, `MADDocumentObjectDataReference.m` and `RptqDocument+Extras.m` so the barcode arms compile everywhere. In `RptqDocumentElementBarcode+Extras.m` put the two `MADElementColor` writes behind `#if __APPLE__` (off Apple `UIColor` is only a forward declaration).

- [ ] **Step 5: Run the gate.** `./Linux/build.sh` (or the Windows equivalent after Step 6) must pass `MADBarcodeExportTests`, `MADReportExporterTests` (London checksums unchanged), and every `MAD` suite.

- [ ] **Step 6: Register the test on Windows and run.** Add `"MADBarcodeExportTests"` to `$testNames`; `pwsh -File .\Windows\Engine\build.ps1 -SkipToolchain` must print `MADTEST MADBarcodeExportTests ... failed=0`, and the London-pinned `SmokeTests` (later, Task 6) must still match byte for byte.

- [ ] **Step 7: Commit.**

```bash
git add MAD/Source Linux/cmake/MADSources.cmake Windows/Engine/cmake/MADSources.cmake Linux/Tests/MADBarcodeExportTests.m Linux/CMakeLists.txt Windows/Engine/build.ps1
git commit -s -m "feat(mad): render barcode elements headlessly and embed them in the exporters"
```

---

### Task 4: `mad serve` — barcode element kind, content, preview and catalogue

**Files:**
- Modify: `CLI/Source/MADCLIServe.m`

**Interfaces:**
- Produces (wire): `add-element` accepts `"kind": "barcode"`; `layout-model` elements of type 9 carry a `"barcode"` object `{type,name,humanReadable,borderStyle,useStaticInput,staticInput,field,preview}` where `preview` is base64 PNG (or `""`); `set-element-content` accepts `barcodeType`, `humanReadable`, `borderStyle`, `field` (0 = static) and `text` (static input); `barcode-types` returns `{types:[{id,name}]}` sorted by name.

- [ ] **Step 1: Add the imports and the method constant.** `#import <MAD/RptqDocumentElementBarcode.h>`, `#import <MADBarcodes/MADBarcode.h>`, `static NSString * const MADCLIServeMethodBarcodeTypes = @"barcode-types";`.

- [ ] **Step 2: Extend `MADCLIServeElementDict`.** Add an `RptqDocumentElementBarcode` arm before the aggregate arm: `text = bc.useStaticInput1 ? (bc.inputStatic1 ?: @"") : @""`; `fieldID = bc.referencesField1 ? bc.referencesField1.identifier : 0`; build the `barcode` dictionary, including a preview: `MADBarcode *drawing = [MADBarcode newBarcode:bc input1:sample input2:@""]`, `NSData *png = drawing.renderedPNGData`, `sample = bc.useStaticInput1 && bc.inputStatic1.length ? bc.inputStatic1 : (bc.referencesField1.databaseSchemaField.name ?: @"1234567890")`, preview is `[png base64EncodedStringWithOptions:0] ?: @""`.

- [ ] **Step 3: Extend `add-element`.** Add a `"barcode"` arm after `"line"`: insert `RptqDocumentElementBarcode`, `type = MADPrintPageElementTypeBarcode`, `barcodeType = MADBarcodeTypeCODE128`, `humanReadable = YES`, `useStaticInput1 = YES`, `inputStatic1 = @"MAD-2026"`, `scale = 1.0f`, `barcodeHeight = 40`, size 160×48 (mirrors `MADMacDesignerViewController -addBarcodeInSection:atPoint:`).

- [ ] **Step 4: Extend `set-element-content` and `MADCLIServeDuplicateElement`.** Content: apply `barcodeType`, `humanReadable`, `borderStyle`; a `field` number resolves the query field (non-zero → `useStaticInput1 = NO`, `referencesField1 = field`, `inputField1 = name`; zero → `useStaticInput1 = YES`, `referencesField1 = nil`); a `text` string sets `useStaticInput1 = YES` and `inputStatic1`. Duplicate: copy `type, barcodeType, humanReadable, barcodeBorderStyle, barcodeBorderWidth, barcodeHeight, scale, whitespaceWidth, option1..3, add2dComponent, useStaticInput1/2, inputStatic1/2, inputField1/2, referencesField1/2`.

- [ ] **Step 5: Add `barcode-types`.** Handler builds `@{@"types": array}` from `[MADBarcode newDictionaryNames]`, each entry `@{@"id": key, @"name": value}`, sorted by `name`; register it in `MADCLIServeDispatch`.

- [ ] **Step 6: Verify.** Run the Windows build (the CLI compiles into `mad.exe`); a manual smoke via the WPF acceptance test happens in Task 6. On Linux the CLI target compiles in `./Linux/build.sh`.

- [ ] **Step 7: Commit.**

```bash
git add CLI/Source/MADCLIServe.m
git commit -s -m "feat(cli): serve barcode elements, content, previews and the symbology catalogue"
```

---

### Task 5: The WPF designer — palette, canvas preview and inspector

**Files:**
- Modify: `Windows/App/Mad.Designer.Windows/Models/LayoutModel.cs`
- Modify: `Windows/App/Mad.Designer.Windows/Engine/EngineService.cs`
- Modify: `Windows/App/Mad.Designer.Windows/ViewModels/DesignerViewModel.cs`
- Modify: `Windows/App/Mad.Designer.Windows/Views/DesignerView.xaml`
- Modify: `Windows/App/Mad.Designer.Windows/Views/DesignerCanvas.cs`
- Modify: `Windows/App/Mad.Designer.Windows/Resources/Strings-{en,de,es,ja,pt-BR,zh-Hans}.xaml`

**Interfaces:**
- Consumes: the Task 4 wire additions.
- Produces: `BarcodeSymbology(int Id, string Name)` and `BarcodeContent` records; `EngineService.BarcodeTypesAsync()`; `DesignerViewModel.AddBarcodeCommand`; `LayoutElement.Barcode`; `LayoutElement.IsBarcode`.

- [ ] **Step 1: Model.** In `LayoutModel.cs` add `public sealed record BarcodeSymbology(int Id, string Name);`, `public sealed record BarcodeContent(int Symbology, string SymbologyName, bool HumanReadable, int BorderStyle, bool UseStaticInput, string StaticInput, long Field, string PreviewBase64);`, `public bool IsBarcode => Type == ElementType.Barcode;`, and on `LayoutElement` an init-only `public BarcodeContent? Barcode { get; init; }` filled by `Parse` from the nested `"barcode"` object (tolerant: absent → null).

- [ ] **Step 2: Service.** `EngineService.BarcodeTypesAsync()` calls `"barcode-types"` and returns `IReadOnlyList<BarcodeSymbology>`. Extend `SetElementContentAsync`'s parameter map with `barcodeType`, `humanReadable`, `borderStyle` from new init-only members on `ElementContent` (`int? BarcodeType`, `bool? HumanReadable`, `int? BorderStyle`).

- [ ] **Step 3: View model.** Add `AddBarcodeCommand` (`AddPaletteAsync("barcode", 160, 48)`), `BarcodeTypes` (loaded in `LoadAsync` via the service, empty on failure), and inspector properties: `ElementBarcodeSymbologyIndex` (index into `BarcodeTypes`, writes `BarcodeType = BarcodeTypes[i].Id`), `ElementBarcodeHumanReadable`, `ElementBarcodeBorderIndex` (0/1/2), `ElementBarcodeFieldId` (0 = static; non-zero binds that field), with `ElementText` already serving as the static input. All commit through `SetElementContentAsync`; extend `CaptureContent` to carry the barcode fields so undo restores them; `ElementTypeName` gains the `IsBarcode` case; `RaiseInspectorChanged` announces the new properties; `RaiseCanExecuteChanged` includes `AddBarcodeCommand`. `KindFor` maps a barcode element back to `"barcode"`.

- [ ] **Step 4: Palette and inspector XAML.** In `DesignerView.xaml` replace the disabled barcode button with `<Button Style="{StaticResource MAD.InsertButton}" Command="{Binding AddBarcodeCommand}" ...>` (add `Designer.Barcode` label + automation name). In the element card, add a barcode section visible only when `PrimaryElement.IsBarcode` (a `DataTrigger` on `PrimaryElement.IsBarcode`; the WPF `Binding` path works on the immutable record): symbology `ComboBox` bound to `BarcodeTypes`/`ElementBarcodeSymbologyIndex`, "Show text" `CheckBox`, border `ComboBox` (three localized items), and a "Bind to field" `ComboBox` whose items are a "(Static input)" entry plus `Fields` (`Display`/`Id`), bound to `ElementBarcodeFieldId`.

- [ ] **Step 5: Canvas preview.** In `DesignerCanvas.DrawElement`, when `element.IsBarcode`, set `border.Child` to an `Image` built from `element.Barcode?.PreviewBase64` (decode base64 → `BitmapImage` with `CacheOption = OnLoad`, `Stretch = Uniform`) and fall back to a `TextBlock` reading `"Barcode: " + (element.Barcode?.StaticInput or the bound column name)` when the preview is absent. `TintFor` returns `LabelTint` for barcodes; `DisplayText` adds a barcode case. `IsLabel`-only double-click editing must not apply to barcodes.

- [ ] **Step 6: Strings.** Add to `Strings-en.xaml`: `Designer.Element.Barcode`, `Designer.Placeholder.Barcode`, `Designer.Barcode.Symbology`, `Designer.Barcode.ShowText`, `Designer.Barcode.Border`, `Designer.Barcode.Border.None`, `Designer.Barcode.Border.Bind`, `Designer.Barcode.Border.Box`, `Designer.Barcode.Field`, `Designer.Barcode.StaticInput`. Add the same keys (translated, same placeholders) to the five other dictionaries. Remove `Designer.BarcodeUnavailable` from all six. Update `LocalizerTests.EveryShippedDictionary_HasEveryEnglishKey`'s expected count (239 + 10 − 1 = 248).

- [ ] **Step 7: Build and test.** `dotnet test Windows/App/Mad.Designer.Windows.Tests` (with the engine built) must pass `LocalizerTests` and the existing designer tests.

- [ ] **Step 8: Commit.**

```bash
git add Windows/App/Mad.Designer.Windows
git commit -s -m "feat(app): enable the barcode element in the Windows designer"
```

---

### Task 6: WPF barcode tests and the smoke-test case

**Files:**
- Modify: `Windows/App/Mad.Designer.Windows.Tests/DesignerAcceptanceTests.cs`
- Modify: `Windows/App/Mad.Designer.Windows.Tests/SmokeTests.cs`

**Interfaces:**
- Consumes: everything above.

- [ ] **Step 1: Write the failing acceptance test.** Add `Barcode_InsertEditBindAndUnbind` to `DesignerAcceptanceTests`: create a document from chinook, load the designer, `AddBarcodeCommand` → one `IsBarcode` element with a non-empty `Barcode.PreviewBase64`; set the symbology to the QR entry from `BarcodeTypes` and `humanReadable = false` → the reloaded model reflects both; bind to a `LayoutField` → `Barcode.Field` equals it and `UseStaticInput` is false; set `ElementText` → `UseStaticInput` true and the text matches; unbind (`ElementBarcodeFieldId = 0`) → static again. Delete the element at the end. Clean up the temp files.

- [ ] **Step 2: Extend the smoke test's created document.** In `SmokeTests.NewDocument_FromSqlite_…`, after the aggregate, add a barcode element (`AddElementAsync(designer, "barcode", detail, 460, 6)`), assert `designer.Elements.Any(e => e.IsBarcode)` and a non-empty preview, and in the export loop assert the HTML export contains `data:image/png;base64,` and the `json-report` export contains `"Barcode"`. The London byte pins in the other fact must remain untouched.

- [ ] **Step 3: Run the tests.** `dotnet test Windows/App/Mad.Designer.Windows.Tests` — all green, including the London pin test (proving no bytes changed for a barcode-free document).

- [ ] **Step 4: Commit.**

```bash
git add Windows/App/Mad.Designer.Windows.Tests
git commit -s -m "test(app): pin the Windows barcode designer and its export"
```

---

### Task 7: Licence register, About window and the documentation sweep

**Files:**
- Modify: `Windows/App/Mad.Designer.Windows/Models/WindowsLicenseRegistry.cs`
- Modify: `Windows/App/Mad.Designer.Windows.Tests/WindowsLicenseRegistryTests.cs`
- Modify: `docs/project/THIRD_PARTY_LICENSES.md` (§9 Linux runtime table, §10 Windows table)
- Modify: `AGENTS.md`, `MADBarcodes/AGENTS.md`, `Linux/AGENTS.md`, `Windows/AGENTS.md`
- Modify: `docs/archive/MAD_BARCODES.md` §5 (mark the headless follow-up landed; do not rewrite the history)
- Modify: `Linux/README.md`, `Windows/README.md`, `docs/project/MAD_LINUX.md`, `docs/project/MAD_WINDOWS.md` (test counts and the library/framework lists)

**Interfaces:**
- Produces: About-window rows for zint and libpng; register rows in §9/§10.

- [ ] **Step 1: Registry and its test.** Add to `WindowsLicenseRegistry.Components`:
  `new("zint", "BSD-3-Clause", "The barcode encoder behind the report's barcode elements.", "BSD 3-Clause License (zint)", "zint-BSD-3-Clause.txt")` and `new("libpng", "PNG Reference Library v2", "The PNG encoder for barcode images.", "PNG Reference Library v2 (libpng)", "libpng-LICENSE.txt")`. Update the class comment (the "never zint, libpng" sentence). In the test change the count to 17, replace the `DoesNotContain` with `Contains` for both and keep `Font Awesome` excluded.

- [ ] **Step 2: Registers.** In `THIRD_PARTY_LICENSES.md` §9 add zint and libpng rows ("static inside `mad`; the same permissive terms as the app"); in §10 add them to the static `.lib` row/table with the "notice must ship" obligations.

- [ ] **Step 3: Agent docs.** Root `AGENTS.md`: MADBarcodes is now built headlessly and backs the barcode element on all three platforms. `MADBarcodes/AGENTS.md`: remove "deliberately excluded from the Linux build"; describe the PNG core and the headless suite. `Linux/AGENTS.md` and `Windows/AGENTS.md`: add zint/libpng to the C-library lists and MADBarcodes to the framework counts.

- [ ] **Step 4: Counts and lists.** Update the test counts in `Linux/README.md`, `Windows/README.md`, `docs/project/MAD_LINUX.md`, `docs/project/MAD_WINDOWS.md` and the root `AGENTS.md` to the numbers the final runs print; update the library lists (§7 of `MAD_LINUX.md`) and the excluded-source narrative (§4/§5.2, `MADSources.cmake` comments are already edited in Task 3). Update `docs/archive/MAD_BARCODES.md` §5's headless follow-up to "done in the barcode-closure increment" and leave the rest.

- [ ] **Step 5: Run the registry and localization tests.** `dotnet test` green.

- [ ] **Step 6: Commit.**

```bash
git add ThirdParty docs AGENTS.md MADBarcodes/AGENTS.md Linux Windows/App Window/Engine README.md
git commit -s -m "docs: register zint and libpng and record the headless barcode build"
```

---

### Task 8: Full verification, the summary, and the pull request

**Files:**
- Create: `C:\dev\mad-win-reports\barcode-closure-summary.md`

- [ ] **Step 1: Linux gate.** `./Linux/build.sh --verify` from the repo root (Docker). Must be green. If Docker is unavailable on this workstation, record that explicitly in the summary as an unverified gate.

- [ ] **Step 2: Windows engine gate.** `pwsh -File .\Windows\Engine\build.ps1 -SkipToolchain` — every suite `failed=0`, smoke `SMOKE RESULT: 0 failure(s)`.

- [ ] **Step 3: WPF gate.** `dotnet test Windows/App/Mad.Designer.Windows.Tests` — all green, including the London byte pins.

- [ ] **Step 4: Apple gate, recorded honestly.** The Apple code paths are unchanged behind `#if __APPLE__` and the new tests are additive, but xcodebuild is not available on this workstation; the summary must say the Apple suites were not run here and name the commands to run them.

- [ ] **Step 5: End-to-end export check.** Using the built `mad.exe`: open a created chinook document through `mad serve` (or the WPF smoke test's evidence), add a barcode, export HTML and JSON, and record the assertions (data URI present, text present).

- [ ] **Step 6: Write the summary** to `C:\dev\mad-win-reports\barcode-closure-summary.md`: what changed per task, the new interfaces, the exact gate outputs, the known gaps (Apple suite unrun here; headless PDF still unavailable; GS1/data input modes still unwired), and the licence disclosure.

- [ ] **Step 7: Commit, push and open the PR.**

```bash
git add -A
git commit -s -m "docs: record the barcode-closure verification"
git push -u origin barcode-closure
gh pr create --base master --head barcode-closure \
  --title "Barcode closure: headless rendering and the Windows designer" \
  --body "<summary from the file>"
```

- [ ] **Step 8: Watch the required checks** (`Linux verification`, `DCO`) with `gh pr checks --watch`; do not merge — the task asks for a ready PR, not a merge.
