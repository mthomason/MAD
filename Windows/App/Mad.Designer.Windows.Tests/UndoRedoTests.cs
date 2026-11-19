//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using System.IO;
using Mad.Designer.Windows.Engine;
using Mad.Designer.Windows.Infrastructure;
using Mad.Designer.Windows.Models;
using Mad.Designer.Windows.ViewModels;

namespace Mad.Designer.Windows.Tests;

/// <summary>Covers the client-side undo/redo stack — the WPF counterpart of the Mac's
/// <c>NSUndoManager</c> — over the geometry and cross-section-move mutations.</summary>
[Collection("Engine")]
public sealed class UndoRedoTests
{
    [Fact]
    public async Task UndoRedo_RestoresGeometryAndCrossSectionMove()
    {
        string sqlite = CopyChinookToTemp();
        string mad = Path.Combine(Path.GetTempPath(), $"mad-undo-{Guid.NewGuid():N}.mad");
        try
        {
            await using var service = new EngineService();
            var open = await service.CreateAsync(mad, new ConnectionSpec(ConnectionDriver.Sqlite3, sqlite, null, null, null, null, null, null));

            var vm = new DesignerViewModel(service);
            await vm.LoadAsync(open.Handle);
            long detailId = vm.Sections.Single(s => s.Type == SectionType.Body).Id;
            long pageHeaderId = vm.Sections.Single(s => s.Type == SectionType.PageHeader).Id;

            await vm.AddElementAsync("label", detailId, 10, 20);
            var label = vm.Elements.Single(e => e.IsLabel);

            // Geometry edit -> undo restores origin/size -> redo re-applies.
            await vm.SetElementGeometryAsync(new[] { new ElementGeometry(label.Id, 111, 22, 200, 30) });
            Assert.Equal(111.0, vm.Elements.Single(e => e.Id == label.Id).X);

            await vm.UndoAsync();
            Assert.Equal(10.0, vm.Elements.Single(e => e.Id == label.Id).X);
            Assert.Equal(20.0, vm.Elements.Single(e => e.Id == label.Id).Y);

            await vm.RedoAsync();
            Assert.Equal(111.0, vm.Elements.Single(e => e.Id == label.Id).X);
            Assert.Equal(22.0, vm.Elements.Single(e => e.Id == label.Id).Y);

            // Cross-section move -> undo returns it -> redo re-applies.
            await vm.MoveElementsAsync(new[] { label.Id }, pageHeaderId);
            Assert.Equal(pageHeaderId, vm.Elements.Single(e => e.Id == label.Id).Section);

            await vm.UndoAsync();
            Assert.Equal(detailId, vm.Elements.Single(e => e.Id == label.Id).Section);

            await vm.RedoAsync();
            Assert.Equal(pageHeaderId, vm.Elements.Single(e => e.Id == label.Id).Section);
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
