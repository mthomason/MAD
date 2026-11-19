//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using System.IO;
using System.Windows;
using Mad.Designer.Windows.Engine;
using Mad.Designer.Windows.Infrastructure;
using Mad.Designer.Windows.Models;
using Mad.Designer.Windows.ViewModels;

namespace Mad.Designer.Windows.Tests;

/// <summary>The Designer acceptance gate — the WPF equivalent of the Mac's
/// <c>MADMacSmokeTest</c> step 5, exercised through the view model's public API.</summary>
[Collection("Engine")]
public sealed class DesignerAcceptanceTests
{
    [Fact]
    public async Task ThreeNonOverlappingElements_EditMoveUndoDelete()
    {
        string sqlite = CopyChinookToTemp();
        string mad = Path.Combine(Path.GetTempPath(), $"mad-accept-{Guid.NewGuid():N}.mad");
        try
        {
            await using var service = new EngineService();
            var open = await service.CreateAsync(mad, new ConnectionSpec(ConnectionDriver.Sqlite3, sqlite, null, null, null, null, null, null));

            var vm = new DesignerViewModel(service);
            await vm.LoadAsync(open.Handle);
            long detailId = vm.Sections.Single(s => s.Type == SectionType.Body).Id;
            long pageHeaderId = vm.Sections.Single(s => s.Type == SectionType.PageHeader).Id;

            // Palette inserts three distinct, non-overlapping elements (they do not stack at 0,0).
            await vm.AddLabelCommand.ExecuteAsync();
            await vm.AddDataFieldCommand.ExecuteAsync();
            await vm.AddAggregateCommand.ExecuteAsync();
            Assert.Equal(3, vm.Elements.Count);

            var rects = vm.Elements.Select(e => new Rect(e.X, e.Y, e.W, e.H)).ToList();
            for (int i = 0; i < rects.Count; i++)
            {
                for (int j = i + 1; j < rects.Count; j++)
                {
                    Assert.False(rects[i].IntersectsWith(rects[j]));
                }
            }

            // X/Y edit persists; undo restores the original geometry.
            var label = vm.Elements.Single(e => e.IsLabel);
            double originalX = label.X;
            await vm.SetElementGeometryAsync(new[] { new ElementGeometry(label.Id, 111, 22, 200, 30) });
            Assert.Equal(111.0, vm.Elements.Single(e => e.Id == label.Id).X);

            await vm.UndoAsync();
            Assert.Equal(originalX, vm.Elements.Single(e => e.Id == label.Id).X);

            // Cross-section move (Detail -> Page Header); undo returns it.
            await vm.MoveElementsAsync(new[] { label.Id }, pageHeaderId);
            Assert.Equal(pageHeaderId, vm.Elements.Single(e => e.Id == label.Id).Section);

            await vm.UndoAsync();
            Assert.Equal(detailId, vm.Elements.Single(e => e.Id == label.Id).Section);

            // Duplicate then delete everything.
            await vm.DuplicateElementsAsync(new[] { label.Id });
            Assert.Equal(4, vm.Elements.Count);

            await vm.RemoveElementsAsync(vm.Elements.Select(e => e.Id).ToList());
            Assert.Empty(vm.Elements);
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
