# MAD_BARCODES.md — the barcode element: modernization and re-integration plan

**Status:** Archived 2026-10-22 — the design and all of its tasks (0-7) were implemented
(TASKS.md §15, done 2026-10-21). The document is kept for reference only and is no longer
a work queue.

**Product decision (user, 2026-10-20):** the barcode element is **always available** in
the designer. The IAP gate (`com.everydayapps.mad.designer.product.element.barcode`) is
removed from the picker; the StoreKit flag machinery stays in place, untouched.

## 1. State of the world (the survey, condensed)

The premise "the barcode generator was removed" is wrong on the Apple side. The element
was **never disconnected from the app** — it was hidden. Everything below compiles and
links today:

- **`MADBarcodes` framework** is a workspace member, linked and embedded by the app target
  and linked by `MAD`. It wraps **zint 2.16.0** (pure C, BSD-3-Clause backend only),
  built by the Compressor recipe into `Compressor/library/zint.xcframework`, linked
  alongside `libpng.xcframework` and `zlib.xcframework` (`LIBRARIES.md:152`).
- **Framework shape:** `MTBarcode` base class + `MTBarcodeProtocol` + `MTBarcodeView`
  (UIView) + **67 symbology subclasses** in 61 headers (two files declare more than one
  class: `MTBarcodeCode128Iso15417.h` holds 6, `MTBarcodeCode39Iso16388.h` holds 2).
  The type enum `MTBarcodeType` (`MADBarcodeType.h`) aliases zint's `BARCODE_*` constants
  by raw value. Construction is via `+[MTBarcode newBarcodeWithType:]` (a 65-case switch).
- **Framework tests exist and pass:** shared scheme `MADBarcodes`,
  `MADBarcodes/MADBarcodesTests/` (`MTBarcodeTests`, `MTBarcodeSymbologyTests`,
  `MTBarcodeViewTests`, 21 tests) — including a real end-to-end draw of a Code 39 symbol
  into an offscreen context. No fixtures needed.
- **Model layer** (`MAD`): `RptqDocumentElementBarcode` (autogen) + Extras category that
  conforms to `MTBarcodeProtocol`; element type `MADPrintPageElementTypeBarcode = 9`
  (`MAD/Source/MADDocumentObjectType.h:14-26`); store schema columns already exist
  (`MAD/Source/rptq/store/MADStoreSchema.m:522-542`) — **no store migration is needed**.
- **Render layer** (`MAD`): `MADPrintPageElementBarcode` builds an `MTBarcode` from row
  data and draws it; dispatched from `MADPrintPageElement+Constructor.m:30-39`. The
  viewer/page-walk (`MADReportPageBuilder.m:214-246`) is element-agnostic — a barcode
  element renders with **zero viewer changes**.
- **Designer layer** (app): the element picker appends Barcode **only when the IAP
  entitlement verifies** (`MADDesignerElementPickerViewController.m:117-120`). Everything
  behind the gate exists and compiles: the editor (`MADDesigner/Source/barcodes/`,
  ~20 files, `MTViewControllerBarcode` family), the storyboard
  (`MADDesigner/Resources/Storyboard/MADBarcodeDesigner.storyboard`), the canvas view
  (`MADDesignerElementBarcodeView`, wired in `MADDesignerElementView+Constructor.m:36-37`),
  and the save/edit plumbing in `MADDesignerViewController.m`.
- **Headless (Linux):** `MADBarcodes` is deliberately not built. The three barcode-backed
  files in `MAD` are excluded (`Linux/cmake/MADSources.cmake:21,43-48`) and the creation
  paths are `#if __APPLE__`-guarded (`RptqDocument+Extras.m:600`,
  `MADPrintPageElement+Constructor.m:31`, `MADDocumentObjectDataReference.m` barcode arm).
  These guards must stay intact; `./Linux/build.sh` must stay green.

### Known defects (all pinned in BUGS.md — read the entries before fixing)

1. `MTBarcode.m:693/:719` — the type-name dictionary has a duplicate key
   (`@(MTBarcodeTypeEan14)` aliases `@BARCODE_EAN14`).
2. `MTBarcodeQrCodeIso18004.m` — init and `+type` both return `MTBarcodeTypeOneCode`, so a
   QR request **draws a OneCode symbol**. Pinned by
   `MTBarcodeSymbologyTests testQrCodeClassClaimsTheOneCodeType`.
3. `MTBarcodeCode128Iso15417.m:145-161` — `MTBarcodeCode128Ean128`'s init assigns the HIBC
   128 type while `+type` says EAN128. GS1-128 requests draw HIBC 128.
4. `MTBarcodeInternationalStandardBookNumberIsbn` — `+type` calls itself (infinite
   recursion; only the factory path works).
5. `MTBarcode.m:492` — unchecked `strcpy(barcode->primary, primaryData)` into zint's
   `char primary[128]`; a >127-byte input corrupts the struct.
6. `MTBarcode.m:376-408` — NSCoding is broken (encoder writes empty keys, decoder
   discards the archive). Latent: nothing archives barcodes today. Pinned by tests.
7. `MADBarcodes/MADBarcodes/MADBarcodes/MADBarcodeDataInputType.h` — a dead stub (enum
   commented out; the live private enum is in `MTBarcode.m:80-84`; the header is a file
   reference in the pbxproj but in no build phase).
8. `BUGS.md` "The store's colour columns have no reader…" — the store has
   `backgroundColorR/G/B/A` + `foregroundColorR/G/B/A` columns (`MADStoreSchema.m:496-503`)
   but the model's `backgroundColor`/`foregroundColor` properties (`RptqDocumentElement.h:30-31`)
   have no attribute mapping in `RptqObject.m:63-92`, so reading or writing a colour
   raises `NSUnknownKeyException`. The **one writer is the barcode creation path**
   (`RptqDocumentElementBarcode+Extras.m:89-90`) — which is untested on Apple today, so
   this may mean barcode creation currently **crashes**. Must be fixed before the
   un-gate task.
9. Element model bug: `RptqDocumentElementBarcode+Extras.m:56` and `:97` write the
   **symbology id into the base element `type` column**, clobbering
   `MADPrintPageElementTypeBarcode` (9). The insert path re-sets it afterwards
   (`RptqDocument+Extras.m:613`), masking the bug there; the **edit** path does not, so
   an edited barcode element's type becomes wrong and the editor dispatch breaks.
10. `MADCellElement.m:138` — the barcode cell's Edit action is disabled (FIXME); the edit
    dispatch it would call exists (`MADDesignerViewController.m:1534-1537`).
11. `MADPrintPageElementBarcode` has no `-text`, so `MADReportLineRepresentation -text`
    returns nil for barcode lines — `json-report`, `html`, `html-flow` and accessibility
    serialize an empty string for the element.
12. `TASKS.md` §13 — `MADBarcodes` still carries first-party compiler warnings/analyzer
    findings (five frameworks were cleared; the app, MAD and MADBarcodes remain).

### Performance problem (the design driver)

`MTBarcode -drawInRect:` encodes via zint and then paints the bitmap **pixel-by-pixel
with one `CGContextFillRect` per module** into the current UIKit context. A BI report
renders a barcode per detail row; with large row counts and repeating values (product
codes repeat), this is both expensive per draw and repeats the same zint encode for every
occurrence of the same value. There is also no image-returning API at all.

## 2. Design decisions

- **D1 — Rename the framework, not the app UI.** `MTBarcode*` → `MADBarcode*` for every
  framework symbol: classes (67 subclasses, base, view), `MTBarcodeProtocol`,
  `MTBarcodeType` (and all ~85 `MTBarcodeType*` enum values), `MTBarcodeSizingMode`,
  the private `MTBarcodeDataInputType`, and the 126 source file names. The app's `MT*`
  barcode view controllers keep their names — `MT` is a live prefix elsewhere in the app,
  and those classes are storyboard-bound (`MADBarcodeDesigner.storyboard` names them in
  `customClass` attributes), so renaming them is churn with no benefit. One storyboard
  string does change: `customClass="MTBarcodeView"` → `"MADBarcodeView"` (storyboard:581).
  The rename touches: the framework (126 files + umbrella + pbxproj), `MAD` (7 files,
  all Apple-guarded), the app (12 files), the framework tests (3 files), and the
  `MTBarcode*.m` path references in open `BUGS.md` entries.
- **D2 — Keep the class-per-symbology hierarchy.** 67 tiny subclasses mirroring zint's
  symbologies 1:1 is a maintainable design (each is an init + `+type`). Collapsing it
  into a table-driven registry would be a rewrite with no product gain. The factory
  stays the construction path.
- **D3 — One CGImage draw + a cache (the performance fix).** The render pipeline becomes:
  zint encode → RGB buffer → one `UIImage`/`CGImage` → **one** image draw scaled into the
  element rect (via `UIImage -drawInRect:`, which also sidesteps the CG y-flip trap).
  A framework cache (`MADBarcodeCache`, an `NSCache`) holds the rendered image keyed by a
  canonical render key (type + both inputs + every draw-affecting option). Repeating
  values encode once per document render; every subsequent draw is one image draw.
  Human-readable text keeps its existing `NSStringDrawing` path, drawn after the bars.
  This is the "must be fast on mobile BI" requirement, concretely.
- **D4 — Fix the pinned defects, and archive them properly.** Items 1–8 above are fixed in
  Task 2/Task 5. NSCoding gets a **correct implementation** (encode/decode all protocol
  properties under real keys) — cheap, and makes the class honest; the pinning tests are
  updated to assert the corrected behavior. `BUGS.md` entries move verbatim to
  `BUGS_FIXED.md` with a one-line index entry left behind (the house protocol).
- **D5 — Delete what is dead.** The `MADBarcodeDataInputType.h` stub and its pbxproj file
  references, the empty `MADBarcodesTests.m` template, and the commented-out colour
  blocks in `MTBarcode.m` (:462-467, :763-782) are deleted. The input mode stays
  hardwired to Unicode (the private enum is kept); GS1/Data-mode wiring is a documented
  follow-up, not this round.
- **D6 — The symbology id never goes in the base `type`.** The element's symbology lives
  in `barcodeType`; base `type` stays `MADPrintPageElementTypeBarcode` (9) everywhere.
- **D7 — Barcode lines carry text.** `MADPrintPageElementBarcode` gains a `-text`
  (the resolved input string) so every exporter and accessibility picks the barcode's
  content up through the existing `MADReportLineRepresentation` path with no exporter
  changes.
- **D8 — Un-gate the picker.** The entitlement check in
  `MADDesignerElementPickerViewController.m:117-120` is removed; Barcode is always
  offered. The `barcodeDesignerEnabled` flag stays defined (dead but harmless; the
  licensing machinery is a separate cleanup).
- **D9 — Out of scope, documented (§5):** headless/Linux barcode rendering (zint in
  `libraries.conf` + a UIKit-free render path), macOS/Catalyst, GS1/Data input-mode
  wiring, storyboard segue IDs living in the model (`detailsSegueIdentifer`), barcode
  images inside the HTML exporter, and the app-wide third-party-notices gap
  (`THIRD_PARTY_LICENSES.md:269-284` — the zint BSD-3 notice obligation is flagged there
  already and belongs to the licence-register track, not this one).

## 3. Ground rules (repeat in spirit inside every task)

- Tabs for indentation; limited comments matching the file's tone.
- No `stringWithFormat:` — use `initWithFormat:`/`appendFormat:` house style.
- Deliberately-unused code gets a clang attribute at the declaration
  (`__attribute__((unused))` for file-static functions, `__unused` locals/parameters,
  `NS_UNAVAILABLE` for initializers that must not exist). Never silence a warning away
  from the code; an unmarked warning means delete.
- zsh `rm`/`cp` are interactive — use `/bin/rm -f`, `/bin/cp -f`, or `git mv`.
- Header imports must match file case exactly (the Linux filesystem is case-sensitive).
- `BUGS.md` is a record: when an entry is fixed, move it **verbatim** to `BUGS_FIXED.md`
  and leave a one-line index entry in `BUGS.md`. `TASKS.md` status updates are welcome;
  never start work merely because a tracking file lists it.
- Work on `master`; commit per task when its gates pass; **do not push** unless asked.
- Gates (run before every commit): the framework suite, the `MAD` suite, the app build,
  and — whenever any `MAD/Source` file changed — `./Linux/build.sh` from the repo root.

```sh
xcodebuild test -workspace Reports.xcworkspace -scheme MADBarcodes \
	-destination 'platform=iOS Simulator,id=94952340-7629-4EBB-BBD3-6FEE068793B8' \
	-derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci
xcodebuild test -workspace Reports.xcworkspace -scheme MAD \
	-destination 'platform=iOS Simulator,id=94952340-7629-4EBB-BBD3-6FEE068793B8' \
	-derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci
xcodebuild build -workspace Reports.xcworkspace -scheme 'MAD Designer' \
	-destination 'platform=iOS Simulator,id=94952340-7629-4EBB-BBD3-6FEE068793B8' \
	-derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci
./Linux/build.sh
```

## 4. Tasks

### Task 0 — Baseline (record the before-state)

**Depends on:** nothing.

**Prompt for the flash model:**

```
Run these four commands in /Users/michael/Desktop/Reports and record their results
exactly (all four must pass; if any fails, stop and report before doing anything else):

	xcodebuild test -workspace Reports.xcworkspace -scheme MADBarcodes \
		-destination 'platform=iOS Simulator,id=94952340-7629-4EBB-BBD3-6FEE068793B8' \
	-derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci
	xcodebuild test -workspace Reports.xcworkspace -scheme MAD \
		-destination 'platform=iOS Simulator,id=94952340-7629-4EBB-BBD3-6FEE068793B8' \
	-derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci
	xcodebuild build -workspace Reports.xcworkspace -scheme 'MAD Designer' \
		-destination 'platform=iOS Simulator,id=94952340-7629-4EBB-BBD3-6FEE068793B8' \
	-derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci
	./Linux/build.sh

Also run `git status` to confirm the tree is clean. This is the safety net: every later
task must return the tree to at least this state. Report the test counts and the app
build result; commit nothing.
```

### Task 1 — Rename `MTBarcode*` → `MADBarcode*` (framework + blast radius)

**Depends on:** Task 0. **This is the biggest mechanical task; do it in one commit,
verified, before anything else.**

**Prompt for the flash model:**

```
Goal: rename the MADBarcodes framework's MTBarcode* symbols to MADBarcode*. Everything
else (app-side MT* view controller class names) stays. Work on master in
/Users/michael/Desktop/Reports. zsh rm/cp are interactive; use git mv, /bin/rm -f or
/bin/cp -f.

Scope — rename these symbols everywhere in the framework AND in the files that consume
them (see the consumer list below):
	MTBarcodeProtocol    -> MADBarcodeProtocol    (protocol)
	MTBarcodeSizingMode  -> MADBarcodeSizingMode  (enum type; the value names
	                                               AutomaticResizing/SpecificSize/
	                                               SpecificErrorLevel do not change)
	MTBarcodeType        -> MADBarcodeType        (enum type)
	MTBarcodeType*       -> MADBarcodeType*       (all ~85 enum value names)
	MTBarcodeDataInputType -> MADBarcodeDataInputType  (the private enum in MTBarcode.m:80-84)
	MTBarcodeView        -> MADBarcodeView        (class)
	MTBarcode            -> MADBarcode            (base class; last, because it is a
	                                               substring of the names above)

Order matters: rename the longer names first, MTBarcode itself last.

Steps:
1. In MADBarcodes/MADBarcodes/MADBarcodes/: rename every file MTBarcode*.h/.m to
   MADBarcode*.h/.m (61 headers + 63 implementations, including the two multi-class
   headers), MTBarcodeProtocol.h to MADBarcodeProtocol.h, MTBarcodeView.h/.m to
   MADBarcodeView.h/.m. Use git mv. Then update the class names inside every renamed
   file (sed is fine; use word-boundary-safe patterns) and fix each file's own
   #import statements to the renamed headers.
2. Rename the umbrella exports in MADBarcodes/MADBarcodes/MADBarcodes/MADBarcodes.h
   and the header list in the framework target's Headers build phase: edit
   MADBarcodes/MADBarcodes.xcodeproj/project.pbxproj — every file reference's name,
   path and comment string that contains MTBarcode. The pbxproj also contains
   MTBarcode*.h as Public-header phase entries and the two dead references to
   MADBarcodeDataInputType.h (leave those dead references for Task 2). Verify with
   `xcodebuild -list -workspace Reports.xcworkspace` and a framework build before
   moving on.
3. Rename the test files MADBarcodes/MADBarcodesTests/MTBarcodeTests.m,
   MTBarcodeSymbologyTests.m, MTBarcodeViewTests.m to MADBarcode*.m; update their
   #imports (they use quoted imports of the renamed headers) and any MTBarcode* symbol
   references inside; update their pbxproj entries in the MADBarcodesTests target.
   Check MADBarcodes.xcodeproj/xcshareddata/xcschemes/MADBarcodes.xcscheme for test
   file names and update if it names them.
4. Update the storyboard: MADDesigner/Resources/Storyboard/MADBarcodeDesigner.storyboard
   contains customClass="MTBarcodeView" (around line 581). Change exactly that string
   to "MADBarcodeView". Do NOT rename any other MT* class in the storyboard.
5. Update consumers (all reference MTBarcode symbols and import <MADBarcodes/...>):
   - MAD framework:
       MAD/Source/MADPrintPageElementBarcode.m            (import, ivar, +newBarcode:)
       MAD/Source/MADPrintPageRenderer.m                  (@class MTBarcode; forward decl)
       MAD/Source/MADDocumentObjectDataReference.h        (@protocol forward decl, line 21)
       MAD/Source/MADDocumentObjectDataReferenceBarcode.h/.m
       MAD/Source/rptq/RptqDocumentElementBarcode+Extras.h/.m   (protocol conformance)
       MAD/Source/rptq/RptqDocument+Extras.m              (line ~603, inside #if __APPLE__)
     IMPORTANT: keep every #if __APPLE__ guard exactly as it is — the Linux build
     compiles RptqDocument+Extras.m and MADDocumentObjectDataReference.h/.m and relies
     on those guards.
   - App target:
       MADDesigner/Source/barcodes/MTViewControllerBarcode.h/.m
       MADDesigner/Source/barcodes/MTViewControllerBarcodeOptions.h/.m
       MADDesigner/Source/barcodes/MTViewControllerBarcodePreview.h/.m
       MADDesigner/Source/barcodes/MTViewControllerBarcodePreviewDelegate.h
       MADDesigner/Source/barcodes/MTViewControllerBarcodeType.h/.m
       MADDesigner/Source/barcodes/MADViewControllerBarcodeDelegate.h
       MADDesigner/Source/barcodes/MADViewControllerBarcodeOptionsDelegate.h
       MADDesigner/Source/MADDesignerElementBarcodeView.m
       MADDesigner/Source/MADDesignerViewController.m     (lines ~1761, ~2454)
       MADDesigner/Source/MADElementCanvas.h/.m
     The app-side CLASS names (MTViewControllerBarcode, MTTableViewControllerBarcodeExtra*
     etc.) do NOT change — only the MTBarcode* framework symbols they reference.
6. Update the open BUGS.md entries that cite MTBarcode*.m paths (the ## MADBarcodes
   section and the colour entry at ~line 89): change the file paths to the new names.
   Do not change any other wording.
7. Grep to confirm nothing is left: `grep -rn 'MTBarcode' MADBarcodes MAD MADDesigner/Source
   MADDesigner/Resources/Storyboard/MADBarcodeDesigner.storyboard` must return nothing
   except intentional app-side names that do not start with MTBarcode (none of the
   classes above do).

Verify (all must pass):
	xcodebuild test -workspace Reports.xcworkspace -scheme MADBarcodes \
		-destination 'platform=iOS Simulator,id=94952340-7629-4EBB-BBD3-6FEE068793B8' \
	-derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci
	xcodebuild test -workspace Reports.xcworkspace -scheme MAD \
		-destination 'platform=iOS Simulator,id=94952340-7629-4EBB-BBD3-6FEE068793B8' \
	-derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci
	xcodebuild build -workspace Reports.xcworkspace -scheme 'MAD Designer' \
		-destination 'platform=iOS Simulator,id=94952340-7629-4EBB-BBD3-6FEE068793B8' \
	-derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci
	./Linux/build.sh

Commit on master with a message like "Rename the barcode classes from MTBarcode to
MADBarcode". Do not push. If the grep or any build shows a straggler you cannot place,
fix it or stop and ask.
```

### Task 2 — Fix the framework defects; delete the dead code; archive the BUGS entries

**Depends on:** Task 1.

**Prompt for the flash model:**

```
Goal: fix the five framework defects below and delete the dead code, each pinned by
BUGS.md entries. Work on master in /Users/michael/Desktop/Reports. House rules: tabs;
no stringWithFormat:; unused code gets a clang attribute at the declaration, never a
silenced warning. Read each BUGS.md entry in full before touching its code — the entry
names the exact symbols.

1. Duplicate dictionary key (BUGS.md ## MADBarcodes, "MTBarcode's type-name dictionary
   has a duplicate key"): in MADBarcodes/MADBarcodes/MADBarcodes/MADBarcode.m the
   dictionary literal built around lines 693/719 uses both @(MADBarcodeTypeEan14) and
   @BARCODE_EAN14 (the enum value aliases the zint constant, so they collide). Delete
   the redundant line (keep the @BARCODE_EAN14 entry). Update the dictionary-shape test
   if it asserts the entry count.
2. Wrong symbology types (BUGS.md, the QR and EAN128 entry): in
   MADBarcodeQrCodeIso18004.m make init and +type both return the QR type (they return
   MADBarcodeTypeOneCode today, and -drawInRect: passes the instance's type to zint, so
   the object draws the wrong symbol). In MADBarcodeCode128Iso15417.m lines ~145-161,
   MADBarcodeCode128Ean128's init assigns the HIBC 128 type — make it assign the EAN128
   type its +type already claims. Then update the two pinning tests in
   MADBarcodes/MADBarcodesTests/MADBarcodeSymbologyTests.m
   (testQrCodeClassClaimsTheOneCodeType and the EAN128 one) to assert the corrected
   behavior, renaming them to match.
3. ISBN recursion (BUGS.md): MADBarcodeInternationalStandardBookNumberIsbn's +type
   calls itself. Make it return the enum value its class is named for (check
   MADBarcodeType.h and the factory case in MADBarcode.m +newBarcodeWithType: for the
   right spelling). Add a test if the suite does not already pin it.
4. strcpy overflow (BUGS.md): MADBarcode.m around line 492 does an unchecked
   strcpy(barcode->primary, primaryData) into zint's char primary[128]
   (Compressor/library/zint/include/zint.h:121). Guard it: if the input's UTF-8 length
   would not fit (>= sizeof(barcode->primary)), skip the encode and follow the
   existing error path used for zint error codes (the mapping around lines 512-536),
   logging the reason; honor showErrorMessage the way the existing error path does.
   Add a test: a >127-byte input must not crash and must produce the defined error
   result (no symbol, or an error image per showErrorMessage).
5. NSCoding (BUGS.md): MADBarcode.m's encodeWithCoder:/initWithCoder: pair is broken
   (empty-key encoding; decoder discards the archive). First grep the workspace for
   NSKeyedArchiver/NSKeyedUnarchiver use with barcode objects to confirm nothing
   depends on the broken format (BUGS.md says nothing does). Then implement it
   properly: encode every MTBarcodeProtocol property plus the inputs and subclass
   state under real string keys, decode them back, and update the pinning test in
   MADBarcodesTests to assert a round-trip preserves the values.
6. Delete dead code (house rule: unmarked dead code goes):
   - MADBarcodeDataInputType.h (the stub header with the commented-out enum) and its
     file references in MADBarcodes.xcodeproj/project.pbxproj (two references, no build
     phase). The live enum stays private in MADBarcode.m.
   - The empty Xcode template MADBarcodesTests/MADBarcodesTests.m and its pbxproj
     entries in the test target.
   - The commented-out colour blocks in MADBarcode.m (~lines 462-467 and 763-782).
7. BUGS.md bookkeeping: for each of the five fixed entries, move the entry VERBATIM
   (full text, including its test names) to BUGS_FIXED.md under the same framework
   heading, and leave a one-line index entry in BUGS.md under ## MADBarcodes so
   "BUGS.md, the X entry" still lands. The colour-columns entry stays open (Task 5).

Verify:
	xcodebuild test -workspace Reports.xcworkspace -scheme MADBarcodes \
		-destination 'platform=iOS Simulator,id=94952340-7629-4EBB-BBD3-6FEE068793B8' \
	-derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci
	xcodebuild test -workspace Reports.xcworkspace -scheme MAD \
		-destination 'platform=iOS Simulator,id=94952340-7629-4EBB-BBD3-6FEE068793B8' \
	-derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci
	xcodebuild build -workspace Reports.xcworkspace -scheme 'MAD Designer' \
		-destination 'platform=iOS Simulator,id=94952340-7629-4EBB-BBD3-6FEE068793B8' \
	-derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci
	./Linux/build.sh

Commit on master ("Fix the pinned MADBarcodes defects and delete the dead code"). Do
not push.
```

### Task 3 — The fast render path: one image draw + `MADBarcodeCache`

**Depends on:** Task 2 (the fixes above change the draw path's neighborhood).

**Prompt for the flash model:**

```
Goal: replace MADBarcode's per-pixel painting with one image draw backed by a cache.
This is the performance design — a BI report renders a barcode per detail row, values
repeat, and today every draw encodes via zint and paints the bitmap one CGContextFillRect
per module. Work on master in /Users/michael/Desktop/Reports. House rules: tabs, no
stringWithFormat:, unused-attribute discipline.

Context: MADBarcode -drawInRect: (MADBarcodes/MADBarcodes/MADBarcodes/MADBarcode.m)
currently: builds a zint_symbol, copies the protocol properties into it, encodes with
ZBarcode_Encode_and_Buffer, maps zint error codes to messages, then walks the RGB
bitmap painting each module with CGContextFillRect, with rotate/scale-to-fit/center
geometry, and finally draws the human-readable text via NSStringDrawing when
humanReadable is set.

Steps:
1. Split the method: extract a `- (UIImage *)renderedImage` that performs everything up
   to and including the bitmap, and builds one UIImage from the RGB buffer
   (UIGraphicsBeginImageContextWithOptions at the zint bitmap's size, draw the pixels
   into it — or equivalently a CGBitmapContext + CGBitmapContextCreateImage — then
   UIGraphicsEndImageContext). Keep the error mapping where it is; on a zint error the
   method returns the error rendering it does today if showErrorMessage, else nil.
2. Rewrite -drawInRect: to call -renderedImage (via the cache below) and draw the
   result ONCE with [image drawInRect:destRect] using the same rotate/scale-to-fit/
   center geometry math the current code has (read it and preserve the behavior; the
   existing tests pin the draw result). Using UIImage's drawInRect: avoids the
   CoreGraphics y-flip trap. Draw the human-readable text after the image, exactly as
   today.
3. Add MADBarcodeCache (new files MADBarcodeCache.h/.m in the framework, public,
   listed in the umbrella and the Headers phase):
   - A shared singleton `+ (MADBarcodeCache *)sharedCache;`
   - Backed by NSCache; stores UIImage keyed by an NSString render key.
   - `- (UIImage *)imageForBarcode:(MADBarcode *)barcode;` — looks up the key, renders
     on miss, stores on hit.
   - `- (void)flush;` (removeAllObjects) for tests and for the report refresh.
   Keep it small: no subclassing, no eviction policy beyond NSCache defaults
   (optionally totalCostLimit by pixel bytes, your call — document it in a comment).
4. Add `- (NSString *)renderCacheKey` on MADBarcode: a canonical string composing every
   draw-affecting value — the type, both inputs, and every MTBarcodeProtocol property
   (border style/width, height, humanReadable, option1-3, showErrorMessage, scale,
   whitespace width, has2dComponent) plus center. Do NOT use description. Two barcodes
   that draw identically must produce equal keys.
5. Where should the cache be invalidated: MADBarcode is a value object built fresh per
   row, so nothing to invalidate per object; but call [MADBarcodeCache.sharedCache flush]
   from the element's refresh boundary if one exists — look at
   MAD/Source/MADPrintPageElementBarcode.m and the report refresh path
   (MADDesigner/Source/MADViewerController.m refresh: → MADOperationRefreshReload) and
   flush on refresh completion so a changed document never serves stale images. If the
   cache key already includes every input (it does), flushing is belt-and-braces — do
   the simplest correct thing and say in the commit message what you did.
6. Tests (extend MADBarcodesTests; quoted imports of the new headers):
   - -renderedImage returns a non-nil UIImage with the expected zint dimensions for a
     Code 39 sample, and nil (or the error image) for an invalid input.
   - The existing end-to-end draw test (non-white pixels in an offscreen context) still
     passes unchanged.
   - Cache: two identical barcodes share the identical UIImage object from the cache
     (flush between cases); two barcodes differing only in input produce different
     images; -renderCacheKey differs when an option differs.
   - A >127-byte input still behaves as Task 2 defined.
7. Update the umbrella MADBarcodes.h to export MADBarcodeCache.h.

Verify:
	xcodebuild test -workspace Reports.xcworkspace -scheme MADBarcodes \
		-destination 'platform=iOS Simulator,id=94952340-7629-4EBB-BBD3-6FEE068793B8' \
	-derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci
	xcodebuild test -workspace Reports.xcworkspace -scheme MAD \
		-destination 'platform=iOS Simulator,id=94952340-7629-4EBB-BBD3-6FEE068793B8' \
	-derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci
	xcodebuild build -workspace Reports.xcworkspace -scheme 'MAD Designer' \
		-destination 'platform=iOS Simulator,id=94952340-7629-4EBB-BBD3-6FEE068793B8' \
	-derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci
	./Linux/build.sh

Commit on master ("Render barcodes as one cached image draw"). Do not push.
```

### Task 4 — `MADBarcodes` warning sweep (TASKS.md §13)

**Depends on:** Task 3.

**Prompt for the flash model:**

```
Goal: clear MADBarcodes' remaining first-party compiler warnings and analyzer findings
(TASKS.md §13: five frameworks were cleared 2026-10-17; the app, MAD and MADBarcodes
remain). Work on master in /Users/michael/Desktop/Reports.

1. Build the framework and run Analyze on it in isolation:
	xcodebuild build -workspace Reports.xcworkspace -scheme MADBarcodes \
		-destination 'platform=iOS Simulator,id=94952340-7629-4EBB-BBD3-6FEE068793B8' \
	-derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci
   plus Product > Analyze equivalent (or the analyze xcodebuild flag) and record every
   first-party diagnostic.
2. Fix first-party diagnostics the house way: deliberately-unused code gets a clang
   attribute at the declaration (__attribute__((unused)) on file-static functions,
   __unused on locals/parameters, NS_UNAVAILABLE for initializers that must not be
   built). Never suppress a warning away from the code; an unmarked warning means the
   code is dead and should be deleted. Do not "fix" warnings inside vendored zint/png
   headers — those are not ours.
3. If a diagnostic reveals a real defect you are unsure how to fix without behavior
   change, leave the code alone and record it as a new BUGS.md entry under
   ## MADBarcodes (Status: Open, with the file:line and what you saw) rather than
   papering over it.
4. Update TASKS.md §13's status line to note MADBarcodes is cleared (or what remains).

Verify:
	xcodebuild test -workspace Reports.xcworkspace -scheme MADBarcodes \
		-destination 'platform=iOS Simulator,id=94952340-7629-4EBB-BBD3-6FEE068793B8' \
	-derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci
	xcodebuild build -workspace Reports.xcworkspace -scheme 'MAD Designer' \
		-destination 'platform=iOS Simulator,id=94952340-7629-4EBB-BBD3-6FEE068793B8' \
	-derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci
	./Linux/build.sh

Commit on master ("Clear the MADBarcodes warning sweep"). Do not push.
```

### Task 5 — Element-layer fixes in `MAD` (type clobber, colour columns, `-text`, Edit menu)

**Depends on:** Task 3. Touches `MAD/Source`, so the Linux gate is mandatory.

**Prompt for the flash model:**

```
Goal: four MAD-layer fixes that make the barcode element actually work on Apple.
Work on master in /Users/michael/Desktop/Reports. House rules: tabs; no
stringWithFormat:; unused-attribute discipline; imports match file case exactly (Linux
is case-sensitive); every #if __APPLE__ guard you see stays intact — the Linux build
compiles some of these files and excludes others (Linux/cmake/MADSources.cmake).

1. Stop clobbering the base element type.
   In MAD/Source/rptq/RptqDocumentElementBarcode+Extras.m, updateWithBarcode:
   (~line 56) and barcodeWithMtBarcode: (~line 97) both assign the SYMBIOLOGY id into
   the base element's `type`. The base type must stay MADPrintPageElementTypeBarcode
   (9); the symbology belongs in `barcodeType`. The insert path re-sets type
   afterwards (RptqDocument+Extras.m ~line 613), which masks the bug on insert but not
   on edit — after an edit, documentObjectType returns the symbology id and the editor
   dispatch breaks. Fix: updateWithBarcode: and barcodeWithMtBarcode: must copy the
   symbology into barcodeType and NEVER assign base type; verify the insert path still
   sets type = MADPrintPageElementTypeBarcode. Add a MAD test (in MAD/MADTests, pattern
   MADDocumentObjectDataReferenceBarcodeTests.m): create a barcode element through the
   factory, assert documentObjectType == MADPrintPageElementTypeBarcode and barcodeType
   == the symbology; then call updateWithBarcode: and assert the same invariant.
2. Fix the store's colour columns (BUGS.md "The store's colour columns have no reader,
   and the model's colour properties have no column" — read the whole entry first).
   The store has backgroundColorR/G/B/A + foregroundColorR/G/B/A columns
   (MAD/Source/rptq/store/MADStoreSchema.m:496-503); the model exposes
   backgroundColor/foregroundColor (RptqDocumentElement.h:30-31); nothing maps them, so
   RptqObject's -valueForUndefinedKey: (MAD/Source/rptq/store/RptqObject.m:63-92)
   raises NSUnknownKeyException. The ONE writer is the barcode creation path
   (RptqDocumentElementBarcode+Extras.m:89-90) — so creating a barcode element likely
   raises today; the HTML facsimile and PDF are monochrome for the same reason.
   Fix the mapping properly: teach RptqObject (or wherever sibling attributes are
   mapped — study how the other element attributes in the schema are registered first)
   to read/write backgroundColor and foregroundColor through the four RGBA columns.
   Do not change the schema columns. Then add a MAD test that creates a barcode element
   via the factory (exercising the :89-90 write) and reads its colours back without an
   exception. Once green, move the BUGS.md entry VERBATIM to BUGS_FIXED.md and leave
   the one-line index entry behind. (This fixes the whole element colour story, not
   just barcodes — the entry's "Why it matters" names the HTML/PDF consequences.)
3. Give barcode lines text.
   MAD/Source/MADPrintPageElementBarcode.h/.m: the class currently has no -text, so
   MADReportLineRepresentation -text returns nil for barcode lines and json-report /
   html / html-flow / accessibility serialize an empty value. Make it carry the
   resolved input: the cleanest is to subclass MADPrintPageElementText (whose -text
   property the line representation already reads via respondsToSelector) — check that
   class's initializer contract in MADPrintPageElement.h/.m first, and set text to the
   composed input (input1, plus input2 when present, in the same order the drawn
   barcode uses them). Keep drawInRect: unchanged. Add a MAD test: build the print
   element from a MADDocumentObjectDataReferenceBarcode with known values (see
   MADPrintPageElementBarcodeTests.m for the existing pattern) and assert -text; then
   build a MADReportLineRepresentation over it and assert its -text.
4. Re-enable Edit on barcode elements.
   MADDesigner/Source/MADCellElement.m line ~138: canPerformAction:withSender: disables
   edit for barcodes with a FIXME; the dispatch it would call exists
   (MADDesignerViewController.m ~1534-1537, editDocumentObjectRepresentedByCell: →
   editDocumentObjectBarcodeWithID:). Remove the exception so barcode elements allow
   the same delete/format/edit actions as their siblings. No new plumbing.

Verify:
	xcodebuild test -workspace Reports.xcworkspace -scheme MAD \
		-destination 'platform=iOS Simulator,id=94952340-7629-4EBB-BBD3-6FEE068793B8' \
	-derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci
	xcodebuild test -workspace Reports.xcworkspace -scheme MADBarcodes \
		-destination 'platform=iOS Simulator,id=94952340-7629-4EBB-BBD3-6FEE068793B8' \
	-derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci
	xcodebuild build -workspace Reports.xcworkspace -scheme 'MAD Designer' \
		-destination 'platform=iOS Simulator,id=94952340-7629-4EBB-BBD3-6FEE068793B8' \
	-derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci
	./Linux/build.sh

Commit on master ("Fix the barcode element's type, colours, text and edit path"). Do
not push.
```

### Task 6 — Export and accessibility coverage for barcode lines

**Depends on:** Task 5.

**Prompt for the flash model:**

```
Goal: prove that a document containing a barcode element exports correctly. Work on
master in /Users/michael/Desktop/Reports. House rules as always (tabs, no
stringWithFormat:, case-exact imports).

Context: the exporters do not switch on element types — they serialize the walked
MADReportLineRepresentation: the kind token comes from
NSStringFromMADPrintPageElementType (MAD/Source/MADDocumentObjectType.h:29-44, which
already names Barcode), and the value from the line's -text (fixed in Task 5). So this
task is mostly tests; change code only where a test proves a gap.

1. Read MADReportExporterTypeToken (used at MADReportExporterJSONReport.m:181-182),
   MADReportExporterHTMLTypeToken (MADReportExporterHTML.m:143-144) and
   MADReportExporterFlowTypeToken (MADReportExporterHTMLFlow.m:218-219). Confirm each
   maps the string "Barcode" (from NSStringFromMADPrintPageElementType) to a sane
   token ("barcode" or equivalent) rather than rejecting it. If one rejects unknown
   names, fix it minimally to pass Barcode through like the other element names.
2. Add tests in MAD/MADTests (follow the existing exporter test files' fixture
   pattern): build a temporary store/document containing one barcode element (create it
   through the RptqDocumentElementBarcode factory like the Task 5 test does, with a
   known symbology and inputs), walk it the way the exporters do, and assert:
   - json-report: the line's kind token is the barcode token and its value equals the
     element's resolved input text;
   - html and html-flow: same, with the text escaped the way sibling elements are;
   - MADAccessibilityLine built over the element carries the value, not an empty string.
   These are Apple-only tests (the Linux build cannot construct barcode elements by
   design — the creation paths log-and-skip there), so guard nothing; just do not add
   them to the Linux test set.
3. Do not change the Linux build or its source lists.

Verify:
	xcodebuild test -workspace Reports.xcworkspace -scheme MAD \
		-destination 'platform=iOS Simulator,id=94952340-7629-4EBB-BBD3-6FEE068793B8' \
	-derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci
	xcodebuild test -workspace Reports.xcworkspace -scheme MADBarcodes \
		-destination 'platform=iOS Simulator,id=94952340-7629-4EBB-BBD3-6FEE068793B8' \
	-derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci
	xcodebuild build -workspace Reports.xcworkspace -scheme 'MAD Designer' \
		-destination 'platform=iOS Simulator,id=94952340-7629-4EBB-BBD3-6FEE068793B8' \
	-derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci
	./Linux/build.sh

Commit on master ("Cover the barcode element in the report exporters"). Do not push.
```

### Task 7 — Un-gate the picker; documentation sweep; end-to-end verification

**Depends on:** Tasks 5 and 6.

**Prompt for the flash model:**

```
Goal: make the barcode element always available in the designer and bring the
documentation in line with reality. Work on master in /Users/michael/Desktop/Reports.

1. Un-gate the picker. In MADDesigner/Source/MADDesignerElementPickerViewController.m,
   the choice list in viewWillAppear (~lines 106-123) appends the barcode type only
   when [MADStoreKitController sharedObject].barcodeDesignerEnabled. Remove the
   conditional so the barcode choice is always added, exactly like the other element
   types. Leave the barcodeDesignerEnabled property and MTStoreKitController+Features
   untouched (the licensing machinery is a separate cleanup). The segue
   (MTIdentifierSeguePushBarcodeLabelNew) and the creation flow behind it already
   exist and are compiled.
2. Documentation sweep (keep each change minimal and factual):
   - AGENTS.md (repo root; CLAUDE.md is a symlink to it): the frameworks list says
     "MADBarcodes: This is used for the barcode element. MADBarcodes is currently
     unused and unmaintained." Replace the last sentence with the true state: the
     framework is maintained, links zint 2.16.0 via the Compressor recipe, and backs
     the barcode element on Apple; it is deliberately excluded from the Linux build.
     Also add MAD_BARCODES.md to the Related Documents list.
   - MADBarcodes/AGENTS.md (and its CLAUDE.md symlink): remove the "unused and
     unmaintained" claim; state the framework's role and its test scheme.
   - LIBRARIES.md lines ~100-102 are stale: they still describe zint 2.4.2 with
     patches/zint-2.4.2-mad.patch. Correct them to the actual arrangement: zint
     2.16.0 built by the Compressor recipe (Compressor/matrix.conf + lib/recipes/zint.sh)
     into Compressor/library/zint.xcframework; the old 2.4.2 patch is retired
     (ZBarcode_Encode_and_Buffer is upstream API in 2.16). THIRD_PARTY_LICENSES.md
     ~283-284 already flags the staleness — check that note and update it to say the
     LIBRARIES.md text is now corrected. Do not touch the notices gap itself (it is on
     the licence-register track).
   - BUGS.md: the colour-columns entry's "untested on Apple" note was resolved by
     Task 5 (the entry moved to BUGS_FIXED.md). The "barcode creation path, which is
     off the headless build" wording in any remaining open entry: adjust only the
     stale "untested on Apple" phrasing where the facts have changed; leave everything
     else verbatim.
   - TASKS.md: update §15 (this queue entry) with what landed, commit hashes included,
     and mark it Done; keep the follow-ups listed there under a short "Remains" line
     (see MAD_BARCODES.md §5).
3. End-to-end verification:
   - Build the app for the simulator AND for a generic device
     (xcodebuild build ... -destination 'generic/platform=iOS' — use the scheme
     'MAD Designer'). Both must pass.
   - Run the full suites (MADBarcodes, MAD) and ./Linux/build.sh.
   - Launch the app in the simulator (the /run skill, or xcrun simctl launch after
     installing the built app). You cannot see the screen, so do the mechanical checks
     and hand the visual pass to the user: (a) the element picker offers Barcode
     without any entitlement; (b) choosing it opens the barcode options composer
     (MADBarcodeDesigner.storyboard) — the app must not crash on the colour write
     (Task 5 fixed the exception); (c) the designer canvas shows the sample barcode;
     (d) after refresh, the viewer draws the barcode from live row data; (e) a
     json-report export of a document with a barcode element contains the barcode
     line's text. Report which of these you could verify mechanically and list the
     visual checks for the user.

Verify (the mechanical ones):
	xcodebuild test -workspace Reports.xcworkspace -scheme MADBarcodes \
		-destination 'platform=iOS Simulator,id=94952340-7629-4EBB-BBD3-6FEE068793B8' \
	-derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci
	xcodebuild test -workspace Reports.xcworkspace -scheme MAD \
		-destination 'platform=iOS Simulator,id=94952340-7629-4EBB-BBD3-6FEE068793B8' \
	-derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci
	xcodebuild build -workspace Reports.xcworkspace -scheme 'MAD Designer' \
		-destination 'platform=iOS Simulator,id=94952340-7629-4EBB-BBD3-6FEE068793B8' \
	-derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci
	xcodebuild build -workspace Reports.xcworkspace -scheme 'MAD Designer' \
		-destination 'generic/platform=iOS'
	./Linux/build.sh

Commit on master ("Return the barcode element to the designer"). Do not push.
```

### Task 8 — Optional: complete the umbrella header

**Depends on:** Task 1. Only if time/desire remains; skip otherwise.

**Prompt for the flash model:**

```
Goal: end the "public subset vs factory-reachable classes" inconsistency. Only 16 of
the 61 symbology headers are marked Public, yet every class is reachable through
+newBarcodeWithType:, and MADBarcodes.h carries a comment about keeping the umbrella in
sync with the Public headers phase (-Wincomplete-umbrella). Make every MADBarcode*
symbology header Public in the framework target and list it in the umbrella
MADBarcodes.h, so the public surface matches the reachable surface. Do not change any
class. Verify with the MADBarcodes suite, the MAD suite, the app build and
./Linux/build.sh, and commit on master ("Complete the MADBarcodes umbrella header").
Do not push.
```

## 5. Follow-ups (documented here, deliberately not built)

- **Headless barcode rendering.** `MADBarcodes` is UIKit-bound (`UIGraphics`,
  `UIColor`, `NSStringDrawing`, `UIView`) and zint is not in `Linux/libraries.conf`.
  A headless path would need a UIKit-free render core (zint's own PNG output is one
  candidate) plus a zint pin in the image — the `Linux/CLAUDE.md` "Adding the next
  framework" recipe applies. Until then the Linux build keeps excluding the three
  barcode files and the element type stays model-only there, exactly as today.
- **GS1 / Data input mode.** The input mode is hardwired to Unicode in the encoder;
  the private `MADBarcodeDataInputType` enum exists but the GS1/Data modes are not
  wired to the option fields.
- **`detailsSegueIdentifer` on the model.** The symbology classes carry storyboard
  segue IDs; the mapping belongs in the app's type picker
  (`MTViewControllerBarcodeType`). Cosmetic decoupling, deferred to avoid storyboard
  churn.
- **Barcode images inside the HTML exporter.** Today the facsimile carries the
  barcode's input text; an embedded data-URI PNG is possible on Apple only.
- **App-wide third-party notices.** The zint BSD-3-Clause notice obligation remains
  unmet (flagged in `THIRD_PARTY_LICENSES.md:269-284`); it rides the licence-register
  track, not this one.
