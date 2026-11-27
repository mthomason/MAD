//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using System.IO;
using System.Xml.Linq;
using Mad.Designer.Windows.Infrastructure;

namespace Mad.Designer.Windows.Tests;

/// <summary>The Composition pane's shell contract: a real column with a splitter beside the
/// workspace, hidden for a Standard Report, an Expand affordance, an Import entry point, and a
/// single Component picker that stays visible when the pane is collapsed. Reads the XAML so a
/// dropped binding fails here rather than in a window.</summary>
public sealed class CompositionPaneTests
{
    private static readonly XNamespace P = "http://schemas.microsoft.com/winfx/2006/xaml/presentation";
    private static readonly XNamespace X = "http://schemas.microsoft.com/winfx/2006/xaml";

    private static XDocument Load(params string[] relative) =>
        XDocument.Load(
            Path.Combine(MadPathResolver.RepoRoot(), Path.Combine(relative)),
            LoadOptions.SetLineInfo);

    private static XDocument Window => Load("Windows", "App", "Mad.Designer.Windows", "MainWindow.xaml");
    private static XDocument QueryView => Load("Windows", "App", "Mad.Designer.Windows", "Views", "QueryView.xaml");

    private static XElement Named(XDocument document, string name) =>
        document.Descendants().Single(e => (string?)e.Attribute(X + "Name") == name);

    [Fact]
    public void MainWindow_DocksThePaneBesideTheWorkspaceWithASplitter()
    {
        Assert.Equal("0", (string?)Named(Window, "CompositionColumn").Attribute("Width"));
        Assert.Equal("0", (string?)Named(Window, "CompositionSplitterColumn").Attribute("Width"));
        Assert.Equal("*", (string?)Named(Window, "WorkspaceColumn").Attribute("Width"));

        XElement splitter = Named(Window, "CompositionSplitter");
        Assert.Equal(P + "GridSplitter", splitter.Name);
        Assert.Contains("Document.IsComposed", (string?)splitter.Attribute("Visibility"));
    }

    [Fact]
    public void MainWindow_ShowsThePaneAndItsEmptyStateOnlyForAComposition()
    {
        XElement pane = Named(Window, "CompositionPane");
        Assert.Contains("Document.IsComposed", (string?)pane.Attribute("Visibility"));
        Assert.Contains("BoolToVis", (string?)pane.Attribute("Visibility"));

        XElement empty = Named(Window, "CompositionEmptyState");
        Assert.Contains("Document.Composition.ShowEmptyState", (string?)empty.Attribute("Visibility"));

        XElement graph = Window.Descendants().Single(e => e.Name.LocalName == "CompositionGraphView");
        Assert.Equal("{Binding Document.Composition}", (string?)graph.Attribute("Composition"));
        Assert.Contains("Document.Composition.ShowGraph", (string?)
            Named(Window, "CompositionScroll").Attribute("Visibility"));
    }

    [Fact]
    public void MainWindow_ProvidesExpandCollapseAndImportInThePaneHeader()
    {
        XElement expand = Named(Window, "CompositionExpandButton");
        Assert.Equal("CompositionExpand_Click", (string?)expand.Attribute("Click"));
        Assert.Equal("{Binding Document.Composition.ExpandTooltip}", (string?)expand.Attribute("ToolTip"));
        Assert.Equal("{Binding Document.Composition.ExpandName}", (string?)expand.Attribute("AutomationProperties.Name"));

        XElement pane = Named(Window, "CompositionPane");
        Assert.Contains(pane.Descendants(P + "Button"),
            b => (string?)b.Attribute("Command") == "{Binding ImportChildCommand}");
    }

    [Fact]
    public void MainWindow_HasOneComponentPickerSharedAcrossWorkspaces()
    {
        XElement picker = Window.Descendants(P + "ComboBox")
            .Single(c => (string?)c.Attribute("ItemsSource") == "{Binding Document.ComponentOptions}");

        Assert.Equal("{Binding Document.SelectedQueryId, Mode=TwoWay}", (string?)picker.Attribute("SelectedValue"));
        Assert.Equal("Id", (string?)picker.Attribute("SelectedValuePath"));
        Assert.Equal("Display", (string?)picker.Attribute("DisplayMemberPath"));
        Assert.Contains("Document.IsComposed", (string?)
            picker.Ancestors(P + "Border").First().Attribute("Visibility"));

        // The Query workspace's old per-workspace selector is gone; the pane and the picker
        // now drive the one document-level selection.
        Assert.DoesNotContain(QueryView.Descendants(P + "ComboBox"),
            c => (string?)c.Attribute("ItemsSource") == "{Binding Queries}");
    }

    [Fact]
    public void MainWindow_HasNoInterimSourceWorkspaceNotice()
    {
        // Every node is a report, so the shell no longer explains away a workspace that would
        // show the Result for a source: the notice and its binding are gone.
        Assert.DoesNotContain(Window.Descendants(),
            e => (string?)e.Attribute(X + "Name") == "SourceWorkspaceNotice");
        Assert.DoesNotContain(Window.Descendants(),
            e => ((string?)e.Attribute("Visibility") ?? "").Contains("ShowSourceWorkspaceNotice"));
    }
}
