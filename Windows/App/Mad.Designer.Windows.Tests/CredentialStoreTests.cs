//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using Mad.Designer.Windows.Infrastructure;

namespace Mad.Designer.Windows.Tests;

public sealed class CredentialStoreTests
{
    [Fact]
    public void Save_ThenTryRead_RoundTrips()
    {
        var store = new InMemoryCredentialStore();
        store.Save("mysql:db.example.com:3306/employees", "root", "pw");

        Assert.True(store.TryRead("mysql:db.example.com:3306/employees", out string? user, out string? pass));
        Assert.Equal("root", user);
        Assert.Equal("pw", pass);
    }

    [Fact]
    public void TryRead_MissingKey_ReturnsFalse()
    {
        var store = new InMemoryCredentialStore();
        Assert.False(store.TryRead("missing", out _, out _));
    }

    [Fact]
    public void Delete_ThenTryRead_ReturnsFalse()
    {
        var store = new InMemoryCredentialStore();
        store.Save("key", "u", "p");
        store.Delete("key");
        Assert.False(store.TryRead("key", out _, out _));
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
