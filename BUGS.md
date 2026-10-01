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

---

## MAD (framework)

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
- **Test:** the `MADSqlite3` suite — 69 tests, 5 skipped, 0 failures — which did *not*
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

---

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

---

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

## MAD Designer (app)

Covered by the hosted `MADDesignerUnitTests` bundle (69 tests across
`MADDesignerUnitTests.m`, `MADAppLogicTests.m`, and
`MADAppOperationConditionTests.m`). The bundle is hosted by
`MAD Designer.app` (TEST_HOST/BUNDLE_LOADER), so it reaches the app's own source
through the running executable; the app's classes are declared locally in the test
files rather than imported, because `MADDesigner/Source` is not on the bundle's
header search path.

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

---

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

### A macOS build cannot be wired from search paths alone
- **Status:** Still open — this is ROADMAP §2.1's third bullet, and it cannot be done
  as written
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
- **The other half of the bullet is blocked too:** `SUPPORTED_PLATFORMS` cannot be
  extended with `macosx` yet, because every framework sits on `MADFoundation` and
  `MADFoundation/Source/MADApplication.h:13` imports `UIKit/UIApplication.h`. A probe
  (`xcodebuild build … -destination 'platform=macOS' SUPPORTED_PLATFORMS=macosx`) fails
  with `'UIKit/UIApplication.h' file not found`. Flipping the setting today would
  advertise a platform no target can compile for.
- **What it needs instead:** the macOS slices do exist on disk
  (`freetds/macOS-arm64` and `macOS-x86_64`, `openssl/macOS`, `libpng/macosx`,
  `bzip2/macOS`, `libarchive/macOS`), but reaching them wants either a second set of
  per-SDK file references or — the answer `MAD_CLI.md` §4.2 and ROADMAP Track 2.3
  already point at — one XCFramework artifact whose slice the toolchain picks. `zlib`
  and `libmysqlclient` have no macOS slice at all (Track 2.2).

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

