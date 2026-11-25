# Windows P0 Tooltip and Accessible-Name Convention — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give every action control in the Windows Query and Designer workspaces a
localized tooltip and a separate localized accessible name, enforce that with a test,
and keep all six string dictionaries complete.

**Architecture:** The two view XAML files gain explicit `ToolTip` and
`AutomationProperties.Name` attributes; a static XAML test reads the sources so it also
covers popup and data-template content. New strings go into the English source and the
five AI-drafted translation dictionaries. Two Query-canvas tooltip defects are fixed in
code and pinned by the existing canvas test class.

**Tech Stack:** WPF / .NET 10 (`net10.0-windows`), xUnit, `XDocument` +
`IXmlLineInfo`, the app's `Localizer` and `{infra:Loc …}` markup extension.

**Spec:** [`docs/superpowers/specs/2026-11-25-windows-tooltip-convention-design.md`](../specs/2026-11-25-windows-tooltip-convention-design.md)

## Global Constraints

- **Scope:** Query and Designer only. No Viewer, Welcome, Connection, About, MainWindow,
  or composition (Report 2) changes. No P1/P2 work (grouping, empty states, unified
  feedback, general canvas hover tooltips).
- **Separate concerns:** `ToolTip` is the rich, task-oriented explanation;
  `AutomationProperties.Name` is the short spoken label. Never derive one from the other.
- **Localization:** every new key goes into `Strings-en.xaml` **and** `Strings-de.xaml`,
  `Strings-es.xaml`, `Strings-ja.xaml`, `Strings-pt-BR.xaml`, and `Strings-zh-Hans.xaml`
  with an AI-drafted translation. English is authoritative. Do not change `Localizer`.
- **Pinned count:** `LocalizerTests.EveryShippedDictionary_HasEveryEnglishKey` starts at
  **269**; this plan raises it to **312** (Task 1), **351** (Task 2), then **353** (Task 3).
- **Test gate:** `TooltipConventionTests` requires `ToolTip` and
  `AutomationProperties.Name` on every `Button`, `ToggleButton`, `CheckBox`, `ComboBox`,
  `ListBox`, and `Slider` in the two XAML files, and requires both values to contain
  `{infra:Loc`.
- **Style:** follow the existing XAML attribute order and four-space indentation; put each
  new attribute on its own line when the element is already multi-line.
- **Commits:** `git commit -s` on `feat/composition-engine-n-node`. No PR, no merge.
- **Verification environment:** `Windows/Engine/build/mad.exe` is already built, so the
  WPF suite runs without an engine rebuild.

## Review Focus

- **A control inside a `Popup` or `DataTemplate` is skipped.** The static XAML scan
  covers these; Task 1's Query test includes the Filters/Groups/Outputs templates, and
  Task 2's Designer test includes the inspector.
- **A key is added to English only.** `LocalizerTests` fails on the missing translation;
  every task runs it.
- **The tooltip is localized but the accessible name is not (or vice versa).** The gate
  requires both attributes to be `{infra:Loc …}` references.
- **The join tooltip stays on the non-hit-testable curve.** Task 3's canvas test asserts
  the midpoint badge carries a tooltip and the field row explains dragging.
- **The copy promises a behaviour the control does not have.** The Bands list's
  double-click toggles visibility (it does not select), so its tooltip says exactly that.

---

## File Structure

| File | Responsibility |
|---|---|
| `Windows/App/Mad.Designer.Windows.Tests/TooltipConventionTests.cs` | **New.** Static XAML gate for both views; shared `AssertViewConforms`. |
| `Windows/App/Mad.Designer.Windows/Views/QueryView.xaml` | Query command bar, sidebars, popups: add tooltips and accessible names (Task 1). |
| `Windows/App/Mad.Designer.Windows/Views/DesignerView.xaml` | Designer command bar, lists, inspector, status bar: add tooltips and accessible names (Task 2). |
| `Windows/App/Mad.Designer.Windows/Views/QueryCanvas.cs` | Move the join tooltip to the badge; add the field drag hint (Task 3). |
| `Windows/App/Mad.Designer.Windows/Resources/Strings-*.xaml` | Six dictionaries: 84 new keys total (43 + 39 + 2). |
| `Windows/App/Mad.Designer.Windows.Tests/LocalizerTests.cs` | Raise the pinned English key count in three steps. |
| `Windows/App/Mad.Designer.Windows.Tests/QueryCanvasTests.cs` | Add the join-badge and field-row tooltip test (Task 3). |
| `docs/project/design/MAD_WINDOWS_UI.md` | Mark P0 complete; record follow-ups (Task 4). |

---

### Task 1: Query workspace tooltips and accessible names

**Files:**
- Create: `Windows/App/Mad.Designer.Windows.Tests/TooltipConventionTests.cs`
- Modify: `Windows/App/Mad.Designer.Windows/Views/QueryView.xaml`
- Modify: all six `Windows/App/Mad.Designer.Windows/Resources/Strings-*.xaml`
- Modify: `Windows/App/Mad.Designer.Windows.Tests/LocalizerTests.cs:25`

**Interfaces:**
- Consumes: `MadPathResolver.RepoRoot()`, `Localizer`, the existing `{infra:Loc …}`
  markup extension.
- Produces: `private static void AssertViewConforms(string fileName)` in
  `TooltipConventionTests` (Task 2 calls it), and the 43 `Query.*` keys in the table below.

- [ ] **Step 1: Write the failing Query test**

Create `TooltipConventionTests.cs` with exactly this content:

```csharp
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using System.IO;
using System.Xml;
using System.Xml.Linq;
using Mad.Designer.Windows.Infrastructure;

namespace Mad.Designer.Windows.Tests;

/// <summary>The P0 tooltip and accessible-name gate: every action control in the Query and
/// Designer XAML carries a localized tooltip and a separate localized accessible name. The
/// check reads the XAML sources, so it also covers popup and data-template content that a
/// loaded visual tree would miss. The Query and Designer facts are added as each view is
/// brought under the convention.</summary>
public sealed class TooltipConventionTests
{
    private static readonly string[] ActionControls =
    {
        "Button", "ToggleButton", "CheckBox", "ComboBox", "ListBox", "Slider",
    };

    [Fact]
    public void QueryView_GivesEveryActionControlATooltipAndAccessibleName()
        => AssertViewConforms("QueryView.xaml");

    private static void AssertViewConforms(string fileName)
    {
        string path = Path.Combine(
            MadPathResolver.RepoRoot(), "Windows", "App", "Mad.Designer.Windows", "Views", fileName);
        XDocument document = XDocument.Load(path);
        XNamespace presentation = "http://schemas.microsoft.com/winfx/2006/xaml/presentation";

        var failures = new List<string>();
        foreach (XElement element in document.Descendants())
        {
            if (element.Name.Namespace != presentation) continue;
            if (!ActionControls.Contains(element.Name.LocalName)) continue;

            string location = $"{fileName}:{((IXmlLineInfo)element).LineNumber} ({element.Name.LocalName})";
            string? toolTip = (string?)element.Attribute("ToolTip");
            string? name = (string?)element.Attribute("AutomationProperties.Name");

            if (toolTip is null || !toolTip.Contains("{infra:Loc", StringComparison.Ordinal))
                failures.Add($"{location} is missing a localized ToolTip");
            if (name is null || !name.Contains("{infra:Loc", StringComparison.Ordinal))
                failures.Add($"{location} is missing a localized AutomationProperties.Name");
        }

        Assert.True(failures.Count == 0,
            $"{fileName} has {failures.Count} tooltip/accessibility gap(s):" +
            Environment.NewLine + string.Join(Environment.NewLine, failures));
    }
}
```

- [ ] **Step 2: Run the test and confirm it fails**

Run from the repo root:

```sh
dotnet test Windows/App/Mad.Designer.Windows.Tests --filter "FullyQualifiedName~TooltipConventionTests"
```

Expected: FAIL. The message lists `QueryView.xaml` controls missing one or both attributes,
including the mode toggles, query selector, Filters/Groups/Outputs/Arrange Tables, the SQL
commands, the schema/sources lists, and the popup buttons.

- [ ] **Step 3: Add the 43 Query keys to the English dictionary**

Add these entries to `Strings-en.xaml`, grouped near the existing `Query.*` keys. The
English text is authoritative and must be copied exactly.

| Key | English text |
|---|---|
| `Query.Mode.Designer.Tooltip` | `Build the query visually with tables, joins, filters, and groupings.` |
| `Query.Mode.Sql.Tooltip` | `Edit the query's SQL directly, then validate or apply it.` |
| `Query.SelectQuery.Tooltip` | `Choose which query this workspace edits.` |
| `Query.SelectQuery.Name` | `Query to edit` |
| `Query.Filters.Tooltip` | `Show or hide the WHERE filters editor.` |
| `Query.Filters.Name` | `Filters` |
| `Query.Groups.Tooltip` | `Show or hide the GROUP BY groupings editor.` |
| `Query.Groups.Name` | `Groupings` |
| `Query.Outputs.Tooltip` | `Show or hide the report columns this composition exposes.` |
| `Query.Outputs.Name` | `Outputs` |
| `Query.ArrangeTables.Tooltip` | `Lay the table cards out automatically.` |
| `Query.RevertSql.Tooltip` | `Discard the SQL edits and return to the generated statement.` |
| `Query.ValidateSql.Tooltip` | `Check the SQL without changing the query.` |
| `Query.ApplySql.Tooltip` | `Compile the SQL and update the visual query.` |
| `Query.AddTable.Tooltip` | `Add the selected table to the query.` |
| `Query.SchemaList.Tooltip` | `Double-click a table to add it to the query.` |
| `Query.SourcesList.Tooltip` | `Double-click a source to add it to the result.` |
| `Query.RemoveFilter.Tooltip` | `Remove this filter.` |
| `Query.RemoveFilter` | `Remove filter` |
| `Query.FilterField.Tooltip` | `Choose the field to filter.` |
| `Query.FilterField` | `Filter field` |
| `Query.FilterOperator.Tooltip` | `Choose the comparison operator.` |
| `Query.FilterOperator` | `Comparison operator` |
| `Query.AddFilter.Tooltip` | `Add this filter to the query.` |
| `Query.AddFilter` | `Add filter` |
| `Query.RemoveGroup.Tooltip` | `Remove this grouping.` |
| `Query.RemoveGroup` | `Remove grouping` |
| `Query.GroupField.Tooltip` | `Choose the field to group by.` |
| `Query.GroupField` | `Grouping field` |
| `Query.GroupSort.Tooltip` | `Choose the grouping sort order.` |
| `Query.GroupSort` | `Grouping sort order` |
| `Query.AddGroup.Tooltip` | `Add this grouping to the query.` |
| `Query.AddGroup.Name` | `Add grouping` |
| `Query.MoveOutputUp.Tooltip` | `Move this column up.` |
| `Query.MoveOutputUp` | `Move column up` |
| `Query.MoveOutputDown.Tooltip` | `Move this column down.` |
| `Query.MoveOutputDown` | `Move column down` |
| `Query.RemoveOutput.Tooltip` | `Remove this column.` |
| `Query.RemoveOutput` | `Remove column` |
| `Query.OutputField.Tooltip` | `Choose the field to expose as a column.` |
| `Query.OutputField` | `Column field` |
| `Query.AddOutput.Tooltip` | `Add this column to the report.` |
| `Query.AddOutput` | `Add column` |

- [ ] **Step 4: Add the same 43 keys with AI-drafted translations**

Add each key to `Strings-de.xaml`, `Strings-es.xaml`, `Strings-ja.xaml`,
`Strings-pt-BR.xaml`, and `Strings-zh-Hans.xaml`. Follow each file's existing tone and
preserve the trailing periods of sentences. The visible labels are short (`Filters`,
`Groupings`, `Outputs`, `Query to edit`); the tooltips are full sentences.

- [ ] **Step 5: Add the attributes to every Query action control**

In `QueryView.xaml`, add `ToolTip` and `AutomationProperties.Name` using this mapping.
Existing names that already match stay as they are; the tooltips change where noted.

| Control | ToolTip key | AutomationProperties.Name key |
|---|---|---|
| Designer mode `ToggleButton` | `Query.Mode.Designer.Tooltip` | `Query.Mode.Designer` (unchanged) |
| SQL mode `ToggleButton` | `Query.Mode.Sql.Tooltip` | `Query.Mode.Sql` (unchanged) |
| Query selector `ComboBox` | `Query.SelectQuery.Tooltip` | `Query.SelectQuery.Name` (replaces `Query.SelectQuery`) |
| Filters `Button` | `Query.Filters.Tooltip` | `Query.Filters.Name` |
| Groups `Button` | `Query.Groups.Tooltip` | `Query.Groups.Name` |
| Outputs `Button` | `Query.Outputs.Tooltip` | `Query.Outputs.Name` |
| Arrange Tables `Button` | `Query.ArrangeTables.Tooltip` | `Query.ArrangeTables` |
| Revert SQL `Button` | `Query.RevertSql.Tooltip` | `Query.RevertSql` |
| Validate SQL `Button` | `Query.ValidateSql.Tooltip` | `Query.ValidateSql` |
| Compile & Apply SQL `Button` | `Query.ApplySql.Tooltip` | `Query.ApplySql` |
| Add table `Button` | `Query.AddTable.Tooltip` (replaces `Query.AddTable`) | `Query.AddTable` (unchanged) |
| Schema `ListBox` | `Query.SchemaList.Tooltip` | `Query.DatabaseTables` |
| Sources `ListBox` | `Query.SourcesList.Tooltip` | `Query.Sources` |
| Filter remove `Button` (`−`) | `Query.RemoveFilter.Tooltip` | `Query.RemoveFilter` |
| Filter field `ComboBox` | `Query.FilterField.Tooltip` | `Query.FilterField` |
| Filter operator `ComboBox` | `Query.FilterOperator.Tooltip` | `Query.FilterOperator` |
| Add filter `Button` | `Query.AddFilter.Tooltip` | `Query.AddFilter` |
| Group remove `Button` (`−`) | `Query.RemoveGroup.Tooltip` | `Query.RemoveGroup` |
| Group field `ComboBox` | `Query.GroupField.Tooltip` | `Query.GroupField` |
| Group sort `ComboBox` | `Query.GroupSort.Tooltip` | `Query.GroupSort` |
| Add group `Button` | `Query.AddGroup.Tooltip` | `Query.AddGroup.Name` |
| Output up `Button` (`↑`) | `Query.MoveOutputUp.Tooltip` | `Query.MoveOutputUp` |
| Output down `Button` (`↓`) | `Query.MoveOutputDown.Tooltip` | `Query.MoveOutputDown` |
| Output remove `Button` (`−`) | `Query.RemoveOutput.Tooltip` | `Query.RemoveOutput` |
| Output field `ComboBox` | `Query.OutputField.Tooltip` | `Query.OutputField` |
| Add output `Button` | `Query.AddOutput.Tooltip` | `Query.AddOutput` |

Example shape (the ToggleButton):

```xml
<ToggleButton Style="{StaticResource MAD.SegmentToggle}"
              Content="{infra:Loc Query.Mode.Designer}"
              IsChecked="{Binding DesignerSelected, Mode=TwoWay}"
              ToolTip="{infra:Loc Query.Mode.Designer.Tooltip}"
              AutomationProperties.Name="{infra:Loc Query.Mode.Designer}" />
```

Leave the two `TextBox` inputs (`FilterValue`, `NewOutputKey`) alone; they are labeled by
their editors and are outside this P0 convention.

- [ ] **Step 6: Raise the pinned English key count**

In `LocalizerTests.cs`, change `Assert.Equal(269, english.Count);` to
`Assert.Equal(312, english.Count);`.

- [ ] **Step 7: Run the Query gate and the localization gate**

```sh
dotnet test Windows/App/Mad.Designer.Windows.Tests --filter "FullyQualifiedName~TooltipConventionTests|FullyQualifiedName~LocalizerTests"
```

Expected: PASS — both `QueryView_GivesEveryActionControlATooltipAndAccessibleName` and
every `LocalizerTests` case. A failure names the missing attribute or dictionary key.

- [ ] **Step 8: Commit**

```sh
git add Windows/App/Mad.Designer.Windows.Tests/TooltipConventionTests.cs \
        Windows/App/Mad.Designer.Windows.Tests/LocalizerTests.cs \
        Windows/App/Mad.Designer.Windows/Views/QueryView.xaml \
        Windows/App/Mad.Designer.Windows/Resources/Strings-*.xaml
git commit -s -m "test(wpf): enforce tooltip and accessible names in the query workspace"
```

---

### Task 2: Designer workspace tooltips and accessible names

**Files:**
- Modify: `Windows/App/Mad.Designer.Windows.Tests/TooltipConventionTests.cs`
- Modify: `Windows/App/Mad.Designer.Windows/Views/DesignerView.xaml`
- Modify: all six `Windows/App/Mad.Designer.Windows/Resources/Strings-*.xaml`
- Modify: `Windows/App/Mad.Designer.Windows.Tests/LocalizerTests.cs:25`

**Interfaces:**
- Consumes: `AssertViewConforms(string fileName)` from Task 1.
- Produces: the 39 `Designer.*` keys in the table below.

- [ ] **Step 1: Add the failing Designer test**

Insert this fact in `TooltipConventionTests` immediately after the Query fact:

```csharp
    [Fact]
    public void DesignerView_GivesEveryActionControlATooltipAndAccessibleName()
        => AssertViewConforms("DesignerView.xaml");
```

- [ ] **Step 2: Run the test and confirm it fails**

```sh
dotnet test Windows/App/Mad.Designer.Windows.Tests --filter "FullyQualifiedName~TooltipConventionTests"
```

Expected: FAIL. The message lists `DesignerView.xaml` controls missing one or both
attributes: the six Insert buttons, the edit commands, both lists, the paper and band
pickers, the barcode controls, the typography toggles, the alignment pickers, the image
button, the inspector duplicate/delete buttons, and the status-bar zoom/grid/snap/rulers
controls.

- [ ] **Step 3: Add the 39 Designer keys to the English dictionary**

Add these entries to `Strings-en.xaml`, grouped near the existing `Designer.*` keys:

| Key | English text |
|---|---|
| `Designer.Label.Tooltip` | `Add a static text label to the selected band.` |
| `Designer.DataField.Tooltip` | `Add a query field bound to the selected band.` |
| `Designer.Aggregate.Tooltip` | `Add a summary aggregate to the selected band.` |
| `Designer.Image.Tooltip` | `Add an image to the selected band.` |
| `Designer.Line.Tooltip` | `Add a horizontal line rule to the selected band.` |
| `Designer.Barcode.Tooltip` | `Add a barcode bound to a query field or static text.` |
| `Designer.Undo.Tooltip` | `Undo the last change.` |
| `Designer.Redo.Tooltip` | `Redo the last undone change.` |
| `Designer.Duplicate.Tooltip` | `Duplicate the selected element.` |
| `Designer.Delete.Tooltip` | `Delete the selected element.` |
| `Designer.Bands.Name` | `Report bands` |
| `Designer.Bands.Tooltip` | `Double-click a band to show or hide it.` |
| `Designer.QueryFields.Name` | `Query fields` |
| `Designer.QueryFields.Tooltip` | `Double-click a field to add it to the selected band.` |
| `Designer.Paper.Tooltip` | `Choose the page size for the report.` |
| `Designer.ElementBand.Tooltip` | `Move the selected element to another band.` |
| `Designer.Barcode.Symbology.Tooltip` | `Choose the barcode symbology.` |
| `Designer.Barcode.ShowText.Tooltip` | `Print the encoded value below the barcode.` |
| `Designer.Barcode.Border.Tooltip` | `Choose how the barcode border is drawn.` |
| `Designer.Barcode.Field.Tooltip` | `Choose the static text or query field to encode.` |
| `Designer.Image.Choose.Tooltip` | `Choose a PNG or JPEG for this image element.` |
| `Designer.Bold` | `Bold` |
| `Designer.Bold.Tooltip` | `Make the text bold.` |
| `Designer.Italic` | `Italic` |
| `Designer.Italic.Tooltip` | `Italicize the text.` |
| `Designer.Underline` | `Underline` |
| `Designer.Underline.Tooltip` | `Underline the text.` |
| `Designer.Strikethrough` | `Strikethrough` |
| `Designer.Strikethrough.Tooltip` | `Strike through the text.` |
| `Designer.HAlign.Name` | `Horizontal alignment` |
| `Designer.HAlign.Tooltip` | `Choose the horizontal alignment.` |
| `Designer.VAlign.Name` | `Vertical alignment` |
| `Designer.VAlign.Tooltip` | `Choose the vertical alignment.` |
| `Designer.Zoom.Tooltip` | `Zoom the report canvas.` |
| `Designer.Grid.Tooltip` | `Show the design grid.` |
| `Designer.Snap.Tooltip` | `Snap elements to the grid.` |
| `Designer.Rulers.Tooltip` | `Show the page rulers.` |
| `Designer.SectionVisible.Tooltip` | `Include this band in the report.` |
| `Designer.PageBreakAfter.Tooltip` | `Start a new page after this band.` |

- [ ] **Step 4: Add the same 39 keys with AI-drafted translations**

Add each key to the five translation dictionaries, matching the existing tone and keeping
the sentence periods.

- [ ] **Step 5: Add the attributes to every Designer action control**

In `DesignerView.xaml`, add `ToolTip` and `AutomationProperties.Name` using this mapping.
Existing names that already match stay; existing tooltips that used the label key move to
the new `.Tooltip` key.

| Control | ToolTip key | AutomationProperties.Name key |
|---|---|---|
| Insert Label `Button` | `Designer.Label.Tooltip` | `Designer.Label` |
| Insert Data Field `Button` | `Designer.DataField.Tooltip` | `Designer.DataField` |
| Insert Aggregate `Button` | `Designer.Aggregate.Tooltip` | `Designer.Aggregate` |
| Insert Image `Button` | `Designer.Image.Tooltip` | `Designer.Image` |
| Insert Line `Button` | `Designer.Line.Tooltip` | `Designer.Line` |
| Insert Barcode `Button` | `Designer.Barcode.Tooltip` (replaces `Designer.Barcode`) | `Designer.Barcode` (unchanged) |
| Undo `Button` | `Designer.Undo.Tooltip` (replaces `Designer.Undo`) | `Designer.Undo` (unchanged) |
| Redo `Button` | `Designer.Redo.Tooltip` (replaces `Designer.Redo`) | `Designer.Redo` (unchanged) |
| Duplicate `Button` | `Designer.Duplicate.Tooltip` (replaces `Designer.Duplicate`) | `Designer.Duplicate` (unchanged) |
| Delete `Button` | `Designer.Delete.Tooltip` (replaces `Designer.Delete`) | `Designer.Delete` (unchanged) |
| Bands `ListBox` | `Designer.Bands.Tooltip` | `Designer.Bands.Name` |
| Query Fields `ListBox` | `Designer.QueryFields.Tooltip` | `Designer.QueryFields.Name` |
| Paper `ComboBox` | `Designer.Paper.Tooltip` | `Designer.Paper` |
| Element band `ComboBox` | `Designer.ElementBand.Tooltip` | `Designer.Band` |
| Barcode symbology `ComboBox` | `Designer.Barcode.Symbology.Tooltip` | `Designer.Barcode.Symbology` |
| Barcode Show text `CheckBox` | `Designer.Barcode.ShowText.Tooltip` | `Designer.Barcode.ShowText` |
| Barcode border `ComboBox` | `Designer.Barcode.Border.Tooltip` | `Designer.Barcode.Border` |
| Barcode input `ComboBox` | `Designer.Barcode.Field.Tooltip` | `Designer.Barcode.Field` |
| Choose Image `Button` | `Designer.Image.Choose.Tooltip` | `Designer.Image.Choose` |
| Bold `CheckBox` | `Designer.Bold.Tooltip` | `Designer.Bold` |
| Italic `CheckBox` | `Designer.Italic.Tooltip` | `Designer.Italic` |
| Underline `CheckBox` | `Designer.Underline.Tooltip` | `Designer.Underline` |
| Strikethrough `CheckBox` | `Designer.Strikethrough.Tooltip` | `Designer.Strikethrough` |
| H-Align `ComboBox` | `Designer.HAlign.Tooltip` | `Designer.HAlign.Name` |
| V-Align `ComboBox` | `Designer.VAlign.Tooltip` | `Designer.VAlign.Name` |
| Inspector Duplicate `Button` | `Designer.Duplicate.Tooltip` | `Designer.Duplicate` |
| Inspector Delete `Button` | `Designer.Delete.Tooltip` | `Designer.Delete` |
| Zoom `Slider` | `Designer.Zoom.Tooltip` | `Designer.Zoom` (already present) |
| Grid `CheckBox` | `Designer.Grid.Tooltip` | `Designer.Grid` |
| Snap `CheckBox` | `Designer.Snap.Tooltip` | `Designer.Snap` |
| Rulers `CheckBox` | `Designer.Rulers.Tooltip` | `Designer.Rulers` |
| Section Visible `CheckBox` | `Designer.SectionVisible.Tooltip` | `Designer.SectionVisible` |
| Page Break After `CheckBox` | `Designer.PageBreakAfter.Tooltip` | `Designer.PageBreakAfter` |

The B/I/U/S checkboxes keep their visible single-letter `Content`; the accessible name is
the full word, so a screen reader no longer says only "B".

- [ ] **Step 6: Raise the pinned English key count**

In `LocalizerTests.cs`, change `Assert.Equal(312, english.Count);` to
`Assert.Equal(351, english.Count);`.

- [ ] **Step 7: Run the Designer gate and the localization gate**

```sh
dotnet test Windows/App/Mad.Designer.Windows.Tests --filter "FullyQualifiedName~TooltipConventionTests|FullyQualifiedName~LocalizerTests"
```

Expected: PASS for both view facts and every dictionary case.

- [ ] **Step 8: Commit**

```sh
git add Windows/App/Mad.Designer.Windows.Tests/TooltipConventionTests.cs \
        Windows/App/Mad.Designer.Windows.Tests/LocalizerTests.cs \
        Windows/App/Mad.Designer.Windows/Views/DesignerView.xaml \
        Windows/App/Mad.Designer.Windows/Resources/Strings-*.xaml
git commit -s -m "test(wpf): enforce tooltip and accessible names in the designer workspace"
```

---

### Task 3: Query canvas tooltip defects

**Files:**
- Modify: `Windows/App/Mad.Designer.Windows/Views/QueryCanvas.cs`
- Modify: `Windows/App/Mad.Designer.Windows.Tests/QueryCanvasTests.cs`
- Modify: all six `Windows/App/Mad.Designer.Windows/Resources/Strings-*.xaml`
- Modify: `Windows/App/Mad.Designer.Windows.Tests/LocalizerTests.cs:25`

**Interfaces:**
- Consumes: `Localizer.Format(string, params object?[])`, the existing
  `QueryCanvasTests` engine fixture pattern.
- Produces: `Query.JoinBadge.Tooltip` (`{0}` join type, `{1}` left alias, `{2}` right
  alias) and `Query.FieldDrag.Tooltip`; a `private string AliasOf(long tableId)` helper in
  `QueryCanvas`.

- [ ] **Step 1: Write the failing canvas test**

Add this fact to `QueryCanvasTests`, using the same engine setup as
`CanvasRendersCardsAndLinks_ForTwoConnectedTables`:

```csharp
    [Fact]
    public async Task JoinBadgeAndFieldRow_ExplainTheirInteractions()
    {
        string sqlite = CopyChinookToTemp();
        string mad = Path.Combine(Path.GetTempPath(), $"mad-canvas-tip-{Guid.NewGuid():N}.mad");
        try
        {
            await using var service = new EngineService();
            var open = await service.CreateAsync(mad, new ConnectionSpec(
                ConnectionDriver.Sqlite3, sqlite, null, null, null, null, null, null));
            var describe = await service.DescribeAsync(open.Handle);

            var vm = new QueryViewModel(service);
            await vm.LoadAsync(open.Handle, describe.Driver, describe.Tables, 0);
            await vm.AddTableAsync("Customer");
            await vm.AddTableAsync("Invoice");
            var customer = vm.Tables.Single(t => t.Name == "Customer");
            var invoice = vm.Tables.Single(t => t.Name == "Invoice");
            await vm.ConnectFieldsAsync(
                customer.Fields.Single(f => f.Name == "CustomerId").Id,
                invoice.Fields.Single(f => f.Name == "CustomerId").Id);

            Exception? failure = null;
            string? badgeTip = null;
            string? fieldTip = null;

            var thread = new Thread(() =>
            {
                try
                {
                    var canvas = new QueryCanvas { Width = 900, Height = 700 };
                    canvas.Attach(vm);
                    canvas.Measure(new Size(900, 700));
                    canvas.Arrange(new Rect(0, 0, 900, 700));
                    canvas.UpdateLayout();

                    var badge = canvas.Children.OfType<Border>().FirstOrDefault(b => b.Tag is QueryLink);
                    badgeTip = badge is null ? null : ToolTipService.GetToolTip(badge) as string;

                    var card = canvas.Children.OfType<Border>().First(b => b.Tag is long);
                    var row = Descendants(card).OfType<Border>()
                        .First(b => b.Tag is long && Math.Abs(b.Height - 20.0) < 0.1);
                    fieldTip = ToolTipService.GetToolTip(row) as string;
                }
                catch (Exception ex)
                {
                    failure = ex;
                }
            });
            thread.SetApartmentState(ApartmentState.STA);
            thread.Start();
            thread.Join();

            Assert.Null(failure);
            Assert.False(string.IsNullOrWhiteSpace(badgeTip));
            Assert.False(string.IsNullOrWhiteSpace(fieldTip));
        }
        finally
        {
            if (File.Exists(sqlite)) File.Delete(sqlite);
            if (File.Exists(mad)) File.Delete(mad);
        }
    }

    private static IEnumerable<DependencyObject> Descendants(DependencyObject root)
    {
        int count = VisualTreeHelper.GetChildrenCount(root);
        for (int i = 0; i < count; i++)
        {
            DependencyObject child = VisualTreeHelper.GetChild(root, i);
            yield return child;
            foreach (DependencyObject descendant in Descendants(child)) yield return descendant;
        }
    }
```

`QueryCanvasTests.cs` already imports `System.Windows`, `System.Windows.Controls`, and
`System.Windows.Media`; `ToolTipService` is in `System.Windows.Controls`.

- [ ] **Step 2: Run the test and confirm it fails**

```sh
dotnet test Windows/App/Mad.Designer.Windows.Tests --filter "FullyQualifiedName~JoinBadgeAndFieldRow_ExplainTheirInteractions"
```

Expected: FAIL — `badgeTip` and `fieldTip` are both null (the curve carries the tooltip,
but the badge and the field row carry none).

- [ ] **Step 3: Add the two canvas keys to all six dictionaries**

| Key | English text |
|---|---|
| `Query.JoinBadge.Tooltip` | `{0} join between {1} and {2}. Click to change the join type.` |
| `Query.FieldDrag.Tooltip` | `Drag to another table's field to create a join.` |

Translate both into the five dictionaries. Keep the `{0}`, `{1}`, `{2}` placeholders in
`Query.JoinBadge.Tooltip` exactly; the localization test checks placeholder parity.

- [ ] **Step 4: Move the join tooltip to the badge and add the field hint**

In `QueryCanvas.DrawLinks`, remove `ToolTip = $"{link.Type.DisplayName()}",` from the
`Path` initializer and add the tooltip to the badge's `Border` initializer:

```csharp
                ToolTip = Localizer.Format(
                    "Query.JoinBadge.Tooltip", link.Type.DisplayName(), AliasOf(leftTable), AliasOf(rightTable)),
```

Add the helper near `TableOfField`:

```csharp
    private string AliasOf(long tableId)
        => _tablesById.TryGetValue(tableId, out QueryTable? table)
            ? (string.IsNullOrEmpty(table.Alias) ? table.Name : table.Alias)
            : "";
```

In `BuildFieldRow`, add the hint to the row's `Border` initializer:

```csharp
            ToolTip = Localizer.Get("Query.FieldDrag.Tooltip"),
```

- [ ] **Step 5: Raise the pinned English key count**

In `LocalizerTests.cs`, change `Assert.Equal(351, english.Count);` to
`Assert.Equal(353, english.Count);`.

- [ ] **Step 6: Run the canvas, convention, and localization gates**

```sh
dotnet test Windows/App/Mad.Designer.Windows.Tests --filter "FullyQualifiedName~QueryCanvasTests|FullyQualifiedName~TooltipConventionTests|FullyQualifiedName~LocalizerTests"
```

Expected: PASS — the new canvas fact, both view facts, and every dictionary case.

- [ ] **Step 7: Commit**

```sh
git add Windows/App/Mad.Designer.Windows/Views/QueryCanvas.cs \
        Windows/App/Mad.Designer.Windows.Tests/QueryCanvasTests.cs \
        Windows/App/Mad.Designer.Windows.Tests/LocalizerTests.cs \
        Windows/App/Mad.Designer.Windows/Resources/Strings-*.xaml
git commit -s -m "fix(wpf): show the join tooltip on the join badge and explain field dragging"
```

---

### Task 4: Record the completion and run the full suite

**Files:**
- Modify: `docs/project/design/MAD_WINDOWS_UI.md`

**Interfaces:**
- Consumes: the test names and keys from Tasks 1–3.
- Produces: the completed audit record; no code.

- [ ] **Step 1: Mark the P0 recommendation complete**

In `docs/project/design/MAD_WINDOWS_UI.md`, under the **P0 — Tooltip & automation-name
convention** heading, add this paragraph directly after the heading:

```markdown
**Complete (2026-11-25).** The Query and Designer workspaces now give every `Button`,
`ToggleButton`, `CheckBox`, `ComboBox`, `ListBox`, and `Slider` a localized `ToolTip`
(the task explanation) and a separate localized `AutomationProperties.Name` (the short
spoken label). `TooltipConventionTests` reads both XAML sources and fails with a
file/line list when either is missing or not localized. The five insert commands, the
mode toggles, the query selector, both sidebars, the popup editors, the barcode and
typography controls, and the canvas-view controls are covered. The join-type tooltip
moved from the non-hit-testable curve to its midpoint badge, and query fields now
explain the drag-to-join gesture.
```

- [ ] **Step 2: Record the follow-ups found**

At the end of `docs/project/design/MAD_WINDOWS_UI.md`, add:

```markdown
## Follow-ups found while completing P0 (2026-11-25)

- The element inspector's `Border T / B / L / R` boxes are four unlabeled numeric
  fields. They need accessible names and clearer individual labels.
- The Bands list's double-click toggles section visibility. That is a surprising
  gesture for a list; a visible checkbox or context menu would be more discoverable.
- The remaining P1/P2 items in this audit — command-bar grouping, in-place empty
  states, unified feedback, and general canvas hover tooltips — are still open.
- Composition-facing presentation stays with Report 2 (`MAD_COMPOSITION_UX.md`).
```

- [ ] **Step 3: Run the full WPF suite**

```sh
dotnet test Windows/App/Mad.Designer.Windows.Tests
```

Expected: PASS. The suite includes `ShellSurfaceTests` (loads the views), `SmokeTests`
(engine exports), the new convention tests, and the localization gate.

- [ ] **Step 4: Commit the documentation, design, and plan**

```sh
git add docs/project/design/MAD_WINDOWS_UI.md \
        docs/superpowers/specs/2026-11-25-windows-tooltip-convention-design.md \
        docs/superpowers/plans/2026-11-25-windows-tooltip-convention.md
git commit -s -m "docs: record the Windows P0 tooltip convention"
```

- [ ] **Step 5: Push the branch**

```sh
git push
```

No pull request and no merge; those are the user's direction.

---

## Self-Review

- **Spec coverage:** Convention (Tasks 1–2), the static XAML gate (Tasks 1–2), the two
  same-defect canvas fixes (Task 3), localization and the pinned count (Tasks 1–3), and
  the completion record + follow-ups (Task 4) all map to tasks. The four border boxes,
  the Bands double-click, and the P1/P2 items are deliberately recorded, not built.
- **Step scan:** Each step names one action and one checkable result. The copy tables pin
  the exact English; the implementer writes the translations and the XAML edits.
- **Type consistency:** `AssertViewConforms(string fileName)` is defined in Task 1 and used
  in Task 2; `AliasOf(long tableId)` is defined and used in Task 3; the counts 312 / 351 /
  353 match the key counts 43 / 39 / 2 added to the 269 baseline.
- **Review Focus:** Each line is pinned by a task test (popup coverage in the XAML scan,
  dictionary completeness in `LocalizerTests`, both attributes in the same scan, the badge
  in `JoinBadgeAndFieldRow_ExplainTheirInteractions`, and the Bands copy in the exact
  English table).
- **Proportion:** The code is small; the document is long because the copy and control
  inventory are the decisions an implementer cannot invent.
