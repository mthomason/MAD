//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using System.IO;
using Mad.Designer.Windows.Engine;
using Mad.Designer.Windows.Infrastructure;
using Mad.Designer.Windows.Models;
using Mad.Designer.Windows.ViewModels;
using Xunit.Abstractions;

namespace Mad.Designer.Windows.Tests;

/// <summary>The WPF composition acceptance tests — the counterpart of the macOS composed
/// smoke case. They drive the same engine service and view models the running app uses, so a
/// user's create / combine / convert / save / reopen / refresh / view / export sequence is
/// exercised at the view-model boundary rather than the pixels.</summary>
[Collection("Engine")]
public sealed class CompositionAcceptanceTests
{
    private readonly ITestOutputHelper _output;

    public CompositionAcceptanceTests(ITestOutputHelper output) => _output = output;

    /// <summary>The invoices/payments fixtures the composition tests pin: two SQLite sources
    /// (invoices has one per row; payments two for invoice 1), joined on invoice_id, whose root
    /// output is exactly (1,100,40) (1,100,60) (2,200,null) (3,300,null).</summary>
    private static string FixturePath(string name)
        => Path.Combine(MadPathResolver.RepoRoot(), "Windows", "App", "Mad.Designer.Windows.Tests", "Fixtures", name);

    private static string CopyFixture(string name)
    {
        string temp = Path.Combine(Path.GetTempPath(), $"mad-compose-{Guid.NewGuid():N}-{name}");
        File.Copy(FixturePath(name), temp);
        return temp;
    }

    private static ConnectionSpec Sqlite(string file) => new(ConnectionDriver.Sqlite3, file, null, null, null, null, null, null);

    /// <summary>A field on the composed root's upstream table for <paramref name="upstreamQuery"/>,
    /// matched by its source schema-field name.</summary>
    private static QueryField FieldOn(QueryModel root, long upstreamQuery, string name)
        => root.Tables.Single(t => t.UpstreamQuery == upstreamQuery).Fields.Single(f => f.Name == name);

    [Fact]
    public async Task CreateComposition_AuthorSaveReopenRefreshViewExport()
    {
        string invoices = CopyFixture("invoices.sqlite");
        string payments = CopyFixture("payments.sqlite");
        string mad = Path.Combine(Path.GetTempPath(), $"mad-compose-{Guid.NewGuid():N}.mad");
        try
        {
            await using (var engine = new EngineService())
            {
                // 1. New Composition: an empty document, then the root and two sources.
                OpenResult created = await engine.CreateEmptyAsync(mad);
                var withRoot = await engine.AddRootAsync(created.Handle, "root");
                Assert.True(withRoot.Composed);
                Assert.Equal(created.Handle, created.Handle);

                var afterInvoices = await engine.AddSourceAsync(created.Handle, "invoices", Sqlite(invoices));
                var afterPayments = await engine.AddSourceAsync(created.Handle, "payments", Sqlite(payments));
                long invoicesQuery = afterInvoices.Queries.Single(q => q.Name == "invoices").Id;
                long paymentsQuery = afterPayments.Queries.Single(q => q.Name == "payments").Id;
                long rootQuery = afterPayments.RootQuery;

                // 2. Add a table to each source query, then wire each as a child of the root.
                await engine.AddTableAsync(created.Handle, "invoices", invoicesQuery);
                await engine.AddTableAsync(created.Handle, "payments", paymentsQuery);
                await engine.AddUpstreamAsync(created.Handle, invoicesQuery);
                await engine.AddUpstreamAsync(created.Handle, paymentsQuery);

                // 3. Join on invoice_id and choose/name/order the root outputs.
                QueryModel root = await engine.QueryModelAsync(created.Handle, rootQuery);
                long invInvoiceId = FieldOn(root, invoicesQuery, "invoice_id").Id;
                long invAmount = FieldOn(root, invoicesQuery, "amount").Id;
                long payInvoiceId = FieldOn(root, paymentsQuery, "invoice_id").Id;
                long payAmount = FieldOn(root, paymentsQuery, "amount").Id;
                await engine.AddLinkAsync(created.Handle, invInvoiceId, payInvoiceId, rootQuery);
                await engine.SetRootOutputsAsync(created.Handle, new[]
                {
                    new RootOutput(invInvoiceId, "invoice_id"),
                    new RootOutput(invAmount, "invoice_amount"),
                    new RootOutput(payAmount, "payment_amount"),
                });

                // 4. Adopt the document, refresh, and verify the joined rows.
                var document = new DocumentViewModel(engine);
                await document.AdoptAsync(created, mad);
                Assert.True(document.IsComposed);
                Assert.True(await document.RefreshAsync(), document.ErrorText);
                Assert.Equal(4, document.RowCount);
                _output.WriteLine("PASS: authored a composition and refreshed 4 joined rows");

                // 5. Save, then reopen in a fresh document and refresh again.
                await document.SaveAsync();
            }

            await using (var engine2 = new EngineService())
            {
                var reopened = new DocumentViewModel(engine2);
                await reopened.OpenAsync(mad);
                Assert.True(reopened.IsComposed);
                Assert.True(await reopened.RefreshAsync(), reopened.ErrorText);
                Assert.Equal(4, reopened.RowCount);
                _output.WriteLine("PASS: reopened the composition and refreshed 4 rows");

                // 6. View and export; the JSON carries the output keys and joined rows.
                string export = Path.Combine(Path.GetTempPath(), $"mad-compose-{Guid.NewGuid():N}.json");
                try
                {
                    reopened.Viewer.SelectedFormatIndex = ViewerViewModel.ExportFormats
                        .Select((f, i) => (f, i)).Single(x => x.f.Format == "json").i;
                    await reopened.Viewer.ExportAsync(export);
                    Assert.True(File.Exists(export), "the JSON export wrote no file");

                    MadReport report = MadReport.Parse(File.ReadAllText(export));
                    Assert.Equal(new[] { "invoice_id", "invoice_amount", "payment_amount" },
                        report.Columns.Select(c => c.Key).ToArray());
                    Assert.Equal(4, report.Rows.Count);

                    IReadOnlyDictionary<string, object?> invoice2 = report.Rows.Single(r => Equals(r["invoice_id"], 2m));
                    Assert.Equal(200m, invoice2["invoice_amount"]);
                    Assert.Null(invoice2["payment_amount"]);

                    var invoice1Payments = report.Rows.Where(r => Equals(r["invoice_id"], 1m))
                        .Select(r => r["payment_amount"]).OrderBy(v => v).ToArray();
                    Assert.Equal(new object?[] { 40m, 60m }, invoice1Payments);
                    _output.WriteLine("PASS: exported JSON preserves the output keys and joined rows");
                }
                finally
                {
                    if (File.Exists(export)) File.Delete(export);
                }
            }
        }
        finally
        {
            if (File.Exists(invoices)) File.Delete(invoices);
            if (File.Exists(payments)) File.Delete(payments);
            if (File.Exists(mad)) File.Delete(mad);
        }
    }

    [Fact]
    public async Task ConvertStandardReport_ProducesAComposition()
    {
        string invoices = CopyFixture("invoices.sqlite");
        string mad = Path.Combine(Path.GetTempPath(), $"mad-convert-{Guid.NewGuid():N}.mad");
        try
        {
            await using var engine = new EngineService();
            OpenResult created = await engine.CreateAsync(mad, Sqlite(invoices));
            var info = await engine.DocumentInfoAsync(created.Handle);
            long queryId = info.Queries[0].Id;
            await engine.AddTableAsync(created.Handle, "invoices", queryId);

            var document = new DocumentViewModel(engine);
            await document.AdoptAsync(created, mad);
            Assert.False(document.IsComposed);

            await document.ConvertToCompositionAsync("invoices");
            Assert.True(document.IsComposed);
            Assert.Contains(document.Queries, q => q.IsRoot);
            Assert.Contains(document.Queries, q => !q.IsRoot && q.Name == "invoices");

            Assert.True(await document.RefreshAsync(), document.ErrorText);
            Assert.Equal(3, document.RowCount);
            _output.WriteLine("PASS: converted a standard report into a composition and refreshed 3 rows");
        }
        finally
        {
            if (File.Exists(invoices)) File.Delete(invoices);
            if (File.Exists(mad)) File.Delete(mad);
        }
    }

    [Fact]
    public async Task ImportChild_EmbedsTheSourceGraph()
    {
        // Build a standalone invoices report, then import it as a child of a new composition.
        string invoices = CopyFixture("invoices.sqlite");
        string source = Path.Combine(Path.GetTempPath(), $"mad-import-source-{Guid.NewGuid():N}.mad");
        string composed = Path.Combine(Path.GetTempPath(), $"mad-import-composed-{Guid.NewGuid():N}.mad");
        try
        {
            await using (var engine = new EngineService())
            {
                OpenResult sourceCreated = await engine.CreateAsync(source, Sqlite(invoices));
                var sourceInfo = await engine.DocumentInfoAsync(sourceCreated.Handle);
                await engine.AddTableAsync(sourceCreated.Handle, "invoices", sourceInfo.Queries[0].Id);
                await engine.WriteAsync(sourceCreated.Handle, source);
            }

            await using var engine2 = new EngineService();
            OpenResult created = await engine2.CreateEmptyAsync(composed);
            var withRoot = await engine2.AddRootAsync(created.Handle, "root");
            var imported = await engine2.ImportChildAsync(created.Handle, source, "invoices");
            Assert.True(imported.Composed);
            Assert.Equal(withRoot.RootQuery, imported.RootQuery);
            Assert.Contains(imported.Queries, q => !q.IsRoot && q.Name == "invoices");

            var document = new DocumentViewModel(engine2);
            await document.AdoptAsync(created, composed);
            Assert.True(document.IsComposed);
            Assert.True(await document.RefreshAsync(), document.ErrorText);
            Assert.Equal(3, document.RowCount);
            _output.WriteLine("PASS: imported a child report and refreshed its graph");
        }
        finally
        {
            if (File.Exists(invoices)) File.Delete(invoices);
            if (File.Exists(source)) File.Delete(source);
            if (File.Exists(composed)) File.Delete(composed);
        }
    }

    [Fact]
    public async Task ImportTwoReports_AuthorJoinAndOutputs()
    {
        string invoices = CopyFixture("invoices.sqlite");
        string payments = CopyFixture("payments.sqlite");
        string invoicesMad = Path.Combine(Path.GetTempPath(), $"mad-two-invoices-{Guid.NewGuid():N}.mad");
        string paymentsMad = Path.Combine(Path.GetTempPath(), $"mad-two-payments-{Guid.NewGuid():N}.mad");
        string composed = Path.Combine(Path.GetTempPath(), $"mad-two-composed-{Guid.NewGuid():N}.mad");
        try
        {
            // 1. Two standard reports (invoices, payments), each a single table query.
            await using (var engine = new EngineService())
            {
                OpenResult inv = await engine.CreateAsync(invoicesMad, Sqlite(invoices));
                await engine.AddTableAsync(inv.Handle, "invoices", (await engine.DocumentInfoAsync(inv.Handle)).Queries[0].Id);
                await engine.WriteAsync(inv.Handle, invoicesMad);

                OpenResult pay = await engine.CreateAsync(paymentsMad, Sqlite(payments));
                await engine.AddTableAsync(pay.Handle, "payments", (await engine.DocumentInfoAsync(pay.Handle)).Queries[0].Id);
                await engine.WriteAsync(pay.Handle, paymentsMad);
            }

            // 2. Import both as children, join on invoice_id, and choose the outputs.
            await using var engine2 = new EngineService();
            OpenResult created = await engine2.CreateEmptyAsync(composed);
            await engine2.AddRootAsync(created.Handle, "root");
            var afterInv = await engine2.ImportChildAsync(created.Handle, invoicesMad, "invoices");
            var afterPay = await engine2.ImportChildAsync(created.Handle, paymentsMad, "payments");
            long invQuery = afterInv.Queries.Single(q => q.Name == "invoices").Id;
            long payQuery = afterPay.Queries.Single(q => q.Name == "payments").Id;
            long rootQuery = afterPay.RootQuery;

            QueryModel root = await engine2.QueryModelAsync(created.Handle, rootQuery);
            long invInvoiceId = FieldOn(root, invQuery, "invoice_id").Id;
            long invAmount = FieldOn(root, invQuery, "amount").Id;
            long payInvoiceId = FieldOn(root, payQuery, "invoice_id").Id;
            long payAmount = FieldOn(root, payQuery, "amount").Id;
            await engine2.AddLinkAsync(created.Handle, invInvoiceId, payInvoiceId, rootQuery);
            await engine2.SetRootOutputsAsync(created.Handle, new[]
            {
                new RootOutput(invInvoiceId, "invoice_id"),
                new RootOutput(invAmount, "invoice_amount"),
                new RootOutput(payAmount, "payment_amount"),
            });

            var document = new DocumentViewModel(engine2);
            await document.AdoptAsync(created, composed);
            Assert.True(document.IsComposed);
            Assert.True(await document.RefreshAsync(), document.ErrorText);
            Assert.Equal(4, document.RowCount);
            _output.WriteLine("PASS: imported two reports, joined on invoice_id, refreshed 4 rows");

            // 3. Reorder the outputs and confirm the exported column order follows.
            await engine2.SetRootOutputsAsync(created.Handle, new[]
            {
                new RootOutput(payAmount, "payment_amount"),
                new RootOutput(invInvoiceId, "invoice_id"),
                new RootOutput(invAmount, "invoice_amount"),
            });
            Assert.True(await document.RefreshAsync(), document.ErrorText);

            string export = Path.Combine(Path.GetTempPath(), $"mad-two-{Guid.NewGuid():N}.json");
            try
            {
                document.Viewer.SelectedFormatIndex = ViewerViewModel.ExportFormats
                    .Select((f, i) => (f, i)).Single(x => x.f.Format == "json").i;
                await document.Viewer.ExportAsync(export);
                MadReport report = MadReport.Parse(File.ReadAllText(export));
                Assert.Equal(new[] { "payment_amount", "invoice_id", "invoice_amount" },
                    report.Columns.Select(c => c.Key).ToArray());
                Assert.Equal(4, report.Rows.Count);
                _output.WriteLine("PASS: reordered the outputs and the exported columns followed");
            }
            finally
            {
                if (File.Exists(export)) File.Delete(export);
            }
        }
        finally
        {
            if (File.Exists(invoices)) File.Delete(invoices);
            if (File.Exists(payments)) File.Delete(payments);
            if (File.Exists(invoicesMad)) File.Delete(invoicesMad);
            if (File.Exists(paymentsMad)) File.Delete(paymentsMad);
            if (File.Exists(composed)) File.Delete(composed);
        }
    }

    [Fact]
    public async Task SqlEntry_ActsOnTheSelectedQueryAndRejectsTheRoot()
    {
        string invoices = CopyFixture("invoices.sqlite");
        string composed = Path.Combine(Path.GetTempPath(), $"mad-sql-{Guid.NewGuid():N}.mad");
        try
        {
            await using var engine = new EngineService();
            OpenResult created = await engine.CreateEmptyAsync(composed);
            await engine.AddRootAsync(created.Handle, "root");
            var afterInv = await engine.AddSourceAsync(created.Handle, "invoices", Sqlite(invoices));
            long invQuery = afterInv.Queries.Single(q => q.Name == "invoices").Id;
            long rootQuery = afterInv.RootQuery;
            await engine.AddTableAsync(created.Handle, "invoices", invQuery);

            // A source query accepts SQL entry against its own schema.
            var validated = await engine.ValidateSqlAsync(created.Handle, "SELECT invoice_id, amount FROM invoices", invQuery);
            Assert.True(validated.Tables > 0, "the selected source query validated SQL");
            _output.WriteLine("PASS: validated SQL against the selected source query");

            // The composed root has no single editable statement.
            var exception = await Assert.ThrowsAsync<Mad.Client.MadEngineException>(
                () => engine.ValidateSqlAsync(created.Handle, "SELECT invoice_id, amount FROM invoices", rootQuery));
            Assert.Contains("SQL editing is not supported", exception.Message);
            _output.WriteLine("PASS: the composed root rejects SQL editing");
        }
        finally
        {
            if (File.Exists(invoices)) File.Delete(invoices);
            if (File.Exists(composed)) File.Delete(composed);
        }
    }
}
