# BUGS.md

A running triage list of defects, quirks, and suspicious behavior surfaced by the
unit-testing effort. Each entry is locked down by a characterization test so the
behavior is documented even before it is fixed.

Status key:

- **Confirmed** — a test proves the behavior is wrong; treat as a defect.
- **Investigate** — suspicious but needs a human judgment call (may be an
  intentional hack or an old workaround).
- **Quirk** — odd implementation detail that happens to produce correct output.
- **Fixed** — found during testing and already corrected.

---

## MADAPI

### `MADDatabaseDataBinding`: `nil` vs `[NSNull null]` handled inconsistently
- **Status:** Fixed
- **Where:** `MADAPI/Source/MADDatabaseDataBinding.m:153`
- **Behavior:** Setting a `nil` value stores `[NSNull null]`, but setting an
  explicit `[NSNull null]` value leaves the stored value as `nil`. The two
  "no value" inputs should be treated identically.
- **Why it matters:** The asymmetry is real but was **harmless**, and the
  earlier "bad report data" claim was wrong. The only production reader of
  `.value` is `MADDatabaseSqlite3.m -bindStatement:withBindings:`, and both
  inputs bind SQL NULL there: an explicit `[NSNull null]` is caught by the
  `isEqual:` test at the top, and a `nil` falls through to `case MADDataTypeNull:`
  (`MADDatabaseSqlite3.m:373`) → `sqlite3_bind_null`. No caller observes the
  difference. Pinned by `MADDatabaseDataBindingTests.m:58-60`.
- **Now:** the nil test and the `[NSNull null]` test share one branch, so both
  store `[NSNull null]` with `datatype == MADDataTypeNull`.
- **Test:** `testInitWithNullValueStoresNSNull` (renamed from
  `testInitWithNullValueLeavesValueNil`).

### `NSStringFromMADQueryType`: "TypeCache" missing for `MADQueryTypeCacheIndexDropParameters`
- **Status:** Fixed
- **Where:** `MADAPI/Source/MADQueryType.h:64`
- **Behavior:** `NSStringFromMADQueryType(MADQueryTypeCacheIndexDropParameters)`
  returns `@"MADQueryIndexDropParameters"` — the `TypeCache` segment is dropped.
- **Why it matters:** Any UI that surfaces the query-type name (logs, debug
  views, future AI-generated-query display) will show the wrong string.
- **Now:** it returns `@"MADQueryTypeCacheIndexDropParameters"`, matching the
  sibling `...IndexCreateParameters` case directly above it. Pinned by
  `testNSStringFromMADQueryTypeCacheIndexDropParameters` (renamed from
  `testNSStringFromMADQueryTypeCacheIndexDropParametersDefect`).

### `NSStringFromMADQueryType`: `MADQueryTypeSampleDataTableRange` unmapped
- **Status:** Fixed
- **Where:** `MADAPI/Source/MADQueryType.h:72`
- **Behavior:** `MADQueryTypeSampleDataTableRange` (raw value 28) falls through
  the switch and returns `@"MADQueryTypeUnknown"`.
- **Why it matters:** A whole query type is unnamed; anything keyed off the name
  (persistence, UI) will mislabel it.
- **Now:** it has its own case and returns `@"MADQueryTypeSampleDataTableRange"`.
  Pinned by `testNSStringFromMADQueryTypeSampleDataTableRange` (renamed from
  `testNSStringFromMADQueryTypeSampleDataTableRangeFallsThrough`).

### `MADConnectionViewController` / `MADConnectionSQLGenericViewController` `-databaseConnection` throws an NSString
- **Status:** Confirmed (left as is — no changed functionality)
- **Where:** `MADAPI/Source/MADConnectionViewController.m:279`,
  `MADAPI/Source/MADConnectionSQLGenericViewController.m:353`
- **Behavior:** The override point is implemented as `@throw NSInternalInconsistencyException;`,
  which throws the *name constant* — an `NSString` — rather than an `NSException`.
  Every "subclass me" method on `MADDatabase` builds a real
  `[NSException exceptionWithName:NSInternalInconsistencyException reason:... userInfo:nil]`
  from the same constant; these two do not.
- **Why it matters:** A `@catch (NSException *e)` — the only shape anything in this
  codebase writes — does not catch it; the throw surfaces as an unknown exception
  object. Only the abstract-method misuse path hits it, so the blast radius is small,
  but the inconsistency is real.
- **Test:** `MADConnectionViewControllerTests testDatabaseConnectionThrowsOnBaseClass`
  and `testDatabaseConnectionThrowsOnSQLGenericClass` catch `id` and assert the thrown
  object is the name constant.

### `MADDatabase` is NSCoding-only, so secure archiving rejects it
- **Status:** Quirk (latent — nothing archives a `MADDatabase`)
- **Where:** `MADAPI/Source/MADDatabase.h:32`, `MADAPI/Source/MADDatabase.m:50-63`
- **Behavior:** The class declares `NSCoding`, not `NSSecureCoding`, and does not
  implement `+supportsSecureCoding`. `+[NSKeyedArchiver archivedDataWithRootObject:requiringSecureCoding:YES
  error:]` therefore returns `nil` with an error. Its `-initWithCoder:` also uses the
  non-secure `-decodeObjectForKey:`, so even the modern class-matching decode APIs
  (`-decodeObjectOfClass:forKey:`) refuse it. Round-tripping works only through the
  classic path (`[[NSKeyedArchiver alloc] initRequiringSecureCoding:NO]` and an
  unarchiver with `requiresSecureCoding = NO`, which is *not* the default for
  `-initForReadingFromData:error:`).
- **Why it matters:** If a caller ever reaches for the secure APIs — the enforced
  default in recent SDKs — archiving fails at runtime with a nil result. Nothing in
  the app or frameworks archives a `MADDatabase` today (checked: the only
  `NSKeyedArchiver` users archive caches and query-visualization payloads), so this
  is latent.
- **Test:** `MADDatabaseTests testInsecureNSCodingRoundTrip` and
  `testSecureArchivingIsUnsupported`.

### `MADDatabaseConnection` subclasses do not survive the base class's `NSCopying` / `NSCoding`
- **Status:** Quirk (latent — nothing archives a connection; subclasses override `-copyWithZone:`)
- **Where:** `MADAPI/Source/MADDatabaseConnection.m:34-62`
- **Behavior:** `-initWithCoder:` / `-encodeWithCoder:` / `-copyWithZone:` read and write
  the base class's *own* ivars. A concrete subclass cannot see those ivars (they are
  synthesized in the base `.m`, not declared in the header) and therefore shadows each
  one with its own storage — `MADDatabaseConnectionMySql` does exactly this with
  `@synthesize databaseType = _databaseType;`. The base's accessors are never consulted,
  so a copied or archived connection reads back with `MADDatabaseTypeUnknown`, a nil
  connection string, `requiresCredentials == NO` and a nil identifier.
  `MADDatabaseConnectionMySql` works around the copy half by overriding
  `-copyWithZone:` with a real initializer; nothing overrides the coding half.
- **Why it matters:** Any future persistence of a connection object — or of a
  `MADDatabase` that encodes its `databaseConnection` — silently loses the connection's
  state. Latent today: no archive of either type exists in the app or frameworks.
- **Test:** `MADDatabaseConnectionTests testSubclassCopyDoesNotCarrySubclassState` and
  `testSubclassNSCodingDoesNotCarrySubclassState`, which pin the lossy result so a fix
  will be visible.

---

## MAD (framework)

### `objectsForEntity:` missed every subentity row
- **Status:** Fixed
- **Where:** `MAD/Source/rptq/store/MADStoreGraph.m` (`-objectsForEntity:`) and
  the registry lookup in `MAD/Source/rptq/store/RptqStoreContext.m`
- **Behavior:** Rows are keyed in the graph by their concrete kind
  (`RptqDocumentElementLabel`), and the singular lookup had a table fallback for
  exactly that while the plural lookup returned only rows keyed under the exact
  requested name.  `objectsForEntity:@"RptqDocumentElement"` therefore returned
  nothing, and four live sites suffered: the element `awakeFromInsert` dropIndex
  scan found no rows (every new element got dropIndex 1, so z-order collided),
  `nextDropIndexForSection:` always answered 0, and the two
  `delete*RelatedToTable:` cleanups never deleted anything.  The converter test
  that should have caught it shared the blind spot -- its reference fetch set
  `includesSubentities = NO`.
- **Now:** both lookups apply the table fallback when the requested entity owns
  its table, so a base-entity query returns rows of every kind that shares the
  table while a query for one kind stays exact.  The converter test's reference
  fetch includes subentities for table-owning entities, its total counts each
  row once under its own kind, and
  `testBaseEntityQueryReturnsRowsOfMixedKinds` pins the mixed-kind query with a
  count, so a lookup that silently returned nothing cannot pass.
- **Found during the store migration.**

### Opening a large report and refreshing spikes memory to ~8 GB and never renders a page
- **Status:** Fixed -- root cause found 2026-10-03, fixed 2026-10-03
- **Where:** the app's open+refresh on the user's custom MySQL report: the
  `employees` database, `departments` LEFT OUTER JOIN `dept_emp` -- about 331,603
  detail rows, i.e. thousands of pages at ~45 rows a page.  Two elements.  The
  document is a legacy v0 `.mad` (Core Data `analyitics` store, converts on open)
  and was found in the iPhone 17 simulator's app group container as `Document.mad`.
  London (five pages) and Music (3,503 rows / 77 pages) both work, so the defect
  only bites at this report's scale.
- **Behavior:** on the user's device, opening this report and refreshing makes the
  print-page render do "all kinds of work": memory climbs to ~8 GB and the first
  page never renders.  "It doesn't get to the rendering -- the processing never
  finishes."  The symptom reads as "drawing the whole report instead of the visible
  page", but the two-pass design itself is intact at moderate scale: the CLI export
  of Music runs the same `MADReportFormatter` / `MADPrintPageRenderer` and finishes
  77 pages in ~4 s at ~17 MB RSS.  What Music cannot exercise is the per-row and
  per-page accumulation over 331k rows and ~7,000 pages -- the formatter's own
  comment (`MADReportFormatter.m:454-459`) warns that even an "8k page report"
  spikes 100 MB without the per-row autoreleasepool, and this report is an order of
  magnitude beyond anything the samples reach.
- **Reproduction:** the CLI now drives the user's actual document headlessly against
  the live MySQL server: `CLI/build.sh --run refresh --credentials root:root
  <copy-of-Document.mad>`, with `--rows N` to cap the query.  The CLI runs the same
  refresh chain as the app (the `MADOperationRefresh*` sources are compiled in from
  `MADDesigner`), so a headless failure here is the app's failure.
- **What has been ruled out** (checked against `master`, before assigning):
  - `MADReportFormatter.m`, `MADViewerController.m`, `MADRefreshOperationReload.m`,
    `MADReportPageView.m` are zero-diff; `MADPrintPageRenderer.m` is a mechanical
    4-line keying change; `MADArrayCaching.m` and `MADDataTableFast.m` still carry
    the hot paths unchanged.
  - Store lookups are not O(data): `objectForEntity:identifier:` is a registry
    lookup (`RptqStoreContext.m:129-166`) and every `objectsForEntity:` call site
    in the render/designer path is bounded by document-definition counts, not data
    rows.
  - Legacy conversion-on-open is one-time (`MADocument.m:515-544`), not per open.
- **Root cause -- found 2026-10-03, fix pending.**  Every attribute read on a
  store-backed object allocates.  `-[RptqObject valueForUndefinedKey:]`
  (`MAD/Source/rptq/store/RptqObject.m:64-93`) resolves each key with
  `MADStoreAttributeNamed` (a linear scan over `entity.allAttributes`) and then
  `anyRelationshipNamed:` (a linear scan over `entity.allRelationships`), and
  **both accessors build a fresh array on every call** --
  `-[MADStoreEntity allAttributes]` /
  `-[MADStoreEntity allRelationships]`
  (`MAD/Source/rptq/store/MADStoreSchema.m:151-161`) flatten the inheritance
  chain with `arrayByAddingObjectsFromArray:` on each invocation.  Under Core
  Data the same reads were direct ivar/accessor hits; the store-backed property
  layer turns each one into an entity lookup plus one or two array builds plus
  per-name `isEqualToString:` scans.  The render path reads element geometry and
  text styles per element per row per page, and the format path reads the same
  per row -- so at this report's scale (331k rows x 9,475 pages) that is tens of
  millions of reads, each allocating.  Reproduced headlessly on the user's own
  document: a 4 s `sample` of an export showed 2,343 of 2,351 samples inside
  `drawPageAtIndex:` -> `drawSection:` -> `RptqGetObject` ->
  `valueForUndefinedKey:` -> `MADStoreAttributeNamed` ->
  `-[MADStoreEntity allAttributes]` -> `arrayByAddingObjectsFromArray:`, with
  the bulk of the footprint in **Malloc Small**.  (A first measurement's
  absolute peak of ~5.8 GB is not trusted -- overlapping orphaned exports were
  running concurrently -- and the flat ~17 MB RSS in the A/B below is the
  honest single-process number; the stacks, not the absolute figure, are the
  evidence.)  The CLI's render loop also has no per-page autoreleasepool
  (`CLI/Source/MADCLIDocument.m:260-263`), so the garbage the lookups produce
  accumulates across all 9,475 pages until the loop ends.  On the device the
  same curve hits the memory limit (~8 GB) and the first page never renders.
- **Fix shape.**  Memoize the schema lookups: cache the flattened
  `allAttributes` / `allRelationships` per entity (compute-once after the schema
  is built), and replace the linear `MADStoreAttributeNamed` /
  `anyRelationshipNamed:` scans in `RptqObject` with per-entity cached
  name->descriptor dictionaries, so an attribute read is one dictionary hit and
  allocates nothing.  Wrap the CLI's per-page render body in `@autoreleasepool`
  so any residual garbage is bounded per page.  Behaviour must not change;
  verify with the existing suites plus the headless export below, whose peak RSS
  must come down from ~5.8 GB to a few hundred MB.
- **Now:** the flattened arrays are memoized per entity and warmed once at the
  end of schema construction (the descriptors are immutable after that), and the
  name lookups in `RptqObject`'s property layer are per-entity cached
  dictionaries -- an attribute read is one dictionary hit and allocates
  nothing.  First-match ordering, the attribute-before-relationship precedence,
  and the unknown-key raise through `NSObject` are preserved and pinned by
  `testSchemaFlattenedArraysAreMemoizedAndStable` and
  `testRptqObjectKVCSemanticsAreUnchanged`.  The CLI's per-page render body is
  wrapped in `@autoreleasepool`.
- **Measured (A/B, same document, same output 9,196,432 bytes / 9,475 pages):**
  master baseline 32 s / 17 MB RSS; the branch before the fix 89 s / 17 MB RSS;
  the branch with the fix 63 s / 17 MB RSS.  The RSS is flat in all three on
  this machine (the CLI's own pooling bounds it; the earlier 5.8 GB sample was
  not reproduced here), and the time improvement is real but leaves a ~2x gap
  to master: the remaining cost is the store layer's constant-factor read path
  (sampled: `valueForUndefinedKey:` -> two dictionary hits, the registry fault,
  and the selector-name string), all O(1) and allocation-free now, which the
  fix shape deliberately does not go beyond.  Music stays the control (77 pages
  / ~4-6 s / ~17 MB) and London stays 5 pages.
- **The rule this violated:** attribute reads on `RptqObject` must be
  allocation-free; the property layer is the render and format hot path.
- **Reproduction (the regression guard):** `CLI/build.sh --run export
  --credentials root:root --out /tmp/employees.pdf <copy-of-Document.mad>` --
  9,475 pages / 9,196,432 bytes.  Needs the MySQL server reachable; the
  document lives in the iPhone 17 simulator's app group container as
  `Document.mad` (MySQL, `employees`, `departments` LEFT OUTER JOIN
  `dept_emp`, two elements).

### Page draws run one SQLite transaction per cell, so opening a large report pegs the CPU
- **Status:** Fixed
- **Now:** `MADDataTableFast` caches the prepared select per column
  (`-selectStatementForColumn:database:error:`, keyed by column name; the SQL
  is `WHERE rowid = ?` and each call binds, steps, resets, and clears
  bindings, so one statement serves every row).  A `SQLITE_SCHEMA` step
  re-prepares once and retries -- the prepare-per-call code never saw a stale
  statement, and the cached one must not either -- and the cache is finalized
  when the connection is reopened, a column is added, or the table is
  deallocated.  `-beginReadTransaction` / `-commitReadTransaction` on the
  select connection (never the writer) wrap
  `MADPrintPageRenderer -drawPageAtIndex:withContext:inPageRect:` so a page's
  cell reads share one transaction.  Measured: the app's open-time first-page
  draw went from ~25 s at 100% CPU to ~2 s of CPU for launch, open, and the
  draw together (process idle immediately after; verified in the iPhone 17
  simulator via the launch hooks).  The CLI export is 58 s -> 52 s
  (9,196,432 bytes / 9,475 pages unchanged); a 25 s sample of the export's
  draw loop shows zero `sqlite3BtreeBeginTrans` and 255 of 10,151 samples in
  the whole `dataForRow:column:` chain -- the remaining CLI time is the
  store-context KVC draw path and Core Text glyph drawing, not this defect.
  Four new `MADDataTableRegressionTests` pin repeated-read identity, fresh
  values after an intervening write (same table and via a sibling table on
  the same cache file), and reads after a table rebuild.
- **Where:** `MADSqlite3/Source/MADDataTableFast.m:981`
  (`-dataForRow:column:error:` prepares a fresh statement and steps it exactly
  once, in autocommit, so every cell read runs an implicit
  begin/journal-stat/lock/commit).  The caller is per cell:
  `MAD/Source/MADPrintPageElement.m:80-84`
  (`MADPrintPageElementTextDynamic -initWithDefinition:` asks the datasource
  for the row value every time the element is instantiated -- dynamic,
  data-bound elements have no value baked into the layout cache), reached
  from `MADReportPageView -drawRect:` on the main thread.
- **Behavior:** opening the user's large report in the app pegs the CPU at
  100% for ~25 s drawing a single page at ~900 MB RSS, before any refresh --
  reproduced in the simulator and sampled: all 2,908 samples inside one
  `drawRect:` -> `drawPageAtIndex:` -> `drawSection:` ->
  `newDocumentObject:` -> `dataForRow:column:error:` -> `sqlite3_step` ->
  `sqlite3BtreeBeginTrans` -> `lockBtree` -> per-cell journal `stat()` /
  `fcntl()` locks.  The viewer redraws the last page after every refresh, so
  the same storm is the "everything freezes when you hit refresh" symptom, and
  it is why a five-page report looks fine while this one does not: the cost
  scales with cells drawn, not with anything the small samples exercise.
- **Pre-existing or new?** The call pattern is zero-diff against `master`
  (the renderer and `MADDataTableFast` are unchanged), so master's app pays
  the same per-cell transaction; this report's scale (9,475 pages, two
  dynamic fields, 331k rows) was never opened in the old app, so there is no
  "worked before" measurement at this size.  Either way it is a live defect
  now: the design's purpose is fast page scanning from the hidden Sqlite3
  cache, and one transaction per cell defeats it.
- **Fix shape.**  Make the per-cell read cheap in the two places the storm
  lives, changing no results: (1) cache the prepared select statement per
  column in `MADDataTableFast` (prepare once; bind, step, reset per call),
  and (2) wrap each page draw in one read transaction on the select
  connection (begin before the draw, commit after) so the per-cell implicit
  transactions collapse into one.  The CLI export exercises the same
  `drawPageAtIndex:` path, so its wall time (59 s after the lookup fix) is
  the regression guard and should drop substantially.
- **The rule this violated:** the render path must not run one SQLite
  transaction per cell; page draws are the app's hottest loop.
- **Reproduction:** install the DEBUG app in the iPhone 17 simulator, launch
  with `-UITestOpenSample Document -UITestSelectTab Viewer`, and watch the
  main thread draw the last page at 100% CPU; or `sample` the app process
  during the peg (the stacks above are from exactly that).

### `insertObjectForEntity:` mints identifiers per entity, not per table
- **Status:** Fixed
- **Now:** `RptqStoreContext -insertObjectForEntity:identifier:` mints over
  the table's owner entity -- `descriptor.parentName` when the requested
  entity is a subentity sharing a parent's table, the requested entity itself
  otherwise -- whose `objectsForEntity:` table fallback returns every kind in
  the table, so a new `RptqDocumentElementLabel` is numbered past the last
  row of any element kind.  Two regression tests in
  `RptqStoreContextTests`: a label holding identifier 5 followed by a chart
  inserting with 0 returns a chart identifier greater than 5 (and not equal
  to 5), and an owner-entity insert (`RptqDatabaseSchemaField`) still mints
  past its own table's maximum.  Both suites green.
- **Where:** `MAD/Source/rptq/store/RptqStoreContext.m:183-188` -- when the
  identifier is 0, the new identifier is max-over-the-requested-entity plus
  one.  The nine `RptqDocumentElement*` kinds share one table with
  `identifier INTEGER PRIMARY KEY` (`MADStoreSchema.m:841`), and the
  factories insert with the concrete kind name, so a new
  `RptqDocumentElementLabel` is numbered past the last *label* only.  If any
  other kind already holds the next integer (the legacy store was one table
  for the whole hierarchy, so converted identifiers interleave kinds), the
  minted identifier collides with a live row -- and the table-wide primary
  key turns the collision into a failed write or a replaced row.
- **Why it changed:** under Core Data `identifier` was an indexed attribute
  with per-class fetch semantics (duplicates across kinds were legal and
  harmless); the portable store made it the table key, and the milestone-(a)
  minting (`RptqDataHelper nextIdentifierForClass:`'s replacement) did not
  pick up the new constraint.
- **Fix shape.**  Mint over the table owner: when the requested entity does
  not own its table, compute the maximum over
  `objectsForEntity:` of the *owner* entity (whose table fallback returns
  every kind that shares the table), then add one.  Add a regression test: a
  context holding a text field with identifier 5 inserts a new label with
  identifier 0 and the label's identifier must be greater than 5.
- **The rule this violated:** identifiers are table keys in the portable
  store; allocation must be per table, not per entity.

### The milestone-(a) model rewrites dropped the schema sort orders
- **Status:** Fixed
- **Now:** `MADModelTable -update` sorts the schema fields by `name`
  ascending and `MADModelDatabase -updateTables` sorts the schema tables by
  `name` ascending before building the model objects -- the same
  `NSSortDescriptor initWithKey:ascending:` the pre-migration fetches used.
  `MADDocumentTests testModelDatabaseSortsTablesAndFieldsByName` inserts
  tables and fields out of name order and pins the projected orders (green).
- **Where:** `MAD/Source/MADModelTable.m` (`-update`) and
  `MAD/Source/MADModelDatabase.m` (`-updateTables`)
- **Behavior:** both projection fetches sorted by `name` ascending before the
  migration; the store rewrites keep insertion order.  The model's field and
  table orderings feed the sample-data tables and the SQL/schema display
  paths, so the visible order can change even though nothing else did.
- **Fix shape.**  Restore the sorts -- one comparator each -- before building
  the model objects.

### A NULL read from a source database printed as the text `<null>`, or as the epoch
- **Status:** Fixed
- **Where:** the producer is
  `MAD/Source/rptq/RptqDocumentElement+Extras.m:973`
  (`-formattedString:forValue:`). The four callers that tried to undo it are
  `MAD/Source/MADDocumentObjectDataReference.m:185`, `:270` and
  `MAD/Source/MADDocumentObjectDataReferenceBarcode.m:59`, `:66`.
- **Behavior:** the method opened with `if (!value) return @"";`, which catches `nil`
  but not `[NSNull null]` — `NSNull` is an object, and truthy. A NULL read from a
  source database arrives as `NSNull` (see the `MADQueryCacheSelectGroupKeys` entry
  below for why that representation is deliberate), so it fell through to the branches
  below. Every text path there ends in `-initWithFormat:@"%@", value`, and
  `[NSNull description]` is `"<null>"` — angle brackets. The date branches are worse:
  `NSNull` is not `NSData`, not `NSString` and not `NSNumber`, so the time interval
  defaulted to 0 and a NULL date printed as the epoch, 1970-01-01.
- **Why it matters:** a NULL in the data was a visible `<null>` on the printed report,
  and a NULL date was a plausible-looking wrong date. The intended guard never worked:
  the four callers compared the result against `MTNullIdentifier`, which was declared
  `@"(null)"` — *parentheses*, the way a nil pointer formats, not the way `NSNull`
  does. The two strings differ, so `-isEqualToString:` was always false. The constant
  was dead from the day it was written, and the only value that could ever have matched
  it is real text in the data spelling `(null)`, which would then have been blanked.
- **Now:** the guard covers both cases — `if (!value || [value isKindOfClass:[NSNull
  class]])` — so a NULL is empty where it enters the formatter. The four comparisons
  and the constant go with it: `MTNullIdentifier` is deleted from
  `MAD/Source/rptq/autogen/RptqDocumentElement.h:24` and `:15` of the `.m`. They were
  removed rather than left in place because they are not merely unreachable after this
  change — they were already unreachable before it, and leaving a comparison against a
  string nothing produces invites the next reader to assume the round trip is live.
- **Note:** `MAD/Source/rptq/autogen/` holds Xcode-generated Core Data subclass code and
  is hand-edited here; nothing in the build regenerates it, so the deletion stands.
- **Test:** `MADTests MADDocumentTests testFormattedStringRendersNullAsEmpty`. It
  asserts `NSNull` formats empty for a string, an integer, a date and a datetime, that
  `nil` still does, and that a real value still formats. Run against the old guard it
  fails four ways, and the failure text is the evidence for the paragraph above:
  `("<null>") is not equal to ("")` for the string and integer cases, and
  `("12/31/69, 7:00 PM") is not equal to ("")` for the datetime — the epoch in US
  Eastern, which is 1970-01-01 UTC.

### `MADSectionLayout` computes no element height, so a report piles onto its first pages
- **Status:** Fixed -- found 2026-10-03, reproduced from the shipped samples
- **Where:** `MAD/Source/MADSectionLayout.m:63-65` (the stub). Consumed by
  `MAD/Source/MADReportFormatter.m:517`, `:522`, `:580-594`, `:626`.
- **Behavior:** `-initWithObject:managedObjectContext:` used to set `_displayHeight`
  to the **maximum calculated height of the section's elements** -- for each element,
  `rect.origin.y + rect.size.height + margin.top + margin.bottom + padding.top +
  padding.bottom + border.width.top + border.width.bottom`, computed by the Core Data
  projection `RptqDocumentElement +fetchRequestSectionHeight:`. Note what the old code
  did *not* do: `_displayHeight` started at zero and the section's own declared
  `height` never entered it. The projection went with the store migration and was
  replaced by `_displayHeight = _visibility ? _height : 0.0000f` -- the declared
  height, a value the old code never used for this purpose. `displayHeight` is what
  `MADReportFormatter` adds to `cumulativePageHeight` to place the next section and
  decide page breaks, so sections now advance by the wrong amount and overlap.
- **Why it matters:** Every rendered report is mispaginated, and a section whose
  declared height is zero collapses entirely onto the page it starts on. Measured on
  the London sample through the CLI: before the migration 5 pages / 43,177 bytes /
  638 text strings; after, 3 pages / 40,547 bytes / 636. The two strings are the page
  header, which now repeats on fewer pages; everything else is intact and piled onto
  three pages instead of five. The user-visible report is "everything prints on the
  first page".
- **Reproduction:** `CLI/build.sh --run export --out /tmp/london.pdf
  MADDesigner/Resources/Assets/Samples.xcassets/Reports/London.dataset/London.mad`
  -- 5 pages before the migration, 3 after. The CLI goes through the same
  `MADReportFormatter` the app does, so it is a headless check for the fix.
- **Now:** the computation is restored against the store in the same initialiser: the
  section resolves through `objectForEntity:@"RptqDocumentSection" identifier:`, its
  elements are walked over `hasRows` / `hasObjects`, and `_displayHeight` is the
  maximum of `rect.origin.y + rect.size.height + margin.top + margin.bottom +
  padding.top + padding.bottom + border.width.top + border.width.bottom`, where a
  missing edge contributes 0; an invisible section is 0 exactly as before.  The stub
  and its "stands in until" comment are gone.  The London export is 5 pages / 43,177
  bytes again.  Pinned by `testSectionDisplayHeightIsTheMaximumElementCalculatedHeight`
  (the sum, the maximum over a shorter element, and an element with every optional
  edge absent) and by the CLI export itself.  Along the way the element
  `awakeFromInsert` gained the four satellites the Core Data version created but the
  store version had dropped (alignment, border, dropPoint, numericFormat), which the
  test's border edge immediately exposed.

### `MADocument -managedObjectContext` returns a `RptqStoreContext` under a Core Data type
- **Status:** Fixed — 2026-10-06, in Phase D.
- **Where:** `MAD/Source/MADocument.h` (`managedObjectContext` is declared there as
  `RptqStoreContext *`, next to `storeContext`, which it returns).
- **Behavior:** `managedObjectContext` used to be inherited from `UIManagedDocument`
  as an `NSManagedObjectContext` while the override returned the store context — a
  type lie the compiler could not check.  Now the superclass is `UIDocument`, which
  has no such property: `MADocument` declares the property itself as
  `RptqStoreContext *` and returns `self.storeContext`, so every call site compiles
  against the real type (the `CLI/Source/MADCLIQuery.m` incompatible-pointer warning
  is gone with it).

### `MADSectionGroupLayout` segfaults on a group whose field has no query table
- **Status:** Still open
- **Where:** `MAD/Source/MADSectionGroupLayout.m:43`, `:46`, `:49`, `:58`
- **Behavior:** The initialiser lifts the group's `sort`, `weight` and
  `hasField.databaseSchemaField.dataType`, and the field's
  `inQueryTable.dropIndex`, straight out of the dictionary-result row and pushes
  each through `CFNumberGetValue`. A nil value is a NULL `CFNumberRef`, which
  `CFNumberGetValue` does not test for: the process dies with SIGSEGV instead of
  raising. Reached whenever a group's field is not backed by a `RptqQueryTable` --
  a document whose group field is not in a table the query selects.
- **Why it matters:** It is a hard crash in the formatter on data read back from a
  `.mad`, not an assertion or a wrong number. Found by `MADTestReportFormatter`:
  an incompletely-wired fixture took down the test host rather than failing a
  test, and the crash log was the only diagnosis.
- **Not yet fixed:** the fixture now wires the table, so the test passes without
  reaching it. Nobody has decided what the layout *should* do with a group it
  cannot place -- skip it, or default the four numbers and let it render
  mis-keyed. That is a behaviour decision, not a one-line guard.

### `MADReportTextRepresentation` `-characterCount` / `-elementCount` crash on non-empty input
- **Status:** Fixed
- **Where:** `MAD/Source/MADReportTextRepresentation.m:64` and `:76`
- **Behavior:** Both methods fast-enumerate the page map directly, which yields
  the `NSNumber *` **keys** rather than the page values. A non-empty
  representation raises an "unrecognized selector" exception.
- **Why it matters:** These are the text-export / character-count paths, which
  will be exercised by the text/JSON export work in TODO.md.
- **Now:** both iterate `self.pages.allValues`, so each element is the
  `MADReportPageRepresentation` the loop variable claims. The class also gained
  the `#import <Foundation/NSArray.h>` it was reaching through a transitive
  header for `-allValues`. `testTextRepresentationCountsSumPageValues` (renamed
  from `testTextRepresentationCountsEnumerateKeysDefect`) asserts the counts
  instead of asserting the throw.

### `RptqDirectionalAsymmetry +keyRight` returns `@"left"`
- **Status:** Fixed
- **Where:** `MAD/Source/rptq/RptqDirectionalAsymmetry+Extras.m:18`
- **Behavior:** `keyRight` delegates to `keyLeft`, returning `@"left"` instead of
  `@"right"`.
- **Why it matters:** Blast radius is smaller than the earlier "read/write the
  wrong key on the right edge" claim. All live right-edge access goes through the
  real Core Data properties (`MADDesignerLayout.m:368,456,544`;
  `RptqDocumentElement+Extras.m:751,769,792`), not these key builders. The six
  collapsed builders are consumed only by
  `+fetchRequestElementsInSectionDetailed:`, which has **no callers** — it would
  put duplicate key paths into `propertiesToFetch`. So the defect is real but
  currently unreachable. Pinned by `MADRptqValueTypeTests.m:99-100`.
- **Now:** `keyRight` returns `[RptqDirectionalProperty keyRight]`, matching the
  three sibling accessors that each return their own key.
  `testDirectionalAsymmetryKeyConstants` now asserts `@"right"` where it used to
  pin `@"left"`.

### `MADDatabaseTypeReuseIds` (10) vs `MADDatabaseTypeNames` (9) mismatch
- **Status:** Fixed
- **Where:** `MAD/Source/rptq/RptqDatabase+Extras.h:17`
- **Behavior:** The reuse-id table has one more entry than the localized-name
  table, so "Microsoft SQL Server" is missing a name and the two tables are
  misaligned past index 4.
- **Why it matters:** The new-document database-type picker likely iterates these
  arrays in lockstep; an off-by-one here can pick the wrong driver.
- **Now:** `MADDatabaseTypeNames` has the missing `@"Microsoft SQL Server"` at
  index 5, so both tables have ten entries and line up. Only "None" is wrapped in
  `NSLocalizedString`; leaving the rest as literals is a translation task, not
  part of this defect. `testDatabaseTypeReuseIdsAndNamesAlign` (renamed from
  `testDatabaseTypeReuseIdsAndNamesMismatch`) asserts the two counts match and
  pins index 5.

### `MADDataTableFast -allObjects` was unimplemented (FIXME)
- **Status:** Fixed
- **Commit:** `f25b53118`
- **Where:** `MAD/MADTests/MADDataTableRegressionTests.m`
- **Behavior:** Returned `nil` even when rows existed, from a method the header
  declares `nonnull`. It now returns the rows via `-objectAtRow:limit:`, and
  `@[]` for a table with no columns.
- **Why it mattered:** No production caller existed, so the annotation was a trap
  laid for the next one rather than a live crash. The test that pinned the `nil`
  was replaced by `testFastTableBulkInsertAllObjectsReturnsEveryRow` and
  `testFastTableAllObjectsIsEmptyWhenThereAreNoRows`.

### `digit_count_*_int`: `INT_MIN` collapsed onto `INT_MAX`
- **Status:** Quirk
- **Where:** `MAD/MADTests/MADCoreLogicTests.m`
- **Behavior:** `INT_MIN` is collapsed onto `INT_MAX` before counting digits.
  Both happen to have 10 digits, so the output is correct, but only by
  coincidence.
- **Why it matters:** Harmless today; note it only because the collapse is not
  mathematically general.

### `MADQueryPredicate` and `MADQueryCacheSelectGroupKeys` quote string literals with double quotes
- **Status:** Fixed
- **Commit:** `0c187aca3`
- **Where:** `MAD/Source/MADQueryPredicate.m:80-88`. The hook is
  `MADAPI/Source/MADDatabaseSQLProtocol.h` (`-newSafeLiteral:`), with the base
  implementation in `MADAPI/Source/MADDatabase.m` and overrides in
  `MADTdsClient/Source/MADDatabaseSQLServer.m` and
  `MADMySQL/Source/MADDatabaseMySQL.m`. The group-key builder,
  `MAD/Source/MADQueryCacheSelectGroupKeys.m`, holds the old form in its history and
  now goes through the same hook — see *Now, the two sites left open* below.
- **Behavior:** A predicate's right-hand side was emitted as `"<value>"`:
  `[[NSString alloc] initWithFormat: @"\"%@\"", rightFieldID]`, and the group-key
  builder writes `[sqlPredicate appendFormat:@"%@ = \"%@\"", left, right]`. Both
  wrapped a *value* in double quotes. Neither escaped it, and neither bound it. The
  generated SQL read `("Customer0"."City" = "London")`.
- **Why it mattered:** By the SQL standard a double-quoted token is an *identifier*,
  so these literals only ever worked because SQLite was forgiving about it.
  `SQLITE_DQS=0`, pinned today in `Compressor/sqlite3.xcconfig` (commit
  `26ca18ff7`), turned that forgiveness off, and `sqlite3_prepare_v2` failed with
  *no such column: "London" — should this be a string literal in single-quotes?*.
  Every filtered report refreshed zero rows. Measured on the sample documents,
  `London.mad` went from 0 rows to 76 when `DQS` was set back to 3 with nothing else
  changed. This was the exact risk the `DQS=0` entry under `## MADSqlite3` set out to
  consider and then dismissed.
  Two consequences beyond SQLite. A value containing `'` or `"` was a syntax error
  at best and an injection at worst, since nothing escaped. And SQL Server, whose
  `QUOTED_IDENTIFIER` is ON by default, read these same tokens as identifiers — so
  `Document22.mad` (SQL Server, bracketed, AdventureWorksLT) would have failed the
  same way the moment it carried a filter. MySQL was unaffected by default, reading
  `"…"` as a string, which is why the defect hid in the one backend under test.
- **Now:** The value goes through `-newSafeLiteral:`, which quotes and escapes it for
  the database in use — declared on `MADDatabaseSQLProtocol` beside
  `-newSafeIdentifier:`, implemented once on `MADDatabase` as the ANSI `'…'` with the
  interior quote doubled, and overridden on `MADDatabaseSQLServer` to add T-SQL's `N`
  prefix, without which a literal is varchar and a non-ASCII value goes through the
  database's collation. SQLite and MySQL inherit the base rather than overriding: both
  read an interior quote doubled, and neither gives a backslash a meaning inside a
  literal, so the ANSI form is already what they escape to. `London.mad` refreshes 76
  rows again and the emitted predicate reads `("Customer0"."City" = 'London')`. The
  SQL Server schema lookup, which hand-quoted a table name into `OBJECT_ID('%@')`,
  goes through the same hook; an apostrophe in a table name used to end the literal
  early and leave the rest of the name as SQL.
- **Now, the two sites left open:** both are fixed.
  `MADQueryCacheSelectGroupKeys` adopts `MADQueryDatabaseProtocol`, so
  `-[MADQuery getSql:database:error:]` — the entry point every driver uses, including
  `MADDatabaseSqlite3.m:591` — hands it the database it is about to run against. The
  predicate is no longer assembled in the initializer, where no database existed yet;
  `-whereClauseQuotedByDatabase:` quotes the column with `-newSafeIdentifier:` and the
  value with `-newSafeLiteral:`, and the column and table names go through the same
  dialect. With no database injected — the plain `-getSql:` entry point — it quotes
  with a `MADDatabaseSqlite3`, because this query only ever runs against a document's
  Sqlite3 cache; the sort description it builds is already Sqlite3's. The class is
  still unreachable: only `-initWithQueryType:MADQueryTypeCacheSelectGroupKeys` builds
  it and no caller passes that type, the live group-key path being
  `MADQuerySelectItemsForGroup`, whose `-whereClauseWithParameters:`
  (`MADSqlite3/Source/MADQuery+Sqlite3.m`) binds `?`. Two smaller defects fell out of
  reading it closely. A statement with no predicates came out as
  `… FROM "Customer"  WHERE  ORDER BY …`, a syntax error, and now has no clause at
  all. And a `NULL` term was written `"<null>"` — `-appendFormat:` on an `NSNull` —
  which is a literal string that matches nothing; it is the keyword now. (`NSNull` in
  the cache is deliberate: a NULL read from a source database is stored as `NSNull`
  rather than `nil`, so unwrapping a column value into an `NSObject` never faces a
  nil. Not a defect, and not to be "fixed".)
  The other is MySQL's backslash, which needed the live connection the driver was
  not keeping. See the `## MADMySQL` entry *A backslash in a MySQL literal is an
  escape character*.
- **Test:** `MADAPITests testNewSafeLiteralQuotesAndEscapes` and
  `testNewSafeLiteralNilIsNull`; `MADTdsClientTests testNewSafeLiteralIsANvarcharLiteral`;
  and `MADSqlite3Tests testNewSafeLiteralProducesAValueSQLiteWillRead`, which puts a
  value containing a quote through a real query against the shipped `DQS=0` build, so
  a literal that is bare or double-quoted fails in the suite. That last one was
  confirmed to fail against the old behaviour before it was kept.
  For the group-key builder, `MADTests MADCoreLogicTests`:
  `testGroupKeysQuotesTheValueAsALiteralNotAsAName`,
  `testGroupKeysQuotesColumnAndTableAsIdentifiers`,
  `testGroupKeysWithoutPredicatesLeavesOutTheWhereClause`,
  `testGroupKeysWritesNullAsAKeyword` and
  `testGroupKeysEscapesAnApostropheInTheValue`. All five were run against
  `MADQueryCacheSelectGroupKeys.m` as it stood in `c2be14442` and all five failed,
  the old SQL printed in each failure — including `… FROM Customer  WHERE  ORDER BY
  …` and `= "<null>"`.

### `MADocument -paperSize` reads the `_paper` ivar the lazy `-paper` accessor builds
- **Status:** Fixed
- **Where:** `MAD/Source/MADocument.m`; the accessor is `-paper` in the same file
- **Behavior:** `- (CGSize)paperSize { return _paper.paperSize; }` read the ivar
  directly, but `_paper` stays nil until something calls the lazy `-paper` accessor,
  which is what builds it from `activeDocumentModel.paperType`. Asked first,
  `-paperSize` answered `{0, 0}`.
- **Why it matters:** `-format` and `-formatContentChange` both hand
  `self.paperSize` to the report formatter, and a zero layout size makes
  `PrintableHeightForPage` negative, so the formatter starts a new page on every
  row. The application never sees it because its viewer touches `paper` while
  opening the document. A second caller — the CLI — produced 11602 pages for 3503
  rows until it learned to ask for `document.paper` first.
- **Now:** `-paperSize` reads `self.paper` instead of `_paper`, so it builds the
  paper like any other caller. The CLI workaround — `(void)document.paper;` at
  `CLI/Source/MADCLIDocument.m`, with a comment pointing here — is gone. Verified
  with the CLI: Music, 3503 rows, went from 11602 pages to 77; London, 76 rows, 5.
- **Test:** `MADTestsMADDocumentTests testPaperSizeBuildsThePaperItself`, which
  gives a document a model whose `papersize` is letter and asserts `-paperSize` is
  non-zero, agrees with `-paper`, and is the letter size. Confirmed to fail against
  the ivar read before it was kept.

### `MTPaper -initWithType:` returned class objects for Legal and Government papers
- **Status:** Fixed
- **Where:** `MAD/Source/paper/MTPaper.m`; the `MTPaperLegal`,
  `MTPaperGovernemntLetter`, and `MTPaperGovernemntLegal` branches of the factory
- **Behavior:** `result = [MTPaperLegal init]` (and the two Government siblings)
  sent `init` to the class object instead of `[[MTPaperLegal alloc] init]`, so the
  factory returned the class itself. A document whose paper is Legal,
  Government-Letter, or Government-Legal then stored that class in `MADocument
  -paper`, and the first `-paperSize` read crashed with an unrecognized selector.
  (The correctly-spelled `MTPaperGovernmentLetter` and `MTPaperGovernmentLegal`
  interfaces in the subclass headers were never implemented at all — the `.m`
  files implemented the misspelled names.)
- **Why it matters:** a `.mad` document set to one of those three paper types
  could not be opened.
- **Now:** `MTPaper` is a single class with a static size table.
  `-initWithType:` stores a validated type and answers the Letter size for unknown
  types. The Legal/Government branches, the misspelled classes, and the 72
  boilerplate subclass files are gone; all 37 persisted paper types still answer
  their original sizes through `+sizeForType:`.
- **Test:** `MADTests MTPaperTests testEveryKnownTypeBuildsItsPaperAndSize`, which
  pins the size of every persisted paper type, and
  `testUnknownTypeFallsBackToLetter`.

### `MADArchiveManager -archive:` deleted its backup before it could restore it
- **Status:** Fixed
- **Where:** `MAD/Source/MADArchiveManager.m`
- **Behavior:** Two defects in the save path's failure recovery. The backup of the
  previous archive (written beside it with a `~` suffix) was removed *before* the
  code decided whether it needed it, and the restore guard was
  `if (!success && access(backup_path, F_OK))` — `access` answers 0 when the file is
  present, so the guard was true exactly when the backup did **not** exist. A write
  that failed partway therefore could never restore the previous document; it left
  the archive truncated or absent.
- **Why it mattered:** A failed save is the one place a corruption bug is
  unrecoverable, and the restore logic existed precisely to prevent it. Both defects
  together made the restore a no-op.
- **Now:** `mad_file_remove_if_exist(backup_path)` runs *after* the restore, and the
  guard is `access(backup_path, F_OK) == 0`, so the previous archive is put back
  when — and only when — a backup exists. A first save (no prior archive) produces no
  backup, so the guard correctly skips the restore.
- **Test:** the success path is pinned by
  `MADDocumentTests testArchiveRoundTripWritesAndStripsTheV1Header`. The restore
  path is verified by reasoning, not a fault-injected test: forcing `write_archive`
  to fail in the harness is not worth the machinery.

---


### The document thumbnail uses the deprecated QuickLook file-attribute keys
- **Status:** Open -- kept deliberately, behind a scoped pragma.
- **What:** `MAD/Source/MADocument.m -fileAttributesToWriteToURL:forSaveOperation:error:`
  writes the document's thumbnail with `NSThumbnail1024x1024SizeKey` and
  `NSURLThumbnailDictionaryKey` (`:667`, `:671`), both deprecated in iOS 15 in favour of
  QuickLookThumbnailing.
- **Why it is not changed here:** there is no drop-in replacement.  The modern route is a
  QuickLook thumbnail extension target that renders the icon on demand; deleting this
  code without it would silently drop the custom document icon.  The build warning is
  suppressed locally with a `#pragma clang diagnostic` pair and a pointer to this entry.
- **Where:** `MAD/Source/MADocument.m:661-676`.
- **Follow-up:** decide whether the app wants a thumbnail extension; if not, the code can
  go entirely and the pragma with it.


### MADSectionLayout reads CFNumbers at the wrong widths, corrupting adjacent ivars
- **Status:** Open -- found by the analyzer; could not be fixed blind, so it is recorded.
- **What:** `MAD/Source/MADSectionLayout.m` fills its ivars with `CFNumberGetValue` but
  passes widths that do not match the destinations.  `:55` writes a `double` (8 bytes)
  into `float _height` (4 bytes), and `:61` writes `SInt64` (8 bytes) into
  `MADDocumentSectionType _type`, which is an `int16_t` (`MADDocumentSectionType.h:20`).
  Each call therefore overwrites the storage after its target -- `:55`'s high half lands
  in `_groupLevel`, and `:61`'s high half lands in `_height` -- and neither `_height` nor
  `_groupLevel` is ever assigned again in the file, so the corrupted values stand.
- **Why it is not fixed here:** the ivars are read as the layout's height and grouping;
  correcting the widths changes what those reads return (today `_height` is effectively
  zero), which would visibly change report layout.  That is a behaviour decision, not a
  warning fix.
- **Where:** `MAD/Source/MADSectionLayout.m:52-67`.
- **Evidence:** `xcodebuild analyze`, `osx.coreFoundation.CFNumber`: "a CFNumber object
  that represents a 64-bit integer is used to initialize a 16-bit integer; 48 bits of the
  CFNumber value will overwrite adjacent storage".


### MADocument calls writeContents: with nil contents
- **Status:** Open -- documented; deliberate under the portable store, but it violates the
  inherited contract.
- **What:** `saveToURL:forSaveOperation:completionHandler:` passes `nil` for both the
  contents and the attributes (`:598`, and again at `:624`) to
  `-writeContents:andAttributes:safelyToURL:forSaveOperation:error:`, whose parameters are
  declared non-null.  The override of `contentsForType:error:` returns nil on purpose
  because the portable store writes itself, so the call is consistent with the design --
  but the compiler is right that the API's own contract is being broken.
- **Follow-up:** if the save path is ever revisited, either funnel the write through a
  method whose signature admits nil or make the intent explicit at the call.
- **Where:** `MAD/Source/MADocument.m:594-630`.


### MADReportFormatter compares untyped values through id
- **Status:** Open -- documented; the dynamic dispatch is intentional but unchecked.
- **What:** `MADReportFormatter.m:219` and `:222` send `compare:` to a value held as `id`
  while several classes declare that selector with different argument types, so the
  compiler cannot bind it (`-Wstrict-selector-match`).  If the values being sorted are not
  all the same class -- the formatter sorts query results, which mix numbers and strings --
  the wrong implementation can be invoked, or none at all.
- **Where:** `MAD/Source/MADReportFormatter.m:210-225`.


### UIManagedDocument's resetPersistentStore is declared but never implemented
- **Status:** Fixed — 2026-10-06, in Phase D.  The declaration was removed with the
  category's rename to `UIDocument (Extras)` (`UIDocument+Extras.h`); there is no
  `resetPersistentStore` anywhere in the tree now, so the unrecognized-selector risk
  is gone.
- **What:** `-resetPersistentStore` was declared on the `UIManagedDocument (Extras)`
  category (`UIManagedDocument+Extras.h:16`) with no implementation; the only reference
  in the implementation file was a commented-out call.  Any future call would have been
  an `unrecognized selector` crash.


### MADModelQuery can insert a nil table into its dictionary
- **Status:** Open -- documented; the analyzer flags it as a nil-object risk.
- **What:** `[_tables setObject:queryTable forKey:qtidn]` (`:301`) assumes `queryTable` was
  built earlier in the loop (`:289`), but the assignment only happens when
  `resultCounter == 0`, so a path that reaches `:301` with an unset `queryTable` sends nil
  to `setObject:forKey:`, which throws.
- **Where:** `MAD/Source/MADModelQuery.m:285-302`.
- **Evidence:** `osx.cocoa.NilArg` from `xcodebuild analyze`.


### MysqlFetch passes an uninitialized value to a function
- **Status:** Open -- documented from the analyzer run.
- **What:** `core.CallAndMessage` reports that the first argument of a function call at
  `MysqlFetch+DataTable.m:668` is uninitialized on some paths.
- **Where:** `MADMySQL/Source/MysqlFetch+DataTable.m:668`.


### The installed accessor blocks re-read a weak store context
- **Status:** Fixed
- **Now:** the four accessor blocks in `RptqObject.m` read the weak `storeContext` once
  into a strong local at the top of the block, and the block parameter that used to be
  named `self` is `target` (it shadowed the enclosing class method's `self`).  The
  to-many accessors therefore touch the weak property once per call instead of once per
  member, and the four `-Wshadow` findings are gone with the same edit.
- **Why the local is safe here:** the strong local lives for the block's *invocation*
  only; it is not captured by the stored block, so nothing gains a reference that
  outlives the call.  An earlier version of this entry claimed hoisting would create a
  retain cycle -- that is true only of a strong capture taken at *install* time, which
  this is not.
- **Where:** `MAD/Source/rptq/store/RptqObject.m:233-254`.

### The nullability analyzer reports nil crossing nonnull boundaries
- **Status:** Open -- documented from the analyzer run; each site is a crash risk if its
  value is ever nil.
- **What:** `xcodebuild analyze` reports fourteen sites where nil crosses a boundary the
  declarations call non-null.  The return sites (the method promises non-nil and then
  `return nil` on a guard path): `MADDocumentObjectDataReference.m:219,225,231,243,253,258`,
  `MADocument.m:978`, `MADStoreGraph.m:65`.  The argument sites (a possibly-nil value
  passed to a non-null parameter): `MADModelQuery.m:462,483` (a nil table into a
  dictionary), `MADPrintPageElement.m:222`, `RptqDocument+Extras.m:610`
  (`[hasObjects insertObject:reportObject atIndex:0]` with a possibly-nil object).
- **Note:** `MADocument.m:598,624` appear here too and are covered by the
  `writeContents:` entry above.
- **Where:** the file:line list above.
- **Evidence:** `nullability.NullReturnedFromNonnull` and
  `nullability.NullPassedToNonnull` in `xcodebuild analyze`.


### MADDataTableFast returns nil from methods declared non-null
- **Status:** Open -- documented from the analyzer run.
- **What:** Five `return nil` / possibly-nil returns sit on paths of methods the
  declarations say always return a value: `:964`, `:973`, `:987`, `:1280`, `:1416`.
  Callers that trust the declaration will not nil-check.
- **Where:** `MADSqlite3/Source/MADDataTableFast.m:964,973,987,1280,1416`.
- **Evidence:** `nullability.NullReturnedFromNonnull` in `xcodebuild analyze`.


### The store's per-column read loop relies on schema names being non-nil
- **Status:** Invariant, not a defect -- recorded so the next reader knows.
- **What:** `MADStore.m`'s row loop passes `column.attribute.name` (and
  `column.relationship.name`) to `setAttributeValue:forName:`, whose implementation does
  `self.values[name] = value`.  A nil key throws, but the schema always names its
  attributes, so the call sites carry an explicit `(NSString *)` cast rather than a
  guard: this is the per-column, per-row loop that fills every document, and a branch
  there buys nothing when a nil name would mean a malformed schema.
- **Where:** `MAD/Source/rptq/store/MADStore.m:273-278`.

### `MADOperationCreateDocumentAddConnection` reports success without a document
- **Status:** Confirmed (latent -- only reached when the queue is mis-wired)
- **Where:** `MAD/Source/MADOperationCreateDocumentAddConnection.m:38-58`
- **Behavior:** `-execute` scans its dependencies for a
  `MADOperationCreateDocumentProtocol`, leaves `document` nil when none matches, sends
  `[document activeDocumentModel]` (a message to nil, so a no-op), then sets
  `self.success = YES` and finishes -- no error, no document.  Its siblings
  (`MADOperationCreateDocumentImportSchema`, `...SaveAndCloseNewDocument`) finish with
  an error in the same situation, and `MADOperationCreateDocumentFirstTimeSetup` trips
  `RptqDocument`'s nil-context `NSAssert` instead, so the family has three different
  answers to the same missing dependency.
- **Why it matters:** `success` is the only signal the queued consumer gets; a queue
  assembled in the wrong order reports "connection added" for work that never happened.
- **Test:** `MADOperationCreateDocumentAddConnectionTests
  testExecuteWithoutADocumentDependencyStillReportsSuccess`.

### `MADOperationKeyChainDeletePassword`'s `success` never leaves NO
- **Status:** Confirmed (latent -- nothing reads the property in-tree today)
- **Where:** `MAD/Source/MADOperationKeyChainDeletePassword.m:19,36-50`
- **Behavior:** The initializer sets `_success = NO`, and `-execute` never assigns it:
  a delete MADKeyChain reports as clean still finishes with `success == NO`.  The error
  path is also silent -- a failed delete carries the error through
  `-finishWithError:` but leaves the flag at NO too, so the two outcomes are
  indistinguishable from the property.
- **Why it matters:** Any future consumer that reads `success` instead of checking
  `errors` will treat every successful delete as a failure.
- **Test:** `MADOperationKeyChainDeletePasswordTests
  testExecuteWithAMissingKeyFinishesWithoutError`.

### `MADOperationDeleteFile`'s dependency scan is order-dependent and can coordinate a nil URL
- **Status:** Confirmed (latent)
- **Where:** `MAD/Source/MADOperationDeleteFile.m:34-60`
- **Behavior:** Two separate hazards in the same loop:
  1. The scan `break`s as soon as it sees a `MADOperationCreateDocumentProtocol`
     dependency, so a `MADOperationTestResults` dependency that happens to appear later
     in `-dependencies` (whose order is undefined) is never consulted: `deleteFile`
     stays NO and the failed create's file is left on disk, even though a unique URL
     was reserved for it.
  2. When `deleteFile` is YES but no `MADOperationUniqueUrlForFilenameProtocol`
     dependency was seen, the local `fileURL` is nil and is handed to
     `MADFileUtilities -removeFileAtURL:completion:`, which passes it to
     `NSFileAccessIntent`/`NSFileCoordinator` -- a likely invalid-argument crash.
- **Why it matters:** The order-dependent path is unreachable deterministically, and
  the nil-URL path crashes rather than failing the operation.  Fixing means splitting
  the loop (collect all three) and guarding the URL.
- **Test:** `MADOperationDeleteFileTests` pins the three deterministic paths
  (`testExecuteWithFailingResultsDeletesTheFile`,
  `testExecuteWithSuccessfulResultsLeavesTheFile`,
  `testExecuteWithOnlyADocumentDependencyDoesNotDelete`); the order-dependent
  combination and the nil-URL path are deliberately not exercised -- the first cannot
  be pinned, the second would take the test process down.

### `MADOperationDocumentCloseDocument` treats "no document" as a successful close
- **Status:** Quirk (hazard -- documented, not changed)
- **Where:** `MAD/Source/MADOperationDocumentCloseDocument.m:30-52`
- **Behavior:** With no `MADOperationCreateDocumentProtocol` dependency, `doc` is nil;
  `(doc.documentState & UIDocumentStateClosed)` is 0 and `doc.storeContext == nil` is
  true, so the guard falls through to `[MADocument close:nil completion:]`, which reads
  nil as "already closed" and reports success.  Nothing distinguishes closing a
  document from having none -- the same shape as the AddConnection entry above.
- **Test:** `MADOperationDocumentCloseDocumentTests
  testExecuteWithoutDependencyFinishes`.

### Image elements do not survive a save
- **Status:** Confirmed (live defect)
- **Where:** `MAD/Source/rptq/RptqDocument+Extras.m:559-562` (the factory assigns a
  `UIImage`), `MAD/Source/rptq/store/MADStoreSchema.m:563-565` (the attribute is a
  `BlobOpt`), `MAD/Source/rptq/store/MADStore.m:483-485` (the Blob binder accepts only
  `NSData` and otherwise binds `NULL`), `MADStore.m:217-220` (reads come back as
  `NSData`).
- **Behavior:** `RptqDocumentElementImage.image` is declared `UIImage *` and the
  factory stores one, but the store's Blob column binds bytes only for `NSData`; a
  `UIImage` therefore writes SQL NULL and the value is gone on the next open (a read
  would hand back `NSData` if anything had been written).  The store-open/again round
  trip in the test is the whole bug: in-memory the image is there, after save/reopen it
  is nil.
- **Why it matters:** An inserted picture silently disappears from the document the
  next time it is opened -- the one place a report can carry a logo.  The fix is a
  transform at the attribute boundary (PNG data in, UIImage out).
- **Test:** `MADDocumentObjectDataReferenceImageTests testImageDoesNotSurviveSaveAndReopen`
  (and the in-memory half by `testImageIsTheElementImageWhileInMemory`).

### `MADReportSection -identifier` recurses forever when its section is unwired
- **Status:** Confirmed (latent)
- **Where:** `MAD/Source/MADReportSection.m:109-120` (`-documentSection`) and
  `:122` (`-identifier`)
- **Behavior:** `-identifier` reads `self.documentSection.identifier`.  The lazy
  `-documentSection` getter, when `_documentSection` is nil, builds one with
  `newDocumentSectionWithIdentifier:self.identifier` -- which re-enters `-identifier`
  before the getter can store anything: unbounded recursion (stack overflow), not a
  nil answer.  `-type`, `-height`, `-isVisible` go through the same getter and would
  recurse the same way on an unwired section.  Related: `+initWithReportSection:`
  returns nil for `MADDocumentSectionTypeUnknown` (the switch's default leaves the
  strong local zero-initialised), so an unknown row is silently dropped rather than
  surfaced.
- **Test:** none -- exercising the recursion would take the process down; recorded
  from reading.  The Unknown-type nil is pinned by
  `MADReportSectionTests testInitWithAnUnknownTypeReturnsNil` (added with this entry).

### `MADImageThumbnail` draws page 1, so a one-page document's thumbnail is blank
- **Status:** Confirmed (live defect)
- **Where:** `MAD/Source/MADImageThumbnail.m:102`
- **Behavior:** The renderer-based path calls
  `[printPageRenderer drawPageAtIndex:1 inRect:rect withTransparentBackground:YES]`.
  `MADPrintPageRenderer`'s page loop is zero-based (`drawPageAtIndex:withContext:`), so
  index 1 is the *second* page; for a one-page report the bounds check answers no and
  the thumbnail is the blank white canvas.  The comment in the sibling draw code calls
  this "the first page is never drawn", so the off-by-one looks deliberate for
  multi-page reports and wrong for the cover.
- **Why it matters:** The document browser shows empty thumbnails for single-page
  reports.  Related quirk: the factory methods are declared on `MADImageThumbnail` (a
  `UIImage` subclass) with an `instancetype` return, but the object built is a plain
  `UIImage` -- callers that trust the static type would be wrong about the class.
- **Test:** `MADImageThumbnailTests
  testRendererThumbnailIsASquareLetterPageAndDrawsPageOne` (pins the page index and the
  plain-`UIImage` result).

### `MADPrintPageRenderer` ignores `withTransparentBackground:`
- **Status:** Confirmed (live defect)
- **Where:** `MAD/Source/MADPrintPageRenderer.m:289-295`
- **Behavior:** `-drawPageAtIndex:inRect:withTransparentBackground:` never reads the
  flag; it always paints the opaque white canvas and then draws the page.  The header
  documents the parameter as "draws a transparent background instead of white", and
  `MADImageThumbnail` calls it with `YES` expecting transparency.
- **Why it matters:** Any caller asking for a transparent page gets an opaque white
  one; the parameter is a lie.
- **Test:** `MADPrintPageRendererTests testDrawPageDrawsTheWhiteCanvasEvenWithTransparentBackground`.

### `RptqDocumentSectionEnumerator`'s two enumerators disagree with their own counts
- **Status:** Confirmed (latent -- the enumerators have no callers in-tree)
- **Where:** `MAD/Source/rptq/RptqDocumentSectionEnumerator.m:58-61` (the type
  enumerator's `-nextObject`) and `:102-106` (the row enumerator's)
- **Behavior:** The *type* enumerator pre-increments the row
  (`getSectionTypeforRow:++_current`), so the first call skips row 0 (the report
  header) and no call ever terminates -- past the last row it keeps answering
  `GroupFooter`.  The *row* enumerator ignores its `_total`: with no query it answers
  row 0 anyway (a `MADReportSection` that does not exist), and it never ends either.
- **Why it matters:** Both are `NSFastEnumeration` sources; anything that iterates one
  gets an endless stream with the first row missing (or a phantom row).
- **Test:** `RptqDocumentSectionEnumeratorTests
  testTypeEnumeratorNextObjectSkipsRowZeroAndHasNoEnd` and
  `testNextObjectIgnoresTheCountWhenThereIsNoQuery`.

### `MADQueryFullTableEnumerator` overrides no enumeration method
- **Status:** Quirk (dead class -- left as is)
- **Where:** `MAD/Source/MADQueryFullTableEnumerator.m`
- **Behavior:** It subclasses `NSEnumerator` and stores a document identifier and
  context, but never overrides `-nextObject`; enumerating it raises
  `NSInvalidArgumentException` from `NSEnumerator`'s abstract implementation.  Nothing
  in the tree instantiates it.
- **Test:** `MADQueryFullTableEnumeratorTests
  testNextObjectIsStillNSEnumeratorsAbstractImplementation`, which pins the inherited
  IMP rather than calling it.

### `MADModelQueryTable -addField:schemaField:` never wires the field's query table
- **Status:** Quirk (documented, not changed)
- **Where:** `MAD/Source/MADModelQueryTable.m:92-105`
- **Behavior:** The field is registered in the table's dictionary under its identifier,
  but its `inQueryTable` back-reference is never set (nothing in the class's own
  initialiser sets it either), so every `MADModelQueryField` reports a nil query table.
- **Why it matters:** Low today -- nothing reads the back-reference -- but it makes the
  registration one-directional and surprises the next reader.
- **Test:** `MADModelQueryTableTests testAddFieldRegistersTheFieldUnderItsIdentifier`.

### `MADDocumentObjectDataReference -copyWithZone:` drops the delegate
- **Status:** Quirk (documented, not changed)
- **Where:** `MAD/Source/MADDocumentObjectDataReference.m:134-144`
- **Behavior:** The copy carries item, page, row and the weak datasource but not the
  delegate, so `-fontAttributes` on a copy is always nil (it is built from the
  delegate).  Note the delegate is a strong property here while the datasource is weak.
- **Test:** `MADDocumentObjectDataReferenceTests
  testCopyCarriesItemAndIndexesButNotTheDelegate`.

### `MADSectionLayoutAttributes +movePlacedItem:` teleports an isolated item to the origin
- **Status:** Confirmed (live defect)
- **Where:** `MAD/Source/MADSectionLayoutAttributes.m:62-82`
- **Behavior:** The candidate drop point starts as `CGPointZero` with its distance
  measured from the item's own origin, so when there is no *other* item to snap
  against, the loop never replaces the candidate and the item's frame is set to
  `(0, 0, w, h)` -- the origin, not a nearby valid point.  An item that was already
  somewhere sensible is yanked to the top-left the first time layout runs while it is
  alone.
- **Test:** `MADSectionLayoutAttributesTests testPlaceItemWithNoOtherItemsSnapsToTheOrigin`
  (characterization) and `testPlaceItemSnapsToTheNearestOtherCorner` (the
  with-neighbours half).

### `MADSectionLayoutManager -removeItemWithID:` corrupts indexes for an unknown ID
- **Status:** Confirmed (latent)
- **Where:** `MAD/Source/MADSectionLayoutManager.m:244-263`
- **Behavior:** The lookup for an ID not in `items` answers nil, `pathToRemvoe` is nil,
  and `[nil indexAtPosition:]` reads 0 -- so the "shift later items down" comparison
  passes for *every* item, each index is decremented, the item at index 0 underflows to
  `NSUIntegerMax`, and nothing is removed.  The manager is left with corrupt
  index-paths; `NSIndexPath` tolerates the huge value, so the corruption surfaces later
  (or crashes downstream) rather than in the call.
- **Test:** `MADSectionLayoutManagerTests
  testRemoveWithAnUnknownIDLeavesEveryIndexDecremented`.

### `MADReportSectionRowsRepresentation` declares `itemCount` but implements `isItemCount`
- **Status:** Confirmed (latent -- nothing reads either accessor)
- **Where:** `MAD/Source/MADReportSectionRowsRepresentation.h:20`,
  `MAD/Source/MADReportSectionRowsRepresentation.m:50`
- **Behavior:** The header declares `@property (nonatomic, readonly) NSUInteger itemCount;`.
  The implementation never implements that getter; it implements
  `- (NSUInteger)isItemCount` instead.  The declared property is therefore
  auto-synthesised against an `_itemCount` ivar nothing writes, so `-itemCount` returns
  0 however many lines the container holds, while `-isItemCount` returns the real count.
- **Why it matters:** A caller using the declared API silently sees an empty container.
  No production code reads either selector today (checked: `itemCount` appears only in
  the declaration), so the defect is latent.  The honest fix is to either rename the
  implementation or declare the property `getter=isItemCount` -- a one-line change left
  for a deliberate decision.
- **Test:** `MADReportSectionRepresentationTests testDeclaredItemCountGetterReadsZero`,
  which asserts the declared getter reads 0 and the implemented one reads 2, via the
  test-only bridge the suite already uses for undeclared implementation selectors.

### `RptqQueryTable -isEqualTo:` compares every non-nil table as equal
- **Status:** Confirmed (latent -- conforms to MTProtocolCompare, but no production caller)
- **Where:** `MAD/Source/rptq/RptqQueryTable+Extras.m:97`
- **Behavior:** The first clause is `if ([sender isEqual:sender]) return YES;` -- a
  tautology -- so any non-nil argument compares equal.  The fallback branch is
  unreachable and, if it were reached, compares two uninitialised `NSNumber` locals
  (nil under ARC), yielding `NO`.  The method therefore answers "equal" for every
  non-nil pair and "not equal" only for nil.
- **Why it matters:** Anything treating query tables as graph nodes would see every
  table as the same node.  Today `MADQueryFull`'s graph wraps `NSNumber` identifiers
  (`MADQueryFull.m:176-193`), and `MTVertex`/`MTEdge` equality is by
  `uniqueIdForStructure`, so nothing reaches this method -- checked across MAD,
  MADDataStructures, and MADDesigner.
- **Test:** `MADRptqQueryTests testQueryTableIsEqualToIsDegenerate`.

### `MADReportFormatterCache` is in no target's Sources build phase
- **Status:** Quirk (dead file -- left as is)
- **Where:** `MAD/Source/MADReportFormatterCache.m`
- **Behavior:** The file sits in the MAD project group and its header is in the Headers
  phase, but the `.m` appears in no `Sources` build phase, so the class is in no binary.
  Nothing in the tree references it (checked: the only reference is this test suite,
  which cannot link it).
- **Why it matters:** It looks like a live size-keyed layout cache, so a reader could
  "use" a class that does not exist at link time.  Either wiring it into the framework
  or deleting the file is the real fix; both are project changes, deferred.
- **Test:** none possible -- `MADQuerySimpleTypesTests` records why the class is not
  covered.

### `MADQueryCacheIndexCreateTemplate -parameterCount` is declared nowhere and called nowhere
- **Status:** Quirk (dead code -- left as is)
- **Where:** `MAD/Source/MADQueryCacheIndexCreateTemplate.m:54`
- **Behavior:** `-parameterCount` (`_groupCount * 2 + 2`) is implemented, but no header
  declares it and no code in the tree calls it.  The class's own `-getSql:` template
  emits the same number of `?` placeholders, so the count is presumably meant for the
  statement binder, which today must count placeholders itself (or not at all).
  The class is also absent from the `MADQuery (Extras)` factory switch -- callers
  construct it directly.
- **Why it matters:** Low; it is internal bookkeeping with no consumer.  Recorded so a
  future binder work does not reinvent it without noticing the existing convention.
- **Test:** `MADQuerySimpleTypesTests testIndexCreateTemplateWithGroupCount` and
  `testIndexCreateTemplateWithZeroGroupCount`, through the test-only bridge.

### `MADQueryFull` treats its `error` out-parameter as an input, and drops the sort error
- **Status:** Confirmed (latent -- no test; both paths need inputs the app does not produce yet)
- **Where:** `MAD/Source/MADQueryFull.m:206`, `:260`
- **Behavior:** Three related contracts are broken in
  `-SQLOnlyActiveFields:managedObjectContext:error:`:
  1. `if (*error != NULL)` at `:206` reads the caller's out-parameter as if it were an
     incoming value.  A caller who passes an `NSError **` whose pointee is not nil
     (garbage from an uninitialised local, or a reused variable) takes the "bad
     conditions" branch and gets empty SQL for a perfectly good query.  The topological
     sort's own error is written to the local `sortError` and never read, so a circular
     query -- the one thing that branch exists for -- is silently ignored and the
     generator proceeds.
  2. The same `*error` read crashes outright when the caller passes `NULL`, which both
     this method and `-copySQLWithManagedObjectContext:error:` accept as nullable.  The
     crash happens on every call, before any SQL is built.
  3. The "no active fields" branch writes `*error = ...` (code 5774) at `:260` without
     checking `error != NULL`, a second unguarded write on the same parameter.
- **Why it matters:** Contract violations a caller can trip with ordinary C habits;
  none have bitten yet because the app always passes a live `NSError **` and
  (presumably) never builds a cyclic query.  Fixing means NULL-checking the parameter
  and reading `sortError` in the guard -- a deliberate behaviour change left for the
  queue.
- **Test:** The non-nil error path is pinned by `MADQueryFullTests
  testNoActiveFieldsReportsError` (code 5774, domain `MADQuery`); the NULL and cyclic
  paths are deliberately untested because both currently crash or emit garbage.

### `MADElementStylizedText` accepts a nullable font name that crashes when nil
- **Status:** Confirmed (latent -- callers always pass a font name)
- **Where:** `MAD/Source/MADElementStylizedText.h:21`,
  `MAD/Source/UIFontDescriptor+MADAdditions.m:21-25`
- **Behavior:** `-initWithFontName:fontSize:textStyle:horizontalAlignment:` annotates
  `fontname` (and its return value) nullable, but it hands the name straight to
  `UIFontDescriptorFamilyAttribute` in a dictionary literal.  A nil name throws
  `NSInvalidArgumentException` from `+[NSDictionary dictionaryWithObjects:forKeys:count:]`
  rather than returning nil.
- **Why it matters:** The annotation promises a graceful nil; the caller gets a crash.
  Every current caller passes a name, so it is latent.  Either the annotation or the
  nil handling has to give.
- **Test:** `MADElementStylizedTextTests testNilFontNameThrows` pins the current
  throw.

## MADFoundation

### `MADOperation -willEnqueue` advances past `Pending` to `Ready`
- **Status:** Quirk (documented; not a defect)
- **Where:** `MADFoundation/Source/MADOperation.m:163-166`
- **Behavior:** `-willEnqueue` sets `state = Pending`, but because `isReady` is a
  KVO-dependent key of `state` (see `+keyPathsForValuesAffectingValueForKey:`),
  the `didChangeValueForKey:@"state"` notification re-enters `-isReady`, which
  runs `-evaluateConditions` and advances a dependency-free operation straight to
  `Ready`. The operation never observably rests in `Pending`.
- **Why it is not a defect:** That `isReady` → `state` mapping is exactly what
  NSOperation dependency scheduling requires, so removing it is not an option.
  Nothing outside `MADOperation.m` reads `.state`, which makes the skipped
  transition unobservable. Called a defect in an earlier pass; kept here so the
  next reader does not "fix" the mapping and break dependencies.
- **Locked down by:** `MADOperationTests.m` `testWillEnqueueAdvancesPastPendingToReady`
  (comment corrected to record this as intended).

---


### MADDataTable's cache loader dereferenced a null error pointer
- **Status:** Fixed
- **Now:** both writes to `outError` in `-loadFromCacheWithUrl:error:` are guarded with
  `if (outError)`, matching the three other failure paths in the same method that already
  checked it.  A caller passing NULL -- the convention the parameter's `_Nullable`
  annotation invites -- now gets NO back instead of a null dereference.
- **Where:** `MADFoundation/Source/MADDataTable.m:150` (file-missing path) and `:187`
  (payload-failure path).
- **Why it changed:** `xcodebuild analyze` reported both sites under `osx.cocoa.NSError`
  ("Potential null dereference.  According to coding standards in 'Creating and Returning
  NSError Objects' the parameter may be null").  A sweep of MADFoundation found exactly
  these two unguarded writes in the module; `MADDataTableVirtual.m:95` and
  `MADKeyChain.m:257` already guard.
- **Locked down by:** `MADDataTableRegressionTests`
  `testBaseTableLoadFromCacheWithMissingFileAndNullErrorReturnsNo` and
  `testBaseTableLoadFromCacheWithInvalidPlistAndNullErrorReturnsNo`.  Both crashed the
  test process before the change (verified) and pass after it, and the existing
  `testBaseTableLoadFromCacheWithMissingFileReturnsError` (asserting error code -215) and
  `testBaseTableLoadFromCacheWithNilUrlThrows` still pass -- 76 tests green in the class.

### `MADDataTable`'s caching pair throws an NSError object, not an NSException
- **Status:** Confirmed (left as is -- no changed functionality)
- **Where:** `MADFoundation/Source/MADDataTable.m:139` (`-loadFromCacheWithUrl:error:`,
  code -213) and `:201` (`-cacheWithUrl:error:`, code -22)
- **Behavior:** Both nil-URL guards `@throw` the `NSError` object itself.  The other
  failure paths in the same methods return `NO` with the error handed back through the
  out-parameter.
- **Why it matters:** `@catch (NSException *)` -- the only shape the codebase writes --
  does not catch it, so a caller passing nil (nullable per the signature) gets an untyped
  object thrown past it.  The same shape as the MADAPI connection view controllers'
  `@throw NSInternalInconsistencyException;`.
- **Test:** `MADDataTableBaseTests testCacheWithNilUrlThrowsTheErrorObject` and
  `testLoadFromCacheWithNilUrlThrowsTheErrorObject`, which catch `id` and assert the
  thrown object's class, code and domain.

### `BDHost +addressForHostname:` crashes when the name resolves to no IPv4 address
- **Status:** Confirmed (latent -- no IPv6-only resolution in the test environment)
- **Where:** `MADFoundation/Source/BDHost.m:27`
- **Behavior:** The guard is `addresses.class > 0 ? addresses[0] : nil`.  `[NSArray class]`
  is never 0, so the test only rejects nil; `+addressesForHostname:` answers an *empty*
  array for a name that resolves to IPv6 only (it filters everything that is not
  `AF_INET`), and subscripting element 0 of an empty array throws `NSRangeException`.
- **Why it matters:** An IPv6-only hostname -- the normal case on some networks -- takes
  the connection screen down instead of reporting a lookup failure.
- **Test:** none, deliberately: no IPv6-only fixture resolves deterministically in an
  offline simulator.  The non-empty path is pinned by `BDHostTests
  testLocalhostResolvesToLoopback`.

### `BDHost +ipAddresses` / `+ethernetAddresses` are unchecked walks of `getifaddrs()`
- **Status:** Quirk (dead code -- left as is)
- **Where:** `MADFoundation/Source/BDHost.m:117`, `:140`
- **Behavior:** Both iterate the interface list and read `ifa_addr->sa_family` without
  checking `ifa_addr` for NULL; an interface without an address dereferences NULL.  Both
  methods are also declared in no header and called from nowhere in the tree (checked
  across every framework and the app).
- **Why it matters:** Dead code that crashes on a well-formed input is best wired up or
  deleted; both are changes, so it is recorded instead.
- **Test:** none -- the unchecked walk is exactly why the suite does not call them;
  `BDHostTests`' header records that.

### `MADDataTableVirtual -addRow:error:` lets a short row desynchronize the two views
- **Status:** Quirk (hazard -- documented, not changed)
- **Where:** `MADFoundation/Source/MADDataTableVirtual.m:179-195`
- **Behavior:** The method walks the supplied array positionally and stops when the
  array runs out.  A row shorter than the column list therefore stores the row
  dictionary with only the supplied keys, appends only those values to the column
  objects, and still increments the row counter and appends to the index.  The row
  view and the column view then describe different rows: `-objectAtRow:column:` for
  the missing column indexes an empty `MADDataColumn`, which asserts in Debug
  (`MADDataColumn.m:170`) and reads out of bounds in Release.
- **Why it matters:** Nothing in the app calls `-addRow:error:` with short rows --
  `-addRowWithDataForFieldKeys:`, the path the drivers use, pads missing values with
  `@""` -- so this is latent.  It is the kind of latent that surfaces the first time
  a driver writes a ragged row.
- **Test:** `MADDataTableVirtualTests testShortRowLeavesTheColumnViewDesynchronized`
  pins the stored state; the empty-column read is not exercised because it asserts.

### `MADDataTableVirtual` has undeclared implementation selectors
- **Status:** Quirk (left as is)
- **Where:** `MADFoundation/Source/MADDataTableVirtual.m` (vs `MADDataTableVirtual.h`)
- **Behavior:** `-objectAtIndex:` (`:147`) and `-sortedIndexForIndex:` (`:124`) are
  implemented but declared in no header; the declared surface only carries
  `-objectAtIndexedSubscript:`.  `+keySortIndex` is likewise internal.
- **Why it matters:** Hidden API is easy to break silently; none of it is called from
  outside the class today.  Same shape as `MADFileUtilities`' undeclared helpers and
  `MADQueryCacheIndexCreateTemplate -parameterCount`, both recorded elsewhere in this
  file.
- **Test:** `MADDataTableVirtualTests testObjectAtIndexAndSubscriptAgree`, through the
  test-only category bridge the suite already uses.
### `MADOperationConditionResultTests`: the async-path assertion raced the dispatch_group

- **Status:** Fixed
- **Where:** `MADFoundation/MADFoundationTests/MADOperationConditionResultTests.m`,
  `-testCompletionIsNotCalledBeforeTheMethodReturnsForTheAsyncPath` (formerly the
  `XCTAssertFalse(calledBack, ...)` at :265).
- **Behavior:** the test called `evaluateConditions:` with a condition that reports
  on the spot, then asserted on the very next line that the completion had not run.
  A condition that reports immediately leaves the dispatch_group empty during the
  loop, so `dispatch_group_notify` enqueues its block to a global concurrent queue
  before the method returns -- another core can run it in that window.  Reliably
  green on a quiet machine; it failed twice under the Linux image's parallel
  `ctest` load (59 executables on a saturated VM), where the caller is descheduled
  right after the notify.
- **Now:** not weakened but made deterministic: the stub condition can defer its
  report (`defersCompletion` / `-reportDeferredCompletion`), so the "not yet
  called" observation happens while the condition is provably still outstanding
  -- and the test then waits for the completion it previously never observed.
  The same change is in the Linux port
  (`Linux/Tests/MADOperationConditionResultTests.m`), which is where the flake
  was measured.
- **Locked down by:** the same test; a 60-run loop of the Linux executable and
  eight parallel full-suite passes with zero failures (measured 2026-10-06), and
  MADFoundation 118/118 on the simulator.

## MADCocoaExtensions

### `CGRectAdjustForScale` shrinks regardless of zoom direction
- **Status:** Quirk (load-bearing; do not "fix" one branch)
- **Where:** `MADCocoaExtensions/Source/CGGeometry+Extras.h`
- **Behavior:** For `zoomScale > 1` it multiplies by `1/zoomScale`; for
  `zoomScale < 1` it multiplies by `zoomScale`. Both paths shrink the rect.
- **Why it is intentional:** the two callers split the `zoomScale` domain between
  them. `MADDesignerScrollView.m:30` calls it only on the `zoomScale < 1` path,
  and `:146` only after forcing `zoomScale >= 1` at `:142-144`; the two results are
  then compared with `CGRectContainsRect` at `:150`. Each therefore lands in the
  branch that is correct for its case, and changing one branch without reworking
  both call sites breaks that test — which is exactly what an earlier pass
  suspected. Left as-is, with a comment above the function in the header.
- **Locked down by:** `MADGeometryExtrasTests.m` `testAdjustForScale`.

### `newColorWitColors` misspells "With"
- **Status:** Quirk (deferred)
- **Where:** `MADCocoaExtensions/Source/MADColor.h`
- **Behavior:** The public factory is named `newColorWitColors` (missing the
  "h"). A corrected `newColorWithColorsAlpha` variant already exists.
- **Why it matters:** Cosmetic API typo, consistent with the `TypeCache` typo
  noted under MADAPI. Deferred: the fix is an additive alias
  (`+newColorWithColors:` forwarding to the misspelling) so no caller has to
  change, and that is churn for a cosmetic gain.

### `MADColorEverydayApps` header colors bypass the 8-bit-to-unit conversion
- **Status:** Confirmed (pinned as-is -- no changed functionality)
- **Where:** `MADCocoaExtensions/Source/UIColor+EverydayApps.m:30`
  (`-newColorHeaderColor`) and `:40` (`-blueHeaderSecondaryColor`)
- **Behavior:** Every other palette member builds its color through
  `newColorWitColors` / `newColorWithColorsAlpha`, which divide the 8-bit triple by
  255.  The light-mode branches of these two dynamic colors instead call
  `+[UIColor colorWithRed:green:blue:alpha:]` with the raw 8-bit numbers
  (2, 108, 182 and 13, 158, 215).  That initializer expects 0-1; the components are
  stored as given -- an extended-range sRGB color -- so the intended blue is not
  what the color carries, and at draw time Core Animation clamps the out-of-range
  components to white.
- **Why it matters:** In light mode the header tint renders as a 20%-alpha white
  veil instead of the blue.  `blueHeaderSecondaryColor` has the same arithmetic
  but an alpha of 0, so it is invisible either way.  The fix is dividing by 255,
  as every sibling does.
- **Test:** `MADColorEverydayAppsTests testHeaderColorLightModeComponentsAreOutOfRange`
  and `testBlueHeaderSecondaryLightModeComponentsAreOutOfRange`, which pin the
  stored 2/108/182 and 13/158/215 components; every other palette member is pinned
  at unit scale.

---

## MADFileManager

### `MADMetaData -fileSystemFileCreationDate` / `-fileSystemContentChangeDate` return `NSData` not `NSDate`
- **Status:** Fixed (type lie)
- **Where:** `MADFileManager/Source/MADMetaData.m`, `MADMetaDataLocal.m`, `MADMetaDataCloud.m`
- **Behavior:** The header declares both as `@property (readonly) NSDate *`, but the
  accessor implementations are typed `- (NSData *)...`. The object that actually
  comes back is an `NSDate` (copied out of the file attributes), so callers that
  trust the compiler's `NSData` type will crash on methods like `-length`.
- **Why it matters:** The compiler and runtime disagree about these two types; the
  property/accessor mismatch is exactly the kind of thing that will bite once
  file metadata is routed through the new manual-SQL cache.
- **Now:** both subclass accessors and the base class's throwing stubs are typed
  `- (NSDate *)...`, so the implementation agrees with the `NSDate *` property
  in the header. The returned object is unchanged.

### `MADMetaDataLocal` downloading-status reports "current" but the derived flag says NO
- **Status:** Fixed
- **Where:** `MADFileManager/Source/MADMetaDataLocal.m:125`
- **Behavior:** `-ubiquitousItemDownloadingStatus` returns
  `NSMetadataUbiquitousItemDownloadingStatusCurrent`, yet
  `-isUbiquitousItemDownloadingStatusCurrent` hardcodes `NO` instead of deriving
  from that string. A local file simultaneously claims "current" and "not current".
- **Why it matters:** Any UI keying off the status boolean (e.g. a "downloading"
  spinner) will disagree with the status string.
- **Now:** the boolean derives from `-ubiquitousItemDownloadingStatus`, so the two
  agree. `testLocalDownloadingStatusIsConsistent` (renamed from
  `testLocalDownloadingStatusInconsistency`) asserts it is YES.

### `MADMetaData -initWithURL:` / `-initWithMetadataItem:` are self-replacing factories
- **Status:** Quirk (load-bearing — documented, not changed)
- **Where:** `MADFileManager/Source/MADMetaData.m`
- **Behavior:** `-initWithURL:` never touches `self`; it allocates a fresh
  `MADMetaDataLocal` and returns that. Same for `-initWithMetadataItem:` (returns
  a `MADMetaDataCloud`). The caller's original `MADMetaData` allocation is dropped.
- **Why it matters:** Works as a class-cluster-style factory, but under ARC the
  original `self` is leaked and the `instancetype` signature lies about the
  concrete class. Callers doing `[[MADMetaData alloc] initWithURL:]` get a
  subclass back.
- **Caller analysis (2026-10-01): load-bearing — do not stop the replacement.**
  Every `MADMetaData` producer depends on the concrete subclass coming back:
  `MADFilesController.m` (`:311,318,325,370,381,396,411,428,439,580`) assigns the
  result to `MADMetaData *` and uses it immediately, and
  `+newMetaDatumForMetadataItems:` requires `MADMetaDataCloud`. The base class
  throws `exceptionNotImplemented` from every accessor, so "initialise and return
  `self`" breaks all of them. The genuine faults are only the ARC leak and the
  type-lie; fixing those means a proper `+allocWithZone:` class cluster that keeps
  the return value identical. An inline comment now records this at the source.

### `MADFileInfo -isEqual:` has no matching `-hash` override
- **Status:** Fixed
- **Where:** `MADFileManager/Source/MADFileInfo.m:72`
- **Behavior:** `-isEqual:` compares `URL.absoluteURL`, but `-hash` is left to
  `NSObject`'s identity hash. Two `MADFileInfo` objects for the same file compare
  equal yet hash differently.
- **Why it matters:** Using `MADFileInfo` as an `NSSet` member or `NSDictionary`
  key silently fails lookups/`containsObject:`.
- **Now:** `-hash` returns `self.URL.absoluteURL.hash`, the same key `-isEqual:`
  compares. `testEqualObjectsHaveEqualHashes` (renamed from
  `testEqualObjectsHaveDifferentHashes`) pins it.

### `MADFileUtilities -removeContentsOfDirectory:` removes the directory itself
- **Status:** Quirk (load-bearing — documented, not changed)
- **Where:** `MADFileManager/Source/MADFileUtilities.m:656`
- **Behavior:** The method removes each child and then removes the directory too,
  despite the name promising to remove only the contents.
- **Caller analysis (2026-10-01): load-bearing — do not stop the directory
  removal.** The only production caller is
  `+removeCachedFileForDocumentUrl:groupIdentifier:` (`.m:645`), which tears down a
  document's whole local cache directory; leaving an empty directory behind is
  exactly what it does not want. The method's name is what is wrong, not its
  behaviour. An inline comment now records this at the source, and the test's
  header comment points at it.

### `MADFileUtilities` has several undeclared public-ish helpers
- **Status:** Quirk (left as is)
- **Where:** `MADFileManager/Source/MADFileUtilities.m` (vs `.h`)
- **Behavior:** `+createDirectoryForUrlIfItDoesNotExist:`,
  `+contentsOfDirectory:withPathExtension:`, `+removeContentsOfDirectory:`,
  `+removeCachedFileForDocumentUrl:` etc. are implemented but not declared in the
  public header. The tests surface them via a test-only category.
- **Why it matters:** Hidden API is easy to break silently; these are likely
  intended to be either private or public but are currently neither clearly.
- **Left as is (2026-10-01).** Publishing them would widen the framework's public
  surface for no caller's benefit, and making them formally private is a
  declaration move with no behaviour change. The test-only category is the
  deliberate bridge, and the test file's header comment says so.

### `MADMetaDataLocal` reports 100% uploaded/downloaded for a local file
- **Status:** Quirk (left as is — the impact claim was wrong)
- **Where:** `MADFileManager/Source/MADMetaDataLocal.m:130`
- **Behavior:** `-ubiquitousItemPercentUploaded` / `-ubiquitousItemPercentDownloaded`
  return `100.0` for a non-ubiquitous local file.
- **Why it matters:** The earlier "shows a full bar rather than N/A" claim is not
  true. The only production reader is
  `MADCollectionViewCellDocument.m:387-390`, which pairs each percentage with a
  guard — `isUploading` / `isDownloading`, both `NO` for a local item — and
  `+updateProgressView:active:percent:` hides the view and zeroes its progress
  when `active` is `NO` (`.m:60-64`). The value is never displayed.

### `MADFilesController -setFileCoordinator:` hands URLs where metadata is expected — crash
- **Status:** Open (found by test 2026-10-06; not fixed)
- **Where:** `MADFileManager/Source/MADFilesController.m:193-220` (the offending
  value at `:204`, the hand-over at `:208-212`)
- **Behavior:** Swapping coordinators reads the tracked list as
  `allURLs = [self.fileMetaDatum valueForKey:@"URL"]` — an array of `NSURL` — and
  then passes it straight in as `removedMetaDatum:`. Everything downstream of
  `-processContentChangesWithInsertedMetaDatum:removedMetaDatum:updatedMetaDatum:completion:`
  treats that argument as `MADMetaData`, and the first thing it does is build
  `[NSPredicate predicateWithFormat:@"URL in %@.URL", …]` and filter with it
  (`.m:474-478`). `NSURL` has no `URL` key, so the predicate raises
  `NSUnknownKeyException`.
- **Why it matters:** The raise happens on the delegate operation queue, so it is
  uncaught and takes the process down. It fires on any coordinator swap while at
  least one file is tracked (an empty list filters to nothing and survives).
  `-setFileCoordinator:` is called by the app's file-location manager when the
  storage setting changes; an empty list may be why this has not been seen.
- **Pinned by:** `MADFilesControllerTests`
  `-testSettingANewCoordinatorStopsTheOldOneAndStartsTheNewOne`, which can only
  exercise the empty case — the populated case terminates the test process. The
  test's header comment records it.
- **Fix sketch:** map the URLs to `MADMetaData` first
  (`-fileInfosByMappingURLs:` already exists at `.m:584`), or have the method take
  the tracked objects directly.

### `MADLocalFileCoordinator -removeFileAtURL:` reports the removal as an update
- **Status:** Open (found by test 2026-10-06; not fixed)
- **Where:** `MADFileManager/Source/MADLocalFileCoordinator.m:112-119`
- **Behavior:** The success branch builds `removes = @[URL]` and then calls
  `fileCoordinatorDidUpdateContentsWithInsertedURLs: removedURLs:updates
  updatedURLs:removes` — the `removes` and `updates` arrays are swapped. The
  delegate is told the file was *updated*, and `removedURLs` stays empty. The
  file is deleted either way.
- **Why it matters:** `MADFilesController` trusts the buckets: a removal reported
  as an update looks up the still-tracked entry and rewrites it in place
  (`.m:530-549`) instead of untracking it, so a file deleted through the
  coordinator stays in the browser list until a refresh notices a file-system
  difference. The same swapped call exists in
  `MADCloudFileCoordinator -createURLWithName:` (`.m:214-221`), where both arrays
  are empty and the inversion is inert.
- **Pinned by:** `MADLocalFileCoordinatorTests
  -testRemoveReportsTheURLAsUpdatedNotRemoved`.

### `MADLocalFileCoordinator -documentsDirectory` has no setter
- **Status:** Open (found by test 2026-10-06; not fixed)
- **Where:** `MADFileManager/Source/MADLocalFileCoordinator.m:38` (`@dynamic`)
  against `MADFileCoordinatorProtocol.h:18-19` (`readwrite, copy`)
- **Behavior:** The class declares the property `@dynamic` and implements only
  `-documentsDirectory` (`.m:206-209`). The setter the protocol promises is never
  provided, so `-setDocumentsDirectory:` raises `NSInvalidArgumentException`
  ("unrecognized selector") at the call site.
- **Why it matters:** The protocol is the only contract a caller sees; code that
  holds an `id <MADFileCoordinatorProtocol>` is entitled to write the property and
  will crash instead. `MADFilesController` only reads it today, and the app's
  writes go through the reader-side accessors, which is why it has not surfaced.
- **Pinned by:** `MADLocalFileCoordinatorTests -testDocumentsDirectoryHasNoSetter`
  (`-respondsToSelector:` plus the throwing call).

### `MADFilesController` accepts and ignores `sortComparator`
- **Status:** Quirk (left as is)
- **Where:** `MADFileManager/Source/MADFilesController.m:154-174`
- **Behavior:** `-initWithFileCoordinator:delegateQueue:sortComparator:` never
  stores or calls the block. Both class factories pass a file-static
  `sortComparator` (`.m:53`), and the controller's own ordering is
  `finderSortWithLocale` by `fileSystemName` (`.m:495-501`).
- **Why it matters:** A caller passing a comparator gets no warning and no effect;
  the parameter is a lie in the initializer's signature. The finder ordering is
  what the browser actually wants, so the block is dead weight rather than a wrong
  result.
- **Pinned by:** `MADFilesControllerTests -testTheSortComparatorArgumentIsIgnored`
  (a comparator that would keep the reverse order makes no difference).

### `MADFilesController` gates the renaming failure on the removing callback
- **Status:** Open (found by test 2026-10-06; not fixed)
- **Where:** `MADFileManager/Source/MADFilesController.m:405-416`
- **Behavior:** `-fileCoordinatorDidFailRenamingFileAtURL:withError:` puts
  `@selector(filesController:didFailRemovingFileInfo:withError:)` in the
  `respondsToSelector:` check but sends
  `filesController:didFailRenamingFileInfo:withError:`. A delegate that implements
  only the renaming callback — the natural choice — never hears about a rename
  failure; one that implements only the removing callback gets the renaming
  failure anyway.
- **Why it matters:** A failed rename is silent for the expected delegate shape.
- **Pinned by:** `MADFilesControllerTests
  -testRenamingFailureIsGatedOnTheRemovingCallback`.

### `+[MADFilesController getFileStorageLocationsForUbiquityIdentifier:…]` crosses its two URLs
- **Status:** Open (latent; found by test 2026-10-06)
- **Where:** `MADFileManager/Source/MADFilesController.m:136-137`
- **Behavior:** The completion block's parameters are `(cloudAvailable,
  documents, data)`, but the non-cloud branch answers
  `documents = [MADURLFactory newURLForLocalDataDirectoryForGroupIdentifier:…]`
  (the **Data** directory) and
  `data = [MADURLFactory newURLLocalDocumentsDirectoryForGroupIdentifier:…]`
  (the **Documents** directory).
- **Why it matters:** Latent today only because the sole caller —
  `MADFileLocationManager -setupFileStorageLocationsForCloud`
  (`MADExplorer/…/MADFileLocationManager.m:223`) — declares both as `__unused`. The
  first caller that trusts the labels gets the wrong directory.
- **Pinned by:** `MADFilesControllerTests
  -testStorageLocationsWithoutCloudAnswerLocalDirectories`.

### `MADLocalFileCoordinator` drops the removal when the last matching file goes away
- **Status:** Quirk (left as is — the guard predates the tests)
- **Where:** `MADFileManager/Source/MADLocalFileCoordinator.m:251`
- **Behavior:** `-processChangeToLocalDocumentsDirectory` wraps the whole
  insert/remove comparison in `if (localListURLs.count > 0)`. With no matching
  files left in the directory, no delegate callback is sent at all — not even for
  the removals that just happened. The coordinator also leaves
  `currentLocalContents` at its old value in that case.
- **Why it matters:** A browser that empties the document store this way is told
  nothing; the next refresh with any file present reports the removals then. It is
  the mirror of the `removeFileAtURL:` swap above: removals are the fragile path.
- **Pinned by:** `MADLocalFileCoordinatorTests
  -testRefreshIsSilentWhenTheLastMatchingFileIsGone`.

### `MADDirectoryMonitor`'s cancel handler dereferences a nil owner — SIGSEGV on dealloc
- **Status:** Open (found by test 2026-10-06; not fixed)
- **Where:** `MADFileManager/Source/MADDirectoryMonitor.m:99-104`
- **Behavior:** Both handlers load their owner weakly
  (`MADDirectoryMonitor __weak *weakself = self;` at `.m:70`) and then use it
  without a nil check.  The cancel handler does it with **direct ivar access**:

  ```objc
  dispatch_source_set_cancel_handler(self.directoryMonitorSource, ^{
      MADDirectoryMonitor *sself = weakself;
      close(sself->_fileDescriptor);          // *(int *)((void *)0 + 8)
      sself->_fileDescriptor = NotListening;
      sself.directoryMonitorSource = nil;
  });
  ```

  A message send to nil is harmless; `->` on nil is a load/store at address
  `offset` and faults.  `_fileDescriptor` sits at offset 8, which is exactly the
  fault address reported.
- **Why it matters:** A monitor that is released with its source still live (or
  still cancelling) crashes in the cancel handler after the owner is gone:
  `dispatch_source_cancel` → cancel callout → `sself->_fileDescriptor` →
  `EXC_BAD_ACCESS (SIGSEGV) KERN_INVALID_ADDRESS at 0x8`.  There is no way for
  the caller to avoid it other than keeping the monitor alive until the cancel
  handler has run, which no caller does.  The same missing guard leaves the
  event handler one weak-load away from `dispatch_source_get_data(NULL)`.
- **Fix sketch:** the cancel handler is the last user of the monitor, so it can
  capture `self` **strongly** — the handler already sets
  `directoryMonitorSource = nil`, which breaks the source→block→self→source
  cycle on the one and only cancel.  (A bare `if (sself == nil) return;` would
  stop the fault but leak the descriptor, which is why the handler exists.)
- **Pinned by:** the crash report above; `MADDirectoryMonitorTests` works around
  it everywhere (each monitor is stopped and the run loop drained before the
  test releases it — `-stopAndDrain:` and `-tearDown`).

### `MADCloudFileCoordinator -init…` writes `_documentsDirectory` through a weak self — SIGSEGV
- **Status:** Open (found by test 2026-10-06; not fixed)
- **Where:** `MADFileManager/Source/MADCloudFileCoordinator.m:74-79`
- **Behavior:** The initializer resolves the iCloud Documents directory
  asynchronously and assigns it with direct ivar access:

  ```objc
  MADCloudFileCoordinator __weak *wself = self;
  dispatch_barrier_async(self.documentsDirectoryQueue, ^{
      MADCloudFileCoordinator *sself = wself;
      sself->_documentsDirectory =            // objc_storeStrong(&nil->_documentsDirectory, …)
          [MADFileUtilities newURLForCloudDocumentsDirectoryForUbiquityID: identifier];
  });
  ```

  There is no nil check, and the assignment is an ARC store through
  `&sself->_documentsDirectory`.
- **Why it matters:** Any `MADCloudFileCoordinator` that is released before the
  queued barrier block runs crashes on that block: `EXC_BAD_ACCESS (SIGSEGV)
  KERN_INVALID_ADDRESS at 0x10` in
  `__80-[MADCloudFileCoordinator initWithPredicate:identifier:firstQueryUpdateHandler:]_block_invoke`.
  Building a cloud coordinator and letting it deallocate promptly — which is what
  the factory does for any short-lived caller — is enough.  The coordinator is
  normally retained by `MADFilesController` for the life of the browser, which
  hides it.
- **Fix sketch:** `if (sself == nil) return;`, or capture `self` strongly in the
  init block (the block is a one-shot assignment; there is no cycle to keep).
- **Pinned by:** the crash report above.  `MADCloudFileCoordinatorTests`,
  `MADFileCoordinatorTests`, and `MADFilesControllerTests` all keep every cloud
  coordinator alive and drain `documentsDirectoryQueue` before releasing it
  (`-tearDown`), which is the workaround, not the fix.

### `MADDirectoryMonitor`'s cancel handler dereferences a nil owner — SIGSEGV on dealloc
- **Status:** Quirk (left as is — logging and a silent no-op only)
- **Where:** `MADFileManager/Source/MADDirectoryMonitor.m:52`, `:73-96`
- **Behavior:** (1) `-startMonitoring` on a path that cannot be opened
  (`open(2)` fails, `.m:52`) returns without a source or an error — the monitor
  silently never observes anything. (2) The event handler switches on the raw
  `dispatch_source_get_data` bitmask, so an event carrying more than one flag
  (`WRITE|EXTEND`, common) falls through to `default` and logs "Untracked event."
  The delegate is still called.
- **Why it matters:** (1) is a setup error that will look like "the browser does
  not refresh"; (2) only costs a misleading log line.
- **Pinned by:** `MADDirectoryMonitorTests`
  `-testStartMonitoringAMissingDirectoryIsANoOp` and
  `-testObservesAChangeInTheMonitoredDirectory`.

---

## MADExplorer

> MADExplorer is almost entirely UI (collection-view cells, data sources, view
> controllers), which a logic test bundle cannot exercise. Its only non-UI logic
> is `MADStandard`, the file-size formatter below.

### `MADStandard -standardStringForFileSize:` uses decimal megabytes
- **Status:** Confirmed (quirk) — **left as is** (decimal MB is the house
  convention; the live tests pin `1.049 MB` for 2^20 bytes)
- **Where:** `MADExplorer/MADExplorerTests/MADStandardTests.m`
- **Behavior:** The scale is `1000000.0` (decimal MB) rather than `1048576.0`
  (binary MiB), so a `2^20`-byte file is reported as `1.049 MB` instead of
  `1.000 MB`.
- **Why it matters:** The number shown next to a file in the explorer won't match
  the binary megabytes that Finder / `NSFileManager` report.

### `MADStandard -standardStringForFileSize:` has dead code with a latent throw
- **Status:** Fixed
- **Where:** `MADExplorer/MADExplorer/MADStandard.mm`
- **Behavior:** The guard `if (filesize_str.length() <= range_end) { filesize_str.append(zero, range_end); }`
  is never taken for a `double` (the formatted string is always `dec_pos + 7`
  chars while `range_end` is `dec_pos + 4`). If it ever did execute, the two-arg
  `append(str, subpos)` overload would try to read the single-character `"0"` at
  `subpos >= 4` and throw `std::out_of_range`.
- **Why it matters:** Dead code that would crash if the input format ever changed;
  worth deleting or fixing the append argument count.
- **Now:** the guard pads to `range_end` with the `(count, char)` overload —
  `append(range_end - filesize_str.length(), '0')` — so it does what it reads as
  and cannot throw. The unused `zero` constant is gone.

### `MADStandard -standardStringForFileSize:` has no byte/kB fallback
- **Status:** Quirk — **left as is** (a file under ~500 bytes shows `0.000 MB`,
  pinned by `testTinyFileReportsZero`)
- **Where:** `MADExplorer/MADExplorerTests/MADStandardTests.m`
- **Behavior:** Any file under ~500 bytes formats as `0.000 MB`.
- **Why it matters:** Tiny example reports/documents show `0.000 MB` in the
  explorer rather than a byte or kilobyte figure.

### `MADStandard` hides `+standardStringForDouble:` / `+standardStringForUnsignedLong:`
- **Status:** Fixed
- **Where:** `MADExplorer/MADExplorer/MADStandard.mm` (vs `MADStandard.h`)
- **Behavior:** Both class methods are implemented but not declared in the public
  header; the tests reach them via a test-only category.
- **Why it matters:** Same hidden-API smell as the `MADFileUtilities` helpers.
- **Now:** both are declared in `MADStandard.h`, and
  `MADStandardTests.m`'s test-only category is gone.

---

## MADSqlite3

The `MADDataTypeUnknown → String`/`TEXT` coercions in `MADDatabaseSqlite3` are
intentional fallbacks and are covered by tests. One defect in this framework was
found by inspection rather than by a test and is recorded under "Already fixed
(for reference)": eight call sites passed a variable to `sqlite3_mprintf` as the
format string. The first two below were found while writing the write-port test
that proves the driver is decoupled from `MADDataTable`; the third was found by
the ingest benchmark, which is also what measures it. The fourth was found while
inventorying the static-library build for the CLI work, and is the only one here
that changed a file the application writes. The fifth took the application down and
was found from a crash log; it is the one entry here that is a crash rather than a
wrong answer.

### `fieldsForTable:` ran the tables query and returned tables as fields
- **Status:** Fixed
- **Where:** `MADSqlite3/Source/MADDatabaseSqlite3.m` (`-fieldsForTable:connection:error:`)
- **Behavior:** The method ran the same `sqlite_master` query as
  `-getTablesFromConnection:`, wrapped each row in a `MADDatabaseTable`, and
  returned those as the field list.  The schema-import chain sent the result
  straight into `RptqDatabaseSchemaField` factories, which crashed sending
  `fieldType` to a `MADDatabaseTable`.
- **Now:** the method runs `PRAGMA table_info("…")`, builds a `MADDatabaseField`
  per column, and maps the declared type through `+dataTypeForNativeType:` with
  the primary-key flag from the `pk` column.  Found and fixed by the
  create-document chain test (`testCreateDocumentChainImportsAChinookSchema`),
  which imports all eleven Chinook tables.
- **Found during the store migration.**

### `connectWithConnection:credentals:connectionError:` returned nil after connecting
- **Status:** Fixed
- **Where:** `MADSqlite3/Source/MADDatabaseSqlite3.m` (`-connectWithConnection:credentals:connectionError:`)
- **Behavior:** The driver opened the database and returned nil.  The create
  chain treats a nil connection object as a failed connection, so schema import
  aborted with "Failed to establish database connection for schema import (nil
  connection object)."
- **Now:** the driver returns itself as the handle; the callers that take a
  connection object pass it back to the table and field readers, which ignore
  it.  Found and fixed by the create-document chain test.
- **Found during the store migration.**

### `MADDataTableFast` stored an absolute cache URL that a container change invalidates

- **Status:** Fixed
- **Commit:** `d8de8ece0`
- **Where:** `MADSqlite3/Source/MADDataTableFast.m:304` (`-loadWithPlist:`), written at
  `:244` (`-copyPlist:`), `:226` (`-encodeWithCoder:`), `:206` (`-initWithCoder:`)
- **Behavior:** The `.mdcache` plist records `urlFastCache` as an absolute URL —
  `file:///…/Containers/Data/Application/<container-UUID>/Library/Caches/<tag>/<tag>.maddb`.
  `-loadWithPlist:` adopted it verbatim, so the cache was opened at the path named by
  the container that *wrote* the plist. An application's data-container UUID is not
  stable: a reinstall or a device restore allocates a new one and deletes the old
  directory. The stored URL then names a directory that does not exist, and
  `sqlite3_open_v2` with `SQLITE_OPEN_CREATE` cannot create a file where the directory
  is missing, so it returns `SQLITE_CANTOPEN`.
- **Why it mattered:** This is a crash, not a mis-read. `-openDatabaseWithFlags:`
  asserts on a failed open, and every document open reaches it —
  `MADocument -initWithFileURL:andDatabaseConnection:` → `loadFromCacheWithUrl:` →
  `-loadWithPlist:` → `-reopenDbConnection` → `-openDatabaseWithFlags:`. So the whole
  application failed on the first tap in the file explorer, with nothing but
  `openDatabaseWithFlags failed (unable to open database file).` Three distinct dead
  container UUIDs were found across the four caches on the simulator this was diagnosed
  from, so each reinstall had been re-arming it.
- **Now:** `-loadWithPlist:` adopts the stored URL only when its directory still exists.
  Otherwise it discards it, logs the missing directory, and lets `-urlFastCache`
  recompute a path under the cache directory in use now. `-openDatabaseWithFlags:` also
  names the path in its assert, which is what the original message withheld — the
  failure says only "unable to open database file", which identifies neither the file
  nor the reason.
- **Test:** `testLoadWithPlistDiscardsACacheUrlWhoseDirectoryIsGone` and
  `testLoadWithPlistKeepsACacheUrlWhoseDirectoryIsPresent` in
  `MADSqlite3/MADSqlite3Tests/MADDatabaseSqlite3DatabaseTests.m`. With the guard removed,
  the first reproduces the crash exactly: `*** Assertion failure in
  -[MADDatabaseSqlite3 openDatabaseWithFlags:] … (unable to open database file) for
  …/gone/gone.maddb.`
- **Format, now fixed too:** `-copyPlist:` and `-encodeWithCoder:` wrote the absolute
  URL, so reading a stale one was safe but writing one was still how the staleness got
  in. They record the file name alone now — `<tag>.maddb` — and
  `-cacheUrlForStoredValue:` resolves it against the cache directory in use when the
  plist is read, which is `-cacheDirectoryURL:`: the caller's directory, else the cache
  delegate's, else the application group's. A plist written by an older build still
  holds the absolute form, and that is honoured only while the directory it names
  exists, so existing caches are still read. `-initWithCoder:` goes through the same
  helper. Verified by reading a cache plist the CLI wrote:
  `"urlFastCache" => "7308922102201200.maddb"`.
- **Tests:** `testCopyPlistStoresTheCacheFileNameNotAnAbsoluteUrl` and
  `testLoadWithPlistResolvesAStoredFileNameInTheDirectoryInUseNow`, both in
  `MADDatabaseSqlite3DatabaseTests.m`. The second writes a plist against one cache
  directory and reads it against another, which is what an absolute URL could not
  survive. Both were confirmed to fail against the old write before being kept.

### `MADDataTableFast` left its row counter stale after an in-memory drop or delete
- **Status:** Fixed
- **Commit:** `850c32f51`
- **Where:** `MADSqlite3/Source/MADDataTableFast.m:799`, `:804`, `:818`, `:789`
- **Behavior:** `rowCounter` is the only thing `-count` and `-numberOfRows`
  consult (`:1216`, `:1222`), and none of `-dropTable`, `-dropTableName:`,
  `-deleteAll` or `-vacuumCacheDb` touched it. After any of the four the counter
  named a row count the file no longer held.
- **Why it mattered:** No caller could reach it — `-deleteAll` had no callers
  anywhere in the repository, and the other three are reached only from
  `-removeAllObjects`, which zeroes the counter itself — so no live path was
  broken. But `-count` is a *page cursor* to `MTTableController` (see the app
  section below), so the hazard was one new caller away from being live.
- **Now:** `-dropTable` and `-dropTableName:` zero the counter, as does
  `-deleteAll`. `-vacuumCacheDb` deliberately does not — VACUUM rewrites the file
  but keeps every row, and the source carries a comment saying so. `-dropTableName:`
  takes an arbitrary table name, so it zeroes the counter only when the table that
  went away is this one; dropping a foreign table must not touch this count.
- **Test:** `testFastTableDropTableZeroesRowCount`,
  `testFastTableDropForeignTableKeepsRowCount`,
  `testFastTableDeleteAllZeroesRowCount` and `testFastTableVacuumKeepsRowCount` in
  `MAD/MADTests/MADDataTableRegressionTests.m`, each driving one of the private
  methods directly. They call `-reopenDbConnection` first: `-endBulkInsert` closes
  the inserts connection and nulls its handle, so the mutations that send SQL
  through it cannot run until it is reopened. That is also what `-removeAllObjects`
  does.

### `MADDataTableFast -deleteAll` built its query with the wrong initializer
- **Status:** Fixed
- **Commit:** `850c32f51`
- **Where:** `MADSqlite3/Source/MADDataTableFast.m:818`
- **Behavior:** `-deleteAll` sent `[[MADQueryCacheDeleteAllFromTable alloc]
  initWithObject:tableName]`. `-initWithObject:` expects the parameters
  *dictionary* and subscripts it, so an `NSString` raised
  `-[NSTaggedPointerString objectForKeyedSubscript:]` on the first row. The sqlite
  driver's own `-beginBulkInsert` uses `-initWithTableName:` for exactly this.
- **Why it mattered:** Nothing called the method, which is why nothing had ever
  hit it — the same reason the counter drift above went unnoticed. It would have
  raised on the first call from any future caller.
- **Now:** `-initWithTableName:`.
- **Test:** `testFastTableDeleteAllZeroesRowCount`.

### The bulk-insert row loop held the whole result set in autoreleased memory
- **Status:** Fixed
- **Commit:** `94a8d2068`, `3fbfb800b`
- **Where:** `MADSqlite3/Source/MADDataTableFast.m:618`,
  `MADSqlite3/Source/MADQueryCacheAddRow.m:51`
- **Behavior:** `-addRowWithDataForFieldKeys:` is the write port's per-row entry,
  and the insert path below it autoreleases on every call — the binding
  statement builds autoreleased objects per column. There was no pool at this
  granularity: the method carried the author's
  `// FIXME: Maybe wrap in autorelease block.` with the pool written out and
  commented off at both ends, and no caller established one either, so the
  objects survived until the caller's own loop ended. A second, independent
  waste sat in the same path: `MADQueryCacheAddRow -update` runs once per row
  and rebuilt the entire `INSERT INTO … VALUES (?, ?, …)` statement each time —
  a string nothing reads after the first row's prepare — and replaced its
  bindings array rather than emptying the one it had.
- **Why it mattered:** A report is meant to hold hundreds of thousands of rows,
  and this is the path that puts them in. The spike is transient rather than a
  leak, but transient is enough: it is resident memory at the moment the process
  is most loaded, which is the shape of a jetsam kill. Reached from
  `MADDatabaseSqlite3.m:535`, the sqlite driver's own row loop, so every report
  refresh paid it.
- **Now:** `-addRowWithDataForFieldKeys:` opens an `@autoreleasepool` around the
  row, and `-update` keeps its bindings array and builds `_sql` once, guarded on
  `_sql == nil` the same way `_sqlColumnPart` beside it already was. The pool
  belongs in the table rather than the caller because that is the only place
  that knows a row has ended, and because the caller is a generic loop over a
  `<MADDataTableWriting>` with no reason to know it needs one.
- **Test:** `testIngestSpikeStaysBounded` in
  `MADSqlite3/MADSqlite3Tests/MADDataTableFastBenchmarkTests.m`, which skips
  unless built with `MAD_BENCH_ROWS`. At 200000 rows the spike fell from 49.1 MB
  to 2.5 MB (256 → 13 bytes per row) and ingest from 1.156 s to 0.975 s; the
  pool costs about 2%, within the run-to-run noise, so the path ends faster than
  it started. `testRetainedFootprintDoesNotScaleWithRowCount` pins the separate
  question of whether anything is held after the pool drains, and reports 0.0 MB
  growth for a second table of 200000 more rows.

### The SQLite engine was compiled with one of the twenty options the build script declared
- **Status:** Fixed
- **Commit:** `26ca18ff7`
- **Where:** `Compressor/build_sqlite3.sh:25`,
  `MADSqlite3/MADSqlite3.xcodeproj/project.pbxproj:571`, `:630`
- **Behavior:** `build_sqlite3.sh` declared twenty compile options for SQLite — FTS5,
  STAT4, column metadata, an 8192-byte page size, `DQS=0`, `TEMP_STORE=2` and so on —
  but they were never applied to the engine that ships. `sqlite3.c` is not built into a
  `.a`; it is a source file of the `MADSqlite3` target (`project.pbxproj:494`), and that
  target passed exactly one define, `SQLITE_ENABLE_COLUMN_METADATA=1`. Every other
  option fell back to the amalgamation's own `#ifndef` default.
- **Why it mattered:** For one of them, because it changes the file on disk. SQLite
  reports its options through a table built with `#ifdef` guards (`sqlite3.c:22411`), and
  the built framework listed `DEFAULT_PAGE_SIZE=4096` and `ENABLE_COLUMN_METADATA` and
  nothing else. Page size is recorded in the header of every database written, so the
  engine writing every `.maddb` cache produced a different file than the build script
  intended — and a second build (the macOS or CLI work, `LIBRARIES.md`) that *did*
  honour the script would have written caches this app reads but never wrote. For the
  rest, because the features were simply absent: FTS5 could never be used, its code
  never having been compiled in.
- **Now:** the options live in `Compressor/sqlite3.xcconfig`, named as the base
  configuration of the `MADSqlite3` target's Debug and Release, and read by
  `build_sqlite3.sh` for its own CFLAGS. One list, two consumers, so they cannot drift
  apart again. Rebuilt, the engine reports `DEFAULT_PAGE_SIZE=8192`, `DQS=0`,
  `ENABLE_FTS5`, `ENABLE_STAT4`, `TEMP_STORE=2` and `THREADSAFE=1`, and defines 599
  fts5 symbols where the guards above say it defined none.
- **Then (Compressor rework, 2026-10-04):** the two consumers became one. The
  sqlite3 recipe (`Compressor/lib/recipes/sqlite3.sh`) generates the amalgamation
  and compiles `libsqlite3.a` per slice with these defines, and `MADSqlite3` links
  that archive from `sqlite3.xcframework` — the target no longer compiles `sqlite3.c`
  and no longer names the xcconfig as its base configuration, so the two lists
  *cannot* disagree again. Verified against the rebuilt framework: the
  compile-option strings are all present and `sqlite3Fts5Init` is linked. The
  fts5 *symbol count* dropped from 599 to 336 because the archive is compiled
  `-Os` (the old count was a Debug `-O0` binary; at `-Os` the optimizer inlines
  away most of fts5's static functions) — the presence check is now the init
  symbol plus the option strings, not the count.
- **Test:** the `MADSqlite3` suite — 77 tests, 5 skipped, 0 failures — which did *not*
  cover the risk this option carried. `DQS=0` removes SQLite's habit of reading an
  unknown double-quoted token as a string literal, and an earlier version of this entry
  waved that through, claiming the query builder "quotes identifiers and binds values
  through `?`, so it was already written the way `DQS=0` requires". **That claim was
  wrong.** `MADQueryPredicate.m:81` and `MADQueryCacheSelectGroupKeys.m:55` each wrap a
  *value* in double quotes and neither binds, so this commit silently stopped every
  filtered report from refreshing. See the entry under `## MAD (framework)`. The check
  that catches it is `mad refresh` over the sample documents, and `London.mad` is the
  case that shows it: 0 rows at `DQS=0`, 76 rows at `DQS=3`, nothing else changed. Both
  quoting sites have since been fixed through `-newSafeLiteral:` (commit `0c187aca3`);
  that entry records what changed and the one path deliberately left open.
- **Also found, by compiling the list for the first time:**
  `SQLITE_OMIT_DECLTYPE` and `SQLITE_ENABLE_COLUMN_METADATA` are mutually exclusive —
  the amalgamation refuses both, *"Must not define both SQLITE_OMIT_DECLTYPE and
  SQLITE_ENABLE_COLUMN_METADATA"*, since column metadata is built on
  `sqlite3_column_decltype`. The script asked for both, which could never have built,
  and that is itself evidence the flags had not been in effect.
  `SQLITE_ENABLE_JSON1` was dropped as a no-op on 3.49, JSON having been part of the
  core since 3.38, and `-DNOMINMAX` as a Visual C++ artifact.

### `MADArrayCaching -isEmpty` and `-count` were wrong for an empty cache
- **Status:** Fixed
- **Where:** `MADSqlite3/Source/MADArrayCaching.m`
- **Behavior:** `-isEmpty` returned `_numberOfRows > 0` — YES when the cache had rows,
  the inverse of its name. `-count` computed `max(ci) + 1`, but on an empty table the
  `SELECT ci ORDER BY ci DESC LIMIT 1` returns `SQLITE_DONE` and
  `sqlite3_column_int64` on a done statement reads garbage, so an empty cache reported
  1 row instead of 0. Both are the render cache (`MADReportFormatter`'s `.madac`
  stores), where `count` is read during layout.
- **Why it mattered:** `-isEmpty` was dead code (no caller), a latent trap. `-count`
  only misbehaved at the empty/edge case, which the normal add-then-read flow never
  hit — but a fresh cache asked for its count before any add would have reported 1.
- **Now:** `-isEmpty` is `_numberOfRows == 0` and exposed as a readonly property;
  `-count` returns 0 on `SQLITE_DONE`. The dead `readDataAtIndex:` / `writeData:`
  pair (raw-`NSData` leftovers with a type bug in `readDataAtIndex:`) was deleted, and
  the duplicated `MTArrayCached*` constants were consolidated into
  `MADArrayCaching.h`. The hot `objectAtIndex:` also gained a per-element memory cache
  so repeated reads do not re-run the SQLite round-trip and the unarchive.
- **Test:** `MADSqlite3Tests MADDatabaseSqlite3DatabaseTests
  testArrayCachingIsEmptyAndCountForEmpty` and
  `testArrayCachingRepeatedReadsReturnTheCachedObject`.

### `MADDataTableFast`'s read transactions crash without a selects database
- **Status:** Confirmed (found by a test that made the call)
- **Where:** `MADSqlite3/Source/MADDataTableFast.m:1062-1082`
- **Behavior:** `-beginReadTransaction` and `-commitReadTransaction` guard on
  `self.databaseForSelects->_database == NULL`, but a table built without a cache
  directory or cache delegate has `databaseForSelects == nil`: the ivar read through
  the nil object crashes before the handle guard is reached.  Constructing such a table
  and calling the pair took the test process down; the test now pins only the
  precondition (`databaseForSelects` is nil).
- **Why it matters:** The renderer's draw loop calls the pair around every page draw;
  any fast table that reaches a draw without a cache directory takes the app down.
- **Test:** `MADDataTableFastSelectTests testReadTransactionsWithoutASelectsDatabaseAreNotSafe`
  (precondition only -- the call itself is the crash).

### `MADDatabaseSqlite3 +databaseResultValueCast:…` frees sqlite's own text pointer
- **Status:** Confirmed (latent -- no callers in-tree)
- **Where:** `MADSqlite3/Source/MADDatabaseSqlite3.m:1288` and `:1313`
  (`free((char *)text)` on the pointer `sqlite3_column_text` returned)
- **Behavior:** The pointer sqlite3 hands back belongs to the statement and stays valid
  only until the next step/reset/finalize; freeing it corrupts the allocator (and
  sqlite's own buffer bookkeeping) rather than doing anything useful.  The untyped
  sibling `+databaseResultValue:columnNumber:` -- the hot path -- does not free.
- **Why it matters:** The method is public but has no callers today, so this is latent;
  the first caller that reads a text column through it gets heap corruption.
- **Test:** none for the text-family branches, deliberately: the failure mode is memory
  corruption.  `MADDatabaseSqlite3ResultValueTests` covers the numeric, blob and
  null/unknown branches, which are safe.

### `MADDatabaseResultValue` is a dead near-copy of MADDatabaseSqlite3's factories
- **Status:** Quirk (dead code -- left as is)
- **Where:** `MADSqlite3/Source/MADDatabaseResultValue.m` (in no target's Sources
  phase), versus `MADDatabaseSqlite3.m:1206-1319`
- **Behavior:** The file implements the same two result-value factories as the live
  MADDatabaseSqlite3 class methods (minus the stray `free`), but it is in no target, so
  the class is in no binary -- a test that imports the header fails at link with
  "Undefined symbol: _OBJC_CLASS_$_MADDatabaseResultValue" (verified).  Its
  `-copyWithZone:` also throws unconditionally while the header advertises
  `<NSCopying>`.
- **Why it matters:** A reader can pick the dead file as the place to fix result
  reading and watch their fix never link; the two copies have already drifted (the
  `free`).  Deleting one and keeping the other is the real fix.
- **Test:** none possible -- the class is not linked.  `MADDatabaseSqlite3ResultValueTests`
  covers the live copies.

### `MADDataTableFast -whereClauseForGroupKeys:` indexes past the sort descriptors
- **Status:** Confirmed (latent)
- **Where:** `MADSqlite3/Source/MADDataTableFast.m:1167-1182`
- **Behavior:** The loop walks the group keys and reads `self.sortDescriptors[i]` at the
  same index; with fewer sort descriptors than group keys it walks off the end of the
  array and raises `NSRangeException`.  The pairing is also purely positional -- the
  group keys' values are matched to descriptors by index, not by any key lookup.
- **Why it matters:** The call comes from the group-key cache path
  (`-objectsForGroupKeys:`), where the two arrays are built from different sources; a
  mismatch is a crash rather than an empty clause.
- **Test:** `MADDataTableFastSelectTests testFewerSortDescriptorsThanGroupKeysRaises`
  (and the positional-pairing behavior by
  `testGroupKeysProducePositionalColumnValuePairs`).

### `MADArrayCachingEnumerator` is in no target
- **Status:** Quirk (dead file -- left as is)
- **Where:** `MADSqlite3/Source/MADArrayCachingEnumerator.m` (in no Sources phase; the
  header says so itself)
- **Behavior:** The header is in the project and declares an `NSEnumerator` over a cache
  URL; the implementation is not compiled anywhere, so the class is in no binary and
  cannot be linked against.  The header's comment calls it unfinished and asks for
  investigation.
- **Test:** none possible -- like `MADDatabaseResultValue`, the class does not exist at
  link time.  Verified with `MADArrayCachingEnumerator.m in Sources` == 0.

---


## MADBarcodes

### MTBarcode's type-name dictionary has a duplicate key
- **Status:** Open -- documented; one label is unreachable.
- **What:** The dictionary literal built in `MTBarcode.m` uses both
  `@(MTBarcodeTypeEan14)` (`:693`) and `@BARCODE_EAN14` (`:719`); the enum aliases the zint
  macro, so both box the value 72 and the second entry silently replaces the first --
  "Code 128 (EAN-14)" can never be returned.
- **Where:** `MADBarcodes/MADBarcodes/MADBarcodes/MTBarcode.m:693,719`.
- **Evidence:** `-Wobjc-dictionary-duplicate-keys`.

### Two symbology classes initialize with another class's type
- **Status:** Confirmed (latent -- nothing in-tree builds either symbology today)
- **Where:** `MADBarcodes/MADBarcodes/MADBarcodes/MTBarcodeQrCodeIso18004.m` (init and
  `+type` both return `MTBarcodeTypeOneCode`) and
  `MADBarcodes/MADBarcodes/MADBarcodes/MTBarcodeCode128Iso15417.m:145-161`
  (`MTBarcodeCode128Ean128`'s init assigns `[MTBarcodeCode128Hibc type]` -- HIBC Code
  128 -- while its `+type` says `MTBarcodeTypeEAN128`)
- **Behavior:** `+[MTBarcode newBarcodeWithType:MTBarcodeTypeQrcode]` builds an
  `MTBarcodeQrCodeIso18004` whose `barcodeType` is `MTBarcodeTypeOneCode`; the factory's
  `MTBarcodeTypeEAN128` case builds an `MTBarcodeCode128Ean128` whose `barcodeType` is
  `MTBarcodeTypeHibc128`.  `-drawInRect:` passes the instance's type straight to
  `barcode->symbology`, so each object draws a symbol other than the one it is named
  for -- QR code → USPS Intelligent Mail, GS1-128 → HIBC Code 128.
- **Why it matters:** Any feature that asks for a QR code or a GS1-128 barcode gets the
  wrong symbology and the wrong payload validation.  The exhaustive factory matrix found
  the second one; the other 63 mapped types round-trip correctly.
- **Test:** `MTBarcodeSymbologyTests testQrCodeClassClaimsTheOneCodeType` and
  `testEan128ClassClaimsTheHibcType`, with
  `testEveryMappedTypeRoundTripsExceptTheTwoKnownMismatches` covering the rest.

### `MTBarcodeInternationalStandardBookNumberIsbn +type` calls itself
- **Status:** Confirmed (latent -- no caller in-tree)
- **Where:** `MADBarcodes/MADBarcodes/MADBarcodes/MTBarcodeInternationalStandardBookNumberIsbn.m`
- **Behavior:** The class method's body is
  `return [MTBarcodeInternationalStandardBookNumberIsbn type];` -- itself, so any call
  recurses until the stack is exhausted.  The initializer is fine (it assigns
  `MTBarcodeTypeIsbnX` directly), so the factory path works; only the class-method
  accessor is a trap.
- **Why it matters:** A generic caller enumerating symbology classes for their `+type`
  (the obvious way to build a picker) takes the process down on the ISBN entry.
- **Test:** `MTBarcodeSymbologyTests testIsbnClassInitializesToItsOwnType` exercises the
  factory path only; `+type` is deliberately not called.

### `MTBarcode`'s NSCoding round trip loses everything
- **Status:** Quirk (broken by construction -- left as is)
- **Where:** `MADBarcodes/MADBarcodes/MADBarcodes/MTBarcode.m:376-408`
- **Behavior:** `-encodeWithCoder:` writes every property under the same empty key
  (`@""`), so only the last value survives in the archive; `-initWithCoder:` ignores the
  decoder entirely and just calls `[super init]`.  A decoded barcode is therefore a
  default instance of the right class -- not even the subclass's `-init` defaults apply,
  because `[super init]` skips them.  The class conforms to `NSCoding`, not
  `NSSecureCoding`, so secure archiving rejects it outright.
- **Why it matters:** Nothing archives a barcode today, so this is latent; it would bite
  the first time one is persisted.
- **Test:** `MTBarcodeTests testNSCodingRoundTripLosesTheState`.

### `MTBarcode -drawInRect:` copies user input into `primary[128]` unchecked
- **Status:** Confirmed (crash/memory-corruption risk -- no test)
- **Where:** `MADBarcodes/MADBarcodes/MADBarcodes/MTBarcode.m:492`
  (`strcpy(barcode->primary, primaryData)`), against
  `Compressor/library/zint/include/zint.h:121` (`char primary[128]`)
- **Behavior:** When `has2dComponentEnabled` is on, the user's second input is copied
  with `strcpy` into zint's fixed 128-byte `primary` buffer -- no length check ahead of
  it, unlike the main payload which goes through `ZBarcode_Encode_and_Buffer`'s
  length-taking API.
- **Why it matters:** A primary-data string of 128 bytes or more overruns the struct.
  Not exercised in tests: the failure mode is memory corruption, not an assertion.
- **Test:** none, deliberately.

### `MTBarcodeView` is the framework's one manual-retain-release file
- **Status:** Quirk (left as is)
- **Where:** `MADBarcodes/MADBarcodes/MADBarcodes/MTBarcodeView.m` (compiled with
  `-fno-objc-arc`), `MTBarcodeViewTests`
- **Behavior:** The project is ARC, but this one file keeps a `-dealloc` that releases
  `_barcode` and calls `[super dealloc]`, so it must stay `-fno-objc-arc`.  Its
  `-initWithFrame:` asserts "Don't you dare!", and `UIView -init` forwards there, so the
  view is only constructible from a storyboard (`-initWithCoder:`); a logic test cannot
  build one, which is why `MTBarcodeViewTests` pins the constructor contract and the
  property's declared storage instead of behaviour.
- **Test:** `MTBarcodeViewTests testProgrammaticConstructionIsRefused` and
  `testBarcodePropertyIsAnInstanceOfMTBarcode`.

## MADMySQL

Covered by an offline suite (`MADMySQLTests.m`) plus a live suite
(`MADMySQLLiveTests.m`) that runs against the development instance in
`DEVELOPER.md`. The live suite is the only way to reach `MysqlConnection`,
`MysqlFetch` and `MysqlFetch+DataTable`, which are thin wrappers over
libmysqlclient; it skips rather than fails when no server is reachable.

### `MysqlFetch+DataTable`: no non-SELECT statement could ever execute
- **Status:** Fixed
- **Where:** `MADMySQL/Source/MysqlFetch+DataTable.m`
- **Behavior:** `mysql_stmt_bind_result` was called unconditionally. For any
  statement with `field_count == 0` — every `INSERT`, `UPDATE`, `DELETE`,
  `CREATE`, `DROP` — it fails client-side with code 3534, which aborted the call
  before `mysql_stmt_execute` was reached. All DDL and DML through `MysqlFetch`
  silently did nothing.
- **Why it matters:** `MADDatabaseMySQL -executeSQL:...` and the
  `MysqlInsert`/`MysqlUpdate`/`MysqlDelete`/`MysqlTruncate` builders all route
  through this path, so the whole write side of the MySQL driver was dead.

### `MysqlFetch+DataTable`: row loop spun forever on a fetch error
- **Status:** Fixed
- **Where:** `MADMySQL/Source/MysqlFetch+DataTable.m`
- **Behavior:** The row loop terminated only on `MYSQL_NO_DATA`. `mysql_stmt_fetch`
  returns `1` (`stmt_read_row_no_result_set` → `set_stmt_error`) rather than
  `MYSQL_NO_DATA` for a statement with no result set, so the loop never exited.
  Found by stack-sampling a test run pinned at 98% CPU.
- **Why it matters:** One bad statement hung the app thread with no error and no
  way out. The loop now ends on any result that is neither a row nor a truncation.

### `MysqlFetch+DataTable`: `MYSQL_TYPE_INT24` (MEDIUMINT) read 4 bytes as 8
- **Status:** Fixed
- **Where:** `MADMySQL/Source/MysqlFetch+DataTable.m`, `-fetchResultsFromConnection:`
- **Behavior:** The `MYSQL_TYPE_INT24` case had no `break` and fell through into
  the `MYSQL_TYPE_DECIMAL`/`MYSQL_TYPE_DOUBLE` case, which re-read the 4-byte
  `int` buffer as an 8-byte `double`. That is a heap over-read, and it overwrote
  the correct value with a garbage one.
- **Why it matters:** MEDIUMINT columns returned nonsense. Now covered live by a
  round-trip through a probe table.

### `MysqlFetch+DataTable`: bind and execute failures were never reported
- **Status:** Fixed
- **Where:** `MADMySQL/Source/MysqlFetch+DataTable.m`, `-fetchWithCommand:...`
- **Behavior:** Both failure branches built an `NSError` but never assigned it to
  the caller's `*error` out-parameter, so a failed bind or execute was
  indistinguishable from success. The nil-connection branch had the same problem.
- **Why it matters:** This is what made the DDL bug above invisible for so long:
  the statement did not run, and nothing said so.

### `MysqlFetch+DataTable`: `MYSQL_TYPE_NULL` left its out-parameters uninitialized
- **Status:** Fixed
- **Where:** `MADMySQL/Source/MysqlFetch+DataTable.m`, `-bindDataForStatement:andField:`
- **Behavior:** The `MYSQL_TYPE_NULL` case set only `buffer_type` and `buffer`,
  then fell through into `default:` and fired `NSAssert(NO, ...)`. The `length`,
  `error` and `is_null` pointers were left as uninitialized stack garbage, and the
  row loop dereferences `*bindings[x].is_null`.
- **Why it matters:** `SELECT NULL` — a literal `NULL` in any ad hoc query —
  asserted in debug builds and dereferenced a wild pointer in release.

### `MysqlFetch+DataTable`: bindings and statement leaked on the error paths
- **Status:** Fixed
- **Where:** `MADMySQL/Source/MysqlFetch+DataTable.m`, `-fetchWithCommand:...`
- **Behavior:** The `free()` calls and `mysql_stmt_close` sat inside the
  success-only branch, so a failed bind or execute leaked the `calloc`'d binding
  buffers and the `MYSQL_STMT` on every call.
- **Why it matters:** Leaks per failed statement. Became reachable once failing
  DML was able to run at all.

### `MysqlFetch`: `mySQLTypeForType` returned wrong names for three types
- **Status:** Fixed
- **Where:** `MADMySQL/Source/MysqlFetch.m`
- **Behavior:** `MYSQL_TYPE_MEDIUM_BLOB` and `MYSQL_TYPE_LONG_BLOB` both returned
  `"MYSQL_TYPE_DECIMAL"` (copy-paste), and `MYSQL_TYPE_LONGLONG` had no case at
  all and fell through to `"Unknown"`.
- **Why it matters:** Diagnostics only, but this is the string in the
  `NSAssert` message for unmapped types, so it actively misleads debugging.

### `MADDataTypeMySQL` mapping is lossy for three types
- **Status:** Fixed (all three decided — two corrected, one kept on purpose)
- **Where:** `MADMySQL/Source/MADDataTypeMySQL.m`
- **Behavior:** `MYSQL_TYPE_TIME` mapped to `MADDataTypeDateTime` (not the dedicated
  `MADDataTypeTime`); `MYSQL_TYPE_NULL` maps to `MADDataTypeNumber` (not
  `MADDataTypeNull`); `MYSQL_TYPE_INT24` mapped to `MADDataTypeInteger` (not
  `MADDataTypeInt24`). All three dedicated enum cases exist.
- **Caller analysis (2026-10-01), and the decision for each:**
  - **INT24 — corrected.** Every consumer groups `MADDataTypeInt24` with
    `MADDataTypeInteger` (`MADDatabaseField.m -isDataTypeNumeric`, the sqlite3 bind
    switch, `RptqDocumentElement+Extras.m:1074` value formatting), so using the
    dedicated case is behaviour-neutral and more accurate. Tests updated:
    `MADMySQLTests.m`, `MADMySQLLiveTests.m:594`.
  - **TIME — corrected.** `MYSQL_TYPE_TIME` now maps to `MADDataTypeTime`. The
    mapping was reachable (`MADDatabaseMySQL.m:247` sets every schema field's
    `fieldType` from it) and wrong in a way that showed: `MysqlFetch+DataTable.m:431`
    builds the value from hour/minute/second alone, so the `NSDate` carries whatever
    date the calendar defaults to, and `RptqDocumentElement+Extras.m:1008-1076`
    rendered `MADDataTypeDateTime` through `dateTimeformatter` — a date part the value
    never had. `MADDataTypeTime` is the live case, not a dormant one: the SQL Server
    driver has produced it since long before this and its live suite asserts it
    (`MADDatabaseSQLServer.m:174`, `:251`), so the clock-only branch is exercised.
    The only user-visible change is that a MySQL TIME column now reads as a clock
    rather than "1/1/01, 1:45 PM". Test updated: `MADMySQLTests.m`.
  - **NULL — kept, on purpose.** `MYSQL_TYPE_NULL` stays `MADDataTypeNumber`.
    `MADDataTypeNull` is not a column type at all: it is the *binding* null,
    produced by `MADDatabaseDataBinding.m:141`/`:157` for a null parameter and
    consumed by `MADQuery+Sqlite3.m:66`. It has no display case in
    `RptqDatabaseSchemaField+Extras.m`, so a schema field carrying it renders as
    "Type 24" (`MADRptqDatabaseTests.m:45`). A column whose native type is NULL can
    never hold a value, so the mapping only chooses a schema label and a formatting
    branch, and `MADDataTypeNull` would be wrong for both. This is a decision, not a
    deferral. Pinned by `MADMySQLTests.m` `-testDataTypeForNativeTypeMapsNullToNumber`.

### `MysqlFetch+DataTable` comment claims SMALLINT/MEDIUMINT/BIT are unsupported
- **Status:** Fixed
- **Where:** `MADMySQL/Source/MysqlFetch+DataTable.m:139`
- **Behavior:** The comment block above the binding loop says these types are
  "not handled currently - exception will occur if used", but all three have
  `bindDataForStatement:` cases and fetch cases and work correctly.
- **Why it matters:** The comment discourages using types that are fine.
- **Now:** the three lines name the binding each type actually goes through
  (`MYSQL_TYPE_SHORT`, `MYSQL_TYPE_INT24`, `MYSQL_TYPE_BIT`), matching the
  comment's own style for the entries above them.

### A backslash in a MySQL literal is an escape character, so ANSI quoting alone is wrong
- **Status:** Fixed
- **Where:** `MADMySQL/Source/MADDatabaseMySQL.m` (`-newSafeLiteral:`, and the
  connection lifetime in `-connectWithConnection:credentals:connectionError:`,
  `-executeSQL:fieldKeys:onConnection:intoResultTable:withError:`,
  `-executeQuery:withDataTable:andError:`, `-getTables:` and `-closeConnection:`)
- **Behavior:** `-newSafeLiteral:` inherited the base's ANSI quoting from `MADDatabase`
  — `'…'` with the interior quote doubled — which is right for SQLite and for T-SQL but
  not for MySQL, where a backslash inside a literal is an escape character. The value
  `C:\temp` was written as `'C:\temp'` and read back by the server as `C:<TAB>emp`.
  Measured, not reasoned about: the failure output of the test below prints
  `("C:\temp") is not equal to ("C:	emp")` with the tab in it. The escape was recorded in
  the `MADQueryPredicate` / `MADQueryCacheSelectGroupKeys` entry above and left open there
  because the fix needed something this driver did not have.
- **Why it matters:** `mysql_real_escape_string` is the only thing that knows what a given
  session makes of a backslash, and it needs a live connection. This driver opened a
  connection per query and let it go without ever keeping it on `self`, so by the time the
  SQL builder ran `-newSafeLiteral:` there was nothing to ask. Every filter on a value
  containing a backslash — a UNC path, a Windows path, a regular expression — silently
  compared against a mangled string, and a value crafted to end its own literal had
  nothing stopping it.
- **Now:** the connection is held on `self` for as long as the query is being built and
  run: `-connectWithConnection:credentals:connectionError:` keeps the session it opened,
  and the query entry points that came through it let it go again — `-executeSQL:…`,
  `-executeQuery:withDataTable:andError:`, `-getTables:` and `-closeConnection:`, each
  guarded by `dbconn == self.liveConnection` so a connection the driver does not own is
  never dropped. The driver still holds no idle connection; only the window between
  opening and running changed. `-newSafeLiteral:` escapes through that session when it is
  there, and falls back to the base when it is not (SQL built with no session open, such
  as a preview that never connects), which is what the driver emitted before and is no
  worse for such a value than it ever was. The handle is still freed by
  `MysqlConnection -dealloc`: `mysql_init` is handed memory this side `calloc`'d, so the
  client's `free_me` is false and `mysql_close` does not free it.
- **Test:** `MADMySQLLiveTests testNewSafeLiteralEscapesABackslashThroughTheLiveSession`
  and `testNewSafeLiteralEscapesAnApostropheThroughTheLiveSession`. Each connects the way
  a query does, asks the driver for the literal and then has the server read it back —
  `SELECT <literal> AS v` — because only the server's reading proves the escape. Both were
  confirmed to fail against the old behaviour, printing the tab. The offline
  `MADMySQLTests testNewSafeLiteralWithoutASessionFallsBackToAnsiQuoting` pins the
  no-session path, backslash and all, so the limitation is stated rather than implied.

### `MysqlUpdate -execute` raises an out-of-bounds string exception instead of its own error
- **Status:** Open (found by test 2026-10-06; not fixed)
- **Where:** `MADMySQL/Source/MysqlUpdate.m:70` (the column list) and `:130` (the qualifier)
- **Behavior:** Both buffers are built with a leading separator and then trimmed with
  `deleteCharactersInRange:NSMakeRange(0, 2)` / `NSMakeRange(0, 4)`.  Nothing forces
  either buffer to have that many characters:

  - no `rowData` (or an empty dictionary) → the column list is still empty → the
    two-character delete raises `NSInvalidArgumentException` ("Range or index out of
    bounds");
  - `rowData` but no `qualifier` → the WHERE clause is still empty → the four-character
    delete raises the same way.

  The class intends to report "table must be specified" (it does, for a missing table)
  and needs the equivalent for a missing qualifier, but neither guard is reached.
- **Why it matters:** An update built without a qualifier is the classic "forgot the
  WHERE clause" mistake; instead of a diagnostic it takes the process down with an
  exception that names `__NSCFString`, not the caller's mistake.  (Losing the qualifier
  *silently* would be worse — the error is the point.)
- **Test:** `MysqlUpdateTests testExecuteWithoutRowDataRaisesAnInvalidArgumentException`
  and `testExecuteWithAnEmptyRowDataDictionaryRaisesTheSameWay` (offline), plus
  `MADMySQLLiveTests testUpdateWithoutAQualifierRaisesAnInvalidArgumentException` — the
  live one because the row-data path escapes through the session before it reaches the
  qualifier delete, so it cannot be reproduced without a server.

### `MysqlConnection`'s transaction toggles crash on a connection with no handle
- **Status:** Confirmed (latent -- no caller builds such a connection)
- **Where:** `MADMySQL/Source/MysqlConnection.m:214-232` (`enableTransactions`,
  `disableTransactions`, and the commit/rollback pair beside them)
- **Behavior:** These call `mysql_autocommit(_connection, 0)` / `mysql_commit` /
  `mysql_rollback` without checking the handle.  `mysql_autocommit` dereferences it, so
  `[[MysqlConnection alloc] init]` followed by `-enableTransactions` crashes the process
  (verified: the test process died at that call, with no exception to catch).
- **Why it matters:** Only latent.  Every production path gets its connection from
  `+connectToServer:…`, which answers `nil` rather than a handle-less object, and no
  in-tree caller invokes the transaction methods yet — they are API for the query cache
  and the portable store.  The trap is that the class is `init`-able and looks usable;
  note that the neighbouring accessors (`-errorNumber`, `-errorText`) *are* NULL-safe,
  which is what makes the omission look inconsistent rather than deliberate.
- **Test:** `MADMySQLTests testErrorAccessorsOnAConnectionWithoutAServer` and
  `testTransactionsFlagStartsOff` pin the safe half.  The crash itself is not asserted —
  it terminates the test process, so there is nothing to catch.

### `MysqlInsert -execute` reports `ULONG_MAX` rows for a duplicate it ignored
- **Status:** Quirk (left as is)
- **Where:** `MADMySQL/Source/MysqlInsert.m:139-142`
- **Behavior:** With `ignoreDuplicateErrors` set, a failed `mysql_stmt_execute` is
  swallowed and the code goes straight on to read `mysql_affected_rows`, which answers
  `(my_ulonglong)-1` for a statement that did not run.  `affectedRows` therefore comes
  back as 18446744073709551615 rather than 0.
- **Why it matters:** The flag exists so an insert can be "fire and forget"; a caller
  that logs or accumulates `affectedRows` will add a number larger than the row count of
  the universe.  No in-tree caller reads it after an ignored duplicate.
- **Test:** `MADMySQLLiveTests testInsertRejectsADuplicateKeyUnlessToldToIgnoreIt`
  asserts the value exactly, so a future fix to 0 fails the test rather than passing
  silently.

### `MysqlTruncate`'s factories skip the nil-connection check the other DML classes make
- **Status:** Quirk (left as is)
- **Where:** `MADMySQL/Source/MysqlTruncate.m:22-33` against `MysqlInsert.m:27-33`,
  `MysqlUpdate.m:26-32`, `MysqlDelete.m:25-31`
- **Behavior:** `MysqlInsert`, `MysqlUpdate` and `MysqlDelete` all raise
  `MysqlException` from their factories when handed a nil connection; the two truncate
  factories do not, and hand back an object that fails at `-execute` instead.
- **Why it matters:** A caller that checks for a raise (or relies on the factory to
  refuse) gets an object rather than a diagnosis.  Harmless today — nothing in-tree
  passes nil — but the four classes should behave the same way.
- **Test:** `MysqlTruncateTests testFactoryAcceptsANilConnection`.

---


## MADTds

### MADTds publishes FreeTDS's headers as-is, so one quoted include remains
- **Status:** Not ours -- the header is third-party; recorded rather than changed.
- **What:** `sybdb.h`, shipped from `Compressor/library/freetds/include/`, includes
  `tds_sysdep_public.h` with a double-quoted include (`:31`), which
  `-Wquoted-include-in-framework-header` reports because MADTds republishes the header as
  part of its public module.  Every first-party public header was converted to
  angle-bracket includes in the warning sweep; this one was left because the file is
  FreeTDS's, and `THIRD_PARTY_LICENSES.md` already records that the shipped copy is
  modified -- which carries its own LGPL notice obligation.
- **If it should ever go:** patch the copy the Compressor recipe installs for the
  framework, leaving the build copy untouched.  That is a licence-notice change, not a
  warning fix.
- **Where:** `Compressor/library/freetds/include/sybdb.h:31`.

### MADTds's build carries an unsandboxed-script advisory
- **Status:** Intentional -- documented; it cannot be fixed without breaking Compressor.
- **What:** Xcode warns "tasks in 'Copy Headers' are delayed by unsandboxed script
  phases; set ENABLE_USER_SCRIPT_SANDBOXING=YES".  Every project with a Compressor
  "Ensure Libraries" phase carries it.  Sandboxing is off deliberately: the phase runs
  `Compressor/build.sh`, which writes into `Compressor/library/`, outside any script
  sandbox.
- **Note:** the companion warning -- "will be run during every build because it does not
  specify any outputs" -- was cleared by marking those phases `alwaysOutOfDate`.  The
  script is a manifest check that is meant to run every build, and it skips rebuilding
  when the libraries are current, so this documents intent rather than changing it.
- **Where:** the six projects with the phase: MAD, MADBarcodes, MADMySQL, MADSqlite3,
  MADTds, MAD Designer.

## MADTdsClient

Covered by an offline suite (`MADTdsClientTests.m`, 47 tests) plus a live suite
(`MADTdsClientLiveTests.m`, 28 tests) that runs against the local SQL Server 2022
instance in `DEVELOPER.md` (`127.0.0.1`, `sa`, `AdventureWorksLT2022`). The live
suite is the only way to reach `-connect:andPassword:error:`,
`-getTablesFromConnection:error:`, `-fieldsForTable:connection:error:` and
`-runSQL:onDataTable:fieldKeys:process:`, which are thin wrappers over freetds;
it skips rather than fails when no server is reachable.

### `-getTables:` passed the process wrapper to freetds as if it were a `DBPROCESS`
- **Status:** Fixed
- **Where:** `MADTdsClient/Source/MADDatabaseSQLServer.m:241`
- **Behavior:** `-connectWithConnection:credentals:connectionError:` returns a
  `MADDatabaseProcessSQLServer` that wraps the `DBPROCESS`, but the code
  bridge-cast that object straight to `DBPROCESS *` and handed it to `dbcmd()`.
  freetds then realloc'd at an offset inside the Objective-C object instead of
  its command buffer, and every call aborted the process:
  `tds_realloc → dbcmd → -[MADDatabaseSQLServer getTables:]`. The wrapper is now
  unwrapped with `-process` before the first freetds call.
- **Why it matters:** The method could never work, and it takes the whole host
  process down rather than returning an error — the connection-creation flow is
  the one place it is called.

### `-runSQL:onDataTable:fieldKeys:process:` closes the connection it was given
- **Status:** Quirk (load-bearing — documented, not changed)
- **Where:** `MADTdsClient/Source/MADDatabaseSQLServer.m:1481`
- **Behavior:** `dbclose(dbconn)` runs on every exit path, including the success
  path, on a `DBPROCESS` the caller opened. The read paths
  (`-getTablesFromConnection:error:`, `-fieldsForTable:connection:error:`) have
  their `dbclose` calls commented out; this one does not.
- **Why it matters:** Two consequences, both fatal:
  - A caller that closes the connection it opened double-frees inside freetds.
    The live suite reproduced this before it was worked around —
    `dbstring_free → dbclose → -[MADDatabaseSQLServer closeConnection:]`,
    `SIGSEGV`. `-executeQuery:withDataTable:andError:` never closes its
    connection at all, so it leaks rather than crashing; `-getTables:` does
    close, and would crash.
  - Only one statement can ever be run per connection, which defeats the
    `-runSQL:` contract and makes `-getTables:`'s own `dbclose` at line 291
    (legitimate there, because that method opens its own connection) the odd
    one out.
  - Locked down by `testEachStatementNeedsItsOwnConnection`, which pins the
    one-statement-per-connection pattern the defect forces.
- **Caller analysis (2026-10-01): load-bearing — do not remove the `dbclose`.**
  Every caller was written assuming `-runSQL:` consumes the process it is
  handed: `MADOperationRefresh.m:80-122` and
  `-executeQuery:withDataTable:andError:` each open one process, run one
  statement, and never close it themselves. Deleting the `dbclose` because it
  "double-frees" would instead leak a `DBPROCESS` per query. The contract is
  ugly but every caller is correct against it. An inline comment now records
  this at the call site; changing it requires first giving those callers
  explicit ownership and a close of their own.

### Every `DECIMAL` / `NUMERIC` value is lost or corrupted
- **Status:** Fixed
- **Where:** `MADTdsClient/Source/MADDatabaseSQLServer.m:1043`
  (`case SYBDECIMAL: case SYBNUMERIC:`)
- **Behavior:** The separator-detection block derives a "separator" by trimming
  decimal digits off both ends of the value string, then only ever assigns the
  working copy when that bogus separator differs from the locale separator:

  ```objc
  NSString *objectStr2 = nil;
  if (tdsDecimalSeperatorMatchesCocoaDecimalSeperator == NO) {
      objectStr2 = [objectStr stringByReplacingOccurrencesOfString:...];
  }
  NSDecimalNumber *decimalNumber = [[NSDecimalNumber alloc] initWithString:objectStr2];
  ```

  When no replacement is wanted `objectStr2` stays `nil`, and
  `-initWithString:` on `nil` returns `notANumber`. The value is discarded.
  The negative case is worse: the derived separator for `"-2.5"` is the literal
  `"-2."`, which occurs inside the string being rewritten, so `"-2.5"` becomes
  `".5"` and is reported as `0.5` — a plausible number that is silently wrong.
- **Verified against the server:** `sqlcmd` returns 3.5, 1.00 and 123.456 for
  the expressions the tests use; the loss is in the framework.
- **Why it matters:** Any report built on a `DECIMAL` or `NUMERIC` column shows
  `NaN`, or a wrong value with no indication anything failed.
- **Now:** the separator is found by scanning for the first character that is
  neither a digit nor a leading sign, so `"-2.5"` yields `"."` rather than
  `"-2."`; the working copy of the value string defaults to the value itself
  instead of `nil`; and the substitution runs only when there is a separator to
  substitute. `-2.5`, `3.5`, `1.00` and `123.456` all decode to their server
  values.
- **Test:** `testSelectDecimalReturnedValues` and
  `testSelectNegativeDecimalKeepsItsSign` (renamed from the characterization
  tests `testSelectDecimalReturnsNotANumber` /
  `testSelectNegativeDecimalReturnsCorruptedValue`), plus the DECIMAL column of
  `testTypeConversionRoundTrip`.

### `-fieldsForTable:connection:error:` feeds sybdb type codes into a table of SQL Server type ids
- **Status:** Fixed
- **Where:** `MADTdsClient/Source/MADDatabaseSQLServer.m:1993`
- **Behavior:** The query selects `sys.columns.system_type_id` and passes it to
  `+dataTypeForNativeType:`, which is written against sybdb (`SYB*`) codes. The
  two numbering schemes overlap only for the legacy types, so the mapping is
  right by coincidence where it is right at all. `DECIMAL` is 106 in both — and
  106 has no case, so it falls to `default` and reports `String`. `VARBINARY` is
  165, which is not a sybdb code at all, so it also reports `String`. Unlike the
  query path there is no `SYBDECIMAL → SYBNUMERIC` rewrite here to save it.
- **Now:** a dedicated `+dataTypeForSystemTypeId:` (`.m:226`) maps
  `sys.columns.system_type_id` onto `MADDataType` on its own terms, and
  `-fieldsForTable:` calls it. `Weight` (106) is `MADDataTypeDecimal` and
  `ThumbNailPhoto` (165) is `MADDataTypeBlob`.
- **Test:** `testFieldsForTableMapsDecimalAndBinary` (renamed from
  `testFieldsForTableMisreportsDecimalAndBinaryAsString`), plus the new
  `+dataTypeForSystemTypeId:` cases in `MADTdsClientTests.m`.

### `+dataTypeForNativeType:` has no case for several live SQL Server types
- **Status:** Fixed
- **Where:** `MADTdsClient/Source/MADDatabaseSQLServer.m:156`
- **Behavior:** `SYBDECIMAL` (106), `SYBDATE` (49), `SYBTIME` (51), `SYBMONEY4`
  (122), `SYBMSDATE` (40), `SYBMSTIME` (41), `SYBMSDATETIME2` (42),
  `SYBMSDATETIMEOFFSET` (43), `SYBBIGDATETIME` (187) and `SYBBIGTIME` (188) all
  reach `default` and become `MADDataTypeString`. On the query path
  `-runSQL:` rescues `SYBDECIMAL` and `SYBMONEY4` by rewriting the code before
  calling this method, but nothing rewrites the post-2005 date/time types.
- **Why it matters:** `DATE`, `TIME`, `DATETIME2` and `DATETIMEOFFSET` columns
  are typed as strings, so date grouping, formatting and comparison in the
  designer do not apply to them.
- **Now:** all ten codes have a case. `SYBDECIMAL` joins `SYBNUMERIC` as
  `MADDataTypeDecimal`; `SYBMONEY4` joins the other money codes as
  `MADDataTypeFloat`; `SYBDATE`/`SYBMSDATE` are `MADDataTypeDate`;
  `SYBTIME`/`SYBMSTIME`/`SYBBIGTIME` are `MADDataTypeTime`; and
  `SYBBIGDATETIME`/`SYBMSDATETIME2`/`SYBMSDATETIMEOFFSET` are
  `MADDataTypeDateTime`.
- **Now (2026-10-01, values):** the modern codes carry their values too, and need
  no bind array to do it. freetds keeps each one in the row buffer in a layout
  only the type code explains, so the row conversion hands the buffer straight to
  `dbanydatecrack()` together with the column's own type code; a NULL reads back
  as a null pointer, the same signal the `SYBDATETIME` case already relied on.
  This is the call freetds makes for itself when it prints such a column
  (`src/dblib/dblib.c`, `dbspr1row`). Binding was the wrong shape: the bind
  constants for these codes write a *converted* layout, not the one
  `dbanydatecrack()` reads.
- **Test:** `testDataTypeForNativeTypeMapsModernDateTimeFamily`,
  `testDataTypeForNativeTypeMapsNumericToDecimal` and
  `testDataTypeForNativeTypeMapsMoneyAndFloatingPointToFloat` in the offline
  suite, and `testSelectModernDateTimeTypes` (values) and
  `testSelectModernDateTimeTypesNull` (NULLs) live.

### Every SQL `DATETIME` reads back one month late
- **Status:** Fixed
- **Where:** `MADTdsClient/Source/MADDatabaseSQLServer.m:1330` and `:1354`
  (`case SYBDATETIME` and `case SYBDATETIMEN` in the row conversion)
- **Behavior:** both cases did `comps.month = dateinfo.datemonth + 1`. The record
  freetds fills in has *already* been shifted to the 1-based Microsoft month
  before it is returned — `dblib_datecrack()` bumps `datemonth` when the
  `DBPROCESS` is in MS mode, which this build is — so the extra `+ 1` counted
  January twice. Measured against the live server:
  `CAST('2020-01-15T13:45:00' AS DATETIME)` came back as February, and
  `CAST('2020-12-15T13:45:00' AS DATETIME)` came back as **2021**-01-15.
- **Why it matters:** every `DATETIME` and `SMALLDATETIME`-family value from SQL
  Server was shifted a month, and a December value also moved a year, in a
  shipping driver. Nothing downstream compensates: the shift is invisible in the
  value and only shows when a report is compared with the database.
- **Now:** both cases read `dateinfo.datemonth` as it arrives, with a comment
  giving the reason. Found while fixing the post-2005 date/time values above,
  which go through the same freetds record.
- **Not changed:** `SYBDATETIME4` does not use the cracked record — it does its
  own day/minute arithmetic — so it is unaffected. Its base date is another
  matter; see the note below.
- **Test:** `testSelectClassicDateTimeKeepsItsMonth` live, which pins January
  staying January and December staying in its own year.

### `SYBDATETIME4` counts its days from the wrong epoch
- **Status:** Still open — recorded, not fixed
- **Where:** `MADTdsClient/Source/MADDatabaseSQLServer.m:432`
  (`janFirst1990Components`, read at `:1295`)
- **Behavior:** the variable is named for 1990 and its components are 1900-01-00,
  but `DBDATETIME4.days` counts from **1900-01-01**, and day 0 must therefore be
  1900-01-01 too. Building the base as 1900-01-**00** (i.e. 1899-12-31) makes
  every `SMALLDATETIME` land one day early.
- **Why it matters:** `SMALLDATETIME` columns are off by a day.
- **Why it is not fixed here:** it is a different arithmetic path from the
  cracked-record cases and it has not been measured against the server yet, so
  the off-by-one is read from the code rather than observed. It wants its own
  live test first — the same shape as
  `testSelectClassicDateTimeKeepsItsMonth` — before the base date is changed.

### `-connectWithConnection:credentals:connectionError:` never reports its error
- **Status:** Fixed
- **Where:** `MADTdsClient/Source/MADDatabaseSQLServer.m:1593`
- **Behavior:** `error = &dberror;` rebound the parameter to a local, so the
  caller's out-parameter was never written. It also meant the surrounding
  `if (error && dberror)` was always true when a failure occurred, so the
  `else` branch that would have produced the wrapper was skipped and the method
  returned `nil` — the only failure signal the caller got.
- **Why it matters:** Callers pass an `NSError **` and got back nothing, so a
  failed connection was indistinguishable from any other nil return. This was
  one of the two causes of the silent SQL Server create-report failure.
- **Now:** the method writes the underlying `dberror` through to the caller's
  pointee (guarded on non-NULL) and still inserts it into `self.errors`.
- **Test:** `testConnectWithConnectionReportsErrorToCaller` (renamed from the
  characterization test `testConnectWithConnectionDoesNotReportErrorToCaller`),
  now asserting the error is non-nil and in the `MTDatabaseTds` domain.

### `-connect:andPassword:error:` dereferences `*error` without a NULL check
- **Status:** Fixed
- **Where:** `MADTdsClient/Source/MADDatabaseSQLServer.m:1602`
- **Behavior:** The first statement of the failure path is
  `if (*error != NULL)`, and several later paths assign `*error` directly. A
  caller that passes `NULL` — which is the documented Cocoa convention for "I
  don't care" — crashes.
- **Why it matters:** Passing `NULL` is exactly what a caller who only wants
  the `DBPROCESS *` back would do.
- **Now:** the method takes an `NSError * __autoreleasing *err` that aliases the
  caller's pointee when there is one and a throwaway local when there is not,
  and every assignment goes through `*err`. The inverted `if (*error != NULL)`
  guard on the `dbinit` failure is gone with it.

### `-fieldsForTable:connection:error:` has dead error handling that dereferences a known-NULL pointer
- **Status:** Fixed
- **Where:** `MADTdsClient/Source/MADDatabaseSQLServer.m:1993`
- **Behavior:** A branch reads
  `if (sqlReturnCode != SUCCEED && error == NULL) { if (error != NULL) {...} NSAssert(error == NULL, @"...", *error); }`
  — the inner test can never be true inside a block that already established
  `error == NULL`, and the assertion's message argument dereferences `*error`
  anyway.
- **Why it matters:** The failure this code was meant to handle is not reported
  at all; the code only looks like it is handled.
- **Now:** on a non-`SUCCEED` return the method writes a `3456`-coded
  `MADDomainTDS` error describing the syntax failure to the caller's pointee,
  guarded on non-NULL. `MADTdsClientLiveTests` exercises it against the server.

### `port` is never passed to freetds
- **Status:** Fixed
- **Where:** `MADTdsClient/Source/MADDatabaseSQLServer.m:1602`
- **Behavior:** `MADDatabaseConnectionSQLServer` carries a `port` and includes it
  in `connectionString`, but `-connect:andPassword:error:` only calls
  `DBSETLUSER`, `DBSETLPWD`, `DBSETLAPP` and `DBSETLDBNAME`. `DBSETLPORT` is
  never called, so freetds always dials its default port.
- **Why it matters:** A SQL Server listening anywhere other than the default
  port cannot be reached, even though the connection UI lets the user type the
  port in. The live suite works only because the test instance is on 1433.
- **Now:** this freetds build exports no `DBSETLPORT`, so the port travels in
  the server string handed to `dbopen()` — `"host:port"`, which freetds parses —
  when the connection carries a non-zero port.

### `+newSafeQueryField:andTable:` does not split a schema-qualified table
- **Status:** Fixed
- **Where:** `MADTdsClient/Source/MADDatabaseSQLServer.m:1730`
- **Behavior:** The method brackets the table name as a single identifier —
  `[[NSString alloc] initWithFormat:@"[%@].[%@]", tableName, fieldName]` — with
  no handling of a dot. `dbo.employees` therefore becomes
  `[dbo.employees].[emp_no]`, which is a table named `dbo.employees`, not a
  column of `dbo.employees`.
- **Why it matters:** Schema discovery returns schema-qualified names
  (`SalesLT.Customer`), so the generated SQL for any query built on a discovered
  table names a table that does not exist.
- **Now:** the table half goes through `+newSafeIdentifier:`, which brackets
  each dot-separated component: `dbo.employees` → `[dbo].[employees]`, so the
  result is `[dbo].[employees].[emp_no]`.
- **Test:** `testNewSafeQueryFieldSplitsSchemaQualifiedTable` (renamed from the
  characterization test `testNewSafeQueryFieldDoesNotSplitSchemaQualifiedTable`).

### `-sqlSampleDataForField:andTable:` bypasses the base class's clause builders
- **Status:** Quirk (load-bearing — documented, not changed)
- **Where:** `MADTdsClient/Source/MADDatabaseSQLServer.m:1680`
- **Behavior:** The override hardcodes `SELECT DISTINCT TOP 511 ...` instead of
  composing `-selectPart` / `-selectPartWithLimitedResults:` and calling
  `-sqlAggregateFunctionLength` the way the base class does. It works, and it
  is the reason SQL Server sample data does not emit the base class's invalid
  `LIMIT 511;`, but the two paths will drift.
- **Why it matters:** Nothing is broken today; noted so the duplication is not
  mistaken for the base implementation.
- **Caller analysis (2026-10-01): load-bearing — do not "deduplicate".** The base
  implementation in `MADAPI/Source/MADDatabase.m` hardcodes `LIMIT 511;` into its
  format string and never goes through `-sqlLimitClause`, so SQL Server's empty
  limit clause cannot neutralise it. Composing the base implementation would emit
  invalid T-SQL. An inline comment now records this at the source.

### `-executeQuery:withDataTable:andError:` discards its error
- **Status:** Fixed
- **Where:** `MADTdsClient/Source/MADDatabaseSQLServer.m:325`
- **Behavior:** It declared `NSError * __autoreleasing dberror = nil`, passed
  `&dberror` to the connect call, and then never read `dberror` or wrote
  `*error`. A connection failure returned `NO` with no explanation.
- **Why it matters:** Same as `-connectWithConnection:...` above: the caller's
  `NSError **` contract was not honoured. Together, these two were the whole of
  the reported "SQL Server fails silently" symptom —
  `MADOperationDatabaseTestConnection.m:166-183` now routes into
  `finishWithError:` with the real error instead of `finishWithError:nil`.
- **Now:** on a nil process the method writes `dberror` to the caller's error;
  on success it forwards the caller's `error` to `-runQuery:...`. Note
  `-runQuery:...` and `-executeSQL:...withError:` still do not populate their own
  error out-parameters for post-connection SQL failures — separate findings.

---


### dbdatecrack is called with the sybase DBDATETIME under a microsoft DBDATEREC name
- **Status:** Open -- found by the warning sweep, documented rather than changed.
- **What:** `MADTdsClient/Source/MADDatabaseSQLServer.m` copies each `SYBDATETIME` /
  `SYBDATETIMN` value into a malloc'd buffer and passes it to `dbdatecrack`
  (`:1327`, `:1355`).  FreeTDS types the buffer as `struct tds_sybase_dbdaterec *`
  while the call's third parameter is `DBDATEREC *`, which this build aliases to
  `struct tds_microsoft_dbdaterec *`; the compiler reports the mismatch on both
  calls.  The surrounding local (`dateinfo`, `:1323`) is declared with the sybase
  struct as well.
- **Why it is not changed here:** the FreeTDS sybase/microsoft struct duality decides
  the layout of the data `dbdatecrack` reads, so the correct form depends on which
  compatibility mode the vendored FreeTDS was built with -- a driver-correctness
  question, not a cast to add mechanically.  The code carries `// CORRECTED:` notes
  from an earlier pass, so the area is already sensitive.
- **Where:** `MADTdsClient/Source/MADDatabaseSQLServer.m:1320-1360`.
- **Evidence:** `xcodebuild analyze` reports `-Wincompatible-pointer-types` on both
  `dbdatecrack` calls; the two are the only remaining instances of that diagnostic in
  the workspace.


### REAL and FLTN result values were narrowed through float before the NSNumber
- **Status:** Fixed -- though the narrowing is not observable with SQL Server's own types.
- **What:** the `SYBREAL` and `SYBFLTN` cases of the result-building switch built their
  `NSNumber` with `initWithFloat:` from a `double` bind buffer; the compiler reported it as
  an implicit precision-losing conversion.  Both now use `initWithDouble:`, matching the
  `SYBFLT8` case next to them, which boxes the double directly.
- **Why it is safe:** a `SYBREAL` value is a 4-byte float by definition, so it is exactly
  representable either way, and SQL Server sends `FLOAT` as `SYBFLT8` (already correct).
  The change removes the narrowing for the case where `SYBFLTN` carries an 8-byte value --
  which a Sybase server can do -- not for any value today's server produces.
- **Evidence that nothing changed for SQL Server:** the live suite was run against the
  old `initWithFloat:` code and the new code and passes identically both ways.
- **Locked down by:** `MADTdsClientLiveTests -testSelectFloatKeepsDoublePrecision`, which
  guards the 8-byte FLOAT path; its comment records that the SYBREAL/SYBFLTN cases cannot
  be told apart by any value, so no test can discriminate them.
- **Where:** `MADTdsClient/Source/MADDatabaseSQLServer.m:1131-1150`.

## MAD Designer (app)

Covered by the hosted `MADDesignerUnitTests` bundle (74 tests across
`MADDesignerUnitTests.m`, `MADAppLogicTests.m`,
`MADAppOperationConditionTests.m`, and `MADStatusLabelRefreshTests.m`). The bundle
is hosted by `MAD Designer.app` (TEST_HOST/BUNDLE_LOADER), so it reaches the app's
own source through the running executable; the app's classes are declared locally
in the test files rather than imported, because `MADDesigner/Source` is not on the
bundle's header search path.

### The refresh path reads the shared store context from operation-queue threads
- **Status:** Fixed
- **Now:** store reads on the refresh path are marshalled onto the main queue
  (inline when already there), the store's owning queue.  In
  `MADOperationRefresh -execute` the SQL build and the field-key read run on
  main and only the built string and key array cross back to the operation
  thread.  In `MADOperationRefreshInitialize -execute` the document-graph
  reads and the sort run on main and only the resolved query crosses back.
  `MADRefreshOperationReload -execute` now marshals `prepareForQuery`
  (whose sort-descriptor walk reads the store) onto main as well; the
  format's own layout-part reads still run on the operation thread -- they
  are what keep the per-page UI updates flowing during the page count, and
  the layout part is quiescent during a refresh (the open flow writes only
  the query part).  `MADQueryValueFromFieldController -loadPickerView`
  resolves the schema field and its credentials (building the database
  connection) on main before dispatching, so the global-queue block holds
  only plain values.  Of the create-document operations,
  `MADOperationCreateDocumentFirstTimeSetup` marshals its insert-and-save to
  main; `MADOperationCreateDocumentImportSchema` is deliberately left on its
  operation thread -- the whole point of the operation is a network-bound
  schema import whose store writes would block the UI for the import's
  duration, and the store is otherwise quiescent during document creation.
  `MADQuerySampleDataField -getSql:` still reads the schema field's
  `name`/`inTable.name` from inside the driver while the sample-data query
  executes on that same global queue; those attributes are immutable during
  the fetch, but it is the one residual off-main store read on this path.
  Chosen main-queue marshalling rather than a dedicated serial store queue
  because the store is already documented as main-thread-owned and the
  operations' store work is small.  No locking was added to any accessor.
- **Where:** `MADDesigner/Source/MADOperationRefresh.m:104-118` and
  `MADDesigner/Source/MADOperationRefreshInitialize.m:64-99` (the two live
  ones), plus the same pattern in `MADQueryValueFromFieldController.m:157-159`
  (a global GCD queue).  The other former `performBlock:` sites
  (`MADDesignerViewController`, `MADQueryViewController` delete/add flows) now
  run inline on the main thread, which changes timing but is thread-safe.
- **Behavior:** the milestone-(b) mapping replaced each private
  `NSManagedObjectContext` + `performBlockAndWait:` with a direct read of the
  shared `document.storeContext` on the operation's own thread.  Core Data's
  queue confinement is gone, and `RptqStoreContext` / `MADStoreGraph` keep
  plain mutable collections (registry, dirty sets, graph rows) with no
  synchronization.  A refresh therefore mutates and iterates those collections
  on a background thread while the main thread reads them continuously --
  a data race that can fault objects twice, lose registry entries, or corrupt
  iteration.  The Phase C design (MAD_STORE_PHASE_C.md §2-3) specified the
  single shared context but never addressed queue confinement, so this is a
  design gap, not a mechanical slip.
- **Fix shape.**  Restore confinement on the refresh path without touching the
  hot paths: the store reads the refresh operations perform are small (SQL
  generation and layout setup), so marshalling them onto the main queue (or a
  single serial store queue that owns all context access) is the right
  restore; a lock inside every `RptqStoreContext` accessor is not (it taxes the
  render/formatter hot path the store was rebuilt to serve).  The
  `MADQueryValueFromFieldController` global-queue read should read the field on
  the main thread and pass plain values into the block.
- **The rule this violated:** the shared store context is main-thread-owned;
  only its owning queue may touch it unless confinement is explicitly added.

### The page-count updates never fire because the formatter instance is unstable
- **Status:** Fixed
- **Now:** the reload operation observes
  `MADNotificationDidFormatPagesName` with `object:nil` instead of the
  formatter instance, and re-asserts `didRefresh` on the formatter that is
  about to format.  The document's formatter is not a stable instance:
  `-activeDocumentModel` (reached through `-prepareForQuery`) calls
  `-resetReportFormatter`, and the refresh's initialize step replaces it
  with a fresh one, so an observation keyed to the instance could end up
  listening to a formatter that is no longer the one that formats -- the
  format ran, the pages were counted, and `reportFormatterDidFormatPage:`
  was never called.  The same churn could lose the `didRefresh` flag the
  refresh operation had set, after which a recreated formatter reloaded the
  old layout from the index cache and the format was skipped entirely.
  Verified with the launch hooks and the instrumented poster/observer: the
  per-page deliveries now reach the reload operation and the page count
  updates flow.
- **Where:** `MAD/Source/MADDocument.m` (`-activeDocumentModel` ->
  `-resetReportFormatter`), `MADDesigner/Source/MADOperationRefreshInitialize.m`
  (replaces `document.reportFormatter`), `MADDesigner/Source/MADRefreshOperationReload.m`
  (`-watchFormatter:` / `-ignoreFormatter:` / the format call).
- **Behavior:** reported by the user: "`reportDocumentDidReadRows:` should be
  called over-and-over as the report is refreshing, and
  `reportFormatterDidFormatPage:` is supposed to be called as each page is
  formatting... Now, it's never called during the formatting.  It does seem
  like the formatting is happening, but the UI updates are not working like
  they use to."  Both failure modes come from the formatter identity churn:
  the observer keyed to the old instance misses every post (formatting
  happens, updates do not), and the lost `didRefresh` skips the format
  (stale page count, no posts at all).  Which one appears depends on where
  the recreate lands relative to the watch and the refresh flag.
- **The rule this violated:** notification observation must not depend on an
  object identity the owning graph is free to replace.

### The open-time reload operation hides the refresh activity indicator
- **Status:** Fixed
- **Now:** the viewer's `operationDidFinish:` treated any
  `MADRefreshOperationReload` finish as reload-complete and flipped the
  display back to active.  The reload the viewer enqueues in
  `viewDidAppear:` is exactly that class, so when its finish landed while a
  user-initiated refresh was in flight, the activity indicator went dark
  mid-refresh (whether the indicator appeared at all depended on which
  operation finished last).  The callback now skips the display update for a
  `MADRefreshOperationReload` while `_refreshing` is set; the refresh group
  (a `MADOperationRefreshReload`) still updates the display through the
  first branch.  Verified with the launch hooks and the instrumented
  formatter gate: refresh -> format runs -> per-page updates flow -> final
  page count lands.
- **Where:** `MADDesigner/Source/MADViewerController.m`
  (`-operationDidFinish:`) and the reload enqueued in `-viewDidAppear:`.
- **Behavior:** reported by the user: "the app doesn't always display the
  refresh activity indicator," and after a refresh the reload's page-count
  updates were not displayed.  The refresh chain itself was completing --
  the instrumented formatter gate shows `formatDocument` running and the
  final count landing -- but the open-time reload's late finish could mask
  the indicator, and the whole format now completes in 1-3 s (the
  pre-migration Core Data version took long enough that the page count was
  visibly "analyzing the backing store").  The A/B against the pre-fix HEAD
  (`fff8d7dff`) shows identical end state, so this is a store-migration
  regression, not one of the four fixes' doing.
- **The rule this violated:** the activity indicator belongs to the refresh
  in flight; an unrelated operation's completion must not clear it.

### The "Formatting page N." status message was set but never shown
- **Status:** Fixed -- pending the user's check of the running app
- **Where:** `MADDesigner/Source/MADRefreshOperationReload.m` (the delivery
  path), `MADDesigner/Source/MADViewerController.m` (`-operation:didFormatPage:`
  and the reload enqueued in `-viewDidAppear:`),
  `MADDesigner/Source/MADLabelStatus.m` (`-updateFormattingStarted:`),
  `MADDesigner/Source/MADOperationRefreshReloadProtocol.h`.
- **Behavior:** reported by the user: during a refresh and during the open-time
  reload, `MADNotificationDidFormatPagesName` posts over and over and the final
  page count lands correctly, but the screen showed nothing changing for the
  2-3 s the format takes.  The label's text was being set (see the test), so
  what was wrong was when and how often the label was told.
- **Now:** the status line tells the run's phases instead of waiting on the
  formatter's posts.
  * The refresh's first phase is announced from the viewer at the start of the
    run (`-refresh:` and the open-time reload): the line reads "Refreshing…".
    The read can take seconds on a large report, and that window used to show
    the previous run's page position.
  * `-operationDidBeginFormatting:` (new protocol method) is sent before the
    format starts and puts "Formatting…" on the line; the page posts refine it
    from there.
  * The formatting progress is coalesced.  Only the newest page is kept,
    deliveries are floored at 10 Hz -- the rate the status label already
    re-renders at -- and the newest page that never got out is flushed just
    ahead of the page position in the same dispatch, so the position is still
    the label's last word.  For the 9,212-page sample (1,321 posts) the label
    now gets ~6 deliveries instead of 1,322; the records path coalesces the
    same way in `MADOperationRefreshReload -updateNumberOfRecords:`.
  * The open-time reload (`-viewDidAppear:`) disables the refresh button for
    its run and registers the viewer as its observer -- the branch
    `-operationDidFinish:` always had for that operation (`!_refreshing`) and
    never reached because nothing registered it.  A refresh started
    mid-format would have set a second format going against the same document.
    The button was already disabled for a user-started refresh by the
    indicator swap.
- **Verified in the running app:** launched headlessly with the app's own hooks
  (`-UITestOpenSample Music -UITestRefresh`) and streamed at debug level.  The
  full chain runs in the app -- posts, delivery, label write -- and with the
  format stretched to a few seconds for observation the label was traced
  through `-drawTextInRect:` drawing "Formatting…", then a rising
  "Formatting page N." every ~100 ms, then "Page 1 of 77 pages."  What the
  samples cannot show is the reported gap: their whole format is 40-80 ms, so
  the phase is a sub-frame event there -- which is why the line, not the
  screen, was where the fault had to be found.
- **Test:** `MADStatusLabelRefreshTests` (new) drives the real operation, the
  real notification singleton and a real label; it records every string the
  label is handed, renders the label's pixels to prove it draws, and pins both
  phase messages, the coalesced delivery count, the flush order and the final
  page position.  Run with
  `-only-testing:MADDesignerUnitTests/MADStatusLabelRefreshTests`.
- **Also worth knowing:** `MADViewerController -reportFormatterDidFormatPage:`
  and `-reportDocumentDidReadRows:` duplicate the reload operation's handlers
  but have no registrar -- the reload operation is the only observer of the
  format post -- so breakpoints there never fire during a refresh, and the log
  lines that do fire are the operation's.
- **Found during:** the user's report on the status label; the test is new
  infrastructure for this path, which had no coverage.

### The value picker offers `NULL` as a value, and it is not SQL NULL
- **Status:** Still open
- **Where:** `MADDesigner/Source/MADQueryValueFromFieldController.m:269-270`
  (`-pickerView:titleForRow:forComponent:`) and `:283-284`
  (`-pickerView:didSelectRow:inComponent:`)
- **Behavior:** when the sampled row's value object is nil, the picker labels the row
  `@"NULL"`. `-didSelectRow:` then copies that label straight into the text field, and
  the field's contents are what becomes the predicate's right-hand value. From there
  `MADQueryPredicate` quotes a non-numeric value — so the SQL reads `= 'NULL'`, a text
  literal matching only those four characters — and emits a numeric one bare, `= NULL`,
  which is SQL NULL and matches no row at all. Neither is `IS NULL`, which is what the
  label implies to the user.
- **Why it is not a one-line fix:** there is no `IS NULL` in the operator set, so the
  "no value" case has nowhere correct to go. Doing it properly means the comparison
  symbol enum, `MADQueryPredicate` and the predicate-entry UI together, and it is a
  product decision — what should a blank value mean — not a defect to patch.
- **The branch is also aimed at the wrong thing:** it tests `resultObject == nil`, but a
  dictionary read out of the data table cannot hold nil for a value; it holds `NSNull`.
  An actual NULL therefore falls past this branch to the final `else` and displays as
  an empty row, so the label is not reached for the case it is written for.
- **Not fixed:** audited for ROADMAP Track 1.5 and left alone. The string here stands
  in for a NULL, which is what that item is about, but it is a picker's display text
  that the selection handler copies into a value field — changing it changes what the
  user sees and what gets typed, and nothing covers either today.

### `MADOperationRefresh` reports the connection error in place of the execution error
- **Status:** Fixed
- **Where:** `MADDesigner/Source/MADOperationRefresh.m`
- **Behavior:** When `-executeSQL:fieldKeys:onConnection:intoResultTable:withError:`
  returns NO, the handler finishes with `NSError *error = eerror;`. `eerror` is the
  *connection* error from the `-connectWithConnection:credentals:connectionError:`
  call at `:78-88`, which has already succeeded and is therefore still nil. The
  `executeError` captured one line earlier at `:104` is logged at `:112` and then
  dropped.
- **Why it matters:** `-finishWithError:nil` completes the operation with an empty
  error list, so a query that failed is indistinguishable from one that matched
  nothing — and, worse, from one that succeeded. `-resetCache`
  (`MAD/Source/MADocument.m:229-238`) *loads* the existing `.maddb` before this
  operation runs, so `-numberOfResults` still answers with the previous run's rows
  while the current query is failing, and those are the rows the caller sees.
  Measured on `London.mad` at `SQLITE_DQS=0`: with its stale 76-row cache present,
  `mad refresh` printed "refreshed 76 rows" and exited 0; with that cache moved
  aside, the identical command printed "refreshed 0 rows". The prepare failure was
  invisible in both cases and the real message only surfaced under instrumentation.
  Every failure between `-executeSQL:` and the cache is reported as success, and the
  cache makes the success look like it carries data.
- **Related:** the credentials branch raised domain `@"MADCache"` with code
  `errCache + 1` for a *missing credential*, so a document whose database needed
  credentials the caller did not supply reported "MADCache error 3" and read as a
  cache fault. Both were diagnosability defects in the same method, and both cost
  time in the CLI work.
- **Now:** the failure path finishes with `executeError`, and only builds its own
  error — domain `com.everydayapps.operation.refresh`, code `errExecute` — when the
  driver reported none. The credentials branch uses that domain with a new
  `errMissingCredentials` code and carries a description saying what is missing.
  The CLI's error output goes through `MADCLIDescriptionForError` (`CLI/Source/`),
  which appends `-localizedFailureReason` because the drivers put the database's own
  words there — without it the result was a bare "refresh failed: Error".
- **Verified:** with `chinook.sqlite3` moved aside, `mad refresh London.mad` exited
  0 with "refreshed 76 rows" under the old code (the stale cache's rows) and exits
  4 with `refresh failed: Error: no such table: Customer` under this one.
- **Test:** none; the repro needs a document whose query fails against a live
  database, which the CLI does and the unit targets do not.

### `MTTableController` read a stale page count after a failed fetch
- **Status:** Fixed
- **Commit:** `7b3e976db`
- **Where:** `MADDesigner/Source/MTTableController.m:449` (and `:380`, `:402`)
- **Behavior:** `-fetchFromAPIWithOffset:limit:completion:` answered
  `hasMore = (datatable.count == limit)` from *both* of its branches. On the
  success branch that is right: the driver clears the table before filling it, so
  the count is the page just written. On the failure branch the driver has not
  cleared anything, so the count still described the *previous* page — a failed
  fetch reported `hasMoreData = YES` and re-issued its own query. Two further
  sites, in `-fetchMoreRows` and `-fetchRowAtIndex:`, computed `offset + count - 1`
  without checking for an empty page; with `count == 0` and `offset == 0` that
  yields `NSUIntegerMax`, cast to `NSInteger` as `-1`, so `maxKnownRow` is left at
  `-1` instead of at a value meaning "no rows".
- **Why it mattered:** A query that failed once kept retrying itself instead of
  stopping — that half was live. The underflow was latent rather than visible:
  `-invalidateLayout`'s `maxKnownRow >= minKnownRow` guard turns the `-1` into a
  row count of 0, which is the right answer for an empty page, and
  `-fetchMoreRows`'s `maxKnownRow == NSIntegerMin` sentinel test then falls
  through to arithmetic that wraps `-1` back to an offset of 0. It worked by
  accident on both sides, which is what made it worth removing.
- **Now:** the failure path reports `completion(NO)`; the page-cursor arithmetic
  guards `count > 0` before deriving a last row.
- **Test:** none. `MTTableController` is app source, and the app's unit bundle
  reaches app classes only through locally-declared copies (the bundle's header
  search path does not include `MADDesigner/Source`), so there is nothing here to
  drive it from. The paging invariant it depends on — the driver clears the table
  before filling it — is pinned on the driver side instead, by
  `testDriverFillsAWritePortWithNoDataTableBehindIt` in `MADSqlite3Tests`.

### `+[MADDateFromTimeFormatter timeIntervalForResolution:]` returns 0.1 seconds for a millisecond
- **Status:** Investigated — left as is
- **Where:** `MADDesigner/Source/NSDate+Extras.m:250`
- **Behavior:** The `MTDateResolutionMillisecond` case returns `0.1`. A millisecond
  is a thousandth of a second (`0.001`), so the value is 100x too large. The caller
  at `MADViewerController.m:870` hands this straight to
  `+[NSTimer scheduledTimerWithTimeInterval:]`, so a viewer refresh armed at
  "millisecond" resolution runs at 10 Hz rather than 1000 Hz.
- **Investigated (2026-10-01): left as is.** The caller is a one-shot timer whose
  handler re-arms itself (`-updateTimeSinceLastRefresh:`), so 0.1 s throttles the
  status label's re-render to ten times a second. "Correcting" the value to 0.001
  would re-arm it a thousand times a second, each pass rebuilding a spelled-out
  elapsed-time string. The constant is a UI refresh throttle that reads as a
  resolution; the name is what is wrong here, not the value.

### `+[MADDateFromTimeFormatter timeIntervalForResolution:]` has no case for year, month, or week
- **Status:** Investigated — left as is
- **Where:** `MADDesigner/Source/NSDate+Extras.m:253`
- **Behavior:** The switch covers only Day, Hour, Minute, Second, and Millisecond.
  Year, Month, and Week fall through to `default:` and return `86400.0` -- one day
  -- so a caller asking for year resolution gets a timer that fires daily.
  `-stringWithTimeIntervalSinceDate:` *does* report `MTDateResolutionYear`,
  `MTDateResolutionMonth`, and `MTDateResolutionWeek`, so the two halves of the
  class disagree about which resolutions exist.
- **Investigated (2026-10-01): left as is.** A month is not a fixed number of
  seconds, so the only resolutions this method could honestly answer for are the
  two it has no sensible constant for anyway; the daily fallthrough is what the
  viewer actually wants here, since the label it drives only ever spells out
  "a day ago" and coarser. The tests pin the fallthrough so a later reader does
  not "correct" it to 2629746 or 604800 by guesswork.

### `MADPageViewAttributes` decodes a missing cache date as 2001-01-01
- **Status:** Fixed
- **Where:** `MADDesigner/Source/MADPageViewAttributes.m:66-67` and `:92-93`
- **Behavior:** `-encodeWithCoder:` writes
  `_reportLastCacheDate.timeIntervalSinceReferenceDate`; messaging `nil` yields
  `0.0`. `-initWithCoder:` reads it back with `-decodeDoubleForKey:` and builds
  `[[NSDate alloc] initWithTimeIntervalSinceReferenceDate:]`, which cannot return
  `nil`. "Never cached" therefore round-trips as the reference date, 2001-01-01
  00:00:00 UTC, and a caller testing the property for `nil` will not see it. A
  genuine 2001 date encodes to the same 0, so the two states are indistinguishable
  afterwards.
- **Now:** the date is written only when it is non-nil, under a companion
  `encodeBool:forKey:` presence flag, and read back only when that flag is set.
  `-decodeDoubleForKey:` alone cannot distinguish the two states, so the flag is
  what carries the nil.
- **Test:** `testPageViewAttributesCodingPreservesANilDate` (renamed from
  `testPageViewAttributesCodingTurnsANilDateIntoTheReferenceDate`) and
  `testPageViewAttributesCodingRoundTrip`.

### `MADPageViewAttributes` narrows `zoomScaleInital` and `contentScaleFactor` to float
- **Status:** Fixed
- **Where:** `MADDesigner/Source/MADPageViewAttributes.m:58` and `:61`
- **Behavior:** Both are `double` properties, encoded with `-initWithDouble:` and
  decoded with `-.floatValue`, so only single precision survives a round trip.
  Harmless for the values the app actually stores (zoom scales near 1.0), but the
  coding round trip is not lossless.
- **Now:** the decoded `NSNumber` is unwrapped with `-.doubleValue`, matching the
  `-initWithDouble:` that produces it.
- **Test:** `testPageViewAttributesCodingPreservesTheZoomScalePrecision` (renamed
  from `testPageViewAttributesCodingNarrowsTheZoomScaleToFloat`).

### `NSData (AES256)` encrypts with a NULL IV, so ciphertext is deterministic
- **Status:** Fixed
- **Where:** `MADDesigner/Source/NSData+AES256.m:43` and `:87`
- **Behavior:** `CCCrypt` is called with a NULL IV, so every encryption under a
  given key uses an all-zero IV. The same plaintext always produces the same
  ciphertext, which leaks whether two stored values are equal. Fixing it means
  generating a random IV and storing it alongside the ciphertext.
- **Now:** both methods draw a fresh 16-byte IV from `arc4random_buf` and pass it
  to `CCCrypt`; `-AES256EncryptWithKey:` prepends it to the ciphertext, and
  `-AES256DecryptWithKey:` reads the first block as the IV and decrypts from the
  rest. A payload shorter than one block is refused rather than misread.
  Round-tripping is unchanged for callers; only the byte layout on the wire moved.
- **Test:** `testAES256EncryptionIsNotDeterministic`,
  `testAES256RoundTripOfAnEmptyPayload` and `testAES256RoundTrip`.
  The two category methods have no production caller -- the tests are the only
  users -- so the layout change breaks nothing outside the suite.

### `NSData (AES256)` silently falls back to an all-zero key when the key is over 32 bytes
- **Status:** Fixed
- **Where:** `MADDesigner/Source/NSData+AES256.m:24` and `:68`
- **Behavior:** The key is copied into a zeroed 33-byte buffer with
  `-getCString:maxLength:encoding:` and the return value is discarded. A key whose
  UTF-8 form does not fit fails the conversion and writes nothing, leaving the
  buffer as the 32 zero bytes it was `bzero`'d to. Two completely different
  over-long keys therefore produce identical ciphertext -- the key contributes
  nothing. A key of 32 bytes or fewer is copied in and zero-padded, which is the
  documented intent; the over-long case is not.
- **Now:** both methods check the `-getCString:maxLength:encoding:` result and
  return nil when the key does not fit. A short key is still zero-padded, which
  the test pins by decrypting under the explicitly padded form as well.
- **Test:** `testAES256KeyLongerThanThirtyTwoBytesIsRefused` and
  `testAES256ShortKeyIsZeroPadded`.

### `NSData (Base64) +dataFromBase64String:` writes past its output buffer
- **Status:** Fixed
- **Where:** `MADDesigner/Source/NSData+Base64.m:78`
- **Behavior:** `NewBase64Decode` sizes the buffer as `(length / 4) * 3`, but the
  store loop always writes 3 bytes per group, including the final partial group.
  For a length that is not a multiple of 4 the last group writes up to 3 bytes past
  the allocation: `@"YWJjY"` gets a 3-byte buffer and writes at offsets 3, 4 and 5.
  The decoded value is still correct because the returned length is tracked
  separately, so the overrun lands in malloc's slack and is invisible outside a
  guard-malloc or ASan run. The test can only pin the decoded value.
- **Now:** the allocation rounds up to a whole number of groups,
  `((length + 3) / 4) * 3`, so the final partial group is inside the buffer. The
  decoded bytes and the returned length are unchanged.
- **Test:** `testBase64DecodeOfTruncatedInput` (renamed from
  `testBase64DecodeOfTruncatedInputOverrunsItsBuffer`, whose old comment said the
  overrun was beyond what a test could see), with a comment recording that the
  buffer sizing is what changed.

### `+[NSDateFormatter RFC_3339]` rejects RFC 3339 timestamps with a numeric offset
- **Status:** Fixed
- **Where:** `MADDesigner/Source/NSDateFormatter+RFC_3339.m:23`
- **Behavior:** The format string ends in a literal `'Z'` rather than a timezone
  token, so only the `Z` spelling of UTC is accepted. Because the locale is
  `en_US_POSIX` the formatter is also strict, so `2020-01-15T13:45:00+02:00`
  returns `nil` instead of being misread as UTC. RFC 3339 permits both spellings,
  and a server timestamp using the offset form is silently dropped.
- **Now:** the format string ends in `XXXXX` ("ISO 8601 with a colon"), which
  emits `Z` for a zero offset and `±hh:mm` otherwise, and parses both spellings on
  the way in. The `Z` form still produces the same date as before.
- **Test:** `testRFC3339FormatterAcceptsAnExplicitNumericOffset` (renamed from
  `testRFC3339FormatterRejectsAnExplicitNumericOffset`), which asserts the epoch
  seconds of `2020-01-15T13:45:00+02:00`.

### `MADFeature -initWithDictionary:` yields type 0 for a missing "type" key
- **Status:** Partly fixed
- **Where:** `MADDesigner/Source/MADFeature.m:59`
- **Behavior:** Every key is read by subscripting and cast to `NSNumber` --
  `((NSNumber *)dictionary[@"type"]).shortValue`. A missing or non-numeric entry
  reads as `nil`, and messaging `nil` yields 0. Zero is not one of the two declared
  `MADFeatureType` values (`NonConsumable` = 1, `Subscription` = 2), so a plist typo
  produces a feature that is neither rather than an error. The method is deprecated
  in favour of the designated initialiser, so this may be moot in practice.
- **Now:** the numeric entries are shape-checked with `isKindOfClass:` before
  `-shortValue` is sent, so a wrong-shaped value ("type" as a string) reads as 0
  rather than crashing. The zero-type behaviour itself is left alone, per the
  "deprecated in favour of the designated initialiser" note above; it is now
  documented in a comment at the site.
- **Test:** `testFeatureFromDictionaryWithWrongShapedValuesDoesNotCrash`, plus the
  existing `testFeatureFromIncompleteDictionaryYieldsZeroedType`, which pins the
  zero type as intentional.

---

### `MADOperationConditionPolarQuestionAffirmative` discards the answer it was given
- **Status:** Fixed
- **Where:** `MADDesigner/Source/MADOperationConditionPolarQuestionAffirmative.m:65`
- **Behavior:** The satisfied branch calls
  `+[MADOperationConditionPolarQuestionAffirmativeResult newOperationConditionResult:name:]`
  with the *dependency object* in the `BOOL satisfied` position. On arm64, where
  `BOOL` is `_Bool`, the pointer converts to `YES` by way of "is not null" rather
  than by way of the dependency's answer -- so the condition does report satisfied,
  but the result's own `result` property is left at NO. A caller that reads the
  answer back off the result is told "no" after asking "yes".
  The negative condition next door does it correctly, through
  `+newOperationCondition:name:`, which sets `result`; the two are meant to be
  mirror images and only one of them is.
- **Why it matters:** Nothing points at the call site. `-fsyntax-only` on both
  `arm64` and `x86_64` accepts the line without a warning, so the mistake is only
  visible by reading the value back off the result. The behaviour pinned by the
  test is the arm64 one, where `BOOL` is `_Bool`; on `x86_64`, where it is
  `signed char`, the same expression is the low byte of the pointer instead.
- **Now:** the affirmative class declares and calls the same
  `+newOperationCondition:name:` the negative class uses, so the dependency's
  answer lands in the result's `result` property. The two classes are once again
  mirror images.
- **Test:** `testAffirmativeCarriesTheAnswerItWasGiven` (renamed from
  `testAffirmativeDropsTheAnswerItWasGiven`), which asserts the result's `result`
  is YES.

### `MADOperationConditionSuccess` asserts instead of failing when no dependency matches
- **Status:** Fixed
- **Where:** `MADDesigner/Source/MADOperationConditionSuccess.m:78`
- **Behavior:** When the loop finds no dependency whose `NSOperation.name` equals
  the condition's key, `result` is still nil at the end and the method hits
  `NSAssert(result != nil, @"We expect dependencies.")` before it can return. The
  `result != nil ? result : [self result: NO]` on the following line is therefore
  unreachable in Debug builds, which abort the calling operation instead. Release
  builds define `NS_BLOCK_ASSERTIONS` and do get the quiet failure, so the same
  input asserts in development and silently fails in production.
  Note also that `dependency.name` is read *before* the `conformsToProtocol:`
  check, which is only safe because `NSOperation` declares `name`.
- **Now:** the assert is gone and the method returns
  `result != nil ? result : [self result: NO]` in both configurations, so Debug
  and Release agree. The loop now skips dependencies that do not conform to
  `MADOperationTestResults` before reading their name, so the
  ordering note above no longer applies.
- **Test:** `testSuccessFailsWhenNoDependencyMatchesTheKey` (renamed from
  `testSuccessAssertsWhenNoDependencyMatchesTheKey`).

### `MADOperationConditionDisplayedAlertConfirm` returns nil when nothing can answer
- **Status:** Fixed
- **Where:** `MADDesigner/Source/MADOperationConditionDisplayedAlertConfirm.m:70`
- **Behavior:** If no dependency conforms to either
  `MADOperationConditionDisplayedAlertProtocol` or
  `MADOperationHoldsCredentialsProtocol`, the loop falls through and the method
  returns nil from a method declared `nonnull`. The empty-dependency case returns
  a proper failure, so the nil only appears when dependencies are present but
  none of them can answer -- which is the case a caller is least likely to test.
- **Now:** the fall-through returns
  `+[MADOperationConditionResult newOperationConditionResultFailedNotSatisfied:]`
  with the condition's name, the same failure the empty-dependency case above
  already returns.
- **Test:** `testDisplayedAlertConfirmFailsWhenNoDependencyCanAnswer` (renamed
  from `testDisplayedAlertConfirmReturnsNilWhenNoDependencyCanAnswer`).

### The document status signalling is inert at both ends
- **Status:** Resolved — 2026-10-06.  The signal end is wired (milestone d, below); the
  flag end is a **decision, not a defect**: `MADDocumentState.needsSave` and
  `.contextChagned` are kept deliberately as the reserved home of the planned
  cloud-status feature.  Nothing reads them today; nothing should delete them as dead
  code.
- **Where:** `MAD/Source/MADocument.m` (the `handleManagedObjectContext…` handlers and
  the `MADDocumentState` flags they write); `MADDesigner/Source/MADDesignerViewController.m`
  (`-managedObjectContextDidChange:`, `-managedObjectContextDidSave:`, `-addObservers`);
  `MADDesigner/Source/MADQueryViewController.m` (`-managedObjectContextDidChange:`,
  `-ingnoreManagedObjectContextChanges:` and `-observeManagedObjectContextChanges:`)
- **Behavior:** The status signalling is inert at **both** ends, not merely
  dormant pending a store signal.  Nothing can fire it -- `RptqStoreContext`
  posts no change notification -- and nothing consumes it either: a repo-wide
  grep shows no code reads `MADDocumentState.needsSave` or
  `.contextChagned`; the handlers write flags nothing uses.  The designer and
  query controllers likewise register for Core Data notifications the store
  never posts.  `MADDesignerViewController.m` carries a private `changedValues`
  shim on `RptqObject` that returns *every* attribute, not the actually-changed
  keys, so the handlers stay correct if they are ever delivered.
  `MADQueryViewController.m`'s `_suspendAutomaticTrackingOfChangesInManagedObjectContext`
  toggles nothing for the same reason, and its handler body was reduced to a
  no-op.  The observer method name `ingnoreManagedObjectContextChanges:` also
  carries a long-standing typo.
- **Now (milestone d):** the signal end is wired.  `RptqStoreContext` posts
  `RptqStoreContextObjectsDidChangeNotification` (object = the context, the same
  userInfo keys under `RptqStoreContext*` names since Phase D), coalesced to one post
  per run-loop turn, from `insertObjectForEntity:`, `markObjectChanged:`,
  `deleteObject:`, and after `save:`.  The designer's undo-button/element-refresh
  handler and the query controller's list tracking consume it again, and
  `MADModelDocument` / `MADQueryFull` receive it.  The remaining decision narrowed to
  the flags themselves and was made on 2026-10-06: keep `MADDocumentState.needsSave`
  and `.contextChagned` for the future cloud-status feature.
- **Found during the store migration.**

### Saves run unconditionally now, and each rewrites the whole store
- **Status:** Fixed
- **Where:** `MADDesigner/Source/MADDesignerViewController.m` (the bare
  `{ // Save unconditionally … }` blocks, e.g. `:2969`, `:2986`, `:3332`, `:3381`)
  and `MADDesigner/Source/MADDesignerElementView.m:286-292`
- **Behavior:** `RptqStoreContext` had no `hasChanges`, so every former
  `if ([context hasChanges])` guard was mechanically replaced with an
  unconditional save, and `-save:` was `writeGraph:replacingAll:YES` -- a full
  store rewrite. The pinch, pan, insert, and delete paths in the designer
  rewrote the entire store per gesture event, where Core Data saved only dirty
  objects.
- **Now:** `RptqStoreContext` tracks dirty objects -- every attribute set (a set
  to the same value is not a change), every relationship set on either end of
  the edge, every insert, and deletions as pending rows -- and `-save:` writes
  only the dirty rows, plus the position and join-table rows their to-many
  edges produce, in one transaction; a clean save does not touch the file.  The
  designer's guards are real `if ([context hasChanges])` checks again, so a
  no-op pan saves nothing.  Pinned by `testHasChangesTracksInsertEditAndSave`,
  `testSettingTheSameValueDoesNotDirtyTheRow`,
  `testACleanSaveLeavesTheStoreFileUntouched`,
  `testOnePropertyChangeWritesOnlyThatRow`,
  `testAnOrderedToManyReorderIsWrittenIncrementally`, and
  `testDeleteIsPendingUntilSave` in `RptqStoreContextTests`.

### The explorer lists no documents, and the Query tab lists no tables
- **Status:** Fixed
- **Where:** `MADDesigner/Source/MADExplorerController.m` (the file list) and
  `MADDesigner/Source/MADQueryViewController.m` / `MADQueryViewDataSource.m`
  (the query table list)
- **Behavior:** In the simulator the explorer's list stayed empty even with
  `London.mad` and `Music.mad` in the app group's `Documents/` directory, and
  the MAD Query tab rendered with no tables after opening London.
- **Now:** The Query tab was the gutted change-notification handler: once
  `RptqStoreContext` posts `NSManagedObjectContextObjectsDidChangeNotification`
  (milestone (d)'s change signal), the restored handler reloads the query lists
  and the tab shows the tables, links, groups, and predicate sections.  The
  explorer was not a store defect at all: its list is gated on the first-launch
  storage-option bootstrap, and in the headless simulator the option stays
  unset (no one can tap the prompt), leaving the explorer unconfigured.  With
  the storage option seeded to local, the explorer lists London and Music.
- **Found during the store migration.**

### Query group, link, and predicate lists load every row in the store
- **Status:** Fixed
- **Where:** `MADDesigner/Source/MADQueryViewDataSource.m` (the
  `queryLinksController`, `queryGroupsController`, and `queryPredicatesController`
  getters); `MADDesigner/Source/MTGroupByViewController.m` (`-viewDidLoad`)
- **Behavior:** Only `queryTablesController` filtered rows by the open query;
  the link, group, and predicate lists fetched every row of their entity, so a
  second query's rows would appear in the first query's lists.  The
  pre-migration fetched-results controllers had the same shape, so this was
  preserved behavior rather than a new regression.
- **Now:** the data source stores the query identifier and each list filters to
  it (links by `hasLeftField.inQueryTable.inQuery.identifier`, groups and
  predicates by `inQuery.identifier`); the group-by picker scopes to the
  document's default query; and the restored change-notification handler resets
  all four lists when any query row changes.
- **Found during the store migration.**

### The choose-field list used to fetch a single field; it now fetches all of them
- **Status:** Fixed
- **Where:** `MADDesigner/Source/MADQueryChooseFieldController.m`
  (`-sections`)
- **Behavior:** The pre-migration controller built its sectioned
  fetched-results controller from `[RptqQueryField fetchRequestFields:1]` -- a
  fetch limited to one row -- so the picker showed at most one field.  The
  store-backed getter fetches every `RptqQueryField` and groups them by table
  alias.
- **Now:** the all-fields shape is confirmed right -- a field picker showing one
  row was the bug -- and the list honors the presenter's `excludeTables` (the
  link builder excludes the table being linked, by alias).
- **Found during the store migration.**

---


### The receipt check uses the deprecated SHA-1 verify API, and leaks its key on failure
- **Status:** Open -- found by the warning sweep, documented rather than changed.
- **What:** `MADDesigner/Source/MADVerificationController.m` validates the App Store
  receipt with `SecTrustCopyPublicKey` (`:482`, deprecated in iOS 14) and
  `SecKeyRawVerify` with `kSecPaddingPKCS1SHA1` (`:484`, deprecated in iOS 15), over a
  SHA-1 digest of the receipt (`CC_SHA1_*`, `:475-480`).  Separately, the analyzer's
  `osx.cocoa.RetainCount` check reports that `receipt_signing_key` (`:482`) leaks on the
  failure path: the `__Require` macros jump straight to `outLabel`, and the `CFRelease`
  at `:489` is only reached when verification succeeds.
- **Why it is not changed here:** swapping `SecKeyRawVerify`/PKCS1SHA1 for
  `SecKeyVerifySignature` with `kSecKeyAlgorithmRSASignatureMessagePKCS1v15SHA256`
  changes which signatures the app accepts -- a security decision, not a warning fix.
  The leak is mechanical in comparison: drop the `CFRelease` at `:489` (the success path
  falls through to `outLabel`) and release there instead.
- **Where:** `MADDesigner/Source/MADVerificationController.m:475-489`.
- **Reproduction:** the analyzer reports both the deprecation and the leak on every
  `xcodebuild analyze` of the app scheme.


### The barcode delegate's query-field accessors disagree with their declarations
- **Status:** Open -- found by the warning sweep; the mismatch is real and reachable.
- **What:** The `MADViewControllerBarcodeOptionsDelegate` protocol declares
  `- (RptqQueryField *)barcodeQueryField1;` and `:2`
  (`MADViewControllerBarcodeOptionsDelegate.h:60-61`), but `MTViewControllerBarcode`
  implements both returning `int64_t` (`MTViewControllerBarcode.m:321`, `:325`).  The
  caller `MTViewControllerBarcodeOptions.m:347` then messages the result
  (`[[delegate barcodeQueryField1] toStringHumanReadable]`), so an integer is treated as an
  object pointer -- a crash whenever that cell is populated.  The same file resolves the
  identifiers to `RptqQueryField` objects itself at `:168` and `:219`, which is what the
  protocol's callers appear to expect.
- **Why it is documented rather than fixed:** the correct shape depends on intent -- return
  the looked-up field object, or change the protocol and both call sites to the identifier.
  Both are real options and neither is a compile-fix.
- **Where:** `MADDesigner/Source/barcodes/MTViewControllerBarcode.m:321-327`,
  `MADViewControllerBarcodeOptionsDelegate.h:60-61`,
  `MTViewControllerBarcodeOptions.m:347,516`.
- **Evidence:** `-Wmismatched-return-types` on both implementations.


### AppDelegate's retry blocks capture themselves
- **Status:** Open -- documented; a leak rather than a crash.
- **What:** `tryOpen` and `tryRefresh` are `__block` blocks that reschedule themselves with
  `dispatch_after` (`AppDelegate.m:205`, `:256`), so each block retains itself until the
  retry chain ends.  These are the UI-test launch hooks; the cycle ends when the chain
  stops, but while retries are failing the block and everything it captures stay alive.
- **Where:** `MADDesigner/Source/AppDelegate.m:200-260`.


### An assertion formats an integer with %@
- **Status:** Open -- documented; debug-only.
- **What:** `MADQueryViewController.m:605` asserts
  `NSAssert(objectToDelete != nil, @"Need a non-nil value for %@", tableID)` where
  `tableID` is an `int64_t`; `%@` expects an object.  `NSAssert` is compiled out of
  Release builds, so this only bites in Debug, where the formatter will treat the integer
  as a pointer.
- **Where:** `MADDesigner/Source/MADQueryViewController.m:605`.


### MADToolboxStyleViewController passes an uninitialized value to a setter
- **Status:** Open -- documented from the analyzer run.
- **What:** `core.CallAndMessage` reports that the argument to a property setter at
  `MADToolboxStyleViewController.m:609` is uninitialized -- the value can be read before
  any assignment on some paths.
- **Where:** `MADDesigner/Source/MADToolboxStyleViewController.m:609`.


### The app passes possibly-nil values to non-null parameters
- **Status:** Open -- documented from the analyzer run.
- **What:** Three argument sites where a value that can be nil reaches a parameter the
  declarations call non-null: `AppDelegate.m:210`, `MADQueryBuilderSplitViewController.m:151`,
  `MADQueryChooseFieldController.m:169`.
- **Where:** the file:line list above.
- **Evidence:** `nullability.NullPassedToNonnull` in `xcodebuild analyze`.

## Build wiring (Xcode references)

Found while doing ROADMAP §2.1. These are project-file defects, not source defects:
a reference in a `.pbxproj` that names a path which does not exist, or a build
setting that names a platform no target can build for.

### Three library references named directories that were never created
- **Status:** Fixed
- **Where:** `MAD/MAD.xcodeproj/project.pbxproj` — `libct.a` and `libsybdb.a`, both
  at `../opt/lib/freetds/`; `Scrimpter/Scrimpter.xcodeproj/project.pbxproj` —
  `MADDataStructures.framework` at `../MADDataStructures/build/Debug-iphoneos/`
- **Behavior:** all three paths are relative to the project directory, so they named
  `MAD/../opt/lib/freetds/` and `Scrimpter/../MADDataStructures/build/…`. Neither
  directory has ever existed in this checkout.
- **Why it matters:** a dangling reference does not fail the build, so nothing surfaces
  it. `ld` is handed a file that is not there, then finds the library anyway through
  `LIBRARY_SEARCH_PATHS` — for MAD's two, the iOS slice in
  `Compressor/library/freetds/iOS/lib`. The reference is a lie that reads as a real
  dependency: it is what makes `MAD` look like it links freetds directly, when
  `MADTds` is the framework that does.
- **Now:** all three are gone — `PBXBuildFile`, `PBXFileReference`, Frameworks-phase
  entry and group child. MAD's two are safe to remove because `nm -u` on the built
  `MAD.framework/MAD` reports no `ct_`, `sybdb` or `tds` undefined symbols.
  Scrimpter's is removed from a project outside the workspace with no shared scheme,
  which could not already link: its `LIBRARY_SEARCH_PATHS` names a
  `DerivedData/Reports-dojbzwnmytpjqefezxjmhftrkacg` that does not exist, and nothing
  builds `MADDataStructures`. That Scrimpter's headers do
  `#import <MADDataStructures/MADDataStructures.h>` is recorded here so the dependency
  is not lost with the reference.
- **Evidence:** `MAD Designer` builds; `MAD` 176 tests, 0 failures.

### Five library search paths named directories that were never created
- **Status:** Fixed
- **Where:** `MADMySQL/MADMySQL.xcodeproj/project.pbxproj` (the unsuffixed
  `LIBRARY_SEARCH_PATHS`, Debug and Release) and the MAD Viewer target in
  `MADDesigner/MAD Designer.xcodeproj/project.pbxproj` (Debug and Release)
- **Behavior:** MADMySQL's base value was
  `$(SRCROOT)/../Compressor/library/openssl/lib/iOS`; the real layout is
  `openssl/iOS/lib`, which the `[sdk=…]` arms already name correctly. The MAD Viewer
  target listed five directories that do not exist — `library/libsybdb`,
  `../libMySqlClientObjectiveC/build/Release-iphoneos`, `libMysqlClient/MysqlClient`,
  `../CloudManager/build/Debug-iphoneos`, `../MAD/MAD/build/Debug-iphoneos` — and named
  `$(PROJECT_DIR)` twice.
- **Now:** the base is `""` in MADMySQL, matching the sibling frameworks; the viewer's
  dead entries and the duplicate are gone. The link line the viewer target produces
  now carries exactly the surviving entries: `Compressor/library`,
  `library/libmysqlclient`, `library/libpng`, `library/openssl`, `MADDesigner`.
- **Test:** `MADMySQL` 58 tests, 0 failures, and the app build links MADMySQL.

### The workspace pinned MADTds with an absolute path
- **Status:** Fixed
- **Where:** `Reports.xcworkspace/contents.xcworkspacedata:44`
- **Behavior:** the MADTds `FileRef` was
  `location = "group:/Users/michael/Desktop/Reports/MADTds/MADTds.xcodeproj"` — the
  only absolute path in the workspace; every other project uses the portable
  `group:<name>` form. Moving the tree leaves a stale reference and the workspace
  drops MADTds.
- **Why it matters:** it makes the workspace machine-specific, so it is the first
  failure in the "move the source tree" portability test the Compressor rework sets
  out to pass.
- **Now:** `location = "group:MADTds/MADTds.xcodeproj"`, matching every other entry.
- **Evidence:** `xcodebuild -list -workspace Reports.xcworkspace` lists all 18
  schemes from a relocated copy of the tree.

### CLI/build.sh named a machine-specific DerivedData directory
- **Status:** Fixed
- **Where:** `CLI/build.sh:22`
- **Behavior:** the DerivedData default was
  `${HOME}/Library/Developer/Xcode/DerivedData/Reports-cozeiyczmvgrbeapplwfuygymqci`,
  a per-machine hash Xcode generated once on this machine. On any other checkout the
  script builds the frameworks and then looks for the products in a directory that
  does not exist.
- **Why it matters:** a fresh-clone `CLI/build.sh` could not find the frameworks it
  just built — the same portability failure the workspace fix above addresses, in the
  other build entry point.
- **Now:** the default is a project-local `${REPO_ROOT}/.cli-deriveddata`, passed to
  `xcodebuild -derivedDataPath`, and `.gitignore` carries it. `MAD_DERIVED_DATA`
  still overrides, as before.
- **Evidence:** `CLI/build.sh` builds from a clean tree and `CLI/build.sh --run
  inspect` runs.

### MADMySQL linked every build with a stray `-v`
- **Status:** Fixed
- **Where:** `MADMySQL/MADMySQL.xcodeproj/project.pbxproj` — the project-level Debug
  and Release `OTHER_LDFLAGS`
- **Behavior:** `OTHER_LDFLAGS = ("-lc++", "-v")` — every link of the framework and
  its tests ran the linker in verbose mode, burying the real link output.
- **Now:** `"-lc++"` alone.
- **Evidence:** `MADMySQL` 58 tests, 0 failures, with a quiet link line.

### The app target defined SQLITE_ENABLE_COLUMN_METADATA for nothing
- **Status:** Fixed
- **Where:** `MADDesigner/MAD Designer.xcodeproj/project.pbxproj` — the `MAD Designer`
  target's `GCC_PREPROCESSOR_DEFINITIONS_NOT_USED_IN_PRECOMPS`, Debug and Release
- **Behavior:** `SQLITE_ENABLE_COLUMN_METADATA=1` sat in the app's defines, where it
  is inert: the app compiles no `sqlite3.c` — the amalgamation is compiled by the
  `MADSqlite3` target, whose options come from `Compressor/sqlite3.xcconfig`. It read
  like a second home for SQLite flags, which is exactly the two-consumers mistake the
  H7 fix removed.
- **Now:** gone. The app's SQLite behavior is whatever `MADSqlite3` was built with,
  as it should be.
- **Evidence:** `MAD Designer` builds; `MADSqlite3` 72 tests pass, 5 skipped, 0
  failures.

### A macOS build cannot be wired from search paths alone
- **Status:** Fixed — by the Compressor rework's XCFramework rewiring
- **Where:** every vendored `.a` reference, e.g. `MAD/MAD.xcodeproj`'s `libarchive.a`
  at `../Compressor/library/libarchive/iOS/lib/libarchive.a`,
  `MADTds/MADTds.xcodeproj`'s `libct.a` at `freetds/iOS-arm64/lib/`, and
  `MADBarcodes/MADBarcodes.xcodeproj`'s `libpng.a` at `libpng/libpng.a`
- **Behavior:** `LIBRARY_SEARCH_PATHS` is the only one of the two that can be made
  SDK-conditional (the `[sdk=…]` arms). `PBXFileReference.path` cannot. A
  `[sdk=macosx*]` search path would therefore still link the iOS slice the file
  reference names, and `lipo -info` reports none of them as macOS:
  `libarchive/iOS/lib/libarchive.a` is `arm64 arm64e`, `freetds/iOS-arm64/lib/libct.a`
  is `arm64`, `openssl/iOS/lib/libssl.a` is `arm64 arm64e`. The linker refuses a file
  built for another platform.
- **Now:** every consumer target links an XCFramework, not a `.a` path, so the
  toolchain picks the slice for the platform being built and there is nothing to make
  SDK-conditional. The SDK-conditional search-path arms are deleted everywhere
  (the MAD Viewer target's legacy list and Scrimpter — outside the workspace — are
  the only survivors, unchanged). The matrix also builds macOS slices for every
  library, so `zlib/macOS` and `mysqlclient/macOS` now exist (Track 2.2's two
  missing rows).
- **Still blocked, and it stays so:** `SUPPORTED_PLATFORMS` cannot be extended with
  `macosx` yet, because every framework sits on `MADFoundation` and
  `MADFoundation/Source/MADApplication.h:13` imports `UIKit/UIApplication.h`. A probe
  (`xcodebuild build … -destination 'platform=macOS' SUPPORTED_PLATFORMS=macosx`) fails
  with `'UIKit/UIApplication.h' file not found`. Flipping the setting today would
  advertise a platform no target can compile for. The XCFrameworks are ready for the
  day that decoupling lands; nothing here unblocks the app-side macOS work.

### The MAD Viewer target has not linked since `09e0e7b8d`
- **Status:** Still open
- **Where:** the MAD Viewer target in
  `MADDesigner/MAD Designer.xcodeproj/project.pbxproj`
- **Behavior:** its build settings were left pointing into `MADStack/`, the directory
  `09e0e7b8d` ("Project cleanup and reorganization") deleted —
  `CODE_SIGN_ENTITLEMENTS` and `GCC_PREFIX_HEADER` at the Designer's old paths, and
  `INFOPLIST_FILE = MADStack/MADViewer/info.plist`. The build stopped at
  `ProcessProductPackaging` with *"Build input file cannot be found"*.
- **Now:** those six settings (Debug and Release) point at the viewer's own files under
  `Targets/MADViewer/`, which all exist, and the build reaches the link step.
- **Still broken:** the link then fails on seven undefined classes — `MADApplication`,
  `MADDesignerNavigationBar`, `MADNavigationControllerDesigner`,
  `MADNavigationControllerViewer`, `MADSalesReceipt`, `MADThemeManager` and
  `MADViewerNavigationBar`. They are the *Designer* target's own sources, and the
  viewer target neither compiles them nor links a framework that contains them. What
  the stand-alone viewer should be is a product decision, not a build-wiring repair,
  so it is recorded rather than patched.
- **When the viewer is repaired (2026-10-04):** it opens `.mad` documents, so it will
  need the legacy-store conversion sources the app and CLI compile —
  `MADDesigner/Source/MADStoreLegacy/MADStoreConverter.m` and
  `MADStoreLegacyConverter.m` — and its framework search paths must reach
  `MAD.framework`'s headers, which today they do not. Until then the converter is
  compiled into the Designer target and the CLI only.

---

## Already fixed (for reference)

### MADFoundation batch: ten defects, each caller-audited first
- **Status:** Fixed
- **Commit:** `39ffa249c` (also corrects two BUGS.md impact notes that were wrong)
- **Where:** `MADFoundation/Source/MADDataColumn.{h,m}`, `MADGroupOperation.{h,m}`,
  `MADKeyChain.m`, `MADOperationConditionResult.m`,
  `MADOperationConditionTestConnectionSuccess.m`
- **Behavior and fixes:**
  - `MADDataColumn -addRows:` looped `i <= count`, adding one row too many.
    **Now:** `i < count`. The old note said the SQLite result cache would be
    "one row too long"; that was wrong — the method has **no production
    caller**, so no phantom row ever existed.
  - `MADDataColumn -initWithType:` stored the `length:` argument into
    `dataLength`. **Now:** it stores `dataLen:`, matching the property name.
    Inert today (the one caller never reads it back); `number:`,
    `indexOfType:` and `length:` stay unused for the MADTdsClient pass.
  - `MADDataColumn -initWithPlist:` did not decode the `@"~MTNull~"`
    sentinel that `-copyPlist` writes. **Now:** a single named constant is
    used by both sides and the sentinel decodes back to `[NSNull null]`.
    The old note said this "corrupts report data"; also wrong — the sentinel
    only ever touched `defaultValue`, which nothing reads, and row cells ride
    under a separate `"column"` key and round-tripped intact.
  - `MADDataColumn -initWithCoder:` encoded but never decoded `notNull` /
    `autoIncrement`. **Now:** both are decoded.
  - `MADDataColumn -objectAtIndex:` was declared `instancetype` in the
    header while the implementation already returned `id`. **Now:** the
    header says `id`.
  - `MADGroupOperation -addOperation:` was declared taking `NSArray` but
    implemented taking `NSOperation`; single-argument `-addOperations:` was
    missing from the header. **Now:** both match the implementation and are
    declared.
  - `MADGroupOperation`'s delegate called
    `-finishWithError:self.aggregatedErrors.copy`, passing an *array* where a
    single `NSError *` was expected, re-wrapping it as one bogus "error" that
    was itself an array. **Now:** it calls `-finish:`, which takes the array.
    One-word fix — `-finish:` was already declared on `MADOperation`. Removes
    a latent crash in `MADViewerController.m:925`, which sends
    `-localizedDescription` to every element.
  - `MADKeyChain -deleteSavedPasswordForKey:error:` guarded with
    `if (deleteError != nil && *error != nil)`, dereferencing a `NULL` `error`
    and silently swallowing failures into a fresh `&err`. **Now:** the
    `NULL` case is legal and failures surface.
  - `MADOperationConditionTestConnection` (abstract base) returned `nil` from
    `-evaluateForOperation:`, violating the protocol's nonnull contract.
    **Now:** it asserts (`NSAssert(NO, … must be overridden)`) and returns
    `nil` in Release, matching the `MADDataTable` base.
  - `MADOperationConditionResult` built errors with
    `domain:NSStringFromClass([self class])`, putting the *result subclass*
    name in the domain. **Now:** the fixed `@"MADOperationCondition"`; the
    condition name still travels in `userInfo[MADOperationConditionKey]`.
- **Test:** MADFoundation 116 → 118, 0 failures. The characterization tests
  that pinned the buggy behaviour are flipped; `-finish:` gains the
  regression guard it never had
  (`MADGroupOperationTests.m` `testFinishingWithSeveralErrorsKeepsThemSeparate`).

### MADCocoaExtensions batch: seven defects, one deliberate non-change
- **Status:** Fixed
- **Commit:** `86e9ecfb9` (also corrects a BUGS.md "unused" claim that was wrong)
- **Where:** `MADCocoaExtensions/Source/CGGeometry+Extras.h`, `MADTextStyle.m`,
  `MTMath.{h,m}`, `MADColorSocial.{h,m}`
- **Behavior and fixes:**
  - `CGRectBottomLeft` / `CGRectBottomRight` / `CGRectTopRight` returned
    transposed points (right only for a square rect at `(0,0)`). **Now:**
    the real corners, matching the `CGCorner*PointInRect` siblings.
  - `CGCenterRect` returned `((x + w)/2, (y + h)/2)`. **Now:**
    `origin + size/2`.
  - `MADDirectionHorizontalDirectionOfPoint` had Left/Right swapped.
    **Now:** the name's plain reading. No caller either way.
  - `MADDirectionVerticalDirectionOfPoint` compared X instead of Y, so a
    vertical segment reported `NoDirection`. **Now:** it compares Y.
  - `MADGeneralDirectionOfDegrees` used strict inequalities, so exact
    boundary angles (`0`, `30`, `60`, …) fell through to `north`. **Now:**
    half-open octants.
  - `MADTextStyle`'s initializer passed `(bold, strikethrough, italic,
    underline)` to `MADLayoutTextStyleMake`, scrambling the flags.
    **Now:** the struct maker's order. The setters were already correct.
  - `MTMath`'s file-size conversion used integer division
    (`1500000` → `1.0`). **Now:** divides by `1000000.0`. Kept decimal
    megabytes — the house convention (`MADStandard`). The integer→double
    promotion needs an explicit `(double)` cast or
    `-Wimplicit-int-float-conversion` fires in every target that includes
    the header.
  - `MADColorSocial +newBlueTwitter` was declared `instancetype` but returns
    `newColorWitColors(…)`, a plain `UIColor`. **Now:** declared `UIColor *`.
    The old note said "the classes appear unused" — that was wrong: it
    renders the Twitter button at `MADAttributedStringCommon.m:32`. The
    genuinely unused `+newBlueLinkedIn` / `+newBlueFacebook` (never
    declared, never called) are deleted.
- **Deliberately not changed:** `CGRectAdjustForScale` — see the load-bearing
  entry under MADCocoaExtensions above. Only a comment was added.
- **Test:** MADCocoaExtensions 76, 0 failures. Every characterization test is
  flipped to pin the corrected behaviour.

### `MADDataTableFast -objectAtRow:column:` ignored its `column` argument
- **Status:** Fixed
- **Commit:** `f51be71ef`
- **Note:** Found during testing; the method now honors the column argument.
  Kept here as a record of the kind of bug this effort is meant to catch.

### `sqlite3_mprintf` was passed the SQL as its format string (8 sites)
- **Status:** Fixed
- **Where:** `MADSqlite3/Source/MADDataTableFast.m`, `MADDatabaseSqlite3.m`,
  `MADDataTableObjectEnumerator.m`, `MADDataTableSingleColumnEnumerator.m`
- **Behavior:** `sqlite3_mprintf` treats its first argument as a *format*, so
  passing SQL directly (`sqlite3_mprintf(sql.UTF8String)`) meant a `%` in that
  SQL was read as a conversion. The function would then consume arguments that
  were never passed and read whatever sat on the stack — mangling the statement
  or crashing.
- **Now:** every call passes a literal `"%s"` and the SQL as the argument.
  `grep -n sqlite3_mprintf MADSqlite3/Source/*.m` shows fourteen calls, none
  with a variable format string.
- **Note:** Reachability was low — a `%` would have to appear in a column or
  table name — but the failure mode was silent corruption. Found by inspection
  while fixing the `-dataForRow:error:` contract, not by a test; there is no
  regression test, because exercising it needs a schema identifier containing
  `%`.

### `MADDataTable` base class failed silently instead of trapping
- **Status:** Fixed (Phase 0)
- **Where:** `MADFoundation/Source/MADDataTable.m`
- **Behavior:** The base class stubbed every row and column operation. Worst
  case, `-addRow:error:` returned `YES` while discarding the row, so a storage
  subclass that forgot an override lost data and reported success.
- **Now:** the nine operations a concrete subclass must implement assert with
  `NSAssert(NO, @"%s must be overridden", __PRETTY_FUNCTION__)`, matching the
  existing unimplemented-enumerator group. `-addRow:error:` returns `false` in
  Release rather than `YES`.
- **Deliberately unchanged:** the optional bulk-insert hooks, and the read
  answers that are *truthful* for an empty table (`-count` → `0`, `-allObjects`
  → `@[]`, and friends). Asserting on those would turn a correct answer into a
  crash. See §3.2 of the architecture report for the split.
- **Test:** `MADDataTableRegressionTests.m` `testBaseTableAbstractOperationsAssert`
  (Debug-gated, since `NSAssert` compiles out of Release) replaced
  `testBaseTableOperationsAreInert`, which had pinned the silent behaviour.

### `MADDataTableFast -addRow:error:` was unprotected while a bulk insert ran
- **Status:** Fixed
- **Commit:** `470dfcab6`
- **Where:** `MADSqlite3/Source/MADDataTableFast.m`
- **Behavior:** Under `-beginBulkInsert` the table reuses one cached
  `_statementInsert` across every `-addRow:error:`, running
  `sqlite3_bind_*` → `sqlite3_step` → `sqlite3_clear_bindings` →
  `sqlite3_reset` on it. Nothing serialized those sequences, so two writers
  racing on one table would interleave binds on the same statement and lose
  rows. `SQLITE_OPEN_FULLMUTEX` does not help: the race is in the sequence, not
  inside any single sqlite call. The class's one concurrency primitive,
  `queueBulkAdd`, was used in a single place — `-endBulkInsert`'s barrier —
  which made the teardown of `_statementInsert` race the inserts too.
- **Now:** `-addRow:error:` runs the insert body under
  `dispatch_sync(queueBulkAdd)`, and `-endBulkInsert` finalizes the cached
  statement *inside* its `dispatch_barrier_sync`. On a serial queue the barrier
  and the sync are mutually exclusive, which is all the mutual exclusion the
  sequence needs. No caller had ever driven `-addRow:` from more than one
  thread, so this was a hazard rather than a live loss.
- **Test:** `MADDataTableRegressionTests.m` `testFastTableConcurrentWritersLoseNoRows`
  (four writers from a concurrent queue, 100 rows in and 100 enumerated out).
  The CONTRACT note on `testFastTableSerializedConcurrentWritesLoseNoRows` said
  concurrent writers were unsupported; it now says the opposite.

### A reloaded `MADDataTableFast` trusted a row counter that could be stale
- **Status:** Fixed
- **Commit:** `470dfcab6` (reload half); `850c32f51` (in-memory half)
- **Where:** `MADSqlite3/Source/MADDataTableFast.m`
- **Behavior:** The plist carries `rowCounter` but no rows — the rows live in
  the `.maddb` file — so `-loadWithPlist:` rehydrated the count from one source
  and the data from another. A table whose counter had drifted from its file
  came back reporting the drifted count. `-dropTable:`, `-deleteAll` and
  `-vacuumCacheDb` all change the row count without touching the counter.
- **Now:** the reload half landed first: `-loadWithPlist:` ends with
  `-recountRows`, which runs `SELECT COUNT(*) FROM t<tag>` against the select
  connection and falls back to the stored counter only when the file cannot
  answer (no table yet, or no handle). The in-memory half followed in
  `850c32f51` — `-dropTable`, `-dropTableName:` and `-deleteAll` zero the
  counter, `-vacuumCacheDb` deliberately does not because VACUUM keeps every
  row. `-numberOfRows` / `-count` still return the ivar rather than querying the
  file: that is the design, not a remaining gap, since `-recountRows` is the
  reload path's check and not a per-read cost. The caller audit that this entry
  used to ask for is recorded in the `MADSqlite3` section above — `-deleteAll`
  has no callers, `-dropTable` is reached only from `-removeAllObjects`, and
  `MTTableController` treats `count` as a page cursor.
- **Test:** `MADDataTableRegressionTests.m` `testFastTableReloadRecountsRowsFromCacheFile`
  (a plist claiming 99 rows over a file holding 3 now reports 3), plus
  `testFastTableDropTableZeroesRowCount`, `testFastTableDropForeignTableKeepsRowCount`,
  `testFastTableDeleteAllZeroesRowCount` and `testFastTableVacuumKeepsRowCount`.

### `MADDesignerTestConnection.m` was an empty template that still ran
- **Status:** Fixed
- **Where:** `MADDesigner/Targets/MADDesignerUnitTests/MADDesignerTestConnection.m`
- **Note:** An untouched Xcode template -- an empty `-testExample` and an empty
  `-testPerformanceExample` -- contributing two no-op tests to every run. The file
  and its four `project.pbxproj` entries have been removed.

---

## Test infrastructure (not product bugs)

### The XCUITest runner sees an empty accessibility tree for the app
- **Status:** Still open
- **Where:** `MADDesigner/Targets/MADDesignerUITests`
- **Behavior:** Every XCUITest query against the running app -- down to
  `app.debugDescription` -- reports no elements at all, so no UI assertion can
  pass in this environment.  The simulator exercise (open a sample, walk the
  three tabs) is instead driven with the app's launch arguments (see
  `AppDelegate.m`: `-UITestOpenSample`, `-UITestSelectTab`) and verified by
  screenshot.  `MADDesignerUITests.m` documents this and is intentionally empty.
- **Found during the store migration; not investigated.**

### `MADTestReportFormatter` was blocked, and the reason recorded was wrong
- **Status:** Fixed
- **Where:** `MAD/MADTests/MADTestReportFormatter.m`
- **Behavior:** The whole file was commented out. The register (and a memory note)
  said it could not be revived until the Core Data model was added to a build
  phase. That had already happened: `MAD.xcdatamodeld` is in the `MADTests`
  target's Sources phase, so `MAD.momd` is built into the test bundle and
  `MADCoreDataModelTests` has been loading it all along. The stated blocker was
  stale; what actually blocked the test was the fixture.
- **Now:** the test runs, and `testGroupFooterRowIDAssociation` passes. Four
  separate things had to be right, none of them the model:
  - `MADReportFormatter` takes a `MADocument` and reads `-filename`, the class of
    `-database`, `-managedObjectContext` and `-resetSectionLayoutManagers` from it.
    The test cast a plain `RptqDocument` to `MADocument *`, which is not one --
    hence the original `unrecognized selector`. A `MADTestReportFormatterDocument`
    test double now answers those four from the in-memory stack. A real
    `MADocument` cannot stand in: opening one routes through `-readFromURL:error:`,
    which unarchives a `.mad` the app's create path produces.
  - The model was loaded from `[NSBundle bundleForClass:[RptqDocument class]]`,
    the **MAD.framework** bundle, which has no `MAD.momd`. It is now loaded from
    the test bundle, the way `MADCoreDataModelTests` does it.
  - The context was flat. Every `Rptq` class assigns its required `identifier`
    in `-awakeFromInsert`, and that override is guarded by
    `self.managedObjectContext.parentContext`, so a flat context left every new
    object with a nil `identifier` and the save failed with
    `NSValidationMultipleErrorsError` (1560). The test now uses the two-context
    shape `MADocument` has.
  - Nothing was saved before formatting. `MADSectionsLayout` reads the sections
    through an `NSDictionaryResultType` fetch, and a dictionary-result fetch is
    answered from the store, so unsaved inserts are invisible to it and the
    layout came up with no sections -- nil-ing out the five section layouts and
    crashing at `MADSectionsLayout.m:115`. Both contexts are saved first.
- **Also:** the fixture had to model the cache's row shape: the group value keyed
  by `MADSectionGroupLayout -safeSortKey` (`alias + drop index + "." + field`),
  and a `MADIdentifierROWID` per row, which the sqlite-backed tables inject in
  their enumerators. With the bare field name as the key every row compared equal
  and the report collapsed into one group; with no row id every row reported 0.

### `MADDesignerUnitTests` was misconfigured and had not built in some time
- **Where:** `MADDesigner/MAD Designer.xcodeproj/project.pbxproj`,
  `MADDesigner/Targets/MADDesignerUnitTests/MADDesignerUnitTests.m`
- **Behavior:** Four separate pre-existing faults, all now fixed:
  - `IPHONEOS_DEPLOYMENT_TARGET` was `12.0` on both `MADDesignerUnitTests` and
    `MADDesignerUITests`, below the 15.0 floor this toolchain supports.
  - `INFOPLIST_FILE` pointed at `MADDesignerUnitTests/Info.plist`; the file is at
    `Targets/MADDesignerUnitTests/Info.plist`.
  - The unit-test target's Frameworks phase was empty. `BUNDLE_LOADER` resolves
    undefined symbols against the host *executable* only, not against the dylibs
    the app links, so `_OBJC_CLASS_$_MADQueryTest` and the other framework classes
    the tests use had to be linked explicitly.
  - The test file itself was the Xcode template plus a `testExample` that opened a
    live RDS instance in `us-east-1` with hardcoded credentials, against APIs that
    no longer exist. It was rewritten around the app's own helper categories and
    framework consumption.

### XCTest assertion macros split on commas inside square brackets
- **Where:** any test file using `XCTAssert*(...)`
- **Behavior:** The preprocessor separates macro arguments on commas that are not
  inside *parentheses*, so `XCTAssertEqualObjects(a, [Foo bar:baz, qux])` is torn
  into `expression2` and a stray variadic argument and fails to parse, with the
  error reported at the end of the statement rather than at the comma. Wrapping the
  send in parentheses, or hoisting it into a local first, fixes it. Worth knowing
  because the messages the app's conditions take are often two-argument sends.

