//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using System.Data;
using System.Text.Json;

namespace Mad.Designer.Windows.Models;

/// <summary>One column of a node's materialized result, as the engine's <c>node-result</c>
/// spells it.</summary>
public sealed record NodeResultColumn(string Key, string Name, string? Table, string? Type);

/// <summary>A node's materialized rows — the query-scoped read of the selected node's
/// retained result (the root's published result, or a source's from the per-node map).
/// Rows are positional, in <see cref="Columns"/> order. <see cref="ToDataTable"/> turns it
/// into the dynamic-column table the Viewer's row grid binds to, the same way
/// <see cref="MadReport"/> does for the root.</summary>
public sealed record NodeResult(
    long Query,
    string Name,
    int RowCount,
    IReadOnlyList<NodeResultColumn> Columns,
    IReadOnlyList<IReadOnlyList<object?>> Rows)
{
    public static NodeResult Parse(JsonElement root)
    {
        long query = root.TryGetProperty("query", out var q) && q.ValueKind == JsonValueKind.Number ? q.GetInt64() : 0;
        string name = root.TryGetProperty("name", out var n) && n.ValueKind == JsonValueKind.String ? n.GetString() ?? "" : "";
        int rowCount = root.TryGetProperty("rowCount", out var rc) && rc.ValueKind == JsonValueKind.Number ? rc.GetInt32() : 0;

        var columns = new List<NodeResultColumn>();
        if (root.TryGetProperty("columns", out var columnsEl) && columnsEl.ValueKind == JsonValueKind.Array)
        {
            foreach (var column in columnsEl.EnumerateArray())
            {
                columns.Add(new NodeResultColumn(
                    column.GetProperty("key").GetString() ?? "",
                    column.TryGetProperty("name", out var cn) && cn.ValueKind == JsonValueKind.String ? cn.GetString() ?? "" : "",
                    column.TryGetProperty("table", out var ct) && ct.ValueKind == JsonValueKind.String ? ct.GetString() : null,
                    column.TryGetProperty("type", out var cty) && cty.ValueKind == JsonValueKind.String ? cty.GetString() : null));
            }
        }

        var rows = new List<IReadOnlyList<object?>>();
        if (root.TryGetProperty("rows", out var rowsEl) && rowsEl.ValueKind == JsonValueKind.Array)
        {
            foreach (var row in rowsEl.EnumerateArray())
            {
                var values = new List<object?>();
                foreach (var cell in row.EnumerateArray()) values.Add(ConvertValue(cell));
                rows.Add(values);
            }
        }

        return new NodeResult(query, name, rowCount, columns, rows);
    }

    public DataTable ToDataTable()
    {
        // The grid's headers are the columns' display names, not their qualified keys
        // ("amount", not "\"payments0\".\"amount\""). Duplicate names fall back to the key.
        var table = new DataTable();
        var names = new List<string>(Columns.Count);
        var used = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        foreach (var column in Columns)
        {
            string name = Friendly(column.Name);
            if (string.IsNullOrWhiteSpace(name)) name = Friendly(column.Key);
            if (string.IsNullOrWhiteSpace(name)) name = $"Column {names.Count + 1}";
            if (!used.Add(name))
            {
                // A duplicate display name (e.g. two tables' `amount`) falls back to the key.
                name = string.IsNullOrWhiteSpace(column.Key) ? $"{name} ({names.Count + 1})" : column.Key;
                used.Add(name);
            }
            table.Columns.Add(name, typeof(object));
            names.Add(name);
        }

        foreach (var row in Rows)
        {
            var dataRow = table.NewRow();
            for (int i = 0; i < names.Count; i++)
            {
                dataRow[names[i]] = i < row.Count && row[i] != null ? row[i]! : DBNull.Value;
            }
            table.Rows.Add(dataRow);
        }

        return table;
    }

    /// <summary>The engine may spell a node column's name as its qualified key
    /// (<c>"payments0"."amount"</c>); the grid header shows the bare field name.</summary>
    private static string Friendly(string name)
    {
        if (string.IsNullOrEmpty(name)) return "";
        int dot = name.LastIndexOf('.');
        string tail = dot >= 0 ? name[(dot + 1)..] : name;
        return tail.Trim().Trim('"');
    }

    private static object? ConvertValue(JsonElement element)
    {
        return element.ValueKind switch
        {
            JsonValueKind.String => element.GetString(),
            JsonValueKind.Number => element.GetDecimal(),
            JsonValueKind.True => true,
            JsonValueKind.False => false,
            JsonValueKind.Null => null,
            _ => element.GetRawText(),
        };
    }
}
