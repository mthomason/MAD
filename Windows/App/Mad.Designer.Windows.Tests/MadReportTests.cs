//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using Mad.Designer.Windows.Engine;
using Mad.Designer.Windows.Infrastructure;
using Mad.Designer.Windows.Models;

namespace Mad.Designer.Windows.Tests;

[Collection("Engine")]
public sealed class MadReportTests
{
    private const string SampleReport = """
{
  "format": "mad.report/1",
  "document": { "driver": "Sqlite 3" },
  "query": { "sql": "SELECT * FROM A", "rowCount": 3 },
  "columns": [
    { "key": "A.Id", "name": "Id", "table": "A", "type": "Integer" },
    { "key": "B.Id", "name": "Id", "table": "B", "type": "Integer" },
    { "key": "A.Name", "name": "Name", "table": "A", "type": "String" }
  ],
  "rows": [
    { "A.Id": 1, "B.Id": 10, "A.Name": "One" },
    { "A.Id": 2, "B.Id": 20, "A.Name": null },
    { "A.Id": 3, "B.Id": 30, "A.Name": "Three" }
  ]
}
""";

    [Fact]
    public void Parse_ExtractsColumnsAndRows()
    {
        var report = MadReport.Parse(SampleReport);
        Assert.Equal("mad.report/1", report.Format);
        Assert.Equal(3, report.Columns.Count);
        Assert.Equal(3, report.Rows.Count);
        Assert.Null(report.Rows[1]["A.Name"]);
        Assert.Equal(1m, Assert.IsType<decimal>(report.Rows[0]["A.Id"]));
    }

    [Fact]
    public void NullCells_BecomeDBNull()
    {
        var table = MadReport.Parse(SampleReport).ToDataTable();
        Assert.Equal(DBNull.Value, table.Rows[1]["A.Name"]);
    }

    [Fact]
    public void DuplicateNames_KeyOnKey()
    {
        var table = MadReport.Parse(SampleReport).ToDataTable();
        Assert.Equal(3, table.Columns.Count);
        Assert.Equal("A.Id", table.Columns[0].ColumnName);
        Assert.Equal("B.Id", table.Columns[1].ColumnName);
        Assert.Equal("Id", table.Columns[0].Caption);
        Assert.Equal("Id", table.Columns[1].Caption);
    }

    [Fact]
    public async Task Parse_LondonExport_Has76Rows()
    {
        await using var service = new EngineService();
        var open = await service.OpenAsync(MadPathResolver.DefaultDocument());
        _ = await service.RefreshAsync(open.Handle);
        string json = await service.ExportAsync(open.Handle, "json");

        var report = MadReport.Parse(json);
        Assert.Equal(76, report.RowCount);
        Assert.Equal(76, report.Rows.Count);
        Assert.Equal(21, report.Columns.Count);
    }
}
