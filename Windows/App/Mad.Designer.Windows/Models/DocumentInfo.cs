//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using System.Text.Json;

namespace Mad.Designer.Windows.Models;

/// <summary>One query in a document, as the engine's <c>document-info</c> lists it.</summary>
public sealed record QueryInfo(long Id, string Name, bool IsRoot)
{
    internal static QueryInfo Parse(JsonElement e) => new(
        e.GetProperty("id").GetInt64(),
        e.GetProperty("name").GetString() ?? "",
        e.TryGetProperty("isRoot", out var root)
            && (root.ValueKind == JsonValueKind.True
                || (root.ValueKind == JsonValueKind.Number && root.GetInt32() != 0)));
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
