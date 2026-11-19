//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

namespace Mad.Designer.Windows.Models;

/// <summary>The four database drivers the connection assistant offers, mirroring the
/// Mac's <c>MADMacConnectionWindowController</c>.</summary>
public enum ConnectionDriver
{
    Sqlite3,
    MySql,
    SqlServer,
    Postgres,
}

public static class ConnectionDriverExtensions
{
    /// <summary>The `serve` protocol's driver token ("sqlserver" is the wire name for TDS).</summary>
    public static string Token(this ConnectionDriver driver) => driver switch
    {
        ConnectionDriver.Sqlite3 => "sqlite3",
        ConnectionDriver.MySql => "mysql",
        ConnectionDriver.SqlServer => "sqlserver",
        ConnectionDriver.Postgres => "postgres",
        _ => throw new ArgumentOutOfRangeException(nameof(driver)),
    };

    /// <summary>The driver's default server port; 0 for SQLite (which has none).</summary>
    public static int DefaultPort(this ConnectionDriver driver) => driver switch
    {
        ConnectionDriver.MySql => 3306,
        ConnectionDriver.SqlServer => 1433,
        ConnectionDriver.Postgres => 5432,
        _ => 0,
    };
}

/// <summary>The connection window's collected state, passed to the engine as
/// `test-connection` / `create` / `apply-connection` params.</summary>
public sealed record ConnectionSpec(
    ConnectionDriver Driver,
    string? File,
    string? Host,
    int? Port,
    string? Database,
    string? ServerInstance,
    string? Username,
    string? Password)
{
    public static ConnectionDriver DriverFromToken(string token) => token switch
    {
        "sqlite3" => ConnectionDriver.Sqlite3,
        "mysql" => ConnectionDriver.MySql,
        "sqlserver" => ConnectionDriver.SqlServer,
        "postgres" => ConnectionDriver.Postgres,
        _ => throw new ArgumentException($"unknown driver token '{token}'.", nameof(token)),
    };

    /// <summary>The Credential Manager key for a server connection, or null for SQLite
    /// (which stores no credentials).</summary>
    public string? CredentialKey => Driver == ConnectionDriver.Sqlite3
        ? null
        : $"{Driver.Token()}:{Host}:{Port}/{Database}";
}
