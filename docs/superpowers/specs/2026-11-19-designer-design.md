# Phase 6c — Designer: design doc

**Date:** 2026-11-19
**Branch:** `windows-engine`
**Status:** design (awaiting approval before build)

## Intent

Make the MAD Designer workspace a working report-layout studio in the WPF shell,
mirroring the Mac's three-pane design, by closing the one real gap: the `mad serve`
protocol cannot read or mutate the report-layout model (`RptqDocumentSection` /
`RptqDocumentElement`) that the Mac edits in-process. This doc records *how* — the
protocol shape, the WPF architecture, and the delivery split. The *what* (palette,
minimap, canvas, inspector, undo) is already fixed by `PHASE6C_DESIGNER.md` and
`WINDOWS_POC_PLAN.md` §4 Phase 6.

## Goals

- `mad serve` gains a report-layout read method plus granular mutations that expose the
  existing engine model — no report-model reimplementation in C#.
- The WPF Designer renders the paper bands and placed elements, and supports
  click-to-add / drag-to-canvas palette, a minimap, a query-fields browser, a selected
  element/section inspector, geometry editing, cross-section moves, and client-side
  undo/redo.
- Acceptance (from the plan and `MADMacSmokeTest` step 5): three resizable panes
  (220pt / canvas / 260pt) that stay put on resize; a minimap wired to the canvas; three
  distinct non-overlapping elements from label + data field + aggregate; X/Y edits persist
  and undo/redo restores geometry; cross-band moves undo/redo; zoom/grid/snap/rulers/guides;
  delete/duplicate; no crashes or UI stalls.

## Non-goals / accepted gaps

- **Barcode** — the Windows engine excludes `MADBarcodes`. The palette shows Barcode
  disabled. No zint.
- **PDF / real image rendering** — the canvas draws bands/elements in WPF. Image elements
  are placeholders (`[Image]`); the engine's image payload is an `NSImage`/`UIImage` that
  does not exist off-Apple.
- **Colour persistence** — `foregroundColor`/`backgroundColor` are AppKit/UIKit colours in
  the engine model and have no portable representation on Windows; the inspector omits the
  colour wells (deferred).
- Localization (6e), Apple/Linux builds, one-shot CLI verbs — untouched. English-only.

## Constraints

- Reuse the engine and protocol; build on `EngineService`/MVVM and the 6b query-model work.
- Undo/redo is **client-side** (WPF has no undo manager).
- Keep the engine change minimal and protocol-shaped; do not reimplement the report model in C#.
- Commit with `-s` to `windows-engine`, keep DCO and Linux verification green, leave PR #32 a draft.

## Approaches

**Chosen — granular mutations (mirrors Phase 6b).** A `layout-model` read returns the full
snapshot; ~10 small mutation methods keyed by store identifier each mutate the `Rptq*`
objects and answer the same snapshot. The client holds the snapshot for display and records
inverse calls for undo. This is the proven 6b pattern and honours "expose the existing model".

**Rejected — coarse get/apply spec.** A single `apply-layout` replacing the whole model
would make the C# client reconstruct the model (closer to reimplementing it) and force the
engine to reconcile object identities on apply. Bigger, riskier, and against the constraint.

## The protocol (extending `mad serve`, §6f)

Every mutation returns the full `layout-model` object, so the client swaps its snapshot
atomically — exactly as the query-model methods do.

### Read

| method | params | result |
|---|---|---|
| `layout-model` | `handle` | `paperSize`, `sections[]`, `elements[]`, `fields[]` |

### Mutations (all take `handle` and answer the full `layout-model`)

| method | extra params | effect |
|---|---|---|
| `add-element` | `kind` (`label`\|`data-field`\|`aggregate`\|`image`\|`line`), `section`, `x`, `y` | create element (default size/content), place at origin |
| `remove-elements` | `elements: [id…]` | remove elements from their rows |
| `duplicate-elements` | `elements: [id…]` | clone each (same kind/content/style/size), offset +16/+12 |
| `move-elements` | `elements: [id…]`, `section` | transfer to target section, keep relative origin |
| `set-element-geometry` | `elements: [{id,x,y,w,h}…]` | set origin + size |
| `set-element-content` | `element`, `content{…}` | type-specific content (label text / data-field binding / aggregate function+scope+field) |
| `set-element-typography` | `elements: [id…]`, `style{fontname,fontsize,bold,italic,underline,strikethrough,hAlign,vAlign}` | bulk typography |
| `set-element-box-model` | `elements: [id…]`, `box{borderTop,borderBottom,borderLeft,borderRight,padding,margin}` | bulk box model |
| `set-section` | `section`, `{height,visible,pageBreak}` | band height/visibility/page-break |
| `set-paper-size` | `paperSize` | `MTPaperType` int16 (Letter 2 / Legal 7 / A4 19) |

### Snapshot shape

- `paperSize`: `MTPaperType` int16.
- `sections[]`: `{ id, type (MADDocumentSectionType int16), title, height (interface height),
  visible, pageBreak, groupField }` — in the engine's canonical order (Report Header, Page
  Header, Group Headers, Detail, Group Footers, Page Footer, Report Footer), the same order
  `MADMacDocument -orderedSections` yields.
- `elements[]`: `{ id, type (MADPrintPageElementType int16), section, x, y, w, h, text, field,
  table, column, aggregateFunction, aggregateScope, aggregateGroup, fontname, fontsize, bold,
  italic, underline, strikethrough, hAlign, vAlign, borderTop, borderBottom, borderLeft,
  borderRight, padding, margin }`.
- `fields[]`: `{ id, name, table, display }` — the query fields (from the main query), so the
  sidebar browser and the binding popup have store identifiers to bind to.

Engine-side, each method calls the same factories/helpers the Mac controller uses
(`newDocumentSectionOfType:`, `addDocumentObject:withDropPoint:managedObjectContext:`,
`setOriginPoint:`, `setSizeWidth:height:`, `moveElement` semantics via row membership,
`setInterfaceHeight:`, `setProducesFormFeed:`), reading the live document through
`[RptqDocument newDocumentReadFromManagedObjectContext: document.storeContext]` so every
mutation is visible to the next read. `add-element` takes an explicit origin; the
*non-overlapping placement* heuristic (the Mac's `nextAvailableOriginInSection:`) is
computed client-side, keeping the engine free of visual layout policy.

## WPF architecture (building on Phase 5/6b)

- **`Models/LayoutModel.cs`** — records + `Parse` for the snapshot (mirrors `QueryModel`).
- **`EngineService`** — `LayoutModelAsync`, `AddElementAsync`, `RemoveElementsAsync`,
  `DuplicateElementsAsync`, `MoveElementsAsync`, `SetElementGeometryAsync`,
  `SetElementContentAsync`, `SetElementTypographyAsync`, `SetElementBoxModelAsync`,
  `SetSectionAsync`, `SetPaperSizeAsync`.
- **`ViewModels/DesignerViewModel.cs`** — owns the `LayoutModel` snapshot, selection
  (section + element set), zoom/grid/snap/ruler state, the non-overlap placement helper, and
  the **undo/redo stack** (a bounded list of inverse-call closures, the WPF counterpart of the
  Mac's `NSUndoManager`). Every mutation goes through the stack and re-applies the snapshot.
- **`Views/DesignerCanvas.cs`** — a WPF `Canvas` drawing the bands and elements (the template
  is `QueryCanvas.cs`), with drag-move, cross-section drag, 8-handle resize, marquee,
  alignment guides, grid/snap, rulers, and inline label editing. Reports geometry commits back
  to the view model.
- **`Views/DesignerMinimap.cs`** — miniature bands/elements + viewport box, wired to the canvas.
- **`Views/DesignerView.xaml`** — replaces the placeholder: top palette bar, `GridSplitter`
  three-pane layout (220pt / canvas / 260pt), left sidebar (minimap + sections outline +
  query-fields browser), right inspector (document/section card + element cards).
- **`DocumentViewModel`** — gains a `Designer` child (`DesignerViewModel`), loaded on open and
  re-read on `apply-connection`, the same way `Query` is.

## Delivery split (two shippable, tested increments)

1. **6c-i — protocol + layout model + canvas rendering.** The ten+one protocol methods, the
   `LayoutModel` parser, `EngineService` additions, `DesignerViewModel` (snapshot + selection +
   placement), `DesignerCanvas` bands/elements rendering, and the three-pane shell. Headless
   tests: a fresh-document protocol round-trip (add three distinct non-overlapping elements →
   edit geometry → move → read back), plus an STA canvas render test (bands/elements draw and
   geometry round-trips) in the existing `Mad.Designer.Windows.Tests` pattern.
2. **6c-ii — palette, sidebar, inspector, undo, interactions.** Palette click/drag, minimap,
   sections outline, query-fields browser (drag + double-click), the full inspector, the
   client-side undo/redo stack, and all canvas interactions (move/resize/marquee/guides/snap/
   zoom/inline-edit/delete/duplicate). Tests: undo/redo restores geometry and cross-section
   moves; delete/duplicate; non-overlap insertion.

Each increment lands as its own DCO-signed commit on `windows-engine`, pushed to `origin`,
with Linux verification and DCO green. Docs (`docs/project/MAD_WINDOWS.md` §6f,
`Windows/README.md`) are updated in 6c-i.

## What's left to the builder

- Exact `MADHorizontalAlignment`/`MADVerticalAlignment` int values (confirm from the headers
  during implementation; the JSON carries the raw int16).
- Font-name→WPF-font mapping (pass the string through; WPF falls back where a name is unknown).
- Undo stack depth / coalescing policy (e.g. coalesce drag commits).
- Whether `duplicate-elements` clones image/barcode placeholders or only the three core kinds
  (label/data-field/aggregate/line — barcode is disabled, image is a placeholder).
