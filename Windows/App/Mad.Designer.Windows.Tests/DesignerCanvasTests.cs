//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using System.IO;
using System.Windows;
using System.Windows.Controls;
using Mad.Designer.Windows.Engine;
using Mad.Designer.Windows.Infrastructure;
using Mad.Designer.Windows.Models;
using Mad.Designer.Windows.ViewModels;
using Mad.Designer.Windows.Views;

namespace Mad.Designer.Windows.Tests;

/// <summary>Verifies the designer canvas actually materializes the report bands and the placed
/// elements, on an STA thread — the headless stand-in for the interactive visual check that
/// the Designer renders a report layout.</summary>
[Collection("Engine")]
public sealed class DesignerCanvasTests
{
    [Fact]
    public async Task CanvasRendersBandsAndElements()
    {
        string sqlite = CopyChinookToTemp();
        string mad = Path.Combine(Path.GetTempPath(), $"mad-designer-canvas-{Guid.NewGuid():N}.mad");
        try
        {
            await using var service = new EngineService();
            var open = await service.CreateAsync(mad, new ConnectionSpec(ConnectionDriver.Sqlite3, sqlite, null, null, null, null, null, null));
            var vm = new DesignerViewModel(service);
            await vm.LoadAsync(open.Handle);
            await vm.AddElementAsync("label", vm.Sections.Single(s => s.Type == SectionType.Body).Id, 10, 20);

            Exception? renderError = null;
            int sectionCount = 0;
            int elementCount = 0;

            var thread = new Thread(() =>
            {
                try
                {
                    var canvas = new DesignerCanvas { Width = 900, Height = 900 };
                    canvas.Attach(vm);
                    canvas.Measure(new Size(900, 900));
                    canvas.Arrange(new Rect(0, 0, 900, 900));
                    canvas.UpdateLayout();

                    sectionCount = canvas.Children.OfType<Border>().Count(b => b.Tag is LayoutSection);
                    elementCount = canvas.Children.OfType<Border>().Count(b => b.Tag is LayoutElement);
                }
                catch (Exception ex)
                {
                    renderError = ex;
                }
            });
            thread.SetApartmentState(ApartmentState.STA);
            thread.Start();
            thread.Join();

            Assert.Null(renderError);
            Assert.Equal(5, sectionCount); // Report Header, Page Header, Detail, Page Footer, Report Footer
            Assert.Equal(1, elementCount); // the single label
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
