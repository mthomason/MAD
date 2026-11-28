//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using Mad.Designer.Windows.Infrastructure;
using Mad.Designer.Windows.Models;

namespace Mad.Designer.Windows.ViewModels;

/// <summary>What the app shows for one composition source that needs a credential:
/// the source's name (which the prompt names), and the connection with host, port,
/// database and the username hint prefilled and the password empty.</summary>
public sealed record SourceCredentialPrompt(long QueryId, string Name, ConnectionSpec Initial, string Message);

/// <summary>The connection window's answer: the entered connection and whether the
/// "Save password in Windows Credential Manager" box stayed checked.</summary>
public sealed record SourceCredentialResult(ConnectionSpec Spec, bool SaveCredentials);

/// <summary>Resolves one credential per composition source.  A source first uses the
/// credential entered this session (keyed by its query id), then Windows Credential
/// Manager under its <see cref="ConnectionSpec.CredentialKey"/>
/// (<c>driver:host:port/database</c>); a source with neither is asked for, one sheet
/// at a time.  Keeping the session credentials per query id means one source's
/// password is never offered to another, even when two sources share a server.</summary>
public sealed class SourceCredentialCollector
{
    private readonly ICredentialStore? _store;
    private readonly Func<SourceCredentialPrompt, Task<SourceCredentialResult?>>? _prompt;
    private readonly Dictionary<long, (string Username, string Password)> _session = new();
    // Credentials the user asked to save, held until the refresh that used them
    // succeeds: a rejected password is never written to Credential Manager.
    private readonly List<(string Key, string Username, string Password)> _pendingSaves = new();

    public SourceCredentialCollector(
        ICredentialStore? store,
        Func<SourceCredentialPrompt, Task<SourceCredentialResult?>>? prompt = null)
    {
        _store = store;
        _prompt = prompt;
    }

    /// <summary>True when a missing credential can be asked for; false in a headless
    /// or test run, where the engine's own source-named error is surfaced instead.</summary>
    public bool CanPrompt => _prompt != null;

    /// <summary>A source is a non-root, non-composing leaf whose connection takes
    /// credentials.  A composing node carries its first source's database row in
    /// document-info, but it is not a source: its children connect, not it.</summary>
    public static bool RequiresCredential(QueryInfo query)
        => !query.IsRoot
           && !query.IsComposing
           && query.Connection is { RequiresCredentials: true }
           && query.Connection.ToSpec().CredentialKey != null;

    /// <summary>The leaf sources a composition must configure, in document order.</summary>
    public static IEnumerable<QueryInfo> SourcesRequiringCredentials(IEnumerable<QueryInfo> queries)
        => queries.Where(RequiresCredential);

    /// <summary>The `user:password` this source can use now, or null when it has none.</summary>
    public string? Resolve(QueryInfo query)
    {
        if (!RequiresCredential(query)) return null;

        if (_session.TryGetValue(query.Id, out var session) && Usable(session.Username, session.Password))
        {
            return CredentialString(session.Username, session.Password);
        }

        ConnectionSpec spec = query.Connection!.ToSpec();
        if (_store != null && spec.CredentialKey is string key
            && _store.TryRead(key, out string user, out string password)
            && Usable(user, password))
        {
            return CredentialString(user, password);
        }
        return null;
    }

    /// <summary>
    /// Collects the credentials every source needs.  A source with a resolved
    /// credential contributes it; a missing one is prompted for in turn.  Answers
    /// null when the user cancels a sheet.  When no prompt is available the map is
    /// returned as far as it goes, so the engine names the source that lacked one.
    /// </summary>
    public async Task<Dictionary<long, string>?> CollectAsync(IReadOnlyList<QueryInfo> sources)
    {
        var map = new Dictionary<long, string>();
        var missing = new List<QueryInfo>();
        foreach (QueryInfo source in SourcesRequiringCredentials(sources))
        {
            string? credential = Resolve(source);
            if (credential != null) map[source.Id] = credential;
            else missing.Add(source);
        }

        foreach (QueryInfo source in missing)
        {
            // With no sheet to show (a headless or test run), leave the source out of
            // the map: the engine names it in its error instead of silently skipping it.
            if (!CanPrompt) continue;

            string? credential = await PromptForSourceAsync(source);
            if (credential == null)
            {
                DiscardPendingSaves();
                return null;
            }
            map[source.Id] = credential;
        }
        return map;
    }

    /// <summary>Writes the credentials the user chose to save once the refresh that
    /// used them succeeds.  Called by the document after a successful refresh.</summary>
    public void CommitPendingSaves()
    {
        foreach ((string key, string username, string password) in _pendingSaves)
        {
            _store?.Save(key, username, password);
        }
        _pendingSaves.Clear();
    }

    /// <summary>Forgets saves whose refresh never succeeded (a rejected or abandoned
    /// credential), so the stale password is never stored.</summary>
    public void DiscardPendingSaves() => _pendingSaves.Clear();

    /// <summary>Prompts for one source, then remembers and (when requested) saves the
    /// credential.  Answers the `user:password`, or null when the user cancelled.</summary>
    public async Task<string?> PromptForSourceAsync(QueryInfo source)
    {
        if (_prompt == null || source.Connection == null) return null;

        ConnectionSpec spec = source.Connection.ToSpec(password: "");
        if (!string.IsNullOrEmpty(spec.Username) && _store != null
            && spec.CredentialKey is string key
            && _store.TryRead(key, out string savedUser, out _)
            && !string.IsNullOrEmpty(savedUser))
        {
            spec = spec with { Username = savedUser };
        }

        string name = string.IsNullOrEmpty(source.Name)
            ? Localizer.Get("Composition.Source")
            : source.Name;
        string message = Localizer.Format("Document.SourceCredentials.Prompt", name);
        SourceCredentialResult? result = await _prompt(
            new SourceCredentialPrompt(source.Id, name, spec, message));
        if (result == null) return null;

        string? username = result.Spec.Username;
        string? password = result.Spec.Password;
        Remember(source.Id, username, password);
        // The map is applied to the source's own connection string, so save under that
        // key even if the user edited the sheet's host/database.  The write is deferred
        // until the refresh proves the credential works, and a re-prompt replaces an
        // earlier pending value for the same source (or cancels it when Save is off).
        string? sourceKey = source.Connection.ToSpec().CredentialKey ?? result.Spec.CredentialKey;
        if (sourceKey != null)
        {
            _pendingSaves.RemoveAll(pending => pending.Key == sourceKey);
            // An empty or partial pair is not a credential the refresh can use, so it
            // is never written to Credential Manager.
            if (result.SaveCredentials && Usable(username, password))
            {
                _pendingSaves.Add((sourceKey, username ?? "", password ?? ""));
            }
        }
        return CredentialString(username, password);
    }

    /// <summary>Remembers a credential entered this session (a source connection edit).</summary>
    public void Remember(long queryId, string? username, string? password)
        => _session[queryId] = (username ?? "", password ?? "");

    private static bool Usable(string? username, string? password)
        => !string.IsNullOrEmpty(username) && !string.IsNullOrEmpty(password);

    private static string CredentialString(string? username, string? password)
        => $"{username ?? ""}:{password ?? ""}";
}
