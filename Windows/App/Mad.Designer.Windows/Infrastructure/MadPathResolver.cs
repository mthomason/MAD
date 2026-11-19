//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using System.IO;

namespace Mad.Designer.Windows.Infrastructure;

/// <summary>Resolves the repo-relative paths the shell depends on: the .mad fixture,
/// the built engine, the GNUstep bin directory, and the licence register. Each value is
/// overridable with the same environment variable the Phase 4 client honours.</summary>
public static class MadPathResolver
{
    public static string RepoRoot()
    {
        var directory = new DirectoryInfo(AppContext.BaseDirectory);
        while (directory != null)
        {
            if (File.Exists(Path.Combine(directory.FullName, "CLI", "Fixtures", "London.portable.mad")))
            {
                return directory.FullName;
            }
            directory = directory.Parent;
        }
        throw new DirectoryNotFoundException("could not locate the repo root (CLI/Fixtures/London.portable.mad)");
    }

    public static string DefaultDocument()
    {
        return Environment.GetEnvironmentVariable("MAD_DOCUMENT")
            ?? Path.Combine(RepoRoot(), "CLI", "Fixtures", "London.portable.mad");
    }

    public static string MadExe()
    {
        return Environment.GetEnvironmentVariable("MAD_EXE")
            ?? Path.Combine(RepoRoot(), "Windows", "Engine", "build", "mad.exe");
    }

    public static string GnustepBin()
    {
        return Environment.GetEnvironmentVariable("GNUSTEP_BIN")
            ?? @"C:\GNUstep\x64\Release\bin";
    }

    public static string LicensesRoot()
    {
        string repoRoot = Environment.GetEnvironmentVariable("MAD_REPO_ROOT") ?? RepoRoot();
        return Path.Combine(repoRoot, "ThirdParty", "Licenses");
    }
}
