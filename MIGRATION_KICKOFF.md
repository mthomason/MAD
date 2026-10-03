# Store Migration — Kickoff

A handoff brief for whoever takes on the portable-store migration. Read `MAD_STORE_MIGRATION.md`
first — it is the plan and the source of truth; this file is the assignment.

## The task

Move the `.mad` document's store off Core Data and onto a SQLite schema we own. This is the
project's most important remaining work: it removes the last Apple dependency (hazard H3 in
`MAD_FORMAT.md`), which is what makes a document openable on a non-Apple platform.

## Where you are

Objective-C, iOS 15+, repo at the repo root, main branch `master`. Large codebase — a main app
plus ~13 frameworks. Read, in order: `MAD_STORE_MIGRATION.md`, `MAD_FORMAT.md`, `CLAUDE.md`
(symlinked to `AGENTS.md`), then `ROADMAP.md` / `TASKS.md` / `BUGS.md` (maintain these; do not
start work from them).

## What is being migrated

A `.mad` file is a bzip2-tar archive (now with a `MADFILE\0` header — v1). Inside it,
`StoreContent/analyitics` is a Core Data SQLite store holding the document **definition**: three
things — the database **schema** (imported from the source DB at creation, reloadable), the
**query** (built in the Query tab), and the report **layout** (built in the Designer tab). The
row data is *not* here; it lives in the `.maddb` cache. Replace that Core Data store with a
SQLite schema we own, so a reader on another platform opens a document without Core Data.

## Findings that shape the work (`MAD_STORE_MIGRATION.md` §3)

- It is a **simple database**: 32 `Rptq`-prefixed entities keyed by an `identifier`
  (`Integer 64`) every entity carries.
- **No Core Data faulting is needed.** The definition is under 80 KB; the fetch patterns are
  fetch-by-identifier and fetch-the-root. Load per part (schema / query / layout) on demand.
- **Undo is not a blocker.** It is manual high-level undo in `MADDesignerLayout`
  (`registerUndoWithTarget:handler:` on an `NSUndoManager`), needing only fetch-by-id and
  set-a-property — not Core Data's change tracking.
- The only Core Data features to replace are `NSFetchedResultsController` (two files) and
  relationship traversal; both have plain equivalents.
- A clean `MADModel*` domain layer already wraps the `Rptq` entities; it is the seam to keep.

## The assignment — Phase A first, only

Start with **Phase A** of `MAD_STORE_MIGRATION.md`. Do **not** begin Phases C/D until Phases A
and B have been reviewed.

1. Define the portable SQLite schema: one table per entity, keyed by `identifier`; foreign keys
   for relationships; an explicit `position` column on the four ordered to-many relationships
   (`RptqDatabaseSchemaTable.hasFields`, `RptqDatabaseSchemaTable.inQueryTable`,
   `RptqDocumentSection.hasRows`, `RptqDocumentSectionRows.hasObjects`); a join table for the
   one many-to-many (`inQuery`); portable scalars for the four transformable attributes
   (`UIColor` → RGBA, `NSLocale` → identifier string, `UIImage` → PNG bytes).
2. Write a reader/writer pair that round-trips a `RptqDocument` graph headlessly: build a graph
   in memory, write it, read it back, assert equality — including fetch-by-identifier and
   fetch-by-part.
3. Write unit tests for everything. Add them to the existing files under `MAD/MADTests`; a new
   test file needs a hand-edited `project.pbxproj` entry.

The current model is `MADDesigner/Resources/MADFileDefinition/MAD.xcdatamodeld/MAD 3.xcdatamodel/contents`
(32 entities). The generated `Rptq` headers are in `MAD/Source/rptq/autogen/` — keep them as a
fixed, hand-maintained contract (stop regenerating) and write the CRUD yourself.

## Non-negotiables

- Success = everything keeps working **except iCloud**. Local open/save, query/design/viewer,
  refresh/export, and the `.maddb`/`.mdcache`/`.madac` caches all behave as today. Stripping
  iCloud is Phase D, last.
- Do not delete anything under `Compressor/library`.
- The two samples — `MADDesigner/Resources/Assets/Samples.xcassets/Reports/London.dataset/London.mad`
  and `Music.dataset/Music.mad` — stay openable throughout; they are the Phase B fixtures.
- Tabs for indentation; limited comments.
- Mark deliberately-unused code with the clang attribute at the declaration
  (`__attribute__((unused))`, `__unused`, `NS_UNAVAILABLE`).
- No `+[NSString stringWithFormat:]` in tight loops; match the `initWithFormat:` /
  `appendFormat:` house style.

## Build and test

```
xcodebuild test -workspace Reports.xcworkspace -scheme MAD \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -derivedDataPath ~/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci
```

Substitute `MADSqlite3`, `MADFoundation`, etc. for the other framework schemes. If
`iPhone 17 Pro` does not resolve, list a booted simulator with `xcrun simctl list devices`.
The headless `mad` CLI — `CLI/build.sh --run <command> <document.mad>` — proves the document
path without the app: `inspect`, `schema`, `query`, `refresh`, `export`.

## Report back

What you built, the tests you wrote, and a clean `xcodebuild test` result. Work on a branch; do
not push to `master` unless asked. End commit messages with:

```
Co-Authored-By: Claude Code <noreply@anthropic.com>
```
