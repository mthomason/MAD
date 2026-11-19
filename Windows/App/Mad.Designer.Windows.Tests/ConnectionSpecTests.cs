//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using Mad.Designer.Windows.Models;

namespace Mad.Designer.Windows.Tests;

public sealed class ConnectionSpecTests
{
    [Fact]
    public void DriverToken_And_DefaultPort_AreCorrect()
    {
        Assert.Equal("sqlite3", ConnectionDriver.Sqlite3.Token());
        Assert.Equal(0, ConnectionDriver.Sqlite3.DefaultPort());
        Assert.Equal("mysql", ConnectionDriver.MySql.Token());
        Assert.Equal(3306, ConnectionDriver.MySql.DefaultPort());
        Assert.Equal("sqlserver", ConnectionDriver.SqlServer.Token());
        Assert.Equal(1433, ConnectionDriver.SqlServer.DefaultPort());
        Assert.Equal("postgres", ConnectionDriver.Postgres.Token());
        Assert.Equal(5432, ConnectionDriver.Postgres.DefaultPort());
    }

    [Fact]
    public void DriverFromToken_RoundTrips()
    {
        Assert.Equal(ConnectionDriver.Sqlite3, ConnectionSpec.DriverFromToken("sqlite3"));
        Assert.Equal(ConnectionDriver.MySql, ConnectionSpec.DriverFromToken("mysql"));
        Assert.Equal(ConnectionDriver.SqlServer, ConnectionSpec.DriverFromToken("sqlserver"));
        Assert.Equal(ConnectionDriver.Postgres, ConnectionSpec.DriverFromToken("postgres"));
    }

    [Fact]
    public void DriverFromToken_UnknownThrows()
    {
        Assert.Throws<ArgumentException>(() => ConnectionSpec.DriverFromToken("oracle"));
    }

    [Fact]
    public void CredentialKey_IsNullForSqlite_AndFormattedForServer()
    {
        var sqlite = new ConnectionSpec(ConnectionDriver.Sqlite3, "/db/chinook.sqlite3", null, null, null, null, null, null);
        Assert.Null(sqlite.CredentialKey);

        var mysql = new ConnectionSpec(ConnectionDriver.MySql, null, "db.example.com", 3306, "employees", null, "root", "pw");
        Assert.Equal("mysql:db.example.com:3306/employees", mysql.CredentialKey);
    }
}
