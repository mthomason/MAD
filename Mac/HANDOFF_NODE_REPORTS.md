# macOS composition slice — every node is a report

You are the macOS implementation agent for MAD Designer's AppKit app. Read this whole
file, then the referenced documents, then produce a plan and **stop for approval**. Do
not edit anything until the user approves the plan.

This is an implementation handoff, not a normative design document; fold anything durable
into `docs/project/design/` and delete this file when the slice lands.

## Where you are

- Repository: the MAD checkout on this Mac, on branch `feat/composition-engine-n-node`
  at `7ca328dca` (the integration branch).
- That branch already contains the engine work (query-scoped layouts/results, the
  node-aware page walk) and the Windows WPF slice. **Do not change engine, store,
  import, or serve code** unless you find a real gap; if you do, stop and report — an
  engine fix belongs on the integration branch, not in this slice.
- AppKit app: `Mac/Source` (programmatic AppKit; no storyboards for these views).
- Smoke suite: `Mac/Tests/MADMacSmokeTest.m`.
- Build: `./Mac/build.sh --smoke-test` (frameworks + app + smoke suite);
  `./Mac/build.sh --no-frameworks` for fast app-only iteration.
- Strings: `MADDesigner/Resources/Localizable.xcstrings` (en, de, es, ja, pt-BR,
  zh-Hans; 796 keys at the time of writing).

## Mission

Every node in a composition is a first-class report in the macOS app:

- Selecting a node (the Result or any source) keeps the active workspace and updates
  **Query**, **Designer**, and **Viewer** to that node.
- The Designer shows and edits **that node's own layout**.
- The Viewer renders **that node's report**; a node with no layout shows a **row grid**.
- The Result is the document's default report. A Standard Report behaves exactly as
  today.
- No forced workspace switch and no "source layouts are not available yet" notice.

The normative decision is `docs/project/design/MAD_COMPOSITION_SPEC.md` §0. Do not
reopen it. The presentation direction is `MAD_COMPOSITION_UX.md`; the engine contract is
`MAD_COMPOSITION_NODE_VIEW.md` §3.3–3.4b and §3.6 (macOS/iOS).

## Read first

1. `docs/project/design/MAD_COMPOSITION_SPEC.md` — §0 (final decision) and §3.
2. `docs/project/design/MAD_COMPOSITION_NODE_VIEW.md` — §3.3–3.4b (engine/serve
   contract) and §3.6 (macOS).
3. `docs/project/design/MAD_COMPOSITION_UX.md` — the vocabulary and states.
4. `docs/project/design/MAD_QUERY_COMPOSITION.md` — the 2026-11-26 decision and
   Checkpoint K.
5. `AGENTS.md` and the `mad-verify` skill.
6. The Mac code:
   - `Mac/Source/MADMacDocument.{h,m}` — the document/selection/refresh/export model.
   - `Mac/Source/MADMacWindowController.{h,m}` — three workspaces, toolbar, notifications.
   - `Mac/Source/MADMacQueryViewController.m` — the existing query selector popup.
   - `Mac/Source/MADMacDesignerViewController.{h,m}` — the Designer shell, section table,
     field list, inspector.
   - `Mac/Source/MADMacDesignerCanvasView.{h,m}` — the canvas; sections come from
     `[document orderedSections]`.
   - `Mac/Source/MADMacViewerViewController.{h,m}` — the PDFView preview, refresh, export.
   - `Mac/Tests/MADMacSmokeTest.m` — the composed fixture and end-to-end checks.
7. The Windows slice as a **behavioural** reference (not code to port):
   `Windows/App/Mad.Designer.Windows/ViewModels/{DocumentViewModel,QueryViewModel,DesignerViewModel,ViewerViewModel}.cs`
   and `Engine/EngineService.cs` at `7ca328dca`. The Windows tests
   `CompositionNodeReportsTests.cs` enumerate the behaviours to match.

## What already exists on the Mac

- `MADMacDocument` has `isComposed`, `rootQuery`, `reportQuery` (root, or the single
  query), `allQueries` (root first, then sources), `selectedQuery` (defaults to
  `reportQuery`), `orderedSections`, `sectionsLayout`, `designerLayout`, and the
  headless document (`headlessDocument`). `refreshDataWithPassword:` runs the composed
  refresh, which materializes **every** node's result. `exportToURL:format:error:`
  currently exports the report root.
- `MADMacQueryViewController` already has a query popup; `querySelectorChanged:` sets
  `_document.selectedQuery` and reloads only the Query workspace.
- `MADMacDesignerViewController` / `MADMacDesignerCanvasView` take their bands from
  `[document orderedSections]`, which today always returns the **document/root**
  sections. The field list is root-scoped (`doc.isComposed` → the root's output fields;
  otherwise `doc.rptqQuery` fields).
- `MADMacViewerViewController` renders a PDF from `document.headlessDocument` with
  `exportDocument:toURL:` and reads the root's `dataTable`; it observes the mutate and
  refresh notifications and reloads.
- `MADMacWindowController` owns the three workspace tabs and reloads Query/Designer on
  `MADMacDocumentDidMutateNotification`. There is no node picker outside Query and no
  shared selection notification.
- The Mac app uses the frameworks in-process; it does **not** use `mad serve`.

## The engine API to use

All of these are already on the integration branch.

- **Selection classification:** `-[RptqQuery isComposing]` (upstream-table based) and
  `-[RptqQuery isLayoutRootInDocument:]`. `reportQuery` is the layout/result root: the
  explicit composed root, or a Standard Report's single query.
- **Ordered bands:** `-[RptqQuery orderedLayoutSectionsForDocument:]` returns the five
  structural bands plus that query's group bands in render order. For the layout root
  it returns the document's sections (parity); for a non-root it reads
  `hasLayoutSections` and the query's own groups. This is the method the serve
  `layout-model` uses.
- **Legacy leaf bands:** `-[RptqQuery ensureStructuralSectionsInContext:]` creates the
  five empty bands for a non-root query that has none (the same lazy step serve's
  `layout-model` performs). Call it when a legacy leaf is selected, then reload.
- **Per-node results:** `headlessDocument.nodeResults[@(query.identifier)]` is the
  `MADDataResult` retained by the last composed refresh. The refresh stays
  whole-document; the read is per node.
- **Per-node render:** the exporters implement
  `exportDocument:query:toURL:options:error:`. Pass the node query; the exporter sets
  `renderQueryIdentifier`, pins the node result, and restores both afterwards. `pdf`,
  `html`, `html-flow`, `csv`, `json`, and `text` are node-scoped. `json-report` is
  **root-only** and errors for a non-root — do not offer it for a source.
- **Apple print walk:** `MAD/Source/MADPrintPageRenderer.m` received the node-aware
  section substitution in `089f8c12a` but has never been compiled. The first build is
  its gate.

## Work items

### 1. Selection model

- Make `MADMacDocument.selectedQuery` the single selection for all three workspaces.
  It already defaults to `reportQuery`; keep `reportQuery`/`rptqQuery` as the
  root/single query (refresh and credentials use them).
- Add a selection notification (e.g. `MADMacDocumentDidSelectQueryNotification`, or KVO
  on `selectedQuery`) posted by the setter. Do not treat selection as a document
  mutation (it must not mark the document dirty or save).
- The Query popup's `querySelectorChanged:` and the new shared node picker both set the
  same property. Keep the two controls in sync.
- Selecting a node must never change the active workspace.

### 2. Shared node picker

- Add a native `NSPopUpButton` node picker to the window toolbar, visible only for a
  composition. Items: the Result first, then each source (`allQueries` is already root
  first); mark the Result (e.g. "Result — <name>") so its role stays visible.
- The Query workspace's existing popup stays; it reflects the same selection.
- Optional if time permits: a small `NSTableView`/`NSOutlineView` list in a sidebar
  showing Result + sources with indentation. Do not build a graph; a list/popup is the
  native Mac shape. Do not block the slice on it.

### 3. Query workspace

- It already edits `selectedQuery`; make the composer/leaf rules explicit, matching
  Windows:
  - the root and any composing node: SQL editing disabled; no "Add table"; the root
    keeps its Sources/Columns authoring; a composing non-root shows its upstream
    tables read-only for structure and a short "this source is itself a composition"
    note;
  - a leaf: its own schema tables and "Add table", SQL, filters, groupings, as today;
  - a Standard Report's single query is a leaf and behaves exactly as today.
- The existing Query workspace may already do most of this; verify rather than rewrite.

### 4. Designer — per node

- `-[MADMacDocument orderedSections]` must return the **selected** query's bands:
  return `[self.selectedQuery orderedLayoutSectionsForDocument:self.rptqDocument]`.
  That single change makes the canvas, section table, inspector, and drag/drop follow
  the selection while preserving the root/Standard Report path.
- When selecting a non-root query with no structural bands, call
  `[query ensureStructuralSectionsInContext:context]`, rebuild `sectionsLayout`, and
  reload. The document may need marking dirty if bands were created (persist the way
  `notifyDocumentMutated` does, without firing the node-selection reload loop).
- Rebuild `sectionsLayout` against the selected query
  (`initWithManagedObjectContext:databaseClass:queryIdentifier:`) wherever its heights
  or ordering are used; audit for document-only section assumptions
  (`hasReportHeaderSection`, `hasDetailSection`, `hasReportFooterSection`,
  `hasPageHeaderSection`, `hasPageFooterSection`) in `Mac/Source` — replace them with
  the selected query's ordered sections where the Designer is editing a node.
- Field list: for a composing node use **its** output fields
  (`orderedOutputFieldsWithError:`), for a leaf use its own query fields — not the
  root's `orderedCompositionOutputsWithError:`. Keep the existing caption wording
  ("Report columns" for a Result/composing node, "Query fields" for a leaf); do not use
  the document-level composition caption for a source.
- Element bindings for a leaf must use the field key the node result carries (the
  leaf's own field key; a composing field uses its `outputKey`). Verify a bound data
  field actually renders the node's values — a blank field means the key mapping is
  wrong.
- Empty bands are authorable. Show a short "add elements to design this report" hint
  when the selected node's layout has no elements; do not treat empty as an error.
- Paper size stays document-level (`headlessDocument.paperType`, the document's
  `papersize`); do not add per-node paper.

### 5. Viewer — per node

- Keep a `selectedQuery` reference in the viewer (set by the document/selection
  notification).
- Render the selected node: call the PDF exporter's
  `exportDocument:headlessDocument query:selectedQuery toURL:… options:error:` for the
  preview, and pass the selected query for every node-scoped export in the save panel.
  For a Standard Report, the single query is the report root and the current path
  remains correct.
- Status uses the selected node's row count, not the root's.
- **Layout-less node → row grid.** If the selected node's ordered sections contain no
  elements, hide the PDFView and show an `NSTableView` (inside the viewer area) whose
  columns come from `nodeResults[@(query.identifier)]`'s data table and whose headers
  use the table's column names. A node with elements shows the PDF; a node with empty
  bands and no elements shows the grid.
- Clear the previous node's PDF/rows when the selection changes, before the new render,
  so the old node never flashes.
- `json-report` stays available only for the report root; filter the export popup and
  surface the engine error if it is forced. All other formats pass the selected query.
- Refreshing remains whole-document. When the refresh completes while a source is
  selected, re-render that node from its retained result; a failed node names it and
  leaves the previous complete result intact (already the engine behaviour).

### 6. Notifications, ordering, and races

- Serialize and version-check selection reloads: an older selection must not overwrite
  a newer one (the Windows `ReloadNodeAsync` is the pattern). The Query model reload,
  Designer reload, and Viewer render all key off the selected query.
- The selection notification must not create a reload loop with
  `MADMacDocumentDidMutateNotification`; selection is not a mutation.
- The window controller coordinates: selecting a node reloads Designer; the Viewer
  updates via the notification; switching tabs still calls `reloadFromDocument`.

### 7. Localization

- Add every new string to `MADDesigner/Resources/Localizable.xcstrings` in all six
  languages (en, de, es, ja, pt-BR, zh-Hans), using the existing `NSLocalizedString`
  keys/comments. New strings will include at least: the node picker label/tooltip, the
  nested-authoring note, the row-grid status/headers fallback, the "not yet refreshed"
  node wording, and the `json-report`-unavailable wording.
- Run the Tier 0 localization checks:
  - `python3 -I scripts/localization/audit.py`
  - `python3 -I scripts/localization/sync_catalog.py --check`
  - `python3 -I scripts/localization/check_translations.py` (omit `--require-complete`
    while translating; CI requires completeness).
- Every new control gets an accessibility label/tooltip consistent with the existing
  Mac controls.

### 8. Tests

Extend `Mac/Tests/MADMacSmokeTest.m`, which already builds a composed invoices/payments
fixture and refreshes it. Add checks that:

- selecting a source keeps the workspace and exposes the source's bands in
  `orderedSections` (not the root's);
- authoring a label + data field on a source, refreshing, then selecting it produces a
  non-empty node PDF (or HTML) containing the authored text and values;
- selecting the Result returns the Result's layout and render in all three workspaces;
- a layout-less source shows the row grid, not an error;
- a Standard Report's layout/export are unchanged and `json-report` works;
- `json-report` is unavailable for a source while the other formats work;
- a composed root with no sources still reads as the Result.

Keep every existing smoke check green.

### 9. Build, run, screenshots

- **First gate (before UI edits):** `./Mac/build.sh --smoke-test` on the clean
  `7ca328dca` base. This is the first compile of the Apple-only
  `MAD/Source/MADPrintPageRenderer.m` node-aware substitution. If it fails, stop and
  report the compile/run error; do not work around it in the UI.
- After approval, use `./Mac/build.sh --no-frameworks` for iteration, and run the full
  `--smoke-test` before reporting.
- Run the app against a composed fixture (the smoke test's fixture builder can produce
  one, or copy its steps) and capture the per-node Designer and Viewer states with
  `screencapture` or the app's own window. Report the PNG paths. The user wants to see
  it run on the Mac.
- If the change touches `MAD/Source` (it should not except a real gap), run the touched
  framework's suite per `mad-verify`. Linux/Windows gates do not apply to UI-only Mac
  changes; the engine change is already on the integration branch.

## Out of scope / recorded deferrals

- No engine/store/import/serve changes; if the per-node Apple render path is
  insufficient, stop and report.
- No Windows/WPF or iOS changes.
- `json-report` node scoping, per-node paper size, direct nested authoring, and a
  Standard Report with no elements cannot refresh (empty active-field SELECT).
- The Windows composition graph/expand/collapse is not required; a picker/list is the
  Mac shape.
- `convertToCompositionWithChildName:` moving the child's bands to the root remains an
  engine deferral.

## Acceptance

1. Open a composition; select a source in the picker. The workspace does not change;
   Query shows the source's query; Designer shows the source's bands; Viewer shows its
   PDF or row grid.
2. Author a layout on a source, save, close, reopen; the source's layout persists and
   the Result's layout is unchanged. Selecting the Result returns all three workspaces
   to the Result.
3. A source with a data field renders that field's values from its own rows.
4. A layout-less source shows the row grid, not an error.
5. A Standard Report behaves exactly as before: document layout, `json-report` works.
6. `json-report` is unavailable for a source; the other formats work.
7. The smoke suite is green and the screenshots exist.

## Process

- Produce a plan first: files, document/selection changes, AppKit views, localization
  keys, tests, screenshots, risks. Stop for user approval. Do not edit before approval.
- After approval: create `feat/composition-node-reports-macos` off
  `feat/composition-engine-n-node` (the integration branch), commit with `-s`, push.
  **No PR, no merge** unless the user directs.
- Report the branch, exact commands, results, screenshot paths, and any engine gap
  found. If an engine fix is needed, stop and report; it belongs on the integration
  branch, followed by a rebase of this slice.
