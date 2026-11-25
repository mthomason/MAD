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
Add a `ToolTip` + `AutomationProperties.Name` to every command, and a shared helper (a
`ToolTipService`-based attached property, or just discipline in XAML) so it stays consistent.
Prioritize the Query and Designer command buttons above.

**P0 — Make the document type and its next action explicit.** (The composition case is
redesigned in detail in [`MAD_COMPOSITION_UX.md`](MAD_COMPOSITION_UX.md).)
Promote the document-type label to a visible pill/badge next to the filename (Standard =
neutral, Composition = accent), and add a one-line hint on open: e.g. "Composition: use
Import… to add reports, then join them in the Query workspace." (Detailed in Report 2.)

**P1 — Group the command bars.** Introduce visual groups (Insert / Edit / View) with a small
divider, and move less-used commands (Arrange Tables, Fit, grid/rulers) out of the primary
bar into a menu or the status bar. Reduces crowding and teaches the layout.

**P1 — In-place empty/error states.** Per workspace, replace the generic status with a
situational message (e.g. the Query sidebar says "This source has no tables yet — add one
below", the root canvas says "Import or add a source to begin composing").

**P2 — Unify feedback.** Route all mutations' success/error to one visible place (the
document status bar), with workspace-local detail where helpful, so a failed action is never
missed.

**P2 — Real tooltips for the canvases.** The Designer canvas and Query canvas draw their own
elements (tables, fields, joins, bands); they get no native tooltips. Add cursor/hover
tooltips for "drag field-to-field to join", "drag a band to resize", etc.

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
