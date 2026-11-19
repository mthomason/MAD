//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using System.Text.Json;
using Mad.Designer.Windows.Models;

namespace Mad.Designer.Windows.Tests;

/// <summary>Covers the report-layout model snapshot parser — the C# mirror of the engine's
/// <c>layout-model</c> wire shape (<see cref="LayoutModel.Parse"/>).</summary>
public sealed class LayoutModelTests
{
    [Fact]
    public void Parse_ReadsAllFields()
    {
        const string json = """
        {
          "paperSize": 19,
          "sections": [
            { "id": 1, "type": 1, "title": "Report Header", "height": 60.0, "visible": true, "pageBreak": false, "groupField": null }
          ],
          "elements": [
            {
              "id": 101, "type": 1, "section": 1,
              "x": 10.5, "y": 20.25, "w": 124.0, "h": 22.0,
              "text": "Static Label",
              "field": 0, "table": "", "column": "",
              "function": 0, "scope": 0, "group": 0,
              "fontname": "Helvetica", "fontsize": 12.0,
              "bold": false, "italic": false, "underline": false, "strikethrough": false,
              "hAlign": 0, "vAlign": 1,
              "borderTop": 0.0, "borderBottom": 0.0, "borderLeft": 0.0, "borderRight": 0.0,
              "padding": 2.0, "margin": 0.0
            }
          ],
          "fields": [
            { "id": 5001, "name": "CustomerId", "table": "Customer", "display": "Customer.CustomerId" }
          ]
        }
        """;

        var model = LayoutModel.Parse(JsonDocument.Parse(json).RootElement);

        Assert.Equal(PaperSize.A4, (PaperSize)model.PaperSize);

        var section = Assert.Single(model.Sections);
        Assert.Equal(1L, section.Id);
        Assert.Equal(SectionType.ReportHeader, section.Type);
        Assert.Equal("Report Header", section.Title);
        Assert.Equal(60.0, section.Height);
        Assert.True(section.Visible);
        Assert.False(section.PageBreak);
        Assert.Null(section.GroupField);

        var element = Assert.Single(model.Elements);
        Assert.Equal(101L, element.Id);
        Assert.Equal(ElementType.LabelStatic, element.Type);
        Assert.Equal(1L, element.Section);
        Assert.Equal(10.5, element.X);
        Assert.Equal(20.25, element.Y);
        Assert.Equal(124.0, element.W);
        Assert.Equal(22.0, element.H);
        Assert.Equal("Static Label", element.Text);
        Assert.Equal(0L, element.Field);
        Assert.Equal("", element.Table);
        Assert.Equal("", element.Column);
        Assert.Equal(AggregateFunction.Unknown, element.Function);
        Assert.Equal(AggregateScope.Unknown, element.Scope);
        Assert.Equal(0, element.Group);
        Assert.Equal("Helvetica", element.FontName);
        Assert.Equal(12.0, element.FontSize);
        Assert.False(element.Bold);
        Assert.False(element.Italic);
        Assert.False(element.Underline);
        Assert.False(element.Strikethrough);
        Assert.Equal(ElementHAlign.Left, element.HAlign);
        Assert.Equal(ElementVAlign.Center, element.VAlign);
        Assert.Equal(0.0, element.BorderTop);
        Assert.Equal(0.0, element.BorderBottom);
        Assert.Equal(0.0, element.BorderLeft);
        Assert.Equal(0.0, element.BorderRight);
        Assert.Equal(2.0, element.Padding);
        Assert.Equal(0.0, element.Margin);

        var field = Assert.Single(model.Fields);
        Assert.Equal(5001L, field.Id);
        Assert.Equal("CustomerId", field.Name);
        Assert.Equal("Customer", field.Table);
        Assert.Equal("Customer.CustomerId", field.Display);
    }

    [Fact]
    public void Parse_MissingOptionalFields_UsesDefaults()
    {
        const string json = """
        {
          "paperSize": 2,
          "sections": [ { "id": 1, "type": 1 } ],
          "elements": [ { "id": 2, "type": 1, "section": 1 } ],
          "fields": []
        }
        """;

        var model = LayoutModel.Parse(JsonDocument.Parse(json).RootElement);

        Assert.Equal(2, model.PaperSize);
        Assert.Empty(model.Fields);

        var section = Assert.Single(model.Sections);
        Assert.Equal("", section.Title);
        Assert.Equal(0.0, section.Height);
        Assert.False(section.Visible);
        Assert.False(section.PageBreak);
        Assert.Null(section.GroupField);

        var element = Assert.Single(model.Elements);
        Assert.Equal(0.0, element.X);
        Assert.Equal(0.0, element.Y);
        Assert.Equal(0.0, element.W);
        Assert.Equal(0.0, element.H);
        Assert.Equal("", element.Text);
        Assert.Equal(0L, element.Field);
        Assert.Equal("", element.Table);
        Assert.Equal("", element.Column);
        Assert.Equal(AggregateFunction.Unknown, element.Function);
        Assert.Equal(AggregateScope.Unknown, element.Scope);
        Assert.Equal(0, element.Group);
        Assert.Equal("", element.FontName);
        Assert.Equal(0.0, element.FontSize);
        Assert.False(element.Bold);
        Assert.False(element.Italic);
        Assert.False(element.Underline);
        Assert.False(element.Strikethrough);
        Assert.Equal(ElementHAlign.Left, element.HAlign);
        Assert.Equal(ElementVAlign.Top, element.VAlign);
        Assert.Equal(0.0, element.BorderTop);
        Assert.Equal(0.0, element.Padding);
        Assert.Equal(0.0, element.Margin);
    }
}
