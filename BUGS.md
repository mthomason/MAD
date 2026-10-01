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

### `MADDataTableFast -allObjects` unimplemented (FIXME)
- **Status:** Investigate (known gap, not a regression)
- **Where:** `MAD/MADTests/MADDataTableRegressionTests.m`
- **Behavior:** Returns `nil` even when rows exist. Callers must use the
  enumerators instead.
- **Why it matters:** Low priority — the enumerators cover it, but any new code
  that assumes `-allObjects` works will silently get nothing.

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

### `MADDataColumn -addRows:` is off by one (appends one extra row)
- **Status:** Confirmed
- **Where:** `MADFoundation/MADFoundationTests/MADDataColumnTests.m`
- **Behavior:** `addRows:2` appends three default rows and `addRows:0` still
  appends one. The loop uses `i <= count` instead of `i < count`.
- **Why it matters:** Column sizing in the SQLite result cache will always be
  one row too long; anything that indexes off `count` will read a phantom
  trailing `NSNull`.

### `MADDataColumn -initWithType:` ignores `dataLen:`
- **Status:** Confirmed
- **Where:** `MADFoundation/MADFoundationTests/MADDataColumnTests.m`
- **Behavior:** `self.dataLength` is assigned from the `length:` parameter; the
  `dataLen:` argument is silently discarded.
- **Why it matters:** Callers that pass distinct data-length and display-length
  values get the wrong value stored.

### `MADDataColumn -copyPlist` / plist round-trip loses `NSNull`
- **Status:** Confirmed (asymmetry)
- **Where:** `MADFoundation/MADFoundationTests/MADDataColumnTests.m`
- **Behavior:** `copyPlist` encodes a default `NSNull` cell as the literal string
  `@"~MTNull~"`, but `initWithPlist:` does not convert that sentinel back to
  `[NSNull null]`. A plist round-trip turns a `NULL` cell into the string
  `@"~MTNull~"`.
- **Why it matters:** SQLite `NULL`s cached as `NSNull` become the string
  `"~MTNull~"` after a plist round-trip, corrupting report data.

### `MADDataColumn` NSCoding loses `notNull` / `autoIncrement`
- **Status:** Confirmed
- **Where:** `MADFoundation/MADFoundationTests/MADDataColumnTests.m`
- **Behavior:** `initWithCoder:` does not decode the `notNull` and
  `autoIncrement` flags; they come back `NO` after an archive round-trip.
- **Why it matters:** Any column metadata persisted via `NSCoding` drops its
  nullability / auto-increment constraints.

### `MADDataColumn -objectAtIndex:` returns `instancetype` instead of `id`
- **Status:** Quirk
- **Where:** `MADFoundation/Source/MADDataColumn.h`
- **Behavior:** The method is typed `instancetype` (i.e. `MADDataColumn *`), so
  comparing a cell against `[NSNull null]` (or any non-column object) needs a
  cast and produces a distinct-pointer-type warning.
- **Why it matters:** Cosmetic API smell; cells are arbitrary `id`, so the
  signature should be `id`. Not a runtime defect.

### `MADGroupOperation -addOperation:` header/impl type mismatch (and missing `-addOperations:`)
- **Status:** Confirmed
- **Where:** `MADFoundation/Source/MADGroupOperation.h` / `.m`
- **Behavior:** The header declares `-addOperation:(NSArray *)operation` but the
  implementation is `-addOperation:(NSOperation *)operation`. The single-argument
  `-addOperations:` (which exists in the implementation) is missing from the
  header entirely, so only `-addOperations:finishingOperation:` is publicly
  callable.
- **Why it matters:** The public API is misleading and hides a method that
  callers would otherwise use.

### `MADGroupOperation` finishes with an array passed to `-finishWithError:`
- **Status:** Confirmed (inspection; not yet exercised at runtime)
- **Where:** `MADFoundation/Source/MADGroupOperation.m` (delegate
  `-operationQueue:operationDidFinish:withErrors:`)
- **Behavior:** `[self finishWithError:self.aggregatedErrors.copy]` passes an
  `NSArray<NSError *>` to `-finishWithError:`, which expects a single
  `NSError *`. The array is copied and re-wrapped, collapsing the group's
  multiple errors into one bogus "error" that is itself an array.
- **Why it matters:** Error aggregation is the whole point of a group
  operation; the aggregated errors are mis-reported.

### `MADOperation -willEnqueue` advances past `Pending` to `Ready`
- **Status:** Confirmed
- **Where:** `MADFoundation/MADFoundationTests/MADOperationTests.m`
- **Behavior:** `-willEnqueue` sets `state = Pending`, but because `isReady` is a
  KVO-dependent key of `state`, the `didChangeValueForKey:@"state"` notification
  re-enters `-isReady`, which runs `-evaluateConditions` and advances a
  dependency-free operation straight to `Ready`. The operation never observably
  rests in `Pending`.
- **Why it matters:** Any code (or future test) that inspects state right after
  enqueueing will see `Ready` rather than `Pending`; the state machine skips a
  transition.

### `MADKeyChain -deleteSavedPasswordForKey:error:` mis-handles errors
- **Status:** Confirmed (inspection; not covered by a test — keychain calls)
- **Where:** `MADFoundation/Source/MADKeyChain.m`
- **Behavior:** The guard is `if (deleteError != nil && *error != nil)`. This
  dereferences `error` without a null check (crash if the caller passes `NULL`)
  and, even when `error` is non-NULL, only reports the failure when `*error` was
  already non-nil — so a deletion failure into a fresh `&err` is silently
  swallowed and the method returns success.
- **Why it matters:** Credential deletion failures are silently dropped, and the
  legal `error:NULL` call site crashes.

### `MADOperationConditionTestConnection` base class returns `nil` from `-evaluateForOperation:`
- **Status:** Quirk
- **Where:** `MADFoundation/Source/MADOperationConditionTestConnectionSuccess.m:58`
- **Behavior:** The class is an abstract middle class — only
  `MADOperationConditionTestConnectionSuccess` and
  `MADOperationConditionTestConnectionFailuare` implement
  `-evaluateForOperation:`; the base returns `nil`. That violates the protocol's
  nonnull contract, and the inherited `-evaluateForOperation:completion:` would
  pass that `nil` straight to the completion block.
- **Why it matters:** Nothing in the app instantiates the base directly, so it is
  latent rather than live — recorded so the `nil` is not mistaken for an
  intentional "always satisfied" signal.
- **Locked down by:** `testTestConnectionBaseClassProducesNoResult`.

### `MADOperationConditionResult` factories put the result class name in the error domain
- **Status:** Quirk
- **Where:** `MADFoundation/Source/MADOperationConditionResult.m:54`
- **Behavior:** `-newOperationConditionResultFailedNotSatisfied:` builds its error
  with `domain:NSStringFromClass([self class])`, so a failure raised by
  `MADOperationConditionHasResultStringResult` reports the domain
  `MADOperationConditionHasResultStringResult`. The *condition* name travels in
  `userInfo[MADOperationConditionKey]` instead.
- **Why it matters:** Error domain is not a useful way to tell which condition
  failed; code that switches on the domain rather than the userInfo key will be
  misled.
- **Locked down by:** `testFailedNotSatisfiedResultShape`.

---

## MADCocoaExtensions

### `MADTextStyle -initWithBold:italic:underline:strikethrough:` scrambles its flags
- **Status:** Confirmed
- **Where:** `MADCocoaExtensions/MADCocoaExtensionsTests/MADTextStyleTests.m`
- **Behavior:** The initializer passes `(bold, strikethrough, italic, underline)`
  to the struct maker, so `italic`/`underline`/`strikethrough` land in the wrong
  properties. The individual setters are correct; only the initializer is broken.
- **Why it matters:** Any text style created via this initializer gets the wrong
  underline/strikethrough/italic attributes rendered.

### `CGRectTopRight` / `CGRectBottomLeft` / `CGRectBottomRight` transpose X and Y
- **Status:** Confirmed
- **Where:** `MADCocoaExtensions/MADCocoaExtensionsTests/MADGeometryExtrasTests.m`
- **Behavior:** These inline helpers return transposed coordinates (e.g.
  `CGRectTopRight` returns `(origin.y, origin.x + width)` instead of
  `(origin.x + width, origin.y)`). The correctly-written `CGCorner*PointInRect`
  variants exist alongside them.
- **Why it matters:** Any caller using the `CGRect*` corner helpers gets the
  wrong point (they only look right for a square rect anchored at `(0,0)`).

### `CGCenterRect` computes the wrong center
- **Status:** Confirmed
- **Where:** `MADCocoaExtensions/MADCocoaExtensionsTests/MADGeometryExtrasTests.m`
- **Behavior:** `CGCenterRect` returns `((origin.x + size.width)/2,
  (origin.y + size.height)/2)` instead of `origin + size/2`. It is only correct
  when the origin is `(0,0)`. (`CGCenterOfRect` is the correct version.)
- **Why it matters:** Centering a non-zero-origin rect via `CGCenterRect` lands
  off-center.

### `MADDirectionHorizontalDirectionOfPoint` reports the inverse direction
- **Status:** Confirmed
- **Where:** `MADCocoaExtensions/MADCocoaExtensionsTests/MADDirectionTests.m`
- **Behavior:** Moving from `p1` to a `p2` to the right returns `MADDirectionLeft`
  (and moving left returns `MADDirectionRight`) — the Left/Right arms are swapped.
- **Why it matters:** Callers resolving horizontal swipe/drag direction get the
  opposite answer.

### `MADDirectionVerticalDirectionOfPoint` compares X instead of Y
- **Status:** Confirmed (copy-paste)
- **Where:** `MADCocoaExtensions/MADCocoaExtensionsTests/MADDirectionTests.m`
- **Behavior:** The alignment guard uses `CGFloatCompare(p2.x, p1.x)`, so a purely
  vertical segment (same X, different Y) reports `MADDirectionNoDirection`
  instead of `Up`/`Down`.
- **Why it matters:** Vertical movement is never classified as vertical.

### `MADColorSocial +newBlueTwitter` returns a `UIColor`, not a `MADColorSocial`
- **Status:** Confirmed
- **Where:** `MADCocoaExtensions/MADCocoaExtensionsTests/MADColorTests.m`
- **Behavior:** The method is declared `instancetype` but returns
  `newColorWitColors(...)`, a plain `UIColor`. Calling `.hexStringValue` (or any
  `MADColor` API) on the result would fail.
- **Why it matters:** The social-color API lies about its return type; the
  classes appear unused, but any future caller will be misled.

### `MTMath` file-size conversion uses integer division
- **Status:** Confirmed (quirk)
- **Where:** `MADCocoaExtensions/MADCocoaExtensionsTests/MTMathTests.m`
- **Behavior:** Both `madSystemFileSizeToMB` and
  `[MTMath newSystemFileSizeToMB:]` divide by `1000000` in integer arithmetic, so
  fractional megabytes are truncated (`1500000` → `1.0`). It is also decimal
  (×10⁶) rather than binary (×2²⁰).
- **Why it matters:** File-size display loses precision and mismatches the
  binary megabytes that `NSFileManager` typically reports.

### `CGRectAdjustForScale` shrinks regardless of zoom direction
- **Status:** Investigate
- **Where:** `MADCocoaExtensions/MADCocoaExtensionsTests/MADGeometryExtrasTests.m`
- **Behavior:** For `zoomScale > 1` it multiplies by `1/zoomScale`; for
  `zoomScale < 1` it multiplies by `zoomScale`. Both paths shrink the rect.
- **Why it matters:** If the intent is to scale by `zoomScale`, the zoom-in
  branch is inverted; if the intent is to normalize out an applied scale, the
  name is misleading. Needs a human judgment call.

### `MADGeneralDirectionOfDegrees` falls through to `north` on exact boundaries
- **Status:** Quirk
- **Where:** `MADCocoaExtensions/MADCocoaExtensionsTests/MADGeometryExtrasTests.m`
- **Behavior:** Because the range checks use strict inequalities, exact boundary
  angles (`0`, `30`, `60`, …) fall through to the default `north`.
- **Why it matters:** Cosmetically wrong only at exact boundary values.

### `newColorWitColors` misspells "With"
- **Status:** Quirk
- **Where:** `MADCocoaExtensions/Source/MADColor.h`
- **Behavior:** The public factory is named `newColorWitColors` (missing the
  "h"). A corrected `newColorWithColorsAlpha` variant already exists.
- **Why it matters:** Cosmetic API typo, consistent with the `TypeCache` typo
  noted under MADAPI.

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

No defects found. The `MADDataTypeUnknown → String`/`TEXT` coercions in
`MADDatabaseSqlite3` are intentional fallbacks and are covered by tests.

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

## Already fixed (for reference)

### `MADDataTableFast -objectAtRow:column:` ignored its `column` argument
- **Status:** Fixed
- **Commit:** `f51be71ef`
- **Note:** Found during testing; the method now honors the column argument.
  Kept here as a record of the kind of bug this effort is meant to catch.

---

## Test infrastructure (not product bugs)

### `MADTestReportFormatter` is blocked
- **Where:** `MAD/MADTests/MADTestReportFormatter.m`
- **Behavior:** Disabled; cannot be revived until the Core Data model is added
  to a build phase. See `memory/madtestreportformatter-blocked.md`.
