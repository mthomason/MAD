//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using System.IO;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using ShapePath = System.Windows.Shapes.Path;
using Mad.Designer.Windows.Engine;
using Mad.Designer.Windows.Infrastructure;
using Mad.Designer.Windows.Models;
using Mad.Designer.Windows.ViewModels;
using Mad.Designer.Windows.Views;

namespace Mad.Designer.Windows.Tests;

/// <summary>Verifies the visual canvas actually materializes cards and join links from the
/// query model, on an STA thread (WPF elements need one). This stands in for the
/// interactive visual check that the Query workspace renders the London-style query.</summary>
[Collection("Engine")]
public sealed class QueryCanvasTests
{
    [Fact]
    public async Task CanvasRendersCardsAndLinks_ForTwoConnectedTables()
    {
        string sqlite = CopyChinookToTemp();
        string mad = Path.Combine(Path.GetTempPath(), $"mad-canvas-{Guid.NewGuid():N}.mad");
        try
        {
            await using var service = new EngineService();
            var open = await service.CreateAsync(mad, new ConnectionSpec(ConnectionDriver.Sqlite3, sqlite, null, null, null, null, null, null));
            var describe = await service.DescribeAsync(open.Handle);

            var vm = new QueryViewModel(service);
            await vm.LoadAsync(open.Handle, describe.Driver, describe.Tables);
            await vm.AddTableAsync("Customer");
            await vm.AddTableAsync("Invoice");
            var customer = vm.Tables.Single(t => t.Name == "Customer");
            var invoice = vm.Tables.Single(t => t.Name == "Invoice");
            await vm.ConnectFieldsAsync(
                customer.Fields.Single(f => f.Name == "CustomerId").Id,
                invoice.Fields.Single(f => f.Name == "CustomerId").Id);

            Exception? renderError = null;
            int cardCount = 0;
            int linkCount = 0;

            var thread = new Thread(() =>
            {
                try
                {
                    var canvas = new QueryCanvas { Width = 900, Height = 700 };
                    canvas.Attach(vm);
                    canvas.Measure(new Size(900, 700));
                    canvas.Arrange(new Rect(0, 0, 900, 700));
                    canvas.UpdateLayout();

                    cardCount = canvas.Children.OfType<Border>().Count(b => b.Tag is long);
                    linkCount = canvas.Children.OfType<ShapePath>().Count(p => p.Tag is QueryLink);
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
            Assert.Equal(2, cardCount);
            Assert.Equal(1, linkCount);
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
