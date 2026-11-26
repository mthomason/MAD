# Composition (container) report UX — decision and design

Status: **UX decision final.** The user-facing shape of a composition report. The normative
execution and per-node-report model is [`MAD_COMPOSITION_SPEC.md`](MAD_COMPOSITION_SPEC.md)
(especially §0); the implementation record is [`MAD_QUERY_COMPOSITION.md`](MAD_QUERY_COMPOSITION.md);
the per-node layout/viewer scope is [`MAD_COMPOSITION_NODE_VIEW.md`](MAD_COMPOSITION_NODE_VIEW.md).
This file is about how the feature is *presented*, not how it runs.

> **Final decision (2026-11-26): a node is a report.** Every source keeps its layout and its
> data; combining reports does not reduce a source to a table. Selecting a node selects its
> query, its layout, and its rows in **every** workspace. The root is the document's default
> report, not the only report. This is final; see spec §0.
>
> **Windows implementation (2026-11-26).** The persistent chrome shipped as a docked **left
> Composition pane** (the direction in `Composable UI on Windows.md`) rather than the top node
> strip recommended in §4: a `GridSplitter`, an Expand/Collapse mode, one toolbar Component
> picker, a clickable graph whose Result is at depth 0, and the terminology/empty-state/
> localization work below. The pane and the Query-workspace selection are live. The
> Designer/Viewer per-node rendering and the notice that currently explains the gap are
> **pending the engine/store work** in `MAD_COMPOSITION_NODE_VIEW.md`; the notice is temporary
> and must be removed when that lands.

## 1. The problem

A Standard Report is legible because it mirrors the iOS app: one query → one table → Designer →
Viewer. A composition report has no familiar shape. The macOS authoring is half-baked and the
Windows surface (built over the last two checkpoints) exposes the pieces — a query selector, a
sources list, an Outputs popover — but never tells the story, and nothing on screen
*persistently* says "you are inside a container".

## 2. Naming

Final, user-facing terms:

| Concept | Term |
| --- | --- |
| Document type | **Composition Report** |
| A child report brought into the composition | **Source** |
| The document's default report, built from its sources | **Result** |
| A field the Result exposes | **Column** |
| The layout choice in the Query workspace | **Columns** (popover: **Report columns**) |

Do not use "root", "upstream", "output key", "child query", or "subreport" in the UI. Those
are engine/store terms. "Container report" remains the internal design term.

## 3. The mental model to teach

> A **composition report combines other reports into one.** You bring in existing reports
> ("sources"). **Each source is itself a full report:** it keeps its layout and its data.
> You join the sources' result tables to build a new **Result** report, choose which result
> **columns** to show, then design and view that Result exactly like a Standard Report.
> Selecting a source gives you that source's query, layout, and rows again.

Three verbs: **add sources → join them → pick the columns.** The fourth, equally important
verb is **select**: the Composition pane makes any report in the document one click away in
every workspace.

## 4. The one thing that makes it legible: a persistent "container chrome"

The single biggest gap is that nothing on screen *persistently* indicates a container and shows
its structure. A one-line toolbar label is not enough. Add an always-visible **node graph** —
shipped as a docked left pane — that:

- carries **"container" chrome** (a distinct accent tint or header strip) so you always know
  you are inside one;
- shows the **nodes** — the **Result** plus each **Source** — as chips or small cards;
- draws the **links** between them (the joins), so the graph is visible at a glance;
- **switches the active node** on click and highlights the selected one;
- for a Standard Report this strip is absent (or shows a single "Report" node), so the two
  document types are unmistakably different.

Placement options:

- **Top node strip (considered):** a horizontal graph strip, Sources left → Result right,
  matching "combine". Always visible across all three workspaces, room to draw links.
- **Left node rail / pane (chosen):** a persistent vertical graph beside the workspace; more
  room for names and a natural home for per-node status.

**Final placement (2026-11-26):** a docked **left Composition pane** with a `GridSplitter` and
an Expand/Collapse mode, plus a one-line **Component** picker above the workspace. This is what
shipped on Windows. The pane is always available across Query, Designer, and Viewer; the picker
stays visible when the pane collapses. The earlier top-strip recommendation is retained below
as design history.

## 5. The "data source" view must show multiple linked sources

When the user is on the Result, the canvas must read as *"multiple data sources joined
together"*, not "a table". Concretely:

- each Source card shows its **connection/database** (a small driver icon + name), so it is
  clear these are separate data sources;
- the join links between cards are labelled with the join type and the linked fields;
- a caption explains, in plain language, that these sources are joined into one result
  (engine detail: SQLite `ATTACH DATABASE` stays out of the UI).

This is the moment the user understands "multiple reports, multiple data sources, linked
together".

## 6. The workflow (happy path)

1. **New Composition… / Import…** — opens with the container chrome visible and an empty-state
   hint (*"Import reports to combine."*).
2. **Add sources** — import `.mad` reports (or connect to a database); each becomes a node.
3. **Join them** — on the Result canvas, drag field-to-field; a labelled join link appears;
   change the join type at the link's badge.
4. **Pick the columns** — open **Columns** (today's "Outputs" popover); choose/name/order the
   result columns.
5. **Design** — the Result's Designer field list shows exactly those columns.
6. **Select any node** — the pane and the Component picker switch Query, Designer, and Viewer
   to that report. A source shows its own layout and rows; it is not reduced to a table.
7. **View / refresh / export / save** — unchanged. The selected node is what the Viewer,
   print, and export show, defaulting to the Result.

## 7. Per-area UI

- **Document chrome:** the Composition pane and the document-type badge together frame the
  document. The badge says "Composition Report"; the pane shows its structure.
- **Node switching:** the pane's graph and the toolbar **Component** picker share one selection.
  The picker stays when the pane collapses. The graph is the visual navigation; the picker is
  the compact/keyboard one.
- **Result canvas:** Source cards show driver + name; join badges get tooltips
  (`Left → Right, Join type`); an empty state when there are no sources; the Sources list
  shows only sources not yet joined and says when all are added.
- **Columns editor:** "Outputs" → **Columns**; title **Report columns**; one line of copy.
- **Source canvas:** in Query, unchanged from a Standard Report (that source's schema tables,
  SQL editor, filters/groups). Each source has **its own Designer and Viewer**; selecting it
  shows that source's layout and rows.
- **Designer/Viewer:** every node is a report. The Designer edits the selected node's layout;
  the field list shows that node's columns, captioned "Report columns" for a Result and its
  own output fields for a source. The Viewer renders the selected node; a layout-less source
  shows a row grid.
- **Root/Result:** the Result is visually distinct (accent) and is the default when the
  document opens; it is never the only option.

## 8. WPF expressiveness opportunities

WPF can make this feel like a real graph rather than a list:

- lift the Query canvas's cubic-bezier join rendering into the node strip (animated on hover);
- accent-tinted **container chrome** (header strip + badge) that visually "frames" the document;
- per-node **badges** — a driver icon for sources, a row count once refreshed, a "columns"
  callout on the Result;
- the Result node visually distinct (larger / accent) from the Source nodes;
- light/dark/high-contrast all fall out of the existing Fluent dynamic resources.

## 9. States and edge cases

| State | Presentation |
|---|---|
| Empty container (no sources) | hint + empty-state Import action; the Result canvas explains how to begin |
| One source | Result = that source's columns; hint "add another source to combine" |
| Source selected | Query shows that source's query; Designer shows its layout; Viewer shows its rows/pages. No notice, no forced workspace switch |
| Source has no layout | the Viewer shows a row grid; the Designer offers to author a layout |
| Missing/offline source | refresh error names the source (already); surface it on the source node |
| Join cycle | design-time error names the query (already); show in the status bar |
| Result selected + SQL mode | SQL editor disabled (already); tooltip explains why |

## 10. Shipped vs remaining

Shipped on Windows (2026-11-26): the docked Composition pane, clickable graph, Expand/Collapse,
one Component picker, document-type badge/tooltip, Outputs → Columns with explanatory copy,
composition empty states, the one-source hint, the Designer "Report columns" caption,
consistent Result/Source wording in all six dictionaries, and Query-on-open.

Remaining (the node-as-report decision): per-node layouts and data reads in the store, import,
serve, and all three workspaces. Scoped in
[`MAD_COMPOSITION_NODE_VIEW.md`](MAD_COMPOSITION_NODE_VIEW.md). The interim "source layouts are
not available yet" notice and the forced switch to Query are removed when that lands.

## 11. Order

The terminology, empty states, pane, and picker are complete. Next is the engine/store work in
`MAD_COMPOSITION_NODE_VIEW.md` §3, then the Windows/macOS/iOS follow-up in §3.5–§3.6.
