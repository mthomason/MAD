//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using System.IO;
using Mad.Designer.Windows.Engine;
using Mad.Designer.Windows.Infrastructure;
using Mad.Designer.Windows.Models;
using Mad.Designer.Windows.ViewModels;

namespace Mad.Designer.Windows.Tests;

public sealed class ConnectionWindowViewModelTests
{
    private static readonly ICredentialStore NoStore = new InMemoryCredentialStore();

    [Fact]
    public void Defaults_AreSqlite_WithVisibility()
    {
        var vm = new ConnectionWindowViewModel(new EngineService(), NoStore, isEdit: false);

        Assert.Equal(ConnectionDriver.Sqlite3, vm.Driver);
        Assert.True(vm.IsSqlite);
        Assert.False(vm.IsServer);
        Assert.False(vm.IsSqlServer);
    }

    [Fact]
    public void SelectingMySql_HidesSqlite_ShowsServer_NotSqlServer()
    {
        var vm = new ConnectionWindowViewModel(new EngineService(), NoStore, isEdit: false);
        vm.Driver = ConnectionDriver.MySql;

        Assert.False(vm.IsSqlite);
        Assert.True(vm.IsServer);
        Assert.False(vm.IsSqlServer);
        Assert.Equal(3306, vm.Port);
    }

    [Fact]
    public void SelectingSqlServer_ShowsServerInstance()
    {
        var vm = new ConnectionWindowViewModel(new EngineService(), NoStore, isEdit: false);
        vm.Driver = ConnectionDriver.SqlServer;

        Assert.True(vm.IsSqlServer);
        Assert.Equal(1433, vm.Port);
    }

    [Fact]
    public void ToSpec_RoundTripsFields()
    {
        var vm = new ConnectionWindowViewModel(new EngineService(), NoStore, isEdit: false);
        vm.Driver = ConnectionDriver.MySql;
        vm.Host = "db.example.com";
        vm.Port = 3306;
        vm.Database = "employees";
        vm.Username = "root";
        vm.Password = "pw";

        Assert.Equal("mysql:db.example.com:3306/employees", vm.Spec.CredentialKey);
        Assert.Equal("db.example.com", vm.Spec.Host);
        Assert.Equal("root", vm.Spec.Username);
    }

    [Fact]
    public async Task TestConnection_Sqlite_ReportsTableCount()
    {
        string sqlite = CopyChinookToTemp();
        try
        {
            await using var engine = new EngineService();
            var vm = new ConnectionWindowViewModel(engine, NoStore, isEdit: false);
            vm.File = sqlite;

            await vm.TestConnectionCommand.ExecuteAsync();

            Assert.Contains("Found 11 schema tables", vm.StatusText);
        }
        finally
        {
            if (File.Exists(sqlite)) File.Delete(sqlite);
        }
    }

    private static string CopyChinookToTemp()
    {
        string source = Path.Combine(MadPathResolver.RepoRoot(), "MADDesigner", "Resources", "Assets", "Samples.xcassets", "Data", "chinook.dataset", "chinook.sqlite3");
        string temp = Path.Combine(Path.GetTempPath(), $"mad-chinook-{Guid.NewGuid():N}.sqlite3");
        File.Copy(source, temp);
        return temp;
    }

    private sealed class InMemoryCredentialStore : ICredentialStore
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
    }
}
