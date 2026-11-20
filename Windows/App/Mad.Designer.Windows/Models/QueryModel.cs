//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using System.Text.Json;
using Mad.Designer.Windows.Infrastructure;

namespace Mad.Designer.Windows.Models;

/// <summary>A join type, matching the engine's <c>MADLinkType</c> (MADQueryLinkType.h).</summary>
public enum LinkType
{
    InnerJoin = 0,
    EquiJoin = 1,
    NaturalJoin = 2,
    CrossJoin = 3,
    LeftOuterJoin = 4,
    RightOuterJoin = 5,
    FullOuterJoin = 6,
    Unknown = 7,
}

/// <summary>A WHERE comparison operator, matching <c>MADPredicateOperator</c>.</summary>
public enum PredicateOperator
{
    Equal = 0,
    NotEqual = 1,
    GreaterThan = 2,
    GreaterThanOrEqualTo = 3,
    LessThan = 4,
    LessThanOrEqualTo = 5,
}

/// <summary>A GROUP BY sort direction, matching <c>MADSortOrder</c>.</summary>
public enum GroupSort
{
    Ascending = 0,
    Descending = 1,
}

public static class LinkTypeExtensions
{
    /// <summary>The join's short SQL badge ("LEFT OUTER", "INNER", …), as the Mac's canvas shows.</summary>
    public static string ShortBadge(this LinkType type) => type switch
    {
        LinkType.InnerJoin => "INNER",
        LinkType.EquiJoin => "EQUI",
        LinkType.NaturalJoin => "NATURAL",
        LinkType.CrossJoin => "CROSS",
        LinkType.RightOuterJoin => "RIGHT OUTER",
        LinkType.FullOuterJoin => "FULL OUTER",
        _ => "LEFT OUTER",
    };

    /// <summary>The user-facing name ("Left Outer Join", "Inner Join", …).</summary>
    public static string DisplayName(this LinkType type) => type switch
    {
        LinkType.InnerJoin => Localizer.Get("Join.Inner"),
        LinkType.EquiJoin => Localizer.Get("Join.Equi"),
        LinkType.NaturalJoin => Localizer.Get("Join.Natural"),
        LinkType.CrossJoin => Localizer.Get("Join.Cross"),
        LinkType.RightOuterJoin => Localizer.Get("Join.RightOuter"),
        LinkType.FullOuterJoin => Localizer.Get("Join.FullOuter"),
        _ => Localizer.Get("Join.LeftOuter"),
    };

    /// <summary>The join types the current driver supports, in the Mac's order (Left Outer first).</summary>
    public static IReadOnlyList<LinkType> SupportedJoinTypes(string? driverToken) => driverToken switch
    {
        // MySQL cannot express FULL OUTER or NATURAL through this engine's generator.
        "mysql" => [LinkType.LeftOuterJoin, LinkType.InnerJoin, LinkType.RightOuterJoin, LinkType.EquiJoin, LinkType.CrossJoin],
        // TDS (Microsoft SQL Server) cannot express NATURAL JOIN.
        "sqlserver" => [LinkType.LeftOuterJoin, LinkType.InnerJoin, LinkType.RightOuterJoin, LinkType.FullOuterJoin, LinkType.EquiJoin, LinkType.CrossJoin],
        _ => [LinkType.LeftOuterJoin, LinkType.InnerJoin, LinkType.RightOuterJoin, LinkType.FullOuterJoin, LinkType.EquiJoin, LinkType.NaturalJoin, LinkType.CrossJoin],
    };
}

public static class PredicateOperatorExtensions
{
    public static string Symbol(this PredicateOperator op) => op switch
    {
        PredicateOperator.NotEqual => "!=",
        PredicateOperator.GreaterThan => ">",
        PredicateOperator.GreaterThanOrEqualTo => ">=",
        PredicateOperator.LessThan => "<",
        PredicateOperator.LessThanOrEqualTo => "<=",
        _ => "=",
    };
}

/// <summary>One query field: its store identifier, its schema field name, and its type token.</summary>
public sealed record QueryField(long Id, string Name, string Type);

/// <summary>One query table (a placed card) and its fields.</summary>
public sealed record QueryTable(long Id, string Name, string Alias, long DropIndex, IReadOnlyList<QueryField> Fields);

/// <summary>One join between two query fields.</summary>
public sealed record QueryLink(long Id, LinkType Type, long LeftField, long RightField);

/// <summary>One WHERE predicate: a field (or literal) on each side of an operator.</summary>
public sealed record QueryPredicate(long Id, PredicateOperator Operator, long LeftField, long RightField, string? LeftValue, string? RightValue);

/// <summary>One GROUP BY level over a field.</summary>
public sealed record QueryGroup(long Id, long Field, GroupSort Sort);

/// <summary>The full query model the engine exposes over <c>query-model</c>.</summary>
public sealed record QueryModel(
    string Driver,
    string Sql,
    string SqlSourceText,
    IReadOnlyList<QueryTable> Tables,
    IReadOnlyList<QueryLink> Links,
    IReadOnlyList<QueryPredicate> Predicates,
    IReadOnlyList<QueryGroup> Groups)
{
    public static QueryModel Parse(JsonElement root)
    {
        string driver = root.TryGetProperty("driver", out var d) ? d.GetString() ?? "" : "";
        string sql = root.TryGetProperty("sql", out var s) ? s.GetString() ?? "" : "";
        string sqlSource = root.TryGetProperty("sqlSourceText", out var st) ? st.GetString() ?? "" : "";

        var tables = new List<QueryTable>();
        foreach (var table in root.GetProperty("tables").EnumerateArray())
        {
            var fields = new List<QueryField>();
            foreach (var field in table.GetProperty("fields").EnumerateArray())
            {
                fields.Add(new QueryField(
                    field.GetProperty("id").GetInt64(),
                    field.GetProperty("name").GetString() ?? "",
                    field.GetProperty("type").GetString() ?? ""));
            }
            tables.Add(new QueryTable(
                table.GetProperty("id").GetInt64(),
                table.GetProperty("name").GetString() ?? "",
                table.GetProperty("alias").GetString() ?? "",
                table.GetProperty("dropIndex").GetInt64(),
                fields));
        }

        var links = new List<QueryLink>();
        foreach (var link in root.GetProperty("links").EnumerateArray())
        {
            links.Add(new QueryLink(
                link.GetProperty("id").GetInt64(),
                (LinkType)link.GetProperty("type").GetInt32(),
                link.GetProperty("leftField").GetInt64(),
                link.GetProperty("rightField").GetInt64()));
        }

        var predicates = new List<QueryPredicate>();
        foreach (var predicate in root.GetProperty("predicates").EnumerateArray())
        {
            predicates.Add(new QueryPredicate(
                predicate.GetProperty("id").GetInt64(),
                (PredicateOperator)predicate.GetProperty("operator").GetInt32(),
                predicate.GetProperty("leftField").GetInt64(),
                predicate.GetProperty("rightField").GetInt64(),
                predicate.TryGetProperty("leftValue", out var lv) && lv.ValueKind == JsonValueKind.String ? lv.GetString() : null,
                predicate.TryGetProperty("rightValue", out var rv) && rv.ValueKind == JsonValueKind.String ? rv.GetString() : null));
        }

        var groups = new List<QueryGroup>();
        foreach (var group in root.GetProperty("groups").EnumerateArray())
        {
            groups.Add(new QueryGroup(
                group.GetProperty("id").GetInt64(),
                group.GetProperty("field").GetInt64(),
                (GroupSort)group.GetProperty("sort").GetInt32()));
        }

        return new QueryModel(driver, sql, sqlSource, tables, links, predicates, groups);
    }
}

/// <summary>The result of <c>validate-sql</c> / <c>apply-sql</c>: the plan's counts.</summary>
public sealed record SqlCompileResult(int Tables, int Links, int Predicates, int Groups)
{
    public static SqlCompileResult Parse(JsonElement root) => new(
        root.GetProperty("tables").GetInt32(),
        root.GetProperty("links").GetInt32(),
        root.GetProperty("predicates").GetInt32(),
        root.GetProperty("groups").GetInt32());
}
