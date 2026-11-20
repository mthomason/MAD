//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using System.IO;
using System.Security.Cryptography;
using Mad.Designer.Windows.Engine;
using Mad.Designer.Windows.Infrastructure;
using Mad.Designer.Windows.Models;
using Mad.Designer.Windows.ViewModels;
using Xunit.Abstractions;

namespace Mad.Designer.Windows.Tests;

/// <summary>The WPF smoke test — the counterpart of <c>Mac/Tests/MADMacSmokeTest.m</c>, driven at
/// the view-model/service level rather than the pixels. Step 1 opens the London fixture,
/// refreshes 76 rows and exports every format this build produces, asserting the bytes match
/// the Mac/Linux pins in <c>Linux/README.md</c>. Step 2 creates a new document from the chinook
/// SQLite fixture, applies a SQL statement, adds report elements, refreshes, and exports.
/// PDF and barcode are the accepted gaps; HTML + print is the interim for PDF.</summary>
[Collection("Engine")]
public sealed class SmokeTests
{
    private static readonly (string Format, long Bytes, string Sha256)[] LondonPins =
    {
        ("html", 62007, "285541ed59333e0e55b8c7fe5619e4b64dde7aaf8e93a24ba881b40111ab2327"),
        ("html-flow", 54766, "0565204a55d02f925602b5c0bf298bb0e41c9cbe56bea6df770e828a35782382"),
        ("csv", 12538, "773f6215a5447f72d499282d337a5916b11f0f3b06cb4c5aec134db6f493cb21"),
        ("json", 64595, "569c6ee25223c51ecffd15923dd897e75c8362d72f4ece72f8dbeee3e9c8cdbc"),
        ("json-report", 118109, "9d01d0daabbb5e38921c0bfbed083b288031c9340e9a4af81679d03b691ce94c"),
        ("text", 40441, "7dcee96c45951fac0e0057094a6a142c90a88d6d88a1c03278b273f5140c6e49"),
    };

    private readonly ITestOutputHelper _output;

    public SmokeTests(ITestOutputHelper output) => _output = output;

    [Fact]
    public async Task London_RefreshesAndExportsThePinnedBytes()
    {
        await using var engine = new EngineService();
        var document = new DocumentViewModel(engine);
        await document.OpenAsync(MadPathResolver.DefaultDocument());
        Assert.True(document.HasDocument);

        Assert.True(await document.RefreshAsync(), document.ErrorText);
        Assert.Equal(76, document.RowCount);
        Assert.Equal(5, document.Viewer.PageCount);
        _output.WriteLine("PASS: Opened & refreshed London.portable.mad (76 rows, 5 pages)");

        foreach ((string format, long expectedBytes, string expectedSha) in LondonPins)
        {
            string path = Path.Combine(Path.GetTempPath(), $"mad-smoke-{Guid.NewGuid():N}.{ExtensionFor(format)}");
            try
            {
                document.Viewer.SelectedFormatIndex = FormatIndex(format);
                await document.Viewer.ExportAsync(path);

                Assert.True(File.Exists(path), $"the {format} export wrote no file");
                Assert.Equal(ViewerStatusKind.Success, document.Viewer.StatusKind);

                byte[] bytes = File.ReadAllBytes(path);
                string sha = Convert.ToHexString(SHA256.HashData(bytes)).ToLowerInvariant();
                _output.WriteLine($"PASS: Exported London as {format} ({bytes.Length} bytes, {sha})");

                Assert.Equal(expectedBytes, bytes.Length);
                Assert.Equal(expectedSha, sha);
            }
            finally
            {
                if (File.Exists(path)) File.Delete(path);
            }
        }

        await engine.ShutdownAsync();
    }

    [Fact]
    public async Task NewDocument_FromSqlite_AppliesSqlDesignsRefreshesAndExports()
    {
        string sqlite = CopyChinookToTemp();
        string madPath = Path.Combine(Path.GetTempPath(), $"mad-smoke-created-{Guid.NewGuid():N}.mad");
        try
        {
            await using var engine = new EngineService();
            var spec = new ConnectionSpec(ConnectionDriver.Sqlite3, sqlite, null, null, null, null, null, null);
            OpenResult created = await engine.CreateAsync(madPath, spec);

            var document = new DocumentViewModel(engine);
            await document.AdoptAsync(created, madPath);
            Assert.True(document.HasDocument);

            // Apply a SELECT with a WHERE clause, as the Mac smoke test does.
            const string sql = "SELECT Customer.FirstName, Customer.LastName, Customer.City FROM Customer WHERE Customer.Country = 'United Kingdom';";
            document.Query.SqlEditorText = sql;
            await document.Query.CompileAndApplySqlAsync();
            Assert.StartsWith("Applied:", document.Query.StatusText);
            _output.WriteLine("PASS: Created a document from chinook.sqlite3 and applied the SQL query");

            await document.Designer.ReloadAsync();
            long detail = document.Designer.Sections.Single(s => s.Type == SectionType.Body).Id;

            long label = await AddElementAsync(document.Designer, "label", detail, 12, 6);
            await document.Designer.SetElementContentAsync(label, new ElementContent(Text: "UK Customer:"));

            LayoutField? lastName = document.Designer.Fields.FirstOrDefault(f => f.Name == "LastName");
            Assert.NotNull(lastName);
            long dataField = await AddElementAsync(document.Designer, "data-field", detail, 140, 6);
            await document.Designer.SetElementContentAsync(dataField, new ElementContent(Field: lastName!.Id));

            long aggregate = await AddElementAsync(document.Designer, "aggregate", detail, 300, 6);
            await document.Designer.SetElementContentAsync(aggregate, new ElementContent(
                Field: lastName.Id,
                Function: (int)AggregateFunction.Count,
                Scope: (int)AggregateScope.Report));
            Assert.Equal(3, document.Designer.Elements.Count);
            _output.WriteLine("PASS: Added a static label, a data field and an aggregate");

            Assert.True(await document.RefreshAsync(), document.ErrorText);
            Assert.True(document.RowCount > 0, "the created document refreshed 0 rows");
            _output.WriteLine($"PASS: Refreshed the created document ({document.RowCount} rows, {document.Viewer.PageCount} pages)");

            for (int i = 0; i < ViewerViewModel.ExportFormats.Count; i++)
            {
                ViewerExportFormat format = ViewerViewModel.ExportFormats[i];
                string path = Path.Combine(Path.GetTempPath(), $"mad-smoke-created-{Guid.NewGuid():N}.{format.Extension}");
                try
                {
                    document.Viewer.SelectedFormatIndex = i;
                    await document.Viewer.ExportAsync(path);

                    Assert.True(File.Exists(path), $"the {format.Format} export wrote no file");
                    string content = File.ReadAllText(path);
                    Assert.False(string.IsNullOrWhiteSpace(content), $"the {format.Format} export wrote nothing");
                    Assert.Equal(ViewerStatusKind.Success, document.Viewer.StatusKind);

                    if (format.Format == "json")
                    {
                        Assert.Equal(document.RowCount, MadReport.Parse(content).Rows.Count);
                    }
                    else if (format.Format == "html")
                    {
                        Assert.True(ViewerViewModel.CountPages(content) > 0, "the HTML export has no pages");
                    }

                    _output.WriteLine($"PASS: Exported the created document as {format.Format} ({content.Length} chars)");
                }
                finally
                {
                    if (File.Exists(path)) File.Delete(path);
                }
            }
        }
        finally
        {
            if (File.Exists(sqlite)) File.Delete(sqlite);
            if (File.Exists(madPath)) File.Delete(madPath);
        }
    }

    private static async Task<long> AddElementAsync(DesignerViewModel designer, string kind, long section, double x, double y)
    {
        await designer.AddElementAsync(kind, section, x, y);
        return designer.Elements.Max(e => e.Id);
    }

    private static int FormatIndex(string format)
    {
        for (int i = 0; i < ViewerViewModel.ExportFormats.Count; i++)
        {
            if (ViewerViewModel.ExportFormats[i].Format == format) return i;
        }
        throw new ArgumentOutOfRangeException(nameof(format), format, "no such viewer export format");
    }

    private static string ExtensionFor(string format)
        => ViewerViewModel.ExportFormats[FormatIndex(format)].Extension;

    private static string CopyChinookToTemp()
    {
        string source = Path.Combine(MadPathResolver.RepoRoot(), "MADDesigner", "Resources", "Assets", "Samples.xcassets", "Data", "chinook.dataset", "chinook.sqlite3");
        string temp = Path.Combine(Path.GetTempPath(), $"mad-smoke-chinook-{Guid.NewGuid():N}.sqlite3");
        File.Copy(source, temp);
        return temp;
    }
}
