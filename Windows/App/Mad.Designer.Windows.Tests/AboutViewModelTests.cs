//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using Mad.Designer.Windows.Infrastructure;
using Mad.Designer.Windows.Models;
using Mad.Designer.Windows.ViewModels;

namespace Mad.Designer.Windows.Tests;

/// <summary>The About surface's content: the Windows component set (never Apple's), the
/// WebView2 SDK licence and runtime attribution, and the policy that the legal texts stay
/// verbatim English while the chrome is localized.</summary>
public sealed class AboutViewModelTests
{
    [Fact]
    public void About_ListsWebView2_WithBothTheSdkLicenceAndTheRuntimeNotice()
    {
        var about = new AboutViewModel();
        WindowsComponent? webView = about.Components.FirstOrDefault(c => c.Name == "Microsoft Edge WebView2");
        Assert.NotNull(webView);

        about.SelectedComponent = webView;
        Assert.Contains("BSD-3-Clause", about.SelectedAcknowledgement);
        Assert.Contains("Microsoft Software License Terms", about.SelectedAcknowledgement);
        Assert.Contains("Microsoft Edge WebView2 Runtime", about.SelectedAcknowledgement);
        Assert.Contains("NOTICES AND INFORMATION", about.SelectedAcknowledgement);
    }

    [Fact]
    public void About_ReportsTheEngineAndApplicationVersionsSeparately()
    {
        var about = new AboutViewModel();
        Assert.Equal("v9.0 (r4433)", about.EngineVersion);
        Assert.Equal("v0.7", about.ApplicationVersion);
        Assert.NotEqual(about.EngineVersion, about.ApplicationVersion);
    }

    [Fact]
    public void About_English_ShowsTheNoticeAndTheEnglishLegalTexts()
    {
        var about = new AboutViewModel();
        Assert.Contains("machine-assisted", about.Overview);
        Assert.Contains("The licence texts below are reproduced in their original English.", about.LicenseNotice);
        Assert.Contains("GNU Lesser General Public License v3.0", about.LicenseNotice);
        Assert.Contains("Copyright", about.Copyright);
    }

    [Fact]
    public void About_German_TranslatesTheChrome_ButNotTheLegalTexts()
    {
        try
        {
            Localizer.Apply("de");
            var about = new AboutViewModel();

            Assert.Contains("maschinell", about.Overview);
            Assert.Contains("Lizenztexte", about.LicenseNotice);
            Assert.Contains("GNU Lesser General Public License v3.0", about.LicenseNotice);
            Assert.Contains("NOTICE", about.LicenseNotice);
            Assert.Contains("Copyright © 2012–2026 Michael Thomason", about.Copyright);
        }
        finally
        {
            Localizer.Apply("en");
        }
    }
}
