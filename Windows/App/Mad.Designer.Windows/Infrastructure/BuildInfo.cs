//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using System.IO;
using System.Text.Json;

namespace Mad.Designer.Windows.Infrastructure;

/// <summary>The generated per-build identity (MADBuildInfo.json) beside the app.  It is
/// a build product, never a committed file: an app built without it reports unknown
/// rather than a guess.  The engine's own identity is asked of the engine; this record
/// carries only the application's identity and the source commit.</summary>
public sealed record BuildInfo(
    string? AppVersion,
    string? AppBuild,
    string? EngineVersion,
    string? EngineRevision,
    string? SourceCommit,
    string? SourceCommitShort,
    bool SourceDirty)
{
    /// <summary>The identity of a build that produced no MADBuildInfo.json.</summary>
    public static BuildInfo Missing { get; } =
        new(null, null, null, null, null, null, false);

    /// <summary>Reads MADBuildInfo.json from the application's base directory.  Any
    /// failure -- absent file, malformed JSON, unreadable directory -- answers
    /// <see cref="Missing"/>; this method never throws.</summary>
    public static BuildInfo Load()
    {
        try
        {
            string path = Path.Combine(AppContext.BaseDirectory, "MADBuildInfo.json");
            if (!File.Exists(path)) return Missing;

            using var document = JsonDocument.Parse(File.ReadAllText(path));
            JsonElement root = document.RootElement;

            string? Value(string name) =>
                root.TryGetProperty(name, out JsonElement value)
                && value.ValueKind == JsonValueKind.String
                    ? value.GetString()
                    : null;

            bool dirty = root.TryGetProperty("MADSourceDirty", out JsonElement dirtyValue)
                && dirtyValue.ValueKind == JsonValueKind.True;

            return new BuildInfo(
                Value("MADAppVersion"),
                Value("MADAppBuild"),
                Value("MADEngineVersion"),
                Value("MADEngineRevision"),
                Value("MADSourceCommit"),
                Value("MADSourceCommitShort"),
                dirty);
        }
        catch
        {
            return Missing;
        }
    }
}
