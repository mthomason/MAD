//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using System.IO;
using Mad.Designer.Windows.Infrastructure;

namespace Mad.Designer.Windows.Tests;

public sealed class RecentFilesServiceTests
{
    private static string TempFile() => Path.Combine(Path.GetTempPath(), $"mad-recent-{Guid.NewGuid():N}.json");

    [Fact]
    public void Add_ThenGet_ReturnsMostRecentFirst()
    {
        string path = TempFile();
        try
        {
            var service = new RecentFilesService(path);
            service.Add("C:\\a.mad");
            service.Add("C:\\b.mad");

            Assert.Equal(new[] { "C:\\b.mad", "C:\\a.mad" }, service.Get().ToArray());
        }
        finally
        {
            if (File.Exists(path)) File.Delete(path);
        }
    }

    [Fact]
    public void Add_DeduplicatesExistingPath()
    {
        string path = TempFile();
        try
        {
            var service = new RecentFilesService(path);
            service.Add("C:\\a.mad");
            service.Add("C:\\b.mad");
            service.Add("C:\\a.mad");

            Assert.Equal(new[] { "C:\\a.mad", "C:\\b.mad" }, service.Get().ToArray());
        }
        finally
        {
            if (File.Exists(path)) File.Delete(path);
        }
    }

    [Fact]
    public void Add_CapsAtTen()
    {
        string path = TempFile();
        try
        {
            var service = new RecentFilesService(path);
            for (int i = 0; i < 12; i++) service.Add($"C:\\f{i}.mad");

            var list = service.Get();
            Assert.Equal(10, list.Count);
            Assert.Equal("C:\\f11.mad", list[0]);
            Assert.Equal("C:\\f2.mad", list[9]);
        }
        finally
        {
            if (File.Exists(path)) File.Delete(path);
        }
    }

    [Fact]
    public void Remove_RemovesPath()
    {
        string path = TempFile();
        try
        {
            var service = new RecentFilesService(path);
            service.Add("C:\\a.mad");
            service.Add("C:\\b.mad");
            service.Remove("C:\\a.mad");

            Assert.Equal(new[] { "C:\\b.mad" }, service.Get().ToArray());
        }
        finally
        {
            if (File.Exists(path)) File.Delete(path);
        }
    }

    [Fact]
    public void Get_OnMissingFile_ReturnsEmpty()
    {
        string path = Path.Combine(Path.GetTempPath(), $"mad-missing-{Guid.NewGuid():N}.json");
        Assert.Empty(new RecentFilesService(path).Get());
    }

    [Fact]
    public void Add_WhenTheStoreCannotBeWritten_DoesNotThrow()
    {
        // A regular file where the store's directory should be makes Directory.CreateDirectory
        // fail. Persisting the recent list is best-effort: opening a report must not terminate
        // the app because %APPDATA% is unavailable.
        string blocker = Path.Combine(Path.GetTempPath(), $"mad-blocker-{Guid.NewGuid():N}");
        File.WriteAllText(blocker, "not a directory");
        try
        {
            var service = new RecentFilesService(Path.Combine(blocker, "recent.json"));
            service.Add("C:\\a.mad");
            service.Remove("C:\\a.mad");
        }
        finally
        {
            if (File.Exists(blocker)) File.Delete(blocker);
        }
    }
}
