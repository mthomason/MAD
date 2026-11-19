//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using System.IO;
using Mad.Designer.Windows.Engine;
using Mad.Designer.Windows.Infrastructure;
using Mad.Designer.Windows.Models;
using Mad.Designer.Windows.ViewModels;

namespace Mad.Designer.Windows.Tests;

[Collection("Engine")]
public sealed class DocumentViewModelTests
{
    [Fact]
    public async Task OpenRefreshExport_London_Completes()
    {
        await using var engine = new EngineService();
        var viewModel = new DocumentViewModel(engine);

        await viewModel.OpenAsync(MadPathResolver.DefaultDocument());
        Assert.True(viewModel.HasDocument);
        Assert.Equal(21, viewModel.Columns.Count);
        Assert.Equal(11, viewModel.Tables.Count);
        Assert.Contains("FROM", viewModel.Sql);

        await viewModel.RefreshAsync();
        Assert.Equal(76, viewModel.RowCount);
        Assert.Equal(76, viewModel.DataView!.Count);

        string csvPath = Path.Combine(Path.GetTempPath(), $"mad-vm-{Guid.NewGuid():N}.csv");
        string jsonPath = Path.Combine(Path.GetTempPath(), $"mad-vm-{Guid.NewGuid():N}.json");
        try
        {
            await viewModel.ExportAsync("csv", csvPath);
            Assert.True(File.Exists(csvPath));
            var lines = File.ReadAllText(csvPath).Split("\r\n", StringSplitOptions.None);
            Assert.Equal(78, lines.Length);

            await viewModel.ExportAsync("json", jsonPath);
            Assert.True(File.Exists(jsonPath));
            var report = MadReport.Parse(File.ReadAllText(jsonPath));
            Assert.Equal(76, report.Rows.Count);
        }
        finally
        {
            if (File.Exists(csvPath)) File.Delete(csvPath);
            if (File.Exists(jsonPath)) File.Delete(jsonPath);
        }
    }

    [Fact]
    public async Task Open_BadDocument_SetsErrorAndStaysUsable()
    {
        await using var engine = new EngineService();
        var viewModel = new DocumentViewModel(engine);

        await viewModel.OpenAsync("no-such.mad");

        Assert.False(viewModel.HasDocument);
        Assert.False(string.IsNullOrEmpty(viewModel.ErrorText));
        Assert.False(viewModel.IsBusy);
    }

    [Fact]
    public async Task ExportAsync_UsesProvidedPath()
    {
        await using var engine = new EngineService();
        string target = Path.Combine(Path.GetTempPath(), $"mad-provided-{Guid.NewGuid():N}.csv");
        var viewModel = new DocumentViewModel(engine, exportPath: _ => target);

        try
        {
            await viewModel.OpenAsync(MadPathResolver.DefaultDocument());
            await viewModel.RefreshAsync();
            await viewModel.ExportAsync("csv");

            Assert.True(File.Exists(target));
            var lines = File.ReadAllText(target).Split("\r\n", StringSplitOptions.None);
            Assert.Equal(78, lines.Length);
        }
        finally
        {
            if (File.Exists(target)) File.Delete(target);
        }
    }

    [Fact]
    public async Task SaveAs_WritesCopy_AndUpdatesFilePath()
    {
        await using var engine = new EngineService();
        var viewModel = new DocumentViewModel(engine);
        string target = Path.Combine(Path.GetTempPath(), $"mad-saveas-{Guid.NewGuid():N}.mad");

        try
        {
            await viewModel.OpenAsync(MadPathResolver.DefaultDocument());
            await viewModel.SaveAsAsync(target);

            Assert.True(File.Exists(target));
            Assert.Equal(target, viewModel.FilePath);
        }
        finally
        {
            if (File.Exists(target)) File.Delete(target);
        }
    }

    [Fact]
    public async Task Save_WithNoDocument_SetsError()
    {
        await using var engine = new EngineService();
        var viewModel = new DocumentViewModel(engine);

        await viewModel.SaveAsync();

        Assert.False(string.IsNullOrEmpty(viewModel.ErrorText));
    }

    [Fact]
    public async Task GetConnection_ReturnsSqliteSpec()
    {
        await using var engine = new EngineService();
        var viewModel = new DocumentViewModel(engine);

        await viewModel.OpenAsync(MadPathResolver.DefaultDocument());
        var spec = await viewModel.GetConnectionAsync();

        Assert.NotNull(spec);
        Assert.Equal(ConnectionDriver.Sqlite3, spec.Driver);
    }
}
