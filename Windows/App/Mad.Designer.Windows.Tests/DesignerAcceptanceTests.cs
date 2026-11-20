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

    /// <summary>The barcode composer: the palette inserts a real symbol (the engine's
    /// preview), and the inspector's symbology, options and input binding round-trip
    /// through the engine.</summary>
    [Fact]
    public async Task Barcode_InsertEditBindAndUnbind()
    {
        string sqlite = CopyChinookToTemp();
        string mad = Path.Combine(Path.GetTempPath(), $"mad-barcode-{Guid.NewGuid():N}.mad");
        try
        {
            await using var service = new EngineService();
            var open = await service.CreateAsync(mad, new ConnectionSpec(ConnectionDriver.Sqlite3, sqlite, null, null, null, null, null, null));
            // A query, so the designer's field list is not empty when the test binds
            // the barcode's input.
            await service.ApplySqlAsync(open.Handle,
                "SELECT Customer.FirstName, Customer.LastName, Customer.City FROM Customer WHERE Customer.Country = 'United Kingdom';");

            var vm = new DesignerViewModel(service);
            await vm.LoadAsync(open.Handle);
            long detailId = vm.Sections.Single(s => s.Type == SectionType.Body).Id;
            vm.SelectSection(detailId);

            Assert.NotEmpty(vm.BarcodeTypes);

            await vm.AddBarcodeCommand.ExecuteAsync();
            var barcode = vm.Elements.Single(e => e.IsBarcode);
            Assert.NotNull(barcode.Barcode);
            Assert.False(string.IsNullOrEmpty(barcode.Barcode!.PreviewBase64));
            Assert.StartsWith("iVBOR", barcode.Barcode.PreviewBase64); // the PNG signature, base64
            Assert.False(string.IsNullOrEmpty(barcode.Barcode.SymbologyName));

            vm.SelectElement(barcode.Id, extend: false);

            int qrIndex = IndexOfSymbology(vm, "QR Code (ISO 18004)");
            Assert.True(qrIndex >= 0, "the catalogue carries QR Code");
            vm.ElementBarcodeSymbologyIndex = qrIndex;
            await SettleAsync(vm);
            Assert.Equal("QR Code (ISO 18004)", vm.PrimaryElement!.Barcode!.SymbologyName);

            vm.ElementBarcodeHumanReadable = false;
            await SettleAsync(vm);
            Assert.False(vm.PrimaryElement!.Barcode!.HumanReadable);

            var field = vm.Fields.First();
            vm.ElementBarcodeInputId = field.Id;
            await SettleAsync(vm);
            Assert.False(vm.PrimaryElement!.Barcode!.UseStaticInput);
            Assert.Equal(field.Id, vm.PrimaryElement!.Barcode!.Field);

            // The text box edits the static input, which switches the binding back.
            vm.ElementText = "QR-TEST";
            await SettleAsync(vm);
            Assert.True(vm.PrimaryElement!.Barcode!.UseStaticInput);
            Assert.Equal("QR-TEST", vm.PrimaryElement!.Barcode!.StaticInput);

            // The picker's first row is the static input (id 0).
            vm.ElementBarcodeInputId = 0;
            await SettleAsync(vm);
            Assert.True(vm.PrimaryElement!.Barcode!.UseStaticInput);

            await vm.RemoveElementsAsync(new[] { barcode.Id });
            Assert.DoesNotContain(vm.Elements, e => e.IsBarcode);
        }
        finally
        {
            if (File.Exists(sqlite)) File.Delete(sqlite);
            if (File.Exists(mad)) File.Delete(mad);
        }
    }

    private static int IndexOfSymbology(DesignerViewModel vm, string name)
    {
        for (int i = 0; i < vm.BarcodeTypes.Count; i++)
        {
            if (vm.BarcodeTypes[i].Name == name) return i;
        }
        return -1;
    }

    /// <summary>The inspector's setters dispatch their mutation and return; wait for it.</summary>
    private static async Task SettleAsync(DesignerViewModel vm)
    {
        for (int i = 0; i < 300 && vm.IsBusy; i++) await Task.Delay(10);
        Assert.False(vm.IsBusy, "the designer did not settle");
        await vm.ReloadAsync();
    }

    private static string CopyChinookToTemp()
    {
        string source = Path.Combine(MadPathResolver.RepoRoot(), "MADDesigner", "Resources", "Assets", "Samples.xcassets", "Data", "chinook.dataset", "chinook.sqlite3");
        string temp = Path.Combine(Path.GetTempPath(), $"mad-chinook-{Guid.NewGuid():N}.sqlite3");
        File.Copy(source, temp);
        return temp;
    }
}
