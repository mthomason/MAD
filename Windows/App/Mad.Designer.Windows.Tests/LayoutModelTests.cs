//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using System.IO;
using System.Text.Json;
using Mad.Designer.Windows.Engine;
using Mad.Designer.Windows.Infrastructure;
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

/// <summary>Headless coverage of the Phase 6c report-layout read/mutation protocol paths,
/// mirroring the Mac's <c>MADMacSmokeTest</c> step 5.</summary>
[Collection("Engine")]
public sealed class LayoutProtocolTests
{
    [Fact]
    public async Task LayoutRoundTrip_AddMoveResizeSetSection_And_Remove()
    {
        string sqlite = CopyChinookToTemp();
        string mad = Path.Combine(Path.GetTempPath(), $"mad-layout-{Guid.NewGuid():N}.mad");
        try
        {
            await using var service = new EngineService();
            var open = await service.CreateAsync(mad, new ConnectionSpec(ConnectionDriver.Sqlite3, sqlite, null, null, null, null, null, null));

            var model = await service.LayoutModelAsync(open.Handle);

            // Canonical order: Report Header, Page Header, Detail, Page Footer, Report Footer.
            Assert.Equal(5, model.Sections.Count);
            Assert.Equal(SectionType.ReportHeader, model.Sections[0].Type);
            Assert.Equal(SectionType.PageHeader, model.Sections[1].Type);
            Assert.Equal(SectionType.Body, model.Sections[2].Type);

            long detailId = model.Sections.Single(s => s.Type == SectionType.Body).Id;
            long pageHeaderId = model.Sections.Single(s => s.Type == SectionType.PageHeader).Id;

            model = await service.AddElementAsync(open.Handle, "label", detailId, 10, 20);
            var label = model.Elements.Single(e => e.IsLabel);
            Assert.Equal(ElementType.LabelStatic, label.Type);
            Assert.Equal(10.0, label.X);
            Assert.Equal(20.0, label.Y);
            Assert.Equal("Static Label", label.Text);

            model = await service.AddElementAsync(open.Handle, "data-field", detailId, 0, 0);
            model = await service.AddElementAsync(open.Handle, "aggregate", detailId, 0, 0);
            Assert.Equal(3, model.Elements.Count);
            var dataField = model.Elements.Single(e => e.IsDataField);
            var aggregate = model.Elements.Single(e => e.IsAggregate);
            Assert.True(label.Id != dataField.Id && dataField.Id != aggregate.Id && label.Id != aggregate.Id);

            // Geometry edit round-trips.
            model = await service.SetElementGeometryAsync(open.Handle, new[] { new ElementGeometry(label.Id, 111, 22, 200, 30) });
            label = model.Elements.Single(e => e.Id == label.Id);
            Assert.Equal(111.0, label.X);
            Assert.Equal(22.0, label.Y);
            Assert.Equal(200.0, label.W);
            Assert.Equal(30.0, label.H);

            // Cross-section move preserves origin.
            model = await service.MoveElementsAsync(open.Handle, new[] { label.Id }, pageHeaderId);
            label = model.Elements.Single(e => e.Id == label.Id);
            Assert.Equal(pageHeaderId, label.Section);
            Assert.Equal(111.0, label.X);
            Assert.Equal(22.0, label.Y);

            // Section height/visible/pageBreak round-trip.
            model = await service.SetSectionAsync(open.Handle, pageHeaderId, 120, true, false);
            var pageHeader = model.Sections.Single(s => s.Id == pageHeaderId);
            Assert.Equal(120.0, pageHeader.Height);
            Assert.True(pageHeader.Visible);
            Assert.False(pageHeader.PageBreak);

            // Removing the three elements leaves an empty layout.
            model = await service.RemoveElementsAsync(open.Handle, new[] { label.Id, dataField.Id, aggregate.Id });
            Assert.Empty(model.Elements);
        }
        finally
        {
            if (File.Exists(sqlite)) File.Delete(sqlite);
            if (File.Exists(mad)) File.Delete(mad);
        }
    }

    [Fact]
    public async Task SetSectionHeight_RoundTripsWithoutDrift()
    {
        string sqlite = CopyChinookToTemp();
        string mad = Path.Combine(Path.GetTempPath(), $"mad-layout-{Guid.NewGuid():N}.mad");
        try
        {
            await using var service = new EngineService();
            var open = await service.CreateAsync(mad, new ConnectionSpec(ConnectionDriver.Sqlite3, sqlite, null, null, null, null, null, null));

            var model = await service.LayoutModelAsync(open.Handle);
            long detailId = model.Sections.Single(s => s.Type == SectionType.Body).Id;

            model = await service.SetSectionAsync(open.Handle, detailId, 137, null, null);
            var detail = model.Sections.Single(s => s.Id == detailId);
            Assert.Equal(137.0, detail.Height);
        }
        finally
        {
            if (File.Exists(sqlite)) File.Delete(sqlite);
            if (File.Exists(mad)) File.Delete(mad);
        }
    }

    [Fact]
    public async Task AddElement_AutoCreatesFirstRow()
    {
        string sqlite = CopyChinookToTemp();
        string mad = Path.Combine(Path.GetTempPath(), $"mad-layout-{Guid.NewGuid():N}.mad");
        try
        {
            await using var service = new EngineService();
            var open = await service.CreateAsync(mad, new ConnectionSpec(ConnectionDriver.Sqlite3, sqlite, null, null, null, null, null, null));

            var model = await service.LayoutModelAsync(open.Handle);
            long detailId = model.Sections.Single(s => s.Type == SectionType.Body).Id;

            model = await service.AddElementAsync(open.Handle, "label", detailId, 5, 5);
            Assert.Single(model.Elements);
        }
        finally
        {
            if (File.Exists(sqlite)) File.Delete(sqlite);
            if (File.Exists(mad)) File.Delete(mad);
        }
    }

    [Fact]
    public async Task AddElement_BelowBand_GrowsSectionHeight()
    {
        string sqlite = CopyChinookToTemp();
        string mad = Path.Combine(Path.GetTempPath(), $"mad-layout-{Guid.NewGuid():N}.mad");
        try
        {
            await using var service = new EngineService();
            var open = await service.CreateAsync(mad, new ConnectionSpec(ConnectionDriver.Sqlite3, sqlite, null, null, null, null, null, null));

            var model = await service.LayoutModelAsync(open.Handle);
            long detailId = model.Sections.Single(s => s.Type == SectionType.Body).Id;
            double originalHeight = model.Sections.Single(s => s.Id == detailId).Height; // 88 (Detail default)

            // A label placed low in the band (bottom 322) must grow the stored section height.
            model = await service.AddElementAsync(open.Handle, "label", detailId, 0, 300);
            double grownHeight = model.Sections.Single(s => s.Id == detailId).Height;

            Assert.Equal(330.0, grownHeight);
            Assert.True(grownHeight > originalHeight);
        }
        finally
        {
            if (File.Exists(sqlite)) File.Delete(sqlite);
            if (File.Exists(mad)) File.Delete(mad);
        }
    }

    [Fact]
    public async Task LayoutMutations_StyleContentDuplicateAndPaper()
    {
        string sqlite = CopyChinookToTemp();
        string mad = Path.Combine(Path.GetTempPath(), $"mad-layout-{Guid.NewGuid():N}.mad");
        try
        {
            await using var service = new EngineService();
            var open = await service.CreateAsync(mad, new ConnectionSpec(ConnectionDriver.Sqlite3, sqlite, null, null, null, null, null, null));

            var model = await service.LayoutModelAsync(open.Handle);
            long detailId = model.Sections.Single(s => s.Type == SectionType.Body).Id;

            model = await service.AddElementAsync(open.Handle, "label", detailId, 10, 20);
            var label = model.Elements.Single(e => e.IsLabel);

            // Content edit (label text).
            model = await service.SetElementContentAsync(open.Handle, label.Id, new ElementContent(Text: "Hello"));
            Assert.Equal("Hello", model.Elements.Single(e => e.Id == label.Id).Text);

            // Typography edit.
            model = await service.SetElementTypographyAsync(open.Handle, new[] { label.Id },
                new ElementTypography(FontName: "Arial", FontSize: 18, Bold: true, Italic: true));
            label = model.Elements.Single(e => e.Id == label.Id);
            Assert.Equal("Arial", label.FontName);
            Assert.Equal(18.0, label.FontSize);
            Assert.True(label.Bold);
            Assert.True(label.Italic);

            // Box model edit.
            model = await service.SetElementBoxModelAsync(open.Handle, new[] { label.Id },
                new ElementBoxModel(BorderTop: 1.5, BorderBottom: 0.5, Padding: 4, Margin: 2));
            label = model.Elements.Single(e => e.Id == label.Id);
            Assert.Equal(1.5, label.BorderTop);
            Assert.Equal(0.5, label.BorderBottom);
            Assert.Equal(4.0, label.Padding);
            Assert.Equal(2.0, label.Margin);

            // Duplicate clones content, size and offsets +16/+12.
            model = await service.DuplicateElementsAsync(open.Handle, new[] { label.Id });
            Assert.Equal(2, model.Elements.Count);
            Assert.Equal(2, model.Elements.Count(e => e.IsLabel));
            Assert.True(model.Elements.All(e => e.Text == "Hello"));
            Assert.Contains(model.Elements, e => e.Id != label.Id && e.X == label.X + 16.0 && e.Y == label.Y + 12.0);

            // Paper size edit.
            model = await service.SetPaperSizeAsync(open.Handle, (int)PaperSize.A4);
            Assert.Equal(19, model.PaperSize);
        }
        finally
        {
            if (File.Exists(sqlite)) File.Delete(sqlite);
            if (File.Exists(mad)) File.Delete(mad);
        }
    }

    private static string CopyChinookToTemp()
    {
        string source = Path.Combine(MadPathResolver.RepoRoot(), "MADDesigner", "Resources", "Assets", "Samples.xcassets", "Data", "chinook.dataset", "chinook.sqlite3");
        string temp = Path.Combine(Path.GetTempPath(), $"mad-chinook-{Guid.NewGuid():N}.sqlite3");
        File.Copy(source, temp);
        return temp;
    }
}
