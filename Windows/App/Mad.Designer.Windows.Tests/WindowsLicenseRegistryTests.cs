//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using Mad.Designer.Windows.Models;

namespace Mad.Designer.Windows.Tests;

public sealed class WindowsLicenseRegistryTests
{
    [Fact]
    public void Components_AreTheWindowsSet_NotApple()
    {
        var components = WindowsLicenseRegistry.Components;
        Assert.Equal(17, components.Count);
        Assert.Contains(components, c => c.Name == "GNUstep Base" && c.License == "LGPL-2.1-or-later");
        Assert.Contains(components, c => c.Name == "MariaDB Connector/C");
        Assert.Contains(components, c => c.Name == "Microsoft Edge WebView2"
            && c.License == "BSD-3-Clause (SDK) / Microsoft Software License Terms (Runtime)");
        // The barcode renderer links both; the Apple app's Font Awesome does not ship here.
        Assert.Contains(components, c => c.Name == "zint" && c.License == "BSD-3-Clause");
        Assert.Contains(components, c => c.Name == "libpng");
        Assert.DoesNotContain(components, c => c.Name == "Font Awesome");
    }

    [Fact]
    public void EveryComponent_LicenseFileExists()
    {
        foreach (var component in WindowsLicenseRegistry.Components)
        {
            Assert.False(
                string.IsNullOrEmpty(WindowsLicenseRegistry.ReadLicenseText(component)),
                $"{component.Name} licence text is missing");
        }
    }

    [Fact]
    public void MissingLicenseFile_ReturnsNull_AboutHandlesIt()
    {
        var bogus = new WindowsComponent("Bogus", "MIT", "none", "none", "no-such-file.txt");
        Assert.Null(WindowsLicenseRegistry.ReadLicenseText(bogus));
    }

    [Fact]
    public void RelinkOffer_MentionsWindowsEngine()
    {
        string offer = WindowsLicenseRegistry.RelinkOffer;
        Assert.False(string.IsNullOrEmpty(offer));
        Assert.Contains("Windows engine", offer);
        Assert.Contains("relink", offer);
    }
}
