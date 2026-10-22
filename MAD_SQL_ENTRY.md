# MAD SQL Entry — pasting a SQL query into the query designer

**Scope:** a new parser/resolver/compiler in `MAD/Source/sql/`, an apply path on `MADocument`,
the SQL popover in `MADDesigner`, the persisted source text (§8, which adds the store's first
versioning step), and the tests that pin all of it.
**Date:** 2026-10-22, read at `cf0fe3acd`; revised 2026-10-22 with the persistence decision (§8).
**Status:** design. Nothing here is implemented; it is not on the task queue until the user asks
for it (TASKS.md §16).

---

## 1. The goal

Today the only way to build a query is the visual designer: pick tables, link them field by
field, add filters, add groupings — all through the tabbed UI. The user wants a second way in:

> "…a user could hit a button and it flips around and shows a multiline text view where they
> can paste the SQL… when that SQL is saved, it manually creates the query in the backend of
> the report… it does everything it already would do with the user selecting all the details…
> the software still recognizes what fields are used what joins are used what tables are used,
> and it completely setups the document in the proper way, and then allows the user to even
> use the query designer with the fields entered by the standard query (if they wish to)."

So: the pasted SQL is **compiled into the document's query model** (the `Rptq` object graph),
through exactly the same factories the visual designer calls. After apply, the visual query
designer, the visualization canvas, and the report designer all see the query as if it had
been built by hand — and the user can keep editing it there. There must be a validation phase.

## 2. What exists today (read first-hand)

### 2.1 The canonical query model — the `Rptq` graph

The document's query lives in the portable store as plain `Rptq*` objects
(`MAD/Source/rptq/`); the `MADModel*` layer is a read-only view over them
(`MADModel_Layer.md`). The importer writes `Rptq` rows and nothing else.

* `RptqQuery` (`MAD/Source/rptq/autogen/RptqQuery.h:30-34`): `hasQueryTables`,
  `hasQueryLinks`, `hasQueryPredicate` (note the singular name), `hasQueryGroups`.
* `RptqQueryTable` — a schema-table reference plus an alias; the alias is *computed*:
  the schema table's name for the first copy, name + drop index afterwards
  (`Customer`, `Customer0`, … — `MADModelQueryTable.m:119-129`).
* `RptqQueryField` — two ids: `inQueryTable` + `databaseSchemaField`. Every field of every
  query table gets a row (the add-table flow creates one per schema field,
  `MADQueryViewController.m:762-770`).
* `RptqQueryLinks` — one join: `hasLeftField`/`hasRightField` (a `RptqQueryField` each),
  `type` (`MADLinkType`, `MADQueryLinkType.h`: inner / equi / natural / cross / left / right
  / full outer). Exactly one field pair per link; the generator always emits `ON l = r`
  (`MADQueryFull.m:366-380`).
* `RptqQueryPredicate` — `comparson` (`MADPredicateOperator`: `=`, `<>`, `>`, `>=`, `<`,
  `<=` — `MADPredicateOperator.h`, `RptqQueryPredicate+Extras.m:245-265`), plus a
  left/right side that is either a `RptqQueryField` or a typed value string
  (`leftFieldID`/`rigthFieldID`). All predicates are AND-ed, each written `(left op right)`
  (`MADQueryPredicate.m:43-93`). No OR, no LIKE, no IN, no functions.
* `RptqQueryGroup` — `hasField`, `sort` (`MADSortOrder`), `weight`, and `hasSection`: the
  report's group header/footer sections (`RptqQueryGroup.h:24-29`).

What the model does **not** hold — the boundaries the importer must respect:

* **No SELECT list.** The SELECT is derived at SQL-build time from which query fields are
  referenced by designer elements (data labels, aggregates, barcodes), links, and groups
  (`MADQueryActiveQueryFields.m:37-97`, `MADQuerySelectExpressionActiveFields.m`).
* **No free ORDER BY.** Sort order exists only per group (`RptqQueryGroup.sort`).
* **No OR / IN / LIKE / functions / subqueries / UNION** — none are representable.
* **No stored SQL text**, and no store versioning to add a column with (below, §8).

### 2.2 SQL generation — the round-trip contract

`MADQueryFull` builds the executed SQL from the model
(`SQLOnlyActiveFields:managedObjectContext:error:`, `MADQueryFull.m:143-273`):

* `SELECT` part from the driver, then the active fields, sorted by column alias, written
  **without `AS`**: `"Table0"."Field"` (`MADQuerySelectExpressionActiveFields.m:32-38, 46-53`).
* `FROM` — a DFS over the join graph: `tableName <connector> queryAlias`, then
  `LEFT OUTER JOIN tableName <connector> queryAlias ON l.field = r.field` per link
  (`MADQueryFull.m:275-426`, join text from `RptqQueryLinks SqlForLinkType:`,
  `RptqQueryLinks+Extras.m:76-86`).
* `WHERE` — the AND-ed predicate triples (`MADQueryPredicate.m`).
* No `GROUP BY`/`ORDER BY` in the SQL — grouping and sorting are applied over the
  `.maddb` cache (`MADParameters+QueryCacheAggregate`, `MADQueryCacheSelectGroupKeys`).
* A driver-supplied `LIMIT` clause.

The importer's contract is therefore: **a pasted statement is acceptable exactly when it
could be the output of `MADQueryFull` for some model.** That is what makes the round-trip
honest — the View side of the SQL popover shows the SQL regenerated from the imported model,
and it reads like what the user pasted.

### 2.3 The refresh pipeline — the pattern validation reuses

`MADOperationRefresh.m:60-172`: connect with credentials supplied by operation dependencies,
build the SQL **on the main queue** (the store context is main-queue-owned — BUGS.md), then
`[database executeSQL:fieldKeys:onConnection:intoResultTable:withError:]`
(`MADDatabaseProtocol.h:33`) and `dataTableMakeCache`. A validation probe is the same
operation shape minus the cache build.

### 2.4 The backend the UI already calls — the seam the compiler reuses

Writing `Rptq` rows and saving is enough; the `MADModel*` layer mirrors the change into the
UI via store notifications (`MADModel_Layer.md` §3.3). The factories to call, verbatim from
today's UI code:

* **Add table** — `[RptqQueryTable newQueryTableForSchemaTable:database:forManagedObjectContext:]`
  then one `[RptqQueryField newQueryField:context]` per schema field, wired to the table,
  table added to `query.hasQueryTables`, save (`MADQueryViewController.m:744-799`).
* **Add link** — `[RptqQueryLinks newQueryLinksWithLeftField:rightField:joinType:managedObjectContext:]`
  then `[document.activeDocumentModel addQueryLink:link]`, save
  (`MADQueryLinkBuilderController.m:112-122`).
* **Add predicate** — `[RptqQueryPredicate newQueryPredicateFactoryWithLeftFieldID:…]` /
  `…WithLeftValue:…` variants (`MADQueryAddPredicateController.m:142-162`,
  `RptqQueryPredicate+Extras.h:20-39`).
* **Add group** — `[document addQueryGroupWithQueryField:andSortOrder:]`
  (`MADocument.m:728-792`). This one call creates the group row *and* the report's group
  header/footer sections *and* their section layout managers — "completely sets up the
  document" for a `GROUP BY`, for free.
* **Deletion, for the replace path** — `removeGroupWitObjectID:fromManagedObjectContext:`
  (`MADocument.m:1130`), `deleteDatafieldsRelatedToTable:inContent:` and
  `deleteAggregateFieldRelatedToTable:inContent:` (`MADocument.h:91-95`), and the existing
  link/predicate removal paths in the query UI. Phase B inventories these; any missing
  symmetrical helper for links/predicates gets added there.

### 2.5 The UI seam

The query builder split view controller already has a `barButtonItemSQL` toolbar item that
presents a **read-only** `MADViewControllerSQL` popover (`MADQueryBuilderSplitViewController.m:31,
106-111`; `MADQuery.storyboard`; `MADViewControllerSQL.m:27-56` shows
`[doc.mainQuery SQLOnlyActiveFields:…]`). The feature is a mode of this same screen, so the
button, the popover, and the navigation all exist.

## 3. The feature, as the user sees it

1. In the query tab, tap the existing SQL button. The popover now has **View / Edit** modes.
2. **View** shows both representations of the query's SQL, as a segmented control:
   * **Generated** — the SQL `MADQueryFull` builds from the model right now (today's
     popover content, kept as the default tab).
   * **As entered** — the user's last applied statement, verbatim
     (`RptqQuery.sqlSourceText`, §8); hidden or empty when the query has never been built
     from pasted SQL.
   Both tabs are read-only — the "see what you pasted, and see what it became" screen.
3. **Edit** — a monospaced multiline text view, seeded from `sqlSourceText` when present
   (the user re-edits *their* text, formatting and comments intact) and from the generated
   SQL otherwise; a **Revert to generated** button re-seeds from the generated form.
4. **Validate** — structural check plus, when the document's database can be reached, a
   zero-row server probe (§7). Errors come back with line and column.
5. **Apply** — the statement is compiled into the document (atomic — §6.5) and the exact
   pasted text is persisted as `sqlSourceText` (§8). The popover closes; the query tables
   list, the visualization canvas, and the report designer all show the imported structure.
   The designer's field pickers work as usual.
6. A failed or conflicted apply persists nothing — not the text, not any rows. The previous
   query and its previous entered text stay exactly as they were.
7. The user can flip back at any time: the visual designer keeps working on the imported
   query, View shows both forms, and Edit re-opens their own words.

## 4. Architecture

```
pasted SQL
  → MADSQLTokenizer        dialect-aware lexer; quotes per driver; tracks line:column
  → MADSQLParser           recursive descent; produces a MADSQLStatement parse tree
  → MADSQLStatementResolver  binds names to RptqDatabaseSchemaTable / RptqDatabaseSchemaField
  → [MADOperationValidateSQL]  server probe, when connected (§7); never writes
  → MADSQLQueryCompiler    the write plan: deletes + creates Rptq rows via the §2.4 factories
  → store save → model notifications → query UI / visualization / designer update
```

**Placement.** Everything except the probe operation and the editor UI lives in the `MAD`
framework, pure Foundation, no UIKit — so it runs in the `MAD` test suite and in the Linux
image. The new files go on `Linux/cmake/MADSources.cmake` and `./Linux/build.sh` stays green.
The probe operation (needs drivers, credentials, UIKit alerts) and the popover UI live in
`MADDesigner/Source`.

**New files.** `MAD/Source/sql/MADSQLTokenizer.{h,m}`, `MADSQLParser.{h,m}`,
`MADSQLStatement.{h,m}` (the tree and its value types: `MADSQLColumnReference`,
`MADSQLPredicateTerm`, …), `MADSQLStatementResolver.{h,m}`, `MADSQLQueryCompiler.{h,m}`,
`MADSQLCompileError.{h,m}`. App: `MADOperationValidateSQL.{h,m}` (mirroring
`MADOperationRefresh`), plus the editor changes in `MADViewControllerSQL` or a sibling
editor controller in the same storyboard seam.

**One small API addition.** The lexer needs each dialect's identifier quoting (MySQL
backticks, T-SQL brackets, double quotes) before a connection exists. Add
`+ (NSString *)identifierQuoteCharacters` to `MADDatabase` (default: double quote), with
per-driver overrides in `MADMySQL`/`MADTdsClient` — or, if preferred, a class method on the
driver protocol resolved through `MADDatabaseDriverRegistry`. Either way it is a
three-method addition.

## 5. The supported subset

The importer accepts **exactly the language the model can hold** — one `SELECT`, no
subqueries anywhere, and each clause within the limits of §2.1:

* **SELECT list** — column references only: `col`, `tbl.col`, `alias.col`, quoted or bare,
  plus `alias.*`. The list is *validated and used for table/column discovery*, not stored
  (the model has no SELECT list — §2.1): every column must resolve, and a qualified column
  names a table that must appear in `FROM`. Expressions, aggregates, aliases (`AS x`), and
  `DISTINCT` are rejected with a pointer to Phase E (§9), which is the phase that makes the
  pasted column list real by synthesizing designer elements. The entered text itself *is*
  stored, verbatim, in `sqlSourceText` (§8) — validation shape and input text are separate
  things.
* **FROM** — one table reference `name [AS alias]`, then a chain/tree of
  `[INNER] JOIN`, `LEFT [OUTER] JOIN`, `RIGHT [OUTER] JOIN`, `FULL [OUTER] JOIN` each with
  exactly one equi-condition `l.col = r.col` (bare columns allowed when unambiguous).
  * Aliases must be the schema table's own name, or the drop-index form (`name0`, `name1`)
    for a second copy of the same table — the model computes aliases itself and cannot hold
    renames (`Customer AS c` is rejected: "the designer names tables itself").
  * At most one join between a given pair of tables (the generator emits one `JOIN` per
    table pair; two links between the same pair would double the alias).
  * No comma joins, no `NATURAL`/`CROSS` joins (the link model holds exactly one field pair
    and the generator always writes `ON …`), no subqueries in `FROM`/`ON`.
* **WHERE** — a conjunction (AND) of comparisons `left op right`, `op` ∈
  `{ =, <>, >, >=, <, <= }` (the `MADPredicateOperator` set), each side a column reference
  or a literal. Parens are accepted only where they don't change the flat AND shape.
  Everything else — `OR`, `IN`, `BETWEEN`, `LIKE`, `NOT`, functions, subqueries — is
  rejected: the predicate model ANDs flat triples and nothing else.
* **GROUP BY** — column references, imported in order (weight), each becoming a group via
  the `MADocument` helper, which also creates the report's group sections.
* **ORDER BY** — accepted **only when every column is a GROUP BY column**, and the
  asc/desc map onto the groups' sort orders. Otherwise rejected (no free sort in the model).
* **LIMIT** — rejected: the app applies its own designer/reporting-mode limit
  (`MADDocument.limitResultsDesignMode`, `MADQueryFull.limitResults`).

Literals are handled per dialect at generation time (`newSafeLiteral:`,
`MADDatabaseSQLProtocol.h`); the importer only records the value string and the field's data
type, exactly as the predicate UI does (`MADQueryPredicate.m:74-88`).

Rejections are never silent: every one names the construct, the clause, the reason (which
model limitation it hits), and the line:column.

## 6. Resolution and compilation

### 6.1 Resolver

* Alias (or bare table name) → `RptqDatabaseSchemaTable` by name, case-insensitive.
  Unknown → error "unknown table".
* Column → `RptqDatabaseSchemaField`: qualified must exist on its table; bare must be unique
  across the `FROM` set, else "ambiguous column".

### 6.2 The write plan

Resolver output is a value-object plan: ordered table list, join list (`MADLinkType` per
join), predicate list (`MADPredicateOperator` + left/right terms), group list with sort
orders. The plan is validated whole before anything is written.

### 6.3 Conflict check — the apply is atomic

Apply **replaces** the query (the pasted SQL *is* the query — that is the feature). Before
writing, check every table the new plan does **not** include for references from designer
elements — the three shapes `MADQueryActiveQueryFields` knows about
(`MADQueryActiveQueryFields.m:37-68`: label-data, aggregate, barcode references) plus any
group sections that would be deleted. If a field of a dropped table is referenced, abort
with an error naming the elements ("this field is used by … in the designer"); nothing is
deleted, nothing is written, and the old query still runs. This is the one case where the
import cannot be atomic-and-silent, so it fails loudly instead.

### 6.4 Write

In reverse-dependency order using the §2.4 helpers: remove links and predicates, remove
groups (via the existing group-removal path, which detaches their sections and layout
managers), remove tables that are not in the plan (via the existing
`deleteDatafieldsRelatedToTable:` family), then create tables → links → predicates → groups
through the same factories the UI calls. One save; the caller then marks the document dirty
and autosaves, as the add-table flow does (`MADQueryViewController.m:796-799`).

### 6.5 After the write

No UI poking: the store notification path updates the model layer and both query screens
(`MADModel_Layer.md` §3.3). The compiler returns a summary (tables / links / predicates /
groups counts) for the popover.

## 7. Validation — two levels

**Structural (always, offline).** Parse + resolve, §5–§6. Errors are
`MADSQLCompileError`-domain `NSError`s with a code, line, column, and message. This is the
whole feature when the document's database is unreachable.

**Server probe (when a connection can be made).** Wrap the statement:

```sql
SELECT * FROM (<user sql>) AS _mad_probe WHERE 1=0
```

The derived-table alias is mandatory in MySQL and valid in T-SQL; `WHERE 1=0` folds, so the
probe compiles the query and returns column metadata without reading rows. Run it through
the `MADOperationRefresh` shape (`MADOperationRefresh.m:104-162`): connect with credentials
from operation dependencies, store reads marshaled to the main queue, results via the
driver's `executeSQL:…intoResultTable:…` so `MADDataColumn` gives names and types. The probe
then catches what static parsing cannot — server-side name resolution (case sensitivity,
views, reserved words), dialect differences, and the server's own syntax errors, which are
surfaced with the server's message. Column names/types are compared against the resolved
schema fields and mismatches reported as warnings, not failures.

Offline, or when credentials are unavailable, the probe is skipped and the UI says
"validated by structure only."

## 8. The persisted source text — `RptqQuery.sqlSourceText`

The compiled model remains the source of truth for execution, but **the user's pasted text
is part of the document**: a new nullable text attribute `sqlSourceText` on `RptqQuery`
holds the last successfully applied statement, verbatim. Deleting the user's words was never
an option — the document keeps both the input and its compilation. The user chose a single
property over a history array (2026-10-22); a revision history can be added later as an
ordered to-many and backfilled from the current text with no data loss.

Persistence rules:

* Written only by a successful Apply, replaced wholesale; a failed or conflicted apply
  touches neither the store rows nor this text (§3.6).
* The Edit view seeds from it when present; the View tab shows it as **As entered** next to
  **Generated** (§3.2-3.3).

### 8.1 The store change

The attribute lands on both sides of the schema cross-check: the compiled model and the
hand-maintained `MADStoreSchema` descriptors, plus the `RptqQuery` autogen property
(`MAD/Source/rptq/autogen/`). `MAD_FORMAT.md` gains the column in its field list.

**Amended (Phase A, 2026-10-22).** The model change is a **new `MAD 4.xcdatamodel`
version**, not an in-place `MAD 3` edit: a shipped model version's hash pins every
in-the-wild document's store metadata, and editing it orphans them. `MAD 4` also drops
`RptqDocumentElementBarcode.barcodeBorderType`'s dead `elementID="type"` (no pre-`MAD 3`
version has a barcode entity; BUGS.md).

### 8.2 Store versioning — new, small, and now required

The portable store has no versioning today (`MADStore.m` carries no `user_version` pragma).
This phase adds the mechanism, deliberately minimal:

* `MADStoreSchema` gains a version constant and an ordered list of migration steps. Today
  that list has one entry: version 1 (the schema in the wild — `user_version` absent or 0)
  → version 2 (`ALTER TABLE` adding `sqlSourceText`).
* On open, `MADStore` reads `PRAGMA user_version`, applies the missing steps in a
  transaction, and writes the new version. Fresh stores are created at the current version
  (`createSchemaSQL` already generates the whole schema).
* `MADLegacyStoreConversion` is unaffected in flow — converted Core Data documents are
  created at the current version through the same `MADStore` open path.
* The Linux headless engine compiles the same `MADStore` code, so existing documents open
  identically in the image; the migration tests run there too.

**Amended (Phase A, 2026-10-22).** `MADStoreConverter` now opens each legacy store with
the momd version matching its metadata, never via automatic migration: Core Data cannot
infer a mapping for this model family (the barcode `elementID` clash, BUGS.md), and the
momd-current model is no longer the version in-the-wild stores were written against.

### 8.3 Considered and rejected: the guts metadata plist

The metadata plist that rides alongside the store in the guts directory could hold the text
with no schema change at all. Rejected: query data belongs to the query part of the store
(`MADStorePartQuery` — the store's contract is "three parts and nothing else",
`MADStoreSchema.h:12-13`), and the headless engine reads the store, not the plist.

### 8.4 The future this unblocks

The stored entered-text is the natural input surface for the agent-driven query design on
the product's horizon (`MAD_FUTURE.md`): an agent — or a person — writes a statement, the
compiler below turns it into the document, and `sqlSourceText` keeps the prompt of record.
The strict compiled-model architecture is what makes that stepwise: nothing about the
compiler changes when the writer becomes an agent.

## 9. Phases

**Phase A — the persisted source text: store versioning (MAD only; Linux green).**
1. `sqlSourceText` on `RptqQuery`: compiled model + `MADStoreSchema` descriptors + autogen
   property, in one change (the cross-check test fails otherwise).
2. The versioning mechanism of §8.2 — version constant, migration list, `user_version`
   read/apply/write on open, fresh stores at the current version.
3. Tests: `MADStoreSchemaTests` stays green on both sides; new migration tests (§10.2);
   `MAD_FORMAT.md` updated.

Acceptance: a document created before this phase opens cleanly, gains the column, keeps its
data, and round-trips through Linux; a fresh document is born at the current version. This
phase is self-contained — it lands before, and independently of, the parser.

**Phase B — golden tests, then the parser (MAD only; Linux green).**
4. Golden SQL tests pinning `MADQueryFull`'s exact output per dialect (§10.1) — written
   first, so the parser is built against the real generator.
5. `MADSQLTokenizer`/`MADSQLParser`/`MADSQLStatement` + the identifier-quote API (§4).
6. `MADSQLParserTests` — the accept/reject matrix of §5, error codes, line:column.

Acceptance: every supported construct that `MADQueryFull` can emit parses; every rejected
construct fails with a coded, positioned error; MAD suite and `./Linux/build.sh` green.

**Phase C — resolver + compiler (MAD only; Linux green).**
7. `MADSQLStatementResolver`, `MADSQLQueryCompiler` with atomic apply (§6) and the
   `sqlSourceText` write on success (§8).
8. Deletion-helper inventory; add the missing link/predicate removal helpers.
9. `MADSQLQueryCompilerTests` + the fixpoint round-trip test (§10.4).

Acceptance: applying a statement produces exactly the Rptq rows the visual designer would
have, and stores the text verbatim; applying over an existing query leaves no orphans; the
conflict case aborts with the store — and the previous text — untouched; the fixpoint test
passes.

**Phase D — the app (MADDesigner).**
10. The View/Edit popover of §3, `MADOperationValidateSQL` probe, summary view.
11. UI tests (§10.6) using a sample document (sqlite3 driver — no server needed).

Acceptance: paste → validate → apply shows the tables/joins/predicates in the query designer
and visualization, group sections in the report designer, and refresh runs the query; View
shows both the generated SQL and the entered text; closing and reopening the document keeps
the entered text.

**Phase E — deferred, its own decisions.**
* SELECT-list materialization: synthesize designer elements (data labels, aggregates) so
  refresh returns exactly the pasted columns. Until then an imported query behaves like any
  new document — the SELECT derives from elements, links and groups (§2.1).
* A history of applied statements, if ever wanted: an ordered to-many backfilled from the
  current `sqlSourceText` (§8) — the natural companion to the agent-driven query design of
  §8.4.

## 10. Tests

### 10.1 Pinning existing functionality (written first)

* **Golden SQL tests** in `MAD/MADTests` (extending `MADQueryFullTests.m`, which today
  asserts only fragments, `MADQueryFullTests.m:140-162`): fixed store fixtures → exact
  expected SQL strings, per driver dialect (MySQL and TDS configs), covering alias naming
  and the drop-index form, every join type, every predicate operator with literal quoting,
  and the active-field ordering. These pin the generator the parser must round-trip, and
  they run in the Linux image too.
* **The round-trip contract** — see the fixpoint test below; it pins generator ∪ importer
  as one system.

### 10.2 Store persistence and migration tests

* `MADStoreSchemaTests` — the existing cross-check now asserts the descriptors and the
  compiled model agree on `sqlSourceText` (it is the test that forces the two sides of
  §8.1 to land together).
* New `MADStoreMigrationTests` (MAD): build an on-disk store at version 1 (the schema as it
  is today, `user_version` absent) with rows in it → open with the new `MADStore` → the
  column exists, `user_version` reads the current version, and every pre-existing row and
  relationship survives; a fresh store is created at the current version; opening twice is
  idempotent. These run in the Linux image too, since the headless engine shares the
  migration code.
* Compiler-level assertions (in §10.4): a successful apply stores the text **verbatim** —
  comments, whitespace, casing — and a conflicted apply leaves the previous text untouched.

### 10.3 Parser tests — `MADSQLParserTests` (MAD)

* Lexer: quoted identifiers per dialect, string literals with escaped quotes, comments
  (`--`, `/* */`), numbers, operators, keywords case-insensitive; positions on errors.
* Parser: the full §5 accept matrix (single table, each join type, join chains, aliases
  including drop-index, bare and qualified columns, WHERE conjunctions, GROUP BY,
  ORDER BY ⊆ GROUP BY) and the rejection table (OR, IN, LIKE, subquery, UNION, DISTINCT,
  expressions in SELECT, multi-condition ON, alias renames, comma joins, NATURAL/CROSS,
  LIMIT, unknown table/column, ambiguous column, ORDER BY outside GROUP BY) — each asserting
  the error **code** and line:column, never just the message.

### 10.4 Compiler tests — `MADSQLQueryCompilerTests` (MAD)

In-memory store with a schema fixture (the pattern `MADModelQueryTableTests` uses):

* Happy path: apply → assert the resulting Rptq rows — tables with correct schema refs and
  per-field rows, links with correct `MADLinkType` and left/right fields, predicates with
  correct `comparson` and value strings, groups with sort/weight **and** the created group
  header/footer sections and layout managers; saved once; `sqlSourceText` equals the input
  statement exactly (comments and whitespace included).
* Replace path: apply over a populated query → old tables/links/predicates/groups gone, no
  orphan rows (count by entity), new structure present, and `sqlSourceText` replaced.
* Conflict path: designer element referencing a dropped table's field → error, and a
  before/after snapshot shows the store unchanged — including the previous `sqlSourceText`.
* **Fixpoint round-trip**: build a model through the factories → generate SQL via
  `MADQueryFull` → parse → compile into a fresh store → generate SQL again → the two SQL
  strings are equal. This is the test that *defines* "the software recognizes what was
  pasted."

### 10.5 Validation tests

* Probe SQL construction per driver (unit, in the app's test target): the wrapper, the
  alias, the `WHERE 1=0` fold — with a faked database, no server.
* **Live tests** in the `MADMySQLLiveTests.m` style (skip when no server): valid pasted SQL
  probes clean with the expected column names/types; a bad column returns the server's
  error; zero rows are read.

### 10.6 UI tests — `MADDesignerUITests`

With a sample `.mad` (sqlite3 driver): open the SQL popover, switch to Edit, paste a
two-table join with a filter and a group, Apply, then assert the query tables list shows
both tables, the visualization canvas shows two boxes and a connector, the designer shows
the group sections, and View mode shows the regenerated SQL. Then close and reopen the
document: the **As entered** tab still shows the exact pasted text, and the **Generated**
tab still shows the compiled query's SQL — the document kept both.

### 10.7 Design-for-test constraints (binding on implementers)

* Parser/resolver/compiler: pure Foundation, no UIKit, no app imports — MAD suites and the
  Linux image compile them.
* Every public failure is a coded `NSError` (`MADSQLCompileError`); tests assert codes.
* The probe goes behind a small protocol so unit tests fake the database; live coverage
  lives only in the live suites (the existing pattern).
* The compiler takes the document/context, never a view controller; the app passes nothing
  UI-shaped.
* New MAD files are added to `Linux/cmake/MADSources.cmake`; `./Linux/build.sh` stays green.
* The migration mechanism lives in shared `MADStore` code with a version constant tests can
  reference — never in Apple-only paths — so the Linux suites exercise it.

## 11. Decisions — resolved with the user (2026-10-22)

1. **Strict subset.** Confirmed: anything the model cannot hold is rejected with a reason
   (§5). No opaque-SQL fallback.
2. **Apply replaces the query** (atomic, §6.3). Confirmed.
3. **GROUP BY import creates the report's group sections** automatically — the existing
   `MADocument` helper does this, and it stays exactly as it is. Confirmed.
4. **The SELECT list is validated, not stored, until Phase E** — until element synthesis
   exists, an imported query returns join/group columns on refresh until the user adds
   elements, exactly like any new document. Confirmed as phased.
5. **The pasted text is persisted.** Confirmed — `sqlSourceText` on `RptqQuery`, a single
   property holding the last successfully applied statement (§8), shown as **As entered**
   beside **Generated**. The generated form remains what refresh executes; nothing about
   the text being stored changes execution. A history array was considered and set aside
   (§8, Phase E).
