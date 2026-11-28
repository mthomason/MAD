//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using System.IO;
using System.Threading;
using System.Windows.Controls;
using System.Xml.Linq;
using Mad.Designer.Windows.Infrastructure;
using Mad.Designer.Windows.Views;

namespace Mad.Designer.Windows.Tests;

/// <summary>The remaining Report 1 polish: the bands context menu and its hidden-band disabled
/// appearance, the individually labelled border boxes, the workspace empty-state hints, and the
/// status-bar error surfaces. Read from the XAML sources, matching the other surface gates.</summary>
public sealed class DesignerPolishTests
{
    private static readonly XNamespace P =
        "http://schemas.microsoft.com/winfx/2006/xaml/presentation";
    private static readonly XNamespace X =
        "http://schemas.microsoft.com/winfx/2006/xaml";

    private static XDocument Load(string view) =>
        XDocument.Load(
            Path.Combine(MadPathResolver.RepoRoot(), "Windows", "App", "Mad.Designer.Windows", "Views", view),
            LoadOptions.SetLineInfo);

    private static XElement SectionsList => Load("DesignerView.xaml").Descendants(P + "ListBox")
        .Single(e => (string?)e.Attribute(X + "Name") == "SectionsList");

    [Fact]
    public void BandsList_OffersASelectAndVisibilityContextMenu()
    {
        XElement? menu = SectionsList.Element(P + "ListBox.ContextMenu")?.Element(P + "ContextMenu");
        Assert.NotNull(menu);

        var items = menu!.Elements(P + "MenuItem").ToList();
        Assert.Contains(items, i => (string?)i.Attribute("Click") == "SelectSection_OnClick");
        Assert.Contains(items, i => (string?)i.Attribute("Click") == "ToggleSectionVisibility_OnClick");
        Assert.All(items, item =>
        {
            Assert.Contains("{infra:Loc", (string?)item.Attribute("ToolTip"));
            Assert.Contains("{infra:Loc", (string?)item.Attribute("AutomationProperties.Name"));
        });
    }

    [Fact]
    public void HiddenBands_RenderAsDisabledButStayInTheList()
    {
        XElement trigger = SectionsList.Descendants(P + "DataTrigger")
            .Single(t => (string?)t.Attribute("Binding") == "{Binding Visible}");
        Assert.Equal("False", (string?)trigger.Attribute("Value"));
        Assert.Contains(trigger.Elements(P + "Setter"), s =>
            (string?)s.Attribute("Property") == "Foreground" &&
            ((string?)s.Attribute("Value"))!.Contains("TextFillColorDisabledBrush"));
    }

    [Fact]
    public void BorderBoxes_CarryLocalizedAccessibleNamesAndTooltips()
    {
        XDocument document = Load("DesignerView.xaml");
        foreach (string key in new[]
        {
            "Designer.Border.Top.Name", "Designer.Border.Bottom.Name",
            "Designer.Border.Left.Name", "Designer.Border.Right.Name",
        })
        {
            Assert.Contains(document.Descendants(P + "TextBox"),
                box => ((string?)box.Attribute("AutomationProperties.Name"))?.Contains(key) == true);
        }

        Assert.Equal(4, document.Descendants(P + "TextBox")
            .Count(box => ((string?)box.Attribute("ToolTip"))?.Contains("Designer.Border") == true));
    }

    [Fact]
    public void DesignerView_LoadsAndAttachesTheBandsContextMenu()
    {
        Exception? failure = null;
        var thread = new Thread(() =>
        {
            try
            {
                var view = new DesignerView();
                var list = (ListBox)view.FindName("SectionsList")!;
                Assert.NotNull(list.ContextMenu);
                Assert.Equal(2, list.ContextMenu!.Items.OfType<MenuItem>().Count());
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

    [Fact]
    public void Workspaces_ShowEmptyHintsAndStatusBarErrors()
    {
        XDocument query = Load("QueryView.xaml");
        Assert.Contains(query.Descendants(P + "TextBlock"),
            t => (string?)t.Attribute("Text") == "{infra:Loc Query.SchemaEmpty}");
        Assert.Contains(query.Descendants(P + "TextBlock"),
            t => (string?)t.Attribute("Text") == "{Binding ErrorText}");

        XDocument designer = Load("DesignerView.xaml");
        Assert.Contains(designer.Descendants(P + "TextBlock"),
            t => (string?)t.Attribute("Text") == "{infra:Loc Designer.FieldsEmpty}");
        Assert.Contains(designer.Descendants(P + "TextBlock"),
            t => (string?)t.Attribute("Text") == "{Binding ErrorText}");
    }
}
