---
layout: default
---

# The Direction: A Report Is a Table

Updated 2026-10-29. This page states the direction MAD is designed to grow
into. None of the composition or migration machinery described here is built
yet; the design that grounds the data-object model is
[`docs/project/MAD_DATA_OBJECT.md`](https://github.com/mthomason/MAD/blob/master/docs/project/MAD_DATA_OBJECT.md),
the working record is
[`docs/project/MAD_FUTURE.md`](https://github.com/mthomason/MAD/blob/master/docs/project/MAD_FUTURE.md),
and the product wishlist is
[`docs/project/TODO.md`](https://github.com/mthomason/MAD/blob/master/docs/project/TODO.md).

## Where MAD is today

A `.mad` document is a report's *definition*: the schema snapshot, the query
graph (tables, joins, groupings, filters), and the banded layout tree. On
refresh the engine compiles the graph to SQL, reads the rows once, and
materializes them in a companion SQLite cache (`.maddb` + `.mdcache`). The row
data stays outside the document on purpose; the definition stays under 100 KB.

One consequence is easy to miss: **a report is a function from data sources
to a table.** Every driver returns a schema and rows in table form, and a
report's output *is* a schema (`MADDataColumn`) and rows in table form
(`MADDataTableFast`). The engine already treats the two identically.

## Where it is going

Closing the loop between a report's definition and its materialized output
unlocks four capabilities:

### 1. A `.mad` file as an ad hoc database table

In a database, you select from base tables like `employee` or `sales_data`. A
report links multiple tables together, and its output is an ad hoc,
materialized SQLite table. Today nothing can point a query at another report's
output — the result cache exists, but it is keyed by a filename hash rather
than an addressable identity. Making that output addressable means:

> **The result of a report becomes a database table that other reports and
> queries can select from and join against.**

A report built on a report is a DAG of derived tables — a portable semantic
layer where designing a report is also designing a reusable data source.

### 2. Multiple data sources in a single report

Every driver (`MADMySQL`, `MADPostgres`, `MADTdsClient`, `MADSqlite3`)
materializes its result set into the same local SQLite table representation.
Once a document can hold multiple query definitions and address each output as
a table, one report can join a PostgreSQL table to a SQL Server table to a
MySQL table — federated locally in SQLite without a federation server in the
middle. The snapshots *are* the federation.

### 3. Paper as just one paradigm — native UIKit views over raw data

Banded pagination (Report Header, Page Header, Groupings, Detail, Footers) was
invented for printing on paper. Because a `.mad` layout is parametric data and
the `.maddb` row cache is local SQLite on the device, paper pages are only one
way to present a report. When the user is not printing, the same definition
and local cache can render as interactive native UIKit views and raw-data
explorers — layout once, view as paper or as native UI.

### 4. Converting legacy Crystal Reports (`.rpt`) into open `.mad` files

Crystal Reports (`.rpt`) and similar legacy report files remain entrenched
across thousands of enterprises because no open, portable engine shares their
banded-section + relational-query-graph model. Because MAD is built on that
exact structural paradigm — while storing its definitions in an open,
documented SQLite-in-tar format — converting legacy `.rpt` documents into
`.mad` files gives organizations a direct migration path off proprietary
legacy reporting stacks.

## What already exists

The expensive parts are built: portable definitions, deterministic SQL
generation and parsing, a portable materialization format (SQLite), four
database drivers, and one engine that runs natively on iOS/macOS and
headlessly on Linux.

## What this is not

A promise. This page records the direction; the design and the task queue
live in `docs/project/`, and nothing described here ships until it is
designed, tested, and documented the way everything else in the repository
is.
