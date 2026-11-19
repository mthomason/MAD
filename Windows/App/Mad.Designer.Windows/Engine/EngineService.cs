//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using System.IO;
using System.Text.Json;
using Mad.Client;
using Mad.Designer.Windows.Infrastructure;
using Mad.Designer.Windows.Models;

namespace Mad.Designer.Windows.Engine;

/// <summary>The async facade over the Phase 4 <see cref="MadEngineClient"/>. It owns the
/// long-lived `mad serve` child process and serializes every request/response pair through a
/// semaphore, because the client's line protocol is single-threaded by design. Each blocking
/// call runs on the thread pool so the UI thread never waits on the engine.</summary>
public sealed class EngineService : IAsyncDisposable
{
    private readonly string? _madExe;
    private readonly string? _gnustepBin;
    private readonly SemaphoreSlim _gate = new(1, 1);
    private MadEngineClient? _client;

    public EngineService(string? madExe = null, string? gnustepBin = null)
    {
        _madExe = madExe;
        _gnustepBin = gnustepBin;
    }

    public bool IsRunning => _client?.IsRunning ?? false;

    public int Pid => _client?.Pid ?? -1;

    public async Task<OpenResult> OpenAsync(string path, string? host = null, int? port = null, string? database = null)
    {
        var parameters = new Dictionary<string, object?> { ["path"] = path };
        if (host != null) parameters["host"] = host;
        if (port is int portValue) parameters["port"] = portValue;
        if (database != null) parameters["database"] = database;

        var result = await CallAsync("open", parameters).ConfigureAwait(false);
        return new OpenResult(
            result.GetProperty("handle").GetInt32(),
            result.GetProperty("filename").GetString() ?? "",
            result.GetProperty("driver").GetString() ?? "");
    }

    public async Task<DescribeResult> DescribeAsync(int handle)
    {
        var result = await CallAsync("describe", new Dictionary<string, object?> { ["handle"] = handle }).ConfigureAwait(false);

        var columns = new List<ReportColumn>();
        foreach (var column in result.GetProperty("columns").EnumerateArray())
        {
            columns.Add(new ReportColumn(
                column.GetProperty("key").GetString() ?? "",
                column.GetProperty("name").GetString() ?? "",
                column.GetProperty("table").GetString(),
                column.GetProperty("type").GetString()));
        }

        var tables = new List<SchemaTable>();
        foreach (var table in result.GetProperty("tables").EnumerateArray())
        {
            var fields = new List<SchemaField>();
            foreach (var field in table.GetProperty("fields").EnumerateArray())
            {
                fields.Add(new SchemaField(
                    field.GetProperty("name").GetString() ?? "",
                    field.GetProperty("type").GetString() ?? "",
                    field.GetProperty("primaryKey").GetBoolean()));
            }
            tables.Add(new SchemaTable(table.GetProperty("name").GetString() ?? "", fields));
        }

        return new DescribeResult(
            result.GetProperty("driver").GetString() ?? "",
            columns,
            tables);
    }

    public async Task<string> QueryAsync(int handle)
    {
        var result = await CallAsync("query", new Dictionary<string, object?> { ["handle"] = handle }).ConfigureAwait(false);
        return result.GetProperty("sql").GetString() ?? "";
    }

    public async Task<QueryModel> QueryModelAsync(int handle)
    {
        var result = await CallAsync("query-model", new Dictionary<string, object?> { ["handle"] = handle }).ConfigureAwait(false);
        return QueryModel.Parse(result);
    }

    public async Task<QueryModel> AddTableAsync(int handle, string table)
    {
        var result = await CallAsync("add-table", new Dictionary<string, object?> { ["handle"] = handle, ["table"] = table }).ConfigureAwait(false);
        return QueryModel.Parse(result);
    }

    public async Task<QueryModel> RemoveTableAsync(int handle, long table)
    {
        var result = await CallAsync("remove-table", new Dictionary<string, object?> { ["handle"] = handle, ["table"] = table }).ConfigureAwait(false);
        return QueryModel.Parse(result);
    }

    public async Task<QueryModel> AddLinkAsync(int handle, long leftField, long rightField)
    {
        var result = await CallAsync("add-link", new Dictionary<string, object?> { ["handle"] = handle, ["leftField"] = leftField, ["rightField"] = rightField }).ConfigureAwait(false);
        return QueryModel.Parse(result);
    }

    public async Task<QueryModel> SetLinkTypeAsync(int handle, long link, int type)
    {
        var result = await CallAsync("set-link-type", new Dictionary<string, object?> { ["handle"] = handle, ["link"] = link, ["type"] = type }).ConfigureAwait(false);
        return QueryModel.Parse(result);
    }

    public async Task<QueryModel> SwapLinkAsync(int handle, long link)
    {
        var result = await CallAsync("swap-link", new Dictionary<string, object?> { ["handle"] = handle, ["link"] = link }).ConfigureAwait(false);
        return QueryModel.Parse(result);
    }

    public async Task<QueryModel> DeleteLinkAsync(int handle, long link)
    {
        var result = await CallAsync("delete-link", new Dictionary<string, object?> { ["handle"] = handle, ["link"] = link }).ConfigureAwait(false);
        return QueryModel.Parse(result);
    }

    public async Task<QueryModel> AddPredicateAsync(int handle, long leftField, int op, string value)
    {
        var result = await CallAsync("add-predicate", new Dictionary<string, object?> { ["handle"] = handle, ["leftField"] = leftField, ["operator"] = op, ["value"] = value }).ConfigureAwait(false);
        return QueryModel.Parse(result);
    }

    public async Task<QueryModel> RemovePredicateAsync(int handle, long predicate)
    {
        var result = await CallAsync("remove-predicate", new Dictionary<string, object?> { ["handle"] = handle, ["predicate"] = predicate }).ConfigureAwait(false);
        return QueryModel.Parse(result);
    }

    public async Task<QueryModel> AddGroupAsync(int handle, long field, int sort)
    {
        var result = await CallAsync("add-group", new Dictionary<string, object?> { ["handle"] = handle, ["field"] = field, ["sort"] = sort }).ConfigureAwait(false);
        return QueryModel.Parse(result);
    }

    public async Task<QueryModel> RemoveGroupAsync(int handle, long group)
    {
        var result = await CallAsync("remove-group", new Dictionary<string, object?> { ["handle"] = handle, ["group"] = group }).ConfigureAwait(false);
        return QueryModel.Parse(result);
    }

    public async Task<SqlCompileResult> ValidateSqlAsync(int handle, string sql)
    {
        var result = await CallAsync("validate-sql", new Dictionary<string, object?> { ["handle"] = handle, ["sql"] = sql }).ConfigureAwait(false);
        return SqlCompileResult.Parse(result);
    }

    public async Task<SqlCompileResult> ApplySqlAsync(int handle, string sql)
    {
        var result = await CallAsync("apply-sql", new Dictionary<string, object?> { ["handle"] = handle, ["sql"] = sql }).ConfigureAwait(false);
        return SqlCompileResult.Parse(result);
    }

    public async Task<RefreshResult> RefreshAsync(int handle, int? rows = null, string? credentials = null)
    {
        var parameters = new Dictionary<string, object?> { ["handle"] = handle };
        if (rows is int rowCount) parameters["rows"] = rowCount;
        if (credentials != null) parameters["credentials"] = credentials;

        var result = await CallAsync("refresh", parameters).ConfigureAwait(false);
        return new RefreshResult(
            result.GetProperty("rowCount").GetInt32(),
            result.GetProperty("elapsed").GetDouble());
    }

    public async Task<string> ExportAsync(int handle, string format)
    {
        var result = await CallAsync("export", new Dictionary<string, object?> { ["handle"] = handle, ["format"] = format }).ConfigureAwait(false);
        return result.GetProperty("data").GetString() ?? "";
    }

    public async Task<int> TestConnectionAsync(ConnectionSpec spec)
    {
        var result = await CallAsync("test-connection", ConnectionParams(spec)).ConfigureAwait(false);
        return result.GetProperty("tableCount").GetInt32();
    }

    public async Task<OpenResult> CreateAsync(string path, ConnectionSpec spec)
    {
        var parameters = ConnectionParams(spec);
        parameters["path"] = path;
        var result = await CallAsync("create", parameters).ConfigureAwait(false);
        return new OpenResult(
            result.GetProperty("handle").GetInt32(),
            result.GetProperty("filename").GetString() ?? "",
            result.GetProperty("driver").GetString() ?? "");
    }

    public async Task<ConnectionSpec> ConnectionAsync(int handle)
    {
        var result = await CallAsync("connection", new Dictionary<string, object?> { ["handle"] = handle }).ConfigureAwait(false);
        var driver = ConnectionSpec.DriverFromToken(result.GetProperty("driver").GetString() ?? "");

        string? file = result.TryGetProperty("file", out var fileElement) ? fileElement.GetString() : null;
        if (!string.IsNullOrEmpty(file))
        {
            file = Path.GetFullPath(file); // GNUstep returns forward slashes on Windows
        }

        string? host = result.TryGetProperty("host", out var hostElement) ? hostElement.GetString() : null;
        int? port = result.TryGetProperty("port", out var portElement) ? portElement.GetInt32() : null;
        string? database = result.TryGetProperty("database", out var dbElement) ? dbElement.GetString() : null;
        string? server = result.TryGetProperty("server", out var serverElement) ? serverElement.GetString() : null;

        return new ConnectionSpec(driver, file, host, port, database, server, null, null);
    }

    public async Task ApplyConnectionAsync(int handle, ConnectionSpec spec)
    {
        var parameters = ConnectionParams(spec);
        parameters["handle"] = handle;
        await CallAsync("apply-connection", parameters).ConfigureAwait(false);
    }

    public async Task<WriteResult> WriteAsync(int handle, string outPath, bool reproducible = false)
    {
        var parameters = new Dictionary<string, object?> { ["handle"] = handle, ["out"] = outPath };
        if (reproducible) parameters["reproducible"] = true;
        var result = await CallAsync("write", parameters).ConfigureAwait(false);
        return new WriteResult(
            result.GetProperty("path").GetString() ?? "",
            result.GetProperty("bytes").GetInt64());
    }

    public async Task ShutdownAsync()
    {
        if (_client == null) return;

        await _gate.WaitAsync().ConfigureAwait(false);
        try
        {
            if (_client.IsRunning)
            {
                await Task.Run(() => _client.Shutdown()).ConfigureAwait(false);
            }
        }
        finally
        {
            _gate.Release();
        }
    }

    public async ValueTask DisposeAsync()
    {
        await ShutdownAsync().ConfigureAwait(false);
        _client?.Dispose();
        _gate.Dispose();
    }

    private static Dictionary<string, object?> ConnectionParams(ConnectionSpec spec)
    {
        var parameters = new Dictionary<string, object?> { ["driver"] = spec.Driver.Token() };
        if (spec.Driver == ConnectionDriver.Sqlite3)
        {
            parameters["file"] = spec.File;
        }
        else
        {
            parameters["host"] = spec.Host;
            parameters["port"] = spec.Port ?? spec.Driver.DefaultPort();
            parameters["database"] = spec.Database;
            if (spec.Driver == ConnectionDriver.SqlServer)
            {
                parameters["server"] = spec.ServerInstance;
            }
            if (!string.IsNullOrEmpty(spec.Username) || !string.IsNullOrEmpty(spec.Password))
            {
                parameters["credentials"] = $"{spec.Username}:{spec.Password}";
            }
        }
        return parameters;
    }

    private async Task<JsonElement> CallAsync(string method, IReadOnlyDictionary<string, object?>? parameters = null)
    {
        await _gate.WaitAsync().ConfigureAwait(false);
        try
        {
            EnsureStarted();
            MadEngineClient client = _client!;
            return await Task.Run(() => client.CallOk(method, parameters)).ConfigureAwait(false);
        }
        finally
        {
            _gate.Release();
        }
    }

    private void EnsureStarted()
    {
        if (_client != null) return;

        string madExe = _madExe ?? MadPathResolver.MadExe();
        if (!File.Exists(madExe))
        {
            throw new MadEngineException(-1, $"the engine executable was not found at {madExe}; build it first with Windows/Engine/build.ps1");
        }

        _client = new MadEngineClient(madExe, _gnustepBin ?? MadPathResolver.GnustepBin());
        try
        {
            _client.Start();
        }
        catch (Exception exception)
        {
            _client = null;
            throw new MadEngineException(-1, $"could not start the engine: {exception.Message}");
        }
    }
}
