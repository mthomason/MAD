//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using System.IO;
using Mad.Designer.Windows.Engine;
using Mad.Designer.Windows.Infrastructure;
using Mad.Designer.Windows.Models;
using Mad.Designer.Windows.ViewModels;

namespace Mad.Designer.Windows.Tests;

/// <summary>The per-source credential flow: each credential-taking source resolves its
/// own credential from the session or Credential Manager, a missing one is prompted for
/// one sheet at a time, and each accepted credential is saved under that source's own
/// <c>driver:host:port/database</c> key.  A Standard Report never takes this path.</summary>
public sealed class SourceCredentialCollectorTests
{
    private static QueryInfo Source(long id, string name, ConnectionDriver driver, string host, int port, string database,
        string? hint = "root")
        => new(id, name, IsRoot: false, IsComposing: false,
            new QueryConnection(driver, null, host, port, database, null, true, hint));

    [Fact]
    public async Task Collect_PromptsForEachMissingSource_AndSavesEachCredential()
    {
        var store = new InMemoryCredentialStore();
        var prompts = new List<SourceCredentialPrompt>();
        var collector = new SourceCredentialCollector(store, prompt =>
        {
            prompts.Add(prompt);
            return Task.FromResult<SourceCredentialResult?>(
                new SourceCredentialResult(prompt.Initial with { Password = "s3cret" }, SaveCredentials: true));
        });
        var sources = new[]
        {
            Source(2, "MySQL", ConnectionDriver.MySql, "127.0.0.1", 13306, "employees"),
            Source(3, "PostgreSQL", ConnectionDriver.Postgres, "127.0.0.1", 5432, "chinook"),
        };

        Dictionary<long, string>? map = await collector.CollectAsync(sources);

        Assert.NotNull(map);
        Assert.Equal("root:s3cret", map![2]);
        Assert.Equal("root:s3cret", map[3]);
        Assert.Equal(2, prompts.Count);
        Assert.Equal("MySQL", prompts[0].Name);
        Assert.Contains("MySQL", prompts[0].Message);
        Assert.Equal("", prompts[0].Initial.Password);
        Assert.Equal("127.0.0.1", prompts[0].Initial.Host);
        Assert.Equal("employees", prompts[0].Initial.Database);
        Assert.Equal("root", prompts[0].Initial.Username);

        // Nothing is written until the refresh that uses the credential succeeds.
        Assert.Null(store.Read("mysql:127.0.0.1:13306/employees"));
        collector.CommitPendingSaves();
        Assert.Equal("s3cret", store.Read("mysql:127.0.0.1:13306/employees"));
        Assert.Equal("s3cret", store.Read("postgres:127.0.0.1:5432/chinook"));
    }

    [Fact]
    public async Task Collect_UsesASavedCredential_AndPromptsOnlyTheOther()
    {
        var store = new InMemoryCredentialStore();
        store.Save("mysql:h:3306/db", "saveduser", "savedpass");
        int prompts = 0;
        var collector = new SourceCredentialCollector(store, prompt =>
        {
            prompts++;
            return Task.FromResult<SourceCredentialResult?>(
                new SourceCredentialResult(prompt.Initial with { Password = "pw" }, SaveCredentials: true));
        });
        var sources = new[]
        {
            Source(2, "A", ConnectionDriver.MySql, "h", 3306, "db"),
            Source(3, "B", ConnectionDriver.Postgres, "p", 5432, "db2"),
        };

        Dictionary<long, string>? map = await collector.CollectAsync(sources);

        Assert.NotNull(map);
        Assert.Equal("saveduser:savedpass", map![2]);
        Assert.Equal("root:pw", map[3]);
        Assert.Equal(1, prompts);
    }

    [Fact]
    public async Task Collect_CancelledSheet_ReturnsNull()
    {
        var collector = new SourceCredentialCollector(new InMemoryCredentialStore(),
            _ => Task.FromResult<SourceCredentialResult?>(null));

        Assert.Null(await collector.CollectAsync(new[]
        {
            Source(2, "A", ConnectionDriver.MySql, "h", 3306, "db"),
        }));
    }

    [Fact]
    public void RequiresCredential_SkipsSqliteAndTheResult()
    {
        var sqlite = new QueryInfo(2, "S", false, false,
            new QueryConnection(ConnectionDriver.Sqlite3, "a.sqlite", null, null, null, null, false, null));
        Assert.False(SourceCredentialCollector.RequiresCredential(sqlite));

        var result = new QueryInfo(1, "Result", true, true);
        Assert.False(SourceCredentialCollector.RequiresCredential(result));

        Assert.True(SourceCredentialCollector.RequiresCredential(
            Source(3, "M", ConnectionDriver.MySql, "h", 3306, "db")));

        // A non-root composer carries its first source's database row, but it is not
        // a credential-taking source: its children connect.
        var composer = new QueryInfo(4, "Composer", IsRoot: false, IsComposing: true,
            new QueryConnection(ConnectionDriver.MySql, null, "h", 3306, "db", null, true, "root"));
        Assert.False(SourceCredentialCollector.RequiresCredential(composer));
    }

    /// <summary>An empty or partial stored pair is not a usable source credential: the
    /// store keeps it, but the collector asks for the source again.</summary>
    [Fact]
    public void Resolve_IgnoresAPartialSavedCredential()
    {
        var store = new InMemoryCredentialStore();
        store.Save("mysql:h:3306/db", "root", "");
        var collector = new SourceCredentialCollector(store);

        Assert.Null(collector.Resolve(Source(2, "A", ConnectionDriver.MySql, "h", 3306, "db")));
    }

    [Fact]
    public async Task Prompt_WithAnEmptyPassword_DoesNotQueueASave()
    {
        var store = new InMemoryCredentialStore();
        var collector = new SourceCredentialCollector(store, prompt =>
            Task.FromResult<SourceCredentialResult?>(
                new SourceCredentialResult(prompt.Initial with { Password = "" }, SaveCredentials: true)));

        await collector.PromptForSourceAsync(Source(2, "A", ConnectionDriver.MySql, "h", 3306, "db"));
        collector.CommitPendingSaves();

        Assert.Null(store.Read("mysql:h:3306/db"));
    }

    /// <summary>A prompt that edits the sheet's host still saves under the source's own
    /// connection key, because the map is applied to the source's connection.</summary>
    [Fact]
    public async Task Prompt_SavesUnderTheSourceKey_NotAnEditedHost()
    {
        var store = new InMemoryCredentialStore();
        var collector = new SourceCredentialCollector(store, prompt =>
            Task.FromResult<SourceCredentialResult?>(
                new SourceCredentialResult(prompt.Initial with { Host = "elsewhere", Password = "pw" },
                    SaveCredentials: true)));

        string? credential = await collector.PromptForSourceAsync(
            Source(2, "A", ConnectionDriver.MySql, "h", 3306, "db"));

        Assert.Equal("root:pw", credential);
        Assert.Null(store.Read("mysql:h:3306/db"));
        collector.CommitPendingSaves();
        Assert.Equal("pw", store.Read("mysql:h:3306/db"));
    }
}

/// <summary>The Standard Report fallback: it keeps the document-level single credential
/// and never asks for per-source ones.</summary>
[Collection("Engine")]
public sealed class SourceCredentialRefreshTests
{
    [Fact]
    public async Task StandardReport_RefreshesWithoutAskingForSourceCredentials()
    {
        bool prompted = false;
        await using var engine = new EngineService();
        var document = new DocumentViewModel(engine,
            credentials: new InMemoryCredentialStore(),
            sourceCredentialPrompt: _ =>
            {
                prompted = true;
                return Task.FromResult<SourceCredentialResult?>(null);
            });

        await document.OpenAsync(MadPathResolver.DefaultDocument());
        Assert.True(await document.RefreshAsync(), document.ErrorText);

        Assert.Equal(76, document.RowCount);
        Assert.False(prompted);
    }

    [Fact]
    public async Task ApplyingOneSourceConnection_LeavesTheSiblingUntouched()
    {
        string invoices = CopyFixture("invoices.sqlite");
        string payments = CopyFixture("payments.sqlite");
        string replacement = CopyFixture("invoices.sqlite", $"replacement-{Guid.NewGuid():N}.sqlite");
        string mad = Path.Combine(Path.GetTempPath(), $"mad-source-edit-{Guid.NewGuid():N}.mad");
        try
        {
            await using var engine = new EngineService();
            OpenResult created = await engine.CreateEmptyAsync(mad);
            await engine.AddRootAsync(created.Handle, "root");
            DocumentInfo info = await engine.AddSourceAsync(created.Handle, "invoices", Sqlite(invoices));
            info = await engine.AddSourceAsync(created.Handle, "payments", Sqlite(payments));
            long invoicesId = info.Queries.Single(q => q.Name == "invoices").Id;
            long paymentsId = info.Queries.Single(q => q.Name == "payments").Id;

            var document = new DocumentViewModel(engine);
            await document.AdoptAsync(created, mad);

            await document.ApplySourceConnectionAsync(paymentsId, Sqlite(replacement));

            DocumentInfo after = await engine.DocumentInfoAsync(created.Handle);
            QueryInfo invoicesQuery = after.Queries.Single(q => q.Id == invoicesId);
            QueryInfo paymentsQuery = after.Queries.Single(q => q.Id == paymentsId);
            // Only the edited source moved; its sibling still points at its own file.
            Assert.EndsWith(Path.GetFileName(invoices), invoicesQuery.Connection!.File!,
                StringComparison.OrdinalIgnoreCase);
            Assert.EndsWith(Path.GetFileName(replacement), paymentsQuery.Connection!.File!,
                StringComparison.OrdinalIgnoreCase);
            Assert.NotEqual(invoicesQuery.Connection!.File, paymentsQuery.Connection!.File);
        }
        finally
        {
            if (File.Exists(invoices)) File.Delete(invoices);
            if (File.Exists(payments)) File.Delete(payments);
            if (File.Exists(replacement)) File.Delete(replacement);
            if (File.Exists(mad)) File.Delete(mad);
        }
    }

    private static ConnectionSpec Sqlite(string file)
        => new(ConnectionDriver.Sqlite3, file, null, null, null, null, null, null);

    private static string CopyFixture(string name, string? tempName = null)
    {
        string source = Path.Combine(MadPathResolver.RepoRoot(),
            "Windows", "App", "Mad.Designer.Windows.Tests", "Fixtures", name);
        string temp = Path.Combine(Path.GetTempPath(),
            tempName ?? $"mad-source-edit-{Guid.NewGuid():N}-{name}");
        File.Copy(source, temp);
        return temp;
    }
}

/// <summary>A Credential Manager stand-in: the same three operations, in memory.</summary>
internal sealed class InMemoryCredentialStore : ICredentialStore
{
    private readonly Dictionary<string, (string Username, string Password)> _values = new();

    public void Save(string key, string username, string password)
        => _values[key] = (username, password);

    public bool TryRead(string key, out string username, out string password)
    {
        if (_values.TryGetValue(key, out var value))
        {
            username = value.Username;
            password = value.Password;
            return true;
        }
        username = "";
        password = "";
        return false;
    }

    public void Delete(string key) => _values.Remove(key);

    public string? Read(string key)
        => TryRead(key, out _, out string password) ? password : null;
}
