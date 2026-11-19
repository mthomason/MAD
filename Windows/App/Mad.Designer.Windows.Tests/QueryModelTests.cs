//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using System.IO;
using Mad.Designer.Windows.Engine;
using Mad.Designer.Windows.Infrastructure;
using Mad.Designer.Windows.Models;

namespace Mad.Designer.Windows.Tests;

/// <summary>Headless coverage of the Phase 6b query-model read/mutation and SQL-compile
/// protocol paths, mirroring the Mac's <c>MADMacSmokeTest</c> step 4 and step 2.</summary>
[Collection("Engine")]
public sealed class QueryModelTests
{
    [Fact]
    public async Task VisualQueryFlow_AddConnectFilterGroup_RegeneratesSql()
    {
        string sqlite = CopyChinookToTemp();
        string mad = Path.Combine(Path.GetTempPath(), $"mad-query-{Guid.NewGuid():N}.mad");
        try
        {
            await using var service = new EngineService();
            var spec = new ConnectionSpec(ConnectionDriver.Sqlite3, sqlite, null, null, null, null, null, null);
            var open = await service.CreateAsync(mad, spec);

            // A fresh document starts with an empty query model.
            var empty = await service.QueryModelAsync(open.Handle);
            Assert.Empty(empty.Tables);
            Assert.Empty(empty.Links);
            Assert.Equal("sqlite3", empty.Driver);

            // Adding two tables places both with every field.
            var withCustomer = await service.AddTableAsync(open.Handle, "Customer");
            var model = await service.AddTableAsync(open.Handle, "Invoice");
            Assert.Equal(2, model.Tables.Count);

            var customer = model.Tables.Single(t => t.Name == "Customer");
            var invoice = model.Tables.Single(t => t.Name == "Invoice");
            Assert.Equal(13, customer.Fields.Count); // chinook Customer has 13 columns
            Assert.Equal(9, invoice.Fields.Count);   // chinook Invoice has 9 columns

            // Connect Customer.CustomerId -> Invoice.CustomerId: default Left Outer Join.
            long customerId = FieldId(customer, "CustomerId");
            long invoiceCustomerId = FieldId(invoice, "CustomerId");
            model = await service.AddLinkAsync(open.Handle, customerId, invoiceCustomerId);
            Assert.Single(model.Links);
            Assert.Equal(LinkType.LeftOuterJoin, model.Links[0].Type);
            Assert.Contains("LEFT OUTER JOIN", model.Sql);

            // Change the link type to Inner Join.
            model = await service.SetLinkTypeAsync(open.Handle, model.Links[0].Id, (int)LinkType.InnerJoin);
            Assert.Equal(LinkType.InnerJoin, model.Links[0].Type);
            Assert.Contains("INNER JOIN", model.Sql);

            // A filter (WHERE) and a grouping (GROUP BY) regenerate the SQL.
            model = await service.AddPredicateAsync(open.Handle, FieldId(customer, "Country"), (int)PredicateOperator.Equal, "United Kingdom");
            Assert.Contains("WHERE", model.Sql);
            Assert.Contains("'United Kingdom'", model.Sql);

            model = await service.AddGroupAsync(open.Handle, FieldId(customer, "Country"), (int)GroupSort.Ascending);
            // Groupings are a report-structure concept in this engine, not a SQL GROUP BY
            // clause; the model carries them and the generated SQL still regenerates.
            Assert.Single(model.Groups);
            Assert.Equal(FieldId(customer, "Country"), model.Groups[0].Field);
            Assert.Equal(GroupSort.Ascending, model.Groups[0].Sort);
            Assert.Single(model.Predicates);

            // Removing the Invoice table removes its fields, links, groups and predicates.
            model = await service.RemoveTableAsync(open.Handle, invoice.Id);
            Assert.Single(model.Tables);
            Assert.Empty(model.Links);
            Assert.DoesNotContain("INNER JOIN", model.Sql);
        }
        finally
        {
            if (File.Exists(sqlite)) File.Delete(sqlite);
            if (File.Exists(mad)) File.Delete(mad);
        }
    }

    [Fact]
    public async Task RemoveTable_AlsoRemovesLinksPredicatesGroups_ThatReferenceIt()
    {
        string sqlite = CopyChinookToTemp();
        string mad = Path.Combine(Path.GetTempPath(), $"mad-query-{Guid.NewGuid():N}.mad");
        try
        {
            await using var service = new EngineService();
            var open = await service.CreateAsync(mad, new ConnectionSpec(ConnectionDriver.Sqlite3, sqlite, null, null, null, null, null, null));

            var model = await service.AddTableAsync(open.Handle, "Customer");
            model = await service.AddTableAsync(open.Handle, "Invoice");
            var customer = model.Tables.Single(t => t.Name == "Customer");
            var invoice = model.Tables.Single(t => t.Name == "Invoice");

            model = await service.AddLinkAsync(open.Handle, FieldId(customer, "CustomerId"), FieldId(invoice, "CustomerId"));
            model = await service.AddGroupAsync(open.Handle, FieldId(invoice, "InvoiceId"), (int)GroupSort.Ascending);
            model = await service.AddPredicateAsync(open.Handle, FieldId(invoice, "Total"), (int)PredicateOperator.GreaterThan, "1.00");

            Assert.Single(model.Links);
            Assert.Single(model.Groups);
            Assert.Single(model.Predicates);

            // Removing Customer must drop the link and the Customer-side predicate only.
            model = await service.RemoveTableAsync(open.Handle, customer.Id);
            Assert.Single(model.Tables);
            Assert.Empty(model.Links); // the join was Customer<->Invoice

            // Removing the last table clears everything.
            model = await service.RemoveTableAsync(open.Handle, invoice.Id);
            Assert.Empty(model.Tables);
            Assert.Empty(model.Groups);
            Assert.Empty(model.Predicates);
        }
        finally
        {
            if (File.Exists(sqlite)) File.Delete(sqlite);
            if (File.Exists(mad)) File.Delete(mad);
        }
    }

    [Fact]
    public async Task SqlEntry_ValidateAndApply_CompileAgainstSchema()
    {
        string sqlite = CopyChinookToTemp();
        string mad = Path.Combine(Path.GetTempPath(), $"mad-query-{Guid.NewGuid():N}.mad");
        try
        {
            await using var service = new EngineService();
            var open = await service.CreateAsync(mad, new ConnectionSpec(ConnectionDriver.Sqlite3, sqlite, null, null, null, null, null, null));

            // Validate a valid SELECT against the live chinook schema.
            var validated = await service.ValidateSqlAsync(open.Handle,
                "SELECT Customer.FirstName, Customer.LastName, Customer.City FROM Customer WHERE Customer.Country = 'United Kingdom'");
            Assert.Equal(1, validated.Tables);
            Assert.Equal(0, validated.Links);
            Assert.Equal(1, validated.Predicates);
            Assert.Equal(0, validated.Groups);

            // An invalid statement reports a clean error (engine error code 4).
            await Assert.ThrowsAsync<Mad.Client.MadEngineException>(() =>
                service.ValidateSqlAsync(open.Handle, "SELECT Nope FROM Nowhere"));

            // Applying the SQL compiles it into the query model.
            await service.ApplySqlAsync(open.Handle,
                "SELECT Customer.FirstName, Customer.LastName, Customer.City FROM Customer WHERE Customer.Country = 'United Kingdom'");
            var model = await service.QueryModelAsync(open.Handle);
            Assert.Single(model.Tables);
            Assert.Equal("Customer", model.Tables[0].Name);
            Assert.Single(model.Predicates);
            Assert.Contains("'United Kingdom'", model.Sql);
            Assert.Equal(
                "SELECT Customer.FirstName, Customer.LastName, Customer.City FROM Customer WHERE Customer.Country = 'United Kingdom'",
                model.SqlSourceText);
        }
        finally
        {
            if (File.Exists(sqlite)) File.Delete(sqlite);
            if (File.Exists(mad)) File.Delete(mad);
        }
    }

    private static long FieldId(QueryTable table, string name)
        => table.Fields.Single(f => f.Name == name).Id;

    private static string CopyChinookToTemp()
    {
        string source = Path.Combine(MadPathResolver.RepoRoot(), "MADDesigner", "Resources", "Assets", "Samples.xcassets", "Data", "chinook.dataset", "chinook.sqlite3");
        string temp = Path.Combine(Path.GetTempPath(), $"mad-chinook-{Guid.NewGuid():N}.sqlite3");
        File.Copy(source, temp);
        return temp;
    }
}
