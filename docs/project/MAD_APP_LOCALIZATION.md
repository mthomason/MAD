# Application Localization — Plan and Report

**Status:** Decisions recorded 2026-11-04; Phase 0/1 foundation in progress on
`feature/app-localization-foundation`. Not queued in `TASKS.md` beyond its short
entry.
**Scope:** the iOS app (`MAD Designer` and `MAD Viewer`), the native macOS app
(`Mac/`), and the user-facing strings in the frameworks those two apps embed.
**Out of scope:** documentation (already localized under
[`LOCALIZATION.md`](LOCALIZATION.md)), the Linux/CLI headless path, and the
localization of *report content* (a separate product feature; see
`TODO.md`'s "AI-assisted localizations").

## 1. The short answer

The application is **instrumented but not localized**. There are 559 active
`NSLocalizedString` calls across 106 files (573 textual occurrences, of which 14
are commented out), but there is no `Localizable.strings`, no string catalog, no
app `.lproj` resource (only the stock `Settings.bundle` template), and no
Base-localized storyboard anywhere in the app. Every one of those calls
currently returns its English key. The unwrapped surface is also large: 560
localizable attribute values in storyboards and xibs (about 368 after filtering
design-time placeholders, numbers and symbols), roughly 330 hardcoded source
literals that reach users in the iOS code, and about 413 user-facing literals in
the Mac app.

The recommended strategy is:

1. **One String Catalog per app bundle** (`.xcstrings`), as the single source of
   truth. Xcode 27.1's `xcstringstool` was verified against this codebase:
   `extract --legacy-localizable-strings`, `sync`, and `compile` all work on
   Objective-C. A `.strings` + `.stringsdict` pipeline remains the fallback.
2. **Keep the English text as the key.** Every existing call already does this.
   It keeps the no-catalog fallback (the key), the Linux build, and the tests
   working, and it makes the English source the translator's context.
3. **One catalog in the app bundle covers all framework code**, because
   `NSLocalizedString` resolves against `NSBundle.mainBundle`.
   Per-framework localized resources are needed only for the three driver
   storyboards that are loaded from framework bundles.
4. **Move every storyboard and xib to `Base.lproj`** and generate a per-language
   `.strings` for each.
5. **Mirror the documentation's five translations**: German, Spanish, Japanese,
   Brazilian Portuguese, and Simplified Chinese, with the app-side language
   codes mapped from the docs' codes.
6. **Do not translate licence texts, the NOTICE, brand names, SQL identifiers,
   data-type names, or server-returned error text.** Translate the UI chrome
   around them, and say so in the UI.

## 2. What exists today (measured)

### 2.1 Code

`NSLocalizedString` is used widely, but the second argument is often just the
string repeated. Of the 559 active calls in the iOS/shared modules (10 of them
in the un-embedded `MADFeedback`), 448 take a literal key (309 unique), 91 take
a constant or macro (65 symbols), and 20 take a runtime value. The Mac app adds
3 literal calls. Only the literal calls are extractable by the standard tools.

| Module | Files with calls | Active calls | Literal | Constant | Runtime |
| --- | ---: | ---: | ---: | ---: | ---: |
| `MADDesigner/Source` | 69 | 330 | 235 | 90 | 5 |
| `MADExplorer` | 4 | 14 | 13 | 1 | 0 |
| `MAD/Source` | 17 | 124 | 116 | 0 | 8 |
| `MADFoundation/Source` | 1 | 2 | 2 | 0 | 0 |
| `MADCocoaExtensions` | 4 | 28 | 26 | 0 | 2 |
| `MADAPI/Source` | 2 | 15 | 14 | 0 | 1 |
| `MADMySQL/Source` | 1 | 4 | 4 | 0 | 0 |
| `MADTdsClient` | 1 | 5 | 5 | 0 | 0 |
| `MADPostgres/Source` | 1 | 4 | 4 | 0 | 0 |
| `MADSqlite3/Source` | 2 | 14 | 14 | 0 | 0 |
| `MADBarcodes` | 1 | 9 | 9 | 0 | 0 |
| `MADFileManager` | 0 | 0 | 0 | 0 | 0 |
| `MADFeedback` (not embedded) | 3 | 10 | 6 | 0 | 4 |
| **iOS/shared total** | **106** | **559** | **448** | **91** | **20** |
| `Mac/Source` | 1 | 3 | 3 | 0 | 0 |

`MADFeedback` is not embedded in either app, so it is out of scope. `MADTds` is
a thin wrapper with one alert title and a constructed error message
(`MADTdsDb.m:28-34`). `MADFileManager` has no `NSLocalizedString` calls at all.
Its two localization-shaped strings are not user-facing: `Cloud storage is not
available off Apple.` is an `@throw` reason in the non-Apple branch
(`MADFileCoordinator.m:61,86`), and `Error creating directory! %@` is an
`NSAssert` (`MADFileUtilities.m:652`). The audit excludes both deliberately.

Two kinds of call site need work before translation:

* **Runtime-value keys (20).** These cannot be extracted and are often
  semantically wrong. Examples:
  `MADAboutTableViewController.m:269,291` (bundle display name and copyright),
  `AppDelegate.m:162` (an application-name suffix), `MADReportPageView.m:360`
  (a composed page-number string), `MADDocumentObjectTypeDescriptor.m:114,118,122`
  (three descriptor strings), `RptqQueryLinks+Extras.m:90` (a join type name),
  `MADTextField.m:30,44` (`NSLocalizedString(token, token)`),
  `MADConnectionSQLGenericViewController.m:161-162` (a local variable),
  `MADDesignerLayout.m:85,95,105,115` (`bold ? @"Bold" : @"Disable Bold"`),
  `MADExplorerController+DocumentActions.m:600` (a local message), and the four
  `MADFeedback` defaults.
* **Constant keys (91 calls, 65 symbols).** `MADText*` constants in
  `MADLabelStatus.m`, `MADQueryViewControllerTableLayout.m`,
  `MADDesignerSectionLayoutController.m`, `MADOperationPromptPassword.m`, and
  `MADExplorerCellTitle.m`, plus the `Text*`/`Format*` constants in
  `NSDate+Extras.m`, `MADQueryViewSectionDelegate.m`, and others. These work at
  runtime because the constant's value is the English key, but `genstrings` and
  `xcstringstool extract` skip them, so they need manual catalog entries or a
  mechanical conversion to literals at the call site. Several are already dead
  and should be deleted rather than translated: `MADOperationGetCredentials.m:28-30`,
  `Constants.m:26-28`, and `Syncing`/`Downloading` in `MADExplorerCellTitle.m`
  (the class uses the literals instead).
* **No catalogs at all.** `find . -name "*.strings"` returns only the
  `Settings.bundle` template, a dead `InfoPlist.strings`, and two test
  templates. There is no `Localizable.strings`, no `.xcstrings`, and no
  `.xliff` anywhere.

Beyond the 559 calls, roughly 330 hardcoded source literals reach users. The
largest blocks are barcode display names (131, duplicated), the app's own error
and driver text (~102), paper names (19), SQL data-type names (21), and the
About/licence copy (~34); the rest are alerts, buttons, table headers, status
text, and document-object names. The storyboards add the 368 strings above, and
the Mac app adds 413.

Accessibility is in better shape than the rest: 61 accessibility labels/hints/
values were found, most already wrapped, and only
`MADDocumentPageController.m:289,297` returns hardcoded content. They still need
to be in the catalog and in the translation set.

Pluralization and locale formatting are the weak points:

* **Nine plural-sensitive sites, at least 12 distinct keys.**
  `NSDate+Extras.m:16-32` defines eight singular/plural pairs selected by
  `i == 1 ?` at lines 47-68 and 133-199, and spells the count out with
  `NSNumberFormatterSpellOutStyle`, which needs per-language grammar.
  `MADLabelStatus.m:15,19` always uses the plural form ("Read 1 records",
  "Page 1 of 1 pages"). `MADAlertController.m:88-105` hand-rolls `%@ item` /
  `%@ items`. `MADViewControllerSQL.m:349` uses the pseudo-plural
  `table(s), join(s), predicate(s), group(s)`. `MADActivityItemProviderPdf.m:185`
  and `MADocument.m:858` use "page" for every count. `MADPageStatusView.m:39`
  needs reordering.
* `MADLabelStatus.m:19` builds `"\nPage %1@ of %2@ pages."`.
  **`%1@` is a width specifier, not a positional specifier.** Verified:
  `String(format: "%2@ %1@", "one", "two")` returns `"one two"`, while
  `"%2$@ %1$@"` returns `"two one"`. The page string cannot be reordered by a
  translator as written.
* **Format strings:** 59 format-bearing keys (40 literal, 19 constant). Only one
  uses valid positional specifiers — `MADQueryViewDataSource.m:373` with
  `%1$@`/`%2$@`; the rest cannot be reordered.
* **Number and unit formatting:** `NSNumberFormatter+MADExtensions.m:13-19`
  hardcodes `.` as the decimal separator and `,` as the grouping separator, and
  is used at three UI sites (`MADDocumentInformationTableViewController.m:45`,
  `MADExplorerController.m:696`, `MADExplorerViewDelegate.m:477`).
  `MADStandard.mm:35-54` hardcodes `.` and `" MB"` and divides by 1,000,000.
  Hardcoded units appear in 21 places (`%@ MB`, `%#.1f pt`, and the 19 paper
  names in `MTPaper.m:261-300`).
* **Display-name tables are a translation surface of their own:** 65 barcode
  names in `MADBarcode.m:762-830`, duplicated as 66 `self.name` assignments
  across the barcode classes; 18 document-object names in
  `MADDocumentObjectTypeDescriptor.m:12-31`; 21 SQL type names in
  `MADOperationValidateSQL.m:34-55`; 19 paper names in `MTPaper.m:261-300`.
  Consolidate the barcode dictionary and `self.name` before translating.
* The Mac app uses no `NSNumberFormatter`, `NSDateFormatter`, or `NSLocale` at
  all; inspector values, ports, and percentages are C-locale `%f`/`%ld`, and
  plural counts are hand-built.

### 2.2 Storyboards and xibs

* 18 storyboards under `MADDesigner/Resources/Storyboard`, plus four
  `MADCreateDocument.storyboard` copies (MADAPI, MADMySQL, MADPostgres,
  MADTdsClient), plus three xibs.
* **560 localizable attribute values** in total (559 in storyboards, 1 in the
  xibs). After filtering design-time placeholders, numbers, glyphs and
  attributed-string fragments, about 368 are English-like user-visible strings:
  287 label texts, 76 titles, and 5 placeholders. `MADBarcodeDesigner` alone
  has 319 attribute values; `MADDesignerObjectSelector` 45;
  `MADDesignerToolbox` 42.
* **No `Base.lproj` and no `PBXVariantGroup`** anywhere. The files are plain
  single-language resources, so Xcode does not treat them as localizable and
  `xcodebuild -exportLocalizations` cannot produce their strings as configured.
* The app's 18 storyboards and 3 xibs are compiled into both iOS targets. The
  Mac target has no storyboards (AppKit is built in code).
* Layout is better than expected for translation: **zero `left`/`right`
  constraints** against 320 `leading`/`trailing` attributes. But there are 15
  fixed-width constraints on text-bearing views (`MADDesignerToolbox` 10,
  `MADDesigner` 3, `MADQuery` 1, `MADStore` 1), 74 absolute text/button
  alignments, and `MADBarcodeDesigner` is essentially frame-based (816
  autoresizing masks, 6 Auto Layout views). Longer translations will clip.
* There are no accessibility labels or hints in any interface file.

**The driver storyboards are a special case.** `MADDriverSelectorController.m:141-143`
loads `MADCreateDocument` from `[NSBundle bundleForClass:bundleClass]` for
MySQL, SQL Server, and PostgreSQL, so each driver framework ships its own copy
and its translations must live inside that framework's bundle. The app's own
`MADCreateDocument.storyboard` is loaded from `mainBundle` by
`MADNavigationController.m:104`. MADAPI's copy is dead (no code loads the
MADAPI bundle). The three live copies have drifted (default ports, "Schema" vs
"Database"); they are near-duplicates, not shared resources.

### 2.3 The Mac app

* **413 translatable UI strings + 34 legal/licence strings (447 total).** Only
  3 use `NSLocalizedString`, all in `MADMacAboutWindowController.m:433-450`.
* Every menu is built in code in `MADMacAppDelegate.m:67-152` with English
  titles, including `About MAD Designer`, `Hide MAD Designer`, `Quit MAD
  Designer`, `Undo`, `Cut`, `Copy`, `Paste`, and `Minimize`. AppKit localizes
  only the Services submenu, the Window-menu extras, the Help search field,
  system panels, and the menu-bar app name.
* There is no `.lproj` and no `Localizable.strings` in `Mac/` or in the built
  bundle. `Mac/build.sh` wipes and rebuilds `Contents/Resources` on every run
  (lines 82 and 108-114) and has no localization copy step before codesign
  (lines 149-152).
* `Mac/Resources/Info.plist` has `CFBundleDevelopmentRegion = en` but no
  `CFBundleLocalizations` and no `InfoPlist.strings`. The Finder-visible
  document type name (`Mobile Analytics Document`) and copyright cannot be
  localized today.
* The About window's three `NSLocalizedString` calls use `mainBundle`, while
  the rest of the controller resolves a `_resourceBundle`; this is inconsistent
  and should be made explicit.
* `Mac/Tests/MADMacSmokeTest.m` asserts exact English UI: the `New Document`
  button (line 358), the driver popup titles (408-409), the page/row status
  strings (726-728), `About MAD Designer` (847), the Overview copy (877-888),
  and `Open Source Components` / `License Texts` (919, 936). All of these break
  under translation or pseudo-localization.
* `MADMacViewerViewController.m:452-457` detects authentication failures by
  searching English substrings (`access denied`, `authentication`, `password`,
  `login failed`, `credentials`, `fe_sendauth`). If driver messages are ever
  localized, this check must move to error codes.

### 2.4 The localization-adjacent build settings

Every target already sets:

```
CLANG_ANALYZER_LOCALIZABILITY_NONLOCALIZED = YES
```

That is the Clang static analyzer's `NonLocalizedStringChecker`. It is an
**Analyze-action** check, not a build warning; it only runs under
`xcodebuild analyze`. The companion setting,
`CLANG_ANALYZER_LOCALIZABILITY_EMPTY_CONTEXT`, is also `YES`, set on both
project-level configurations (`4C384E46` Debug and `4C384E47` Release), so
every target inherits it; an earlier draft of this report said it was off and
was wrong. No target set `LOCALIZATION_PREFERS_STRING_CATALOGS` before this
branch.

The app project declares 33 `knownRegions`, including `ar` and `he`, but there
are no localized resources behind them. The Linux workflow now runs the
localization audit's tests and check; the Clang analyzer is still not run in CI.

### 2.5 Tests

Several unit-test assertions compare exact English copy (for example
`MADDesignerUnitTests.m:379,699,773,887,889`). The branch adds
`MADLocalizationTests`, the `MAD Designer German` scheme, and the Accented and
Double-Length pseudo schemes, so the catalog value, the German storyboard
title, and both pseudo modes are exercised. The iOS UI tests still set no
`-AppleLanguages` launch argument, and CI runs no iOS suite (the Linux job
remains the only required gate).

**Planning estimate after deduplication:** roughly 900-1,100 unique keys, or
about 4,500-5,500 translated strings across five languages. The dominant blocks
are the barcode display names, the storyboards, and the Mac app.

## 3. Scope: what to translate and what not to translate

| In scope | Out of scope (keep English/verbatim) |
| --- | --- |
| App UI: menus, buttons, titles, labels, placeholders, status text | Licence bodies: `LICENSE`, `NOTICE`, `ThirdParty/Licenses/*` |
| Alerts, errors and errors' `NSLocalizedDescriptionKey`/`NSLocalizedFailureReasonErrorKey` that the app authors | Copyright lines and legal notices, including the About component notices |
| Accessibility labels, hints and values | Brand and product names: MAD, MAD Designer, MAD Viewer, MAD Query, SQL, MySQL, MariaDB, PostgreSQL, SQL Server, SQLite, iCloud, GitHub |
| Storyboard/xib text, including `InfoPlist.strings` document-type names | SQL keywords, table/column names, query text, SQL data-type names (`Bit`, `Blob`, `Date`, …) |
| `Settings.bundle` (`MAD Settings`, `Query Settings`, `Limit Results`) | Text returned by a database server or driver, and server error text |
| Date, number, currency and percentage formatting in the UI | File names, UTIs, bundle identifiers, keychain keys, notification names |
| Plural rules | Log messages, assertions, test names, comments |
| The About page's chrome and section headings | The Linux/CLI output and the documentation |

Two judgement calls are listed as decisions in §4: the SQL data-type names and
the driver's own error text. The recommendation is to keep both English.

## 4. Decisions

### D1 — Languages

Mirror the documentation's set. The app-side codes are Apple's, which are not
always the docs' website codes:

| Docs | App bundle code | Note |
| --- | --- | --- |
| `en` | `en` | Source, development region |
| `de-DE` | `de` | |
| `es-419` | `es` (or `es-419`) | `es` matches all Spanish variants; `es-419` matches Latin American ones and falls back to English for `es-ES`. Recommend `es` with the es-419 copy, reviewed. |
| `ja-JP` | `ja` | |
| `pt-BR` | `pt-BR` | |
| `zh-CN` | `zh-Hans` | Apple's code for Simplified Chinese; `zh-Hant` can be added later. |

Arabic and Hebrew are declared in `knownRegions` but are not in this plan; RTL
is out of scope until an RTL language is actually added. The code is mostly
ready for it (leading/trailing constraints), but the 74 absolute alignments
would need work.

### D2 — Catalog format

Use a String Catalog (`.xcstrings`) as the source of truth, one file per table.
It holds the source strings, translations, plural variations, and extraction
state in one diffable file, and Xcode 15+ can import/export XLIFF around it.
Verified on this machine:

```sh
xcrun xcstringstool extract --legacy-localizable-strings --output-directory /tmp/stringsdata <sources…>
xcrun xcstringstool sync Localizable.xcstrings --stringsdata /tmp/stringsdata/*.stringsdata
xcrun xcstringstool compile Localizable.xcstrings --output-directory /tmp/out
# → /tmp/out/<lang>.lproj/Localizable.strings
```

**Caveat, verified 2026-11-04:** `sync` updates entries that already exist and
marks removed keys stale, but on this toolchain it does **not** add new keys.
`scripts/localization/sync_catalog.py` is the seeding step: it adds every
literal key and every used constant, then `xcstringstool sync` can maintain
existing entries and `compile` builds the products.

Fallback if the ObjC integration proves awkward: keep the catalog as the source
of truth and compile it to `.strings`/`.stringsdict` with `xcstringstool compile`
(or use `genstrings` plus an import script). No information is lost by keeping
the source in the catalog either way.

### D3 — Key policy: the English text is the key

Keep `NSLocalizedString(@"Open Document", @"Opens the selected document.")`.
This is what the code already does, and it has three concrete advantages here:

* With no catalog (framework unit tests, the Linux/GNUstep build, the Mac smoke
  test binary), the lookup returns the key, which is correct English. Symbolic
  keys would return `"explorer.open_document"`.
* The English source is the translator's primary context.
* No churn across the existing call sites.

The cost is that changing English copy orphans its translations. Mitigation:
freeze the English copy before the first translation pass, make copy changes
deliberately (update every language in the same PR), and use the catalog's
extraction state to spot stale keys. For genuinely ambiguous short strings
("Back", "Group", "Item"), add a real comment, not a copy of the string.

### D4 — Bundle and catalog layout

* **One `Localizable.xcstrings` in the iOS app targets** (`MAD Designer` and
  `MAD Viewer`). Because `NSLocalizedString` is
  `[NSBundle.mainBundle localizedStringForKey:value:@"" table:nil]`, this one
  catalog serves the app and every embedded framework. The frameworks do not
  need their own string tables.
* **The same catalog compiled into the Mac app bundle** by `Mac/build.sh` into
  `Contents/Resources/<lang>.lproj/Localizable.strings`. Mac-only keys can live
  in the same file; unused keys in iOS are harmless. If a Mac-only table is
  preferred, add `MacLocalizable.xcstrings` and use
  `NSLocalizedStringFromTable`.
* **Per-framework localized storyboards** for `MADMySQL`, `MADTdsClient`, and
  `MADPostgres`, because those storyboards are loaded from the framework
  bundles. Each needs its own `Base.lproj` + per-language `.strings` in that
  framework's resources.
* **App-bundle storyboards** for the 18 app storyboards and 3 xibs.
* **`InfoPlist.strings`** in the app bundle and the Mac bundle for top-level
  keys only: `CFBundleDisplayName`, `CFBundleName`, and
  `NSHumanReadableCopyright`. `CFBundleTypeName` and `UTTypeDescription` are
  nested inside document-type dictionaries, which `InfoPlist.strings` does not
  localize; keep the English "Mobile Analytics Document" for now (it is a
  technical document-type label) or localize it in code if the user asks.
  `CFBundleLocalizations` declares the supported languages on both platforms.
* **`Settings.bundle/<lang>.lproj/Root.strings`** for the three settings
  strings.

### D5 — Storyboards: Base.lproj, not code

Move each storyboard/xib into `Base.lproj` and add a per-language `.strings`
through a variant group. Do this in one dedicated commit per project, because
it is the largest `project.pbxproj` change in the plan. `ibtool` was verified:

```sh
xcrun ibtool --export-strings-file /tmp/MADQuery.strings MADQuery.storyboard
```

The exported keys are object-ID based (`5gw-CY-Adb.text`), which is stable as
long as the storyboard object IDs are not regenerated. Do not recreate the
storyboards from scratch afterwards.

**Optional simplification first:** the three live driver storyboards are
near-duplicates. Consolidating them into one app-bundle storyboard (with the
port/schema difference set in code) would remove three frameworks' worth of
localization work. It is a behaviour change and should be a separate, reviewed
refactor, not part of the localization branch.

**Optional cleanup:** delete MADAPI's dead `MADCreateDocument.storyboard` and
the dead `MADDesigner/Resources/SupportingFiles/InfoPlist.strings`, which is not
in any build phase.

### D6 — What is not translated

See §3. In particular, the About page's licence bodies and component notices
stay verbatim in English. This is standard practice: a translation of a licence
is not the licence, and translating a copyright notice or a licence name can
create legal ambiguity. Translate the chrome around them and add a localized
sentence saying the texts are shown in their original English.

### D7 — Translation sourcing

Use the catalog/XLIFF as the interchange format:

```sh
xcodebuild -exportLocalizations -workspace Reports.xcworkspace \
  -localizationPath /tmp/MAD.xliff -exportLanguage de
# translate the .xlf, then:
xcodebuild -importLocalizations -workspace Reports.xcworkspace \
  -localizationPath /tmp/MAD.de.xlf
```

Recommended: **AI-drafted translations with a native-speaker review pass**, as
the documentation already does. UI strings are short and context-poor, so the
review must see the screen (or a screenshot) and the developer comment, not
just the string. Build a glossary first; consistency matters more in a BI tool
than in marketing copy. If a vendor is used, XLIFF plus screenshots is a
standard handoff.

### D8 — CI and tests

* Keep the iOS unit tests pinned to English for deterministic assertions, and
  replace exact-copy assertions with `NSLocalizedString(key, nil)` lookups where
  the test is about behaviour rather than copy.
* Add `-AppleLanguages (en)` / `-AppleLocale en_US` to the UI-test launch
  arguments, and add a small localized-run matrix.
* Run a text-based audit in the Linux workflow (no Xcode needed); optionally add
  a macOS `xcodebuild analyze` job.
* The Linux/GNUstep build must keep compiling unchanged: keep using
  `NSLocalizedString`, not a custom macro, and do not make catalogs a build
  dependency of the headless targets.

### D9 — Decision record (2026-11-04)

| Decision | Answer |
| --- | --- |
| **D1 — Languages** | Ship all five translations: `de`, `es`, `ja`, `pt-BR`, `zh-Hans`; `en` stays the source and development region. |
| **D1 — Spanish code** | `es` (generic), carrying the `es-419` copy. `es-419` is not a separate bundle; `es` matches Spain too. |
| **D5 — Driver storyboards** | **Do not consolidate.** One `MADCreateDocument` storyboard per driver is a deliberate pattern: a developer adding a database driver adds that driver's storyboard. The near-identical strings (username, password, …) may be shared in translation, but the resources stay per framework. |
| **D7 — Translation route** | AI drafts; the user reviews every language and takes the screenshots. The agent does not produce the screenshot pack. |
| **D10 — Platform timing** | iOS first. macOS bundle infrastructure is built in parallel, but macOS string translation follows iOS. |
| **D11 — Barcode names** | Consolidate the 65 dictionary entries and 66 `self.name` assignments into one table before translating. |
| **D12 — SQL parser messages** | Translate all of the app's own parser and validation messages, not just the common ones. They need a technical glossary and a review pass. |
| **D13 — Date formatter** | Keep `MADDateFromTimeFormatter`'s component-selection algorithm and cached spell-out formatter. Localize only the unit and sentence layer; do not replace it with `NSDateComponentsFormatter`/`NSRelativeDateTimeFormatter`. Measured cost is ~11 µs per call. |

Still open, and not blocking Phase 0-1: SQL data-type names (§11.6), the
parser/validation messages (§11.7), workspace brand names (§11.8), and a
language override in settings (§11.9).

## 5. Finding the strings: what the tools can and cannot do

This is the direct answer to "can we make the build warn about unlocalized
strings?"

### 5.1 The build flags

`CLANG_ANALYZER_LOCALIZABILITY_NONLOCALIZED = YES` is already set on every
target. It enables the analyzer's `NonLocalizedStringChecker`, which warns when
a non-localized string literal is passed to a UIKit/AppKit method that expects a
localized string. It is useful, but narrower than it sounds:

* It runs only when the analyzer runs (`xcodebuild analyze`), never on a normal
  build. CI does not run it today.
* It knows a fixed list of system APIs. Custom APIs such as
  `MADOperationPromptPolarQuestion -initWithTitle:message:` are invisible, and
  if a constant `NSString *s = @"Database Settings";` is assigned to a local and
  passed later, the check misses it.
* It does not look at storyboards or plists.
* Empirically, `xcodebuild analyze` on `MADExplorer` and `MADAPI` produced **zero
  localization warnings** (and two unrelated warnings in `MADExplorer`). The
  code really is largely wrapped, but a clean analyzer run is not a completeness
  proof.

Turn on `CLANG_ANALYZER_LOCALIZABILITY_EMPTY_CONTEXT = YES` as well: it flags
`NSLocalizedString(key, nil)` and contexts that give the translator nothing.
Most of the existing comments are just the key repeated, which is legal but not
useful.

There is **no compiler warning in Objective-C for an unwrapped `@"..."`**. The
analyzer check above is the closest thing, and it is API-specific. `-Wformat`
checks format arguments, but `NSLocalizedString` is not annotated as a format
function, so a bad format string is only caught where it is consumed by
`initWithFormat:`/`appendFormat:`.

### 5.2 The extraction tools

* `genstrings` and `xcrun xcstringstool extract --legacy-localizable-strings`
  find what is already wrapped. They warn on non-literal keys (verified: the
  MADExplorer extraction warned at `MADExplorerViewDelegate.m:460` for
  `NSLocalizedString(MADTextNotDownloaded, …)`). They cannot find raw literals.
* `xcrun xcstringstool sync` merges `.stringsdata` into the catalog and marks
  removed keys stale; `compile` emits `.lproj/Localizable.strings` (and
  `.stringsdict` for plurals). Verified end to end.
* `ibtool --export-strings-file` emits storyboard/xib strings (verified: 13
  entries for `MADQuery.storyboard`).

### 5.3 The audit script (recommended)

Add a repo-local, dependency-free Python script that runs in the existing Linux
workflow and locally. It should:

1. Extract every `NSLocalizedString` literal key and report non-literal first
   arguments (111 calls: 91 constant keys and 20 runtime values).
2. Flag raw literals passed to known UI APIs (`alertControllerWithTitle:`,
   `addAction:`/`UIAction actionWithTitle:`, `setTitle:`, `setText:`,
   `placeholder`, `NSLocalizedDescriptionKey`, `accessibilityLabel`,
   `accessibilityHint`, `NSAlert` message/buttons, `initWithTitle:message:` on
   the app's own prompt classes) **and** literals assigned to those properties.
3. Flag multi-argument format strings with no `%n$` positional specifiers.
4. Flag `stringByAppendingString` / `appendString:` used to assemble a sentence
   near UI code (there are ~88 such calls in the app and API directories; most
   are harmless, so this is a warning-only category).
5. Keep a checked-in allowlist for non-UI literals (SQL, identifiers, keys,
   fonts, URLs, brand names, data-type names) so the report stays actionable and
   CI fails only on new offenders.

The script is heuristic. Its value is the baseline: before instrumentation it
lists the work; after it, it catches regressions. It belongs in the Linux CI
because it is pure text and needs no Xcode.

#### 5.3.1 The recorded baseline (2026-11-04)

`scripts/localization/audit.py` implements this, with
`scripts/localization/audit_test.py` (11 unittest cases) and
`scripts/localization/baseline.json` checked in. The Linux workflow runs both
the tests and the check on every push and pull request. Commands:

```sh
python3 -I scripts/localization/audit_test.py        # the audit's own tests
python3 -I scripts/localization/audit.py             # the CI check
python3 -I scripts/localization/audit.py --report    # every finding, with lines
python3 -I scripts/localization/audit.py --write-baseline   # after review
```

`sync_catalog.py` is the seeding step for both kinds of source key: every
literal `NSLocalizedString(@"Key", @"Context.")` key (using the context as the
comment when it is meaningful) and every used
`NSString * const NAME = @"Key";` definition (with the symbol and file as the
comment). It preserves existing entries and translations.

```sh
python3 -I scripts/localization/sync_catalog.py          # seed the catalog
python3 -I scripts/localization/sync_catalog.py --check  # CI check
```

The policy stays: a constant is acceptable for a string used repeatedly; a new
one-off string uses a literal at the call site. The Linux workflow runs the
sync's tests and the `--check` form. Unresolved symbols are reported but do not
fail the check, because a definition can live outside the scanned roots.

Current run (2026-11-04, after the Phase 2 runtime-key fixes and the Mac
selector expansion; 1536 files scanned). `MADDataStructures` is included;
`MADFeedback` is excluded because it is neither embedded nor maintained.
`Compressor`, `ThirdParty`, build trees, `Archive`/`Archived`,
`ReceiptModuleAsn1c`, and test bundles are excluded:

| Measure | Count |
| --- | ---: |
| `NSLocalizedString` calls | 673 |
| literal first argument | 613 |
| non-literal first argument | 81 |
| unique literal keys | 439 |
| literal keys containing format specifiers | 30 (multi-argument 2, both positional) |
| raw UI literals | 204 occurrences / 200 unique |
| format strings without positional specifiers | 0 |
| `appendString:`/`stringByAppendingString:` near UI | 42 (warning) |

The 238 baseline entries are 200 `raw-ui-literal` and 38 `nonliteral-key`;
warnings are reported but never fail an otherwise clean check. Entries carry an
occurrence count, so adding a second copy of an already-baselined string in the
same file fails the run. The first Phase 1 run, before these changes and with
`MADFeedback` in scope, was 1505 files / 564 calls / 246 entries.

Two reconciliations with §2:

* **`MADBarcodes` is 9 active calls in one file**, as the table says. A plain
  `grep` reports 16 because `MADBarcodeView.m:31-110` is a block comment; the
  audit strips comments, so the 7 commented-out calls are not counted.
* **`MAD/Source` has 125 calls, not 124** (the table's `MAD` row). That was
  the only drift found in the first run: total iOS/shared calls were 560 (or
  564 including the Mac's 3 and `MADTds`'s 1), not 559. The non-literal split
  (111) and the barcode count matched exactly. The current counts differ because
  the Phase 2 fixes changed the call sites and the scope changed.

The `raw-ui-literal` category is still narrower than the full inventory. It
catches a literal passed directly to a known UIKit, NSAlert, or AppKit API, a
literal stored in a UI property, and an `NSError` description key. It does not
catch display-name tables (barcode, paper, document-object, SQL type) or
sentences built through a helper; those remain Phase 2 work and are why the
baseline is a floor, not the full inventory. The AppKit selector set is in
`audit.py`; a new AppKit constructor or property must be added there and
covered by a test in `audit_test.py`.

The "59 format-bearing keys" in §2 counted call sites including constant keys.
The audit inspects literal keys only: 29 unique keys now, and both
multi-argument keys use positional specifiers after the Phase 2 fix.

### 5.4 Runtime detection

Pseudo-localization is the best check for strings the tools miss:

* Xcode's scheme option **App Language → Double-Length Pseudolanguage** expands
  every translated string and exposes truncation.
* **Accented Pseudolanguage** accents translated strings; any text that stays
  plain English is either unwrapped or marked do-not-translate. This is the
  fastest way to find the residual hardcoded surface.
* For the Mac app, the same effect is available by launching with a pseudo
  language argument; the exact identifier should be taken from Xcode's scheme
  editor rather than guessed.

## 6. Work plan

Sizes are order-of-magnitude engineering effort for one developer; translation
turnaround is elapsed time and runs in parallel.

### Phase 0 — Decisions and baseline (2-3 days)

* Confirm languages (D1), catalog format (D2), key policy (D3), and the
  do-not-translate list (D6).
* Freeze the English copy of the strings that will be translated.
* Build the glossary (query, datasource, grouping, aggregate, predicate, join,
  band, section, detail, record, field, report header/detail/footer, …).
* Choose the translation route (D7) and the review process.
* Land the audit script and record the baseline counts from this report.

**Exit:** the decisions are recorded here; the audit script runs and its
baseline is committed.

**Status 2026-11-04 — complete.** The decisions are D9. The audit is
`scripts/localization/audit.py` with `audit_test.py` and `baseline.json`; the
Linux workflow runs its tests and the check on every push and pull request. The
recorded baseline and the two inventory reconciliations are §5.3.1.

### Phase 1 — Infrastructure (2-3 weeks)

* Add `Localizable.xcstrings` to `MAD Designer` and `MAD Viewer`; set
  `LOCALIZATION_PREFERS_STRING_CATALOGS = YES`.
* Convert the 18 app storyboards and 3 xibs to `Base.lproj` variant groups. The
  six target languages and `Base` are already in the app project's 33
  `knownRegions`; no region-list change is needed, though the list also
  advertises `ar`/`he` with no resources behind them.
* Convert the three live driver storyboards in their own projects; delete or
  leave the dead MADAPI copy.
* Add the languages and localized resources to the Mac bundle in
  `Mac/build.sh`, plus `CFBundleLocalizations` and `InfoPlist.strings`.
* Add `Settings.bundle` localization.
* Verify `CLANG_ANALYZER_LOCALIZABILITY_EMPTY_CONTEXT` per target. It is
  already `YES` at the project level (see §2.4); there is nothing to enable
  unless a target overrides it.
* Add the audit script to CI and a make/run target; add a pseudo-localization
  scheme (or two). The screenshot pass is the user's (D9), so no agent-built
  capture harness.
* Prove the pipeline with one throwaway German string in both apps.

**Exit:** a build of each app contains the expected `.lproj` folders; a German
"hello" renders in iOS and macOS; the audit runs in CI; no storyboard is still
a single-language resource.

**Status 2026-11-04 — complete.** Landed on
`feature/app-localization-foundation`:

* `MADDesigner/Resources/Localizable.xcstrings`, in both the `MAD Designer` and
  `MAD Viewer` targets, with `LOCALIZATION_PREFERS_STRING_CATALOGS = YES` on all
  four app configurations. The built apps contain `de.lproj/Localizable.strings`
  and `en.lproj/Localizable.strings`; the unit test
  `MADLocalizationTests` resolves `Choose Storage Option` to
  `Speicherort wählen` under `-testLanguage de`.
* `MADQuery.storyboard` is the first storyboard in `Base.lproj`, with
  `de.lproj/MADQuery.strings`. Both app bundles contain
  `Base.lproj/MADQuery.storyboardc` and `de.lproj/MADQuery.strings`; the
  simulator test loads the compiled storyboard under German.
* `Mac/build.sh` compiles the shared catalog into
  `Contents/Resources/<lang>.lproj`, and `Mac/Resources/Info.plist` declares
  `CFBundleLocalizations` (`en`, `de`). `./Mac/build.sh --no-frameworks`
  produces both `.lproj` folders and a valid signature.

Also landed after the first proof: all 17 remaining app storyboards and the 3
xibs are in `Base.lproj` (both app targets compile all 21 resources, nothing
left at the bundle root); the three live driver storyboards are in their own
projects' `Base.lproj`; `Settings.bundle/de.lproj/Root.strings` carries the
three German titles; both iOS `Info.plist`s declare `CFBundleLocalizations`
(`en`, `de`); and two shared schemes, **MAD Designer Pseudo Accented** and
**MAD Designer Pseudo Double-Length**, pass
`-NSAccentuateLocalizedStrings` / `-NSDoubleLocalizedStrings`. Both were
verified in the unit test: the catalog value becomes accented
(`Çh̃o̥o̥şë S̈t̃o̥r̀a̧ģë O̧p̊t̃i̥o̥ñ`) and doubled
(`Choose Storage Option Choose Storage Option`). This is the runtime tool for
finding unwrapped strings; the Xcode scheme menu just sets these defaults.

The third shared scheme, **MAD Designer German**, passes
`-AppleLanguages (de)` and `-AppleLocale de_DE` on both the Run and Test
actions. `MADLocalizationTests` uses it to assert the German catalog value and
the loaded storyboard's navigation title (`Generierte Abfrage`), and it reads
the German bundle directly so the German assertions also run under an English
process language.

Xcode upgraded all three driver projects from `objectVersion 51` to `55` while
building them; `MADMySQL` additionally normalized two `OTHER_LDFLAGS` arrays to
the equivalent `"-lc++"` string. No target, phase, resource, or setting was
lost; `plutil -lint` passes and each driver framework builds.

Remaining for Phase 1: `InfoPlist.strings` for the genuinely translatable
top-level keys (the display name is a brand and the copyright is legal text,
so this may stay empty for now; the nested document-type names are not
coverable this way — see D4) and broadening `CFBundleLocalizations` as each
language lands. The screenshot pass belongs to the user (D9), so no agent-built
capture harness is planned; the pseudo schemes and the `-UITestOpenSample` /
`-UITestSelectTab` hooks are the manual tooling. The
`CLANG_ANALYZER_LOCALIZABILITY_EMPTY_CONTEXT` item needs only a per-target
check: it is already `YES` at the project level (§2.4). The 22 storyboards in
the plan's count are the 18 app storyboards plus three live driver copies plus
the dead MADAPI copy; the dead copy is not converted.

### Phase 2 — Instrument the strings (4-6 weeks)

Work module by module, in this order:

1. `MADDesigner/Source` (the app itself): wrap the raw UI literals, fix the 20
   runtime-value keys, convert the `MADText*` constant calls to literals at the
   call site (or add manual catalog entries), and give every key a real
   comment.
2. `MAD` and `MADAPI` (connection, query, SQL entry, report output).
3. `MADExplorer`, `MADCocoaExtensions`, `MADFoundation`, `MADFileManager`
   (small; `MADFileManager` currently has no localized calls at all).
4. The drivers (`MADMySQL`, `MADTdsClient`, `MADPostgres`, `MADSqlite3`,
   `MADBarcodes`): the wrapper's own messages only; leave server text alone.
   Consolidate the 65 barcode display names with the 66 `self.name`
   assignments first, then localize one table.
5. Storyboard strings: export, review, and mark brand/sample/technical strings
   do-not-translate.
6. Plurals: replace the hand-rolled plural sites (`NSDate+Extras.m`,
   `MADLabelStatus.m`, `MADAlertController.m`, `MADViewControllerSQL.m`,
   `MADActivityItemProviderPdf.m`, `MADocument.m`, `MADPageStatusView.m`) with
   catalog plural rules and `localizedStringWithFormat:`. The date formatter
   keeps its own component selection and millisecond fallback (D13); the Cocoa
   relative formatters cannot express them, and the measured cost is already
   low.
7. Format strings and numbers: convert `%1@`/`%2@` to `%1$@`/`%2$@`; add
   positional specifiers wherever an argument can be reordered; replace the
   hardcoded separators in `NSNumberFormatter+MADExtensions.m` and the
   file-size formatter in `MADStandard.mm` with locale-aware formatters.
8. Accessibility: add missing labels/hints, especially to the storyboard
   controls that have none.
9. `InfoPlist.strings`, `Settings.bundle`, and the Mac app (see Phase 5).

**Exit:** the audit reports no unwrapped user-facing literal outside the
allowlist; every `NSLocalizedString` key has a useful comment; the pseudo-
language run shows no plain English on screen except brand/technical strings.

**Status 2026-11-04 — started.** The runtime-value keys and the two format
strings are fixed (27 baseline entries removed). Non-literal calls are 81,
made up of 55 unique entries: 53 constant symbols plus `MADMessageCloudSignout`
and `MADTextFreeGift`, whose definitions the audit does not resolve. The audit
now covers the AppKit constructors and properties the Mac app uses, and
baseline entries carry occurrence counts. `sync_catalog.py` seeded the catalog
from the source: 430 literal keys plus the 53 resolved constants (477 entries),
with the two unresolved names still needing handling. Every iOS-side raw UI
literal is wrapped: the app target (27), the MAD framework (75, including all
47 SQL parser and resolver messages per D12), MADFoundation (10) and the
MySQL/PostgreSQL wrappers (12). The only raw UI literals left are the Mac's
204, which Phase 5 owns. The locale formatters are fixed:
`ma_twoDecimalPlacesFormatter` no longer pins separators, and `MADStandard`'s
file size uses `NSNumberFormatter` with the localized `%@ MB` key. Next:
plurals (the delete alert, records/page status line, applied-SQL counts,
page status, and the date formatter are done; the PDF/document page counts
remain), accessibility, and the storyboard strings.

### Phase 3 — Pilot language (1-2 weeks)

Translate one language end to end. **German is the best stress test** (long
compounds), **Spanish is the largest reach**. Recommended: German first.

* Translate code, storyboards, Info.plist, Settings, and Mac.
* Fix truncation: the 15 fixed widths, `MADBarcodeDesigner`'s frame layout,
  `MADLabelStatus`'s 230×44 box, and the Mac inspector labels.
* Run VoiceOver, Voice Control, and the largest Dynamic Type size.
* Refine the glossary and the translator's screenshot pack.

**Exit:** German is complete and reviewed; no clipped text on the pilot screens;
the process for handoff/merge is written down.

### Phase 4 — Remaining languages (1-2 weeks engineering + vendor time)

Spanish, Japanese, Brazilian Portuguese, and Simplified Chinese. Reuse the
pilot's corrections; review each language in-app; capture the language-matrix
screenshots.

### Phase 5 — macOS parity (1 week, can run in parallel with Phase 2-4)

The Mac app is small but has the most raw strings (~413):

* Wrap menus, window and panel titles, buttons, labels, tooltips, accessibility
  descriptions, alerts, export format names, and About chrome.
* Leave the About legal text, component notices, and copyright verbatim.
* Add `Localizable.xcstrings` (or compile the shared catalog) and
  `InfoPlist.strings` to `Mac/build.sh` before codesign.
* Replace English substring matching in
  `MADMacViewerViewController.m:452-457` with error codes before localizing the
  messages it matches.
* Make the smoke test locale-aware (compare through `NSLocalizedString`, or run
  it with an explicit `en` bundle).
* Add formatters for inspector values, ports and percentages.

### Phase 6 — Ongoing

* Every new user-facing string goes through `NSLocalizedString` with a comment;
  CI's audit fails on new unwrapped literals.
* Run `sync_catalog.py` after adding keys (`xcstringstool sync` only updates
  entries that already exist); never rename an English key without updating all
  languages in the same PR.
* Re-run the pseudo-language screenshot pass each release.
* App Store metadata (name, subtitle, keywords, screenshots, privacy answers)
  is a separate content workstream; it is not produced by the app bundle.

## 7. String rules for developers

* Wrap every user-facing literal in `NSLocalizedString(@"English", @"Context.")`
  at the point of use. Do not pass a variable as the key.
* Never concatenate a sentence at runtime. Use one format string and let the
  translator reorder it; use positional specifiers (`%1$@`) whenever there is
  more than one argument.
* Use the catalog's plural variations and `localizedStringWithFormat:`, not
  hand-written singular/plural pairs. When the number must also be grouped,
  pass the numeric count as the plural selector and the preformatted number as
  a separate `%@` argument; the catalog substitutes the noun on the numeric
  argument. `MADLabelStatus` and `MADAlertController` show the pattern.
* Use `NSNumberFormatter`/`NSDateFormatter`/`NSDateComponentsFormatter` with
  the user's locale; never hardcode `.` as a decimal separator or `%` placement.
* Use `leading`/`trailing` and `natural` alignment, not `left`/`right`, even
  while the current language set is LTR.
* Accessibility text is UI text: localize it, and do not leave it empty on a
  control that has a visible label.
* Mark brand names, SQL identifiers, data-type names, and server text
  do-not-translate rather than leaving them as unmarked raw literals.
* Keep the English copy stable once it has translations.

## 8. The About page and the licences

The About screens load licence files from `ThirdParty/Licenses` (iOS:
`MADAboutTableViewController.m:64-141`; Mac:
`MADMacAboutWindowController.m:142-454`). The policy:

**Translate:** the screen title, `Open Source Components`, the intro sentence,
`License Texts`, the Mac tabs (`Overview`, `License & Notice`, `Acknowledgements`),
the Mac Overview prose, and the section headings (`Licensing & Product Marks
Notice`, `LGPL-3.0 Written Relink Offer…`, `MIT License`).

**Do not translate:** every licence body, the `LICENSE` and `NOTICE` files, the
copyright lines, the licence names, and the per-component notices (including
"Public domain", "Provided under the zlib License", and the LGPL relink offer).
Those are legal notices; a translation is not the notice and may not satisfy
the inclusion obligation.

Add one localized sentence at the top of the licence section: "The licence
texts below are reproduced in their original English." This is the standard
approach and avoids the question entirely. On the Mac, `InfoPlist.strings` can
carry the copyright line unchanged if it ever needs to be in a localized table;
it should not be machine-translated.

## 9. Quality assurance

* **Pseudo-localization:** Double-Length and Accented runs on every screen, on
  iPhone, iPad, and Mac. Any unaccented text is unwrapped.
* **Screenshots:** capture each screen in each language; diff against English
  for truncation and line-break damage.
* **Plurals:** test 0, 1, 2, 5, and 21 (and the language's own rules) on records,
  pages, rows, elements, tables, joins, filters, and groups.
* **Numbers and dates:** run with `de_DE`, `ja_JP`, `pt_BR`, `es_419`, and
  `zh_CN` locales, not just languages. Check the document subtitles, file
  sizes, and paper names: the shared formatter and `MADStandard.mm` currently
  hardcode `.`/`,` separators and `" MB"`.
* **Format strings:** the audit must report zero multi-argument strings without
  positional specifiers; manually reorder one translated string per language as
  a proof.
* **Display-name tables:** barcode names, paper names, document-object names,
  and SQL type names must come from one localized table, not two copies that
  drift.
* **Glyphs:** Font Awesome private-use characters and `✓` must remain
  byte-identical in every language; they are symbols, not words.
* **Storyboard placeholders:** design-time values such as `Item`, `Title`,
  `Detail`, and the Lorem ipsum body must be marked do-not-translate, not
  translated.
* **Accessibility:** VoiceOver in each language; labels and hints must not be
  English under a non-English run.
* **Tests:** the iOS suites pass in English; a smoke run in one translated
  language passes; the Mac smoke test is locale-aware.
* **RTL:** not tested, because no RTL language ships. If one is added, audit the
  74 absolute alignments and the 15 fixed widths first.

## 10. Risks

| Risk | Likelihood | Mitigation |
| --- | --- | --- |
| Storyboard `Base.lproj` conversion creates large pbxproj churn and merge conflicts | High | One dedicated commit per project; do it before other work; verify with a build |
| English-as-key orphans translations when copy changes | Medium | Freeze copy before translation; update every language in the same PR; use catalog state |
| Fixed-width and frame-based layouts clip translations | High | Pilot language first; list of 15 fixed constraints; screenshot matrix; adjust constraints in the pilot |
| The analyzer gives false confidence | High | Do not treat `analyze` as a gate for completeness; the audit script and pseudo-localization are the real gates |
| The three driver storyboards drift further | Medium | Consolidate them first, or keep them in one translation batch and review together |
| Barcode display names are duplicated (65 dictionary entries + 66 `self.name`) | High | Consolidate to one table before translating; otherwise every name is translated twice and drifts |
| Hardcoded locale assumptions (`.`/`,` separators, `" MB"`, `pt`, paper sizes) | High | Fix the shared number formatter and file-size helper before the pilot; test in `de_DE` and `ja_JP` |
| Tests fail under non-English runs | High | Pin tests to English; assert via `NSLocalizedString`; make the Mac smoke test locale-aware |
| Translation quality for short, context-poor strings | Medium | Comments, screenshots, glossary, native review |
| Mac build-script drift (no Xcode project) | Medium | Add the `.lproj` copy/compile step before codesign and make it part of `--smoke-test` |
| App Store declares fewer languages than the bundle has | Low | The `.lproj` set drives the list; verify the built bundle's `lproj` folders |
| Legal text accidentally translated | Low | Keep it out of the catalog/XLIFF; do-not-translate markers; review |

## 11. Open questions for the user

Questions 1-5 and 10 were answered on 2026-11-04 — see D9. Questions 6-9 stay
open; none of them blocks Phase 0 or 1.

1. **Languages:** mirror the documentation's five (de, es, ja, pt-BR, zh-Hans)?
   Or start with one or two? — **Answered: all five (D9).**
2. **Spanish:** `es` (generic, matches all Spanish) or `es-419` (matches Latin
   American, falls back for Spain)? The docs use `es-419`. — **Answered: `es`
   with the es-419 copy (D9).**
3. **Translation route:** AI draft + native review, or a professional vendor?
   — **Answered: AI draft, user reviews and takes screenshots (D9).**
4. **Timing:** iOS first, then macOS? Or both in parallel? The Mac work is
   independent, though its 413 strings are the largest single block. —
   **Answered: iOS first, macOS infrastructure in parallel (D9).**
5. **Consolidate the three driver storyboards before translating?** Recommended,
   but it is a behaviour change. — **Answered: do not consolidate; the
   per-driver pattern is deliberate (D9).**
6. **SQL data-type names** (`Bit`, `Blob`, `Date`, …): keep English (recommended)
   or translate with a glossary?
7. **The app's own SQL parser/validation messages** ("The statement does not
   start with SELECT."): translate now or keep English in v1? They are
   user-facing but highly technical. — **Answered: translate all of them
   (D12).**
8. **Workspace names** (`MAD Query`, `MAD Designer`, `MAD Viewer`): keep as
   brands (recommended) or translate the generic part?
9. **A language override in app settings** for support/testing? Not required by
   the OS, but useful for QA.
10. **Consolidate the barcode display names** (65 dictionary entries plus 66
    `self.name` assignments) before translating? Recommended; otherwise every
    name is translated twice and the copies drift. — **Answered: consolidate
    before translating (D9).**

## Appendix A — Inventory commands

```sh
# Count calls and files. This is textual: 573 occurrences in the iOS/shared
# modules, but 14 are inside comments. The active count is 559 across 106
# files; use a comment-stripping scanner (or xcstringstool extract) for the
# authoritative figure.
grep -rn "NSLocalizedString" --include="*.m" --include="*.h" . | wc -l
grep -rl "NSLocalizedString" --include="*.m" --include="*.h" . | wc -l

# Unique literal keys by module (309 unique literal keys repo-wide)
grep -rhoE 'NSLocalizedString\(\s*@"([^"\\]|\\.)*"' --include="*.m" MODULE \
  | sed -E 's/.*@"//; s/"$//' | sort -u | wc -l

# Non-literal keys (approximate; the authoritative split is 91 constant and
# 20 runtime calls). Use a parenthesis-balancing scanner for multi-line calls.
grep -rnE 'NSLocalizedString\([^@]' --include="*.m" MODULE

# Storyboard strings
xcrun ibtool --export-strings-file /tmp/OUT.strings FILE.storyboard
grep -c '^"' /tmp/OUT.strings

# String-catalog round trip
xcrun xcstringstool extract --legacy-localizable-strings \
  --output-directory /tmp/stringsdata <sources…>
xcrun xcstringstool sync Localizable.xcstrings --stringsdata /tmp/stringsdata/*.stringsdata
xcrun xcstringstool compile Localizable.xcstrings --output-directory /tmp/out

# Analyzer (the only "unlocalized string" build check)
xcodebuild analyze -workspace Reports.xcworkspace -scheme MADAPI \
  -destination 'platform=iOS Simulator,id=94952340-7629-4EBB-BBD3-6FEE068793B8' \
  -derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci
```

## Appendix B — Key files

| Concern | File |
| --- | --- |
| Central UI constants | `MADDesigner/Source/Constants.m` |
| Status text and its fixed 230×44 box | `MADDesigner/Source/MADLabelStatus.m` |
| Hand-rolled singular/plural | `MADDesigner/Source/NSDate+Extras.m` |
| Query-step titles | `MADDesigner/Source/MADQueryViewControllerTableLayout.m` |
| App storyboards | `MADDesigner/Resources/Storyboard/` |
| App xibs | `MADDesigner/Resources/Nibs/` |
| Driver storyboards | `MADAPI/Resources/`, `MADMySQL/Resources/`, `MADPostgres/Resources/`, `MADTdsClient/Resources/` |
| Settings bundle | `MADDesigner/Resources/Assets/Settings.bundle/` |
| About and licences (iOS) | `MADDesigner/Source/MADAboutTableViewController.m` |
| About and licences (Mac) | `Mac/Source/MADMacAboutWindowController.m` |
| Mac menus | `Mac/Source/MADMacAppDelegate.m` |
| Mac bundle assembly | `Mac/build.sh` |
| Mac Info.plist | `Mac/Resources/Info.plist` |
| Mac smoke test | `Mac/Tests/MADMacSmokeTest.m` |
| Licence files | `ThirdParty/Licenses/` |
| Documentation localization contract | `docs/project/LOCALIZATION.md` |
