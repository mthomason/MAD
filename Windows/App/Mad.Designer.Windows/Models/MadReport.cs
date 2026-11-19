//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using System.Data;
using System.Text.Json;

namespace Mad.Designer.Windows.Models;

/// <summary>The parsed `mad.report/1` object the `export` json format returns: columns
/// plus rows keyed by column key. <see cref="ToDataTable"/> turns it into the dynamic-column
/// table the viewer's DataGrid binds to.</summary>
public sealed class MadReport
{
    public required string Format { get; init; }
    public required string Driver { get; init; }
    public required string Sql { get; init; }
    public required int RowCount { get; init; }
    public required IReadOnlyList<ReportColumn> Columns { get; init; }
    public required IReadOnlyList<IReadOnlyDictionary<string, object?>> Rows { get; init; }

    public static MadReport Parse(string json)
    {
        using var document = JsonDocument.Parse(json);
        var root = document.RootElement;

        string format = root.GetProperty("format").GetString() ?? "";
        string driver = root.GetProperty("document").GetProperty("driver").GetString() ?? "";
        string sql = root.GetProperty("query").GetProperty("sql").GetString() ?? "";
        int rowCount = root.GetProperty("query").GetProperty("rowCount").GetInt32();

        var columns = new List<ReportColumn>();
        foreach (var column in root.GetProperty("columns").EnumerateArray())
        {
            columns.Add(new ReportColumn(
                column.GetProperty("key").GetString() ?? "",
                column.GetProperty("name").GetString() ?? "",
                column.GetProperty("table").GetString(),
                column.GetProperty("type").GetString()));
        }

        var rows = new List<IReadOnlyDictionary<string, object?>>();
        foreach (var row in root.GetProperty("rows").EnumerateArray())
        {
            var values = new Dictionary<string, object?>();
            foreach (var property in row.EnumerateObject())
            {
                values[property.Name] = ConvertValue(property.Value);
            }
            rows.Add(values);
        }

        return new MadReport
        {
            Format = format,
            Driver = driver,
            Sql = sql,
            RowCount = rowCount,
            Columns = columns,
            Rows = rows,
        };
    }

    public DataTable ToDataTable()
    {
        var table = new DataTable();
        foreach (var column in Columns)
        {
            var dataColumn = table.Columns.Add(column.Key, typeof(object));
            dataColumn.Caption = column.Name;
        }

        foreach (var row in Rows)
        {
            var dataRow = table.NewRow();
            foreach (var column in Columns)
            {
                dataRow[column.Key] = row.TryGetValue(column.Key, out var value) && value != null ? value : DBNull.Value;
            }
            table.Rows.Add(dataRow);
        }

        return table;
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
