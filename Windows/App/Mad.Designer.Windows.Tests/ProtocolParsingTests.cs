//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using System.Text.Json;
using Mad.Designer.Windows.Models;

namespace Mad.Designer.Windows.Tests;

/// <summary>The engine writes `isRoot` as a JSON boolean in document-info but as 1/0 in
/// query-model (an NSNumber made from a BOOL expression). Both forms must read as the same
/// fact, or the Result's Query workspace shows schema tables instead of its sources.</summary>
public sealed class ProtocolParsingTests
{
    [Theory]
    [InlineData("true", true)]
    [InlineData("1", true)]
    [InlineData("false", false)]
    [InlineData("0", false)]
    public void QueryModel_ReadsTheRootFlagFromEitherEncoding(string flag, bool expected)
    {
        string json = $$"""
            {
              "driver": "sqlite3",
              "tables": [], "links": [], "predicates": [], "groups": [],
              "queryId": 7,
              "isRoot": {{flag}}
            }
            """;

        using JsonDocument document = JsonDocument.Parse(json);
        Assert.Equal(expected, QueryModel.Parse(document.RootElement).IsRoot);
    }

    [Theory]
    [InlineData("true", true)]
    [InlineData("1", true)]
    [InlineData("0", false)]
    public void DocumentInfo_ReadsAQueryRootFlagFromEitherEncoding(string flag, bool expected)
    {
        string json = $$"""
            {
              "composed": true,
              "rootQuery": 1,
              "queries": [ { "id": 1, "name": "Result", "isRoot": {{flag}} } ]
            }
            """;

        using JsonDocument document = JsonDocument.Parse(json);
        Assert.Equal(expected, DocumentInfo.Parse(document.RootElement).Queries[0].IsRoot);
    }
}
