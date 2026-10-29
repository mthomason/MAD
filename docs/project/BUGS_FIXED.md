# BUGS_FIXED.md

The archive of [`BUGS.md`](BUGS.md): every entry whose defect has been fixed, moved
here verbatim so the open file stays readable. Nothing is deleted -- the text, the
bug's behaviour, what the fix took, the test that pins it and the commit hash are all
as they were in `BUGS.md`.

An entry arrives here when its Status says the defect is fixed (or it sits under
*Already fixed (for reference)*, which predates the in-place convention). A partly
fixed entry stays in `BUGS.md`, because the rest of it is still open.

`BUGS.md` keeps a one-line index of each entry below its framework heading, so a
reference to "BUGS.md, the X entry" still lands.

## MADAPI

### `MADDatabaseConnection` subclasses do not survive the base class's `NSCopying` / `NSCoding`
- **Status:** Fixed 2026-10-18 (commit `a25756b5d`).
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
- **Now:** the four ivars are declared `@protected` in
  `MADAPI/Source/MADDatabaseConnection.h`, so a driver uses the base class's storage
  instead of shadowing it; the base's `-copyWithZone:` and coding methods therefore
  carry the standard properties, and `-initWithCoder:` dispatches through `[self init]`
  so a decoded driver's own initializer runs. The three drivers carry their own
  parameters as well: `MADDatabaseConnectionMySql` (host, database, port),
  `MADDatabaseConnectionSqlite3` (URL) and `MADDatabaseConnectionSQLServer` (host,
  server, database, port) override the coding pair, call super and restate
  `+supportsSecureCoding`. The header documents the contract for a third-party driver.
- **Test:** `MADDatabaseConnectionTests testSubclassCopyCarriesSubclassState` and
  `testSubclassNSCodingCarriesSubclassState` (renamed from `...DoesNotCarry...`), plus
  `MADMySQLTests testConnectionCodingRoundTripCarriesTheConnectionState`,
  `MADDatabaseSqlite3Tests testConnectionCodingRoundTripCarriesTheUrl` and
  `MADTdsClientTests testConnectionCodingRoundTripCarriesTheConnectionState`, each with
  its Linux port.

### `MADDatabase` is NSCoding-only, so secure archiving rejects it
- **Status:** Fixed 2026-10-18 (commit `4e9f5af6f`).
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
- **Now:** the class declares `NSSecureCoding` and implements
  `+supportsSecureCoding`; `-initWithCoder:` decodes the connection with
  `-decodeObjectOfClass:` and the errors array with `-decodeObjectOfClasses:` allowing
  `NSArray` and `NSError`. The classic insecure round trip still works.
  `MADDatabaseMySQL`, `MADDatabaseSqlite3` and `MADDatabaseSQLServer` override no
  coding methods, so they inherit the conformance and need no change (their own ivars
  were never encoded by the base class).
- **Now (initializer):** `-initWithCoder:` dispatches through `[self init]` rather
  than `[super init]` (commit `8d78329f9`), so a decoded subclass runs its own `-init`
  before the archived base state is applied -- `MADDatabaseSQLServer`'s
  `MADNotificationError` observer, for example. This matches `-copyWithZone:`, which
  already constructs the copy through the concrete class's initializer.
- **Test:** `MADDatabaseTests testSupportsSecureCoding` and
  `testSecureCodingRoundTrip` (which replaces `testSecureArchivingIsUnsupported`);
  `testInsecureNSCodingRoundTrip` still passes, and
  `testDecodingRunsTheSubclassInitializer` pins the initializer dispatch. The Linux
  port asserts the conformance claim and GNUstep's strict-archive refusal, because
  GNUstep has no secure archiving (`Linux/README.md`).

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
- **Status:** Fixed 2026-10-18 (commit `f492cb00f`).
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
- **Now:** both overrides build a real `NSException` with name
  `NSInternalInconsistencyException` and a reason naming the class to subclass,
  matching `MADDatabase`'s abstract methods.  A `@catch (NSException *)` now catches
  it.
- **Test:** `MADConnectionViewControllerTests testDatabaseConnectionThrowsOnBaseClass`
  and `testDatabaseConnectionThrowsOnSQLGenericClass`, which now catch `NSException`
  and assert its name and reason (previously they caught `id` and asserted the thrown
  object was the name constant).

## MAD (framework)

### `MADDesignerLayout` multi-selection undo clobbers per-element previous values with a single scalar
- **Status:** Fixed 2026-10-29.
- **Where:** `MAD/Source/MADDesignerLayout.m:157-555` (`-updateElements:setFontsize:`,
  `-updateElements:setFontname:`, `-updateElements:setVerticalAlignment:`,
  `-updateElements:setHorizontalAlignment:`, `-updateElements:setSizeWidth:`,
  `-updateElements:setSizeHeight:`, and the `-updateElements:setMargin*`,
  `-updateElements:setPadding*`, and `-updateElements:setBorder*` methods).
- **Behavior:** Each bulk-update method loops over `identifiers`, overwrites a single
  local `previous` scalar (`previous = element.fontsize;`, etc.), and then registers a
  single undo block that applies that one `previous` value back to all `elementIDs`.
  `-updateElements:setFontname:` (`:184`) captures only the *first* element's font name
  (`if (previous == nil) previous = element.fontname.copy;`), whereas all the numeric/enum
  setters capture only the *last* element's value (or `0.0` if `identifiers` is empty).
- **Why it matters:** When a user selects two or more report elements that have different
  sizes, fonts, alignments, margins, paddings, or borders and changes one property,
  pressing Undo overwrites every selected element with one element's old value instead of
  restoring each element's own prior state.
- **Now:** `MADDesignerLayout` records each element's prior value in a dictionary keyed by
  element identifier before applying the new value, and the undo/redo handler restores
  each element's individual value while recording the inverse dictionary on the opposite
  stack.
- **Test:** `MADDesignerViewerTests testDesignerLayoutMultiSelectionUndoRestoresPerElementValues`.

### `MADSQLParser` rejects schema-qualified table names (`schema.table`) in `FROM`, `JOIN`, and three-part column references
- **Status:** Fixed 2026-10-28.
- **Where:** `MAD/Source/sql/MADSQLParser.m:242-267` (`-parseSelectItemReturningError:`),
  `:367-380` (`-parseFromItemReturningError:`), and `:630-655`
  (`-parseColumnReferenceReturningError:`).
- **Behavior:** `MADDatabaseSQLServer` (`MADTdsClient`) and `MADDatabasePostgres`
  (`MADPostgres`, for tables outside `public`) store schema-qualified table names
  such as `SalesLT.Product` or `sales.orders` in the document schema and emit each
  dot-separated part as a separate quoted identifier (`[SalesLT].[Product].[Name]`,
  `"sales"."orders"."id"`).  `MADSQLParser` reads only a single identifier token after
  `FROM` or `JOIN` in `-parseFromItemReturningError:` (never consuming `.` + table) and
  at most one `.` qualifier in `-parseSelectItemReturningError:` /
  `-parseColumnReferenceReturningError:`, so pasting a statement generated for a
  schema-qualified table fails to parse even when the schema dictionary holds
  `"sales.orders"` or `"SalesLT.Product"`.  Tables in PostgreSQL's `public` schema are
  stored unqualified and round-trip through `MADSQLParser` without issue.
- **Why it is not changed here:** `MAD_SQL_ENTRY.md` §5 defines the parser grammar
  around single-token table names and two-part `table.column` references; extending it
  to optional `schema.table` / `schema.table.column` (plus drop-index alias checking on
  the qualified canonical name) is a parser grammar change in `MAD` outside the
  driver's scope.
- **Now:** `MADSQLParser` consumes an optional `.` + table identifier after the first
  identifier in `-parseFromItemReturningError:` (yielding `schema.table`), an optional
  second `.` in `-parseSelectColumnReturningError:` (`schema.table.col` and
  `schema.table.*`) and `-parseColumnReferenceReturningError:` (`schema.table.col`), and
  an optional `.` in a table alias.  Drop-index alias validation in both `MADSQLParser`
  and `MADSQLStatementResolver` accepts the table's own name or `<base><digits>` where
  `<base>` is either the qualified canonical name (`sales.orders0`) or the dot-stripped
  form emitted by `RptqQueryTable +queryAliasForSchemaTableName:dropIndex:`
  (`salesorders0`).
- **Test:** `MADSQLParserTests` (`testSchemaQualifiedTableAndThreePartColumnsParse`,
  `testQuotedSchemaQualifiedTableAndThreePartColumnsParsePerDialect`,
  `testSchemaQualifiedDropIndexAliasesParse`,
  `testAnUnknownSchemaQualifiedTableIsRejected`,
  `testAnUnknownThreePartColumnIsRejected`,
  `testARenamedSchemaQualifiedAliasIsRejected`) and `MADSQLQueryCompilerTests
  testSchemaQualifiedTableApplyAndFixpointRoundTrip`, plus their Linux ports.

### MADReportFormatter compares untyped values through id
- **Status:** Fixed 2026-10-18 (commit `483a77259`).
- **What:** `MADReportFormatter.m:219` and `:222` send `compare:` to a value held as `id`
  while several classes declare that selector with different argument types, so the
  compiler cannot bind it (`-Wstrict-selector-match`).  If the values being sorted are not
  all the same class -- the formatter sorts query results, which mix numbers and strings --
  the wrong implementation can be invoked, or none at all.
- **Where:** `MAD/Source/MADReportFormatter.m:210-225`.
- **Update (2026-10-18, documentation pass -- behaviour unchanged):** the value classes are
  bounded.  The values come from the row cache through
  `MADDataTableFast -enumeratorForKeyObjectsSorted:` -> `MADDataTableObjectEnumerator` ->
  `+[MADDatabaseSqlite3 databaseResultValue:columnNumber:]`, which maps SQLite's storage
  class to a Foundation class and carries no other tag: INTEGER/FLOAT -> `NSNumber`,
  TEXT -> `NSString`, BLOB -> `NSData`, NULL -> `NSNull`.  `NSDate` never comes from that
  reader.  The selector on each level's `NSSortDescriptor` is the schema-side type hint
  (`MADDataTypeSelectorForSorting`): string -> `localizedCaseInsensitiveCompare:`, blob ->
  `compareData:`, everything else -> `compare:`.  No new sqlite API and no per-value cache
  tag are needed: the object's class *is* the tag the reader produced, and the selector is
  the type already known further up the chain.  The cache's actual ordering is a separate
  matter: the formatter's enumerator builds its ORDER BY query with `columns:nil`, so today
  text keys sort binary while this selector says case-insensitive -- see "The cache's ORDER
  BY ignores column types" under MADSqlite3.  The warning is at the two `-compare:` sends in
  `-compareValue:withValue:usingSelector:`; the line numbers above have moved.
- **What actually goes wrong:** a mismatch between the selector and the value's class
  raises -- an `unrecognized selector` (for example an `NSNumber` sent
  `localizedCaseInsensitiveCompare:`) or Foundation's own argument-type exception -- it does
  not silently mis-sort.  The cache binds each column under its declared type, so a column
  is normally homogeneous, but the bind does not enforce the value's class.  Blob columns
  are the loose case (the bind accepts `NSString` and `NSData`, storing TEXT and BLOB), and a
  non-sqlite datasource can supply anything.  The London and Music fixtures exercise only
  matching pairs (London numeric, Music string).
  The entry's "mix numbers and strings" is across group levels, not within one: each level
  has its own value/selector pair, and only `NSOrderedSame` is read from the result.
- **Agreed design (2026-10-18):** the cache column's declared `MADDataType` is the source of
  truth for how a group key is compared -- it is the type the bind path actually stores and
  the type the cache's ORDER BY must use.  The grouping field's schema type is the design
  intent and the fallback when the cache has no column metadata.  A group level is one column
  with one declared type, and every key at that level is compared with a comparator chosen
  once, for that level, from the type.  Groups of groups are independent levels, each with its
  own comparator.  The per-group header/footer structure stays: the two walks express
  different domain behaviour (headers open outside-in, footers close inside-out), and both use
  the shared level comparator.  NULL is first-class in the comparator, not a fallback: `NSNull`
  implements no comparison, so the typed path never sees it.  Canonical representations:
  Date/DateTime/TimeStamp/Time -> `NSNumber` epoch (stored REAL, which is what the display
  path already reads); Decimal -> `NSNumber` double (stored REAL, with documented precision
  loss); the remaining `MADDataType` values get the same table before implementation.
- **Where the contract belongs:** `MADDatabaseDataBinding
  -initWithDataType:fieldIndex:value:` is the single construction point for the bulk insert,
  the non-bulk insert and the aggregate WHERE bindings, so it is where the canonical class is
  chosen; `-[MADDatabaseSqlite3 bindStatement:withBindings:]` keeps a defensive assertion and
  one-time log for a hand-built binding.  The bind path must store one canonical class per
  declared `MADDataType` -- number -> `NSNumber`, string -> `NSString`, blob -> `NSData`,
  null -> `NSNull`, with Date and Decimal as above -- and log or reject a value it cannot
  represent instead of binding nothing or another class.  The reader
  (`+databaseResultValue:columnNumber:`) can then answer a class that is a function of the
  column type.  Compatibility: a cache is reused without a refresh when the file exists
  (offline viewing), so a pre-contract cache can still reach the formatter.  Debug asserts;
  release logs once and takes a cold, safe class-checked fallback only on a violation -- not
  a branch in the healthy hot path.  An optional cache `user_version` stamp can retire the
  fallback later.
- **Work order (correctness before performance):** (0) fix the cache's ORDER BY so text keys
  sort with LSASC and every column uses its own `MADDataType`: pass the cache's columns into
  the enumerator query and switch the five `sortDescriptionForColumnType:` call sites from
  `nativeType` to `column.type` (see the MADSqlite3 entry).  Without this the comparator and
  the row order disagree and case-variant groups split.  (1) write down the canonical
  representation per `MADDataType`; (2) canonicalise in `MADDatabaseDataBinding`, keep the
  binder's defensive check, and move the MySQL first-row type mutation into
  `dataColumnForFieldName:`; (3) give the group level a comparator resolved from the cache
  column type (schema fallback) once per format, use it in both walks, and delete the generic
  `id` path; (4) tests: multi-level groups, string (LSASC case-insensitive), number, date,
  blob, NULL, a malformed cache value reported rather than crashing the formatter, and the
  legacy-cache tolerance.  Then, and only then, performance: the per-level function-pointer
  table, one changed/unchanged result per level per row shared by both walks, and, if still
  needed, boundary flags from the enumerator/SQL.
- **Deferred or rejected:** class-checked typed dispatch at the formatter (the previous
  revision's recommendation) is the release-time fallback for a legacy cache that violates
  the contract, not the target -- it leaves checks in the render loop and fixes only one
  consumer.  Making `MADResult` a real type would ripple through every datasource, dictionary
  and aggregate path.  A new sqlite API returning `(value, type)` duplicates the class.  A
  per-value tag in the cache or key array adds an allocation per row, and the key array's
  values are also fed to the aggregate WHERE clause, so they must stay raw.  Testing equality
  with `-isEqual:` was measured slower than `compare:` (32 ns vs 23 ns for an `NSNumber`).
  Boundary detection in SQLite (LAG or a second pass) is fastest in theory but couples the
  formatter to the cache and changes the datasource contract.
- **Resolved by the second opinion (2026-10-18):** the insert path is the enforcement point
  (with `MADDatabaseDataBinding` doing the canonicalisation); the cache column's type is the
  source of truth; Date/Decimal are `NSNumber` epoch/double; pre-contract caches are tolerated
  with a cold logged fallback; and the cache's ORDER BY is a live, separate defect (see the
  MADSqlite3 entry below).
- **Now:** the canonical table is one class per declared
  type, decided in `MADDatabaseDataBinding -initWithDataType:fieldIndex:value:`
  (`MADCanonicalValueForType`): Bit/Integer/Short/Long/LongLong/Int24/Enum -> `NSNumber`
  (`longLongValue`; a numeric `NSString` is parsed with a one-time log), Float/Double/
  Number/Decimal -> `NSNumber` (`doubleValue`; `NSDecimalNumber` is an `NSNumber`, so the
  precision loss is documented, not silent), String/VarChar/Set/Year/Geometry -> `NSString`
  (an `NSNumber` stores its text with a one-time log), Date/DateTime/TimeStamp/Time -> the
  `NSNumber` epoch (stored REAL, the class the display path reads; `NSDate`,
  `NSDateComponents` and an epoch string all convert), Blob/Image -> `NSData` (an
  `NSString` stores its UTF-8 bytes with a one-time log), Unknown -> stringified (as
  before), Null -> `NSNull`.  A value the type cannot represent stores NULL with a one-time
  log -- never silently another class, and the old binder crashes (data/date into numeric
  columns) are gone.  `-[MADDatabaseSqlite3 bindStatement:withBindings:]` now sees its own
  class per case and keeps a defensive one-time log + NULL for a hand-built binding outside
  the contract (debug asserts).  `MADReportFormatter +compareValue:withValue:forDataType:`
  replaced `-compareValue:withValue:usingSelector:` (the strict-selector-match warning is
  gone): NULL is first-class, the typed classes compare the way the cache's ORDER BY orders
  them, and each group level resolves its type once per format from the row cache's column
  (`-groupDataTypes`, schema field as fallback only when the cache holds no such column --
  a present column keeps its own type, Unknown included).  A violation among the reader's
  four classes -- what a pre-contract cache can hold -- logs once and compares by a safe
  class-checked fallback: same-class pairs compare by value, mixed pairs order by class
  (never Same, so homogeneous runs in a heterogeneous legacy column still group), and an
  offline open still formats; a class the reader can never produce asserts.  MySQL's
  first-row `column.type` correction is gone: TEXT vs BLOB is
  decided once in `+[MADMySQLFetch dataColumnForFieldName:mySqlField:]` from the column's
  charset (binary 63 is a BLOB), and the fetch respects the column's declared type.  Enum
  columns still store parsed numbers (pre-existing; "red" becomes 0) -- left as a follow-up,
  not silently changed here.  The optional cache `user_version` stamp remains a follow-up.
- **Test:** `MADSqlite3Tests/MADDatabaseSqlite3BindingTests.m` (the bind matrix),
  `MADAPITests/MADDatabaseDataBindingTests.m` (the canonical classes), and the group-boundary
  and comparator tranches in `MADTests/MADTestReportFormatter.m`, each mirrored under
  `Linux/Tests/`.  Characterization pins the pairs the contract keeps; the failing pins
  (number-in-string-level raise, date-binds-NULL, LSASC-less ORDER BY) were replaced by the
  contract assertions once green.
- **Documented in the code:** `MADReportFormatter.m`
  (`+compareValue:withValue:forDataType:`, `-groupDataTypes`, `-formatDocumentAddDetail`,
  `-newObjectArrayKeyValuesForResultRow:`, both group walks), `MADDatabaseDataBinding.m`
  (`MADCanonicalValueForType`), and `MADDatabaseSqlite3.m`
  (`+databaseResultValue:columnNumber:`, `-bindStatement:withBindings:`, the LSASC
  collation).

### MADSectionLayout reads CFNumbers at the wrong widths, corrupting adjacent ivars
- **Status:** Fixed 2026-10-17.
- **Where:** `MAD/Source/MADSectionLayout.m:52-67`.
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
- **Evidence:** `xcodebuild analyze`, `osx.coreFoundation.CFNumber`: "a CFNumber object
  that represents a 64-bit integer is used to initialize a 16-bit integer; 48 bits of the
  CFNumber value will overwrite adjacent storage".
- **Now:** `_height` is read with `kCFNumberFloatType` and `_type` with
  `kCFNumberSInt16Type`, matching the ivars.  `_height` now returns the stored declared
  height and the designer sizes section views by it; rendering still uses `displayHeight`,
  which is computed from the elements and is unchanged.  `_groupLevel` no longer holds the
  double's high half.
- **Test:** `MADDocumentTests testSectionLayoutReadsEachNumberAtItsDeclaredWidth`
  (`MAD/MADTests/MADDocumentTests.m`).
- **Commit:** `062eea381`.

### `digit_count_*_int`: `INT_MIN` collapsed onto `INT_MAX`
- **Status:** Fixed 2026-10-17.
- **Where:** `MAD/MADTests/MADCoreLogicTests.m`
- **Behavior:** `INT_MIN` is collapsed onto `INT_MAX` before counting digits.
  Both happen to have 10 digits, so the output is correct, but only by
  coincidence.
- **Why it matters:** Harmless today; note it only because the collapse is not
  mathematically general.
- **Now:** both functions divide before negating for `INT_MIN` and add the digit the
  division dropped, so the count does not depend on `INT_MAX`'s digit count and no
  negation overflows.  The result is identical for every input.
- **Test:** `MADCoreLogicTests testDigitCountRecurIntBounds` and
  `testDigitCountIterativeIntBounds` (iOS), and the same bounds checks in
  `Linux/Tests/MADCoreLogicTests.m`.
- **Commit:** `d2000e960`.

### `MADSectionGroupLayout` segfaults on a group whose field has no query table
- **Status:** Fixed 2026-10-17.
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
- **Correction (2026-10-17):** after the portable-store migration, the nil
  `CFNumberRef` is reached only when `RptqQueryGroup.hasField` itself is nil
  (`MADSectionsLayout.m` then omits both number keys). A field that exists but has
  no `inQueryTable` no longer crashes there: `@(field.inQueryTable.dropIndex)` is
  `@0`, and the layout silently rendered the whole report as one group under a
  `"(null)"` key. Both states are invalid data: the add-group screen keeps Done
  disabled until a field is chosen
  (`MADQueryBuilderAddGroupViewController.m:145-154`), and
  `MADocument -addQueryGroupWithQueryField:` takes a field id, so the UI cannot
  persist either one; a legacy, converted, or hand-edited document can.
- **Now:** a group whose key cannot be derived is refused. The initialiser reads
  each number only when present and records whether the group resolved;
  `MADSectionGroupLayout -sortDescriptor` raises `NSInvalidArgumentException`
  naming the section, and `RptqQuery -sortDescriptorsForDatabase:` raises naming
  the query group before it can build a `"(null)"` key. Both log with
  `os_log_error` first. Construction itself does not raise:
  `MADReportSectionsDataSource.m` builds the same layout for the designer, which
  now labels the broken group `missing grouping field` instead of crashing in
  `-safeSortKey`. The invariant is written up in `MAD_DATA_OBJECT.md` section 3.1.
- **Test:** `testGroupWithoutFieldRaisesWhenFormatted`,
  `testGroupFieldWithoutQueryTableRaisesWhenFormatted`,
  `testDesignerDisplayOfGroupWithoutFieldDoesNotThrow`,
  `testQuerySortDescriptorsRejectGroupWithoutField`,
  `testQuerySortDescriptorsRejectGroupFieldWithoutQueryTable`
  (`MAD/MADTests/MADTestReportFormatter.m`).
- **Commit:** `3fcd388d2`.

### Rendered currency depended on the machine, not on the document
- **Status:** Fixed 2026-10-17.
- **Where:** `MAD/Source/rptq/RptqDocumentElement+Extras.m` (`-formattedString:forValue:`
  and `-awakeFromInsert`), `MAD/Source/MADCurrencyFormatter.h` (the locale and
  decimalCount the model stores), `MAD/Source/rptq/autogen/RptqNumericFormat.h` (the
  store's text column).
- **Behavior:** The currency branch built one `NSNumberFormatter` with
  `NSNumberFormatterCurrencyStyle` and `locale = [NSLocale currentLocale]` -- the
  *process's* locale and the *locale's* fraction digits -- while the element's numeric
  format already stores both the design-time locale (`"en_US"`, as text) and the
  decimal count.  The rendered text therefore depended on the rendering machine.  It
  went unnoticed because only Apple rendered; the render half's move to Linux
  (2026-10-16) measured it: the London fixture's HTML export said `$0.99` on Apple and
  `$ 1` in the image (the image's current locale is `en_US_POSIX`, and GNUstep's
  currency style rendered no fraction digits for any locale).
- **Why it matters:** The same report rendered on two machines, or on two platforms,
  showed different values.  A server rendering reports has no user locale to inherit,
  and a report's text is part of the report.
- **Now:** three things, all in the element's formatter:
  1. The locale comes from the document's numeric format -- a stored identifier when
     there is one, `en_US` when the document does not say.  The fallback is
     deliberately *not* `[NSLocale currentLocale]`: that is what made the two
     platforms disagree, and the London samples were designed in en_US, so the
     reference PDF's bytes do not move (`sha256 3eb2f1c4…`, 43,177 bytes).
  2. The element factory records the design locale when it creates a numeric format
     (`-awakeFromInsert`, as the identifier the store's text column keeps), so new
     documents carry their own locale and a French user's report stays French.
  3. The currency symbol is taken from the locale and written explicitly, with the
     yen sign normalized from GNUstep's fullwidth U+FFE5 to U+00A5.
- **Measured, not assumed:** with an explicit locale and the document's fraction
  digits, the two platforms' currency output is byte-identical across a 60-case
  comparison -- six locales (en_US, fr_FR, de_DE, ja_JP, en_GB, es_ES) times ten values
  including negatives, grouping, rounding at 0.005, and 1e12.  The only difference
  found was the yen-sign codepoint, which point 3 addresses.  The London fixture's
  `html`, `html-flow` and `json-report` exports are now the same sha256 on Apple and
  in the image (`ba12a289…`, `6baa43ed…`, `5ba282fc…`).
- **Test:** `testFormattedStringTakesTheCurrencyLocaleAndPrecisionFromTheDocument`
  (`MAD/MADTests/MADDocumentTests.m`, exact strings) and
  `testMoneyIsFormattedFromTheDocumentNotTheMachine`
  (`Linux/Tests/MADHeadlessDocumentTests.m`, the same facts on GNUstep, plus the
  negative-decimal-count guard).  The Linux exporter suite's three render-side
  checksums are now "the Mac's bytes" like text/csv/json.


### `MADQueryActiveQueryFields`: the SELECT list's order is set order, and set order is not stable
- **Status:** Fixed
- **Where:** `MAD/Source/MADQuerySelectExpressionActiveFields.m` (`MADActiveFieldAlias`
  and `MADActiveFieldsInOrder`), read by
  `MAD/Source/MADQuerySelectExpressionAllFields.m` (`MADAllFieldsInOrder`)
- **Behavior:** The active fields are collected into an `NSMutableSet`, so the SELECT
  list's column order was hash order. `RptqObject -hash` is
  `identifier ^ entity.hash` (`MAD/Source/rptq/store/RptqObject.m:42`), which makes
  the order look deterministic per build -- but it was not: measured 2026-10-16,
  **two documents built by the same fixture in one process enumerate the same two
  fields in different orders**, and Apple and GNUstep disagreed as well (the same
  `.mad` gave a different order under the Linux `mad query` than under the
  simulator's). The *fields* were always the right ones; only the order moved. The
  row cache inherited it: its columns are the field keys in this order.
- **Why it mattered:** Any byte-comparison of `mad query` output, or of a `.maddb`
  cache, across platforms (or across runs) saw a difference that was not in the data --
  exactly the comparison `MAD_LINUX.md` §9 Phase D asks for, and what a JSON or CSV
  export would otherwise have inherited. The refreshed **rows** were always identical
  once columns were matched by field name (verified on the London fixture: 21 columns,
  76 rows, every value equal).
- **Now:** the order is defined as the column alias (`Customer0.City`), compared with
  `-compare:` so Apple and GNUstep agree. `MADQueryActiveQueryFields` still collects
  into an `NSSet` -- a set is the right structure for "which fields are active" -- and
  the two builders that emit SQL sort it: `MADQuerySelectExpressionActiveFields` by
  alias, `MADQuerySelectExpressionAllFields` by field name within each table. The row
  cache inherits the order (its `c<hash-of-fieldName>` column *names* were already
  per-field-name and platform-stable). The change is Apple-visible: the same fields
  appear in a new order in the generated SQL, so a cache refreshed before the change
  and one refreshed after it order their columns differently -- the data is the same,
  the order is not.
- **Test:** `testActiveFieldsSelectListIsOrderedByColumnAlias` and
  `testAllFieldsSelectListIsOrderedByFieldName` in both
  `MAD/MADTests/MADQuerySelectExpressionTests.m` and its Linux port: each builds the
  same fields in both creation orders and asserts one list.
  `testActiveFieldsSelectListContentComesFromTheSet` stays as the content guard, so a
  future *content* change is caught separately from an order change.
- **What was decided:** the user chose the alias order (2026-10-16) over the schema
  snapshot's order, the query-field identifier order, and an export-only order, so
  that the generated SQL, the row cache and every export share one defined order on
  both platforms. Recorded in `MAD_CLI.md` §8 (the JSON export shape).

### The same document does not produce the same `.mad` on Linux and on Apple — and on Linux it cannot be written at all
- **Status:** Fixed (2026-10-16): the Linux writer terminates, a reproducible mode pins
  the archive's inputs, and the two platforms' bytes are equal and pinned by tests.
- **Where:** `MAD/Source/MADArchiveManager.m` (`-write_archive:`, the member walk, and
  `backup_file`), `MAD/Source/madtar.m` (`mad_archive_entry_set_attributes`,
  `mad_archive_write_file`), `MAD/Source/MADHeadlessDocument.m`
  (`-writeToURL:reproducible:error:`), against `MAD_FORMAT.md` §7 (the normative
  format) and §9 (verification).
- **Behavior:** Measured 2026-10-16. On one platform, two saves of a document whose
  members did not change produce **different bytes**: the member contents are identical
  (`store.sqlite` and `meta.plist` compare equal byte for byte) and the archive differs,
  because each tar header carries the member's mtime -- the fixture pair made minutes
  apart differ by one byte in size and by the mtime/checksum fields of every directory
  header.  Cross-platform the inputs that differ are wider: mtime, the filesystem's
  **uid/gid/mode**, the **member order** (the walk is `-enumeratorAtURL:...`, whose order
  is the enumerator's), and anything the SQLite writer decides for itself (the store
  *was* byte-identical across two saves here, so that layer is the least of it).
  **On Linux the writer does not finish at all**: `-write_archive:` walks each
  enumerated URL up to the directory being archived
  (`while (![baseUrl.lastPathComponent isEqualToString:directoryToArchiveFileName])`),
  and GNUstep's `-enumeratorAtURL:...` yields URLs with the containing directory
  stripped (the entry below), so the loop reaches `/`, stays there and allocates an
  `NSURL` a turn.  A 512 MB container killed the process (SIGKILL); a 30 s timeout
  simply elapsed.
- **Why it matters:** The user's requirement, 2026-10-16: *"I'd also, if possible, like
  Linux and iOS to produce the same exact MAD file."*  It is also what makes `.mad` a
  *format* rather than a dump: `MAD_FORMAT.md` §7 defines the container, and
  `MAD_CLI.md` §6.1's first round-trip fixture ("unpack, repack, assert the member list
  and each member's bytes are unchanged") is the test that would hold it -- it does not
  exist yet, which is why this is pinned by characterisation instead.  The `mad export
  --deterministic` flag (`MADCLIPinPDFMetadata`) is the same idea already applied to
  PDFs: pin what the clock and the filesystem stamp in.
- **What the fix took, in the order this entry asked for it:**
  1. **The Linux writer terminates.**  The walk-up loop is gone: the members are read
     with `-subpathsAtPath:` and named by their paths relative to the archived
     directory, so the walk cannot run away on either platform (the same correction the
     CLI's member list carries, `BUGS.md`'s enumerator entry).
  2. **The archive's inputs are pinned, in a mode.**  `MADArchiveManager.reproducible`
     (set before `-archive:`, as `-checkpointed` is) gives every tar member uid/gid 0,
     the fixed time `MADArchiveReproducibleModificationTime` (2001-01-12T00:00:00Z, the
     instant the PDF export pins its dates to) and nanosecond 0, and sorts the member
     walk; no birth time is written.  Ordinary saves are untouched and still record the
     filesystem's metadata.
  3. **The comparison runs, and passes.**  The same document written on the Mac and in
     the Linux image is the same file:
     `mad write CLI/Fixtures/London.portable.mad --out … --reproducible` gives 16,243
     bytes and sha256 `22dd3123ea1efe059f298fe39aa54aa3c7dd89aba33cf15870b55b309f9d1848`
     on both.  What that covers is the container: the members are the same bytes on
     both sides because they are the fixture's.  A future writer that *creates* a store
     rather than re-archiving one extends the same comparison to the store layer; the
     assumption there (SQLite is portable, our writes are identical) is untested today.
- **One defect the fix turned up.**  `backup_file` passes its argument to `dirname(3)`
  and `basename(3)`, which are allowed to modify what they are given -- glibc's do and
  Apple's do not.  On Linux the caller's archive path was left truncated at its last
  slash, so the composed document was written over its own directory ("Open (/tmp/out)
  failed - Is a directory") rather than the file.  Each call now gets its own copy.
  Nothing had noticed because on Linux the writer never got that far, and on Apple the
  buffer survives.
- **Test:** `Linux/Tests/MADArchiveManagerTests.m` (5 tests, 0 needs) is the coverage:
  the round trip (`MAD_CLI.md` §6.1: unpack, repack, unpack, and the member list and
  every member's bytes are unchanged), the ordinary mode's characterisation (an aged
  member changes the bytes), the reproducible mode (two writes are one file, and the
  bytes equal the Mac's -- an FNV-1a checksum of the whole document), and the document
  path (`MADHeadlessDocument -writeToURL:reproducible:error:` writes a copy and leaves
  the source untouched).  On Apple,
  `MADDocumentTests/testArchiveIsNotReproducibleFromUnchangedMembers` keeps pinning
  that the *ordinary* mode is not reproducible -- still true, because the mode is
  opt-in -- and `testArchiveIsReproducibleWithTheModeOn` pins the mode itself.

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
- **Where:** `MAD/Source/model/MADModelTable.m` (`-update`) and
  `MAD/Source/model/MADModelDatabase.m` (`-updateTables`)
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

### MADocument calls writeContents: with nil contents
- **Status:** Fixed — 2026-10-04, in Phase D (`2bf9af919`), before this pass looked at it.
- **What:** `saveToURL:forSaveOperation:completionHandler:` passed `nil` for both the
  contents and the attributes (`:598`, and again at `:624`) to
  `-writeContents:andAttributes:safelyToURL:forSaveOperation:error:`, whose parameters are
  declared non-null.  The override of `contentsForType:error:` returns nil on purpose
  because the portable store writes itself, so the call was consistent with the design --
  but the compiler was right that the API's own contract was being broken.
- **Now:** the save path no longer calls `-writeContents:andAttributes:safelyToURL:…` at
  all: `-saveToURL:forSaveOperation:completionHandler:` and
  `-closeWithCompletionHandler:` call `-writeStoreAndArchiveWithError:` directly.  The
  two `writeContents:` overrides -- which ignore their contents and return that same
  store write -- remain for UIDocument's own machinery, which calls them with the
  file-wrapper contents it built.  The analyzer's two
  `nullability.NullPassedToNonnull` findings at those sites are gone with the calls.
- **Where:** `MAD/Source/MADocument.m:594-630`.
- **Locked down by:** nothing to pin -- the defect was the nil the production path
  passed, and the path no longer exists.  The tests that call `-writeContents:` with nil
  directly (`MADDocumentTests`, `MADOperationDocumentCloseDocumentTests`) exercise the
  override itself, whose `id` parameter has no header annotation of its own.

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
- **Status:** Fixed
- **What:** `[_tables setObject:queryTable forKey:qtidn]` (`:301`) assumes `queryTable` was
  built earlier in the loop (`:289`), but the assignment only happens when
  `resultCounter == 0`, so a path that reaches `:301` with an unset `queryTable` sends nil
  to `setObject:forKey:`, which throws.
- **Where:** `MAD/Source/model/MADModelQuery.m:285-302`.
- **Evidence:** `osx.cocoa.NilArg` from `xcodebuild analyze`.
- **Now:** a table id whose projection filter matches no rows is skipped before anything
  is built, so the registration is never reached with an unset `queryTable` (and no stale
  identifier joins `_queryTableIDs` either).
- **Locked down by:** `xcodebuild analyze` on the MAD scheme, re-run with the edited file:
  zero `osx.cocoa.NilArg` findings in MADModelQuery.m where there was one.  No runtime
  test can reach the path: the ordered set of table ids is derived from the same
  projections the filter walks, so every id it holds matches at least one row today --
  which is also why the analyzer could only warn.

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

### MADDataTableFast returns nil from methods declared non-null
- **Status:** Fixed
- **What:** Five `return nil` / possibly-nil returns sat on paths of methods the
  declarations said always return a value: `:964`, `:973`, `:987`, `:1280`, `:1416`.
  Callers that trust the declaration will not nil-check.
- **Where:** `MADSqlite3/Source/MADDataTableFast.m:964,973,987,1280,1416`.
- **Evidence:** `nullability.NullReturnedFromNonnull` in `xcodebuild analyze`.
- **Now:** the declarations admit what the code does, and no behaviour changed.
  `-dataForRow:column:error:` and `-runSelectQuery:` are nullable in
  `MADDataTableFast.h` -- the first matches the base protocol's nullable
  `-dataForRow:error:`, the second answers nil for a query that yields no row.  The
  `objectEnumerator` finding was the odd one: the Fast table answers nil when it has no
  columns *and* the abstract base answers nil in Release, so the untrue declaration was
  `MADDataTableCursoring`'s `nonnull` -- `MADFoundation/Source/MADDataTable.h` now
  declares it nullable, which is what both implementations have always done.  The
  property `databaseForSelects` is nullable too (a delegate-less table has none).
  MADDataTableFast's own header re-declares `objectEnumerator` nullable so the Fast
  call sites see it.  The sibling `-columnsEnumerator` carries the same untrue `nonnull`
  in the protocol and the same nil-on-the-abstract-path in the base class; it was left
  as it is -- no MADDataTableFast path answers nil for it -- so the next reader knows
  it was seen, not missed.
- **Locked down by:** the analyzer, re-run with its cached results removed: zero
  findings in MADDataTableFast.m where there were five.  A declaration change has no
  runtime failure to pin; the nil each declaration now admits is pinned where it is
  reachable -- `MADDataTableRegressionTests testFastTableDataForRowWithUnknownColumnReturnsError`
  and `MADDataTableFastSelectTests testRunSelectQueryYieldsNilWhenTheQueryHasNoRow`
  (which passes both before and after: it documents the behaviour the header now
  states) -- and `testFastTableObjectEnumeratorIsNilWithoutColumns` keeps pinning the
  enumerator.

### Image elements do not survive a save
- **Status:** Fixed
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
- **Now:** `RptqDocumentElementImage (Extras)` implements `-image` / `-setImage:` at the
  attribute boundary.  The setter writes `UIImagePNGRepresentation` bytes -- the wire
  format the legacy converter already pins (`MADStorePNGData`, and
  `MADStoreConverterTests` checks the bytes) -- and the getter answers
  `[UIImage imageWithData:]` for the bytes the store hands back.  The store's Blob
  binder and reader are unchanged, and a value already in memory as `NSData` reads back
  as a picture either way.  Apple only (`#if __APPLE__`): UIImage is UIKit's, and the
  factory refuses to build an image element off Apple.
- **Locked down by:** `MADDocumentObjectDataReferenceImageTests`:
  `testImageSurvivesSaveAndReopen` (replaces `testImageDoesNotSurviveSaveAndReopen`,
  which pinned the loss), `testTheStoredBlobIsTheImagesPNGData` (the backing attribute
  carries the PNG bytes, not the image or NULL) and `testImageIsTheElementImageWhileInMemory`
  (updated in step: the element hands back the same picture, not the same object).
  `MADPrintPageElementTests testImageElementAdoptsTheDefinitionImage` was updated for
  the same reason -- its identity assertion became a pixel-equality one.  Both new
  tests were confirmed to fail against the old code.  The Linux port pins the
  platform-neutral half: `Linux/Tests/MADDocumentObjectDataReferenceImageTests.m
  testImageDataSurvivesSaveAndReopen` (renamed from `testImageDoesNotSurviveSaveAndReopen`).

### `MADImageThumbnail` draws page 1, so a one-page document's thumbnail is blank
- **Status:** Fixed
- **Where:** `MAD/Source/MADImageThumbnail.m:102`
- **Behavior:** The renderer-based path called
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
- **Now:** the renderer path asks for page index 0 -- the report's first page -- so a
  single-page document's cover is the page itself and a multi-page document's cover is
  its opening page.  The transparent canvas behind it is real now too, see the
  `MADPrintPageRenderer` entry below.
- **Locked down by:** `MADImageThumbnailTests
  testRendererThumbnailIsASquareLetterPageAndDrawsPageOne` (its index assertion moved
  from 1 to 0), `testAOnePageDocumentsThumbnailIsNotBlank` -- a paged test renderer
  that bounds-checks the way the real one does, drawing a valid page and nothing at or
  past the page count; it failed before the fix -- and
  `testAMultiPageDocumentsThumbnailShowsTheFirstPage` for the other direction.

### `MADPrintPageRenderer` ignores `withTransparentBackground:`
- **Status:** Fixed
- **Where:** `MAD/Source/MADPrintPageRenderer.m:289-295`
- **Behavior:** `-drawPageAtIndex:inRect:withTransparentBackground:` never reads the
  flag; it always paints the opaque white canvas and then draws the page.  The header
  documents the parameter as "draws a transparent background instead of white", and
  `MADImageThumbnail` calls it with `YES` expecting transparency.
- **Why it matters:** Any caller asking for a transparent page gets an opaque white
  one; the parameter is a lie.
- **Now:** the flag is read -- the white canvas is drawn only when a transparent
  background was not asked for, so the page's own drawing stands alone over the
  caller's context.
- **Locked down by:** `MADPrintPageRendererTests
  testDrawPageWithATransparentBackgroundDrawsNoCanvas` (failed before the fix: the
  cleared pixel came back opaque white) and `testDrawPageWithAnOpaqueBackgroundDrawsTheWhiteCanvas`,
  which replaces `testDrawPageDrawsTheWhiteCanvasEvenWithTransparentBackground`.

### `MADSectionLayoutAttributes +movePlacedItem:` teleports an isolated item to the origin
- **Status:** Fixed
- **Where:** `MAD/Source/MADSectionLayoutAttributes.m:62-82`
- **Behavior:** The candidate drop point started as `CGPointZero` with its distance
  measured from the item's own origin, so when there is no *other* item to snap
  against, the loop never replaces the candidate and the item's frame is set to
  `(0, 0, w, h)` -- the origin, not a nearby valid point.  An item that was already
  somewhere sensible is yanked to the top-left the first time layout runs while it is
  alone.
- **Now:** the loop records whether there was another item to snap against at all, and
  with none the item keeps the frame it had.  In the with-neighbours case the search
  is unchanged: the origin is still the floor a far corner must beat, which is the
  shape the neighbouring tests pin.
- **Locked down by:** `MADSectionLayoutAttributesTests
  testPlaceItemWithNoOtherItemsStaysWhereItWas` (renamed from
  `testPlaceItemWithNoOtherItemsSnapsToTheOrigin`, which pinned the teleport), both
  halves of it confirmed failing before the fix;
  `testPlaceItemSnapsToTheNearestOtherCorner` and
  `testPlaceItemPrefersTheOriginOverADistantCorner` still pass unchanged.

### MAD's document fixtures shared one store across test runs

- **Status:** Fixed (tests); the underlying name-keying noted below
- **Where:** `MAD/MADTests/MADOperationCreateDocument*Tests.m`,
  `MADOperationDocumentCloseDocumentTests.m`, `MADOperationDeleteFileTests.m`,
  `MADDocumentTests.m` -- fixtures created documents with fixed names
  (`add-connection.mad`, `first-time.mad`, `open.mad`, ...).
- **Behavior:** a document's guts -- and the store inside them -- resolve to
  `<home>/tmp/<name>.mada` (`MADURLFactory
  +newURLDocumentArchiveForFileURL:extension:`), which the device shares and
  keeps between runs; the fixture's unique temp directory never enters the
  path.  So the second run of the suite opened the first run's store and
  `insertObjectForEntity:@"RptqDocument" identifier:1` threw "already in the
  graph".  Measured 2026-10-10: three such failures on the second run of the
  merged suite, a different single failure on the third (after clearing only
  two leftovers), none on the first.
- **Now:** each fixture document's name carries its fixture directory's UUID,
  so every fixture resolves to a fresh store; reopen flows reuse the one URL
  and still find what the first document wrote.
- **Noted (product level, not changed here):** two documents with the same
  file name in different folders resolve to the same guts directory while
  open.  The import path guards against duplicates
  (`MADURLFactory +newURLWithUniqueFilenameForURL:`), which is why this is
  recorded rather than worked around in the product.
- **Locked down by:** two consecutive MAD scheme runs, 547/547 each, with the
  old leftovers still on the simulator.

### The store's colour columns have no reader, and the model's colour properties have no column
- **Status:** Fixed 2026-10-21.
- **Where:** `MAD/Source/rptq/store/MADStoreSchema.m:496-503` (the columns),
  `MAD/Source/rptq/autogen/RptqDocumentElement.h:30-31` (`backgroundColor`,
  `foregroundColor` as `UIColor *`), `MAD/Source/rptq/store/RptqObject.m:63-92`
  (`-valueForUndefinedKey:`: exact name only), `MAD/Source/rptq/RptqDocumentElementBarcode+Extras.m:89-90`
  (the one writer).
- **Behavior:** The portable store gives every element eight colour columns --
  `backgroundColorR/G/B/A` and the same four for `foregroundColor` -- but the model's
  properties are `backgroundColor` / `foregroundColor`, and nothing maps the one to the
  other.  `RptqDocumentElement -backgroundColor` asks for an attribute of that exact
  name, finds none, finds no such relationship, and falls through to
  `NSObject -valueForUndefinedKey:`, which raises `NSUnknownKeyException`.  The one
  caller that writes a colour (`RptqDocumentElementBarcode+Extras.m:89-90`) looks like
  it would raise the same way; it is on the barcode creation path, which is off the
  headless build and untested on Apple.  The converter that writes the four columns
  (`MADDesigner/Source/MADStoreLegacy/MADStoreConverter.m:66-85, 111`) is the only code
  that touches them at all.
- **Why it matters:** A colour set on an element is not readable back, and the same
  document cannot paint it.  The HTML facsimile and the PDF are monochrome for this
  reason (both record it in their headers): the walk has no colour to give them.  The
  banner is only the first casualty -- any element styling that is a colour has the
  same hole.
- **Why it is not fixed here:** the mapping is a store-layer decision, not a format's.
  Reading needs four reals to become a colour -- a `UIColor` on Apple, and something
  portable for Linux, which has no `UIColor` -- and writing needs the reverse.  That is
  the same shape as the `MADCurrencyFormatter` locale question and belongs with the
  store, not with an exporter.
- **Test:** none; there is no reader to characterize.
- **Now:** `RptqObject` maps the two model properties through the four RGBA columns in
  both directions.  The getter assembles a `UIColor` on Apple (an `NSArray` of the four
  component `NSNumber`s off Apple, where there is no `UIColor`), and answers nil when
  all four columns are absent.  The setter decomposes the colour -- converting to sRGB
  when UIKit cannot describe it in RGB, as the converter does -- writes the four
  columns and dirties the row once; nil clears them.  The schema columns are unchanged.
  Pinned by `MADTests/RptqDocumentElementBarcodeTests
  testFactoryWritesAndReadsTheElementColours`, which creates a barcode element through
  `+barcodeWithMtBarcode:...` (the former crash site) and reads both colours back.

## MADFoundation

### `MADURLFactory +newURLForLocalApplicationSupportDirectory` threw `NSInvalidArgumentException` without a bundle identifier, and `+groupRootURLForIdentifier:` targeted `~/Library/Group Containers` on macOS
- **Status:** Fixed 2026-10-29.
- **Where:** `MADFoundation/Source/MADURLFactory.m:190` (`+groupRootURLForIdentifier:`)
  and `:302-310` (`+newURLForLocalApplicationSupportDirectory`).
- **Behavior:** Two related issues surfaced when running `MADFoundationTests` and
  `MADTests` on native macOS:
  1. `+newURLForLocalApplicationSupportDirectory` passed
     `[[NSBundle mainBundle] bundleIdentifier]` directly to
     `[appSupportDirectory URLByAppendingPathComponent:bundleIdentifier]`. In an
     unbundled test host or command-line runner where `bundleIdentifier` is `nil`,
     Apple Foundation threw `NSInvalidArgumentException` (`pathComponent` cannot be nil).
  2. `+groupRootURLForIdentifier:` used `#if __APPLE__` around
     `[[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:]`.
     On macOS 15+, that method returns `~/Library/Group Containers/<groupID>` even for an
     unentitled process, and creating directories inside `~/Library/Group Containers/`
     triggers a blocking macOS TCC modal dialog (`mkdirat` blocks waiting for user
     approval).
- **Now:** `+newURLForLocalApplicationSupportDirectory` falls back to
  `[MADApplication groupIdentifier]` when `bundleIdentifier.length == 0`, and
  `+groupRootURLForIdentifier:` guards the App Group container lookup with
  `#if defined(__APPLE__) && TARGET_OS_IPHONE` so macOS uses the standard per-user
  `~/Library/Application Support`, `~/Documents`, and `~/Library/Caches` directories.
- **Test:** `MADURLFactoryTests testLocalApplicationSupportDirectoryIncludesBundleIdentifier`
  and `testApplicationDirectoryFallsBackToUserDirectoriesWhenGroupContainerIsUnavailable`.

### `MADDataTable -cacheWithUrl:error:` passed `NSDataWritingFileProtectionCompleteUnlessOpen` on macOS, failing unentitled cache writes
- **Status:** Fixed 2026-10-29.
- **Where:** `MADFoundation/Source/MADDataTable.m:218`.
- **Behavior:** `-cacheWithUrl:error:` called
  `[plistData writeToURL:url options:NSDataWritingAtomic | NSDataWritingFileProtectionCompleteUnlessOpen error:&writeError]`.
  On macOS without a Data Protection entitlement, `NSDataWritingFileProtectionCompleteUnlessOpen`
  causes `writeToURL:options:error:` to fail, breaking `MADDataTableVirtual` disk cache
  writes.
- **Now:** `NSDataWritingFileProtectionCompleteUnlessOpen` is guarded with
  `#if defined(__APPLE__) && TARGET_OS_IPHONE`, while `NSDataWritingAtomic` is used on
  macOS and Linux.
- **Test:** `MADDataTableRegressionTests testVirtualTableCacheAndReloadFromDisk`.

### `MADKeyChain` leaks every `CFDataRef` returned by `SecItemCopyMatching` in existence checks and mutating helpers
- **Status:** Fixed 2026-10-29.
- **Where:** `MADFoundation/Source/MADKeyChain.m:155-159` (`+credentialsExist:`),
  `:204-205` (`+saveToken:forKey:withDescription:`), `:221-223` (`+deleteKey:`), and
  `:235-247` (`+deleteSavedPasswordForKey:error:`).
- **Behavior:** All four methods construct a keychain query containing
  `(__bridge id)kSecReturnData : @YES` and pass `(CFTypeRef *)&query...Data` to
  `SecItemCopyMatching`. When an item exists (`errSecSuccess`), Security allocates and
  returns a `+1`-retained `CFDataRef` holding the decrypted secret bytes. None of the
  four methods ever reads that `CFDataRef` or calls `CFRelease` on it.
- **Why it matters:** Every call to `+credentialsExist:`, `+saveToken:forKey:withDescription:`,
  `+deleteKey:`, or `+deleteSavedPasswordForKey:error:` against an existing keychain entry
  leaks a `CFDataRef` containing plaintext credential bytes on the process heap.
- **Now:** `+saveToken:forKey:withDescription:` omits `kSecReturnData` and passes `NULL`
  as the result pointer to `SecItemCopyMatching`, and `+credentialsExist:`, `+deleteKey:`,
  and `+deleteSavedPasswordForKey:error:` release any non-NULL `CFDataRef` returned by
  `SecItemCopyMatching`.
- **Test:** `MADKeyChainTests testSaveCheckAndDeleteCredentialsRoundTrip`.

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

### Framework targets dropped `$(inherited)`, so `DEBUG` never reached framework code

- **Status:** Fixed
- **Where:** the `GCC_PREPROCESSOR_DEFINITIONS` of every target that sets
  `MADLOG_ACCESSOR` -- `MADFoundation`, `MAD`, `MADAPI`, `MADCocoaExtensions`,
  `MADFileManager`, `MADSqlite3`, `MADMySQL`, `MADTds`, `MADExplorer`, and the
  `MAD Designer` app target.
- **Behavior:** each target's list was exactly `MADLOG_ACCESSOR=<accessor>`
  with no `$(inherited)`, so the project-level `DEBUG=1` was overridden away.
  Every `#if DEBUG` in framework code was therefore dead in Debug builds:
  `MADApplication +groupIdentifier` never answered the `.local` group,
  `MADLogDebug` was always the no-op arm (`madlog.h`), and
  `MADMySQL/Source/MADMySQLFetch.m`'s `#ifdef DEBUG` block never compiled.
- **Now:** `"$(inherited)"` added after the accessor in each list (Debug and
  Release, ten projects).  `-showBuildSettings` now resolves to
  `MADLOG_ACCESSOR=... DEBUG=1` for the framework and app targets.
- **Why it matters:** the group identity decides which shared container a
  Debug build uses, and the failure is silent -- a plausible-looking value
  from the wrong branch.
- **Locked down by:** `MADApplicationTests
  testGroupIdentifierMatchesBuildConfiguration` (which caught it, on the
  second run of the merged suite), and the eight framework schemes + the app
  build re-run green afterwards.

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

### `MADDirectoryMonitor`'s cancel handler dereferences a nil owner — SIGSEGV on dealloc
- **Status:** Fixed
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
- **Now:** the cancel handler captures the owner **strongly** and closes the descriptor
  through it; the `directoryMonitorSource = nil` on its last line is what breaks the
  source→block→self→source cycle, on its one and only run, so the monitor is released by
  the handler instead of faulting in it.  The event handler keeps its weak load — a
  strong capture there would hold the monitor for the whole life of the source — and
  nil-checks it, since the same missing guard left it one weak-load away from
  `dispatch_source_get_data(NULL)` (and, off Apple, from the same direct ivar read).
- **Locked down by:** `MADDirectoryMonitorTests
  testReleasingAMonitorWithACancelPendingDoesNotCrash`, on both platforms.  It suspends
  the monitor's queue so the cancel handler cannot have run before the monitor is
  released, releases it, then resumes the queue: the old code faults there (the iOS run
  reports "Restarting after unexpected exit, crash, or test timeout" with zero tests
  executed), and with the fix the test also asserts the monitor really was released, so
  a fix that leaked the owner would fail too.  (The stop-and-drain in the other tests
  is no longer load-bearing; it is left as it was.)

## MADExplorer

### The document-browser thumbnail stayed blank after the viewer rewrote it
- **Status:** Fixed 2026-10-17.
- **Where:** `MADExplorer/MADExplorer/MADExplorer/MADThumbnailView.m`
  (`-setThumbnailPath:`), `MADDesigner/Source/MADReportPageView.m` (the write).
- **Behavior:** The viewer rewrites `Caches/<hash>/Name@2x.png` after every refresh.  The
  thumbnail view reloaded only when the *path* changed, and the path is stable, so a cell
  reconfigured after a refresh kept its old image -- usually the blank placeholder loaded
  before the first write.  The write was also non-atomic, so a reader could decode a
  half-written PNG and fall back to the blank image.
- **Why it matters:** Refreshing a report, or opening and leaving it, made a good
  thumbnail disappear from the document browser even though the PNG on disk was correct.
- **Now:** `-setThumbnailPath:` reloads when the file's modification date changes (the
  path alone is no longer the test), and `MADReportPageView` writes the PNG atomically and
  skips the write when encoding fails.
- **Test:** `MADExplorerTests testSamePathRewriteReloadsTheImage`
  (`MADExplorer/MADExplorerTests/MADExplorerTests.m`).
- **Commit:** `7dff3b42b`.

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

### `MADStandard` hides `+standardStringForDouble:` / `+standardStringForUnsignedLong:`
- **Status:** Fixed
- **Where:** `MADExplorer/MADExplorer/MADStandard.mm` (vs `MADStandard.h`)
- **Behavior:** Both class methods are implemented but not declared in the public
  header; the tests reach them via a test-only category.
- **Why it matters:** Same hidden-API smell as the `MADFileUtilities` helpers.
- **Now:** both are declared in `MADStandard.h`, and
  `MADStandardTests.m`'s test-only category is gone.

### `MADOpenDocumentManager -removeDocumentWithUrl:` removed `self.openUrl` instead of `url`
- **Status:** Fixed 2026-10-28.
- **Where:** `MADExplorer/MADExplorer/MADExplorer/MADOpenDocumentManager.m:58-67`.
- **Behavior:** `-removeDocumentWithUrl:` computed `absoluteString` from `self.openUrl.absoluteURL`
  instead of `url.absoluteURL`, so calling it with a URL other than `self.openUrl` removed the
  active document's entry from `self.openFiles` while leaving `self.openUrl` non-nil and leaving
  `url`'s entry in `self.openFiles`.  In addition, `MADOpenDocumentManager` typed its document
  accessor and storage as `UIManagedDocument *` even though `MADocument` now subclasses
  `UIDocument` directly.
- **Now:** `-removeDocumentWithUrl:` resolves `url.absoluteURL.absoluteString`, and
  `MADOpenDocumentManager` types its document parameter and return value as `__kindof UIDocument *`.
- **Test:** `MADExplorerTests -testRemoveDocumentWithUrlRemovesRequestedURLNotActiveURL`
  (`MADExplorer/MADExplorerTests/MADExplorerTests.m`).

### `MADThumbnailView` loaded thumbnails at `DISPATCH_QUEUE_PRIORITY_BACKGROUND` and blocked on `dispatch_sync(dispatch_get_main_queue(), …)`
- **Status:** Fixed 2026-10-28.
- **Where:** `MADExplorer/MADExplorer/MADExplorer/MADThumbnailView.m:42-92`.
- **Behavior:** `-setThumbnailToDefault` and `-setThumbnailPath:` dispatched image decoding onto
  `dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)` (`QOS_CLASS_BACKGROUND`) and
  then called `dispatch_sync(dispatch_get_main_queue(), …)` to assign `self.image`.  Under Darwin's
  QoS scheduler, `QOS_CLASS_BACKGROUND` is throttled to idle CPU (starving for >2 seconds while the
  main thread pumps `NSRunLoop` in `MADExplorerTests -testSamePathRewriteReloadsTheImage`), and
  synchronously blocking a background worker on the main thread risks priority inversion.
- **Now:** Both methods decode on `QOS_CLASS_USER_INITIATED` and hop back to the main queue with
  `dispatch_async(dispatch_get_main_queue(), …)`.
- **Test:** `MADExplorerTests -testSamePathRewriteReloadsTheImage` (`0.225s`).

## MADSqlite3

### `MADDatabaseSqlite3` called `-endBulkInsert` unconditionally on zero-row `SELECT`s, raising `cannot commit - no transaction is active`
- **Status:** Fixed 2026-10-29.
- **Where:** `MADSqlite3/Source/MADDatabaseSqlite3.m:545-605`
  (`-executeSQL:fieldKeys:onConnection:intoResultTable:transactionSet:returnsResults:binaryBindings:withError:`).
- **Behavior:** Inside the `if (returnsResults && dataTable != nil)` block,
  `[dataTable beginBulkInsert]` is called inside `if (rowCounter == 0)` on the first
  iteration of `while (sqlite3_step(statement) == SQLITE_ROW)` (`:583`), whereas
  `[dataTable endBulkInsert]` was called unconditionally after the `while` loop (`:603`).
  When a `SELECT` query returned 0 rows (`sqlite3_step` returned `SQLITE_DONE` on the
  first step), `rowCounter` stayed 0, `[dataTable beginBulkInsert]` was never called, and
  `[dataTable endBulkInsert]` executed `COMMIT TRANSACTION;` on `_databaseForInserts` when
  no transaction was active, tripping `NSAssert` (`cannot commit - no transaction is active`).
- **Now:** `[dataTable endBulkInsert]` is guarded with `if (rowCounter > 0)` so it is
  only called when `[dataTable beginBulkInsert]` was entered.
- **Test:** `MADDatabaseSqlite3DatabaseTests testDriverZeroRowSelectDoesNotCallUnpairedEndBulkInsert`.

### The cache's ORDER BY ignores column types, so text keys sort binary
- **Status:** Fixed 2026-10-18 (commit `483a77259`).
- **Where:** `MADSqlite3/Source/MADQueryCacheSelectLimitOffset.m`'s ORDER BY block; the
  report enumerators passed `columns:nil` in `MADDataTableFast.m`; the same
  `nativeType`-as-`MADDataType` cast sat at `MADQuery+Sqlite3.m`,
  `MADQueryCacheIndexCreate.m`, and `MAD/Source/MADQueryCacheSelectGroupKeys.m`.
- **Behavior:** `+[MADDatabaseSqlite3 sortDescriptionForColumnType:ascending:]` expects a
  `MADDataType` and returns `COLLATE LSASC` only for text types.  The callers passed
  `MADDataColumn.nativeType`, a driver-native code, and the report enumerators passed no
  columns at all, so `dataColumn` was nil and `nativeType` was 0 (`MADDataTypeBit`): every
  column got plain binary `ASC`.  The report formatter compares the same keys with
  `localizedCaseInsensitiveCompare:`, so equality and adjacency disagreed.  Rows
  `"Apple"`, `"Armadillo"`, `"apple"` arrived in that order and the formatter emitted three
  groups where case-insensitive ordering emits two (`{Apple, apple}`, `{Armadillo}`).
- **Why it matters:** group boundaries are found by comparing adjacent rows, so an ORDER BY
  that disagrees with the comparator splits case-variant groups (user-visible).  The typed
  comparator design depends on the two agreeing, so this was the first correctness step,
  not a performance follow-up.
- **Now:** the sorted enumerators (and the other `MADQueryCacheSelectLimitOffset`
  call sites in `MADDataTableFast.m`) pass the cache's `columns`, and every
  `sortDescriptionForColumnType:` call site passes `column.type`; a query handed no column
  sorts plainly rather than guessing a collation.  Text keys now order under LSASC, which
  is the same comparison the formatter makes, so equality and adjacency agree.  On GNUstep
  `localizedCaseInsensitiveCompare:` is case-sensitive (README.md), so the two sides still
  agree there, just without the case folding -- recorded as a need in the Linux suite.
- **Test:** `MADDataTableFastSelectTests testSelectLimitOffsetWithATextColumnOrdersWithLSASC`,
  `testEnumeratorOrdersTextKeysCaseInsensitively` (both platforms), and
  `testSelectLimitOffsetWithoutColumnsOrdersPlainly` (the no-columns fallback).  iOS and
  `Linux/Tests` mirrors agree.
- **Related:** "MADReportFormatter compares untyped values through id" above -- its
  comparator uses the cache column's type, and this ORDER BY fix was the prerequisite.

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
- **Status:** Fixed
- **Where:** `MADSqlite3/Source/MADDataTableFast.m:1062-1082`
- **Behavior:** `-beginReadTransaction` and `-commitReadTransaction` guard on
  `self.databaseForSelects->_database == NULL`, but a table built without a cache
  directory or cache delegate has `databaseForSelects == nil`: the ivar read through
  the nil object crashes before the handle guard is reached.  Constructing such a table
  and calling the pair took the test process down; the test now pins only the
  precondition (`databaseForSelects` is nil).
- **Why it matters:** The renderer's draw loop calls the pair around every page draw;
  any fast table that reaches a draw without a cache directory takes the app down.
- **Now:** both methods read `self.databaseForSelects` once and return when it -- or its
  handle -- is nil: a table with no selects connection has nothing to begin or commit,
  so the pair is a no-op there.  The property is declared nullable in the header, which
  it always was in fact.
- **Locked down by:** `MADDataTableFastSelectTests
  testReadTransactionsWithoutASelectsDatabaseAreANoOp` (renamed from
  `testReadTransactionsWithoutASelectsDatabaseAreNotSafe`, which could pin only the
  precondition because the call itself was the crash).  Against the old code the call
  still takes the test process down -- the run reports "Restarting after unexpected
  exit, crash, or test timeout" -- and passes against the fix.
- **Noted, not changed:** the sibling select paths (`-selectStatementForColumn:`,
  `-objectsForGroupKeys:`, `-runSelectQuery:`, `:1044`, `:1250`, `:1433`) dereference
  `databaseForSelects->_database` the same way, but each needs a selects connection to
  do anything at all, so none is reached on a table that has none.

### `MADDataTableFast -whereClauseForGroupKeys:` indexes past the sort descriptors
- **Status:** Fixed
- **Where:** `MADSqlite3/Source/MADDataTableFast.m:1167-1182`
- **Behavior:** The loop walks the group keys and reads `self.sortDescriptors[i]` at the
  same index; with fewer sort descriptors than group keys it walks off the end of the
  array and raises `NSRangeException`.  The pairing is also purely positional -- the
  group keys' values are matched to descriptors by index, not by any key lookup.
- **Why it matters:** The call comes from the group-key cache path
  (`-objectsForGroupKeys:`), where the two arrays are built from different sources; a
  mismatch is a crash rather than an empty clause.
- **Now:** the loop is bounded by `MIN(groupKeys.count, self.sortDescriptors.count)`:
  a group key at a position with no descriptor cannot be named -- the descriptor *is*
  the column -- so its pair is left out and the shortfall is logged rather than walked
  off the end.  The pairs that can be built are the same ones the old loop built.
- **Locked down by:** `MADDataTableFastSelectTests
  testFewerSortDescriptorsThanGroupKeysClipsToTheDescriptors` (renamed from
  `testFewerSortDescriptorsThanGroupKeysRaises`; against the old code it fails with the
  `NSRangeException` the entry describes) and
  `testGroupKeysProducePositionalColumnValuePairs`, unchanged.

### `MADArrayCaching` could build a cache URL from an empty identifier
- **Status:** Fixed
- **Where:** `MADSqlite3/Source/MADArrayCaching.h:53-57`,
  `MADSqlite3/Source/MADArrayCaching.m:121`, `:284-290`
- **Behavior:** `-url` appended `"madac"` to `self.identifier` and passed the result
  straight to `URLByAppendingPathComponent:`.  `-stringByAppendingPathExtension:` answers
  nil for an empty identifier, and the URL API raises on nil, so an empty or missing
  identifier surfaced as a deep `NSInvalidArgumentException` while constructing the cache
  URL.  The class also inherited `-init`, which left the identifier nil.
- **Why it matters:** The identifier becomes the on-disk file name; without a designated
  initializer the class advertised a construction path that could never work.
- **Now:** `-initWithIdentifier:cachedDelegate:types:` is marked
  `NS_DESIGNATED_INITIALIZER`, `-init` and `+new` are `NS_UNAVAILABLE`, and an empty
  identifier trips `NSParameterAssert` at initialization.  `-url` still guards the
  nullable file name and answers nil rather than raising when assertion checking is
  disabled.
- **Test:** `MADDatabaseSqlite3DatabaseTests` constructs the class through the designated
  initializer; the full suite passes 89/89 (5 benchmarks skipped).

### `MADDataTableFast` passed possibly-nil values into paths that raise
- **Status:** Fixed
- **Where:** `MADSqlite3/Source/MADDataTableFast.m:447`, `:562`, `:1132`
- **Behavior:** Three nullable values crossed a nonnull boundary and would raise when nil:
  - `url.URLByDeletingLastPathComponent.path` was passed to `-fileExistsAtPath:`;
  - `NSSortDescriptor.key` was passed to `-indexOfObject:`;
  - `self.lastDataForCacheId.object` was passed to `-initWithDictionary:`.
  The analyzer reported all three as `-Wnullable-to-nonnull-conversion`.
- **Why it matters:** A stored cache URL with no directory, a descriptor with no key, or
  a last-row cache holding nil each took the process down instead of producing a defined
  answer.
- **Now:**
  - the directory path is stored in a local and checked; an unresolvable stored URL falls
    through to recomputing the cache URL (and the log names the stored value, not nil);
  - a nil sort key raises `NSInvalidArgumentException` with a message naming the cause --
    the same exception `-indexOfObject:nil` raised, but with a usable diagnosis;
  - a nil last-row cached object falls through to the SQLite query that rebuilds the row;
    the invariant violation is logged once per process through `dispatch_once`, off the
    successful-read path.
- **Test:** `MADSqlite3Tests` 89/89 (5 benchmarks skipped), including
  `MADDataTableFastSelectTests` and the database suite.

### `MADQueryCacheAddRow` built its placeholder list with `strcat`
- **Status:** Fixed
- **Where:** `MADSqlite3/Source/MADQueryCacheAddRow.m:100-112`
- **Behavior:** The `?` list for the bulk insert was built with `strcat(buf, ", ?")`
  into a fixed-size stack buffer, while the write position was tracked separately in
  `buf_ptr`.  The analyzer reported `security.insecureAPI.strcpy` (CWE-119).
- **Why it matters:** The buffer is sized exactly for `n` placeholders, so the existing
  arithmetic cannot overflow, but the append itself was unbounded and its length was
  assumed rather than returned.
- **Now:** `buf_ptr = (int)strlcat(buf, ", ?", sizeof(buf));` bounds the append and takes
  the new length from the call.  The output is byte-identical under the existing sizing;
  the Linux image's glibc 2.39 provides `strlcat`.
- **Test:** the cache write paths in `MADDatabaseSqlite3DatabaseTests`; the Linux build is
  the cross-platform gate for the libc call.

## MADBarcodes

### `MADBarcode -drawInRect:` doubles `rect.origin` when `self.center` is `YES`
- **Status:** Fixed 2026-10-29.
- **Where:** `MADBarcodes/MADBarcodes/MADBarcodes/MADBarcode.m:566-571`
- **Behavior:** `-drawInRect:` initializes `CGFloat x = rect.origin.x;` and
  `CGFloat y = rect.origin.y;`, and then inside `if (self.center)` executes:
  ```objc
  x += CGRectGetMidX(rect) - (bitmapWidth * skewValue) / 2.0000f;
  y += CGRectGetMidY(rect) - (bitmapHeight * skewValue) / 2.0000f;
  ```
  Because `CGRectGetMidX(rect)` is `rect.origin.x + rect.size.width / 2.0`, using `+=`
  instead of `=` adds `rect.origin.x` and `rect.origin.y` a second time.
- **Why it matters:** Whenever `self.center` is `YES` and `rect.origin` is non-zero (for
  example, drawing a centered barcode directly into a page context at an element's frame
  rather than into a zero-origin bounds rect), the barcode is shifted right by an extra
  `rect.origin.x` and down by an extra `rect.origin.y`, drawing outside `rect`.
- **Now:** the centered branch assigns `x = CGRectGetMidX(rect) - ...` and
  `y = CGRectGetMidY(rect) - ...` directly.
- **Test:** `MADBarcodeTests testCenteredDrawWithNonZeroOriginPaintsInsideTargetRect`.

### MADBarcode's type-name dictionary has a duplicate key
- **Status:** Fixed 2026-10-20.
- **What:** The dictionary literal built in `MADBarcode.m` uses both
  `@(MADBarcodeTypeEan14)` (`:693`) and `@BARCODE_EAN14` (`:719`); the enum aliases the zint
  macro, so both box the value 72 and the second entry silently replaces the first --
  "Code 128 (EAN-14)" can never be returned.
- **Where:** `MADBarcodes/MADBarcodes/MADBarcodes/MADBarcode.m:693,719`.
- **Evidence:** `-Wobjc-dictionary-duplicate-keys`.
- **Now:** the redundant `@(MADBarcodeTypeEan14)` entry is deleted, so the surviving
  `@BARCODE_EAN14` entry supplies the type's single name, "EAN-14".
- **Test:** `MADBarcodeTests testDictionaryNamesAreWellFormed`.

### Two symbology classes initialize with another class's type
- **Status:** Fixed 2026-10-20.
- **Where:** `MADBarcodes/MADBarcodes/MADBarcodes/MADBarcodeQrCodeIso18004.m` (init and
  `+type` both return `MADBarcodeTypeOneCode`) and
  `MADBarcodes/MADBarcodes/MADBarcodes/MADBarcodeCode128Iso15417.m:145-161`
  (`MADBarcodeCode128Ean128`'s init assigns `[MADBarcodeCode128Hibc type]` -- HIBC Code
  128 -- while its `+type` says `MADBarcodeTypeEAN128`)
- **Behavior:** `+[MADBarcode newBarcodeWithType:MADBarcodeTypeQrcode]` builds an
  `MADBarcodeQrCodeIso18004` whose `barcodeType` is `MADBarcodeTypeOneCode`; the factory's
  `MADBarcodeTypeEAN128` case builds an `MADBarcodeCode128Ean128` whose `barcodeType` is
  `MADBarcodeTypeHibc128`.  `-drawInRect:` passes the instance's type straight to
  `barcode->symbology`, so each object draws a symbol other than the one it is named
  for -- QR code → USPS Intelligent Mail, GS1-128 → HIBC Code 128.
- **Why it matters:** Any feature that asks for a QR code or a GS1-128 barcode gets the
  wrong symbology and the wrong payload validation.  The exhaustive factory matrix found
  the second one; the other 63 mapped types round-trip correctly.
- **Test:** `MADBarcodeSymbologyTests testQrCodeClassClaimsTheOneCodeType` and
  `testEan128ClassClaimsTheHibcType`, with
  `testEveryMappedTypeRoundTripsExceptTheTwoKnownMismatches` covering the rest.
- **Now:** `MADBarcodeQrCodeIso18004 +type` returns `MADBarcodeTypeQrcode`, and
  `MADBarcodeCode128Ean128 -init` assigns `[MADBarcodeCode128Ean128 type]`.  `+type` is
  also declared on `MADBarcode` (the base answers 0), so a picker can ask a class for its
  type without a private-selector warning.  The two pinning tests became
  `testQrCodeClassClaimsTheQrType` and `testEan128ClassClaimsTheEan128Type`;
  `testEveryMappedTypeRoundTripsExceptTheTwoKnownMismatches` dropped its skip and became
  `testEveryMappedTypeRoundTrips`, which now covers all 65 mapped types.

### `MADBarcodeInternationalStandardBookNumberIsbn +type` calls itself
- **Status:** Fixed 2026-10-20.
- **Where:** `MADBarcodes/MADBarcodes/MADBarcodes/MADBarcodeInternationalStandardBookNumberIsbn.m`
- **Behavior:** The class method's body is
  `return [MADBarcodeInternationalStandardBookNumberIsbn type];` -- itself, so any call
  recurses until the stack is exhausted.  The initializer is fine (it assigns
  `MADBarcodeTypeIsbnX` directly), so the factory path works; only the class-method
  accessor is a trap.
- **Why it matters:** A generic caller enumerating symbology classes for their `+type`
  (the obvious way to build a picker) takes the process down on the ISBN entry.
- **Test:** `MADBarcodeSymbologyTests testIsbnClassInitializesToItsOwnType` exercises the
  factory path only; `+type` is deliberately not called.
- **Now:** `+type` returns `MADBarcodeTypeIsbnX`.  The factory-path test is unchanged, and
  the new `MADBarcodeSymbologyTests testIsbnClassTypeReturnsItsOwnType` calls `+type`
  directly.

### `MADBarcode`'s NSCoding round trip loses everything
- **Status:** Fixed 2026-10-20.
- **Where:** `MADBarcodes/MADBarcodes/MADBarcodes/MADBarcode.m:376-408`
- **Behavior:** `-encodeWithCoder:` writes every property under the same empty key
  (`@""`), so only the last value survives in the archive; `-initWithCoder:` ignores the
  decoder entirely and just calls `[super init]`.  A decoded barcode is therefore a
  default instance of the right class -- not even the subclass's `-init` defaults apply,
  because `[super init]` skips them.  The class conforms to `NSCoding`, not
  `NSSecureCoding`, so secure archiving rejects it outright.
- **Why it matters:** Nothing archives a barcode today, so this is latent; it would bite
  the first time one is persisted.
- **Test:** `MADBarcodeTests testNSCodingRoundTripLosesTheState`.
- **Now:** every `MADBarcodeProtocol` property, the two inputs (`input`, `primaryData`),
  and the subclass state (`name`, `detailsSegueIdentifer`, `has2dComponent`,
  `hasOptionalInput`, `center`, `width`, `has2dComponentType`, `rotate`) are encoded
  under their own string keys and decoded back; `-initWithCoder:` dispatches through
  `[self init]` so the subclass's own initializer runs before the archived values are
  applied.  The class declares
  `NSSecureCoding` and decodes strings with `-decodeObjectOfClass:forKey:`.  A workspace
  grep found no archiver use with a barcode object, so the old format needs no
  compatibility path.  The pinning test became
  `testNSCodingRoundTripPreservesTheState`.

### `MADBarcode -drawInRect:` copies user input into `primary[128]` unchecked
- **Status:** Fixed 2026-10-20.
- **Where:** `MADBarcodes/MADBarcodes/MADBarcodes/MADBarcode.m:492`
  (`strcpy(barcode->primary, primaryData)`), against
  `Compressor/library/zint/include/zint.h:121` (`char primary[128]`)
- **Behavior:** When `has2dComponentEnabled` is on, the user's second input is copied
  with `strcpy` into zint's fixed 128-byte `primary` buffer -- no length check ahead of
  it, unlike the main payload which goes through `ZBarcode_Encode_and_Buffer`'s
  length-taking API.
- **Why it matters:** A primary-data string of 128 bytes or more overruns the struct.
  Not exercised in tests: the failure mode is memory corruption, not an assertion.
- **Test:** none, deliberately.
- **Now:** the UTF-8 length is compared with `sizeof(barcode->primary)` before the copy;
  an overlong value is logged, skips `ZBarcode_Encode_and_Buffer`, and takes the
  ordinary error path -- the error text is drawn when `showErrorMessage` is on and no
  symbol is drawn either way.  `MADBarcodeTests testOverlongPrimaryDataIsRefused` covers
  both settings with a 200-byte input.

## MADMySQL

### The fetch corrected a column's type from its first row
- **Status:** Fixed 2026-10-18 (commit `483a77259`).
- **Where:** was `MADMySQL/Source/MADMySQLFetch+DataTable.m`, the `MYSQL_TYPE_*_BLOB` fetch
  branch: on the first row it decoded the bytes, and when they read as UTF-8 it mutated the
  cache column's `type` to String (a dead NSNumber branch mutated it to Integer).
- **Behavior:** a column's type depended on the content of its first row, and the cache
  table had already been created under the original affinity when the type changed.  Under
  the group-key contract (one canonical class per declared type, enforced at the bind) a
  type decided per row cannot stand.
- **Now:** TEXT and BLOB share the blob-ish protocol types; the column's charset is
  what tells them apart -- binary (63) is a BLOB, anything else is TEXT.  The decision now
  happens once in `+[MADMySQLFetch dataColumnForFieldName:mySqlField:]`, before the table is
  created, and the fetch branch stores bytes for a BLOB column and decodes UTF-8 for a TEXT
  column (empty text stores NULL, as before -- an empty NSData has no bytes).  A binary
  BLOB whose bytes happen to decode as UTF-8 is now data rather than text -- the correct
  reading, and a user-visible change for such columns.
- **Test:** the live suite (`MADMySQLLiveTests`) exercises the fetch; no content-based
  fixture exists for a binary blob that decodes, so the charset decision is pinned by the
  bind-path contract tests in `MADSqlite3Tests/MADDatabaseSqlite3BindingTests.m` instead.

### `MADMySQLFetch+DataTable`: no non-SELECT statement could ever execute
- **Status:** Fixed
- **Where:** `MADMySQL/Source/MADMySQLFetch+DataTable.m`
- **Behavior:** `mysql_stmt_bind_result` was called unconditionally. For any
  statement with `field_count == 0` — every `INSERT`, `UPDATE`, `DELETE`,
  `CREATE`, `DROP` — it fails client-side with code 3534, which aborted the call
  before `mysql_stmt_execute` was reached. All DDL and DML through `MADMySQLFetch`
  silently did nothing.
- **Why it matters:** `MADDatabaseMySQL -executeSQL:...` and the
  `MADMySQLInsert`/`MADMySQLUpdate`/`MADMySQLDelete`/`MADMySQLTruncate` builders all route
  through this path, so the whole write side of the MySQL driver was dead.

### `MADMySQLFetch+DataTable`: row loop spun forever on a fetch error
- **Status:** Fixed
- **Where:** `MADMySQL/Source/MADMySQLFetch+DataTable.m`
- **Behavior:** The row loop terminated only on `MYSQL_NO_DATA`. `mysql_stmt_fetch`
  returns `1` (`stmt_read_row_no_result_set` → `set_stmt_error`) rather than
  `MYSQL_NO_DATA` for a statement with no result set, so the loop never exited.
  Found by stack-sampling a test run pinned at 98% CPU.
- **Why it matters:** One bad statement hung the app thread with no error and no
  way out. The loop now ends on any result that is neither a row nor a truncation.

### `MADMySQLFetch+DataTable`: `MYSQL_TYPE_INT24` (MEDIUMINT) read 4 bytes as 8
- **Status:** Fixed
- **Where:** `MADMySQL/Source/MADMySQLFetch+DataTable.m`, `-fetchResultsFromConnection:`
- **Behavior:** The `MYSQL_TYPE_INT24` case had no `break` and fell through into
  the `MYSQL_TYPE_DECIMAL`/`MYSQL_TYPE_DOUBLE` case, which re-read the 4-byte
  `int` buffer as an 8-byte `double`. That is a heap over-read, and it overwrote
  the correct value with a garbage one.
- **Why it matters:** MEDIUMINT columns returned nonsense. Now covered live by a
  round-trip through a probe table.

### `MADMySQLFetch+DataTable`: bind and execute failures were never reported
- **Status:** Fixed
- **Where:** `MADMySQL/Source/MADMySQLFetch+DataTable.m`, `-fetchWithCommand:...`
- **Behavior:** Both failure branches built an `NSError` but never assigned it to
  the caller's `*error` out-parameter, so a failed bind or execute was
  indistinguishable from success. The nil-connection branch had the same problem.
- **Why it matters:** This is what made the DDL bug above invisible for so long:
  the statement did not run, and nothing said so.

### `MADMySQLFetch+DataTable`: `MYSQL_TYPE_NULL` left its out-parameters uninitialized
- **Status:** Fixed
- **Where:** `MADMySQL/Source/MADMySQLFetch+DataTable.m`, `-bindDataForStatement:andField:`
- **Behavior:** The `MYSQL_TYPE_NULL` case set only `buffer_type` and `buffer`,
  then fell through into `default:` and fired `NSAssert(NO, ...)`. The `length`,
  `error` and `is_null` pointers were left as uninitialized stack garbage, and the
  row loop dereferences `*bindings[x].is_null`.
- **Why it matters:** `SELECT NULL` — a literal `NULL` in any ad hoc query —
  asserted in debug builds and dereferenced a wild pointer in release.

### `MADMySQLFetch+DataTable`: bindings and statement leaked on the error paths
- **Status:** Fixed
- **Where:** `MADMySQL/Source/MADMySQLFetch+DataTable.m`, `-fetchWithCommand:...`
- **Behavior:** The `free()` calls and `mysql_stmt_close` sat inside the
  success-only branch, so a failed bind or execute leaked the `calloc`'d binding
  buffers and the `MYSQL_STMT` on every call.
- **Why it matters:** Leaks per failed statement. Became reachable once failing
  DML was able to run at all.

### `MADMySQLFetch`: `mySQLTypeForType` returned wrong names for three types
- **Status:** Fixed
- **Where:** `MADMySQL/Source/MADMySQLFetch.m`
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
    `fieldType` from it) and wrong in a way that showed: `MADMySQLFetch+DataTable.m:431`
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

### `MADMySQLFetch+DataTable` comment claims SMALLINT/MEDIUMINT/BIT are unsupported
- **Status:** Fixed
- **Where:** `MADMySQL/Source/MADMySQLFetch+DataTable.m:139`
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
  `MADMySQLConnection -dealloc`: `mysql_init` is handed memory this side `calloc`'d, so the
  client's `free_me` is false and `mysql_close` does not free it.
- **Test:** `MADMySQLLiveTests testNewSafeLiteralEscapesABackslashThroughTheLiveSession`
  and `testNewSafeLiteralEscapesAnApostropheThroughTheLiveSession`. Each connects the way
  a query does, asks the driver for the literal and then has the server read it back —
  `SELECT <literal> AS v` — because only the server's reading proves the escape. Both were
  confirmed to fail against the old behaviour, printing the tab. The offline
  `MADMySQLTests testNewSafeLiteralWithoutASessionFallsBackToAnsiQuoting` pins the
  no-session path, backslash and all, so the limitation is stated rather than implied.

### `MADMySQLUpdate -execute` raises an out-of-bounds string exception instead of its own error
- **Status:** Fixed
- **Where:** `MADMySQL/Source/MADMySQLUpdate.m:56-62` (the three guards in `-execute`)
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
- **Now:** `-execute` guards both before either buffer is built: no row data and no
  qualifier each raise the class's own `MADMySQLException` -- *row data must be specified
  to perform an update* and *a qualifier must be specified to perform an update* -- in
  the same nil-connection form as the table guard beside them.  The 2026-10-25
  connector rewrite rebuilt the statement without the leading-separator trims, so the
  buffers the old code trimmed no longer exist; the guards, their strings and the
  tests stand unchanged, and the "forgot the WHERE clause" update is refused with a
  diagnostic instead of an `__NSCFString` range exception.
- **Locked down by:** `MADMySQLUpdateTests testExecuteWithoutRowDataRaisesTheUpdatesOwnError`
  (renamed from `testExecuteWithoutRowDataRaisesAnInvalidArgumentException`) and
  `testExecuteWithAnEmptyRowDataDictionaryRaisesTheSameWay`, both confirmed failing
  against the old code, plus the new
  `testExecuteWithoutAQualifierRaisesTheUpdatesOwnError`, whose uncaught
  `NSInvalidArgumentException` also fails the old code.  The live
  `MADMySQLLiveTests testUpdateWithoutAQualifierRaisesTheUpdatesOwnError`
  (renamed) runs the same guard against a real server -- it now raises before the
  session call the old crash needed, but it keeps the live connection in the loop.
  Both Linux ports carry the same tests.

### `MADMySQLConnection +connectToServer:error:` wrote through a NULL error pointer
- **Status:** Fixed
- **Where:** `MADMySQL/Source/MADMySQLConnection.m:56-64` (`+connectToServer:error:`)
- **Behavior:** After `internal_connectToServer:outError:` returned a non-nil
  `connectionError`, the method did `*error = [connectionError copy]` without checking
  `error`.  `internal_connectToServer:outError:` and the neighbouring `:157` both treat
  the pointer as optional, so `+connectToServer:error:NULL` against an unreachable server
  dereferenced NULL and took the process down.  The analyzer reported it as
  `osx.cocoa.NSError`.
- **Why it matters:** A caller that only wanted the connection result had no safe way to
  opt out of the error object.
- **Now:** the write is guarded by `if (error != NULL)`.  Every caller that passes
  an error pointer behaves exactly as before; a NULL pointer asks for no error at all.
- **Test:** `MADMySQLTests testConnectToServerWithNoListenerAndANULLErrorPointerDoesNotCrash`
  (new; the old code crashes on it) and `testConnectToServerWithNoListenerFailsCleanly`
  for the non-NULL path.

### `MADMySQLConnection`'s transaction toggles crashed on a connection with no handle
- **Status:** Fixed by the first-party connector rewrite (2026-10-25, `c46201465`)
- **Where:** `MADMySQL/Source/MADMySQLConnection.m:157-186` (`enableTransactions`,
  `disableTransactions`, and the commit/rollback pair beside them)
- **Behavior:** The old class left its handle NULL after `-init`, and the toggles called
  `mysql_autocommit` / `mysql_commit` / `mysql_rollback` without checking it.
  `mysql_autocommit` dereferences the handle, so `[[MADMySQLConnection alloc] init]`
  followed by `-enableTransactions` crashed the process (verified: the test process died
  at that call, with no exception to catch).
- **Why it matters:** Only latent.  Every production path got its connection from
  `+connectToServer:…`, which answers `nil` rather than a handle-less object, and no
  in-tree caller invoked the transaction methods — they are API for the query cache and
  the portable store.  The trap was that the class is `init`-able and looked usable;
  note that the neighbouring accessors (`-errorNumber`, `-errorText`) were already
  NULL-safe, which is what made the omission look inconsistent rather than deliberate.
- **Now:** the rewrite's `-init` allocates the handle up front (`calloc` + `mysql_init`,
  freed by `-dealloc`), so every mutating session command has a handle to fail against
  and the toggles raise `MADMySQLException` (the commit/rollback pair their own
  subclasses) instead of dereferencing NULL.  A server-less connection now raises a
  catchable exception where it used to take the process down.
- **Test:** `MADMySQLTests testErrorAccessorsOnAConnectionWithoutAServer` and
  `testTransactionsFlagStartsOff` still pin the safe half.  The old crash could not be
  asserted — it terminated the test process, so there is nothing to catch.

### `MADMySQLFetch+DataTable` read an uninitialised `MYSQL_BIND` in its default case
- **Status:** Fixed
- **Where:** `MADMySQL/Source/MADMySQLFetch+DataTable.m:499`, `:668`
  (`+bindDataForStatement:andField:`)
- **Behavior:** `MYSQL_BIND binding;` was uninitialised, and the `default:` case evaluated
  `mySQLTypeForType(binding.buffer_type)` inside `NSAssert` before assigning anything.
  The analyzer reported `core.CallAndMessage`.  The default case also returned a struct
  whose `length`, `error` and `is_null` fields were uninitialised.
- **Why it matters:** Reaching the default case (an unsupported column type) read
  indeterminate memory; in Debug the assertion itself did.
- **Now:** `MYSQL_BIND binding = {0};` zero-initialises the struct, so every field the
  switch does not assign is zero on every path.  The `MYSQL_TYPE_NULL` case still fills
  the three out-parameter buffers.  The only observable difference is the Debug assertion
  text on the unsupported-type path (it now names DECIMAL, enum 0, instead of garbage).
- **Test:** the live suite's SELECT NULL and type-conversion cases; the default path is
  unreachable with the SQL types the driver supports.

## MADTdsClient

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

### dbdatecrack is called with the sybase DBDATETIME under a microsoft DBDATEREC name
- **Status:** Fixed -- the type-name mismatch is real, but the vendor guarantees the layouts match.
- **What:** `MADTdsClient/Source/MADDatabaseSQLServer.m` copies each `SYBDATETIME` /
  `SYBDATETIMN` value into a malloc'd buffer and passes it to `dbdatecrack`
  (`:1327`, `:1355`).  FreeTDS types the buffer as `struct tds_sybase_dbdaterec *`
  while the call's third parameter is `DBDATEREC *`, which this build aliases to
  `struct tds_microsoft_dbdaterec *`; the compiler reports the mismatch on both
  calls.  The surrounding local (`dateinfo`, `:1323`) is declared with the sybase
  struct as well.
- **Why it was not changed in the first pass:** the FreeTDS sybase/microsoft struct
  duality decides the layout of the data `dbdatecrack` reads, so the correct form
  depends on which compatibility mode the vendored FreeTDS was built with -- a
  driver-correctness question, not a cast to add mechanically.  The code carries
  `// CORRECTED:` notes from an earlier pass, so the area is already sensitive.
- **Where:** `MADTdsClient/Source/MADDatabaseSQLServer.m:1320-1360`.
- **Evidence:** `xcodebuild analyze` reports `-Wincompatible-pointer-types` on both
  `dbdatecrack` calls; the two are the only remaining instances of that diagnostic in
  the workspace.
- **Now:** FreeTDS's own header states that the sybase and microsoft date records are
  physically identical in memory, and `dbdatecrack()` casts one to the other itself.
  Both calls now carry an explicit `(DBDATEREC *)` cast, and a file-scope
  `_Static_assert(sizeof(struct tds_sybase_dbdaterec) == sizeof(DBDATEREC), ...)`
  keeps that vendor guarantee honest across a FreeTDS bump.  No layout or runtime
  behaviour changed; both analyzer warnings are gone.
- **Test:** the live suite's DATETIME/SMALLDATETIME cases, including
  `testSelectClassicDateTimeKeepsItsMonth` and `testSelectModernDateTimeTypes`.

### `-runSQL:...`, `-runQuery:...` and `-executeSQL:...withError:` dropped their SQL errors
- **Status:** Fixed
- **Where:** `MADTdsClient/Source/MADDatabaseSQLServer.m` (`-runSQL:onDataTable:fieldKeys:process:`,
  `-runQuery:onProcess:withDataTable:withError:`, `-executeSQL:fieldKeys:onConnection:intoResultTable:withError:`)
- **Behavior:** `-runSQL:` built three `NSError` objects in a local named `localError`
  and returned `NO` without exposing any of them; the method had no error out-parameter.
  `-runQuery:withError:` discarded the error from `-getSql:` and never wrote through its
  own `error` parameter, and `-executeSQL:...withError:` ignored its `error` entirely.
  A caller of `-executeQuery:withDataTable:andError:` saw `NO` with a nil error.  The
  analyzer reported the three `localError` stores as `deadcode.DeadStores` because
  nothing read them.
- **Why it matters:** the error surfaces promised by `-executeQuery:withDataTable:andError:`
  and `-executeSQL:...withError:` could not explain a failed query; the user-visible
  failure was a silent `NO`.
- **Now:** `-runSQL:` takes `NSError * __autoreleasing *`, clears it on entry, logs a
  failure to `GetTdsLog()` (the error object only, not SQL or row data), and hands the
  error back before returning `NO`.  `-runQuery:` propagates a `-getSql:` error and
  forwards the caller's error to `-runSQL:`; `-executeSQL:` forwards its own.
  `-executeQuery:withDataTable:andError:` already forwards to `-runQuery:`, so it now
  receives post-connection SQL failures as well.  The `-runSQL:` body and its
  load-bearing `dbclose` are untouched.
- **Test:** `MADTdsClientLiveTests -testFailingStatementReturnsNo` now asserts both the
  `NO` and the propagated error domain; the full suite is 76 tests with the live server.

## MAD Designer (app)

### The compiled model cannot be migrated by Core Data's inference (clashing renaming identifiers)
- **Status:** Fixed 2026-10-22 — merged as `c48a39fb7`; the fix is on the portable
  store side entirely.
- **What:** `MAD 3.xcdatamodel`'s `RptqDocumentElementBarcode` declares
  `barcodeBorderType` with `elementID="type"` while the same entity inherits the base
  element's `type` attribute.  Two properties of one entity therefore share the
  renaming identifier `type`, and `NSMappingModel` inference refuses the whole model
  with *"Each property must have a unique renaming identifier"* — so
  `NSMigratePersistentStoresAutomaticallyOption` can never migrate a store written
  against any model version that contains the barcode entity.  It went unnoticed
  because the momd's current version always matched the store exactly and no migration
  ever ran.
- **Why it was load-bearing-free:** no model version before `MAD 3` has a barcode
  entity at all (`MAD.mom` and `MAD 2.mom` both lack it), so the `elementID` renames
  nothing.  It is a fossil of the entity's re-integration (`TASKS.md` §15).
- **Where:** `MADDesigner/Resources/MADFileDefinition/MAD.xcdatamodeld/MAD 3.xcdatamodel`
  (still carries it — its version hash pins the in-the-wild documents and cannot
  change) and `MAD 4.xcdatamodel` (dropped on `sql-entry`).  Diagnosed with
  `-inferredMappingModelForSourceModel:destinationModel:error:` against each `.mom` in
  the compiled `MAD.momd`: `MAD`→`MAD 4` and `MAD 2`→`MAD 4` infer cleanly;
  `MAD 3`→`MAD 4` fails with the renaming-identifier error.
- **The fix (`sql-entry`, with SQL entry Phase A; merged `c48a39fb7`):** `MAD 4.xcdatamodel` drops the
  `elementID`, so the current model is a clean inference source for future versions;
  and `MADStoreConverter` opens each legacy store with the momd version matching its
  metadata (`-modelInMomdMatchingStoreAtURL:`) instead of attempting automatic
  migration — which also repairs the latent breakage for `MAD`/`MAD 2` documents.
  Pinned by `MADStoreConverterTests` (the London/Music samples convert and read back
  equal against a `MAD 4`-current momd).

### The barcode delegate's query-field accessors disagree with their declarations
- **Status:** Fixed 2026-10-22.
- **What:** The `MADViewControllerBarcodeOptionsDelegate` protocol declares
  `- (RptqQueryField *)barcodeQueryField1;` and `:2`
  (`MADViewControllerBarcodeOptionsDelegate.h:60-61`), but `MTViewControllerBarcode`
  implements both returning `int64_t` (`MTViewControllerBarcode.m:321`, `:325`).  The
  caller `MTViewControllerBarcodeOptions.m:347` then messages the result
  (`[[delegate barcodeQueryField1] toStringHumanReadable]`), so an integer is treated as an
  object pointer -- a crash whenever that cell is populated.  The same file resolves the
  identifiers to `RptqQueryField` objects itself at `:168` and `:219`, which is what the
  protocol's callers appear to expect.
- **Why it was documented rather than fixed:** the correct shape depends on intent -- return
  the looked-up field object, or change the protocol and both call sites to the identifier.
  Both are real options and neither is a compile-fix.
- **Where:** `MADDesigner/Source/barcodes/MTViewControllerBarcode.m:321-327`,
  `MADViewControllerBarcodeOptionsDelegate.h:60-61`,
  `MTViewControllerBarcodeOptions.m:347,516`.
- **Evidence:** `-Wmismatched-return-types` on both implementations.
- **Now:** the accessors return what the protocol declares.  Both getters delegate to
  `-queryFieldForIdentifier:`, which returns `nil` for identifier `0` (no field selected
  yet) and otherwise resolves the identifier through `self.document.storeContext` -- the
  same `objectForEntity:identifier:` lookup `MTViewControllerBarcode` already performs in
  `-viewWillAppear:` and the options controller performs when a field is chosen.  A
  stale/deleted identifier resolves to `nil` and the detail label simply stays empty.
  The inline EXC_BAD_ACCESS note at the call site is removed, and the
  `-Wmismatched-return-types` warning is gone.
- **Test:** none; exercising the getter needs a barcode view controller instantiated from
  the storyboard plus a document with a populated store, which the app's unit bundle has
  no fixture for.  Verified by the compiler (the warning above) and the app suite:
  74 unit tests and 33 UI tests, 0 failures, and the app builds.

### AppDelegate's retry blocks capture themselves
- **Status:** Fixed 2026-10-28.
- **What:** `tryOpen` and `tryRefresh` are `__block` blocks that reschedule themselves with
  `dispatch_after` (`AppDelegate.m:205`, `:256`), so each block retains itself until the
  retry chain ends.  These are the UI-test launch hooks; the cycle ends when the chain
  stops, but while retries are failing the block and everything it captures stay alive.
- **Where:** `MADDesigner/Source/AppDelegate.m:200-260`.
- **Now:** Each retry block reschedules through a `__weak __block dispatch_block_t` reference
  and clears the strong `__block` holder once the retry finishes or reaches its attempt cap,
  eliminating the `-Warc-retain-cycles` compiler warnings.

### An assertion formats an integer with %@
- **Status:** Fixed 2026-10-28.
- **What:** `MADQueryViewController.m:605` asserts
  `NSAssert(objectToDelete != nil, @"Need a non-nil value for %@", tableID)` where
  `tableID` is an `int64_t`; `%@` expects an object.  `NSAssert` is compiled out of
  Release builds, so this only bites in Debug, where the formatter will treat the integer
  as a pointer.
- **Where:** `MADDesigner/Source/MADQueryViewController.m:605`.
- **Now:** The format specifier is `%lld` with `(long long)tableID`.

### `MADToolboxFormatViewController` multi-selection decimal-count check never evaluated to `YES`
- **Status:** Fixed 2026-10-28.
- **Where:** `MADDesigner/Source/MADToolboxFormatViewController.m:152-170`.
- **Behavior:** When more than one document element was selected, `allTheSame` was initialized
  to `NO` and `lastInteger` was only assigned when `counter > 0`, so
  `lastInteger == element.numericFormat.decimalCount && allTheSame` could never evaluate to `YES`
  (noted in-source by `#warning Don't think BOOL allTheSame ever becomes "YES"`).  The decimal-count
  label was therefore always blank for any multi-selection, even when every selected element had
  the same decimal count.
- **Now:** `allTheSame` starts as `self.userSelectedObjectIDs.count > 0`, `lastInteger` is
  recorded on every iteration, and `allTheSame` is cleared to `NO` only when `counter > 0` and
  `lastInteger != element.numericFormat.decimalCount`.
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
  iteration.  The Phase C design (docs/project/MAD_STORE_PHASE_C.md §2-3) specified the
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

### MADToolboxStyleViewController passes an uninitialized value to a setter
- **Status:** Fixed 2026-10-28.
- **What:** `core.CallAndMessage` reports that the argument to a property setter at
  `MADToolboxStyleViewController.m:609` is uninitialized -- the value can be read before
  any assignment on some paths.
- **Where:** `MADDesigner/Source/MADToolboxStyleViewController.m:609`.
- **Now:** `size` is initialized to `CGSizeZero` and `_stepperSizeHeight.value` /
  `_stepperSizeWidth.value` read `sizeHolder.height` and `sizeHolder.width`, matching
  the sibling margin, padding and border steppers above them.

### The app passes possibly-nil values to non-null parameters
- **Status:** Fixed 2026-10-28.
- **What:** Three argument sites where a value that can be nil reaches a parameter the
  declarations call non-null: `AppDelegate.m:210`, `MADQueryBuilderSplitViewController.m:151`,
  `MADQueryChooseFieldController.m:169`.
- **Where:** the file:line list above.
- **Evidence:** `nullability.NullPassedToNonnull` in `xcodebuild analyze`.
- **Now:** `AppDelegate.m` guards `rootClass` and `topClass` before calling
  `NSStringFromClass`; `MADQueryBuilderSplitViewController.m` guards
  `barButtonItemRevealQuery != nil` instead of passing a nil first argument to
  `-[NSArray initWithObjects:]`; and `MADQueryChooseFieldController.m` checks
  `current == nil` alongside the alias comparison so the first section array is
  always allocated even when a field's `inQueryTable.alias` is nil.

### `MADFontSelectorViewController -setFamilyName:` calls itself recursively
- **Status:** Fixed 2026-10-28.
- **Where:** `MADDesigner/Source/MADFontSelectorViewController.m:155`.
- **Behavior:** `- (void)setFamilyName:(NSString *)familyName` wrote
  `self.familyName = [familyName copy];`, invoking itself in an infinite recursion
  whenever `setSelectedFamilyName:` or `self.familyName = ...` was called.
- **Now:** `-setFamilyName:` assigns `_familyName = [familyName copy];`.

### The Refresh / Formatting / Page status label in the Viewer toolbar was unreadable on Liquid Glass
- **Status:** Fixed 2026-10-28.
- **Where:** `MADDesigner/Source/MADLabelStatus.m:50-58`,
  `MADCocoaExtensions/Source/MADLabelTitle.m:114`, and
  `MADDesigner/Source/MADThemeManager.m`.
- **Behavior:** `MADLabelStatus` and `MADLabelTitle` hardcoded
  `NSForegroundColorAttributeName: [UIColor whiteColor]`, and `MADThemeManager`
  configured opaque blue bars in Light Mode vs. dark blur in Dark Mode while forcing
  white `UIBarButtonItem.tintColor`. On modern iOS with system/Liquid Glass bar
  materials, white text and bar buttons had low or zero contrast in Light Mode.
- **Now:** `MADThemeManager` uses `configureWithDefaultBackground` and semantic
  dynamic colors (`labelColor`, `secondaryLabelColor`, `systemBlueColor`),
  `MADLabelTitle` uses `[UIColor labelColor]`, and `MADLabelStatus` uses
  `[UIColor labelColor]` and `[UIColor secondaryLabelColor]`.
- **Test:** `MADCocoaExtensionsTests/MADLabelTitleTests`.

### `MADTabBarController` recreated all three tab view controllers on every `-viewWillAppear:`
- **Status:** Fixed 2026-10-28.
- **Where:** `MADDesigner/Source/MADTabBarController.m:85-104,138-143`.
- **Behavior:** `-viewWillAppear:` unconditionally instantiated and assigned new
  Query, Designer, and Viewer view controllers, and `-viewDidDisappear:` cleared
  `self.viewControllers = nil` even when a modal sheet was presented over the tab bar.
- **Now:** `-viewWillAppear:` populates `self.viewControllers` only when
  `self.viewControllers.count == 0`, and `-viewDidDisappear:` clears them only when
  `self.isMovingFromParentViewController || self.isBeingDismissed`.

### `MADDesignerViewController`: editing a dynamic label's field looked up the label by the field ID and anchored the popover at `CGRectZero`
- **Status:** Fixed 2026-10-28.
- **Where:** `MADDesigner/Source/MADDesignerViewController+CollectionView.m`
  (`-editDocumentObjectLabelDynamic:`) and
  `MADDesigner/Source/MADDesignerViewController+ElementSaving.m`
  (`-tableViewControllerChooseFieldDidFinish:withFieldID:`).
- **Behavior:** `-editDocumentObjectLabelDynamic:` looked up `viewToEdit` in
  `self.view.scroller.container.sectionLabels` (which is keyed by section identifier)
  using the element's identifier, returning `nil` and anchoring the popover at
  `CGRectZero`. Then, when the user chose a new field in
  `-tableViewControllerChooseFieldDidFinish:withFieldID:`, it fetched
  `+[RptqDocumentElementLabelDataField newDocumentElementWithIdentifier:field.identifier ...]`
  instead of `self.objectIdEditDynamicLabel.longLongValue`, so the edited label element
  was never found or updated.
- **Now:** `-editDocumentObjectLabelDynamic:` looks up `viewToEdit` in
  `self.elementViewsDictionary[@(object.identifier)]`, and
  `-tableViewControllerChooseFieldDidFinish:withFieldID:` fetches the label element using
  `self.objectIdEditDynamicLabel.longLongValue` and clears `self.objectIdEditDynamicLabel`.
- **Test:** `MADDesignerUnitTests testChooseFieldDidFinishUpdatesEditedDynamicLabelFieldReference`.

### `MADDesignerViewController -sectionForLabelTag:` and `-documentSectionViewWithIdentifier:` looked up the wrong section
- **Status:** Fixed 2026-10-28.
- **Where:** `MADDesigner/Source/MADDesignerViewController.m` (`-sectionForLabelTag:`
  and `-documentSectionViewWithIdentifier:`).
- **Behavior:** `-sectionForLabelTag:(NSInteger)tag` ignored its `tag` parameter and
  queried `self.lastSelectedSectionControlPanel` instead.
  `-documentSectionViewWithIdentifier:(NSInteger)identifier` compared
  `((MADDesignerSectionView *)subview).tag == identifier`, but `MADDesignerSectionView`
  stores its section ID in `.identifier` while `UIView.tag` remains `0`.
- **Now:** `-sectionForLabelTag:` queries `(int64_t)tag`, and
  `-documentSectionViewWithIdentifier:` compares
  `((MADDesignerSectionView *)subview).identifier == identifier`.
- **Test:** `MADDesignerUnitTests testSectionForLabelTagUsesPassedTagNotLastSelectedSectionControlPanel`
  and `testDocumentSectionViewWithIdentifierMatchesIdentifierPropertyNotViewTag`.

### `MADViewerController -showPrintDialog` inverted queue priority and `MADOperationLoadPrintPageRender -main` read an uninitialized `MADocument *` pointer
- **Status:** Fixed 2026-10-28.
- **Where:** `MADDesigner/Source/MADViewerController+PrintingAndExport.m`
  (`-showPrintDialog` and `-[MADOperationLoadPrintPageRender main]`).
- **Behavior:** `-showPrintDialog` dispatched a block to
  `DISPATCH_QUEUE_PRIORITY_BACKGROUND` whose body immediately called
  `dispatch_sync(dispatch_get_main_queue(), ...)`, causing a main-thread priority
  inversion while doing no background work. In `MADOperationLoadPrintPageRender -main`,
  local variable `MADocument *document;` was never initialized from `self.document`
  before `document.printPageRenderer` was read and assigned.
- **Now:** `-showPrintDialog` dispatches UI presentation with
  `dispatch_async(dispatch_get_main_queue(), ...)`, and
  `-[MADOperationLoadPrintPageRender main]` initializes
  `MADocument *document = self.document;`.

### Unselected tab bar icons forced `UIImageRenderingModeAlwaysOriginal` on white PNG strokes, making them invisible in Light Mode and over white surfaces on Liquid Glass
- **Status:** Fixed 2026-10-28.
- **Where:** `MADDesigner/Source/UIViewController+tabBarItem.m:32-38`,
  `MADDesigner/Source/MADThemeManager.m:82-116`, and
  `MADDesigner/Resources/Assets/Images.xcassets/UIBarButtonItem*8.imageset/Contents.json`.
- **Behavior:** `UIViewController+tabBarItem` created `tabBarItem.image` with
  `UIImageRenderingModeAlwaysOriginal` while creating `tabBarItem.selectedImage` with
  `UIImageRenderingModeAutomatic`, and the three tab bar icon asset sets (`UIBarButtonItemDatabase8`,
  `UIBarButtonItemMadDesigner8`, `UIBarButtonItemMadViewer8`) had no template rendering intent.
  Because the underlying PNGs are white strokes with small red accents on a transparent background,
  the selected tab was tinted blue by UIKit, whereas unselected tabs rendered raw white pixels on
  the white Liquid Glass capsule in Light Mode (leaving only tiny red accents visible) and had
  poor contrast in Dark Mode when floating over white content.
- **Now:** Both `tabBarItem.image` and `tabBarItem.selectedImage` use
  `UIImageRenderingModeAlwaysTemplate`, the three asset catalog image sets declare
  `"template-rendering-intent" : "template"`, and `MADThemeManager` configures unselected tab
  bar items with full-contrast `[UIColor labelColor]`.
- **Test:** `MADDesignerUnitTests testTabBarAndViewerToolbarLayout`.

### `MADNavigationControllerViewer` and `MADNavigationControllerQueryBuilder` bottom toolbars overlapped the floating `UITabBar` on iOS 26 and squished `MADLabelStatus`
- **Status:** Fixed 2026-10-28.
- **Where:** `MADDesigner/Source/MADNavigationControllerViewer.m`,
  `MADDesigner/Source/MADNavigationControllerQueryBuilder.m`, and
  `MADDesigner/Source/MADLabelStatus.m`.
- **Behavior:** On iOS 26+, `UINavigationController` hosts its toolbar inside a private
  `FloatingBarContainerView` positioned using only the window's bottom safe area inset,
  ignoring the parent `UITabBarController`'s floating `UITabBar`. As a result, even though
  `UINavigationController` reserved space above the tab bar when sizing `MADViewerController.view`,
  the status toolbar itself was pinned at the bottom of the screen directly underneath the
  floating `UITabBar`. Additionally, iOS 26 wraps `UIBarButtonItem.customView` (`MADLabelStatus`)
  in `_UITAMICAdaptorView` inside `UIPlatformGlassInteractionView`, which compressed
  `MADLabelStatus` to `38pt` wide because `MADLabelStatus` had no `-intrinsicContentSize` or
  width/height constraints.
- **Now:** `MADNavigationControllerViewer` and `MADNavigationControllerQueryBuilder` implement
  `-viewDidLayoutSubviews` to position both classic `self.toolbar` (`self.toolbar.superview == self.view`)
  and iOS 26's `FloatingBarContainerView` directly above `self.tabBarController.tabBar` when the
  tab bar is visible, and `MADLabelStatus` provides `-intrinsicContentSize` (`230x44`) and
  explicit width/height constraints so the 3-line status readout is not compressed inside the
  floating toolbar pill.
- **Test:** `MADDesignerUnitTests testTabBarAndViewerToolbarLayout`.

### `MAD Viewer` launched to a black screen with a missing `UIScene` lifecycle manifest, uncompiled app sources, and unbundled storyboards and sample assets
- **Status:** Fixed 2026-10-29.
- **Where:** `MADDesigner/Targets/MADViewer/info.plist`,
  `MADDesigner/Targets/MADViewer/SupportingFiles/main.m`,
  `MADDesigner/Source/AppDelegate.m`, `MADDesigner/Source/MADTabBarController.m`,
  `MADDesigner/Source/MADExplorerNavigationItem.m`,
  `MADDesigner/Source/MADExplorerController.m`,
  `MADDesigner/Source/MADExplorerController+DocumentActions.m`,
  `MADDesigner/Source/MADUpgradeManager.m`, and
  `MADDesigner/MAD Designer.xcodeproj/project.pbxproj`.
- **Behavior:** Launching the `MAD Viewer` app target logged
  `"`UIScene` lifecycle will soon be required. Failure to adopt will result in an assert in the future."`
  and displayed a solid black window. Specifically:
  1. `MADDesigner/Targets/MADViewer/info.plist` had no `UIApplicationSceneManifest` and no
     `UIMainStoryboardFile`, and `MADViewerAppDelegate.m` instantiated a manual `UIWindow` with no
     `rootViewController`.
  2. In `project.pbxproj`, `MAD Viewer`'s `Sources` build phase compiled only 7 files (missing
     `AppDelegate.m`, `SceneDelegate.m`, `MADExplorerController.m`, `MADTabBarController.m`,
     `MADViewerController.m`, and the rest of `MADDesigner/Source/`), its `Resources` build phase
     bundled only 4 files (missing `MADExplorer.storyboard`, `MADDesigner.storyboard`,
     `SampleDatabases.xcassets`, `FontAwesome.ttf`, and the about/store storyboards), and its
     Debug configuration lacked `MAD DesignerDebug.entitlements` (`group.everydayapps.mad.local`).
  3. `MADTabBarController` always created all 3 tabs (`MADQueryBuilderSplitViewController`,
     `MADNavigationControllerDesigner`, and `MADNavigationControllerViewer`) and kept `UITabBar`
     visible; `MADExplorerNavigationItem` hardcoded `"MAD Designer"` as its title; and
     `MADExplorerController` left the `+` (Create New Document) bar button item visible.
- **Now:** `MAD Viewer` shares `AppDelegate` and `SceneDelegate` with `MAD Designer` (retiring the
  stale `MADViewerAppDelegate` copy and selecting viewer identifiers/names under `#if MAD_VIEWER`),
  declares `UIApplicationSceneManifest` (`SceneDelegate` + `MADExplorer` storyboard) in
  `MADDesigner/Targets/MADViewer/info.plist`, compiles the full shared source set and bundles all
  required storyboards/assets/resources in `project.pbxproj`, titles the explorer `"MAD Viewer"`,
  hides the `+` button in `MADExplorerController`, and configures `MADTabBarController` with a
  hidden `UITabBar` and `[navControllerViewer]` as its sole child controller when `MAD_VIEWER` or
  `[MADApplication isMADViewer]` is true.
- **Test:** `MADDesignerUnitTests testMADViewerModeHidesTabBarOmitsDesignerTabsAndHidesAddDocumentButton`.

### `MADNavigationController +documentNavigationControllerWithType:document:` threw `NSInternalInconsistencyException` for `MADNavigationControllerTypeViewer` in `MAD Viewer`
- **Status:** Fixed 2026-10-29.
- **Where:** `MADDesigner/Source/MADNavigationController.m:20-23,149-182`.
- **Behavior:** `+documentNavigationControllerWithType:document:` wrapped its entire `switch (type)`
  block (including `case MADNavigationControllerTypeViewer:`) inside `#if MAD_DESIGNER`, falling
  through to `@throw [NSException exceptionWithName:NSInternalInconsistencyException ...]` whenever
  compiled into the `MAD Viewer` target (where `MAD_VIEWER=1` and `MAD_DESIGNER` is not defined).
- **Why it matters:** Opening any document in `MAD Viewer` asks `MADTabBarController` to build the
  viewer navigation controller via
  `[UINavigationController documentNavigationControllerWithType:MADNavigationControllerTypeViewer document:document]`,
  which unconditionally crashed with `NSInternalInconsistencyException`.
- **Now:** `MADNavigationControllerViewer.h` is imported unconditionally and
  `case MADNavigationControllerTypeViewer:` is compiled in both `MAD Designer` and `MAD Viewer`,
  while `MADNavigationControllerTypeDesigner` and `MADNavigationControllerTypeQuery` remain scoped
  to `#if MAD_DESIGNER`.
- **Test:** `MADDesignerUnitTests testNavigationControllerViewerFactoryAndNavigationBar`.

### `MADViewerController` set its Refresh button, Done button, and refresh activity indicator on the hidden `self.tabBarController.navigationItem` instead of `self.navigationItem`
- **Status:** Fixed 2026-10-29.
- **Where:** `MADDesigner/Source/MADViewerController.m:203-204,225,421,442`.
- **Behavior:** `-viewDidAppear:`, `-viewDidDisappear:`, `-setDisplayActive`, and
  `-setDisplayInactive` mutated `self.tabBarController.navigationItem.rightBarButtonItem` and
  `leftBarButtonItem`. However, `MADTabBarController -viewDidLoad` hides its enclosing navigation
  controller's navigation bar (`[self.navigationController setNavigationBarHidden:YES animated:NO]`),
  and the visible navigation bar in the viewer is `MADNavigationControllerViewer`'s `MADViewerNavigationBar`,
  which displays `MADViewerController`'s own `self.navigationItem`.
- **Why it matters:** When `-setDisplayInactive` started a refresh, the spinning
  `UIActivityIndicatorView` was placed on the hidden `tabBarController.navigationItem` while the
  visible navigation bar kept showing the static Refresh icon; and `-viewDidAppear:` /
  `-setDisplayActive` wrote their fresh `buttonRefresh` and `buttonDone` items to the hidden
  navigation item instead of the visible one.
- **Now:** `-viewDidAppear:`, `-viewDidDisappear:`, `-setDisplayActive`, and `-setDisplayInactive`
  all update `self.navigationItem`.
- **Test:** `MADDesignerUnitTests testViewerControllerNavigationItemsSetOnOwnNavigationItem`.

### `MADOperationInstallSampleDocument` checked `fileExistsAtPath:` before appending the `.mad` file extension, overwriting existing sample documents
- **Status:** Fixed 2026-10-29.
- **Where:** `MADDesigner/Source/MADOperationInstallSampleDocument.m:60-85` (and the companion
  `fileExistsAtPath:` guard in `MADDesigner/Source/MADOperationInstallSampleDatabase.m:51-77`).
- **Behavior:** `MADOperationInstallSampleDocument -execute` built
  `destination = [localDocumentsDirectory URLByAppendingPathComponent:_filename isDirectory:NO]`
  (e.g. `.../Documents/London` without `.mad`), checked
  `[[NSFileManager defaultManager] fileExistsAtPath:destination.path isDirectory:&isDirectory]`,
  and only *after* `fileExistsAtPath:` returned `NO` appended
  `destination = [destination URLByAppendingPathExtension:_fileExtension]` (`.../Documents/London.mad`)
  and overwrote the file.
- **Why it matters:** Because `Documents/London` (without `.mad`) never exists on disk, the upgrade
  existence check always evaluated to `NO`, and launching `MAD Viewer` (or resetting `NSUserDefaults`)
  overwrote any existing `London.mad` or `Music.mad` in the shared app group container. Conversely,
  `MADOperationInstallSampleDatabase` trusted the `NSUserDefaults` boolean alone without checking
  whether `chinook.sqlite3` actually existed on disk.
- **Now:** `MADOperationInstallSampleDocument` appends `_fileExtension` to `destination` before
  calling `fileExistsAtPath:`, and `MADOperationInstallSampleDatabase` verifies both the user-defaults
  key and `fileExistsAtPath:` on `databaseURL.path`.
- **Test:** `MADDesignerUnitTests testInstallSampleDocumentDoesNotOverwriteExistingFileWithExtension`.

### `MADExplorerController -documentManagerDidChangeContent:removes:updates:completion:` called `performBatchUpdates:` on an unmounted `UICollectionView` (`window == nil`), crashing with `NSInternalInconsistencyException`
- **Status:** Fixed 2026-10-29.
- **Where:** `MADDesigner/Source/MADExplorerController.m:402-415`.
- **Behavior:** When `MADFilesController` finished enumerating files and delivered insertions to
  `MADExplorerController -documentManagerDidChangeContent:removes:updates:completion:` while
  `self.collectionView.window == nil` (before the collection view had ever been added to a window
  or performed its initial layout), calling `[self.collectionView performBatchUpdates:completion:]`
  caused `UICollectionView` to query `[dataSource collectionView:numberOfItemsInSection:0]` for the
  first time at the start of the batch — after `fileMetaDatum` already held the inserted items —
  and then apply `insertItemsAtIndexPaths:`, raising `NSInternalInconsistencyException`
  (`Invalid batch updates detected`).
- **Now:** When `self.collectionView.window == nil`, `-documentManagerDidChangeContent:removes:updates:completion:`
  calls `[self.collectionView reloadData]` and invokes `completion(YES, nil)` directly.
- **Test:** `MADDesignerUnitTests testMADViewerModeHidesTabBarOmitsDesignerTabsAndHidesAddDocumentButton`.

## Linux build

### `mad refresh` over MySQL aborted: a category is not a symbol, so the linker dropped it
- **Status:** Fixed
- **Where:** the arrangement in `Linux/CMakeLists.txt:138,381-384` and
  `Linux/cmake/MADLinuxFramework.cmake`; the failure showed in
  `CLI/Source/MADCLIDocument.m`'s refresh chain
- **Behavior:** The first `mad refresh` against live MySQL from inside the Linux image
  died with SIGABRT and no diagnostic, after `executeSQL:` had been entered and before
  the fetch. `MADMySQLFetch (DataTable)` -- `-fetchWithCommand:dataTable:onConnection:
  extendedNames:error:`, the only path that runs a prepared statement -- is a
  *category*, and a category is reached by message send, which leaves no symbol for
  the linker to resolve; libmadmysql.a was linked normally, so its member was never
  pulled in. `nm` showed `.objc_category_MADMySQLFetchDataTable` present in the MySQL
  test binary and absent from the CLI's; `instancesRespondToSelector:` was false at
  runtime, and the unrecognized selector ended in `abort()`.
- **Why it matters:** The same failure waits for every category in any framework
  archive that is not whole-archived. The build had known about the shape (one file,
  `MADQuery+Sqlite3.m`, was compiled into `libmad.a` by hand for exactly this reason)
  but the reason -- a category is invisible to the linker -- was not written down, so
  each new category was a new landmine.
- **Now:** `Linux/Compat/*` is its own static library, `madcompat`
  (`Linux/CMakeLists.txt:138`), whole-archived by every executable, so framework
  archives are pure and can themselves be whole-archived: the `mad` target
  whole-archives `madsqlite3`, `madmysql` and `madtdsclient` (and MADTds is
  deliberately left out -- it has no categories and whole-archiving it collides with
  freetds' `err_handler`). The per-file `target_sources` hack is gone. `Linux/README.md`
  has the story; `Linux/AGENTS.md` states the rule.
- **Test:** `Linux/Tests/MADDatabaseDriverDispatchTests.m`
  (`testTheDriversCategoriesAreLinked`) asserts at runtime that `MADMySQLFetch` still
  answers its `DataTable` selector and that `MADQuery` still answers
  `-whereClauseWithRowIds:` / `-whereClauseWithParameters:` -- the two categories the
  data path needs. It fails the moment an archive stops being whole-archived.

### Three `Rptq…+extras.h` imports were spelled in the wrong case, which only a case-sensitive filesystem can see
- **Status:** Fixed
- **Where:** `MAD/Source/MADOperationRefreshInitialize.m:34-36` (fixed in `a17d802be`),
  `MAD/Source/MADOperationCreateDocumentFirstTimeSetup.m` (the same three, fixed
  preventively)
- **Behavior:** The imports read `<MAD/RptqDocument+extras.h>`,
  `<MAD/RptqDatabase+extras.h>` and `<MAD/RptqQuery+extras.h>`; the headers are
  `RptqDocument+Extras.h`, `RptqDatabase+Extras.h`, `RptqQuery+Extras.h`. The Mac's
  filesystem is case-insensitive, so the app target compiled them for years and the
  simulator CLI compiled them too. The Linux image copies the sources onto ext4 and
  *refuses* them: the image build failed with a fatal error on the moved file.
- **Why it matters:** It is a class of defect, not an instance: any import whose case
  disagrees with the file resolves here and nowhere else, and nothing on the Mac can
  see it. The audit that finds them all is written down in `Linux/AGENTS.md`
  (compare every `<Framework/Header>` import against the directory listing for exact
  case).
- **Now:** all three spell the headers the way they are spelled on disk. The first was
  found by the image build; the second file is not in the Linux build yet (it is one of
  the create-document operations) and was corrected because it would have failed the
  same way the day it joins.
- **Test:** the Linux image build (the fix's own regression test).

## Build wiring (Xcode references)

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
- **Status:** Fixed
- **Where:** the MAD Viewer target in
  `MADDesigner/MAD Designer.xcodeproj/project.pbxproj`,
  `MADDesigner/Source/MADNavigationController.m`,
  `MADDesigner/Targets/MADViewer/MADViewerAppDelegate.m`
- **Behavior:** its build settings were left pointing into `MADStack/`, the directory
  `09e0e7b8d` ("Project cleanup and reorganization") deleted —
  `CODE_SIGN_ENTITLEMENTS` and `GCC_PREFIX_HEADER` at the Designer's old paths, and
  `INFOPLIST_FILE = MADStack/MADViewer/info.plist`. The build stopped at
  `ProcessProductPackaging` with *"Build input file cannot be found"*. Those six
  settings were pointed at `Targets/MADViewer/`, reaching the link step, which then
  failed on undefined classes (`MADApplication`, `MADDesignerNavigationBar`,
  `MADNavigationControllerDesigner`, `MADNavigationControllerViewer`,
  `MADSalesReceipt`, `MADThemeManager`, `MADViewerNavigationBar`) and missing
  framework links.
- **Now:** the `MAD Viewer` target compiles `MADStoreConverter.m`,
  `MADStoreLegacyConverter.m`, `MADThemeManager.m`, `MADSalesReceipt.m`,
  `NSData+Base64.m`, and `MADViewerNavigationBar.m`, links and embeds the workspace
  frameworks plus `openssl.xcframework`, scopes the Designer-tab
  `+documentNavigationControllerWithType:document:` factory in
  `MADNavigationController.m` under `#if MAD_DESIGNER`, and implements the missing
  `MADApplicationProtocol` methods on `MADViewerAppDelegate`.
- **Verification:** `xcodebuild build -workspace Reports.xcworkspace -scheme "MAD Viewer"`
  builds and links cleanly.

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

### Two parallel Linux suites raced over the same London fixture and sample database
- **Status:** Fixed (2026-10-17)
- **Where:** `Linux/CMakeLists.txt` (the `mad_add_framework(mad …)` block),
  `Linux/Tests/MADHeadlessDocumentTests.m`, `Linux/Tests/MADReportExporterTests.m`
- **Behavior:** ctest runs the 119 test binaries in parallel, and both suites
  install `chinook.sqlite3` into the same per-user Application Support directory
  (remove-then-copy) and refresh the same London fixture into the same cache
  directory. When their windows overlapped, one of them failed — seen as
  `MADHeadlessDocumentTests`' *problem in testTheRefreshChainFillsTheRowCache*,
  and once as an unexplained `MADURLFactoryTests` failure. GNUstep takes the
  home directory from `getpwnam`, not `HOME`, so per-test `HOME` does not
  isolate them.
- **Now:** the pair carries a shared ctest `RESOURCE_LOCK`
  (`mad-london-fixture`), so they take turns while the rest of the suite stays
  parallel. Verified with 35 consecutive green parallel runs on 2026-10-17;
  `Linux/AGENTS.md` records the rule for future suites.
- **Test:** the suite itself (`./Linux/build.sh`).

## Linux build

### The pinned cross-platform export digests went stale on the Apple side

- **Status:** Fixed 2026-10-25 (commit `b07b51f43`).
- **Where:** the pinned digests in `Linux/README.md` (the export tables) and the
  FNV-1a expectations in `Linux/Tests/MADReportExporterTests.m`, recorded from the
  Mac's bytes on 2026-10-16.  The behaviour change is `c27cd4188` ("cache ORDER BY
  uses the column's MADDataType, so text keys sort under LSASC", 2026-10-18): the
  collation lives in `MADSqlite3/Source/MADDatabaseSqlite3.m`
  (`compare_string_utf8_localized_asc_collation`) and is selected by
  `MADDataTableFast -enumeratorForKeyObjectsSorted`
  (`MADSqlite3/Source/MADDataTableFast.m:1380`).
- **Behavior:** the cache's export ORDER BY sorts text keys under LSASC, which is
  `localizedCaseInsensitiveCompare:` — ICU on Apple, code-point on GNUstep (the
  divergence pinned per-platform in `MADDatabaseSqlite3Tests`).  ICU sorts
  punctuation before letters, so `[1997] Black Light Syndrome` sorts ahead of
  `Core`; code-point sorts `[` after `Z`.  Measured 2026-10-25 on
  `CLI/Fixtures/London.portable.mad`: the Mac CLI (iOS 26.0 and 26.1 simulators,
  frameworks built at `91d5b55ff`) exports the same *sizes* but a different *group
  order* for all six formats — html is `285541ed…` where the pin (and today's
  Linux) is `ba12a289…`; json, csv, text, json-report and html-flow diverge the
  same way.  The two caches' insertion order is identical (76 rows compared by
  value); only the collated order differs.  Linux still matches every pinned
  digest, so the Linux suite stays green and nothing re-measures the Mac — the
  staleness is silent.
- **Why it matters:** "the same bytes on two platforms" is the load-bearing claim
  of the launch (`MAD_STRATEGY.md` §3.2) and of the marketing drafts; the pinned
  digests are what the demo script shows.  Until this is settled the claim is
  true of Linux only.
- **Options:** (a) make the export order collation-independent — a stable,
  defined order both platforms can implement, which is the fix that keeps the
  claim; (b) re-baseline the pins to whichever platform's order is chosen as
  canonical and weaken the claim to "identical given the platform's collation";
  (c) accept and document.  Not a blocker for the Linux demo, but the launch
  post must not claim Apple/Linux byte identity until (a) lands.
- **Now:** option (a) landed: the export's group order is a defined order —
  case-fold (the simple one-to-one fold of Unicode 17.0.0, a checked-in table in
  `MADFoundation/Source/NSString+Comparison.m`), then UTF-8 code-point order —
  and one comparator (`-[NSString mad_orderedCompare:]` and its C core) drives
  all three sites: the LSASC collation, the in-memory sort descriptors
  (`MADDataTypeSelectorForSorting`) and the formatter's string pair.  All pins
  re-measured from both platforms and identical; the write `--reproducible`
  bytes (16,261, `09815b24…`) did not change.  On Apple the London fixture's
  group order did not move at all; `Music.portable.mad` moved 31 album blocks
  (89 rows) to the defined order.
- **Test:** the Mac CLI export compared against `Linux/README.md`'s table
  (2026-10-25).  No automated Mac-side digest gate exists; its addition (the
  Mac-side counterpart of `MADReportExporterTests`) is the fix's proof — now
  added (`MAD/MADTests/MADReportExporterTests.m` opens, refreshes and exports
  the London fixture and pins the FNV-1a checksums), alongside the defined-order
  tests (`NSStringComparisonTests`, both platforms) and the collation/formatter
  agreement sweeps in `MADDatabaseSqlite3Tests` and `MADReportExporterTests`.
