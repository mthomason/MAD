---
layout: default
title: "Per-node reports — final decision and implementation plan"
description: "Every node in a composite report is a complete report with its own layout and data; this is the final decision, and this file scopes the store, import, serve, and UI work."
---

# Per-node reports — final decision and implementation plan

**Status: decision final; implementation pending.** The normative contract is
[`MAD_COMPOSITION_SPEC.md`](MAD_COMPOSITION_SPEC.md) §0. This file records the decision, the
evidence for the work it requires, and the implementation scope. The presentation direction is
[`MAD_COMPOSITION_UX.md`](MAD_COMPOSITION_UX.md); the execution walk is
[`MAD_COMPOSITION_SPEC.md`](MAD_COMPOSITION_SPEC.md) §3.

## 0. The decision (final, 2026-11-26)

> **Every node in a composite report is a complete report. It owns its query definition, its
> materialized result table, and its own report layout. Combining reports carries each child's
> layout with it. The root is the document's default node, not the only report.**

This is settled. Do not treat per-node layouts as an open design question, and do not describe
the root as the only report or the only viewable result anywhere in the product.

**What a node owns:**

| Piece | Leaf | Composing |
| --- | --- | --- |
| Query definition | its own database, driver, credentials | its child references, joins, filters, groupings |
| Materialized table | yes (already true) | yes (already true) |
| Report layout | yes — its own bands, rows, elements, field bindings | yes — a layout over its output columns |
| View / print / export | yes, as a report | yes, as a report |

**The root is the default.** It is the node the Viewer opens first, the one print and export
use when the user does not choose another, and the one `rootQuery` identifies. It has no other
privilege: any node can be selected, designed, viewed, printed, and exported.

**Why this is the only model that makes sense to users.** A source is a report the user already
understood before it was combined. Reducing it to a table on import silently discards work and
makes the composition pane a query browser instead of a report navigator. Keeping the layout
means "select Payments and see Payments" works in Query, Designer, and Viewer, which is what a
user expects when they click a report's card.

## 1. The current gap (the evidence)

A composition is a graph of queries, but the document has **one layout**. The store keeps five
document-level sections (`hasReportHeaderSection`, `hasPageHeaderSection`,
`hasDetailSection`, `hasPageFooterSection`, `hasReportFooterSection`) plus the Result query's
group sections; every band, row, and element hangs off those document sections, not off a
query. `importQueryGraphFromContext:` copies the query graph and its databases and
**deliberately drops the source's layout bands and elements**. `mad serve`'s `layout-model` and
every layout mutation resolve the root, and `refresh` / `export` materialize and read the root
only.

Until the implementation below lands, selecting a source on Windows moves to Query (the only
workspace that can show it) and Designer/Viewer display an explicit "source layouts are not
available yet" notice. That notice is an interim state and must be removed when this work
lands; it is not the target behavior.

| Layer | Current behavior | File |
| --- | --- | --- |
| Store | one `RptqDocument` owns the five sections; a section may point at a Result query group | `MAD/Source/rptq/store/MADStoreSchema.m` (Layout part) |
| Import | copies the query-graph entities only; layout edges are dropped | `MAD/Source/rptq/store/RptqStoreContext.m` (`importQueryGraphFromContext:`) |
| Serve | `layout-model` and its mutations are document/root scoped | `CLI/Source/MADCLIServe.m` (`MADCLIServeOrderedSections`, `MADCLIServeLayoutModelDict`) |
| Execution | the walk materializes every node; only the root is published for reading | `MAD_COMPOSITION_SPEC.md` §3 |
| Windows | Designer/Viewer load the document layout; Query is query-scoped | `Windows/App/Mad.Designer.Windows/ViewModels/DocumentViewModel.cs` |

## 2. What shipped on Windows (2026-11-26)

- **Composition pane** beside the workspace, with a `GridSplitter`, an Expand/Collapse mode,
  and an Import entry point. It is absent for a Standard Report.
- **Graph**: one card per query, the Result at depth 0, sources below; connectors point at the
  consumer; cards select. Depth is computed from each query's own upstream tables, so nested
  composers and shared children draw correctly.
- **One selection**: the graph and the toolbar's **Component** picker both drive
  `Document.SelectedQueryId`; the Query workspace loads that query's model.
- **Interim routing**: selecting a source moves to Query. Designer and Viewer show the notice
  above until per-node layouts land.
- **Open behavior**: opening a report starts in Query; a newly created standard report starts
  in the Designer; a newly created composition starts in Query.
- **Empty composition**: a root with no sources opens to its "No sources yet — import a
  report" guide. The engine's `connection` endpoint reports the absent source database as an
  error; the client treats that as the expected state rather than a failed open.
- **Terminology**: Outputs → **Columns** (popover: "Report columns"); Sources/Result/Source
  used consistently; the Designer field list reads "Report columns" for a composition.
- **Empty states**: no sources; one source ("Add another source to combine"); the root canvas
  placeholder; the Sources hint; "All sources are added".
- **Localization**: every new string is in the six dictionaries (en, de, es, ja, pt-BR,
  zh-Hans) with matching placeholders.

The pane, graph, picker, and terminology stay. The interim notice and the "source is only
visible in Query" rule are replaced by §3.5.

## 3. Implementation scope

### 3.1 Store: give each node a layout

Add a layout owner to the store. The preferred shape is a per-query layout: a
`layoutOfDocument`-style relationship from `RptqQuery` to its five sections (or an
`ownerQuery` column on `RptqDocumentSection`). Migrate the current document sections onto the
Result query; when a source query is created or imported, create its five sections.

This is a **store revision** (the current schema is revision 3). Use the same transactional,
refuse-a-newer-revision treatment as the earlier migrations. See
[`MAD_STORE_MIGRATION.md`](MAD_STORE_MIGRATION.md).

Acceptance: a document with three nodes has three independent layouts; editing one leaves the
other two unchanged; save/reopen preserves all three.

### 3.2 Import: carry the source's layout

`importQueryGraphFromContext:` copies the source's layout entities as well as its query graph,
remapping every field reference to the imported objects. A source with no layout imports with
an empty layout; the UI then offers to author one. "Query only" is not a product option — that
would reintroduce the data loss this decision rejects.

Acceptance: import a report that has a designed layout; the source's Designer shows that
layout, and the Result's layout is untouched.

### 3.3 Serve: scope layout and schema by query

- `layout-model` gains the optional `query` parameter used by the query-model methods.
- `add-element`, `remove-elements`, `duplicate-elements`, `move-elements`,
  `set-element-geometry`, `set-element-content`, `set-element-typography`,
  `set-element-box-model`, `set-section`, and `set-paper-size` resolve the same query and
  read/write that query's layout.
- Keep the no-`query` behavior as the Result, so existing callers are unchanged.
- `describe` takes the same optional `query`: its `columns` are the selected query's output
  columns and its `tables` are the selected source's schema tables. Today `tables` concatenates
  every database's schema, so a source in a multi-database composition sees its siblings'
  tables and "Add table" can target the wrong database.

### 3.4 Serve: per-node results

The refresh walk already materializes one table per node. Add a query-scoped read of the
materialized table (a row/cache endpoint, or an `export` variant with `query`) returning that
node's output columns and rows.

- The Viewer uses the node's layout when it has one; otherwise it shows a row grid. A node
  with no layout is still a valid report of rows.
- `refresh` may stay whole-document (every node must run for the root anyway); the read is
  what becomes query-scoped.
- A failed node already fails the refresh and leaves the previous complete results untouched;
  the query-scoped read names the node that failed.

### 3.4b Serve JSON contract (Windows client)

The Windows client is the consumer of `mad serve`; this is the query-scoped contract. All
existing members are unchanged; the optional `query` parameter (a `RptqQuery.identifier`) is
added to the layout, describe, result, and export methods. Omitted `query` targets the root
(today's behavior). An unknown or stale `query` answers
`{ "ok": false, "error": { "code": 1, "message": "no query <id> in this document." } }` and
leaves the document unchanged.

- **`layout-model`** + the nine query-scoped mutations (`add-element`, `remove-elements`,
  `duplicate-elements`, `move-elements`, `set-element-geometry`, `set-element-content`,
  `set-element-typography`, `set-element-box-model`, `set-section`) gain optional `query`.
  The response stays the full `LayoutModel` — `{ paperSize, sections[], elements[], fields[] }`
  — for **that query's** layout. A composing node's `fields` are its `outputKey` columns; a
  leaf's are its query fields (no `outputKey` required). `set-paper-size` stays document-level.
- **`describe`** gains optional `query`: `columns` = the selected query's output columns
  (composing → its `outputKey`s; leaf → its field keys/names); `tables` = the selected leaf's
  own schema tables only (a composing node → `[]`). Omitted → today's all-databases `tables`.
- **`query-model`** gains `isComposing` (beside `isRoot`) — true for the root or any query with
  an upstream table; a composing node reports `driver: "sqlite3"` and `sql: ""`. Only
  `validate-sql`/`apply-sql` reject a composing node ("SQL editing is not supported for a
  composed node."). `query` (no param) still succeeds with `""` for a composed document.
- **`node-result`** (new, + optional `query`) reads a node's materialized rows:
  `{ "query": <id>, "name": "...", "rowCount": N, "columns": [{ "key", "name", "table", "type" }],
  "rows": [[ … ]] }`. Omitted/root reads the root's published result; a non-root node reads its
  retained result (error if the node has not been refreshed). `refresh` stays whole-document.
- **`export`** gains optional `query`: the row formats (`json`, `csv`, `text`) read the selected
  node's result; omitted → the root. `engine-info` advertises `node-result` in its `capabilities`.

### 3.5 Windows UI follow-up

- Bind the Designer and Viewer to `Document.SelectedQueryId` instead of the document layout.
- Remove `Composition.WorkspaceNotice` and the "selecting a source moves to Query" rule:
  selecting a node keeps the active workspace and every workspace follows the selection.
- When a source has no layout, show the row grid in the Viewer and a "this source has no report
  layout yet" empty state in the Designer, with an action to start one.
- Add a node status badge in the pane (connected / no rows / failed) once the per-node result
  exists.
- The node-click behavior then matches the chat-document direction: click a source in View and
  see its cached rows without leaving View.

### 3.6 macOS and iOS

The macOS authoring surface (`Mac/Source/MADMacQueryViewController.m`) and iOS use the same
store and serve contracts. The layout-ownership change is engine/store work; each UI then needs
node selection in all three workspaces and a per-node Designer/Viewer. The Mac already has a
query selector and a canvas; it can adopt the same terminology and empty states first.

## 4. Implementation questions (decision settled)

These do not reopen the decision; they are the remaining policy details.

- When a source's output fields change, what happens to that source's layout bindings and to a
  parent's field references? The spec already requires the parent's reference to fail with a
  named error; the source's own layout needs the same policy.
- Should the Result's layout be allowed to reference a source's fields directly, or only the
  Result's declared columns? Today it references Result output fields; keep that rule unless a
  concrete case requires otherwise.
- Is one row-grid Viewer enough for a layout-less source, or does a source need its own page and
  zoom state? Start with the row grid and reuse the Viewer's existing page/zoom state.
- How are per-node paper sizes and print settings stored? They belong to the node's layout; the
  root remains the default print target.

## 5. Acceptance criteria

The decision is implemented when all of these hold:

1. Open a composition; select a leaf in the pane. Designer shows that leaf's layout (or its
   "no layout yet" state) and Viewer shows its cached rows or rendered pages, **without
   leaving the current workspace**.
2. Select the Result; both return to the Result's layout and rows.
3. Edit a leaf's layout, save, close, reopen; the leaf's layout survives and the Result's
   layout is unchanged.
4. Import a report with a layout; the imported source's layout is present and editable.
5. A failed leaf refresh names the leaf and leaves the previous Result result intact.
6. The Windows pane, macOS selector, and iOS surface use the same Result/Source/Columns
   vocabulary in all six languages.
7. The "source layouts are not available yet" notice is gone.
