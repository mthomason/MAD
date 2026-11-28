//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using System.IO;
using Mad.Client;
using Mad.Designer.Windows.Engine;
using Mad.Designer.Windows.Infrastructure;
using Mad.Designer.Windows.Models;
using Mad.Designer.Windows.ViewModels;

namespace Mad.Designer.Windows.Tests;

/// <summary>Every node in a composition is a report: selecting one loads its own query schema,
/// its own Designer layout, and its own Viewer rows. A node with no elements shows a row grid
/// instead of a report page. A Standard Report keeps its document layout and its json-report;
/// a source drops json-report. These are the Windows acceptance cases for spec §0.</summary>
[Collection("Engine")]
public sealed class CompositionNodeReportsTests
{
    private static string FixturePath(string name)
        => Path.Combine(MadPathResolver.RepoRoot(), "Windows", "App", "Mad.Designer.Windows.Tests", "Fixtures", name);

    private static string CopyFixture(string name)
    {
        string temp = Path.Combine(Path.GetTempPath(), $"mad-node-{Guid.NewGuid():N}-{name}");
        File.Copy(FixturePath(name), temp);
        return temp;
    }

    private static ConnectionSpec Sqlite(string file)
        => new(ConnectionDriver.Sqlite3, file, null, null, null, null, null, null);

    /// <summary>Builds a one-source composition from the invoices fixture: a standard report
    /// (its single query becomes the child), converted to a composition whose Result joins
    /// nothing yet. Returns the document and the two query ids.</summary>
    private static async Task<(OpenResult Created, long Root, long Child, string Mad)> BuildCompositionAsync(
        EngineService engine, string invoices, string mad)
    {
        OpenResult created = await engine.CreateAsync(mad, Sqlite(invoices));
        var info = await engine.DocumentInfoAsync(created.Handle);
        long single = info.Queries[0].Id;
        await engine.AddTableAsync(created.Handle, "invoices", single);

        DocumentInfo composed = await engine.ConvertAsync(created.Handle, "invoices");
        long root = composed.RootQuery;
        long child = composed.Queries.Single(q => !q.IsRoot).Id;
        return (created, root, child, mad);
    }

    private static async Task<long> BodySectionAsync(EngineService engine, int handle, long query)
    {
        LayoutModel layout = await engine.LayoutModelAsync(handle, query);
        return layout.Sections.Single(s => s.Type == SectionType.Body).Id;
    }

    [Fact]
    public async Task SelectingALeaf_ShowsItsLayoutAsHtml_AndTheResultReturnsToTheResult()
    {
        string invoices = CopyFixture("invoices.sqlite");
        string mad = Path.Combine(Path.GetTempPath(), $"mad-node-{Guid.NewGuid():N}.mad");
        try
        {
            await using var engine = new EngineService();
            var (created, root, child, _) = await BuildCompositionAsync(engine, invoices, mad);

            // Give the child leaf a layout: a static label in its detail band.
            long body = await BodySectionAsync(engine, created.Handle, child);
            await engine.AddElementAsync(created.Handle, "label", body, 16, 10, child);

            var document = new DocumentViewModel(engine);
            await document.AdoptAsync(created, mad);
            Assert.True(document.IsComposed);
            Assert.True(await document.RefreshAsync(), document.ErrorText);

            // Selecting the leaf loads its own layout and renders its HTML report.
            await document.SelectQueryAsync(child);

            Assert.Equal(child, document.Viewer.QueryId);
            Assert.Single(document.Designer.Elements);
            Assert.False(document.Designer.SelectedNodeComposing);
            Assert.NotEmpty(document.Query.SchemaTables);
            Assert.False(document.Viewer.IsRowGrid);
            Assert.NotNull(document.Viewer.PreviewHtml);
            Assert.Equal(3, document.Viewer.RowCount);

            // Selecting the Result returns every workspace to the Result.
            await document.SelectQueryAsync(root);

            Assert.Equal(root, document.Viewer.QueryId);
            Assert.True(document.Designer.SelectedNodeComposing);
            Assert.True(document.IsRootSelected);
        }
        finally
        {
            if (File.Exists(invoices)) File.Delete(invoices);
            if (File.Exists(mad)) File.Delete(mad);
        }
    }

    [Fact]
    public async Task ALayoutlessSource_ShowsARowGrid_NotAnError()
    {
        string invoices = CopyFixture("invoices.sqlite");
        string mad = Path.Combine(Path.GetTempPath(), $"mad-node-{Guid.NewGuid():N}.mad");
        try
        {
            await using var engine = new EngineService();
            var (created, root, child, _) = await BuildCompositionAsync(engine, invoices, mad);

            var document = new DocumentViewModel(engine);
            await document.AdoptAsync(created, mad);
            Assert.True(await document.RefreshAsync(), document.ErrorText);

            await document.SelectQueryAsync(child);

            Assert.True(document.Viewer.IsRowGrid);
            Assert.Null(document.Viewer.PreviewHtml);
            Assert.NotNull(document.Viewer.NodeRows);
            Assert.Equal(3, document.Viewer.NodeRows!.Count);
            Assert.Equal(3, document.Viewer.RowCount);
            Assert.NotEqual(ViewerStatusKind.Error, document.Viewer.StatusKind);

            // The Result, also layout-less after a convert from a layout-less report, grids too.
            await document.SelectQueryAsync(root);
            Assert.True(document.Viewer.IsRowGrid);
            Assert.Equal(3, document.Viewer.NodeRows!.Count);
        }
        finally
        {
            if (File.Exists(invoices)) File.Delete(invoices);
            if (File.Exists(mad)) File.Delete(mad);
        }
    }

    [Fact]
    public async Task AStandardReportWithALayout_KeepsItsDocumentLayout()
    {
        string invoices = CopyFixture("invoices.sqlite");
        string mad = Path.Combine(Path.GetTempPath(), $"mad-node-{Guid.NewGuid():N}.mad");
        try
        {
            await using var engine = new EngineService();
            OpenResult created = await engine.CreateAsync(mad, Sqlite(invoices));
            long single = (await engine.DocumentInfoAsync(created.Handle)).Queries[0].Id;
            await engine.AddTableAsync(created.Handle, "invoices", single);

            // A data field (not a static label) makes the report's active-field SELECT non-empty,
            // which the engine's export compiles.
            LayoutModel initial = await engine.LayoutModelAsync(created.Handle, single);
            long body = initial.Sections.Single(s => s.Type == SectionType.Body).Id;
            LayoutModel withElement = await engine.AddElementAsync(created.Handle, "data-field", body, 16, 10);
            long element = withElement.Elements.MaxBy(e => e.Id)!.Id;
            await engine.SetElementContentAsync(created.Handle, element,
                new ElementContent(Field: initial.Fields.First().Id));

            // Passing the single query id is equivalent to omitting it: the report root.
            LayoutModel documentLayout = await engine.LayoutModelAsync(created.Handle);
            LayoutModel queryLayout = await engine.LayoutModelAsync(created.Handle, single);
            Assert.Equal(documentLayout.Elements.Count, queryLayout.Elements.Count);
            Assert.Equal(documentLayout.Sections.Count, queryLayout.Sections.Count);
            Assert.True(documentLayout.Elements.Count > 0, "the standard report kept its element");

            // describe still works with the report's single query. Without a query it answers
            // the layout's columns (none here); with it, the query's own fields and schema.
            // Both must see the same one-database schema, and the query must expose fields.
            DescribeResult documentDescribe = await engine.DescribeAsync(created.Handle);
            DescribeResult queryDescribe = await engine.DescribeAsync(created.Handle, single);
            Assert.Equal(documentDescribe.Tables.Count, queryDescribe.Tables.Count);
            Assert.NotEmpty(queryDescribe.Columns);

            Assert.NotEmpty(await engine.ExportAsync(created.Handle, "html"));
            Assert.NotEmpty(await engine.ExportAsync(created.Handle, "html", single));

            // json-report still works for a Standard Report, with and without the query.
            Assert.NotEmpty(await engine.ExportAsync(created.Handle, "json-report"));
            Assert.NotEmpty(await engine.ExportAsync(created.Handle, "json-report", single));
        }
        finally
        {
            if (File.Exists(invoices)) File.Delete(invoices);
            if (File.Exists(mad)) File.Delete(mad);
        }
    }

    [Fact]
    public async Task AStandardReportWithoutElements_ShowsTheRowGrid()
    {
        string invoices = CopyFixture("invoices.sqlite");
        string mad = Path.Combine(Path.GetTempPath(), $"mad-node-{Guid.NewGuid():N}.mad");
        try
        {
            await using var engine = new EngineService();
            OpenResult created = await engine.CreateAsync(mad, Sqlite(invoices));
            long single = (await engine.DocumentInfoAsync(created.Handle)).Queries[0].Id;
            await engine.AddTableAsync(created.Handle, "invoices", single);

            // A report must reference a field to refresh (the engine compiles an active-field
            // SELECT), so author one data field first: the refresh publishes the rows.
            LayoutModel layout = await engine.LayoutModelAsync(created.Handle, single);
            long body = layout.Sections.Single(s => s.Type == SectionType.Body).Id;
            LayoutModel withElement = await engine.AddElementAsync(created.Handle, "data-field", body, 16, 10, single);
            long element = withElement.Elements.MaxBy(e => e.Id)!.Id;
            await engine.SetElementContentAsync(created.Handle, element,
                new ElementContent(Field: layout.Fields.First().Id), single);

            var document = new DocumentViewModel(engine);
            await document.AdoptAsync(created, mad);
            Assert.True(await document.RefreshAsync(), document.ErrorText);
            Assert.False(document.Viewer.IsRowGrid); // an element means an HTML report

            // Remove the only element: the layout is now empty, but the result stays published,
            // so the Viewer shows the retained rows as a grid rather than an empty report.
            await engine.RemoveElementsAsync(created.Handle, new[] { element }, single);
            await document.Designer.LoadAsync(created.Handle, single);
            Assert.Empty(document.Designer.Elements);

            await document.Viewer.RenderAsync(document.Designer.Elements.Count > 0);

            Assert.True(document.Viewer.IsRowGrid);
            Assert.Null(document.Viewer.PreviewHtml);
            Assert.Equal(3, document.Viewer.NodeRows!.Count);
            Assert.Equal(3, document.Viewer.RowCount);
        }
        finally
        {
            if (File.Exists(invoices)) File.Delete(invoices);
            if (File.Exists(mad)) File.Delete(mad);
        }
    }

    [Fact]
    public async Task JsonReport_IsUnavailableForASource_AndAvailableForAStandardReport()
    {
        string invoices = CopyFixture("invoices.sqlite");
        string mad = Path.Combine(Path.GetTempPath(), $"mad-node-{Guid.NewGuid():N}.mad");
        try
        {
            await using var engine = new EngineService();
            var (created, root, child, _) = await BuildCompositionAsync(engine, invoices, mad);

            // A source is not the report root: the engine refuses its json-report.
            var exception = await Assert.ThrowsAsync<MadEngineException>(
                () => engine.ExportAsync(created.Handle, "json-report", child));
            Assert.False(string.IsNullOrWhiteSpace(exception.Message));

            // The document-level (root) json-report still works.
            Assert.NotEmpty(await engine.ExportAsync(created.Handle, "json-report"));

            // The Viewer's export list follows the selection's report-root identity.
            var document = new DocumentViewModel(engine);
            await document.AdoptAsync(created, mad);
            Assert.True(await document.RefreshAsync(), document.ErrorText);

            Assert.True(document.Viewer.IsNodeReportRoot);
            Assert.Contains(document.Viewer.AvailableExportFormats, f => f.Format == "json-report");

            await document.SelectQueryAsync(child);
            Assert.False(document.Viewer.IsNodeReportRoot);
            Assert.DoesNotContain(document.Viewer.AvailableExportFormats, f => f.Format == "json-report");

            await document.SelectQueryAsync(root);
            Assert.True(document.Viewer.IsNodeReportRoot);
            Assert.Contains(document.Viewer.AvailableExportFormats, f => f.Format == "json-report");
        }
        finally
        {
            if (File.Exists(invoices)) File.Delete(invoices);
            if (File.Exists(mad)) File.Delete(mad);
        }
    }

    [Fact]
    public async Task DesignerUndo_IsClearedOnlyWhenTheSelectedNodeChanges()
    {
        string invoices = CopyFixture("invoices.sqlite");
        string mad = Path.Combine(Path.GetTempPath(), $"mad-node-{Guid.NewGuid():N}.mad");
        try
        {
            await using var engine = new EngineService();
            var (created, root, child, _) = await BuildCompositionAsync(engine, invoices, mad);

            var designer = new DesignerViewModel(engine);
            await designer.LoadAsync(created.Handle, child);
            await designer.AddLabelCommand.ExecuteAsync();
            Assert.True(designer.CanUndo, "adding an element records an undoable edit");

            // Reloading the same node keeps its history.
            await designer.LoadAsync(created.Handle, child);
            Assert.True(designer.CanUndo);

            // Switching nodes discards it, so an edit is never replayed against another node.
            await designer.LoadAsync(created.Handle, root);
            Assert.False(designer.CanUndo);
        }
        finally
        {
            if (File.Exists(invoices)) File.Delete(invoices);
            if (File.Exists(mad)) File.Delete(mad);
        }
    }
}
