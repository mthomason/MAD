# Command-bar grouping — design

Status: proposed 2026-11-25. Report 1, P1: group the command bars.

## Intent and why

The Designer command bar puts six labelled insert buttons and four labelled edit
commands in one row. At the app's 1000 px minimum width the edit group is clipped and
**Undo disappears**. The row is also visually noisy: every insert is a permanent button.
The owner's direction: replace the insert palette with **one Insert button** that opens a
styled, grouped menu; keep the bar calm.

The Query bar is not clipped, but its commands are ungrouped and Arrange Tables (a canvas
command) sits beside the query-shaping commands.

## Goals

- One Insert button in the Designer bar. Pressing it opens a styled popup listing all six
  inserts, grouped: **Text** (Label, Data Field, Aggregate) and **Graphics** (Image, Line,
  Barcode).
- Designer bar: Insert button | divider | **Edit** caption + Undo, Redo, Duplicate, Delete
  (labels kept). Everything fits at 1000 px with slack.
- Query bar: a **Refine** caption over Filters, Groupings, Outputs. Move Arrange Tables to
  the status bar beside Fit, in a canvas-view cluster.
- Fix the glyph collision: Barcode becomes `EC5A` (BarcodeScanner); Duplicate keeps
  `E8C8` (Copy).
- Keyboard support for the menu: Enter/Space opens it, focus enters the first row, Up/Down
  move between rows, Home/End jump, Enter activates the focused row, Esc closes it and
  returns focus to Insert.
- Tooltips and accessible names stay separate and localized; the Query/Designer tooltip
  gate extends to `MenuItem` (skipping disabled caption items), so the Insert menu and its
  rows are covered.

## Non-goals / anti-goals

- No command behaviour changes; every insert and edit keeps its current command.
- No new element types, no composition presentation changes (Report 2).
- No change to the SQL-mode command set.
- No View menu or overflow menu: the View controls (grid, snap, rulers, Fit, zoom) already
  live in the status bars.

## Constraints

- New strings go into all six dictionaries; `LocalizerTests` English count moves 355 → 360.
- Do not change `Localizer` behaviour.
- Keep the Query/Designer tooltip gate green; the top-level Insert button and all six menu
  rows carry a localized `ToolTip` and `AutomationProperties.Name`.
- Full suite: `dotnet test Windows/App/Mad.Designer.Windows.Tests`.
- UI-only; no engine rebuild.

## Approaches considered

1. **Icon-only edit cluster** (my first proposal). Fits, but the owner rejected it: ten
   buttons is still too many.
2. **Insert overflow with three common inserts** — rejected: the owner wants all inserts
   behind the one button.
3. **One Insert button + styled menu** (chosen). A WPF `Menu` with a custom top-level
   `MenuItem` template (command-button look) and a custom row template. The `Menu` supplies
   the keyboard semantics for free — Enter/Space/Down to open, arrows to move, Esc to
   close, correct click-to-toggle — which a hand-written popup would have to reimplement.
   The submenu surface reuses `MAD.PopupSurface`, so it still looks like the app.

## Design

Designer bar at 1000 px:

```
[+ Insert ▾]  │  Edit  ↶ Undo  ↷ Redo  ⧉ Duplicate  🗑 Delete
```

The Insert popup, placed below the button, ~230 px wide, card surface:

```
TEXT
  ▣ Label
  ⊞ Data Field
  Σ Aggregate
────────────────
GRAPHICS
  ▤ Image
  ― Line
  ▥ Barcode
```

- The Insert button uses a plus (`E710`), the localized "Insert" label, and a chevron
  (`E70D`); tooltip explains what it adds; accessible name is "Insert".
- Rows are `MenuItem`s styled as menu rows (icon + label, hover fill, no chrome); each
  reuses its existing localized name and tooltip and binds its existing command. Disabled
  caption items mark the Text and Graphics groups.
- Group captions are `TextBlock`s; the separator is a 1 px divider.
- `MAD.GroupCaption` is a new shared TextBlock style for "Edit" and "Refine" (caption size,
  semibold, small right margin), replacing the inline Insert caption styling.
- Submenu placement: below the Insert header. The WPF `Menu` manages focus, arrow keys,
  Esc, and the click-to-toggle behaviour; the header style uses the same hover fills as the
  command buttons.

Query bar at 1000 px:

```
[Designer|SQL] │ Refine  Filters (1)  Groupings (5)            … query ▾
status bar:  …  − 100% + Fit │ Arrange Tables
```

## New strings (English; translations AI-drafted per D14)

| Key | English |
|---|---|
| `Designer.Insert.Tooltip` | Add an element to the selected band. |
| `Designer.Edit` | Edit |
| `Query.Refine` | Refine |
| `Designer.Insert.Text` | Text |
| `Designer.Insert.Graphics` | Graphics |

## Tests

1. `CommandBarTests` (new, reads the XAML): the Designer bar has one Insert button and no
   free-standing insert buttons; the popup holds six rows bound to the six insert commands,
   all with localized tooltip + name; the Barcode glyph is `EC5A` and differs from
   Duplicate's `E8C8`; the Edit and Refine captions exist; Arrange Tables sits in the Query
   status-bar row.
2. A layout test hosts `DesignerView` at 912 px (the content width at the 1000 px window
   minimum) and asserts the Insert button and the Delete button are fully inside the command
   bar — the regression that caught the clipped Undo.
3. The existing tooltip gate and localization gate cover the new controls/keys.
4. Manual: capture the bar and the open popup at 1000 px, light theme.

## Left to the builder

Row padding, popup width, and the exact group names may be tuned after a screenshot; the
single-Insert-button structure, the two groups, and the status-bar move are fixed.
