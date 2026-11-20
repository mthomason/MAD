//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using System.Diagnostics;
using System.IO;
using System.Text.RegularExpressions;
using Mad.Designer.Windows.Engine;
using Mad.Designer.Windows.Infrastructure;
using Mad.Designer.Windows.Models;
using Mad.Designer.Windows.ViewModels;

namespace Mad.Designer.Windows.Tests;

/// <summary>The Viewer acceptance gate against the engine — the WPF equivalent of the Mac's
/// <c>MADMacSmokeTest</c> step 6 (page size drives the rendered output, every export format,
/// page count and status line).</summary>
[Collection("Engine")]
public sealed class ViewerAcceptanceTests
{
    private static readonly Regex PageSize = new(@"size: ([0-9.]+)pt ([0-9.]+)pt");

    [Fact]
    public async Task Refresh_RendersTheLondonReport()
    {
        await using var engine = new EngineService();
        var document = new DocumentViewModel(engine);

        await document.OpenAsync(MadPathResolver.DefaultDocument());
        Assert.Equal(0, document.Viewer.PageCount);
        Assert.Equal(ViewerStatusKind.Neutral, document.Viewer.StatusKind);
        Assert.Equal(ViewerViewModel.NotYetRefreshedText, document.Viewer.StatusText);

        await document.RefreshAsync();

        Assert.Equal(5, document.Viewer.PageCount);
        Assert.Equal(76, document.Viewer.RowCount);
        Assert.Equal("Rendered 5 pages from 76 cached rows.", document.Viewer.StatusText);
        Assert.Equal(ViewerStatusKind.Success, document.Viewer.StatusKind);
        Assert.Equal("Page 1 of 5", document.Viewer.PageLabel);
        Assert.NotNull(document.Viewer.PreviewHtml);
        AssertPageSize(document.Viewer.PreviewHtml!, 612.0, 792.0);

        await engine.ShutdownAsync();
    }

    [Fact]
    public async Task PageSize_IsLockedAtRefresh_AndPersistsAcrossRefresh()
    {
        await using var engine = new EngineService();
        var document = new DocumentViewModel(engine);
        await document.OpenAsync(MadPathResolver.DefaultDocument());
        await document.RefreshAsync();

        Assert.Equal((int)PaperSize.Letter, document.Viewer.RenderedPaperType);
        Assert.Equal("Rendered Page Size: US Letter", document.Viewer.PaperStatusText);

        // Selecting A4 does not touch the rendered report until the next refresh.
        document.Viewer.SelectedPaperIndex = 2; // A4
        Assert.Equal((int)PaperSize.A4, document.Viewer.SelectedPaperType);
        Assert.Equal((int)PaperSize.Letter, document.Viewer.RenderedPaperType);
        Assert.Equal("Rendered Page Size: US Letter", document.Viewer.PaperStatusText);
        AssertPageSize(document.Viewer.PreviewHtml!, 612.0, 792.0);

        await document.RefreshAsync();
        Assert.Equal((int)PaperSize.A4, document.Viewer.RenderedPaperType);
        Assert.Equal("Rendered Page Size: A4", document.Viewer.PaperStatusText);
        AssertPageSize(document.Viewer.PreviewHtml!, 595.0, 841.0);

        // The Designer's snapshot sees the same paper (the document applied it through its
        // own path, not straight to the engine).
        Assert.Equal((int)PaperSize.A4, document.Designer.Model.PaperSize);

        // The selection survives a refresh: still A4, still 595 x 842.
        await document.RefreshAsync();
        Assert.Equal((int)PaperSize.A4, document.Viewer.RenderedPaperType);
        AssertPageSize(document.Viewer.PreviewHtml!, 595.0, 841.0);

        // Changing the selection again without refreshing leaves the rendered paper alone;
        // an export still uses the rendered paper.
        document.Viewer.SelectedPaperIndex = 1; // US Legal
        string exported = Path.Combine(Path.GetTempPath(), $"mad-viewer-paper-{Guid.NewGuid():N}.html");
        try
        {
            document.Viewer.SelectedFormatIndex = 0; // HTML
            await document.Viewer.ExportAsync(exported);
            AssertPageSize(File.ReadAllText(exported), 595.0, 841.0);
        }
        finally
        {
            if (File.Exists(exported)) File.Delete(exported);
        }

        await engine.ShutdownAsync();
    }

    [Fact]
    public async Task Export_UsesTheRenderedPaper_NotAPaperChangedElsewhere()
    {
        await using var engine = new EngineService();
        var document = new DocumentViewModel(engine);
        await document.OpenAsync(MadPathResolver.DefaultDocument());
        await document.RefreshAsync(); // rendered at US Letter

        // The Designer's own paper selector changes the engine's layout behind the
        // Viewer's back (the Mac's Mac-only path). The preview still shows Letter, so the
        // export must re-assert the rendered paper, as the Mac's export panel does.
        await document.Designer.SetPaperSizeAsync((int)PaperSize.A4);
        Assert.Equal((int)PaperSize.A4, document.Designer.Model.PaperSize);
        Assert.Equal((int)PaperSize.Letter, document.Viewer.RenderedPaperType);

        string path = Path.Combine(Path.GetTempPath(), $"mad-viewer-paper-export-{Guid.NewGuid():N}.html");
        try
        {
            document.Viewer.SelectedFormatIndex = 0; // HTML
            await document.Viewer.ExportAsync(path);

            AssertPageSize(File.ReadAllText(path), 612.0, 792.0);
            // The re-assertion also pulls the Designer's snapshot back to the Viewer's paper.
            Assert.Equal((int)PaperSize.Letter, document.Designer.Model.PaperSize);
        }
        finally
        {
            if (File.Exists(path)) File.Delete(path);
        }

        await engine.ShutdownAsync();
    }

    [Fact]
    public async Task Export_WritesEveryFormat_WithItsExtension()
    {
        await using var engine = new EngineService();
        var document = new DocumentViewModel(engine);
        await document.OpenAsync(MadPathResolver.DefaultDocument());
        await document.RefreshAsync();

        var seen = new HashSet<string>();
        try
        {
            for (int i = 0; i < ViewerViewModel.ExportFormats.Count; i++)
            {
                var format = ViewerViewModel.ExportFormats[i];
                document.Viewer.SelectedFormatIndex = i;
                string path = Path.Combine(Path.GetTempPath(), $"mad-viewer-{Guid.NewGuid():N}.{format.Extension}");
                seen.Add(path);

                await document.Viewer.ExportAsync(path);

                Assert.True(File.Exists(path), $"{format.Format} did not write {path}");
                string content = File.ReadAllText(path);
                Assert.False(string.IsNullOrWhiteSpace(content), $"{format.Format} wrote nothing");
                Assert.StartsWith($"Exported {format.Format.ToUpperInvariant()} to ", document.Viewer.StatusText);
                Assert.Equal(ViewerStatusKind.Success, document.Viewer.StatusKind);

                switch (format.Format)
                {
                    case "csv":
                        Assert.Equal(78, content.Split("\r\n", StringSplitOptions.None).Length);
                        break;
                    case "json":
                        Assert.Equal(76, MadReport.Parse(content).Rows.Count);
                        break;
                    case "html":
                        AssertPageSize(content, 612.0, 792.0);
                        break;
                }
            }
        }
        finally
        {
            foreach (string path in seen)
            {
                if (File.Exists(path)) File.Delete(path);
            }
        }

        await engine.ShutdownAsync();
    }

    [Fact]
    public async Task PaperSizeChange_DrivesTheRenderedExport()
    {
        await using var engine = new EngineService();
        var open = await engine.OpenAsync(MadPathResolver.DefaultDocument());
        await engine.RefreshAsync(open.Handle);

        // A4 (MTPaperType 19) renders 595 x 842.
        await engine.SetPaperSizeAsync(open.Handle, 19);
        string a4 = await engine.ExportAsync(open.Handle, "html");
        AssertPageSize(a4, 595.0, 841.0);

        // Switching to US Legal (7) must reach the next export without another refresh:
        // the layout document's cached paper has to follow the stored paper size.
        await engine.SetPaperSizeAsync(open.Handle, 7);
        string legal = await engine.ExportAsync(open.Handle, "html");
        AssertPageSize(legal, 612.0, 1008.0);

        // And back to US Letter (2), 612 x 792.
        await engine.SetPaperSizeAsync(open.Handle, 2);
        string letter = await engine.ExportAsync(open.Handle, "html");
        AssertPageSize(letter, 612.0, 792.0);

        await engine.ShutdownAsync();
    }

    [Fact]
    public async Task CsvExport_IsByteIdenticalToTheOneShotCli()
    {
        await using var engine = new EngineService();
        var document = new DocumentViewModel(engine);
        await document.OpenAsync(MadPathResolver.DefaultDocument());
        await document.RefreshAsync();

        string viewerPath = Path.Combine(Path.GetTempPath(), $"mad-viewer-{Guid.NewGuid():N}.csv");
        string cliPath = Path.Combine(Path.GetTempPath(), $"mad-cli-{Guid.NewGuid():N}.csv");
        try
        {
            document.Viewer.SelectedFormatIndex = 2; // CSV Spreadsheet
            await document.Viewer.ExportAsync(viewerPath);
            await RunOneShotCliAsync("export", "--format", "csv", "--out", cliPath);

            Assert.Equal(File.ReadAllBytes(cliPath), File.ReadAllBytes(viewerPath));
            Assert.Equal(78, File.ReadAllText(viewerPath).Split("\r\n", StringSplitOptions.None).Length);
        }
        finally
        {
            if (File.Exists(viewerPath)) File.Delete(viewerPath);
            if (File.Exists(cliPath)) File.Delete(cliPath);
        }

        await engine.ShutdownAsync();
    }

    /// <summary>Runs `mad.exe` the way the CLI verbs are invoked, with GNUstep on PATH. Both
    /// streams are drained while the process runs: the engine logs enough to stderr to fill a
    /// pipe buffer and deadlock an unread process.</summary>
    private static async Task RunOneShotCliAsync(params string[] arguments)
    {
        var startInfo = new ProcessStartInfo
        {
            FileName = MadPathResolver.MadExe(),
            WorkingDirectory = MadPathResolver.RepoRoot(),
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            UseShellExecute = false,
        };
        foreach (string argument in arguments) startInfo.ArgumentList.Add(argument);
        startInfo.ArgumentList.Add(MadPathResolver.DefaultDocument());

        string inherited = Environment.GetEnvironmentVariable("PATH") ?? "";
        startInfo.Environment["PATH"] = MadPathResolver.GnustepBin() + Path.PathSeparator + inherited;

        using var process = Process.Start(startInfo);
        Assert.NotNull(process);
        Task<string> drainedOutput = process!.StandardOutput.ReadToEndAsync();
        Task<string> drainedError = process.StandardError.ReadToEndAsync();

        using var timeout = new CancellationTokenSource(TimeSpan.FromMinutes(2));
        try
        {
            await process.WaitForExitAsync(timeout.Token);
        }
        catch (OperationCanceledException)
        {
            process.Kill(entireProcessTree: true);
            throw new TimeoutException("mad export did not exit");
        }

        await drainedOutput;
        await drainedError;
        Assert.Equal(0, process.ExitCode);
    }

    private static void AssertPageSize(string html, double width, double height)
    {
        Match match = PageSize.Match(html);
        Assert.True(match.Success, "the HTML export carries no @page size");
        Assert.InRange(double.Parse(match.Groups[1].Value), width - 1.0, width + 1.0);
        Assert.InRange(double.Parse(match.Groups[2].Value), height - 1.0, height + 1.0);
    }
}
