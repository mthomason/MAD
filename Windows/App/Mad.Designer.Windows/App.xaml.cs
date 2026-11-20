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
        base.OnStartup(e);
    }
}
