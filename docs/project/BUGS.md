# BUGS.md

A running triage list of defects, quirks, and suspicious behavior surfaced by the
unit-testing effort. Each entry is locked down by a characterization test so the
behavior is documented even before it is fixed.

**Fixed defects are archived.** An entry whose defect is fixed moves -- full text,
commit hashes, tests and all -- to [`BUGS_FIXED.md`](BUGS_FIXED.md), and a one-line
index of it stays below its framework heading here, so a reference to "BUGS.md, the X
entry" still lands. This file is the open record: what is still wrong, still
suspicious, or deliberately left as it is.

Status key:

- **Confirmed** -- a test proves the behavior is wrong; treat as a defect.
- **Investigate** -- suspicious but needs a human judgment call (may be an
  intentional hack or an old workaround).
- **Quirk** -- odd implementation detail that happens to produce correct output.
- **Open** -- known, and not fixed yet.
- **Fixed** -- corrected; the entry has been moved to `BUGS_FIXED.md`.

## MADAPI

*Archived (fixed; full text, test and any commit hash in [`BUGS_FIXED.md`](BUGS_FIXED.md)):*

- `MADDatabaseConnection` subclasses do not survive the base class's `NSCopying` / `NSCoding`
- `MADDatabase` is NSCoding-only, so secure archiving rejects it
- `MADConnectionViewController` / `MADConnectionSQLGenericViewController` `-databaseConnection` threw an NSString
- `MADDatabaseDataBinding`: `nil` vs `[NSNull null]` handled inconsistently
- `NSStringFromMADQueryType`: "TypeCache" missing for `MADQueryTypeCacheIndexDropParameters`
- `NSStringFromMADQueryType`: `MADQueryTypeSampleDataTableRange` unmapped

## MAD (framework)

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
- **Update (2026-10-17):** the attribute is now populated from the cached thumbnail PNG
  when the old `-thumbnail` property is empty
  (`MADocument.m -fileAttributesToWriteToURL:...`), so the Files-app icon gets the
  report's first page on the next save.  The keys are still deprecated; the QuickLook
  extension remains the follow-up.  Pinned by
  `MADDocumentTests testFileAttributesUseTheCachedThumbnailWhenThePropertyIsNil`
  (commit `8254c7264`).

### The renderer's page representation keeps only the last page it built
- **Status:** Quirk (inert -- nothing reads it)
- **Where:** `MAD/Source/MADPrintPageRenderer.m:300-301`
  (`-buildPageAtIndex:context:inPageRect:`), `MAD/Source/MADReportTextRepresentation.m`
  (`-removeAllPages`, `-setPage:forPageIndex:`).
- **Behavior:** Every page build clears the renderer's `textRepresentation` and then
  stores the page it just built, so after a full run of page 0 to page N-1 the
  representation holds page N-1 alone -- not every page, which is what a "text
  representation of the report" sounds like.  The call is `removeAllPages` *before*
  the walk, so it is a per-build reset, not a bug in the dictionary.
- **Why it does not bite:** the only reader is `-debugQuickLookObject`
  (`MADPrintPageRenderer.m:351`), which is a debugging view of the last page built;
  nothing else in the tree asks the representation for a page (`-pageIndex:` has no
  caller).  The headers' promise -- "the page is also recorded in -textRepresentation
  either way" -- is true per page.  A caller that wants all pages would get one.
- **Left as is** when the walk moved to `MADReportPageBuilder`
  (2026-10-16): the reset stayed with the renderer, where it was, so the behaviour
  the PDF and thumbnail paths see is unchanged.  If something ever needs the whole
  report's text, the reset belongs after the page loop (or in `-textRepresentation`'s
  owner), not inside `-buildPageAtIndex:`.
- **Test:** none -- there is no caller to characterize.  Recorded so the next reader
  does not mistake the one-page result for a lost page.

### MADMySQLFetch passes an uninitialized value to a function
- **Status:** Open -- documented from the analyzer run.
- **What:** `core.CallAndMessage` reports that the first argument of a function call at
  `MADMySQLFetch+DataTable.m:668` is uninitialized on some paths.
- **Where:** `MADMySQL/Source/MADMySQLFetch+DataTable.m:668`.

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
- **Note:** `MADocument.m:598,624` used to appear here too, covered by the
  `writeContents:` entry above; those two are gone with that entry's fix.
- **Where:** the file:line list above.
- **Evidence:** `nullability.NullReturnedFromNonnull` and
  `nullability.NullPassedToNonnull` in `xcodebuild analyze`.

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
- **Where:** `MAD/Source/model/MADModelQueryTable.m:92-105`
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

*Archived (fixed; full text, test and any commit hash in [`BUGS_FIXED.md`](BUGS_FIXED.md)):*

- `MADSQLParser` rejects schema-qualified table names (`schema.table`) in `FROM`, `JOIN`, and three-part column references
- `MADSectionLayout` reads CFNumbers at the wrong widths, corrupting adjacent ivars
- `digit_count_*_int`: `INT_MIN` collapsed onto `INT_MAX`
- `MADSectionGroupLayout` segfaults on a group whose field has no query table
- `MADReportFormatter compares untyped values through id`
- Rendered currency depended on the machine, not on the document
- `MADQueryActiveQueryFields`: the SELECT list's order is set order, and set order is not stable
- The same document does not produce the same `.mad` on Linux and on Apple — and on Linux it cannot be written at all
- `objectsForEntity:` missed every subentity row
- Opening a large report and refreshing spikes memory to ~8 GB and never renders a page
- Page draws run one SQLite transaction per cell, so opening a large report pegs the CPU
- `insertObjectForEntity:` mints identifiers per entity, not per table
- The milestone-(a) model rewrites dropped the schema sort orders
- A NULL read from a source database printed as the text `<null>`, or as the epoch
- `MADSectionLayout` computes no element height, so a report piles onto its first pages
- The store's colour columns have no reader, and the model's colour properties have no column
- `MADocument -managedObjectContext` returns a `RptqStoreContext` under a Core Data type
- `MADReportTextRepresentation` `-characterCount` / `-elementCount` crash on non-empty input
- `RptqDirectionalAsymmetry +keyRight` returns `@"left"`
- `MADDatabaseTypeReuseIds` (10) vs `MADDatabaseTypeNames` (9) mismatch
- `MADDataTableFast -allObjects` was unimplemented (FIXME)
- `MADQueryPredicate` and `MADQueryCacheSelectGroupKeys` quote string literals with double quotes
- `MADocument -paperSize` reads the `_paper` ivar the lazy `-paper` accessor builds
- `MTPaper -initWithType:` returned class objects for Legal and Government papers
- `MADArchiveManager -archive:` deleted its backup before it could restore it
- MADocument calls writeContents: with nil contents
- UIManagedDocument's resetPersistentStore is declared but never implemented
- MADModelQuery can insert a nil table into its dictionary
- The installed accessor blocks re-read a weak store context
- MADDataTableFast returns nil from methods declared non-null
- Image elements do not survive a save
- `MADImageThumbnail` draws page 1, so a one-page document's thumbnail is blank
- `MADPrintPageRenderer` ignores `withTransparentBackground:`
- `MADSectionLayoutAttributes +movePlacedItem:` teleports an isolated item to the origin
- MAD's document fixtures shared one store across test runs

## MADFoundation

### `MADDataTable` supports `NSCoding` but not secure coding
- **Status:** Open -- found while adopting `NSSecureCoding` on `MADDatabase`
  (2026-10-18); deferred as a larger change.
- **Where:** `MADFoundation/Source/MADDataTable.h:90` (`NSCoding`),
  `MADFoundation/Source/MADDataTable.m:73-110` (non-secure `-decodeObjectForKey:`),
  `MADFoundation/Source/MADDataTableVirtual.m:64-88`,
  `MADSqlite3/Source/MADDataTableFast.m:226-260`.
- **Behavior:** The base class declares `NSCoding`, and neither it nor either subclass
  implements `+supportsSecureCoding` or decodes with the class-matching APIs.
  `+[NSKeyedArchiver archivedDataWithRootObject:requiringSecureCoding:YES error:]`
  therefore has no secure codec to run, and
  `+[NSKeyedUnarchiver unarchivedObjectOfClass:fromData:error:]` refuses the result.
  The table's own cache path (`-cacheWithUrl:error:` /
  `-loadFromCacheWithUrl:error:`) uses property lists, not keyed archives; the keyed
  coding is the path `MADDataTableFast` overrides.
- **Why it matters:** A caller that archives a data table through the SDK's
  secure-coding default -- a cache, a document payload, an export -- cannot, and the
  insecure path is the only one that works.
- **Follow-up:** adopt `NSSecureCoding` in the base and both subclasses the way
  `MADDatabase` now does, with decode allowlists for `MADDataColumn`,
  `NSSortDescriptor`, the column keys and the row storage.
- **Test:** none yet; the existing coding tests use the permissive archiver.

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

### `MADDataTable`'s caching pair throws an NSError object, not an NSException
- **Status:** Confirmed (left as is -- no changed functionality)
- **Where:** `MADFoundation/Source/MADDataTable.m:139` (`-loadFromCacheWithUrl:error:`,
  code -213) and `:201` (`-cacheWithUrl:error:`, code -22)
- **Behavior:** Both nil-URL guards `@throw` the `NSError` object itself.  The other
  failure paths in the same methods return `NO` with the error handed back through the
  out-parameter.
- **Why it matters:** `@catch (NSException *)` -- the only shape the codebase writes --
  does not catch it, so a caller passing nil (which the signature already forbids: `url`
  is `nonnull`) gets an untyped object thrown past it.  The same shape as the MADAPI
  connection view controllers' `@throw NSInternalInconsistencyException;` (fixed
  2026-10-18).
- **Test:** `MADDataTableBaseTests testCacheWithNilUrlThrowsTheErrorObject` and
  `testLoadFromCacheWithNilUrlThrowsTheErrorObject`, which catch `id` and assert the
  thrown object's class, code and domain.
- **Documented (2026-10-18):** both declarations in `MADDataTable.h` now carry `///`
  comments saying `url` is required and that a nil URL throws the `NSError` object
  rather than filling `error` (commit `e72b1e8df`).  Behaviour is unchanged; the
  convention question is recorded at the bottom of this file.

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

*Archived (fixed; full text, test and any commit hash in [`BUGS_FIXED.md`](BUGS_FIXED.md)):*

- MADDataTable's cache loader dereferenced a null error pointer
- `MADOperationConditionResultTests`: the async-path assertion raced the dispatch_group
- Framework targets dropped `$(inherited)`, so `DEBUG` never reached framework code

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

## MADFileManager

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

### `MADDirectoryMonitor` swallows a failed start, and logs a multi-flag event as untracked
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

*Archived (fixed; full text, test and any commit hash in [`BUGS_FIXED.md`](BUGS_FIXED.md)):*

- `MADMetaData -fileSystemFileCreationDate` / `-fileSystemContentChangeDate` return `NSData` not `NSDate`
- `MADMetaDataLocal` downloading-status reports "current" but the derived flag says NO
- `MADFileInfo -isEqual:` has no matching `-hash` override
- `MADDirectoryMonitor`'s cancel handler dereferences a nil owner — SIGSEGV on dealloc

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

### `MADStandard -standardStringForFileSize:` has no byte/kB fallback
- **Status:** Quirk — **left as is** (a file under ~500 bytes shows `0.000 MB`,
  pinned by `testTinyFileReportsZero`)
- **Where:** `MADExplorer/MADExplorerTests/MADStandardTests.m`
- **Behavior:** Any file under ~500 bytes formats as `0.000 MB`.
- **Why it matters:** Tiny example reports/documents show `0.000 MB` in the
  explorer rather than a byte or kilobyte figure.

*Archived (fixed; full text, test and any commit hash in [`BUGS_FIXED.md`](BUGS_FIXED.md)):*

- The document-browser thumbnail stayed blank after the viewer rewrote it
- `MADStandard -standardStringForFileSize:` has dead code with a latent throw
- `MADStandard` hides `+standardStringForDouble:` / `+standardStringForUnsignedLong:`
- `MADOpenDocumentManager -removeDocumentWithUrl:` removed `self.openUrl` instead of `url`
- `MADThumbnailView` loaded thumbnails at `DISPATCH_QUEUE_PRIORITY_BACKGROUND` and blocked on `dispatch_sync(dispatch_get_main_queue(), …)`

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

*Archived (fixed; full text, test and any commit hash in [`BUGS_FIXED.md`](BUGS_FIXED.md)):*

- `MADArrayCaching` could build a cache URL from an empty identifier
- `MADDataTableFast` passed possibly-nil values into paths that raise
- `MADQueryCacheAddRow` built its placeholder list with `strcat`
- `fieldsForTable:` ran the tables query and returned tables as fields
- `connectWithConnection:credentals:connectionError:` returned nil after connecting
- `MADDataTableFast` stored an absolute cache URL that a container change invalidates
- `MADDataTableFast` left its row counter stale after an in-memory drop or delete
- `MADDataTableFast -deleteAll` built its query with the wrong initializer
- `The cache's ORDER BY ignores column types, so text keys sort binary`
- The bulk-insert row loop held the whole result set in autoreleased memory
- The SQLite engine was compiled with one of the twenty options the build script declared
- `MADArrayCaching -isEmpty` and `-count` were wrong for an empty cache
- `MADDataTableFast`'s read transactions crash without a selects database
- `MADDataTableFast -whereClauseForGroupKeys:` indexes past the sort descriptors

## MADBarcodes

*Archived (fixed; full text, test and any commit hash in [`BUGS_FIXED.md`](BUGS_FIXED.md)):*

- MADBarcode's type-name dictionary has a duplicate key
- Two symbology classes initialize with another class's type
- `MADBarcodeInternationalStandardBookNumberIsbn +type` calls itself
- `MADBarcode`'s NSCoding round trip loses everything
- `MADBarcode -drawInRect:` copies user input into `primary[128]` unchecked

### `MADBarcodeView` is the framework's one manual-retain-release file
- **Status:** Quirk (left as is)
- **Where:** `MADBarcodes/MADBarcodes/MADBarcodes/MADBarcodeView.m` (compiled with
  `-fno-objc-arc`), `MADBarcodeViewTests`
- **Behavior:** The project is ARC, but this one file keeps a `-dealloc` that releases
  `_barcode` and calls `[super dealloc]`, so it must stay `-fno-objc-arc`.  Its
  `-initWithFrame:` asserts "Don't you dare!", and `UIView -init` forwards there, so the
  view is only constructible from a storyboard (`-initWithCoder:`); a logic test cannot
  build one, which is why `MADBarcodeViewTests` pins the constructor contract and the
  property's declared storage instead of behaviour.
- **Test:** `MADBarcodeViewTests testProgrammaticConstructionIsRefused` and
  `testBarcodePropertyIsAnInstanceOfMADBarcode`.

## MADMySQL

Covered by an offline suite (`MADMySQLTests.m`) plus a live suite
(`MADMySQLLiveTests.m`) that runs against the development instance in
`DEVELOPER.md`. The live suite is the only way to reach `MADMySQLConnection`,
`MADMySQLFetch` and `MADMySQLFetch+DataTable`, which are thin wrappers over
libmysqlclient; it skips rather than fails when no server is reachable.

### `MADDatabaseMySQL -closeConnection:` and `MADMySQLConnection -dealloc` both `mysql_close` the handle
- **Status:** Confirmed (latent -- the closeConnection path is the create-document-from-schema import)
- **Where:** `MADMySQL/Source/MADDatabaseMySQL.m:397-403` and `MADMySQL/Source/MADMySQLConnection.m:79-85`
- **Behavior:** `-closeConnection:` calls `mysql_close` on the connection's handle, and the
  connection's own `-dealloc` calls `mysql_close` on the same handle again when the object
  dies. The handle's storage is calloc'd by the connection and `free_me` is false, so
  neither call frees the struct -- but each call frees the session's internal buffers, so
  the second is a double free.
- **Why it matters:** Only latent. Every other path drops the connection without
  `-closeConnection:`, so the single close in `-dealloc` is the common case; the import
  path (`MADOperationCreateDocumentImportSchema.m:246,293`) is the only caller that
  closes and then releases. Recorded during the connector rewrite so the next reader does
  not mistake the arrangement for one that was checked.
- **Test:** none -- the path needs the app and a live server.

### `MADMySQLInsert -execute` reports `ULONG_MAX` rows for a duplicate it ignored
- **Status:** Quirk (left as is)
- **Where:** `MADMySQL/Source/MADMySQLInsert.m:110-126`
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

### `MADMySQLTruncate`'s factories skip the nil-connection check the other DML classes make
- **Status:** Quirk (left as is)
- **Where:** `MADMySQL/Source/MADMySQLTruncate.m:30-40` against `MADMySQLInsert.m:44-50`,
  `MADMySQLUpdate.m:43-50`, `MADMySQLDelete.m:28-34`
- **Behavior:** `MADMySQLInsert`, `MADMySQLUpdate` and `MADMySQLDelete` all raise
  `MADMySQLException` from their factories when handed a nil connection; the two truncate
  factories do not, and hand back an object that fails at `-execute` instead.
- **Why it matters:** A caller that checks for a raise (or relies on the factory to
  refuse) gets an object rather than a diagnosis.  Harmless today — nothing in-tree
  passes nil — but the four classes should behave the same way.
- **Test:** `MADMySQLTruncateTests testFactoryAcceptsANilConnection`.

*Archived (fixed; full text, test and any commit hash in [`BUGS_FIXED.md`](BUGS_FIXED.md)):*

- `MADMySQLConnection`'s transaction toggles crashed on a connection with no handle
- `MADMySQLConnection +connectToServer:error:` wrote through a NULL error pointer
- `MADMySQLFetch+DataTable` read an uninitialised `MYSQL_BIND` in its default case
- `MADMySQLFetch+DataTable`: no non-SELECT statement could ever execute
- `MADMySQLFetch+DataTable`: row loop spun forever on a fetch error
- `MADMySQLFetch+DataTable`: `MYSQL_TYPE_INT24` (MEDIUMINT) read 4 bytes as 8
- `MADMySQLFetch+DataTable`: bind and execute failures were never reported
- `MADMySQLFetch+DataTable`: `MYSQL_TYPE_NULL` left its out-parameters uninitialized
- `MADMySQLFetch+DataTable`: bindings and statement leaked on the error paths
- `MADMySQLFetch`: `mySQLTypeForType` returned wrong names for three types
- `MADDataTypeMySQL` mapping is lossy for three types
- `MADMySQLFetch+DataTable` comment claims SMALLINT/MEDIUMINT/BIT are unsupported
- `The fetch corrected a column's type from its first row`
- A backslash in a MySQL literal is an escape character, so ANSI quoting alone is wrong
- `MADMySQLUpdate -execute` raises an out-of-bounds string exception instead of its own error

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

### `MADTdsDb` leaks its login record and can execute on a NULL process
- **Status:** Open -- found by inspection during the 2026-10-17 warning pass; recorded, not
  changed.
- **Where:** `MADTds/MADTds/MADTdsDb.m:79` (`dblogin()`), `:94-105` (the `dbopen`/`dbuse`
  failure paths), and `:111-151` (`-executeQuery:`).
- **Behavior:** The `LOGINREC *login` returned at `:79` is never passed to `dbloginfree()`,
  not on the `dbopen` failure, not on the `dbuse` failure, and not after a successful
  connect. Separately, `-executeQuery:` hands `self.dbProcess` to `dbcmd`, `dbsqlexec`,
  `dbresults` and the row accessors without checking it for NULL, and `-connect` can leave
  it NULL.
- **Why it matters:** Each connection attempt leaks a login record. A query issued before a
  successful `-connect`, or after one failed, dereferences NULL inside freetds instead of
  failing cleanly.
- **Test:** none -- MADTds ships no test target; it is exercised through `MADTdsClient`.
  Both paths need a driver-level test before a fix.

## MADTdsClient

Covered by an offline suite (`MADTdsClientTests.m`, 47 tests) plus a live suite
(`MADTdsClientLiveTests.m`, 29 tests) that runs against the local SQL Server 2022
instance in `DEVELOPER.md` (`127.0.0.1`, `sa`, `AdventureWorksLT2022`). The live
suite is the only way to reach `-connect:andPassword:error:`,
`-getTablesFromConnection:error:`, `-fieldsForTable:connection:error:` and
`-runSQL:onDataTable:fieldKeys:process:error:`, which are thin wrappers over freetds;
it skips rather than fails when no server is reachable.

### `-runSQL:onDataTable:fieldKeys:process:error:` closes the connection it was given
- **Status:** Quirk (load-bearing — documented, not changed)
- **Where:** `MADTdsClient/Source/MADDatabaseSQLServer.m:1648`
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

*Archived (fixed; full text, test and any commit hash in [`BUGS_FIXED.md`](BUGS_FIXED.md)):*

- dbdatecrack was called with the sybase DBDATETIME under a microsoft DBDATEREC name
- `-runSQL:...`, `-runQuery:...` and `-executeSQL:...withError:` dropped their SQL errors
- `-getTables:` passed the process wrapper to freetds as if it were a `DBPROCESS`
- Every `DECIMAL` / `NUMERIC` value is lost or corrupted
- `-fieldsForTable:connection:error:` feeds sybdb type codes into a table of SQL Server type ids
- `+dataTypeForNativeType:` has no case for several live SQL Server types
- Every SQL `DATETIME` reads back one month late
- `-connectWithConnection:credentals:connectionError:` never reports its error
- `-connect:andPassword:error:` dereferences `*error` without a NULL check
- `-fieldsForTable:connection:error:` has dead error handling that dereferences a known-NULL pointer
- `port` is never passed to freetds
- `+newSafeQueryField:andTable:` does not split a schema-qualified table
- `-executeQuery:withDataTable:andError:` discards its error
- REAL and FLTN result values were narrowed through float before the NSNumber

## MAD Designer (app)

Covered by the hosted `MADDesignerUnitTests` bundle (74 tests across
`MADDesignerUnitTests.m`, `MADAppLogicTests.m`,
`MADAppOperationConditionTests.m`, and `MADStatusLabelRefreshTests.m`). The bundle
is hosted by `MAD Designer.app` (TEST_HOST/BUNDLE_LOADER), so it reaches the app's
own source through the running executable; the app's classes are declared locally
in the test files rather than imported, because `MADDesigner/Source` is not on the
bundle's header search path.

- The compiled model cannot be migrated by Core Data's inference (clashing renaming identifiers)

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

*Archived (fixed; full text, test and any commit hash in [`BUGS_FIXED.md`](BUGS_FIXED.md)):*

- The barcode delegate's query-field accessors disagree with their declarations
- AppDelegate's retry blocks capture themselves
- An assertion formats an integer with %@
- `MADToolboxFormatViewController` multi-selection decimal-count check never evaluated to `YES`
- MADToolboxStyleViewController passes an uninitialized value to a setter
- The app passes possibly-nil values to non-null parameters
- `MADFontSelectorViewController -setFamilyName:` calls itself recursively
- The Refresh / Formatting / Page status label in the Viewer toolbar was unreadable on Liquid Glass
- `MADTabBarController` recreated all three tab view controllers on every `-viewWillAppear:`

*Archived (fixed; full text, test and any commit hash in [`BUGS_FIXED.md`](BUGS_FIXED.md)):*

- The refresh path reads the shared store context from operation-queue threads
- The page-count updates never fire because the formatter instance is unstable
- The open-time reload operation hides the refresh activity indicator
- The "Formatting page N." status message was set but never shown
- `MADOperationRefresh` reports the connection error in place of the execution error
- `MTTableController` read a stale page count after a failed fetch
- `MADPageViewAttributes` decodes a missing cache date as 2001-01-01
- `MADPageViewAttributes` narrows `zoomScaleInital` and `contentScaleFactor` to float
- `NSData (AES256)` encrypts with a NULL IV, so ciphertext is deterministic
- `NSData (AES256)` silently falls back to an all-zero key when the key is over 32 bytes
- `NSData (Base64) +dataFromBase64String:` writes past its output buffer
- `+[NSDateFormatter RFC_3339]` rejects RFC 3339 timestamps with a numeric offset
- `MADOperationConditionPolarQuestionAffirmative` discards the answer it was given
- `MADOperationConditionSuccess` asserts instead of failing when no dependency matches
- `MADOperationConditionDisplayedAlertConfirm` returns nil when nothing can answer
- The document status signalling is inert at both ends
- Saves run unconditionally now, and each rewrites the whole store
- The explorer lists no documents, and the Query tab lists no tables
- Query group, link, and predicate lists load every row in the store
- The choose-field list used to fetch a single field; it now fetches all of them

## Linux build

### GNUstep's `-enumeratorAtURL:…` yields URLs with the containing directory stripped
- **Status:** Quirk (platform; worked around at the one call site that depends on it)
- **Where:** measured in `Linux/Tests/ToolchainProbe.m` (report item
  `directory-enumeration-url-form`) and worked around in
  `CLI/Source/MADCLIContainer.m:192` (`-memberPaths`)
- **Behavior:** On GNUstep 1.31.1, `-enumeratorAtURL:includingPropertiesForKeys:
  options:errorHandler:` yields child URLs *without* the directory that was
  enumerated: enumerating `file:///repo/…/London.dataset` yields
  `file:///Contents.json`, which resolved against the process's working directory
  (`/src/Contents.json` in the image). `-contentsOfDirectoryAtURL:`,
  `-enumeratorAtPath:` and `-subpathsAtPath:` are all correct, and
  `-URLByAppendingPathComponent:` is correct -- it is the URL-form enumerator alone.
  Apple's is correct, so this is a GNUstep defect, not ours.
- **Why it matters:** `mad inspect` listed **0 members** for a document whose files
  were plainly there (the store header and the element counts, which do not enumerate,
  were right). Framework call sites exist too (`MADArchiveManager.m:146`,
  `MADFileUtilities.m:64,448`, `UIDocument+Extras.m:23`) -- their suites pass, because
  none of them depends on the enumerator's URLs carrying the directory, so they were
  left alone rather than churned.
- **Now:** the CLI's member list uses `-subpathsAtPath:` (relative paths are what the
  list is made of anyway), which is correct on both platforms. The probe reports the
  GNUstep behaviour as a NEED, so a GNUstep release that fixes it shows up in
  `--probe` rather than going unnoticed.
- **Test:** the probe's report item (counted, never fatal).

*Archived (fixed; full text, test and any commit hash in [`BUGS_FIXED.md`](BUGS_FIXED.md)):*

- `mad refresh` over MySQL aborted: a category is not a symbol, so the linker dropped it
- Three `Rptq…+extras.h` imports were spelled in the wrong case, which only a case-sensitive filesystem can see
- The pinned cross-platform export digests went stale on the Apple side

## Build wiring (Xcode references)

Found while doing ROADMAP §2.1. These are project-file defects, not source defects:
a reference in a `.pbxproj` that names a path which does not exist, or a build
setting that names a platform no target can build for.

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

*Archived (fixed; full text, test and any commit hash in [`BUGS_FIXED.md`](BUGS_FIXED.md)):*

- Three library references named directories that were never created
- Five library search paths named directories that were never created
- The workspace pinned MADTds with an absolute path
- CLI/build.sh named a machine-specific DerivedData directory
- MADMySQL linked every build with a stray `-v`
- The app target defined SQLITE_ENABLE_COLUMN_METADATA for nothing
- A macOS build cannot be wired from search paths alone

## Already fixed (for reference)

*Archived (fixed; full text, test and any commit hash in [`BUGS_FIXED.md`](BUGS_FIXED.md)):*

- MADFoundation batch: ten defects, each caller-audited first
- MADCocoaExtensions batch: seven defects, one deliberate non-change
- `MADDataTableFast -objectAtRow:column:` ignored its `column` argument
- `sqlite3_mprintf` was passed the SQL as its format string (8 sites)
- `MADDataTable` base class failed silently instead of trapping
- `MADDataTableFast -addRow:error:` was unprotected while a bulk insert ran
- A reloaded `MADDataTableFast` trusted a row counter that could be stale
- `MADDesignerTestConnection.m` was an empty template that still ran

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

*Archived (fixed; full text, test and any commit hash in [`BUGS_FIXED.md`](BUGS_FIXED.md)):*

- `MADTestReportFormatter` was blocked, and the reason recorded was wrong
- Two parallel Linux suites raced over the same London fixture and sample database

## Conventions (not product bugs)

### Nullability and error reporting are not uniform across the program
- **Status:** Observation -- recorded, not a defect.
- **What:** Three related conventions are applied ad hoc:
  - **Parameter nullability:** some parameters are annotated `nonnull`; many are
    not, so a signature alone does not say whether nil is tolerated.
  - **Nil-argument behaviour:** the program has not decided to throw on nil
    parameters.  Some methods raise an `NSException`, some `@throw` the `NSError`
    object itself (`MADDataTable`'s caching pair), some return `NO` and fill an
    out-parameter, and some tolerate nil silently.
  - **Error format:** there is no uniform error domain, code range or `userInfo`
    contract; `MADDataTable` alone uses two domains
    (`NSStringFromClass([MADDataTable class])` with negative codes, and
    `MADDataTableErrorDomain`), and other classes define their own.
- **Why record it:** a caller cannot tell from a declaration how to handle a nil or
  invalid argument, and the same failure is reported in three different shapes.
  Choosing one convention is a project-wide design decision, not a one-file fix.
- **Mitigation (2026-10-18):** `MADDataTable -cacheWithUrl:error:` and
  `-loadFromCacheWithUrl:error:` now carry `///` comments naming their nil-URL throw.
  The rest of the program still has no convention.
