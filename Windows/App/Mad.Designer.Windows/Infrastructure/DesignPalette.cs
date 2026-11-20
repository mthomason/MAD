//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using System.Windows.Media;

namespace Mad.Designer.Windows.Infrastructure;

/// <summary>The document-rendering palette the canvases draw with. XAML chrome takes its colours
/// from the Fluent theme (see <c>Themes/Theme.xaml</c>); a report page is a document, so its paper,
/// element tints, selection accent and join colour are fixed design tokens rather than theme
/// brushes. All brushes are frozen so a canvas may be materialised on any UI thread.</summary>
public static class DesignPalette
{
    public static readonly Brush Accent = Frozen(0x0A, 0x84, 0xFF);
    public static readonly Brush Paper = Frozen(0xFF, 0xFF, 0xFF);
    public static readonly Brush PaperInk = Frozen(0x1A, 0x1A, 0x1A);
    public static readonly Brush ElementOutline = Frozen(0x66, 0x80, 0x80, 0x80);
    public static readonly Brush LabelTint = Frozen(0xF7, 0xF7, 0xF7);
    public static readonly Brush DataFieldTint = Frozen(0xEA, 0xF4, 0xFF);
    public static readonly Brush AggregateTint = Frozen(0xEF, 0xF9, 0xEC);
    public static readonly Brush ImageTint = Frozen(0xFA, 0xF4, 0xE7);
    public static readonly Brush ConnectorRed = Frozen(0xC0, 0x3B, 0x3B);
    public static readonly Brush CardRootHeader = Frozen(0x0A, 0x84, 0xFF);
    public static readonly Brush CardSubHeader = Frozen(0xD6, 0xE4, 0xF7);
    public static readonly Brush CardSubHeaderText = Frozen(0x0A, 0x5A, 0xB8);
    public static readonly Brush MinimapBand = Frozen(0xFF, 0xFF, 0xFF);
    public static readonly Brush MinimapHiddenBand = Frozen(0xDD, 0xDD, 0xDD);
    public static readonly Brush MinimapElement = Frozen(0x46, 0x82, 0xB4);
    public static readonly Brush LineRule = Frozen(0x66, 0x66, 0x66);
    public static readonly Brush CanvasGrid = Frozen(0x0B, 0x00, 0x00, 0x00);
    public static readonly Brush MarqueeFill = Frozen(0x1E, 0x0A, 0x84, 0xFF);

    private static SolidColorBrush Frozen(byte r, byte g, byte b)
        => Frozen(0xFF, r, g, b);

    private static SolidColorBrush Frozen(byte a, byte r, byte g, byte b)
    {
        var brush = new SolidColorBrush(Color.FromArgb(a, r, g, b));
        brush.Freeze();
        return brush;
    }
}
