---
layout: default
---

# The Direction: A Report Is a Table

Written 2026-10-26. This page states the direction MAD is designed to grow
into. None of the composition machinery described here is built yet; the
design that grounds it is
[`docs/project/MAD_DATA_OBJECT.md`](https://github.com/mthomason/MAD/blob/master/docs/project/MAD_DATA_OBJECT.md),
and the working record is
[`docs/project/MAD_FUTURE.md`](https://github.com/mthomason/MAD/blob/master/docs/project/MAD_FUTURE.md).

## Where MAD is today

A `.mad` document is a report's *definition*: the schema snapshot, the query
graph (tables, joins, groupings, filters), and the layout tree. On refresh
the engine compiles the graph to SQL, reads the rows once, and materializes
them in a companion cache. The row data stays outside the document on
purpose; the definition stays under 100 KB.

One consequence is easy to miss: **a report is a function from data sources
to a table.** Every driver returns a schema and rows in table form, and a
report's output *is* a schema and rows in table form. The engine already
treats the two identically.

## The direction

Today nothing can point a query at another report's output -- the result
cache exists, but it is not addressable. The direction is to make it
addressable:

> **The result of a report becomes a data source that other reports can
> query.**

Closing that loop changes what a `.mad` is:

* **One document, several databases.** A report can join a MySQL table to a
  SQL Server table to a snapshot of last quarter's numbers -- because every
  report it references contributes a table, and the engine speaks table for
  all of them. No federation server in the middle: the snapshots *are* the
  federation.
* **Reports compose.** A report built on a report built on a report is a
  graph of derived tables -- a semantic layer. Designing a report becomes
  designing a new, custom data source, and the `.mad` file is its portable
  definition.
* **The output travels on its own.** A report's result, as a named
  snapshot, is shareable without credentials, auditable ("what did this
  report show the day Q3 closed?"), and usable offline -- the thing that
  moves when the database cannot.

## What already exists

The expensive parts are built: portable definitions, deterministic SQL
generation, a portable materialization format (SQLite), and one engine that
runs on iOS, macOS, and Linux. The missing piece is addressing -- naming a
report's result so another report's query graph can point at it. That is a
design decision about the document format, not a rewrite.

## What this is not

A promise. This page records the direction; the design and the task queue
live in `docs/project/`, and nothing described here ships until it is
designed, tested, and documented the way everything else in the repository
is.
