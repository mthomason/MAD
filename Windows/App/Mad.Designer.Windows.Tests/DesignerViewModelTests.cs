//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using System.Windows;
using Mad.Designer.Windows.Engine;
using Mad.Designer.Windows.Models;
using Mad.Designer.Windows.ViewModels;

namespace Mad.Designer.Windows.Tests;

/// <summary>Pure layout logic of the Designer workspace — the non-overlap placement the
/// palette and double-click use, so three inserts never stack at (0,0) — plus the field-list
/// caption, which follows the selected node's kind.</summary>
public sealed class DesignerViewModelTests
{
    [Fact]
    public void FieldsCaption_FollowsTheSelectedNodeKind()
    {
        var vm = new DesignerViewModel(new EngineService());

        // A leaf (a source, or a Standard Report's single query) lists query fields.
        Assert.Equal("QUERY FIELDS (DRAG TO CANVAS)", vm.FieldsCaption);

        // A composing node (the Result or a nested composer) lists the columns it exposes.
        vm.SelectedNodeComposing = true;
        Assert.Equal("REPORT COLUMNS (DRAG TO CANVAS)", vm.FieldsCaption);

        vm.SelectedNodeComposing = false;
        Assert.Equal("QUERY FIELDS (DRAG TO CANVAS)", vm.FieldsCaption);
    }

    [Fact]
    public void NextAvailableOrigin_EmptySection_ReturnsDefault()
    {
        var origin = DesignerViewModel.NextAvailableOrigin(
            Array.Empty<LayoutElement>(), sectionId: 5, w: 120, h: 22, gridSpacing: 8, snap: true);

        Assert.Equal(16.0, origin.X);
        Assert.Equal(10.0, origin.Y);
    }

    [Fact]
    public void NextAvailableOrigin_DoesNotOverlapExisting()
    {
        var existing = new LayoutElement(
            Id: 101, Type: ElementType.LabelStatic, Section: 5, X: 16, Y: 10, W: 120, H: 22,
            Text: "Static Label", Field: 0, Table: "", Column: "",
            Function: AggregateFunction.Unknown, Scope: AggregateScope.Unknown, Group: 0,
            FontName: "Helvetica", FontSize: 12, Bold: false, Italic: false, Underline: false, Strikethrough: false,
            HAlign: ElementHAlign.Left, VAlign: ElementVAlign.Top,
            BorderTop: 0, BorderBottom: 0, BorderLeft: 0, BorderRight: 0, Padding: 0, Margin: 0);

        var origin = DesignerViewModel.NextAvailableOrigin(
            new[] { existing }, sectionId: 5, w: 120, h: 22, gridSpacing: 8, snap: true);

        var newRect = new Rect(origin.X, origin.Y, 120, 22);
        var existingRect = new Rect(16, 10, 120, 22);

        Assert.False(newRect.IntersectsWith(existingRect));
    }
}
