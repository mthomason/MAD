# TODO — Product Roadmap & Wishlist

The author's product wishlist and strategic roadmap. Active engineering tasks are tracked in [`TASKS.md`](TASKS.md), open defects are pinned in [`BUGS.md`](BUGS.md), and the architectural designs live in [`MAD_DATA_OBJECT.md`](MAD_DATA_OBJECT.md) and [`MAD_FUTURE.md`](MAD_FUTURE.md). Entries here are picked up when asked for.

## 1. The Data Object & Composable Tables (`.mad` as a Table)

A database exposes base tables (`employee`, `sales_data`); a `.mad` report joins, filters, and shapes multiple tables into a materialized SQLite result table (`.maddb` + `.mdcache`). The next architectural leap is making that output a first-class, addressable table:

* **Reports as virtual / materialized database tables** — Give every query definition a stable identity and schema contract (`MADDataObjectSchema` / `MADDataObjectExecuting`, see [`MAD_DATA_OBJECT.md`](MAD_DATA_OBJECT.md)) so a `.mad` report's output can be queried (`SELECT` / `JOIN`) just like a base table in a database.
* **Multiple data sources in a single report** — Allow one `.mad` document to define queries against multiple databases (e.g., PostgreSQL + SQL Server + MySQL), materialize each into local SQLite tables (`MADDataTableFast`), and join them together in the query designer with no external federation server.
* **Composable subreports & semantic DAGs** — Link `.mad` reports inside other `.mad` reports as upstream table sources, forming a portable, dependency-ordered DAG of derived tables (`mad run`).
* **Named, shareable data snapshots** — Package `.maddb` + `.mdcache` as an addressable, versioned snapshot artifact that can travel offline without database credentials and answer point-in-time audit questions.

## 2. Legacy Report Migration & Interoperability

* **Crystal Reports (`.rpt`) converter / importer** — Parse legacy Crystal Reports `.rpt` files and convert their database schemas, table links, formulas/predicates, and banded section layouts (Report/Page/Group Headers & Footers, Detail) into open `.mad` documents.
* **Additional legacy report importers** — Support importing other entrenched enterprise report definitions (e.g., SSRS `.rdl` / JasperReports `.jrxml`) into `.mad`.
* **Schema-only describe path** — Derive a report's output `MADDataColumn` schema directly from the query graph and stored schema snapshot without requiring a live database execution (also closing the zero-row SQLite schema gap).

## 3. Beyond the Paper Paradigm: Native UI & Presentation Views

Printing on paper (paginated bands) should be just one paradigm for viewing a `.mad` document. Because the layout is parametric and the row cache lives in local SQLite on the device, the same definition should power rich native UI:

* **Native UIKit data views for non-print exploration** — Render a report's layout and underlying `.maddb` data as interactive, native UIKit collection/table components when viewing on device rather than only as fixed-size paper pages.
* **Interactive raw-data & sample-table explorer** — Complete the sample-table / raw-data display with paged/virtualized queries over `.maddb` to browse, sort, and inspect unlimited rows interactively.
* **Chart element** — First-class chart document element bound to query groups and aggregates.
* **Dashboard & KPI document types** — The data model already carries a report type; add a multi-tile Dashboard view and reusable KPI query cards alongside paginated reports.
* **Formula elements (`Scrimpter` / expression engine)** — Bring computed formula elements into the designer and renderer (engine choice tracked in [`MAD_SCRIPTING.md`](MAD_SCRIPTING.md) §8).

## 4. AI-Assisted Authoring (Graph-First, Deterministic)

* **Natural-language to query graph & layout** — Let an LLM propose a validated `Rptq` query graph and layout tree grounded in the document's <100 KB schema snapshot, using the engine's parser/validator in a reject-and-repair loop so the model never writes unchecked raw SQL or computes aggregates itself.
* **AI-assisted localizations** — Translate static report labels and metadata across locales.

## 5. Drivers, Export Formats & Headless Engine

* **New database drivers** — Subclass `MADDatabase` for cloud warehouses and APIs (Snowflake, BigQuery, DuckDB, REST/JSON, Salesforce SOQL).
* **Linux headless PDF writer** — Complete the non-UIKit PDF rendering path on Linux (tracked in [`MAD_PDF_LINUX.md`](MAD_PDF_LINUX.md); `html`, `html-flow`, `json`, `json-report`, `csv`, and `text` already ship on both platforms).
* **Rich office export formats** — Native Excel (`.xlsx`), Word (`.docx`), and Rich Text exporters on the `<MADReportExporting>` seam.
* **`ORDER BY` in the visual query builder** — Expose explicit sort ordering in the query designer UI beyond group-driven sort descriptors.
* **Edit database connection information** — Allow re-pointing an existing `.mad` document at a new host/database in the UI (already supported via `--host`/`--port`/`--database` in the `mad` CLI).
* **Optional document encryption** — Encrypt `.mad` archives at rest when requested.

## 6. App, Viewer & UI Polish

* **Stand-alone MAD Viewer app target** — Complete the decoupled Viewer target (`Targets/MADViewer/`) as a lightweight reader and refresher for `.mad` documents and snapshots.
* **Print & page-numbering ergonomics** — Dedicated Print action in MAD Viewer and built-in Page `N of M` element tokens.
* **Background refresh & notifications** — Run long database refreshes in the background and post a local notification on completion.
* **Automatic report thumbnails** — Render and store `thumbnail@2x.png` in `AdditionalContent/` on save/refresh for the file explorer.
* **Designer & Query UI polish** — Borders styled consistently with margin/padding; horizontal scrolling for long generated SQL text; query-visualization graph layout and caching improvements; paging slider hover effect; About popover tint; cloud activity indicator cleanup.
