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
- **Status:** Investigate (leaning Confirmed)
- **Where:** `MADAPI/MADAPITests/MADDatabaseDataBindingTests.m`
- **Behavior:** Setting a `nil` value stores `[NSNull null]`, but setting an
  explicit `[NSNull null]` value leaves the stored value as `nil`. The two
  "no value" inputs should be treated identically.
- **Why it matters:** This is in the SQL result-binding path. During the
  Core Data → manual-SQL migration, database `NULL`s will flow through here, so
  a wrong `NULL`/`NSNull` round-trip will surface as bad report data.

### `NSStringFromMADQueryType`: "TypeCache" missing for `MADQueryTypeCacheIndexDropParameters`
- **Status:** Confirmed (cosmetic)
- **Where:** `MADAPI/MADAPITests/MADAPIEnumsAndConstantsTests.m`
- **Behavior:** `NSStringFromMADQueryType(MADQueryTypeCacheIndexDropParameters)`
  returns `@"MADQueryIndexDropParameters"` — the `TypeCache` segment is dropped.
- **Why it matters:** Any UI that surfaces the query-type name (logs, debug
  views, future AI-generated-query display) will show the wrong string.

### `NSStringFromMADQueryType`: `MADQueryTypeSampleDataTableRange` unmapped
- **Status:** Confirmed
- **Where:** `MADAPI/MADAPITests/MADAPIEnumsAndConstantsTests.m`
- **Behavior:** `MADQueryTypeSampleDataTableRange` (raw value 28) falls through
  the switch and returns `@"MADQueryTypeUnknown"`.
- **Why it matters:** A whole query type is unnamed; anything keyed off the name
  (persistence, UI) will mislabel it.

---

## MAD (framework)

### `MADReportTextRepresentation` `-characterCount` / `-elementCount` crash on non-empty input
- **Status:** Confirmed (crashes)
- **Where:** `MAD/MADTests/MADFormatterAndRepresentationTests.m`
- **Behavior:** Both methods fast-enumerate the page map directly, which yields
  the `NSNumber *` **keys** rather than the page values. A non-empty
  representation raises an "unrecognized selector" exception.
- **Why it matters:** These are the text-export / character-count paths, which
  will be exercised by the text/JSON export work in TODO.md.

### `RptqDirectionalAsymmetry +keyRight` returns `@"left"`
- **Status:** Confirmed (copy-paste bug)
- **Where:** `MAD/MADTests/MADRptqValueTypeTests.m`
- **Behavior:** `keyRight` delegates to `keyLeft`, returning `@"left"` instead of
  `@"right"`.
- **Why it matters:** Any asymmetric padding/border on the right edge of a report
  element will read/write the wrong key.

### `MADDatabaseTypeReuseIds` (10) vs `MADDatabaseTypeNames` (9) mismatch
- **Status:** Confirmed
- **Where:** `MAD/MADTests/MADRptqDatabaseTests.m`
- **Behavior:** The reuse-id table has one more entry than the localized-name
  table, so "Microsoft SQL Server" is missing a name and the two tables are
  misaligned past index 4.
- **Why it matters:** The new-document database-type picker likely iterates these
  arrays in lockstep; an off-by-one here can pick the wrong driver.

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
- **Status:** Confirmed (type lie)
- **Where:** `MADFileManager/Source/MADMetaData.m`, `MADMetaDataLocal.m`, `MADMetaDataCloud.m`
- **Behavior:** The header declares both as `@property (readonly) NSDate *`, but the
  accessor implementations are typed `- (NSData *)...`. The object that actually
  comes back is an `NSDate` (copied out of the file attributes), so callers that
  trust the compiler's `NSData` type will crash on methods like `-length`.
- **Why it matters:** The compiler and runtime disagree about these two types; the
  property/accessor mismatch is exactly the kind of thing that will bite once
  file metadata is routed through the new manual-SQL cache.

### `MADMetaDataLocal` downloading-status reports "current" but the derived flag says NO
- **Status:** Confirmed (inconsistency)
- **Where:** `MADFileManager/MADFileManagerTests/MADMetaDataTests.m`
- **Behavior:** `-ubiquitousItemDownloadingStatus` returns
  `NSMetadataUbiquitousItemDownloadingStatusCurrent`, yet
  `-isUbiquitousItemDownloadingStatusCurrent` hardcodes `NO` instead of deriving
  from that string. A local file simultaneously claims "current" and "not current".
- **Why it matters:** Any UI keying off the status boolean (e.g. a "downloading"
  spinner) will disagree with the status string.

### `MADMetaData -initWithURL:` / `-initWithMetadataItem:` are self-replacing factories
- **Status:** Investigate
- **Where:** `MADFileManager/Source/MADMetaData.m`
- **Behavior:** `-initWithURL:` never touches `self`; it allocates a fresh
  `MADMetaDataLocal` and returns that. Same for `-initWithMetadataItem:` (returns
  a `MADMetaDataCloud`). The caller's original `MADMetaData` allocation is dropped.
- **Why it matters:** Works as a class-cluster-style factory, but under ARC the
  original `self` is leaked and the `instancetype` signature lies about the
  concrete class. Callers doing `[[MADMetaData alloc] initWithURL:]` get a
  subclass back.

### `MADFileInfo -isEqual:` has no matching `-hash` override
- **Status:** Confirmed
- **Where:** `MADFileManager/MADFileManagerTests/MADFileInfoTests.m`
- **Behavior:** `-isEqual:` compares `URL.absoluteURL`, but `-hash` is left to
  `NSObject`'s identity hash. Two `MADFileInfo` objects for the same file compare
  equal yet hash differently.
- **Why it matters:** Using `MADFileInfo` as an `NSSet` member or `NSDictionary`
  key silently fails lookups/`containsObject:`.

### `MADFileUtilities -removeContentsOfDirectory:` removes the directory itself
- **Status:** Confirmed
- **Where:** `MADFileManager/MADFileManagerTests/MADFileUtilitiesTests.m`
- **Behavior:** The method removes each child and then removes the directory too,
  despite the name promising to remove only the contents.
- **Why it matters:** Callers expecting an empty directory left behind will find
  the directory gone.

### `MADFileUtilities` has several undeclared public-ish helpers
- **Status:** Quirk
- **Where:** `MADFileManager/Source/MADFileUtilities.m` (vs `.h`)
- **Behavior:** `+createDirectoryForUrlIfItDoesNotExist:`,
  `+contentsOfDirectory:withPathExtension:`, `+removeContentsOfDirectory:`,
  `+removeCachedFileForDocumentUrl:` etc. are implemented but not declared in the
  public header. The tests surface them via a test-only category.
- **Why it matters:** Hidden API is easy to break silently; these are likely
  intended to be either private or public but are currently neither clearly.

### `MADMetaDataLocal` reports 100% uploaded/downloaded for a local file
- **Status:** Quirk
- **Where:** `MADFileManager/Source/MADMetaDataLocal.m`
- **Behavior:** `-ubiquitousItemPercentUploaded` / `-ubiquitousItemPercentDownloaded`
  return `100.0` for a non-ubiquitous local file.
- **Why it matters:** Harmless if callers check `-isUbiquitous` first, but a
  bare progress read on a local file shows a full bar rather than "N/A".

---

## MADExplorer

> MADExplorer is almost entirely UI (collection-view cells, data sources, view
> controllers), which a logic test bundle cannot exercise. Its only non-UI logic
> is `MADStandard`, the file-size formatter below.

### `MADStandard -standardStringForFileSize:` uses decimal megabytes
- **Status:** Confirmed (quirk)
- **Where:** `MADExplorer/MADExplorerTests/MADStandardTests.m`
- **Behavior:** The scale is `1000000.0` (decimal MB) rather than `1048576.0`
  (binary MiB), so a `2^20`-byte file is reported as `1.049 MB` instead of
  `1.000 MB`.
- **Why it matters:** The number shown next to a file in the explorer won't match
  the binary megabytes that Finder / `NSFileManager` report.

### `MADStandard -standardStringForFileSize:` has dead code with a latent throw
- **Status:** Investigate
- **Where:** `MADExplorer/MADExplorer/MADStandard.mm`
- **Behavior:** The guard `if (filesize_str.length() <= range_end) { filesize_str.append(zero, range_end); }`
  is never taken for a `double` (the formatted string is always `dec_pos + 7`
  chars while `range_end` is `dec_pos + 4`). If it ever did execute, the two-arg
  `append(str, subpos)` overload would try to read the single-character `"0"` at
  `subpos >= 4` and throw `std::out_of_range`.
- **Why it matters:** Dead code that would crash if the input format ever changed;
  worth deleting or fixing the append argument count.

### `MADStandard -standardStringForFileSize:` has no byte/kB fallback
- **Status:** Quirk
- **Where:** `MADExplorer/MADExplorerTests/MADStandardTests.m`
- **Behavior:** Any file under ~500 bytes formats as `0.000 MB`.
- **Why it matters:** Tiny example reports/documents show `0.000 MB` in the
  explorer rather than a byte or kilobyte figure.

### `MADStandard` hides `+standardStringForDouble:` / `+standardStringForUnsignedLong:`
- **Status:** Quirk
- **Where:** `MADExplorer/MADExplorer/MADStandard.mm` (vs `MADStandard.h`)
- **Behavior:** Both class methods are implemented but not declared in the public
  header; the tests reach them via a test-only category.
- **Why it matters:** Same hidden-API smell as the `MADFileUtilities` helpers.

---

## MADSqlite3

No test-visible defects. The `MADDataTypeUnknown → String`/`TEXT` coercions in
`MADDatabaseSqlite3` are intentional fallbacks and are covered by tests.

One defect in this framework was found by inspection rather than by a test and is
recorded under "Already fixed (for reference)": eight call sites passed a variable
to `sqlite3_mprintf` as the format string.

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
- **Status:** Investigate
- **Where:** `MADMySQL/Source/MADDataTypeMySQL.m`
- **Behavior:** `MYSQL_TYPE_TIME` maps to `MADDataTypeDateTime` (not the dedicated
  `MADDataTypeTime`); `MYSQL_TYPE_NULL` maps to `MADDataTypeNumber` (not
  `MADDataTypeNull`); `MYSQL_TYPE_INT24` maps to `MADDataTypeInteger` (not
  `MADDataTypeInt24`). All three dedicated enum cases exist but are never
  produced by this mapping.
- **Why it matters:** A report designed against a TIME or MEDIUMINT column gets a
  column type that does not describe it. Pinned by tests rather than changed,
  since the enum is consumed across the app.

### `MysqlFetch+DataTable` comment claims SMALLINT/MEDIUMINT/BIT are unsupported
- **Status:** Quirk (stale comment)
- **Where:** `MADMySQL/Source/MysqlFetch+DataTable.m`
- **Behavior:** The comment block above the binding loop says these types are
  "not handled currently - exception will occur if used", but all three have
  `bindDataForStatement:` cases and fetch cases and work correctly.
- **Why it matters:** The comment discourages using types that are fine.

---

## MADTdsClient

Covered by an offline suite (`MADTdsClientTests.m`, 43 tests) plus a live suite
(`MADTdsClientLiveTests.m`, 26 tests) that runs against the local SQL Server 2022
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
- **Status:** Confirmed
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

### Every `DECIMAL` / `NUMERIC` value is lost or corrupted
- **Status:** Confirmed
- **Where:** `MADTdsClient/Source/MADDatabaseSQLServer.m:975-1035`
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
- **Locked down by:** `testSelectDecimalReturnsNotANumber`,
  `testSelectNegativeDecimalReturnsCorruptedValue`.

### `-fieldsForTable:connection:error:` feeds sybdb type codes into a table of SQL Server type ids
- **Status:** Confirmed
- **Where:** `MADTdsClient/Source/MADDatabaseSQLServer.m:1878`
- **Behavior:** The query selects `sys.columns.system_type_id` and passes it to
  `+dataTypeForNativeType:`, which is written against sybdb (`SYB*`) codes. The
  two numbering schemes overlap only for the legacy types, so the mapping is
  right by coincidence where it is right at all. `DECIMAL` is 106 in both — and
  106 has no case, so it falls to `default` and reports `String`. `VARBINARY` is
  165, which is not a sybdb code at all, so it also reports `String`. Unlike the
  query path there is no `SYBDECIMAL → SYBNUMERIC` rewrite here to save it.
- **Locked down by:** `testFieldsForTableMisreportsDecimalAndBinaryAsString`
  (`SalesLT.Product.Weight` and `.ThumbNailPhoto` both come back `String`).

### `+dataTypeForNativeType:` has no case for several live SQL Server types
- **Status:** Confirmed
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
- **Locked down by:** `testSelectModernDateTimeTypes`,
  `testSelectSmallMoneyIsRewrittenToMoney`.

### `-connectWithConnection:credentals:connectionError:` never reports its error
- **Status:** Confirmed
- **Where:** `MADTdsClient/Source/MADDatabaseSQLServer.m:1599`
- **Behavior:** `error = &dberror;` rebinds the parameter to a local, so the
  caller's out-parameter is never written. It also means the surrounding
  `if (error && dberror)` is always true when a failure occurred, so the
  `else` branch that would have produced the wrapper is skipped and the method
  returns `nil` — the only failure signal the caller gets.
- **Why it matters:** Callers pass an `NSError **` and get back nothing, so a
  failed connection is indistinguishable from any other nil return.
- **Locked down by:** `testConnectWithConnectionDoesNotReportErrorToCaller`.

### `-connect:andPassword:error:` dereferences `*error` without a NULL check
- **Status:** Confirmed
- **Where:** `MADTdsClient/Source/MADDatabaseSQLServer.m:1512`
- **Behavior:** The first statement of the failure path is
  `if (*error != NULL)`, and several later paths assign `*error` directly. A
  caller that passes `NULL` — which is the documented Cocoa convention for "I
  don't care" — crashes.
- **Why it matters:** Passing `NULL` is exactly what a caller who only wants
  the `DBPROCESS *` back would do.

### `-fieldsForTable:connection:error:` has dead error handling that dereferences a known-NULL pointer
- **Status:** Confirmed
- **Where:** `MADTdsClient/Source/MADDatabaseSQLServer.m:1878`
- **Behavior:** A branch reads
  `if (sqlReturnCode != SUCCEED && error == NULL) { if (error != NULL) {...} NSAssert(error == NULL, @"...", *error); }`
  — the inner test can never be true inside a block that already established
  `error == NULL`, and the assertion's message argument dereferences `*error`
  anyway.
- **Why it matters:** The failure this code was meant to handle is not reported
  at all; the code only looks like it is handled.

### `port` is never passed to freetds
- **Status:** Confirmed
- **Where:** `MADTdsClient/Source/MADDatabaseSQLServer.m:1512`
- **Behavior:** `MADDatabaseConnectionSQLServer` carries a `port` and includes it
  in `connectionString`, but `-connect:andPassword:error:` only calls
  `DBSETLUSER`, `DBSETLPWD`, `DBSETLAPP` and `DBSETLDBNAME`. `DBSETLPORT` is
  never called, so freetds always dials its default port.
- **Why it matters:** A SQL Server listening anywhere other than the default
  port cannot be reached, even though the connection UI lets the user type the
  port in. The live suite works only because the test instance is on 1433.

### `+newSafeQueryField:andTable:` does not split a schema-qualified table
- **Status:** Confirmed
- **Where:** `MADTdsClient/Source/MADDatabaseSQLServer.m:1624`
- **Behavior:** The method brackets the table name as a single identifier —
  `[[NSString alloc] initWithFormat:@"[%@].[%@]", tableName, fieldName]` — with
  no handling of a dot. `dbo.employees` therefore becomes
  `[dbo.employees].[emp_no]`, which is a table named `dbo.employees`, not a
  column of `dbo.employees`.
- **Why it matters:** Schema discovery returns schema-qualified names
  (`SalesLT.Customer`), so the generated SQL for any query built on a discovered
  table names a table that does not exist.
- **Locked down by:** `testNewSafeQueryFieldDoesNotSplitSchemaQualifiedTable`
  (a characterization test: it pins the current, wrong output).

### `-sqlSampleDataForField:andTable:` bypasses the base class's clause builders
- **Status:** Quirk
- **Where:** `MADTdsClient/Source/MADDatabaseSQLServer.m:1680`
- **Behavior:** The override hardcodes `SELECT DISTINCT TOP 511 ...` instead of
  composing `-selectPart` / `-selectPartWithLimitedResults:` and calling
  `-sqlAggregateFunctionLength` the way the base class does. It works, and it
  is the reason SQL Server sample data does not emit the base class's invalid
  `LIMIT 511;`, but the two paths will drift.
- **Why it matters:** Nothing is broken today; noted so the duplication is not
  mistaken for the base implementation.

### `-executeQuery:withDataTable:andError:` discards its error
- **Status:** Confirmed
- **Where:** `MADTdsClient/Source/MADDatabaseSQLServer.m:319`
- **Behavior:** It declares `NSError * __autoreleasing dberror = nil`, passes
  `&dberror` to the connect call, and then never reads `dberror` or writes
  `*error`. A connection failure returns `NO` with no explanation.
- **Why it matters:** Same as `-connectWithConnection:...` above: the caller's
  `NSError **` contract is not honoured.

---

## MAD Designer (app)

Covered by the hosted `MADDesignerUnitTests` bundle (68 tests across
`MADDesignerUnitTests.m`, `MADAppLogicTests.m`, and
`MADAppOperationConditionTests.m`). The bundle is hosted by
`MAD Designer.app` (TEST_HOST/BUNDLE_LOADER), so it reaches the app's own source
through the running executable; the app's classes are declared locally in the test
files rather than imported, because `MADDesigner/Source` is not on the bundle's
header search path.

### `+[MADDateFromTimeFormatter timeIntervalForResolution:]` returns 0.1 seconds for a millisecond
- **Status:** Confirmed
- **Where:** `MADDesigner/Source/NSDate+Extras.m:250`
- **Behavior:** The `MTDateResolutionMillisecond` case returns `0.1`. A millisecond
  is a thousandth of a second (`0.001`), so the value is 100x too large. The caller
  at `MADViewerController.m:870` hands this straight to
  `+[NSTimer scheduledTimerWithTimeInterval:]`, so a viewer refresh armed at
  "millisecond" resolution runs at 10 Hz rather than 1000 Hz.

### `+[MADDateFromTimeFormatter timeIntervalForResolution:]` has no case for year, month, or week
- **Status:** Confirmed
- **Where:** `MADDesigner/Source/NSDate+Extras.m:253`
- **Behavior:** The switch covers only Day, Hour, Minute, Second, and Millisecond.
  Year, Month, and Week fall through to `default:` and return `86400.0` -- one day
  -- so a caller asking for year resolution gets a timer that fires daily.
  `-stringWithTimeIntervalSinceDate:` *does* report `MTDateResolutionYear`,
  `MTDateResolutionMonth`, and `MTDateResolutionWeek`, so the two halves of the
  class disagree about which resolutions exist.

### `MADPageViewAttributes` decodes a missing cache date as 2001-01-01
- **Status:** Confirmed
- **Where:** `MADDesigner/Source/MADPageViewAttributes.m:61` and `:84`
- **Behavior:** `-encodeWithCoder:` writes
  `_reportLastCacheDate.timeIntervalSinceReferenceDate`; messaging `nil` yields
  `0.0`. `-initWithCoder:` reads it back with `-decodeDoubleForKey:` and builds
  `[[NSDate alloc] initWithTimeIntervalSinceReferenceDate:]`, which cannot return
  `nil`. "Never cached" therefore round-trips as the reference date, 2001-01-01
  00:00:00 UTC, and a caller testing the property for `nil` will not see it. A
  genuine 2001 date encodes to the same 0, so the two states are indistinguishable
  afterwards.

### `MADPageViewAttributes` narrows `zoomScaleInital` and `contentScaleFactor` to float
- **Status:** Quirk
- **Where:** `MADDesigner/Source/MADPageViewAttributes.m:53` and `:56`
- **Behavior:** Both are `double` properties, encoded with `-initWithDouble:` and
  decoded with `-.floatValue`, so only single precision survives a round trip.
  Harmless for the values the app actually stores (zoom scales near 1.0), but the
  coding round trip is not lossless.

### `NSData (AES256)` encrypts with a NULL IV, so ciphertext is deterministic
- **Status:** Confirmed
- **Where:** `MADDesigner/Source/NSData+AES256.m:35` and `:67`
- **Behavior:** `CCCrypt` is called with a NULL IV, so every encryption under a
  given key uses an all-zero IV. The same plaintext always produces the same
  ciphertext, which leaks whether two stored values are equal. Fixing it means
  generating a random IV and storing it alongside the ciphertext.

### `NSData (AES256)` silently falls back to an all-zero key when the key is over 32 bytes
- **Status:** Confirmed
- **Where:** `MADDesigner/Source/NSData+AES256.m:22` and `:54`
- **Behavior:** The key is copied into a zeroed 33-byte buffer with
  `-getCString:maxLength:encoding:` and the return value is discarded. A key whose
  UTF-8 form does not fit fails the conversion and writes nothing, leaving the
  buffer as the 32 zero bytes it was `bzero`'d to. Two completely different
  over-long keys therefore produce identical ciphertext -- the key contributes
  nothing. A key of 32 bytes or fewer is copied in and zero-padded, which is the
  documented intent; the over-long case is not.

### `NSData (Base64) +dataFromBase64String:` writes past its output buffer
- **Status:** Confirmed
- **Where:** `MADDesigner/Source/NSData+Base64.m:76` and `:107`
- **Behavior:** `NewBase64Decode` sizes the buffer as `(length / 4) * 3`, but the
  store loop always writes 3 bytes per group, including the final partial group.
  For a length that is not a multiple of 4 the last group writes up to 3 bytes past
  the allocation: `@"YWJjY"` gets a 3-byte buffer and writes at offsets 3, 4 and 5.
  The decoded value is still correct because the returned length is tracked
  separately, so the overrun lands in malloc's slack and is invisible outside a
  guard-malloc or ASan run. The test can only pin the decoded value.

### `+[NSDateFormatter RFC_3339]` rejects RFC 3339 timestamps with a numeric offset
- **Status:** Confirmed
- **Where:** `MADDesigner/Source/NSDateFormatter+RFC_3339.m:20`
- **Behavior:** The format string ends in a literal `'Z'` rather than a timezone
  token, so only the `Z` spelling of UTC is accepted. Because the locale is
  `en_US_POSIX` the formatter is also strict, so `2020-01-15T13:45:00+02:00`
  returns `nil` instead of being misread as UTC. RFC 3339 permits both spellings,
  and a server timestamp using the offset form is silently dropped.

### `MADFeature -initWithDictionary:` yields type 0 for a missing "type" key
- **Status:** Investigate
- **Where:** `MADDesigner/Source/MADFeature.m:52`
- **Behavior:** Every key is read by subscripting and cast to `NSNumber` --
  `((NSNumber *)dictionary[@"type"]).shortValue`. A missing or non-numeric entry
  reads as `nil`, and messaging `nil` yields 0. Zero is not one of the two declared
  `MADFeatureType` values (`NonConsumable` = 1, `Subscription` = 2), so a plist typo
  produces a feature that is neither rather than an error. The method is deprecated
  in favour of the designated initialiser, so this may be moot in practice.

---

### `MADOperationConditionPolarQuestionAffirmative` discards the answer it was given
- **Status:** Confirmed
- **Where:** `MADDesigner/Source/MADOperationConditionPolarQuestionAffirmative.m:63`
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

### `MADOperationConditionSuccess` asserts instead of failing when no dependency matches
- **Status:** Confirmed
- **Where:** `MADDesigner/Source/MADOperationConditionSuccess.m:90`
- **Behavior:** When the loop finds no dependency whose `NSOperation.name` equals
  the condition's key, `result` is still nil at the end and the method hits
  `NSAssert(result != nil, @"We expect dependencies.")` before it can return. The
  `result != nil ? result : [self result: NO]` on the following line is therefore
  unreachable in Debug builds, which abort the calling operation instead. Release
  builds define `NS_BLOCK_ASSERTIONS` and do get the quiet failure, so the same
  input asserts in development and silently fails in production.
  Note also that `dependency.name` is read *before* the `conformsToProtocol:`
  check, which is only safe because `NSOperation` declares `name`.

### `MADOperationConditionDisplayedAlertConfirm` returns nil when nothing can answer
- **Status:** Confirmed
- **Where:** `MADDesigner/Source/MADOperationConditionDisplayedAlertConfirm.m:51`
- **Behavior:** If no dependency conforms to either
  `MADOperationConditionDisplayedAlertProtocol` or
  `MADOperationHoldsCredentialsProtocol`, the loop falls through and the method
  returns nil from a method declared `nonnull`. The empty-dependency case returns
  a proper failure, so the nil only appears when dependencies are present but
  none of them can answer -- which is the case a caller is least likely to test.

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

### `MADDesignerTestConnection.m` was an empty template that still ran
- **Status:** Fixed
- **Where:** `MADDesigner/Targets/MADDesignerUnitTests/MADDesignerTestConnection.m`
- **Note:** An untouched Xcode template -- an empty `-testExample` and an empty
  `-testPerformanceExample` -- contributing two no-op tests to every run. The file
  and its four `project.pbxproj` entries have been removed.

---

## Test infrastructure (not product bugs)

### `MADTestReportFormatter` is blocked
- **Where:** `MAD/MADTests/MADTestReportFormatter.m`
- **Behavior:** Disabled; cannot be revived until the Core Data model is added
  to a build phase. See `memory/madtestreportformatter-blocked.md`.

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

