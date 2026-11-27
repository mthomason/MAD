//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using System.IO;
using Mad.Designer.Windows.Engine;
using Mad.Designer.Windows.Infrastructure;
using Mad.Designer.Windows.Models;
using Mad.Designer.Windows.ViewModels;

namespace Mad.Designer.Windows.Tests;

/// <summary>Selection is one document-level value: the Composition graph, the Component
/// picker, and every workspace follow it. Selecting a source keeps the active workspace and
/// updates Query, Designer, and Viewer to that node; there is no interim notice and no forced
/// switch to Query.</summary>
[Collection("Engine")]
public sealed class CompositionSelectionTests
{
    private static string FixturePath(string name)
        => Path.Combine(MadPathResolver.RepoRoot(), "Windows", "App", "Mad.Designer.Windows.Tests", "Fixtures", name);

    private static string CopyFixture(string name)
    {
        string temp = Path.Combine(Path.GetTempPath(), $"mad-select-{Guid.NewGuid():N}-{name}");
        File.Copy(FixturePath(name), temp);
        return temp;
    }

    private static ConnectionSpec Sqlite(string file)
        => new(ConnectionDriver.Sqlite3, file, null, null, null, null, null, null);

    [Fact]
    public async Task AnEmptyComposition_OpensWithItsGuidanceInsteadOfAConnectionError()
    {
        string mad = Path.Combine(Path.GetTempPath(), $"mad-empty-{Guid.NewGuid():N}.mad");
        try
        {
            await using var engine = new EngineService();
            OpenResult created = await engine.CreateEmptyAsync(mad);
            await engine.AddRootAsync(created.Handle, "Result");
            await engine.WriteAsync(created.Handle, mad);

            var document = new DocumentViewModel(engine);
            await document.OpenAsync(mad);

            Assert.True(document.HasDocument);
            Assert.True(document.IsComposed);
            Assert.False(document.HasError, document.ErrorText);
            Assert.True(document.Composition.HasNodes);
            Assert.True(document.Composition.ShowEmptyState);
            Assert.False(document.Composition.ShowGraph);
        }
        finally
        {
            if (File.Exists(mad)) File.Delete(mad);
        }
    }

    [Fact]
    public async Task SelectingASource_KeepsTheWorkspaceAndEveryViewFollowsIt()
    {
        string invoices = CopyFixture("invoices.sqlite");
        string mad = Path.Combine(Path.GetTempPath(), $"mad-select-{Guid.NewGuid():N}.mad");
        try
        {
            await using var engine = new EngineService();
            OpenResult created = await engine.CreateEmptyAsync(mad);
            await engine.AddRootAsync(created.Handle, "root");
            DocumentInfo afterSource = await engine.AddSourceAsync(created.Handle, "invoices", Sqlite(invoices));
            long rootId = afterSource.RootQuery;
            long sourceId = afterSource.Queries.Single(q => !q.IsRoot).Id;

            var window = new MainWindowViewModel(engine);
            Assert.False(window.ImportChildCommand.CanExecute(null));

            await window.AdoptCreatedAsync(created, mad);

            // A new composition opens where sources are added and joined, and the File and
            // pane commands that need a document become available.
            Assert.True(window.Document.IsComposed);
            Assert.Equal(Workspace.Query, window.SelectedWorkspace);
            Assert.Equal(rootId, window.Document.SelectedQueryId);
            Assert.True(window.ImportChildCommand.CanExecute(null));
            Assert.True(window.ConvertCommand.CanExecute(null));

            // The graph and the picker share the one selection; move to the Viewer and pick a
            // source there. The workspace stays put, and the selection follows the node.
            window.SelectedWorkspace = Workspace.Viewer;
            window.Document.Composition.Select(sourceId);
            await window.Document.SelectQueryAsync(sourceId);

            Assert.Equal(sourceId, window.Document.SelectedQueryId);
            Assert.Equal(Workspace.Viewer, window.SelectedWorkspace);
            Assert.False(window.Document.IsRootSelected);
            Assert.False(window.Document.Designer.SelectedNodeComposing);

            // Selecting the Result returns every workspace to the Result without moving away.
            window.Document.Composition.Select(rootId);
            await window.Document.SelectQueryAsync(rootId);

            Assert.Equal(rootId, window.Document.SelectedQueryId);
            Assert.Equal(Workspace.Viewer, window.SelectedWorkspace);
            Assert.True(window.Document.IsRootSelected);
            Assert.True(window.Document.Designer.SelectedNodeComposing);
        }
        finally
        {
            if (File.Exists(invoices)) File.Delete(invoices);
            if (File.Exists(mad)) File.Delete(mad);
        }
    }
}
