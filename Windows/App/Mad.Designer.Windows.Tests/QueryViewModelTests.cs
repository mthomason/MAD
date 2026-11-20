//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using System.IO;
using Mad.Designer.Windows.Engine;
using Mad.Designer.Windows.Infrastructure;
using Mad.Designer.Windows.Models;
using Mad.Designer.Windows.ViewModels;

namespace Mad.Designer.Windows.Tests;

/// <summary>Headless coverage of the Query workspace's view-model layer: the two mutually
/// exclusive modes, the topological root classification, and generated-SQL sync.</summary>
[Collection("Engine")]
public sealed class QueryViewModelTests
{
    [Fact]
    public async Task ModesAreExclusive_AndRootClassification_AndSqlSync()
    {
        string sqlite = CopyChinookToTemp();
        string mad = Path.Combine(Path.GetTempPath(), $"mad-qvm-{Guid.NewGuid():N}.mad");
        try
        {
            await using var service = new EngineService();
            var open = await service.CreateAsync(mad, new ConnectionSpec(ConnectionDriver.Sqlite3, sqlite, null, null, null, null, null, null));
            var describe = await service.DescribeAsync(open.Handle);

            var vm = new QueryViewModel(service);
            await vm.LoadAsync(open.Handle, describe.Driver, describe.Tables);

            // Starts in the visual designer mode.
            Assert.Equal(QueryMode.Designer, vm.Mode);
            Assert.True(vm.IsDesigner);
            Assert.False(vm.IsSql);

            // Switching to SQL shows the generated SQL, and the two modes stay exclusive.
            vm.SwitchToMode(QueryMode.Sql);
            Assert.True(vm.IsSql);
            Assert.False(vm.IsDesigner);
            Assert.Equal(vm.Sql, vm.SqlEditorText);

            vm.SwitchToMode(QueryMode.Designer);
            Assert.True(vm.IsDesigner);

            // Add two tables and connect Customer.CustomerId -> Invoice.CustomerId.
            await vm.AddTableAsync("Customer");
            await vm.AddTableAsync("Invoice");
            var customer = vm.Tables.Single(t => t.Name == "Customer");
            var invoice = vm.Tables.Single(t => t.Name == "Invoice");
            long customerId = customer.Fields.Single(f => f.Name == "CustomerId").Id;
            long invoiceCustomerId = invoice.Fields.Single(f => f.Name == "CustomerId").Id;
            await vm.ConnectFieldsAsync(customerId, invoiceCustomerId);

            // The join classifies Customer as the root and orders it first; the generated
            // SQL contains LEFT OUTER JOIN.
            Assert.Contains(customer.Id, vm.RootTableIds);
            Assert.DoesNotContain(invoice.Id, vm.RootTableIds);
            Assert.Equal(customer.Id, vm.OrderedTables[0].Id);
            Assert.Contains("LEFT OUTER JOIN", vm.Sql);
        }
        finally
        {
            if (File.Exists(sqlite)) File.Delete(sqlite);
            if (File.Exists(mad)) File.Delete(mad);
        }
    }

    [Fact]
    public void ClickingTheActiveSegment_DoesNotLeaveTheSwitchUnselected()
    {
        var vm = new QueryViewModel(new EngineService());
        bool designerRefreshed = false;
        bool sqlRefreshed = false;
        vm.PropertyChanged += (_, e) =>
        {
            if (e.PropertyName == nameof(QueryViewModel.DesignerSelected)) designerRefreshed = true;
            if (e.PropertyName == nameof(QueryViewModel.SqlSelected)) sqlRefreshed = true;
        };

        vm.DesignerSelected = false; // the ToggleButton unchecking itself
        Assert.True(vm.DesignerSelected);
        Assert.Equal(QueryMode.Designer, vm.Mode);
        Assert.True(designerRefreshed);

        vm.SqlSelected = false;
        Assert.False(vm.SqlSelected);
        Assert.Equal(QueryMode.Designer, vm.Mode);
        Assert.True(sqlRefreshed);
    }

    [Fact]
    public void Zoom_ClampsStepsAndFitsTheCanvas()
    {
        var vm = new QueryViewModel(new EngineService());
        Assert.Equal(1.0, vm.Zoom);
        Assert.Equal("100%", vm.ZoomText);

        vm.ZoomInCommand.Execute(null);
        Assert.Equal(1.2, vm.Zoom, 6);
        Assert.Equal("120%", vm.ZoomText);

        for (int i = 0; i < 20; i++) vm.ZoomInCommand.Execute(null);
        Assert.Equal(2.0, vm.Zoom, 6);
        for (int i = 0; i < 40; i++) vm.ZoomOutCommand.Execute(null);
        Assert.Equal(0.4, vm.Zoom, 6);

        vm.FitToViewport(1000, 600, 2000, 800);
        Assert.Equal(Math.Min(968.0 / 2000.0, 568.0 / 800.0), vm.Zoom, 6);
    }

    private static string CopyChinookToTemp()
    {
        string source = Path.Combine(MadPathResolver.RepoRoot(), "MADDesigner", "Resources", "Assets", "Samples.xcassets", "Data", "chinook.dataset", "chinook.sqlite3");
        string temp = Path.Combine(Path.GetTempPath(), $"mad-chinook-{Guid.NewGuid():N}.sqlite3");
        File.Copy(source, temp);
        return temp;
    }
}
