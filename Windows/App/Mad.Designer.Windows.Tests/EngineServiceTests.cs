//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using System.Diagnostics;
using System.IO;
using System.Text.Json;
using System.Threading;
using Mad.Designer.Windows.Engine;
using Mad.Designer.Windows.Infrastructure;

// The context-detector test below blocks deliberately, to reproduce the OnClosed
// synchronous-dispose path; xUnit1031's deadlock warning is therefore expected there.
#pragma warning disable xUnit1031

namespace Mad.Designer.Windows.Tests;

[Collection("Engine")]
public sealed class EngineServiceTests
{
    [Fact]
    public async Task LondonFlow_OpenDescribeQueryRefreshExport_Completes()
    {
        await using var service = new EngineService();

        var open = await service.OpenAsync(MadPathResolver.DefaultDocument());
        Assert.True(open.Handle >= 0);
        Assert.Equal("Sqlite 3", open.Driver);
        Assert.True(service.Pid > 0);

        var describe = await service.DescribeAsync(open.Handle);
        Assert.Equal(21, describe.Columns.Count);
        Assert.Equal(11, describe.Tables.Count);
        Assert.Equal("\"Album0\".\"AlbumId\"", describe.Columns[0].Key);

        string sql = await service.QueryAsync(open.Handle);
        Assert.Contains("FROM", sql);

        var refresh = await service.RefreshAsync(open.Handle);
        Assert.Equal(76, refresh.RowCount);

        string json = await service.ExportAsync(open.Handle, "json");
        using var report = JsonDocument.Parse(json);
        Assert.Equal(76, report.RootElement.GetProperty("rows").GetArrayLength());

        string csv = await service.ExportAsync(open.Handle, "csv");
        var lines = csv.Split("\r\n", StringSplitOptions.None);
        Assert.Equal(78, lines.Length);
    }

    [Fact]
    public async Task EngineService_Dispose_StopsProcess()
    {
        int pid;
        await using (var service = new EngineService())
        {
            _ = await service.OpenAsync(MadPathResolver.DefaultDocument());
            pid = service.Pid;
            Assert.True(pid > 0);
        }

        for (int i = 0; i < 50; i++)
        {
            try
            {
                Process.GetProcessById(pid);
            }
            catch (ArgumentException)
            {
                return; // the process no longer exists
            }
            await Task.Delay(100);
        }
        Assert.Fail($"engine process {pid} is still running after disposal");
    }

    [Fact]
    public void EngineService_DoesNotCaptureSynchronizationContext()
    {
        var previous = SynchronizationContext.Current;
        SynchronizationContext.SetSynchronizationContext(new PostThrowingSynchronizationContext());
        try
        {
            var service = new EngineService();
            try
            {
                var open = service.OpenAsync(MadPathResolver.DefaultDocument()).GetAwaiter().GetResult();
                Assert.True(open.Handle >= 0);
                var describe = service.DescribeAsync(open.Handle).GetAwaiter().GetResult();
                Assert.Equal(21, describe.Columns.Count);
            }
            finally
            {
                service.DisposeAsync().GetAwaiter().GetResult();
            }
        }
        finally
        {
            SynchronizationContext.SetSynchronizationContext(previous);
        }
    }

    private sealed class PostThrowingSynchronizationContext : SynchronizationContext
    {
        public override void Post(SendOrPostCallback d, object? state)
            => throw new InvalidOperationException("an await posted to the captured synchronization context");
    }
}
