//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using System.IO;
using System.Windows.Media.Imaging;

namespace Mad.Designer.Windows.Infrastructure;

/// <summary>The file picker's decoder. The engine stores PNG bytes in the image column,
/// so a chosen PNG or JPEG is decoded through WPF's imaging stack (WIC) and encoded
/// again as PNG before it crosses the process boundary. This runs on the UI thread,
/// which is STA — WPF's imaging types expect that.</summary>
public static class ImageFileEncoder
{
    /// <summary>Reads an image file (PNG, JPEG, or anything WIC decodes) and answers its
    /// bytes as PNG.</summary>
    public static byte[] ReadPng(string path)
    {
        var decoder = BitmapDecoder.Create(
            new Uri(Path.GetFullPath(path)),
            BitmapCreateOptions.PreservePixelFormat,
            BitmapCacheOption.OnLoad);
        if (decoder.Frames.Count == 0) throw new InvalidOperationException("the image has no frames");

        var encoder = new PngBitmapEncoder();
        encoder.Frames.Add(BitmapFrame.Create(decoder.Frames[0]));
        using var stream = new MemoryStream();
        encoder.Save(stream);
        return stream.ToArray();
    }
}
