//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

namespace Mad.Designer.Windows.Infrastructure;

/// <summary>The Windows application's own product identity. It is deliberately separate from
/// the engine version the About window reports: the engine is a mature 9.x product while this
/// Windows application is pre-1.0.  The version comes from the generated MADBuildInfo.json;
/// a build without one says unknown, never a stale literal.</summary>
public static class AppInfo
{
    /// <summary>The Windows application version, or "unknown" when this build has no
    /// generated identity file.</summary>
    public static string Version =>
        BuildInfo.Load().AppVersion is { Length: > 0 } version ? "v" + version : "unknown";

    /// <summary>The product name as shown in the window title and About surface.</summary>
    public static string ProductName => Localizer.Get("App.Title");
}
