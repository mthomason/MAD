//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using System.Windows;
using Mad.Designer.Windows.Infrastructure;

namespace Mad.Designer.Windows;

public partial class App : Application
{
    protected override void OnStartup(StartupEventArgs e)
    {
        // Select the language before StartupUri creates the main window: the XAML's
        // {infra:Loc} extensions resolve once, at load time.
        Localizer.ApplyFromEnvironmentOrCulture();

        // The theme follows the system by default (App.xaml's ThemeMode="System");
        // MAD_THEME=Light|Dark is an inspection override, like MAD_LANGUAGE.
        ThemeMode? mode = Environment.GetEnvironmentVariable("MAD_THEME")?.Trim().ToLowerInvariant() switch
        {
            "light" => ThemeMode.Light,
            "dark" => ThemeMode.Dark,
            "system" => ThemeMode.System,
            _ => null,
        };
        if (mode is { } requested)
        {
            ThemeMode = requested;
        }

        base.OnStartup(e);
    }
}
