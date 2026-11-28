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
            // The inspector repeats the Duplicate command without an icon; the command-bar
            // buttons are the ones with icon TextBlocks.
            XElement owner = document.Descendants()
                .Where(e => (e.Name == P + "MenuItem" || e.Name == P + "Button") && HasCommand(e, command))
                .Single(e => e.Descendants(P + "TextBlock").Any());
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

    [Fact]
    public void Query_ArrangeTablesIsVisibleOnlyInDesignerMode()
    {
        XDocument document = Load("QueryView.xaml");
        XElement status = document.Descendants(P + "Border")
            .Single(b => ((string?)b.Attribute("Style"))?.Contains("MAD.StatusBar") == true);
        XElement arrange = status.Descendants(P + "Button")
            .Single(b => HasCommand(b, "ArrangeTablesCommand"));

        // The button, or a container inside the status bar, must carry the Designer gate;
        // moving it to the status bar must not leak it into SQL mode.
        bool gated = false;
        for (XElement? element = arrange; element is not null && element != status; element = element.Parent)
        {
            string? visibility = (string?)element.Attribute("Visibility");
            if (visibility is not null && visibility.Contains("IsDesigner"))
            {
                gated = true;
                break;
            }
        }
        Assert.True(gated, "Arrange Tables must appear only in Designer mode");
    }
}
