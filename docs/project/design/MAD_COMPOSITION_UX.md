# Composition (container) report UX — design draft

Status: **design draft** — the user-facing shape of a composition report. The normative
*execution* model is [`MAD_COMPOSITION_SPEC.md`](MAD_COMPOSITION_SPEC.md); the implementation
record is [`MAD_QUERY_COMPOSITION.md`](MAD_QUERY_COMPOSITION.md). This file is about how the
feature is *presented*, not how it runs.

## 1. The problem

A Standard Report is legible because it mirrors the iOS app: one query → one table → Designer →
Viewer. A composition report has no familiar shape. The macOS authoring is half-baked and the
Windows surface (built over the last two checkpoints) exposes the pieces — a query selector, a
sources list, an Outputs popover — but never tells the story, and nothing on screen
*persistently* says "you are inside a container".

## 2. Naming

- **Design/internal term:** *container report* — it literally contains other reports.
- **User-facing term:** to be decided. Keep "Composition Report" for continuity (it is already
  used in the UI and the capability record), or rename to *Combined Report* / *Multi-source
  Report*. The important thing is one consistent word, used everywhere.

## 3. The mental model to teach

> A **composition report combines other reports into one.** You bring in existing reports
> ("sources"), each of which produces a single table. You join those tables to build one
> **result** table, choose which result **columns** to show, then design and view that result
> exactly like a Standard Report.

Three verbs: **add sources → join them → pick the columns.**

## 4. The one thing that makes it legible: a persistent "container chrome"

The single biggest gap is that nothing on screen *persistently* indicates a container and shows
its structure. A one-line toolbar label is not enough. Add an always-visible element — a
**node strip** across the top of the content area (above the Query/Designer/Viewer workspaces)
that:

- carries **"container" chrome** (a distinct accent tint or header strip) so you always know
  you are inside one;
- shows the **nodes** — the **Result** plus each **Source** — as chips or small cards;
- draws the **links** between them (the joins), so the graph is visible at a glance;
- **switches the active node** on click and highlights the selected one;
- for a Standard Report this strip is absent (or shows a single "Report" node), so the two
  document types are unmistakably different.

Placement options:

- **Top node strip (recommended):** a horizontal graph strip, Sources left → Result right,
  matching "combine". Always visible across all three workspaces, room to draw links.
- **Left node rail:** a persistent vertical list under the workspace nav; more room for names,
  less graph-like.

Recommend the top strip; it is the natural home for the join visualization and stays put while
you work in Query, Designer or Viewer.

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
5. **Design** — the Designer field list shows exactly those columns.
6. **View / refresh / export / save** — unchanged.

## 7. Per-area UI

- **Document chrome:** the node strip *is* the document-type indicator, so the toolbar badge
  becomes secondary (keep both: a small badge + the strip).
- **Node switching:** the node strip replaces the flat query-selector dropdown (or the two
  coexist — the strip for the graph, the dropdown for keyboard/accessibility).
- **Result canvas:** Source cards show driver + name; join badges get tooltips
  (`Left → Right, Join type`); an empty state when there are no sources.
- **Columns editor:** rename "Outputs" → **Columns**; title "Report columns"; one line of copy.
- **Source canvas:** unchanged from Standard (schema tables, SQL editor, filters/groups), only
  labelled "you are editing a source".
- **Designer/Viewer:** Designer field list already shows the result columns in order; caption
  it "Report columns".

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
| Empty container (no sources) | hint + empty Result canvas; Import/Add-source highlighted |
| One source | Result = that source's columns; hint "add another source to combine" |
| Missing/offline source | refresh error names the source (already); surface it on the source node |
| Join cycle | design-time error names the query (already); show in the status bar |
| Result selected + SQL mode | SQL editor disabled (already); tooltip explains why |

## 10. Done vs proposed

Already functional (previous checkpoints): document-type text, query selector, sources list +
double-click add, Outputs popover (add/name/remove/reorder), query-scoped filters/groups/SQL,
Designer field binding to result columns, save/reopen/refresh/view/export.

Proposed (UX layer — copy, tooltips, labels, and the node strip — no engine change):
1. The persistent **node strip** (container chrome + nodes + links + switching).
2. Document-type badge + tooltip + first-run hint.
3. Rename **Outputs → Columns** with explanatory copy.
4. Tooltips on sources list, join badges, Columns controls, segment toggles.
5. Empty states for the Result canvas and source sidebar.
6. Consistent "source / Result" wording across the six language dictionaries.

## 11. Recommended order

Ship terminology + tooltips + empty states first (pure XAML/localization, low risk), then the
node strip (a small view-model + XAML change), which is the piece that makes the feature
finally legible.
