//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using System.Text.Json;

namespace Mad.Designer.Windows.Models;

/// <summary>A query's source connection, as <c>document-info</c> reports it.  A leaf
/// carries one so the app can prompt for its password or edit its connection without
/// the document-level connection; a composing node has none.  <see cref="UsernameHint"/>
/// is the username the document records (the credential row's non-secret `domain`),
/// never a password.</summary>
public sealed record QueryConnection(
    ConnectionDriver Driver,
    string? File,
    string? Host,
    int? Port,
    string? Database,
    string? ServerInstance,
    bool RequiresCredentials,
    string? UsernameHint)
{
    internal static QueryConnection? Parse(JsonElement e)
    {
        string token = e.TryGetProperty("driver", out var driverElement) && driverElement.ValueKind == JsonValueKind.String
            ? driverElement.GetString() ?? "" : "";
        ConnectionDriver driver;
        try
        {
            driver = ConnectionSpec.DriverFromToken(token);
        }
        catch (ArgumentException)
        {
            return null;
        }

        string? Str(string name) => e.TryGetProperty(name, out var value) && value.ValueKind == JsonValueKind.String
            ? value.GetString() : null;
        int? port = e.TryGetProperty("port", out var portElement) && portElement.ValueKind == JsonValueKind.Number
            ? portElement.GetInt32() : null;

        bool requires = e.TryGetProperty("requiresCredentials", out var requiresElement)
            && (requiresElement.ValueKind == JsonValueKind.True
                || (requiresElement.ValueKind == JsonValueKind.Number && requiresElement.GetInt32() != 0));

        return new QueryConnection(driver, Str("file"), Str("host"), port, Str("database"),
            Str("server"), requires, Str("usernameHint"));
    }

    /// <summary>The connection as the connection window collects it.  The username
    /// defaults to the document's hint; the password is never in the document.</summary>
    public ConnectionSpec ToSpec(string? username = null, string? password = null)
        => new(Driver, File, Host, Port, Database, ServerInstance,
            username ?? UsernameHint, password);
}

/// <summary>One query in a document, as the engine's <c>document-info</c> lists it.</summary>
public sealed record QueryInfo(long Id, string Name, bool IsRoot, bool IsComposing = false, QueryConnection? Connection = null)
{
    internal static QueryInfo Parse(JsonElement e) => new(
        e.GetProperty("id").GetInt64(),
        e.GetProperty("name").GetString() ?? "",
        e.TryGetProperty("isRoot", out var root)
            && (root.ValueKind == JsonValueKind.True
                || (root.ValueKind == JsonValueKind.Number && root.GetInt32() != 0)),
        e.TryGetProperty("isComposing", out var composing)
            && (composing.ValueKind == JsonValueKind.True
                || (composing.ValueKind == JsonValueKind.Number && composing.GetInt32() != 0)),
        e.TryGetProperty("connection", out var connection) && connection.ValueKind == JsonValueKind.Object
            ? QueryConnection.Parse(connection) : null);
}

/// <summary>The document's type and its queries, from the engine's <c>document-info</c>.
/// <see cref="Composed"/> distinguishes a Composition Report from a Standard Report;
/// the selected query is tracked separately by the client.</summary>
public sealed record DocumentInfo(bool Composed, long RootQuery, IReadOnlyList<QueryInfo> Queries)
{
    public static DocumentInfo Parse(JsonElement root)
    {
        bool composed = root.TryGetProperty("composed", out var composedEl)
            && (composedEl.ValueKind == JsonValueKind.True || composedEl.ValueKind == JsonValueKind.Number && composedEl.GetInt32() != 0);

        long rootQuery = root.TryGetProperty("rootQuery", out var rootEl) && rootEl.ValueKind == JsonValueKind.Number
            ? rootEl.GetInt64() : 0;

        var queries = new List<QueryInfo>();
        if (root.TryGetProperty("queries", out var queriesEl))
        {
            foreach (var e in queriesEl.EnumerateArray()) queries.Add(QueryInfo.Parse(e));
        }
        return new DocumentInfo(composed, rootQuery, queries);
    }
}

/// <summary>One composed root output: a field and its persisted output key, in order.</summary>
public sealed record RootOutput(long Field, string Key);
