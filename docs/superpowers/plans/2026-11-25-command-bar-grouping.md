# Command-Bar Grouping Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the Designer's six-button insert palette with one Insert menu that opens a styled, grouped submenu; group the Query commands under a Refine caption and move Arrange Tables to the status bar; fix the Barcode/Duplicate glyph collision.

**Architecture:** A single top-level `MenuItem` styled as a command button, with a custom `MenuItem` template for the submenu rows; two captured group captions and a styled separator. The Query change is layout-only. A structural XAML gate plus a 912 px layout test pin the result.

**Tech Stack:** WPF (`net10.0-windows`), XAML resource dictionaries and control templates, xUnit, the existing `Localizer` keys.

**Spec:** `docs/superpowers/specs/2026-11-25-command-bar-grouping-design.md`

## Global Constraints

- Every new UI string goes into all six dictionaries: `Resources/Strings-en.xaml`, `-de`, `-es`, `-ja`, `-pt-BR`, `-zh-Hans`. English is authoritative; translations are AI-drafted per D14.
- Bump the pinned English key count in `LocalizerTests.EveryShippedDictionary_HasEveryEnglishKey` from `355` to `360`.
- Do not change `Localizer` behaviour.
- The tooltip gate now covers `MenuItem` as well as the existing action controls, except disabled caption items (`IsEnabled="False"`).
- No command behaviour changes; every insert keeps its existing command and localized name/tooltip.
- No composition presentation work (Report 2).
- Full suite: `dotnet test Windows/App/Mad.Designer.Windows.Tests`. UI-only; no engine rebuild.
- Commits and push are authorised by the user for this task; never open a PR or merge.

## Review Focus

- **Window minimum width (1000 px)** — the Designer bar must not clip; the Insert button and the whole Edit group stay inside the bar.
- **Keyboard-only use** — Tab to Insert, Enter/Down opens, arrows move, Esc closes; the WPF Menu supplies this, but the manual check confirms it.
- **Screen reader** — the Insert menu and every enabled item carry a localized accessible name and tooltip.
- **High contrast / dark theme** — the menu surface, captions, and hover rows must use theme brushes and stay readable.
- **Popup placement** — the submenu opens below Insert and remains fully on-screen at the minimum window width.

---

### Task 1: Add the five grouping strings to all six dictionaries

**Files:**
- Modify: `Windows/App/Mad.Designer.Windows/Resources/Strings-en.xaml:322`
- Modify: `Windows/App/Mad.Designer.Windows/Resources/Strings-de.xaml:322`
- Modify: `Windows/App/Mad.Designer.Windows/Resources/Strings-es.xaml:322`
- Modify: `Windows/App/Mad.Designer.Windows/Resources/Strings-ja.xaml:322`
- Modify: `Windows/App/Mad.Designer.Windows/Resources/Strings-pt-BR.xaml:322`
- Modify: `Windows/App/Mad.Designer.Windows/Resources/Strings-zh-Hans.xaml:322`
- Test: `Windows/App/Mad.Designer.Windows.Tests/LocalizerTests.cs:73-80`

**Interfaces:**
- Produces: `Designer.Insert.Tooltip`, `Designer.Edit`, `Query.Refine`, `Designer.Insert.Text`, `Designer.Insert.Graphics` for Tasks 2 and 3.

- [ ] **Step 1: Write the failing copy pins**

In `LocalizerTests.English_IsTheSourceAndTheDefault`, after the two `Document.Type*` assertions, add:

```csharp
Assert.Equal("Add an element to the selected band.", Localizer.Get("Designer.Insert.Tooltip"));
Assert.Equal("Edit", Localizer.Get("Designer.Edit"));
Assert.Equal("Refine", Localizer.Get("Query.Refine"));
Assert.Equal("Text", Localizer.Get("Designer.Insert.Text"));
Assert.Equal("Graphics", Localizer.Get("Designer.Insert.Graphics"));
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `dotnet test Windows/App/Mad.Designer.Windows.Tests --filter "FullyQualifiedName~LocalizerTests.English_IsTheSourceAndTheDefault"`
Expected: FAIL — the keys fall back to themselves.

- [ ] **Step 3: Add the keys to every dictionary**

After the two `Document.Type*.Tooltip` lines in each dictionary, add these values:

| File | Insert.Tooltip | Edit | Refine | Insert.Text | Insert.Graphics |
|---|---|---|---|---|---|
| en | Add an element to the selected band. | Edit | Refine | Text | Graphics |
| de | Fügt dem ausgewählten Bereich ein Element hinzu. | Bearbeiten | Verfeinern | Text | Grafik |
| es | Agrega un elemento a la banda seleccionada. | Editar | Refinar | Texto | Gráficos |
| ja | 選択したバンドに要素を追加します。 | 編集 | 絞り込み | テキスト | グラフィック |
| pt-BR | Adiciona um elemento à faixa selecionada. | Editar | Refinar | Texto | Gráficos |
| zh-Hans | 将元素添加到所选区域。 | 编辑 | 细化 | 文本 | 图形 |

Shape (two-space indentation):

```xml
  <sys:String x:Key="Designer.Insert.Tooltip">Add an element to the selected band.</sys:String>
  <sys:String x:Key="Designer.Edit">Edit</sys:String>
  <sys:String x:Key="Query.Refine">Refine</sys:String>
  <sys:String x:Key="Designer.Insert.Text">Text</sys:String>
  <sys:String x:Key="Designer.Insert.Graphics">Graphics</sys:String>
```

- [ ] **Step 4: Bump the pinned English count**

In `LocalizerTests.EveryShippedDictionary_HasEveryEnglishKey`, change `Assert.Equal(355, english.Count);` to `Assert.Equal(360, english.Count);`.

- [ ] **Step 5: Run the localization suite to verify it passes**

Run: `dotnet test Windows/App/Mad.Designer.Windows.Tests --filter "FullyQualifiedName~LocalizerTests"`
Expected: PASS.

---

### Task 2: Replace the Designer insert palette with the Insert menu

**Files:**
- Modify: `Windows/App/Mad.Designer.Windows/Themes/Theme.xaml` (after `MAD.CommandLabel`, around line 308)
- Modify: `Windows/App/Mad.Designer.Windows/Views/DesignerView.xaml:24-111`
- Modify: `Windows/App/Mad.Designer.Windows.Tests/TooltipConventionTests.cs:19-22, 46-50`
- Test: `Windows/App/Mad.Designer.Windows.Tests/CommandBarTests.cs` (create)

**Interfaces:**
- Consumes: the five keys from Task 1; `Designer.Label.Tooltip`/`Designer.DataField.Tooltip`/`Designer.Aggregate.Tooltip`/`Designer.Image.Tooltip`/`Designer.Line.Tooltip`/`Designer.Barcode.Tooltip` (existing).
- Produces: style keys `MAD.GroupCaption`, `MAD.InsertMenu`, `MAD.InsertMenuItem`, `MAD.InsertMenuCaption`, `MAD.MenuGroupCaption`, `MAD.MenuSeparator`; named elements `CommandBar`, `InsertButton` (a `MenuItem`), `EditGroup`.

- [ ] **Step 1: Write the failing structural and layout tests**

Create `CommandBarTests.cs`:

```csharp
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using System.IO;
using System.Threading;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using System.Xml.Linq;
using Mad.Designer.Windows.Infrastructure;
using Mad.Designer.Windows.Views;

namespace Mad.Designer.Windows.Tests;

/// <summary>The P1 command-bar grouping: the Designer inserts live behind one styled
/// Insert menu, the bars carry Edit/Refine captions, the glyphs are distinct, and the
/// Designer bar fits at the window's minimum width. The structural checks read the XAML;
/// the layout check hosts the real view at the content width of a 1000 px window.</summary>
public sealed class CommandBarTests
{
    private static readonly XNamespace P =
        "http://schemas.microsoft.com/winfx/2006/xaml/presentation";
    private static readonly XNamespace X =
        "http://schemas.microsoft.com/winfx/2006/xaml";

    private static readonly string[] InsertCommands =
    {
        "AddLabelCommand", "AddDataFieldCommand", "AddAggregateCommand",
        "AddImageCommand", "AddLineRuleCommand", "AddBarcodeCommand",
    };

    private static XDocument Load(string view) =>
        XDocument.Load(
            Path.Combine(MadPathResolver.RepoRoot(), "Windows", "App", "Mad.Designer.Windows", "Views", view),
            LoadOptions.SetLineInfo);

    private static XElement Bar(XDocument document) => document.Descendants(P + "Border")
        .Single(b => ((string?)b.Attribute("Style"))?.Contains("MAD.CommandBar") == true);

    private static bool HasCommand(XElement element, string command) =>
        ((string?)element.Attribute("Command"))?.Contains(command) == true;

    [Fact]
    public void Designer_HasOneInsertMenuAndTheSixInsertsLiveInItsSubmenu()
    {
        XDocument document = Load("DesignerView.xaml");
        XElement bar = Bar(document);

        XElement insert = bar.Descendants(P + "MenuItem")
            .Single(m => (string?)m.Attribute(X + "Name") == "InsertButton");
        Assert.NotNull(insert.Attribute("ToolTip"));
        Assert.NotNull(insert.Attribute("AutomationProperties.Name"));

        foreach (string command in InsertCommands)
        {
            Assert.DoesNotContain(bar.Descendants(P + "Button"), b => HasCommand(b, command));
            Assert.Contains(insert.Descendants(P + "MenuItem"), m => HasCommand(m, command));
        }
    }

    [Fact]
    public void Designer_InsertItemsAreLocalizedAndGrouped()
    {
        XDocument document = Load("DesignerView.xaml");
        XElement insert = document.Descendants(P + "MenuItem")
            .Single(m => (string?)m.Attribute(X + "Name") == "InsertButton");

        var rows = insert.Descendants(P + "MenuItem")
            .Where(m => (string?)m.Attribute("Command") is not null)
            .ToList();
        Assert.Equal(6, rows.Count);
        Assert.All(rows, row =>
        {
            Assert.Contains("{infra:Loc", (string?)row.Attribute("ToolTip"));
            Assert.Contains("{infra:Loc", (string?)row.Attribute("AutomationProperties.Name"));
        });

        Assert.Contains(insert.Descendants(P + "TextBlock"),
            t => (string?)t.Attribute("Text") == "{infra:Loc Designer.Insert.Text}");
        Assert.Contains(insert.Descendants(P + "TextBlock"),
            t => (string?)t.Attribute("Text") == "{infra:Loc Designer.Insert.Graphics}");
    }

    [Fact]
    public void Designer_BarcodeAndDuplicateUseDistinctGlyphs()
    {
        XDocument document = Load("DesignerView.xaml");

        string GlyphFor(string command)
        {
            XElement owner = document.Descendants()
                .Single(e => (e.Name == P + "MenuItem" || e.Name == P + "Button") && HasCommand(e, command));
            return (string)owner.Descendants(P + "TextBlock").First().Attribute("Text")!;
        }

        Assert.Equal(0xEC5A, (int)GlyphFor("AddBarcodeCommand")[0]);
        Assert.Equal(0xE8C8, (int)GlyphFor("DuplicateElementCommand")[0]);
    }

    [Fact]
    public void Designer_HasAnEditCaption()
    {
        XDocument document = Load("DesignerView.xaml");
        Assert.Contains(document.Descendants(P + "TextBlock"),
            t => (string?)t.Attribute("Text") == "{infra:Loc Designer.Edit}");
    }

    [Fact]
    public void Theme_DefinesTheGroupingStyles()
    {
        XDocument theme = XDocument.Load(Path.Combine(
            MadPathResolver.RepoRoot(), "Windows", "App", "Mad.Designer.Windows", "Themes", "Theme.xaml"));
        foreach (string key in new[]
        {
            "MAD.GroupCaption", "MAD.InsertMenu", "MAD.InsertMenuItem",
            "MAD.InsertMenuCaption", "MAD.MenuGroupCaption", "MAD.MenuSeparator",
        })
        {
            Assert.Contains(theme.Descendants(P + "Style"), s => (string?)s.Attribute(X + "Key") == key);
        }
    }

    [Fact]
    public void DesignerCommandBar_FitsItsGroupsAtTheWindowMinimum()
    {
        Exception? failure = null;
        var thread = new Thread(() =>
        {
            try
            {
                var view = new DesignerView { Width = 912, Height = 600 };
                view.Measure(new Size(912, 600));
                view.Arrange(new Rect(0, 0, 912, 600));
                view.UpdateLayout();

                var bar = (Border)view.FindName("CommandBar")!;
                var insert = (MenuItem)view.FindName("InsertButton")!;
                var edit = (StackPanel)view.FindName("EditGroup")!;

                Point insertOrigin = insert.TransformToAncestor(bar).Transform(new Point(0, 0));
                Point editOrigin = edit.TransformToAncestor(bar).Transform(new Point(0, 0));

                Assert.True(insert.ActualWidth > 0, "the Insert menu has no width");
                Assert.True(edit.ActualWidth > 0, "the Edit group has no width");
                Assert.True(editOrigin.X >= insertOrigin.X + insert.ActualWidth,
                    "the Edit group overlaps the Insert menu (the old clipped-Undo bug)");
                Assert.True(editOrigin.X + edit.ActualWidth <= bar.ActualWidth + 0.5,
                    "the Edit group overflows the bar");
            }
            catch (Exception exception)
            {
                failure = exception;
            }
        });
        thread.SetApartmentState(ApartmentState.STA);
        thread.Start();
        thread.Join();
        Assert.Null(failure);
    }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `dotnet test Windows/App/Mad.Designer.Windows.Tests --filter "FullyQualifiedName~CommandBarTests"`
Expected: FAIL — no grouping styles, no Insert menu, no named elements.

- [ ] **Step 3: Add the grouping styles to `Theme.xaml`**

After `MAD.CommandLabel`, add:

```xml
<Style x:Key="MAD.GroupCaption" TargetType="TextBlock">
    <Setter Property="FontSize" Value="{StaticResource MAD.FontSize.Caption}" />
    <Setter Property="FontWeight" Value="SemiBold" />
    <Setter Property="Foreground" Value="{DynamicResource TextFillColorSecondaryBrush}" />
    <Setter Property="VerticalAlignment" Value="Center" />
    <Setter Property="Margin" Value="2,0,8,0" />
</Style>

<Style x:Key="MAD.InsertMenu" TargetType="MenuItem">
    <Setter Property="Foreground" Value="{DynamicResource TextFillColorPrimaryBrush}" />
    <Setter Property="Template">
        <Setter.Value>
            <ControlTemplate TargetType="MenuItem">
                <Grid>
                    <Border x:Name="Chrome" Background="Transparent"
                            CornerRadius="{StaticResource MAD.CornerRadius.Control}" Padding="10,5">
                        <ContentPresenter ContentSource="Header" VerticalAlignment="Center" />
                    </Border>
                    <Popup x:Name="PART_Popup" Placement="Bottom" AllowsTransparency="True" Focusable="False"
                           IsOpen="{TemplateBinding IsSubmenuOpen}"
                           PlacementTarget="{Binding RelativeSource={RelativeSource TemplatedParent}}">
                        <Border Style="{DynamicResource MAD.PopupSurface}" Width="230" Padding="6" Margin="0,2,0,0">
                            <ScrollViewer VerticalScrollBarVisibility="Auto">
                                <ItemsPresenter />
                            </ScrollViewer>
                        </Border>
                    </Popup>
                </Grid>
                <ControlTemplate.Triggers>
                    <Trigger Property="IsHighlighted" Value="True">
                        <Setter TargetName="Chrome" Property="Background" Value="{DynamicResource SubtleFillColorSecondaryBrush}" />
                    </Trigger>
                    <Trigger Property="IsSubmenuOpen" Value="True">
                        <Setter TargetName="Chrome" Property="Background" Value="{DynamicResource SubtleFillColorTertiaryBrush}" />
                    </Trigger>
                </ControlTemplate.Triggers>
            </ControlTemplate>
        </Setter.Value>
    </Setter>
</Style>

<Style x:Key="MAD.InsertMenuItem" TargetType="MenuItem">
    <Setter Property="Foreground" Value="{DynamicResource TextFillColorPrimaryBrush}" />
    <Setter Property="Template">
        <Setter.Value>
            <ControlTemplate TargetType="MenuItem">
                <Border x:Name="Chrome" Background="Transparent"
                        CornerRadius="{StaticResource MAD.CornerRadius.Control}" Padding="10,7">
                    <ContentPresenter ContentSource="Header" VerticalAlignment="Center" />
                </Border>
                <ControlTemplate.Triggers>
                    <Trigger Property="IsHighlighted" Value="True">
                        <Setter TargetName="Chrome" Property="Background" Value="{DynamicResource SubtleFillColorSecondaryBrush}" />
                    </Trigger>
                </ControlTemplate.Triggers>
            </ControlTemplate>
        </Setter.Value>
    </Setter>
</Style>

<Style x:Key="MAD.InsertMenuCaption" TargetType="MenuItem" BasedOn="{StaticResource MAD.InsertMenuItem}">
    <Setter Property="IsEnabled" Value="False" />
    <Setter Property="Focusable" Value="False" />
    <Setter Property="IsHitTestVisible" Value="False" />
</Style>

<Style x:Key="MAD.MenuGroupCaption" TargetType="TextBlock">
    <Setter Property="FontSize" Value="{StaticResource MAD.FontSize.Caption}" />
    <Setter Property="FontWeight" Value="SemiBold" />
    <Setter Property="Foreground" Value="{DynamicResource TextFillColorSecondaryBrush}" />
    <Setter Property="Margin" Value="10,6,10,2" />
</Style>

<Style x:Key="MAD.MenuSeparator" TargetType="Separator">
    <Setter Property="Template">
        <Setter.Value>
            <ControlTemplate TargetType="Separator">
                <Border Height="1" Margin="6,4" Background="{DynamicResource DividerStrokeColorDefaultBrush}" />
            </ControlTemplate>
        </Setter.Value>
    </Setter>
</Style>
```

- [ ] **Step 4: Restructure the Designer command bar**

In `DesignerView.xaml`, add `x:Name="CommandBar"` to the row-0 command-bar `Border`. Replace the left insert palette (lines 26-77) with:

```xml
<StackPanel Orientation="Horizontal" DockPanel.Dock="Left">
    <Menu Background="Transparent" Padding="0" VerticalAlignment="Center">
        <MenuItem x:Name="InsertButton" Style="{StaticResource MAD.InsertMenu}"
                  ToolTip="{infra:Loc Designer.Insert.Tooltip}"
                  AutomationProperties.Name="{infra:Loc Designer.Insert}">
            <MenuItem.Header>
                <StackPanel Orientation="Horizontal">
                    <TextBlock Text="&#xE710;" Style="{StaticResource MAD.CommandIcon}" />
                    <TextBlock Text="{infra:Loc Designer.Insert}" Style="{StaticResource MAD.CommandLabel}" />
                    <TextBlock Text="&#xE70D;" Style="{StaticResource MAD.CommandIcon}" FontSize="10" Margin="5,1,0,0" />
                </StackPanel>
            </MenuItem.Header>
            <MenuItem Style="{StaticResource MAD.InsertMenuCaption}">
                <MenuItem.Header>
                    <TextBlock Text="{infra:Loc Designer.Insert.Text}" Style="{StaticResource MAD.MenuGroupCaption}" />
                </MenuItem.Header>
            </MenuItem>
            <MenuItem Style="{StaticResource MAD.InsertMenuItem}" Command="{Binding AddLabelCommand}"
                      ToolTip="{infra:Loc Designer.Label.Tooltip}" AutomationProperties.Name="{infra:Loc Designer.Label}">
                <MenuItem.Header>
                    <StackPanel Orientation="Horizontal">
                        <TextBlock Text="&#xE8D2;" Style="{StaticResource MAD.CommandIcon}" Width="20" TextAlignment="Center" />
                        <TextBlock Text="{infra:Loc Designer.Label}" Style="{StaticResource MAD.CommandLabel}" />
                    </StackPanel>
                </MenuItem.Header>
            </MenuItem>
            <MenuItem Style="{StaticResource MAD.InsertMenuItem}" Command="{Binding AddDataFieldCommand}"
                      ToolTip="{infra:Loc Designer.DataField.Tooltip}" AutomationProperties.Name="{infra:Loc Designer.DataField}">
                <MenuItem.Header>
                    <StackPanel Orientation="Horizontal">
                        <TextBlock Text="&#xE7C3;" Style="{StaticResource MAD.CommandIcon}" Width="20" TextAlignment="Center" />
                        <TextBlock Text="{infra:Loc Designer.DataField}" Style="{StaticResource MAD.CommandLabel}" />
                    </StackPanel>
                </MenuItem.Header>
            </MenuItem>
            <MenuItem Style="{StaticResource MAD.InsertMenuItem}" Command="{Binding AddAggregateCommand}"
                      ToolTip="{infra:Loc Designer.Aggregate.Tooltip}" AutomationProperties.Name="{infra:Loc Designer.Aggregate}">
                <MenuItem.Header>
                    <StackPanel Orientation="Horizontal">
                        <TextBlock Text="&#xE9D9;" Style="{StaticResource MAD.CommandIcon}" Width="20" TextAlignment="Center" />
                        <TextBlock Text="{infra:Loc Designer.Aggregate}" Style="{StaticResource MAD.CommandLabel}" />
                    </StackPanel>
                </MenuItem.Header>
            </MenuItem>
            <Separator Style="{StaticResource MAD.MenuSeparator}" />
            <MenuItem Style="{StaticResource MAD.InsertMenuCaption}">
                <MenuItem.Header>
                    <TextBlock Text="{infra:Loc Designer.Insert.Graphics}" Style="{StaticResource MAD.MenuGroupCaption}" />
                </MenuItem.Header>
            </MenuItem>
            <MenuItem Style="{StaticResource MAD.InsertMenuItem}" Command="{Binding AddImageCommand}"
                      ToolTip="{infra:Loc Designer.Image.Tooltip}" AutomationProperties.Name="{infra:Loc Designer.Image}">
                <MenuItem.Header>
                    <StackPanel Orientation="Horizontal">
                        <TextBlock Text="&#xE91B;" Style="{StaticResource MAD.CommandIcon}" Width="20" TextAlignment="Center" />
                        <TextBlock Text="{infra:Loc Designer.Image}" Style="{StaticResource MAD.CommandLabel}" />
                    </StackPanel>
                </MenuItem.Header>
            </MenuItem>
            <MenuItem Style="{StaticResource MAD.InsertMenuItem}" Command="{Binding AddLineRuleCommand}"
                      ToolTip="{infra:Loc Designer.Line.Tooltip}" AutomationProperties.Name="{infra:Loc Designer.Line}">
                <MenuItem.Header>
                    <StackPanel Orientation="Horizontal">
                        <TextBlock Text="&#xE738;" Style="{StaticResource MAD.CommandIcon}" Width="20" TextAlignment="Center" />
                        <TextBlock Text="{infra:Loc Designer.Line}" Style="{StaticResource MAD.CommandLabel}" />
                    </StackPanel>
                </MenuItem.Header>
            </MenuItem>
            <MenuItem Style="{StaticResource MAD.InsertMenuItem}" Command="{Binding AddBarcodeCommand}"
                      ToolTip="{infra:Loc Designer.Barcode.Tooltip}" AutomationProperties.Name="{infra:Loc Designer.Barcode}">
                <MenuItem.Header>
                    <StackPanel Orientation="Horizontal">
                        <TextBlock Text="&#xEC5A;" Style="{StaticResource MAD.CommandIcon}" Width="20" TextAlignment="Center" />
                        <TextBlock Text="{infra:Loc Designer.Barcode}" Style="{StaticResource MAD.CommandLabel}" />
                    </StackPanel>
                </MenuItem.Header>
            </MenuItem>
        </MenuItem>
    </Menu>
</StackPanel>
```

On the right group, add `x:Name="EditGroup"` and put the Edit caption after the divider:

```xml
<StackPanel x:Name="EditGroup" Orientation="Horizontal" DockPanel.Dock="Right" HorizontalAlignment="Right">
    <Border Style="{StaticResource MAD.Divider}" />
    <TextBlock Text="{infra:Loc Designer.Edit}" Style="{StaticResource MAD.GroupCaption}" />
    <!-- Undo, Redo, Duplicate, Delete buttons unchanged, with Duplicate's glyph left at E8C8 -->
</StackPanel>
```

- [ ] **Step 5: Extend the tooltip gate to menu items**

In `TooltipConventionTests.cs`, add `"MenuItem"` to `ActionControls`, and skip caption items:

```csharp
if (!ActionControls.Contains(element.Name.LocalName)) continue;
if (element.Name.LocalName == "MenuItem" && (string?)element.Attribute("IsEnabled") == "False") continue;
```

- [ ] **Step 6: Run the grouping and tooltip tests to verify they pass**

Run: `dotnet test Windows/App/Mad.Designer.Windows.Tests --filter "FullyQualifiedName~CommandBarTests|FullyQualifiedName~TooltipConventionTests"`
Expected: PASS.

- [ ] **Step 7: Run the full suite**

Run: `dotnet test Windows/App/Mad.Designer.Windows.Tests`
Expected: PASS (137 tests: 131 existing + 6 CommandBarTests).

---

### Task 3: Group the Query bar and move Arrange Tables

**Files:**
- Modify: `Windows/App/Mad.Designer.Windows/Views/QueryView.xaml:51-86, 221-240`
- Test: `Windows/App/Mad.Designer.Windows.Tests/CommandBarTests.cs` (extend)

**Interfaces:**
- Consumes: `Query.Refine` from Task 1; `MAD.GroupCaption` from Task 2.

- [ ] **Step 1: Write the failing Query test**

Append to `CommandBarTests`:

```csharp
[Fact]
public void Query_HasARefineCaptionAndArrangeTablesInTheStatusBar()
{
    XDocument document = Load("QueryView.xaml");

    Assert.Contains(document.Descendants(P + "TextBlock"),
        t => (string?)t.Attribute("Text") == "{infra:Loc Query.Refine}");

    Assert.DoesNotContain(Bar(document).Descendants(P + "Button"),
        b => HasCommand(b, "ArrangeTablesCommand"));

    XElement status = document.Descendants(P + "Border")
        .Single(b => ((string?)b.Attribute("Style"))?.Contains("MAD.StatusBar") == true);
    Assert.Contains(status.Descendants(P + "Button"), b => HasCommand(b, "ArrangeTablesCommand"));
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `dotnet test Windows/App/Mad.Designer.Windows.Tests --filter "FullyQualifiedName~Query_HasARefineCaptionAndArrangeTablesInTheStatusBar"`
Expected: FAIL — no Refine caption; Arrange Tables is still in the bar.

- [ ] **Step 3: Add the Refine caption and move Arrange Tables**

In the Designer-mode command group, insert before the Filters button:

```xml
<TextBlock Text="{infra:Loc Query.Refine}" Style="{StaticResource MAD.GroupCaption}" />
```

Remove the trailing `<Border Style="{StaticResource MAD.Divider}" />` and the Arrange Tables button from the command bar (lines 77-85). In the status bar's right-hand `StackPanel`, after the Fit button, add:

```xml
<Border Style="{StaticResource MAD.Divider}" />
<Button Style="{StaticResource MAD.CommandButton}" Margin="6,0,0,0"
        Command="{Binding ArrangeTablesCommand}"
        ToolTip="{infra:Loc Query.ArrangeTables.Tooltip}"
        AutomationProperties.Name="{infra:Loc Query.ArrangeTables}">
    <StackPanel Orientation="Horizontal">
        <TextBlock Text="&#xE80A;" Style="{StaticResource MAD.CommandIcon}" />
        <TextBlock Text="{infra:Loc Query.ArrangeTables}" Style="{StaticResource MAD.CommandLabel}" />
    </StackPanel>
</Button>
```

- [ ] **Step 4: Run the Query test and the full suite**

Run: `dotnet test Windows/App/Mad.Designer.Windows.Tests --filter "FullyQualifiedName~Query_HasARefineCaptionAndArrangeTablesInTheStatusBar"`
Expected: PASS.
Run: `dotnet test Windows/App/Mad.Designer.Windows.Tests`
Expected: PASS (138 tests).

---

### Task 4: Record the audit progress, verify visually, commit and push

**Files:**
- Modify: `docs/project/design/MAD_WINDOWS_UI.md` (the P1 command-bar item)

- [ ] **Step 1: Update the audit record**

Mark the P1 command-bar item complete (2026-11-25): one Insert menu with Text/Graphics groups, the Edit caption, the Refine caption, Arrange Tables moved to the Query status bar, and the Barcode/Duplicate glyph fix. Record the owner's follow-up: the remaining button surfaces (main-window toolbar, inspector's Duplicate/Delete) may get the same treatment later; not part of this item.

- [ ] **Step 2: Capture the result at the window minimum**

Run the app with `CLI/Fixtures/London.portable.mad`, switch to Designer, resize to 1000x720, and capture the bar; open the Insert menu and capture it; switch to Query and capture the bar and status bar. Check: no clipping, the menu is fully on-screen, both captions read correctly, rows highlight, and the glyphs differ. Tune only row padding, popup width, or separator margins if needed.

- [ ] **Step 3: Run the full suite one last time**

Run: `dotnet test Windows/App/Mad.Designer.Windows.Tests`
Expected: PASS, 138 tests.

- [ ] **Step 4: Commit and push (authorised by the user)**

```bash
git add \
  Windows/App/Mad.Designer.Windows/Resources/Strings-en.xaml \
  Windows/App/Mad.Designer.Windows/Resources/Strings-de.xaml \
  Windows/App/Mad.Designer.Windows/Resources/Strings-es.xaml \
  Windows/App/Mad.Designer.Windows/Resources/Strings-ja.xaml \
  Windows/App/Mad.Designer.Windows/Resources/Strings-pt-BR.xaml \
  Windows/App/Mad.Designer.Windows/Resources/Strings-zh-Hans.xaml \
  Windows/App/Mad.Designer.Windows/Themes/Theme.xaml \
  Windows/App/Mad.Designer.Windows/Views/DesignerView.xaml \
  Windows/App/Mad.Designer.Windows/Views/QueryView.xaml \
  Windows/App/Mad.Designer.Windows.Tests/LocalizerTests.cs \
  Windows/App/Mad.Designer.Windows.Tests/TooltipConventionTests.cs \
  Windows/App/Mad.Designer.Windows.Tests/CommandBarTests.cs \
  docs/project/design/MAD_WINDOWS_UI.md \
  docs/superpowers/specs/2026-11-25-command-bar-grouping-design.md \
  docs/superpowers/plans/2026-11-25-command-bar-grouping.md
git commit -s -m "feat(wpf): group the command bars behind an Insert menu" -m "The Designer's six insert buttons become one Insert menu with Text and Graphics groups; the bars gain Edit and Refine captions; Arrange Tables moves to the Query status bar; the Barcode glyph no longer reuses the Duplicate copy icon. A structural gate and a 912 px layout test pin the grouping and the minimum-width fit."
git push
```

Do not open a PR or merge.
