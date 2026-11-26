---
layout: default
title: "Composition node view — remaining work"
description: "What shipped for per-node selection on Windows, and what the engine and store still need before the Designer and Viewer can follow a source node."
---

# Composition node view — remaining work

**Status: design record + backlog.** The Composition pane, node selection, and the Component
picker shipped on Windows (2026-11-26). Selecting a node now updates the **Query** workspace
for that node. The Designer and Viewer still render the document's **Result**; making them
follow a source needs the store and engine work below. The normative execution model is
[`MAD_COMPOSITION_SPEC.md`](MAD_COMPOSITION_SPEC.md); the presentation direction is
[`MAD_COMPOSITION_UX.md`](MAD_COMPOSITION_UX.md).

## 1. The gap, in one paragraph

A composition is a graph of queries, but a document has **one layout**. The store keeps five
document-level sections (`hasReportHeaderSection`, `hasPageHeaderSection`,
`hasDetailSection`, `hasPageFooterSection`, `hasReportFooterSection`) plus the Result query's
group sections; every layout band, row, and element hangs off those document sections, not
off a query. `importQueryGraphFromContext:` copies the query graph and its databases and
**deliberately drops the source's layout bands and elements** (its Pass 2 filters
relationships to the query-graph entity set). `mad serve`'s `layout-model` and every layout
mutation resolve the root query when the document is composed, and `refresh` / `export`
materialize and read the root only. So "select a leaf and see its report" is not a UI
binding that was missed — the leaf has no stored layout and no per-node result endpoint.

Evidence:

| Layer | Current behavior | File |
| --- | --- | --- |
| Store | one `RptqDocument` owns the five sections; a section may point at a Result query group | `MAD/Source/rptq/store/MADStoreSchema.m` (Layout part) |
| Import | copies the query-graph entities only; layout edges are dropped | `MAD/Source/rptq/store/RptqStoreContext.m` (`importQueryGraphFromContext:`) |
| Serve | `layout-model` and its mutations are document/root scoped | `CLI/Source/MADCLIServe.m` (`MADCLIServeOrderedSections`, `MADCLIServeLayoutModelDict`) |
| Execution | the walk materializes every node, but the root is the only published result | `MAD_COMPOSITION_SPEC.md` §3 |
| Windows | Designer/Viewer load the document layout; Query is query-scoped | `Windows/App/Mad.Designer.Windows/ViewModels/DocumentViewModel.cs` |

## 2. What shipped (2026-11-26)

- **Composition pane** beside the workspace, with a `GridSplitter`, an Expand/Collapse mode,
  and an Import entry point. It is absent for a Standard Report.
- **Graph**: one card per query, the Result at depth 0, sources below; connectors point at the
  consumer; cards select. Depth is computed from each query's own upstream tables, so nested
  composers and shared children draw correctly.
- **One selection**: the graph and the toolbar's **Component** picker both drive
  `Document.SelectedQueryId`; the Query workspace loads that query's model.
- **Honest routing**: selecting a source moves to Query (the only workspace that can show a
  source today). The Designer and Viewer show a notice explaining they still show the Result.
- **Open behavior**: opening a report starts in Query; a newly created standard report starts
  in the Designer; a newly created composition starts in Query.
- **Empty composition**: a root with no sources opens to its "No sources yet — import a
  report" guide. The engine's `connection` endpoint reports the absent source database as an
  error; the client now treats that as the expected state rather than a failed open.
- **Terminology**: Outputs → **Columns** (popover: "Report columns"); Sources/Result/Source
  used consistently; the Designer field list reads "Report columns" for a composition.
- **Empty states**: no sources; one source ("Add another source to combine"); the root canvas
  placeholder; the Sources sidebar hint.
- **Localization**: every new string is in the six dictionaries (en, de, es, ja, pt-BR,
  zh-Hans) with matching placeholders.

## 3. Remaining work

### 3.1 Store: give each node a layout

Choose one of:

1. **Per-query layout ownership (preferred).** Add a `layoutOfDocument`-style relationship
   from `RptqQuery` to its five sections (or a `layoutOwner` column on `RptqDocumentSection`),
   migrate the current document sections onto the Result query, and create the same five
   sections when a source query is created or imported. This matches "a node is a report".
2. **Per-document layouts keyed by query.** Keep the sections on `RptqDocument` but add a
   `query` reference so a document holds N layout sets. More rows, same effect; less natural.

Whichever is chosen, this is a **store revision** (the current schema is revision 3) and needs
the same transactional, refuse-a-newer-revision treatment as the earlier migrations. See
[`MAD_STORE_MIGRATION.md`](MAD_STORE_MIGRATION.md).

### 3.2 Import: carry the source's layout

`importQueryGraphFromContext:` should either copy the source's layout entities (and remap
their field references) or the product must state that an imported source starts with an
empty layout. The current behavior is the latter, silently. Copying is the behavior the
composition model implies: "the children start as ordinary reports."

### 3.3 Serve: scope layout by query

- `layout-model` gains the optional `query` parameter used by the query-model methods.
- `add-element`, `remove-elements`, `duplicate-elements`, `move-elements`,
  `set-element-geometry`, `set-element-content`, `set-element-typography`,
  `set-element-box-model`, `set-section`, and `set-paper-size` resolve the same query and
  read/write that query's layout.
- Keep the no-`query` behavior as the Result, so existing callers are unchanged.
- `describe` should optionally report the selected query's output columns, not the document's
  schema, so a source's field list is its own.
- `describe` is currently document-wide: its `tables` member concatenates every database's
  schema. In a composition with several sources, the selected source's sidebar therefore lists
  the other sources' tables too, and "Add table" can target a name that belongs to another
  database. Scope the table list by the selected query's owning database (or add the owning
  database to `document-info` so the client can filter).

### 3.4 Serve: per-node results

The refresh walk already materializes one table per node. To view a source:

- Add a query-scoped read of the materialized table (a row/cache endpoint, or an `export`
  variant with `query`), returning the node's output columns and rows.
- The Viewer uses the node's layout when it has one; otherwise it shows a row grid (the
  chat-document's "cached result" fallback).
- `refresh` may stay whole-document (every node must run for the root anyway); the read is
  what becomes query-scoped.
- A failed node already fails the refresh and leaves the previous root result untouched; the
  query-scoped read should name the node that failed.

### 3.5 Windows UI follow-up

- Bind the Designer and Viewer to `Document.SelectedQueryId` instead of the document layout;
  remove `Composition.WorkspaceNotice`.
- When a source has no layout, show the row grid in the Viewer and a "this source has no
  report layout yet" empty state in the Designer, with an action to start one.
- A node status badge in the pane (connected / no rows / failed) once the per-node result
  exists.
- The node-click behavior then matches the chat document: click a source in View and see its
  cached rows without leaving View.

### 3.6 Apple parity

The macOS authoring surface (`Mac/Source/MADMacQueryViewController.m`) and iOS use the same
store and serve contracts. The layout-ownership change is engine/store work; each UI then
needs a node selector or pane. The Mac already has a query selector and a canvas; it can adopt
the same terminology and empty states first.

## 4. Open questions

- Should an imported source keep its layout verbatim, or should the import offer "query only"
  vs. "query and layout"?
- When a source's output fields change, what happens to the source's layout bindings and to a
  parent's field references? The spec already requires the parent's reference to fail with a
  named error; the source's own layout needs the same policy.
- Should the Result's layout be allowed to reference a source's fields directly, or only the
  Result's declared columns? Today it references Result output fields; keep that rule.
- Is one row-grid Viewer enough for sources, or does a source need its own page/zoom state?

## 5. Acceptance criteria

A node view is complete when all of these hold:

1. Open a composition; select a leaf in the pane. Designer shows that leaf's layout (or its
   "no layout yet" state) and Viewer shows its cached rows or rendered pages.
2. Select the Result; both return to the Result's layout and rows.
3. Edit a leaf's layout, save, close, reopen; the leaf's layout survives and the Result's
   layout is unchanged.
4. Import a report with a layout; the imported source's layout is present and editable (or
   the product decision in §4 is explicitly implemented).
5. A failed leaf refresh names the leaf and leaves the previous Result result intact.
6. The Windows pane, macOS selector, and iOS surface use the same Result/Source/Columns
   vocabulary in all six languages.
