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

        var result = await CallAsync("open", parameters);
        return new OpenResult(
            result.GetProperty("handle").GetInt32(),
            result.GetProperty("filename").GetString() ?? "",
            result.GetProperty("driver").GetString() ?? "");
    }

    public async Task<DescribeResult> DescribeAsync(int handle)
    {
        var result = await CallAsync("describe", new Dictionary<string, object?> { ["handle"] = handle });

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
        var result = await CallAsync("query", new Dictionary<string, object?> { ["handle"] = handle });
        return result.GetProperty("sql").GetString() ?? "";
    }

    public async Task<RefreshResult> RefreshAsync(int handle, int? rows = null, string? credentials = null)
    {
        var parameters = new Dictionary<string, object?> { ["handle"] = handle };
        if (rows is int rowCount) parameters["rows"] = rowCount;
        if (credentials != null) parameters["credentials"] = credentials;

        var result = await CallAsync("refresh", parameters);
        return new RefreshResult(
            result.GetProperty("rowCount").GetInt32(),
            result.GetProperty("elapsed").GetDouble());
    }

    public async Task<string> ExportAsync(int handle, string format)
    {
        var result = await CallAsync("export", new Dictionary<string, object?> { ["handle"] = handle, ["format"] = format });
        return result.GetProperty("data").GetString() ?? "";
    }

    public async Task ShutdownAsync()
    {
        if (_client == null) return;

        await _gate.WaitAsync();
        try
        {
            if (_client.IsRunning)
            {
                await Task.Run(() => _client.Shutdown());
            }
        }
        finally
        {
            _gate.Release();
        }
    }

    public async ValueTask DisposeAsync()
    {
        await ShutdownAsync();
        _client?.Dispose();
        _gate.Dispose();
    }

    private async Task<JsonElement> CallAsync(string method, IReadOnlyDictionary<string, object?>? parameters = null)
    {
        await _gate.WaitAsync();
        try
        {
            EnsureStarted();
            MadEngineClient client = _client!;
            return await Task.Run(() => client.CallOk(method, parameters));
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
