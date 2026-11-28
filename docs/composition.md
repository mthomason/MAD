---
layout: default
title: "Composition Reports"
description: >-
  Combine reports from several databases into one portable .mad document: each source keeps its query, layout, and data, and the Result joins them into a new report.
---

# Composition Reports

A **Composition Report** combines other reports into one `.mad` document. Each report
you bring in is a **Source**; the document's default report is the **Result**, which
joins the sources' result tables into a new report of its own.

Composition is how a single portable document spans several databases — MySQL,
PostgreSQL, SQL Server, and SQLite — without a federation server in the middle. The
sources are brought into the document **with their layouts**; combining them does not
flatten a source to a table. Every member of a composition is a complete report.

> **Platforms:** Composition Reports are available in **MAD Designer for macOS** (0.8)
> and **MAD Designer for Windows** (0.8). The iOS app does not author compositions yet;
> this page describes the desktop applications.


## The mental model

> A composition report combines other reports into one. You bring in existing reports
> (**sources**), join their result tables to build a new **Result** report, choose which
> result **columns** to show, then design and view that Result exactly like a standard
> report. Selecting a source gives you that source's query, layout, and rows again.

Four verbs cover the workflow: **add sources → join them → pick the columns → select**.

| Term | What it means |
|---|---|
| **Composition Report** | A `.mad` document that holds a graph of reports: the Result plus its sources. |
| **Result** | The document's default report. It joins the sources' materialized tables and is what opens first, prints by default, and exports by default. |
| **Source** | A child report brought into the composition. It keeps its own query, database connection, layout, and rows. |
| **Report columns** | The fields the Result exposes to its own layout and to its parents. Edited in the Query workspace (the **Outputs…** item on macOS, **Columns** on Windows). |
| **Layout-less source** | A source whose report has no elements yet. The Designer offers to author a layout; the Viewer shows its rows as a table. |

### Every member is a report

This is the rule that makes the feature legible. A source is not reduced to a table
when it is imported: its query definition, its own report layout, and its data all come
along, and they are saved in the same `.mad` document. Rows stay in companion storage
(the `.maddb` and `.mdcache` files beside the document), not inside the `.mad`.

Selecting a source in the **Report** picker (macOS) or the **Component** picker and
Composition pane (Windows) switches **all three workspaces** — Query, Designer, and
Viewer — to that source. A layout-less source is still a valid report: the Viewer shows
its cached rows in a grid rather than a page.



## Creating a composition

### macOS

* **File ▸ New Document…** offers **Standard Report** and **Composition Report**.
  Choosing Composition Report asks you to pick one or more existing `.mad` reports, then
  where to save the new composition.
* **File ▸ New Composition…** is the direct command for the same flow.
* **File ▸ Convert to Composition…** turns the open standard report into a one-source
  composition, keeping its layout.
* In the **MAD Query** workspace, the Add menu adds a table, a **source query** from a
  new database connection, an **imported report**, or the composed **root query**.

The toolbar's **Report** picker lists the **Result** first (marked *Result — <name>*)
and then each source. Selecting an item never changes the active workspace; it changes
which report that workspace is showing.

### Windows

* **File ▸ New Composition…** creates a composition from existing reports.
* **File ▸ Import…** adds a report as a source of the open composition.
* **File ▸ Convert to Composition** turns the open standard report into a composition.

A docked **Composition** pane sits beside the workspace (absent for a standard report).
Its graph shows the Result at depth 0 and its sources below, with connectors pointing at
the consumer. The pane and the toolbar's **Component** picker share one selection; the
pane can collapse, and the picker remains.

## Joining sources and choosing columns

On the Result's canvas, drag a field from one source card to a field in another to create
a join, then click the join badge to change its type (`INNER`, `LEFT OUTER`,
`RIGHT OUTER`, `FULL OUTER`, `CROSS`) or reverse its direction. The Result is a normal
query: it can join any number of sources, filter, group, and sort.

A source that is itself a composition joins the graph with its own sources; the parent
references that composition's Result. A composing node references only its children —
never a remote table — so each leaf runs against its own database and every joining step
runs locally in SQLite.

Use the Result's **Report columns** editor to choose, name, and order the fields the
Result exposes. The Result's Designer field list is exactly that set. A source exposes
its own query fields.

## Refreshing, credentials, and privacy

Refresh runs the graph **children first, the Result last**. Each leaf executes against
its own database with its own credentials; each composing report runs locally over its
children's materialized tables. Every node materializes its own table, and a failed node
fails the refresh while leaving the previous complete results readable.

A multi-source composition therefore asks for **one credential per source**, one sheet at
a time, with the driver, host, port, database, and non-secret username already filled in.
Passwords are never stored in the `.mad` file: macOS keeps them in the Keychain (or the
current session), and Windows keeps them in the session or the platform credential store.
A SQLite source needs no credential.

## Samples

Two runnable compositions are in [`Samples/Reports`](https://github.com/mthomason/MAD/tree/master/Samples/Reports):

* **`Chinook-Composition.mad`** — two SQLite sources (an Albums report with its own
  layout and an Artists report with none) joined into a Result. It needs nothing beyond
  the bundled `chinook.sqlite3`.
* **`Composition-MySQL-PostgreSQL-SQLServer.mad`** — one small table from MySQL,
  PostgreSQL, and SQL Server joined on `demo_id`, demonstrating a single document that
  spans three databases.

Stand up the three live servers and seed the cross-database table with one idempotent
script (macOS, Linux, and Git Bash on Windows):

```sh
./Samples/setup-databases.sh up
```

On Windows PowerShell:

```powershell
.\Samples\setup-databases.ps1 -Action up
```

`up` creates or starts the pinned containers through the test-database scripts and loads
the `composition_demo` table into each server. `status` reports the containers and row
counts; `down` stops them. The same SQL can be printed without Docker with
`./Samples/setup-databases.sh sql`. See [the samples guide](https://github.com/mthomason/MAD/blob/master/Samples/README.md)
for the first-run walkthrough, including the per-source password prompts.

## Current limits

* **Same document only.** Every source's definition and layout lives inside the one
  `.mad` file. Referencing a report in a different file is not supported.
* **Up to ten direct children per composing report.** The engine's SQLite build allows
  ten attached databases; the Designer rejects an eleventh child.
* **Nested compositions are read-only in the Query workspace.** A source that is itself
  a composition shows the sources it joins, but authoring a nested composer directly is
  a later piece of work.
* **`json-report` exports the Result only.** Every other export format exports the
  selected report.

## Related

* [MAD Designer for macOS](macos.html) — the native AppKit application.
* [MAD Designer for Windows](windows.html) — the native WPF application.
* [The direction](vision.html) — reports as composable data sources.
* [The data object](developers/data-object.html) — a report's definition, schema, and
  result set as one contract.
* [Multi-source reports](developers/multi-source.html) — the architecture behind
  same-document composition.
