//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

namespace Mad.Designer.Windows.Models;

/// <summary>One report column, as `mad.report/1` and `describe` both spell it.</summary>
public sealed record ReportColumn(string Key, string Name, string? Table, string? Type);

/// <summary>One stored-schema field (the `describe` tables list).</summary>
public sealed record SchemaField(string Name, string Type, bool PrimaryKey);

/// <summary>One stored-schema table and its fields.</summary>
public sealed record SchemaTable(string Name, IReadOnlyList<SchemaField> Fields);

/// <summary>The `open` result: a document handle plus its file and driver.</summary>
public sealed record OpenResult(int Handle, string Filename, string Driver);

/// <summary>The `describe` result: the driver, the report columns, and the stored schema.</summary>
public sealed record DescribeResult(string Driver, IReadOnlyList<ReportColumn> Columns, IReadOnlyList<SchemaTable> Tables);

/// <summary>The `refresh` result: how many rows the query produced and how long it took.</summary>
public sealed record RefreshResult(int RowCount, double Elapsed);

/// <summary>The `write` result: the destination path and the number of bytes written.</summary>
public sealed record WriteResult(string Path, long Bytes);
