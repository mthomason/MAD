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
        Assert.Equal("8,0,8,4", setters["Padding"]);
        Assert.Equal("{StaticResource MAD.FontSize.Secondary}", setters["TextElement.FontSize"]);
        Assert.Equal("SemiBold", setters["TextElement.FontWeight"]);
    }
}
