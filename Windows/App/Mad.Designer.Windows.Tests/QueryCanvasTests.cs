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
            await vm.LoadAsync(open.Handle, describe.Driver, describe.Tables, 0);
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

                    vm.Zoom = 1.5;
                    var scale = (ScaleTransform)canvas.LayoutTransform;
                    if (Math.Abs(scale.ScaleX - 1.5) > 0.0001) throw new InvalidOperationException("the canvas did not follow the zoom");

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

    [Fact]
    public async Task JoinBadgeAndFieldRow_ExplainTheirInteractions()
    {
        string sqlite = CopyChinookToTemp();
        string mad = Path.Combine(Path.GetTempPath(), $"mad-canvas-tip-{Guid.NewGuid():N}.mad");
        try
        {
            await using var service = new EngineService();
            var open = await service.CreateAsync(mad, new ConnectionSpec(
                ConnectionDriver.Sqlite3, sqlite, null, null, null, null, null, null));
            var describe = await service.DescribeAsync(open.Handle);

            var vm = new QueryViewModel(service);
            await vm.LoadAsync(open.Handle, describe.Driver, describe.Tables, 0);
            await vm.AddTableAsync("Customer");
            await vm.AddTableAsync("Invoice");
            var customer = vm.Tables.Single(t => t.Name == "Customer");
            var invoice = vm.Tables.Single(t => t.Name == "Invoice");
            await vm.ConnectFieldsAsync(
                customer.Fields.Single(f => f.Name == "CustomerId").Id,
                invoice.Fields.Single(f => f.Name == "CustomerId").Id);

            Exception? failure = null;
            string? badgeTip = null;
            string? fieldTip = null;

            var thread = new Thread(() =>
            {
                try
                {
                    var canvas = new QueryCanvas { Width = 900, Height = 700 };
                    canvas.Attach(vm);
                    canvas.Measure(new Size(900, 700));
                    canvas.Arrange(new Rect(0, 0, 900, 700));
                    canvas.UpdateLayout();

                    var badge = canvas.Children.OfType<Border>().FirstOrDefault(b => b.Tag is QueryLink);
                    badgeTip = badge is null ? null : ToolTipService.GetToolTip(badge) as string;

                    var card = canvas.Children.OfType<Border>().First(b => b.Tag is long);
                    var row = Descendants(card).OfType<Border>()
                        .First(b => b.Tag is long && Math.Abs(b.Height - 20.0) < 0.1);
                    fieldTip = ToolTipService.GetToolTip(row) as string;
                }
                catch (Exception ex)
                {
                    failure = ex;
                }
            });
            thread.SetApartmentState(ApartmentState.STA);
            thread.Start();
            thread.Join();

            Assert.Null(failure);
            Assert.False(string.IsNullOrWhiteSpace(badgeTip));
            Assert.Contains("Right-click", badgeTip!);
            Assert.False(string.IsNullOrWhiteSpace(fieldTip));
        }
        finally
        {
            if (File.Exists(sqlite)) File.Delete(sqlite);
            if (File.Exists(mad)) File.Delete(mad);
        }
    }

    private static IEnumerable<DependencyObject> Descendants(DependencyObject root)
    {
        int count = VisualTreeHelper.GetChildrenCount(root);
        for (int i = 0; i < count; i++)
        {
            DependencyObject child = VisualTreeHelper.GetChild(root, i);
            yield return child;
            foreach (DependencyObject descendant in Descendants(child)) yield return descendant;
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
