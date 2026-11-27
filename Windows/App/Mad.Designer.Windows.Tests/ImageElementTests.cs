//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using System.IO;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Threading;
using Mad.Designer.Windows.Engine;
using Mad.Designer.Windows.Infrastructure;
using Mad.Designer.Windows.Models;
using Mad.Designer.Windows.ViewModels;
using Mad.Designer.Windows.Views;

namespace Mad.Designer.Windows.Tests;

/// <summary>The image element over the process boundary and on the designer canvas: PNG
/// bytes set through <c>set-element-content</c> survive a re-read and a duplicate, a chosen
/// JPEG is re-encoded to PNG, and the canvas shows the picture instead of the placeholder.</summary>
[Collection("Engine")]
public sealed class ImageElementTests
{
    /// <summary>A real 1x1 transparent PNG — the wire format the image column carries.</summary>
    private const string OnePixelPngBase64 =
        "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==";

    [Fact]
    public async Task ImageElement_CarriesPngBytesThroughTheEngine()
    {
        string sqlite = CopyChinookToTemp();
        string mad = Path.Combine(Path.GetTempPath(), $"mad-image-{Guid.NewGuid():N}.mad");
        try
        {
            await using var service = new EngineService();
            var open = await service.CreateAsync(mad, new ConnectionSpec(ConnectionDriver.Sqlite3, sqlite, null, null, null, null, null, null));
            var model = await service.LayoutModelAsync(open.Handle);
            long detailId = model.Sections.Single(s => s.Type == SectionType.Body).Id;

            model = await service.AddElementAsync(open.Handle, "image", detailId, 30, 20);
            var image = model.Elements.Single(e => e.IsImage);
            Assert.Equal(ElementType.Image, image.Type);
            Assert.True(string.IsNullOrEmpty(image.Image?.DataBase64), "a fresh image element has no picture");

            model = await service.SetElementContentAsync(open.Handle, image.Id,
                new ElementContent { Data = OnePixelPngBase64 });
            var withPicture = model.Elements.Single(e => e.Id == image.Id);
            Assert.Equal(OnePixelPngBase64, withPicture.Image?.DataBase64);

            // The bytes are in the store, not just the reply: a fresh snapshot reads them.
            model = await service.LayoutModelAsync(open.Handle);
            Assert.Equal(OnePixelPngBase64, model.Elements.Single(e => e.Id == image.Id).Image?.DataBase64);

            // A duplicate carries the picture too.
            var before = model.Elements.Select(e => e.Id).ToHashSet();
            model = await service.DuplicateElementsAsync(open.Handle, new[] { image.Id });
            var dup = model.Elements.Single(e => !before.Contains(e.Id));
            Assert.True(dup.IsImage);
            Assert.Equal(OnePixelPngBase64, dup.Image?.DataBase64);
        }
        finally
        {
            if (File.Exists(sqlite)) File.Delete(sqlite);
            if (File.Exists(mad)) File.Delete(mad);
        }
    }

    [Fact]
    public void ImageFileEncoder_ReEncodesAJpegAsPng()
    {
        string jpeg = WriteTinyJpeg();
        try
        {
            byte[]? png = null;
            Exception? error = null;
            RunSta(() =>
            {
                try { png = ImageFileEncoder.ReadPng(jpeg); }
                catch (Exception exception) { error = exception; }
            });

            Assert.Null(error);
            Assert.NotNull(png);
            Assert.True(png!.Length > 8, "the encoder wrote no PNG");
            Assert.Equal(new byte[] { 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A }, png![..8]);
        }
        finally
        {
            if (File.Exists(jpeg)) File.Delete(jpeg);
        }
    }

    [Fact]
    public async Task CanvasShowsTheImageElementPicture()
    {
        string sqlite = CopyChinookToTemp();
        string mad = Path.Combine(Path.GetTempPath(), $"mad-image-canvas-{Guid.NewGuid():N}.mad");
        try
        {
            await using var service = new EngineService();
            var open = await service.CreateAsync(mad, new ConnectionSpec(ConnectionDriver.Sqlite3, sqlite, null, null, null, null, null, null));
            var vm = new DesignerViewModel(service);
            await vm.LoadAsync(open.Handle, 0);

            await vm.AddElementAsync("image", vm.Sections.Single(s => s.Type == SectionType.Body).Id, 10, 20);
            long id = vm.Elements.Single(e => e.IsImage).Id;

            // No picture yet: the canvas shows the localized placeholder.
            Assert.False(CanvasHasImage(vm, id), "an image element without bytes should show the placeholder");

            await vm.SetImageDataAsync(id, Convert.FromBase64String(OnePixelPngBase64));
            Assert.True(CanvasHasImage(vm, id), "the canvas should show the element's picture");
        }
        finally
        {
            if (File.Exists(sqlite)) File.Delete(sqlite);
            if (File.Exists(mad)) File.Delete(mad);
        }
    }

    private static bool CanvasHasImage(DesignerViewModel vm, long elementId)
    {
        bool found = false;
        RunSta(() =>
        {
            var canvas = new DesignerCanvas { Width = 900, Height = 900 };
            canvas.Attach(vm);
            canvas.Measure(new Size(900, 900));
            canvas.Arrange(new Rect(0, 0, 900, 900));
            canvas.UpdateLayout();
            found = canvas.Children.OfType<Border>()
                .Where(b => b.Tag is LayoutElement element && element.Id == elementId)
                .Any(b => b.Child is Image image && image.Source is BitmapImage);
        });
        return found;
    }

    private static void RunSta(Action action)
    {
        Exception? error = null;
        var thread = new Thread(() =>
        {
            try { action(); }
            catch (Exception exception) { error = exception; }
        });
        thread.SetApartmentState(ApartmentState.STA);
        thread.Start();
        thread.Join();
        if (error != null) throw new AggregateException(error);
    }

    private static string WriteTinyJpeg()
    {
        string path = Path.Combine(Path.GetTempPath(), $"mad-image-{Guid.NewGuid():N}.jpg");
        byte[] pixels = { 255, 0, 0, 255 };
        var bitmap = BitmapSource.Create(1, 1, 96, 96, PixelFormats.Bgra32, null, pixels, 4);
        var encoder = new JpegBitmapEncoder();
        encoder.Frames.Add(BitmapFrame.Create(bitmap));
        using (var stream = File.Create(path)) encoder.Save(stream);
        return path;
    }

    private static string CopyChinookToTemp()
    {
        string source = Path.Combine(MadPathResolver.RepoRoot(), "MADDesigner", "Resources", "Assets", "Samples.xcassets", "Data", "chinook.dataset", "chinook.sqlite3");
        string temp = Path.Combine(Path.GetTempPath(), $"mad-image-chinook-{Guid.NewGuid():N}.sqlite3");
        File.Copy(source, temp);
        return temp;
    }
}
