# `mad` -- the MAD Designer Command-Line Interface

This document defines a command-line tool that opens, inspects, refreshes and exports
`.mad` documents without a user interface.

It exists because the application cannot reach the two places it needs to go. It
cannot run on a Mac as a Mac application, and it cannot run on Windows at all,
because its entire presentation layer is UIKit. A CLI needs none of that: the data
path -- open the document, run the query, fill the cache, render the report -- is
almost entirely free of UIKit already (see §4). Building the CLI first is therefore
not a detour around the platform work; it **is** the platform work, done in the order
that produces something usable at each step.

---

## 1. Scope

**In scope.** A single binary, `mad`, that can:

- open a `.mad` document and report what is in it
- print the database schema the document was built against
- print the query the document defines, as SQL
- connect to the source database, run the query and fill the row cache
- export a rendered report

**Out of scope, deliberately.** Anything that edits a document. The CLI reads and
runs documents; it does not design them. Argument parsing, the verbs and the exit
codes are the whole surface.

---

## 2. Why a CLI first

| | CLI | Mac app |
|---|---|---|
| Needs a UI toolkit | no | AppKit (rewrite) or Catalyst (rejected) |
| Needs the frameworks to be portable | **yes** | yes |
| Needs the row cache to be portable | **yes** | yes |
| Needs `.mad` to be defined | **yes** | yes |
| Delivers something you asked for | yes | yes |
| Work that is thrown away if the format changes | none | the UI |

Everything the Mac application needs in order to exist -- portable frameworks, a
defined file format, libraries built for more than one platform -- the CLI needs
first. Doing the UI port first would be the expensive way to discover the same
problems. The Mac application remains a separate decision, taken later, with the
frameworks already portable.

---

## 3. Command surface

```
mad <command> [options] <document.mad>
```

### `mad inspect <doc.mad>`

Reads the container only. No database connection, no Core Data.

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

This is the verb that proves `MAD_FORMAT.md` §7 has been implemented: it must work
on a v0 sample. It is also the verb that makes the format's hazards visible -- H2
(the un-checkpointed WAL) is reported rather than silently suffered.

### `mad schema <doc.mad>`

Prints the database schema captured in the document definition: the driver, the
tables sorted by name, and each table's fields with their display type and a `pk`
marker. It reads the snapshot stored at creation time, so it needs no credentials and
no source database. (The original plan here was to emit SQL `CREATE TABLE`; the
snapshot stores the `MADDataType` abstraction rather than each source dialect's type
names, so a faithful `CREATE TABLE` needs a per-dialect mapping that does not exist
yet. The readable listing is what the tool produces until then.)

### `mad query <doc.mad>`

Prints the SQL the document's query generates, without running it. This is the
feature the application is built around -- the user assembles tables, joins and
filters, and the software writes the SQL -- so exposing it is the natural first
non-trivial verb.

```
$ mad query London.mad --format sql
SELECT ... FROM ... WHERE ...
```

### `mad refresh <doc.mad>`

Connects to the source database, runs the query and fills the row cache. This is the
data path, and it is the verb the rest depends on.

```
$ mad refresh London.mad --credentials user:pass
refreshed 148,392 rows in 1.21 s (122,638 rows/s)
cache  ~/Library/Caches/MADDesigner/<id>/<tag>.maddb
```

Options: `--credentials`, `--no-cache` (run without persisting), `--rows N` (stop
after N rows, for smoke tests).

`--rows` exists because it is what makes the verb testable in CI against a live
server without pulling a million rows, and because the benchmark in
`MADDataTableFastBenchmarkTests` already proves the path is measurable at scale.

### `mad export <doc.mad>`

Renders the report and writes it out.

```
$ mad export London.mad --format pdf  --out London.pdf
$ mad export London.mad --format json --out -          # to the standard output
```

The formats are the export seam's (§5.3): each is a class registered with
`MADReportExporterRegistry`, and the usage text names whatever the build has.

| format | writes | where it runs |
|---|---|---|
| `pdf` | the rendered report (pages, drawn) | Apple: UIKit's `UIPrintPageRenderer`, Core Graphics; Linux says why not |
| `html` | the rendered report as one HTML file, one page box per page, printed from a browser | both platforms |
| `html-flow` | the rendered report as reflowable HTML, one table per section | both platforms |
| `text` | the rows as a fixed-width table | both platforms |
| `csv` | the rows as RFC 4180 CSV | both platforms |
| `json` | the schema and the rows as JSON (§8.3) | both platforms |
| `json-report` | `json` plus the rendered report's sections | both platforms |

`--out` is optional for the Foundation formats -- absent, or `-`, writes the standard
output -- and required for `pdf`. The Foundation formats write the same bytes on Apple
and on Linux for the same document (`Linux/README.md`; the two platforms' exports of
the London fixture compare equal by digest).

**`json-report`** (`MAD_LINUX.md` §10.1, §9 Phase E) is the same schema with the
rendered report as a `report` member: pages, each page's sections in draw order (type,
group level, visibility), each section's rows, and each line's element kind, frame and
resolved text. It is what testing and a renderer read, and it is the renderer's own
structure -- the page walk with nothing drawn -- so it cannot drift from what a PDF
shows. The frame is where the line sits **on the page** (the element's frame offset by
its section), which is what a renderer or a browser needs. The render half is compiled
on Linux now, so this format runs on both platforms.

**`html`** is the page-shaped artifact a browser prints: one CSS page box per walked
page, each element absolutely positioned at its frame, its resolved text in the
element's own font, size, weight, slant, decoration and alignment. The line-break rule
is the renderer's (`NSLineBreakByTruncatingTail` -> `white-space: pre; overflow:
hidden; text-overflow: ellipsis`). It is one UTF-8 file with an embedded style block
and no script. **`html-flow`** is the same report with the pages dropped: a `<section>`
per report section, a `<table>` per section, a `<td>` per element, page furniture
emitted once, and a generated class per distinct element style. It is a reading view;
`json` is the data contract. Neither carries colours (the store's colour columns have
no reader on either platform today) or images on Linux (the Apple path draws them from
`UIImage`; a Linux export places the empty box).

Rendering to PDF goes through `MADPrintPageRenderer`; the share-sheet wrapper
`MADActivityItemProviderPdf` is its other caller, and `MADActivityItemProviderDelegate.h`
is the protocol it talks to. All three live in the `MAD` framework rather than the
app. What PDF is not is **headless**: it is UIKit's `UIPrintPageRenderer`, which is why
it is the one format still implemented on the CLI's side (see §5.3).

### `mad write <doc.mad> --out <copy.mad>`

Writes the document out as a `.mad` -- a *copy*: the guts directory the document was
read into, archived again with the v1 header.  It does not edit the document it read,
and the CLI still does not design documents (§1); what this verb is for is the
byte-identity requirement -- the same document written on two platforms must be the
same file -- and §6.1's round-trip fixture, which needs a writer a script can run.

```
$ mad write London.portable.mad --out copy.mad --reproducible
wrote /tmp/copy.mad (16261 bytes, reproducible)
```

`--reproducible` pins what the clock and the filesystem would otherwise stamp into the
archive: a fixed modification time (2001-01-12T00:00:00Z, the instant the PDF export
pins its dates to), owner and group 0, and a sorted member walk
(`MADArchiveManager.reproducible`).  Without it an ordinary save is written, with the
members' real metadata.  The document is opened headlessly on both platforms
(`MADHeadlessDocument`), so the two sides of the comparison run the same writer, and
the same document writes the same bytes there (16,243 bytes on the London fixture,
`Linux/README.md`).

### Global options

| Option | Meaning |
|---|---|
| `--verbose` | log the data path at each stage |
| `--quiet` | suppress everything but the result |
| `--credentials user:pass` | source-database credentials; otherwise the keychain |
| `--no-keychain` | never touch the keychain |
| `--format <name>` | output format |
| `--out <path>` | output path; default stdout |
| `--deterministic` | pin the export's dates and identifier, so two runs over unchanged data are byte-identical |
| `--reproducible` | pin the `.mad` archive's inputs -- time, ownership, member order (`write`) |

### Exit codes

| Code | Meaning |
|---|---|
| 0 | success |
| 1 | usage error |
| 2 | document could not be read or is not a `.mad` |
| 3 | source database unreachable, or credentials rejected |
| 4 | the query failed on the server |
| 5 | export failed |

Distinct codes matter because the first real use of this tool is a script, and a
script needs to tell "the document is bad" from "the server is down".

---

## 4. What must exist before the CLI can be built

The data path is nearly UIKit-free already. This is measured, not estimated:

| Framework | Files importing UIKit | Needed by the CLI |
|---|---|---|
| `MADDataStructures` | 0 / 37 | yes |
| `MADFileManager` | 0 / 31 | yes |
| `MADSqlite3` | 0 / 65 | yes |
| `MADMySQL` | 0 / 42 | yes |
| `MADTds` / `MADTdsClient` | 0 / 3, 0 / 9 | yes |
| `Scrimpter` | 0 / 48 | no |
| `MADFoundation` | 4 / 66 | yes |
| `MADAPI` | 3 / 34 | partly |
| `MAD` | 28 / 464 | partly |

Four files in `MADFoundation` carry the whole UIKit dependency of the base framework:

| File | UIKit use | Disposition |
|---|---|---|
| `MADApplication.{h,m}` | a `UIApplication` wrapper | not needed by the CLI; excluded from the headless target |
| `MADURLFactory.m:32` | `UIScreen.mainScreen.scale > 1.0` | one call; return 2.0 off iOS |
| `MADOperation.m:550-563` | `beginBackgroundTaskWithName:` | one feature, guarded by `#if TARGET_OS_IPHONE` |

The author already flagged the last one (`MADOperation.m:21`): *"Wish I didn't have to
import UIApplication here, but it's really the cleanest way."* For a headless build it
is not the cleanest way, and it is the only place in the base framework where that is
true.

`MADAPI`'s three UIKit files are connection *view controllers* and are simply not part
of a headless target.

### 4.1 The refresh core must move

The one substantive piece of work is this. The refresh orchestration is **in the application
target, not in a framework**:

| File | Lines | UIKit symbols | Role |
|---|---|---|---|
| `MADDesigner/Source/MADOperationRefresh.m` | 131 | **0** | builds the SQL, runs it, writes the cache |
| `MADDesigner/Source/MADOperationRefreshReload.m` | 196 | 3 | UI-side reload |
| `MADDesigner/Source/MADRefreshOperationReload.m` | 132 | 1 | UI-side reload |

`MADOperationRefresh.m` imports only `MADAPI`, `MADFoundation` and `MAD`, and touches
no UIKit. It is the CLI's refresh verb already; it is merely in the wrong target. It
moves to the `MAD` framework, and the two `Reload` operations stay behind in the app,
which is what their names have been saying all along.

### 4.2 The headless target

A build configuration of `MADFoundation`, `MADAPI` and `MAD` that compiles without
UIKit, plus the CLI target itself. Mechanically this is `SUPPORTED_PLATFORMS` extended
with `macosx`, the per-SDK library search paths from `LIBRARIES.md` §6, and the three
file-level exclusions above.

**Done on Linux, 2026-10-16** (`MAD_LINUX.md` §9 Phase D), and done this way: the
headless target is the ten frameworks compiled by `Linux/CMakeLists.txt` against
GNUstep, and the CLI is a target beside them. The piece §4.1 assigned to the `MAD`
framework — the refresh chain — moved there, and the piece it did not anticipate —
`MADocument`, a `UIDocument`, on which `MADCLIDocument` was built — is answered by
`MADHeadlessDocument` behind `MADDocumentDataProtocol`: the same data half, with no
document lifecycle and nothing to render. `inspect`, `schema`, `query` and `refresh`
are the same sources on both platforms; `export` is PDF and stays on Apple (§5.2,
§9's staging). A macOS target is still Track 5.1's, but it now has the seam and the
document class it was missing.

---

## 5. Design

### 5.1 One binary, no frameworks in the way

`mad` links the headless frameworks directly. It does not load the application
bundle, and it must not require the Core Data model to be present in a build phase --
a constraint the test suite has already run into (see the note on
`MADTestReportFormatter` in the project memory).

### 5.2 The refresh verb reuses the measured path

`mad refresh` must call the same code the application calls:
`MADOperationRefresh` → `MADDatabase executeSQL:fieldKeys:onConnection:intoResultTable:`
→ `<MADDataTableWriting>`. It must not reimplement it. The benchmark added in
`MADDataTableFastBenchmarkTests` measures exactly this path at 200,000 rows
(1.16 s ingest, 2.5 MB transient), so a CLI that regresses it will show up as a
failed test rather than as a user complaint.

### 5.3 Export is a protocol, not a switch

`MAD_FORMAT.md` describes documents; documents contain report elements. Export should
be an extensible point, matching the project's stated goal that developers "create new
document export formats (e.g. export to PDF and JSON)". Define
`<MADReportExporting>` with one method and register implementations, so `--format json`
is a new class rather than a new branch in a switch.

**Done 2026-10-16**, in the shape §5.1's driver registry already has: `MADReportExporting.h` is the
protocol (a format's name, extension, whether it needs `--out`, whether this build can
produce it, and one export method), `MADReportExporterRegistry` is the lookup, and each
exporter registers itself in `+load` -- so which formats a process has is what it links,
and the CLI asks for one by name. `text`, `csv` and `json` are the framework's own
(`MADReportExporterText/CSV/JSON`, pure Foundation, both platforms);
`MADReportExportSource` is the one place a document is read as columns and rows, so the
formats cannot disagree about what a document is; and `MADReportExportWriter` is the one
place bytes reach a file or the standard output.

`json-report`, `html` and `html-flow` are on the seam too, built on the render half's
protocol (`MADDocumentRenderProtocol`: a document that can ready its rows, format and
hand over its formatter) and on one page walk (`MADReportPageBuilder`). **`pdf` is on
the seam as well** now: `MADReportExporterPDF` registers everywhere, its body is
Core Graphics' (Apple's), and off Apple it answers `+isAvailable NO` with the reason
(`MAD_LINUX.md` §10.2: the Linux writer is the next step). The CLI has no local arms
left; every format, `pdf` included, is looked up in the registry.

### 5.4 Credentials

The CLI must never prompt. It takes `--credentials`, or reads the keychain the
application wrote, or fails with exit code 3. `--no-keychain` exists so that a test
run cannot read or write a developer's real credentials.

### 5.5 Running it: the Linux image

`Linux/build.sh --runtime` builds `mad-cli:latest`, a runtime-only layer with the
CLI on PATH, the shared libraries it links, and the Sqlite3 sample database — no
compiler, sources or test binaries (283 MB on disk; `Linux/README.md` has the
contents). A document is mounted, not stored:

	docker run --rm -v "$PWD/CLI/Fixtures":/docs:ro mad-cli:latest \
		mad inspect /docs/London.portable.mad
	docker run --rm -v "$PWD/CLI/Fixtures":/docs:ro mad-cli:latest \
		mad refresh /docs/MySQL.employees.mad --credentials root:root --rows 50

A Sqlite3 document resolves its stored database name against the per-user
Application Support directory, which is
`/root/GNUstep/Library/ApplicationSupport` in the image; `chinook.sqlite3` is
there, so the London and Music fixtures refresh without setup. The row cache
lives under the same home and is per-container; every export refreshes the
document itself, so a cache does not need to persist between runs.
`mad-cli` is not published, and there is no CI (the user's decisions,
2026-10-17).

`Linux/build.sh --verify` rebuilds the image and runs the repeatable check: all
six verbs on the fixtures, every format's pinned digest, `pdf`'s refusal, the
writer's bytes and the exit codes (`Linux/verify-cli.sh`; `--live` adds the two
live databases).

---

## 6. Testing

The format and the CLI are pinned by **round-trip fixtures**, not by prose:

1. **Container fidelity.** Unpack `Music.mad` and `London.mad`, repack them, and
   assert the member list and each member's bytes are unchanged. This pins
   `MAD_FORMAT.md` §2 and catches H4 (hidden files) immediately.  **Landed
   2026-10-16** as `Linux/Tests/MADArchiveManagerTests.m`'s round trip -- `mad write`
   writes the container on both platforms now -- with the reproducible mode's bytes
   pinned against the Mac's.
2. **v0 readability.** `mad inspect` on both shipping samples must succeed and report
   the values in `MAD_FORMAT.md` §2 -- including the un-checkpointed WAL, which is the
   assertion that proves the WAL hazard is being reported rather than ignored.
3. **Cache-free round trip.** Open a document, refresh, export, close, reopen. The
   second open must not need the network. This pins §5 of the format document -- that
   the cache is derived and external.
4. **Scale.** `mad refresh --rows 200000` against a local SQLite source, asserted
   against the same ceilings the benchmark uses, so the CLI cannot quietly become the
   slow path.
5. **Exit codes.** One test per row of the table in §3, driven by deliberately broken
   inputs.

Fixtures live beside the samples they test. Tests that need a live MySQL or SQL Server
**skip** when one is not reachable, following the existing convention in
`MADMySQLLiveTests.m` and `MADTdsClientLiveTests.m`.

---

## 7. Phasing

| Phase | Deliverable | Depends on |
|---|---|---|
| 0 | `MAD_FORMAT.md`, `MAD_CLI.md`, `LIBRARIES.md` | -- |
| 1 | Library build system, sqlite flags pinned | Phase 0 |
| 2 | Per-SDK search paths; macOS slices wired | Phase 1 |
| 3 | Headless subset; `MADOperationRefresh` moved to `MAD` | Phase 2 |
| 4 | `mad` target: `inspect`, `schema`, `query` | Phase 3 |
| 5 | `mad refresh` | Phase 4 |
| 6 | `mad export` (PDF first) | Phase 5 |
| 7 | Round-trip fixtures wired into the test matrix | Phase 6 |

Phases 4-6 are ordered by dependency, not by difficulty: `inspect` needs only the
container, `query` needs the document model, and `refresh` needs a database
connection.

---

## 8. Open questions

1. **Does the CLI ship, or is it a developer tool?** That decides whether it needs
   code signing, notarisation and an installer, and whether `--credentials` may
   accept a plaintext argument or must take a file descriptor.
2. **Should `mad` accept the row cache from an external file?** A packed `.mad`
   (§8.3 of the format document) would make offline export possible. Nothing needs it
   yet.
3. **What is the JSON export shape? — answered 2026-10-16: both, the report half as
   its own format.** `--format json` is the data contract, `--format json-report`
   adds the rendered report as an extra member. The shape is in
   `MADReportExporterJSON.h`, implemented by `MADReportExporterJSON` (the data half,
   both platforms) and `MADReportExporterJSONReport` (the report member, where the
   render half is). Its columns are the query's own, in the order the SELECT
   list defines -- the column alias, sorted (`BUGS.md`, the SELECT-list entry) --
   and a value keeps its JSON type: numbers are numbers, NULL is `null`, dates are
   ISO 8601 and binary is base64.
