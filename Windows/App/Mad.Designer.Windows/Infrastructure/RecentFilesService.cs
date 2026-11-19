//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using System.IO;
using System.Text.Json;

namespace Mad.Designer.Windows.Infrastructure;

/// <summary>The client-side recent-documents list, persisted as a JSON array at
/// <c>%APPDATA%\MAD\recent.json</c> (most-recent-first, capped at ten).</summary>
public sealed class RecentFilesService
{
    private const int MaxEntries = 10;
    private readonly string _path;

    public RecentFilesService(string? filePath = null)
    {
        _path = filePath ?? Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
            "MAD", "recent.json");
    }

    public IReadOnlyList<string> Get()
    {
        if (!File.Exists(_path))
        {
            return Array.Empty<string>();
        }
        try
        {
            return JsonSerializer.Deserialize<List<string>>(File.ReadAllText(_path)) ?? new List<string>();
        }
        catch (JsonException)
        {
            return Array.Empty<string>();
        }
        catch (IOException)
        {
            return Array.Empty<string>();
        }
    }

    public void Add(string path)
    {
        var list = new List<string>(Get());
        list.RemoveAll(existing => string.Equals(existing, path, StringComparison.OrdinalIgnoreCase));
        list.Insert(0, path);
        if (list.Count > MaxEntries)
        {
            list.RemoveRange(MaxEntries, list.Count - MaxEntries);
        }
        Write(list);
    }

    public void Remove(string path)
    {
        var list = new List<string>(Get());
        list.RemoveAll(existing => string.Equals(existing, path, StringComparison.OrdinalIgnoreCase));
        Write(list);
    }

    private void Write(List<string> list)
    {
        string directory = Path.GetDirectoryName(_path)!;
        Directory.CreateDirectory(directory);
        string temp = _path + "." + Guid.NewGuid().ToString("N") + ".tmp";
        File.WriteAllText(temp, JsonSerializer.Serialize(list));
        File.Move(temp, _path, overwrite: true);
    }
}
