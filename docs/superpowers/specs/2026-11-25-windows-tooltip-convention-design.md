# Windows P0 tooltip and automation-name convention — design

Date: 2026-11-25
Status: proposed
Scope: the P0 tooltip/accessibility item in
[`MAD_WINDOWS_UI.md`](../../project/design/MAD_WINDOWS_UI.md), for the Query and
Designer workspaces only.

## Intent

Report 1's first P0 finding is that tooltips and accessible names are
inconsistent: some commands carry both, some carry one, and many carry neither.
A user cannot discover what the icon+label commands do, and a screen reader has
nothing to announce for the query selector, the list boxes, or the segment
toggles. The goal is a convention that is complete for the two authoring
workspaces, legible in the XAML, and enforced by a test so it does not decay.

## Goals

- Every action control in `QueryView.xaml` and `DesignerView.xaml` has a
  localized `ToolTip` explaining what it does and a localized
  `AutomationProperties.Name` for assistive technology.
- Tooltips and automation names are authored separately, because they serve
  different purposes: a tooltip may be a full sentence and may later hold rich
  content; an automation name is a short, spoken label and must not.
- A test fails when a command control is added without either property.
- New strings are added to all six shipped dictionaries (English source plus
  AI-drafted `de`, `es`, `ja`, `pt-BR`, `zh-Hans`), keeping the localization
  gate green.
- The P0 section of `MAD_WINDOWS_UI.md` is marked complete with what landed.

## Non-goals

- No P1 or P2 work: no command-bar regrouping, no empty-state redesign, no
  unified feedback surface, no general canvas hover tooltips.
- No composition (Report 2) terminology or workflow changes.
- No layout or visual redesign of the two views.
- No changes to the Viewer, Welcome, Connection, or About surfaces.

## Anti-goals

- A convention that only covers the buttons a test can reach at runtime. Popup
  content and data-template content must be covered too, which is why the gate
  reads the XAML sources rather than a materialized visual tree.
- Duplicating the same sentence into both properties when a short name will do.
  Names stay short; tooltips carry the explanation.

## Constraints

- WPF on .NET 10, `net10.0-windows`; `{infra:Loc Key}` resolves at XAML load
  time from `Localizer`, so the test can assert the attribute values without
  instantiating the views.
- `LocalizerTests.EveryShippedDictionary_HasEveryEnglishKey` pins the English
  key count (currently 269) and requires every shipped dictionary to carry every
  key. Adding strings means updating that count and all six dictionaries.
- The app's localization decision D14 is AI-drafted translations shipped
  unreviewed, with the machine-assisted notice already in the About screen.
- The repo's Windows build is already present (`Windows/Engine/build/mad.exe`),
  so the existing WPF suite can run.

## Approaches considered

**A — Attached-property helper + static XAML test.** A `LocalizedTip` attached
property takes one key and sets both properties; the test requires the attached
property. Least XAML, one source of truth. Rejected because tooltips and
automation names are treated as one thing, which is the opposite of the desired
model: a tooltip is rich UI, an automation name is accessibility.

**B — Explicit attributes + static XAML test (selected).** Each control writes
`ToolTip="{infra:Loc …}"` and `AutomationProperties.Name="{infra:Loc …}"`
separately; the test requires both on every action control. More verbose, but
the XAML reads plainly, the two concerns stay separate, and a reviewer sees
exactly what is announced and what is shown. This is the user's choice.

**C — Runtime visual-tree test only.** Cheap to write but misses controls inside
closed popups and data templates, and is more brittle. Rejected as the gate; no
part of B depends on it.

## The design

### Convention

For both views, an **action control** is a `Button`, `ToggleButton`, `CheckBox`,
`ComboBox`, `ListBox`, or `Slider`. Every one gets:

- `ToolTip` — localized, task-oriented: what the control does and, for lists,
  what a double-click does. Full sentences are allowed.
- `AutomationProperties.Name` — localized, short: the visible label where that
  is already the right name (Undo, Delete, Barcode), or a concise action name
  for icon-only controls. It is never a sentence when a label will do.

`TextBox` inputs stay out of the convention in this pass; they are labeled by
the adjacent `MAD.FieldLabel` text and are not commands. Two exceptions already
in scope: the inspector's `B / I / U / S` checkboxes get real names (Bold,
Italic, Underline, Strikethrough) instead of single letters.

Where a control already complies (the Query zoom controls, the Barcode insert
button, the Designer edit commands), its strings are reviewed and only changed
where the tooltip does not explain the action.

### Coverage and new strings

`QueryView.xaml`:

- Segment toggles: Designer and SQL modes.
- Query selector.
- Filters, Groups, Outputs (root only), Arrange Tables.
- Revert, Validate, Apply SQL.
- Schema and Sources lists: the double-click action.
- Add table (already present; tooltip gets a task sentence).
- Filter/Group/Output editors: field, operator/order, and key controls; the
  add/remove/up/down buttons in their templates.

`DesignerView.xaml`:

- Insert palette: Label, Data Field, Aggregate, Image, Line, Barcode.
- Undo, Redo, Duplicate, Delete.
- Bands and Query Fields lists: what a double-click does.
- Page/selected-band card: paper picker.
- Element inspector: band picker, barcode symbology/show-text/border/input,
  Choose Image, typography toggles, alignment pickers, duplicate/delete.
- Status bar: zoom slider, Grid, Snap, Rulers.

Key names follow the existing shape: `<Area>.<Thing>.Tooltip` for the sentence;
the automation name reuses an existing label key, or adds `<Area>.<Thing>` only
when no label exists (for example `Designer.Bold`).

### The gate

A new `TooltipConventionTests.cs` in `Mad.Designer.Windows.Tests` parses the two
XAML sources (located through `MadPathResolver.RepoRoot()`), selects every
action control, and asserts:

1. `ToolTip` exists, is non-empty, and is a `{infra:Loc …}` reference.
2. `AutomationProperties.Name` exists, is non-empty, and is a `{infra:Loc …}`
   reference.

Failures are reported in one message naming each offending element, so a later
agent adding a command gets a precise list. No WPF thread is needed. The test
runs without the engine.

### Small fixes included because they are the same defect

- `QueryCanvas` puts the join-type tooltip on the bezier curve, but the curve is
  `IsHitTestVisible="false"`, so it can never appear. Move the tooltip to the
  midpoint badge, which is the click target, and give it a sentence that names
  both fields.
- Give the Query canvas field rows a drag-to-join tooltip ("Drag to another
  table's field to create a join").
- Give the Designer canvas bands and elements no new hover tooltips (P2), but
  record that the Bands list's double-click toggles visibility, which the
  tooltip must say plainly.

### Localization

Add the same keys to `Strings-en.xaml` and the five translation dictionaries,
in the existing tone. Update the pinned English count in `LocalizerTests`. No
change to `Localizer` itself.

### Documentation

Update `docs/project/design/MAD_WINDOWS_UI.md`: mark the P0 tooltip and
automation-name recommendation complete, with a short note of the convention,
the test name, and the date. Record the follow-ups found but not built.

## Verification

- `dotnet test Windows/App/Mad.Designer.Windows.Tests --filter "FullyQualifiedName~TooltipConventionTests|FullyQualifiedName~LocalizerTests"`
  for the new gate and the dictionaries.
- The full `dotnet test Windows/App/Mad.Designer.Windows.Tests` suite, since
  `ShellSurfaceTests` loads the views and would catch a broken style/resource
  reference.
- No engine rebuild is needed; `mad.exe` is already present.

## What is left to the builder

- The exact English copy and the matching translations.
- The final key inventory (the design lists the controls, not every string).
- Keeping the automation name short even where the tooltip is a sentence.

## Follow-ups recorded, not built

- The element inspector's four border boxes (`Border T / B / L / R`) are four
  unlabeled numeric fields; they need accessible names and possibly separate
  labels.
- The Bands list's double-click toggles section visibility; that is a
  surprising gesture and deserves a more discoverable control.
- P1/P2 from Report 1: command-bar grouping, empty/error states, unified
  feedback, general canvas tooltips.
- Composition-facing changes remain with Report 2 and the future agent.
