//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using System.IO;
using Mad.Designer.Windows.Infrastructure;

namespace Mad.Designer.Windows.Tests;

public sealed class MadPathResolverTests
{
    [Fact]
    public void DefaultDocument_ResolvesLondonFixture()
    {
        string document = MadPathResolver.DefaultDocument();
        Assert.EndsWith("CLI/Fixtures/London.portable.mad", document.Replace('\\', '/'));
        Assert.True(File.Exists(document));
    }

    [Fact]
    public void MadExe_ResolvesBuiltEngine()
    {
        string madExe = MadPathResolver.MadExe();
        Assert.EndsWith("Windows/Engine/build/mad.exe", madExe.Replace('\\', '/'));
        Assert.True(File.Exists(madExe));
    }

    [Fact]
    public void GnustepBin_ResolvesGnuStepDir()
    {
        Assert.Equal(@"C:\GNUstep\x64\Release\bin", MadPathResolver.GnustepBin());
    }

    [Fact]
    public void LicensesRoot_ResolvesThirdPartyLicenses()
    {
        string root = MadPathResolver.LicensesRoot();
        Assert.EndsWith("ThirdParty/Licenses", root.Replace('\\', '/'));
        Assert.True(Directory.Exists(root));
    }
}
