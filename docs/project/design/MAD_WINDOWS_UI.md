# Report 1 — Windows app & UI review

Scope: the whole WPF shell, its design system, and general usability. No code changed;
this is an audit with prioritized recommendations.

## What is already good

- **Design system** (`Themes/Theme.xaml`) is disciplined: Fluent dynamic resources for
  light/dark/accent/high-contrast, a small set of MAD.* styles (text, surfaces, command
  button, primary/secondary button, segmented control, nav rail, popup surface), and
  semantic brushes for success/error. This is the right foundation.
- **Designer** and **About** are the strongest surfaces (consistent cards, a clear
  inspector, a minimap that is sensibly collapsed by default, a real page-size/paper model).
- **Viewer** has good status colouring (success/error) and a clean command/status split.
- **Welcome** is clean and appropriately minimal.

## Issues found (grounded in the XAML/view models)

1. **Tooltips are inconsistent, and many are missing.** The user is right. Concrete gaps:
   - Query workspace: the Designer/SQL segment toggles, Filters, Groups, Arrange Tables, and
     the query selector have no `ToolTip`. The schema/sources lists don't explain the
     double-click action.
   - Designer: the five Insert buttons (Label, Data Field, Aggregate, Image, Line) have no
     `ToolTip` (only Barcode does); they are effectively icon+label buttons whose exact
     effect ("adds a bound data field into the selected band") is not explained.
   - Several commands pair a `ToolTip` with `AutomationProperties.Name` (good), but many
     others have only one or neither. There is no convention enforced.
2. **Command bars are crowded and icon-first.** The Designer bar holds six Insert buttons
   plus four edit commands; the Query bar holds mode toggles, a query selector, three
   edit commands, and SQL commands. Icon + short label is workable, but there is no grouping
   or progressive disclosure, and icon glyphs vary in meaning (e.g. `&#xE8C8;` is reused for
   Barcode and Duplicate).
3. **The document type is too quiet.** The toolbar shows a small "Standard Report" /
   "Composition Report" text. It is present but easy to miss, and it says nothing about what
   to *do* next (especially for a composition).
4. **Empty/error states are weak.** A freshly opened document with no query, a composed
   document with no children, and a disconnected source all fall back to generic status text.
   There is no in-place guidance ("add a source query", "import a report", "no rows").
5. **Accessibility is partial.** `AutomationProperties.Name` is set on many but not all
   icon-only controls; the query selector, schema/sources lists, and segment toggles lack
   automation names/tooltips.
6. **Feedback placement is split.** Query/Designer errors go to a workspace status bar;
   Viewer errors go to its own status bar; document-level errors go to the toolbar. A user
   editing a query can miss a failed mutation that lands on the document toolbar.

## Prioritized recommendations

**P0 — Tooltip & automation-name convention (low effort, high payoff).**
**Complete (2026-11-25).** The Query and Designer workspaces now give every `Button`,
`ToggleButton`, `CheckBox`, `ComboBox`, `ListBox`, and `Slider` a localized `ToolTip`
(the task explanation) and a separate localized `AutomationProperties.Name` (the short
spoken label). `TooltipConventionTests` reads both XAML sources and fails with a
file/line list when either is missing or not localized. The five insert commands, the
mode toggles, the query selector, both sidebars, the popup editors, the barcode and
typography controls, and the canvas-view controls are covered. The join-type tooltip
moved from the non-hit-testable curve to its midpoint badge, and query fields now
explain the drag-to-join gesture.

**P0 — Make the document type and its next action explicit.** (The composition case is
redesigned in detail in [`MAD_COMPOSITION_UX.md`](MAD_COMPOSITION_UX.md).)
**Badge complete (2026-11-25).** The small type text is now a pill next to the filename
(Standard = neutral, Composition = accent) with a per-type tooltip, and
`DocumentTypeBadgeTests` pins the bindings, the accent trigger, and the placement beside
a trimmed filename. The one-line next-action hint on open (e.g. "Composition: use
Import… to add reports, then join them in the Query workspace") still waits for Report 2.

**P1 — Group the command bars.** **Complete (2026-11-25).** The Designer's six insert
buttons are now one Insert menu with Text and Graphics groups; the Designer bar carries an
Edit caption, and the Query bar a Refine caption. Arrange Tables moved to the Query status
bar beside Fit — the other View controls (grid, snap, rulers, zoom) were already in the
status bars. Barcode now uses the BarcodeScanner glyph (EC5A) instead of the Copy glyph it
shared with Duplicate. `CommandBarTests` pins the structure and hosts the Designer at
912 px, the content width of the 1000 px window minimum, to prove the edit group no longer
clips. Follow-up (owner, 2026-11-25): the remaining button surfaces — the main-window
toolbar and the inspector's Duplicate/Delete — may get the same treatment in time.

**P1 — In-place empty/error states.** Per workspace, replace the generic status with a
situational message (e.g. the Query sidebar says "This source has no tables yet — add one
below", the root canvas says "Import or add a source to begin composing").
**Complete for standard reports (2026-11-26).** A leaf query whose database has no tables
now says so above the empty schema list, and the Designer's field list says "Build the
query to see fields here." when the query exposes none. The composition/root empty states
stay with Report 2, per the scope note below.

**P2 — Unify feedback.** Route all mutations' success/error to one visible place (the
document status bar), with workspace-local detail where helpful, so a failed action is never
missed.
**Complete (2026-11-26).** `DocumentViewModel` forwards a Query or Designer failure to the
always-visible document toolbar, and both workspace status bars now render their own
`ErrorText` in red. A workspace clears the toolbar error only when it set that text, so a
successful edit never hides an unrelated document failure.

**P2 — Real tooltips for the canvases.** The Designer canvas and Query canvas draw their own
elements (tables, fields, joins, bands); they get no native tooltips. Add cursor/hover
tooltips for "drag field-to-field to join", "drag a band to resize", etc.
**Complete (2026-11-26).** The Query table header explains dragging to move the table. The
Designer canvas gives every element ("drag to move, drag a handle to resize, or
double-click to edit") and every band ("click to select; drag its bottom edge to resize") a
hover tooltip. Field rows and join badges were already covered in P0.

## What I need to run/debug the UI (and tools to add to the box)

**Why I couldn't run it:** this SSH session is `LocalSystem` (session 0), a non-interactive
session. A WPF app launched from it renders in session 0, not the signed-in desktop, so I
can't see the window (and it may fail to create its surface). Code-level review works fine;
visual verification does not.

**To let me (or you) iterate visually, in order of simplicity:**
1. **You run it and share screenshots** — zero setup. `dotnet run --project
   .\Windows\App\Mad.Designer.Windows` (or the packaged `Mad.Designer.Windows.exe`).
2. **A screenshot harness I can invoke.** A small PowerShell screen-capture (System.Drawing
   `CopyFromScreen`) run against a window launched in the interactive session (via
   `schtasks … /it` or `psexec -i 1`). This captures pixels so I can see real rendering.
3. **Visual Studio** (already installed) — open the WPF project, use the XAML designer +
   hot reload + a debugger. The project has not been opened there; that is the single most
   useful addition for *you* and *me*.
4. **FlaUI** (UI Automation) as a headless driver — verifies layout/logic and the visual
   tree without pixels; good for acceptance tests, not for polish.

Recommendation: add nothing mandatory — open the project in Visual Studio and share a few
screenshots; that unblocks visual iteration for both of us.

## Follow-ups found while completing P0 (2026-11-25)

- **Complete (2026-11-26).** The element inspector's `Border T / B / L / R` boxes are now
  individually labelled Top / Bottom / Left / Right in two rows, each with a localized
  tooltip and accessible name.
- **Complete (2026-11-26).** The Bands list's visibility gesture is now a right-click
  context menu (Select Section / Show Section / Hide Section). A hidden band stays in the
  list but renders dimmed and italic so it reads as disabled, mirroring the iOS designer.
  Double-click remains a silent accelerator.
- **Complete (2026-11-26).** The composition-facing presentation from Report 2 landed as a
  docked **Composition pane** (the direction in `Composable UI on Windows.md`), not the top
  node strip: a clickable graph with the Result at depth 0, Expand/Collapse, one toolbar
  Component picker, the "Outputs → Columns" rename with explanatory copy, the Sources and
  result-canvas empty states, the one-source hint, and the type-specific start workspace
  (Query on open). Every new string is in all six dictionaries. Selecting a source currently
  moves to Query and Designer/Viewer show a notice — that is an **interim** state, not the
  target. The final decision (spec §0) is that every node is a full report with its own layout
  and data, and all three workspaces follow the selection. The store/import/serve and UI work
  to remove the notice is scoped in
  [`MAD_COMPOSITION_NODE_VIEW.md`](MAD_COMPOSITION_NODE_VIEW.md).
