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
    [InlineData("false", false)]
    [InlineData("0", false)]
    public void QueryModel_ReadsTheComposingFlagFromEitherEncoding(string flag, bool expected)
    {
        string json = $$"""
            {
              "driver": "sqlite3",
              "tables": [], "links": [], "predicates": [], "groups": [],
              "queryId": 9,
              "isRoot": false,
              "isComposing": {{flag}}
            }
            """;

        using JsonDocument document = JsonDocument.Parse(json);
        Assert.Equal(expected, QueryModel.Parse(document.RootElement).IsComposing);
    }

    [Fact]
    public void DocumentInfo_ReportsAConnectionOnlyForALeaf()
    {
        string json = """
            {
              "composed": true,
              "rootQuery": 1,
              "queries": [
                { "id": 1, "name": "Result", "isRoot": true, "isComposing": true },
                { "id": 2, "name": "MySQL", "isRoot": false, "isComposing": false,
                  "connection": { "driver": "mysql", "host": "127.0.0.1", "port": 3306,
                                  "database": "db", "requiresCredentials": true,
                                  "usernameHint": "root", "connectionString": "(MySQL)[127.0.0.1:3306]db" } },
                { "id": 3, "name": "Composer", "isRoot": false, "isComposing": true }
              ]
            }
            """;

        using JsonDocument document = JsonDocument.Parse(json);
        DocumentInfo info = DocumentInfo.Parse(document.RootElement);

        Assert.Null(info.Queries.Single(q => q.Id == 1).Connection);
        Assert.Null(info.Queries.Single(q => q.Id == 3).Connection);

        QueryConnection leaf = info.Queries.Single(q => q.Id == 2).Connection!;
        Assert.Equal(ConnectionDriver.MySql, leaf.Driver);
        Assert.Equal("127.0.0.1", leaf.Host);
        Assert.Equal(3306, leaf.Port);
        Assert.Equal("db", leaf.Database);
        Assert.True(leaf.RequiresCredentials);
        Assert.Equal("root", leaf.UsernameHint);
        Assert.Equal("mysql:127.0.0.1:3306/db", leaf.ToSpec().CredentialKey);
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
