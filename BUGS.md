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

## MADSqlite3

No defects found. The `MADDataTypeUnknown → String`/`TEXT` coercions in
`MADDatabaseSqlite3` are intentional fallbacks and are covered by tests.

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
