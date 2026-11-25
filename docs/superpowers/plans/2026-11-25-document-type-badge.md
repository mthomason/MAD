# Document-Type Badge Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the quiet document-type text in the main command bar with a visible pill badge next to the filename — neutral for a standard report, accent for a composition — with a localized per-type tooltip.

**Architecture:** Add a neutral `MAD.DocumentTypeBadge` `Border` style to `Theme.xaml`; in `MainWindow.xaml` replace the type `TextBlock` with a named `Border` you can test structurally, layering a view-level `DataTrigger` on `Document.IsComposed` for the accent pair. Add a `DocumentTypeTooltip` computed property to `DocumentViewModel` parallel to the existing `DocumentTypeText`.

**Tech Stack:** WPF (`net10.0-windows`), XAML resource dictionaries, xUnit, existing `Localizer` keys.

**Spec:** `docs/superpowers/specs/2026-11-25-document-type-badge-design.md`

## Global Constraints

- Every new UI string goes into all six dictionaries: `Resources/Strings-en.xaml`, `-de`, `-es`, `-ja`, `-pt-BR`, `-zh-Hans`. English is authoritative; translations are AI-drafted per D14.
- Bump the pinned English key count in `LocalizerTests.EveryShippedDictionary_HasEveryEnglishKey` from `353` to `355`.
- Do not change `Localizer` behaviour.
- No composition first-run guidance — that is Report 2's (`MAD_COMPOSITION_UX.md`). The tooltip is descriptive only.
- Do not extend `TooltipConventionTests`; its Query/Designer scope is deliberate. The badge is informational, not an action control.
- No engine rebuild; UI-only work. Verify with `dotnet test Windows/App/Mad.Designer.Windows.Tests`.
- Commits only when the user asks, with `git commit -s` (DCO). Never open a PR or merge.
- Keep the existing "Standard Report" / "Composition Report" badge text (existing keys).

## Review Focus

- **No document open** — the badge must be hidden, not show a stale type.
- **Standard report** — the badge must be neutral, never accent.
- **Composition report** — accent background with the on-accent foreground must stay legible in light, dark, and high contrast.
- **A long filename** — the trimmed filename must not push the badge out of view.
- **Non-English language** — the tooltip must resolve from each dictionary; a missing key must not crash the badge.

---

### Task 1: Add the two tooltip keys to all six dictionaries

**Files:**
- Modify: `Windows/App/Mad.Designer.Windows/Resources/Strings-en.xaml:322`
- Modify: `Windows/App/Mad.Designer.Windows/Resources/Strings-de.xaml:322`
- Modify: `Windows/App/Mad.Designer.Windows/Resources/Strings-es.xaml:322`
- Modify: `Windows/App/Mad.Designer.Windows/Resources/Strings-ja.xaml:322`
- Modify: `Windows/App/Mad.Designer.Windows/Resources/Strings-pt-BR.xaml:322`
- Modify: `Windows/App/Mad.Designer.Windows/Resources/Strings-zh-Hans.xaml:322`
- Test: `Windows/App/Mad.Designer.Windows.Tests/LocalizerTests.cs:73-78`

**Interfaces:**
- Produces: `Document.TypeStandard.Tooltip`, `Document.TypeComposition.Tooltip` (string keys) for Task 2.

- [ ] **Step 1: Write the failing copy pins**

In `LocalizerTests.English_IsTheSourceAndTheDefault`, after the `Viewer.PageSize` assertion, add:

```csharp
Assert.Equal("This report queries one database.", Localizer.Get("Document.TypeStandard.Tooltip"));
Assert.Equal("This report combines reports imported as sources.", Localizer.Get("Document.TypeComposition.Tooltip"));
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `dotnet test Windows/App/Mad.Designer.Windows.Tests --filter "FullyQualifiedName~LocalizerTests.English_IsTheSourceAndTheDefault"`
Expected: FAIL — the key falls back to itself.

- [ ] **Step 3: Add both keys to every dictionary**

Immediately after each dictionary's `Document.TypeComposition` line (line 322), add the two keys. Use these exact values:

| File | `Document.TypeStandard.Tooltip` | `Document.TypeComposition.Tooltip` |
|---|---|---|
| en | This report queries one database. | This report combines reports imported as sources. |
| de | Dieser Bericht fragt eine Datenbank ab. | Dieser Bericht kombiniert als Quellen importierte Berichte. |
| es | Este informe consulta una base de datos. | Este informe combina informes importados como orígenes. |
| ja | このレポートは1つのデータベースにクエリを実行します。 | このレポートはソースとしてインポートしたレポートを結合します。 |
| pt-BR | Este relatório consulta um banco de dados. | Este relatório combina relatórios importados como fontes. |
| zh-Hans | 此报表查询一个数据库。 | 此报表合并作为源导入的报表。 |

Shape (same two-space indentation as the neighbouring keys):

```xml
  <sys:String x:Key="Document.TypeStandard.Tooltip">This report queries one database.</sys:String>
  <sys:String x:Key="Document.TypeComposition.Tooltip">This report combines reports imported as sources.</sys:String>
```

- [ ] **Step 4: Bump the pinned English count**

In `LocalizerTests.EveryShippedDictionary_HasEveryEnglishKey`, change `Assert.Equal(353, english.Count);` to `Assert.Equal(355, english.Count);`.

- [ ] **Step 5: Run the localization suite to verify it passes**

Run: `dotnet test Windows/App/Mad.Designer.Windows.Tests --filter "FullyQualifiedName~LocalizerTests"`
Expected: PASS (all LocalizerTests).

---

### Task 2: Expose `DocumentTypeTooltip` on the document view model

**Files:**
- Modify: `Windows/App/Mad.Designer.Windows/ViewModels/DocumentViewModel.cs:152-154`, `:220`, `:284`
- Test: `Windows/App/Mad.Designer.Windows.Tests/CompositionAcceptanceTests.cs:156-166`

**Interfaces:**
- Consumes: the two keys from Task 1.
- Produces: `public string DocumentViewModel.DocumentTypeTooltip { get; }`; raises `PropertyChanged` whenever `DocumentTypeText` is raised.

- [ ] **Step 1: Write the failing assertions**

In `CompositionAcceptanceTests.ConvertStandardReport_ProducesAComposition`, after `Assert.False(document.IsComposed);` (line 158) add:

```csharp
Assert.Equal(Localizer.Get("Document.TypeStandard.Tooltip"), document.DocumentTypeTooltip);
```

and after the existing `Assert.True(document.IsComposed);` (line 161) add:

```csharp
Assert.Equal(Localizer.Get("Document.TypeComposition.Tooltip"), document.DocumentTypeTooltip);
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `dotnet test Windows/App/Mad.Designer.Windows.Tests --filter "FullyQualifiedName~ConvertStandardReport_ProducesAComposition"`
Expected: build FAILS — `DocumentViewModel` has no `DocumentTypeTooltip`.

- [ ] **Step 3: Add the property**

Directly below `DocumentTypeText` (line 154) in `DocumentViewModel.cs`:

```csharp
/// <summary>The localized tooltip for the document-type badge: a description of the type
/// currently shown, never an instruction.</summary>
public string DocumentTypeTooltip
    => IsComposed ? Localizer.Get("Document.TypeComposition.Tooltip") : Localizer.Get("Document.TypeStandard.Tooltip");
```

Add `OnPropertyChanged(nameof(DocumentTypeTooltip));` next to both existing `OnPropertyChanged(nameof(DocumentTypeText));` calls — in `LoadAsync` (line 220) and `ReloadDocumentInfoAsync` (line 284).

- [ ] **Step 4: Run the test to verify it passes**

Run: `dotnet test Windows/App/Mad.Designer.Windows.Tests --filter "FullyQualifiedName~ConvertStandardReport_ProducesAComposition"`
Expected: PASS.

---

### Task 3: Add the badge style and replace the type text in the window

**Files:**
- Modify: `Windows/App/Mad.Designer.Windows/Themes/Theme.xaml:115` (after `MAD.Card`)
- Modify: `Windows/App/Mad.Designer.Windows/MainWindow.xaml:88-90`
- Test: `Windows/App/Mad.Designer.Windows.Tests/DocumentTypeBadgeTests.cs` (create)

**Interfaces:**
- Consumes: `MAD.CornerRadius.Pill`, `MAD.FontSize.Secondary`, Fluent brushes; `Document.DocumentTypeText`, `Document.DocumentTypeTooltip`, `Document.IsComposed`, `Document.HasDocument`.
- Produces: style key `MAD.DocumentTypeBadge`; element `x:Name="DocumentTypeBadge"`.

- [ ] **Step 1: Write the failing structural test**

Create `DocumentTypeBadgeTests.cs`:

```csharp
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using System.IO;
using System.Xml.Linq;
using Mad.Designer.Windows.Infrastructure;

namespace Mad.Designer.Windows.Tests;

/// <summary>The document-type badge: MainWindow replaces the small type text with a pill
/// next to the filename, neutral for a standard report and accent for a composition. The
/// check reads the XAML so a missing binding or trigger fails here, not in a window.</summary>
public sealed class DocumentTypeBadgeTests
{
    private static readonly XNamespace P =
        "http://schemas.microsoft.com/winfx/2006/xaml/presentation";
    private static readonly XNamespace X =
        "http://schemas.microsoft.com/winfx/2006/xaml";

    private static XDocument Load(params string[] relative) =>
        XDocument.Load(
            Path.Combine(MadPathResolver.RepoRoot(), Path.Combine(relative)),
            LoadOptions.SetLineInfo);

    private static XDocument Window => Load("Windows", "App", "Mad.Designer.Windows", "MainWindow.xaml");
    private static XDocument Theme => Load("Windows", "App", "Mad.Designer.Windows", "Themes", "Theme.xaml");

    private static XElement Badge => Window.Descendants()
        .Single(e => (string?)e.Attribute(X + "Name") == "DocumentTypeBadge");

    [Fact]
    public void MainWindow_BindsTheBadgeToTheDocumentAndHidesItWithoutOne()
    {
        Assert.Equal(P + "Border", Badge.Name);
        Assert.Contains("Document.HasDocument", (string?)Badge.Attribute("Visibility"));
        Assert.Contains("BoolToVis", (string?)Badge.Attribute("Visibility"));
        Assert.Equal("{Binding Document.DocumentTypeTooltip}", (string?)Badge.Attribute("ToolTip"));

        XElement text = Badge.Elements(P + "TextBlock").Single();
        Assert.Equal("{Binding Document.DocumentTypeText}", (string?)text.Attribute("Text"));
    }

    [Fact]
    public void MainWindow_KeepsTheBadgeAfterATrimmedFileName()
    {
        XElement name = Badge.ElementsBeforeSelf(P + "TextBlock").Last();
        Assert.Equal("{Binding Document.FileName}", (string?)name.Attribute("Text"));
        Assert.Equal("420", (string?)name.Attribute("MaxWidth"));
    }

    [Fact]
    public void MainWindow_SwitchesToTheAccentPairForAComposition()
    {
        XElement style = Badge.Element(P + "Border.Style")!.Element(P + "Style")!;
        Assert.Equal("{StaticResource MAD.DocumentTypeBadge}", (string?)style.Attribute("BasedOn"));

        XElement trigger = style.Descendants(P + "DataTrigger")
            .Single(t => (string?)t.Attribute("Value") == "True");
        Assert.Equal("{Binding Document.IsComposed}", (string?)trigger.Attribute("Binding"));

        var setters = trigger.Elements(P + "Setter").ToList();
        Assert.Contains(setters, s => (string?)s.Attribute("Property") == "Background"
            && ((string?)s.Attribute("Value"))!.Contains("AccentFillColorDefaultBrush"));
        Assert.Contains(setters, s => (string?)s.Attribute("Property") == "TextElement.Foreground"
            && ((string?)s.Attribute("Value"))!.Contains("TextOnAccentFillColorPrimaryBrush"));
    }

    [Fact]
    public void Theme_DefinesTheNeutralPill()
    {
        XElement style = Theme.Descendants(P + "Style")
            .Single(s => (string?)s.Attribute(X + "Key") == "MAD.DocumentTypeBadge");
        Assert.Equal("Border", (string?)style.Attribute("TargetType"));

        var setters = style.Elements(P + "Setter")
            .ToDictionary(s => (string)s.Attribute("Property")!, s => (string?)s.Attribute("Value"));
        Assert.Equal("{DynamicResource SubtleFillColorSecondaryBrush}", setters["Background"]);
        Assert.Equal("{DynamicResource TextFillColorPrimaryBrush}", setters["TextElement.Foreground"]);
        Assert.Equal("{StaticResource MAD.CornerRadius.Pill}", setters["CornerRadius"]);
        Assert.Equal("8,2", setters["Padding"]);
        Assert.Equal("{StaticResource MAD.FontSize.Secondary}", setters["TextElement.FontSize"]);
        Assert.Equal("SemiBold", setters["TextElement.FontWeight"]);
    }
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `dotnet test Windows/App/Mad.Designer.Windows.Tests --filter "FullyQualifiedName~DocumentTypeBadgeTests"`
Expected: FAIL — no `DocumentTypeBadge` element and no theme style.

- [ ] **Step 3: Add the neutral pill style to `Theme.xaml`**

After the `MAD.Card` style (around line 115) and before `MAD.CommandBar`, add:

```xml
<Style x:Key="MAD.DocumentTypeBadge" TargetType="Border">
    <Setter Property="Background" Value="{DynamicResource SubtleFillColorSecondaryBrush}" />
    <Setter Property="CornerRadius" Value="{StaticResource MAD.CornerRadius.Pill}" />
    <Setter Property="Padding" Value="8,2" />
    <Setter Property="TextElement.Foreground" Value="{DynamicResource TextFillColorPrimaryBrush}" />
    <Setter Property="TextElement.FontSize" Value="{StaticResource MAD.FontSize.Secondary}" />
    <Setter Property="TextElement.FontWeight" Value="SemiBold" />
</Style>
```

- [ ] **Step 4: Replace the type text with the badge in `MainWindow.xaml`**

Replace lines 88-90 (the `DocumentTypeText` `TextBlock`) with:

```xml
<Border x:Name="DocumentTypeBadge" Margin="8,0,0,0" VerticalAlignment="Center"
        ToolTip="{Binding Document.DocumentTypeTooltip}"
        Visibility="{Binding Document.HasDocument, Converter={StaticResource BoolToVis}}">
    <Border.Style>
        <Style TargetType="Border" BasedOn="{StaticResource MAD.DocumentTypeBadge}">
            <Style.Triggers>
                <DataTrigger Binding="{Binding Document.IsComposed}" Value="True">
                    <Setter Property="Background" Value="{DynamicResource AccentFillColorDefaultBrush}" />
                    <Setter Property="TextElement.Foreground" Value="{DynamicResource TextOnAccentFillColorPrimaryBrush}" />
                </DataTrigger>
            </Style.Triggers>
        </Style>
    </Border.Style>
    <TextBlock Text="{Binding Document.DocumentTypeText}" />
</Border>
```

Do not add `AutomationProperties.Name` to the `Border`: it is not an action control, and the `TextBlock` text is exposed to assistive technology naturally.

- [ ] **Step 5: Run the badge test to verify it passes**

Run: `dotnet test Windows/App/Mad.Designer.Windows.Tests --filter "FullyQualifiedName~DocumentTypeBadgeTests"`
Expected: PASS (4 tests).

- [ ] **Step 6: Run the full suite**

Run: `dotnet test Windows/App/Mad.Designer.Windows.Tests`
Expected: PASS, 131 tests (127 existing + 4 badge tests; the two modified tests change assertions, not counts).

---

### Task 4: Record the audit progress and verify visually

**Files:**
- Modify: `docs/project/design/MAD_WINDOWS_UI.md:59-63`

**Interfaces:**
- Consumes: everything above.

- [ ] **Step 1: Update the audit record**

Under "P0 — Make the document type and its next action explicit.", record that the badge portion is complete (2026-11-25): the pill next to the filename, neutral/accent, per-type tooltip, and `DocumentTypeBadgeTests` pinning it. State that the composition first-run hint still waits for Report 2 (`MAD_COMPOSITION_UX.md`).

- [ ] **Step 2: Ask the user for a screenshot**

Ask the user to run the app and share a screenshot of a standard report and a composition in light and dark themes. Check: pill shape, neutral vs accent, on-accent text legibility, badge still visible beside a long filename. Tune only `Padding` / `MAD.FontSize.Secondary` if needed; the brush pair is fixed by the design.

- [ ] **Step 3: Commit only on the user's word**

If the user asks to commit, stage the six dictionaries, `LocalizerTests.cs`, `DocumentViewModel.cs`, `CompositionAcceptanceTests.cs`, `Theme.xaml`, `MainWindow.xaml`, `DocumentTypeBadgeTests.cs`, the audit record, the design (`docs/superpowers/specs/2026-11-25-document-type-badge-design.md`), and this plan, then `git commit -s`. Do not push, open a PR, or merge unless told.
