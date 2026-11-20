//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using System.Windows;

namespace Mad.Designer.Windows.Infrastructure;

/// <summary>Keeps a window inside the current work area on small or heavily scaled displays.
/// The preferred size stays as authored; only an overflow is reduced, and the minimum size is
/// relaxed when the work area itself is smaller than it.</summary>
public static class WindowSizing
{
    public static void FitToWorkArea(Window window, double margin = 16.0)
    {
        Rect work = SystemParameters.WorkArea;
        window.MaxWidth = Math.Max(320.0, work.Width);
        window.MaxHeight = Math.Max(240.0, work.Height);

        window.MinWidth = Math.Min(window.MinWidth, window.MaxWidth);
        window.MinHeight = Math.Min(window.MinHeight, window.MaxHeight);

        if (window.Width > window.MaxWidth)
        {
            window.Width = Math.Max(window.MinWidth, window.MaxWidth - margin);
        }
        if (window.Height > window.MaxHeight)
        {
            window.Height = Math.Max(window.MinHeight, window.MaxHeight - margin);
        }
    }
}
