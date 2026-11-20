//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using Microsoft.Win32;

namespace Mad.Designer.Windows.Infrastructure;

/// <summary>Answers whether the application's chrome is dark. WPF's Fluent theme follows the
/// system automatically; the WebView2 preview renders its own HTML and needs to know the desk
/// colour explicitly. <c>MAD_THEME</c> wins (the inspection override), otherwise the Windows
/// personalisation setting does. The value is read when the preview is created, so a theme
/// change takes effect on the next launch.</summary>
public static class ThemeInfo
{
    public static bool IsDark
    {
        get
        {
            string? inspection = Environment.GetEnvironmentVariable("MAD_THEME");
            if (string.Equals(inspection, "Dark", StringComparison.OrdinalIgnoreCase)) return true;
            if (string.Equals(inspection, "Light", StringComparison.OrdinalIgnoreCase)) return false;

            try
            {
                using RegistryKey? key = Registry.CurrentUser.OpenSubKey(
                    @"Software\Microsoft\Windows\CurrentVersion\Themes\Personalize");
                return key?.GetValue("AppsUseLightTheme") is int light && light == 0;
            }
            catch (Exception exception) when (exception is UnauthorizedAccessException or System.Security.SecurityException)
            {
                return false;
            }
        }
    }

    /// <summary>The desk colour around the rendered report pages, as CSS.</summary>
    public static string DeskColor => IsDark ? "#1F1F1F" : "#8C8C8C";
}
