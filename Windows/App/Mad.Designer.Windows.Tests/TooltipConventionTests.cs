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
        "Button", "ToggleButton", "CheckBox", "ComboBox", "ListBox", "Slider", "MenuItem",
    };

    [Fact]
    public void QueryView_GivesEveryActionControlATooltipAndAccessibleName()
        => AssertViewConforms("QueryView.xaml");

    [Fact]
    public void DesignerView_GivesEveryActionControlATooltipAndAccessibleName()
        => AssertViewConforms("DesignerView.xaml");

    private static void AssertViewConforms(string fileName)
    {
        string path = Path.Combine(
            MadPathResolver.RepoRoot(), "Windows", "App", "Mad.Designer.Windows", "Views", fileName);
        XDocument document = XDocument.Load(path, LoadOptions.SetLineInfo);
        XNamespace presentation = "http://schemas.microsoft.com/winfx/2006/xaml/presentation";

        var failures = new List<string>();
        foreach (XElement element in document.Descendants())
        {
            if (element.Name.Namespace != presentation) continue;
            if (!ActionControls.Contains(element.Name.LocalName)) continue;
            // A disabled menu item is a group caption, not an action.
            if (element.Name.LocalName == "MenuItem" && (string?)element.Attribute("IsEnabled") == "False") continue;

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
