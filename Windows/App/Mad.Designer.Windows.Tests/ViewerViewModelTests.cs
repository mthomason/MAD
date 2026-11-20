//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using System.IO;
using Mad.Designer.Windows.Engine;
using Mad.Designer.Windows.Models;
using Mad.Designer.Windows.ViewModels;

namespace Mad.Designer.Windows.Tests;

/// <summary>The Viewer view model's engine-free behaviour — the status-line grammar, the export
/// format catalogue, page counting from the engine's HTML, zoom, and page navigation.</summary>
public sealed class ViewerViewModelTests
{
    [Fact]
    public void StatusMessage_PluralizesPagesAndRows()
    {
        Assert.Equal("Rendered 0 pages from 0 cached rows.", ViewerViewModel.StatusMessage(0, 0));
        Assert.Equal("Rendered 1 page from 1 cached row.", ViewerViewModel.StatusMessage(1, 1));
        Assert.Equal("Rendered 3 pages from 42 cached rows.", ViewerViewModel.StatusMessage(3, 42));
        Assert.Equal("Rendered 1 page from 76 cached rows.", ViewerViewModel.StatusMessage(1, 76));
        Assert.Equal("Rendered 5 pages from 1 cached row.", ViewerViewModel.StatusMessage(5, 1));
    }

    [Fact]
    public void ExportFormats_AreTheSixAvailableOnWindows()
    {
        Assert.Equal(
            new[] { "html", "html-flow", "csv", "json", "json-report", "text" },
            ViewerViewModel.ExportFormats.Select(f => f.Format).ToArray());
        Assert.DoesNotContain(ViewerViewModel.ExportFormats, f => f.Format == "pdf");

        var byFormat = ViewerViewModel.ExportFormats.ToDictionary(f => f.Format, f => f.Extension);
        Assert.Equal("html", byFormat["html"]);
        Assert.Equal("html", byFormat["html-flow"]);
        Assert.Equal("csv", byFormat["csv"]);
        Assert.Equal("json", byFormat["json"]);
        Assert.Equal("json", byFormat["json-report"]);
        Assert.Equal("txt", byFormat["text"]);

        Assert.Equal("HTML Page (.html)", ViewerViewModel.ExportFormats[0].Title);
        Assert.Equal("Plain Text (.txt)", ViewerViewModel.ExportFormats[^1].Title);
    }

    [Fact]
    public void PaperOptions_AreLetterLegalA4_AndLetterIsTheDefault()
    {
        Assert.Equal(
            new[] { (int)PaperSize.Letter, (int)PaperSize.Legal, (int)PaperSize.A4 },
            ViewerViewModel.PaperOptions.Select(p => p.Type).ToArray());

        var vm = new ViewerViewModel(new EngineService());
        Assert.Equal(0, vm.SelectedPaperIndex);
        Assert.Equal((int)PaperSize.Letter, vm.SelectedPaperType);
        Assert.Equal((int)PaperSize.Letter, vm.RenderedPaperType);
        Assert.Equal("Rendered Page Size: US Letter", vm.PaperStatusText);
    }

    [Fact]
    public void NotYetLoaded_StatusIsNeutral()
    {
        var vm = new ViewerViewModel(new EngineService());

        Assert.Equal(ViewerStatusKind.Neutral, vm.StatusKind);
        Assert.Equal(
            "Not yet refreshed. Click “Refresh” to query the database and render the report.",
            vm.StatusText);
        Assert.Equal(0, vm.PageCount);
        Assert.Equal(0, vm.CurrentPage);
        Assert.Equal("Page 0 of 0", vm.PageLabel);
        Assert.Null(vm.PreviewHtml);
    }

    [Fact]
    public void SetRenderedHtml_CountsPages_AndReportsSuccess()
    {
        var vm = new ViewerViewModel(new EngineService());

        vm.SetRenderedHtml(BuildHtml(3), rowCount: 42);

        Assert.Equal(3, vm.PageCount);
        Assert.Equal(1, vm.CurrentPage);
        Assert.Equal("Page 1 of 3", vm.PageLabel);
        Assert.Equal(42, vm.RowCount);
        Assert.Equal("Rendered 3 pages from 42 cached rows.", vm.StatusText);
        Assert.Equal(ViewerStatusKind.Success, vm.StatusKind);
        Assert.NotNull(vm.PreviewHtml);
        Assert.True(vm.CanGoNext);
        Assert.False(vm.CanGoPrevious);
    }

    [Fact]
    public void CountPages_IgnoresTheStylesheetUsesOfThePageClass()
    {
        const string html = """
            <style>.page { position: relative } .page:first-of-type { break-before: auto }</style>
            <body>
            <div class="page" data-index="0" style="width: 612pt"></div>
            <div class="page" data-index="1" style="width: 612pt"></div>
            </body>
            """;

        Assert.Equal(2, ViewerViewModel.CountPages(html));
        Assert.Equal(0, ViewerViewModel.CountPages("<html><body>no pages</body></html>"));
    }

    [Fact]
    public void Zoom_StepsClampsAndResets()
    {
        var vm = new ViewerViewModel(new EngineService());
        Assert.Equal(1.0, vm.Zoom);
        Assert.Equal("100%", vm.ZoomText);

        vm.ZoomInCommand.Execute(null);
        Assert.Equal(1.25, vm.Zoom, 6);
        Assert.Equal("125%", vm.ZoomText);

        for (int i = 0; i < 20; i++) vm.ZoomInCommand.Execute(null);
        Assert.Equal(4.0, vm.Zoom, 6);

        vm.ResetZoomCommand.Execute(null);
        Assert.Equal(1.0, vm.Zoom, 6);

        for (int i = 0; i < 20; i++) vm.ZoomOutCommand.Execute(null);
        Assert.Equal(0.25, vm.Zoom, 6);
    }

    [Fact]
    public void Navigation_StepsWithinBounds()
    {
        var vm = new ViewerViewModel(new EngineService());
        vm.SetRenderedHtml(BuildHtml(3), rowCount: 10);

        Assert.False(vm.PreviousPageCommand.CanExecute(null));
        Assert.True(vm.NextPageCommand.CanExecute(null));

        vm.NextPageCommand.Execute(null);
        vm.NextPageCommand.Execute(null);
        Assert.Equal(3, vm.CurrentPage);
        Assert.Equal("Page 3 of 3", vm.PageLabel);
        Assert.True(vm.PreviousPageCommand.CanExecute(null));
        Assert.False(vm.NextPageCommand.CanExecute(null));

        vm.PreviousPageCommand.Execute(null);
        Assert.Equal(2, vm.CurrentPage);
    }

    [Fact]
    public async Task Export_AfterAFailedRefresh_LeavesTheErrorAndWritesNothing()
    {
        var vm = new ViewerViewModel(new EngineService());
        string path = Path.Combine(Path.GetTempPath(), $"mad-viewer-failed-{Guid.NewGuid():N}.html");
        await vm.LoadAsync(0, () =>
        {
            vm.ReportRefreshFailed("the database is unreachable");
            return Task.FromResult(false);
        });

        try
        {
            await vm.ExportAsync(path);

            Assert.False(File.Exists(path), "a failed refresh must not export a file");
            Assert.Equal(ViewerStatusKind.Error, vm.StatusKind);
            Assert.Equal("the database is unreachable", vm.StatusText);
        }
        finally
        {
            if (File.Exists(path)) File.Delete(path);
        }
    }

    [Fact]
    public async Task Print_WithARenderedPreview_RaisesAPrintRequest()
    {
        var vm = new ViewerViewModel(new EngineService());
        await vm.LoadAsync(0, () => Task.FromResult(true));
        vm.SetRenderedHtml(BuildHtml(2), rowCount: 10);

        int requests = 0;
        vm.PrintRequested += (_, _) => requests++;
        vm.PrintCommand.Execute(null);

        Assert.Equal(1, requests);
    }

    [Fact]
    public async Task Print_WhenNothingIsRendered_RefreshesFirst()
    {
        var vm = new ViewerViewModel(new EngineService());
        int refreshes = 0;
        await vm.LoadAsync(0, () =>
        {
            refreshes++;
            vm.SetRenderedHtml(BuildHtml(1), rowCount: 1);
            return Task.FromResult(true);
        });

        int requests = 0;
        vm.PrintRequested += (_, _) => requests++;
        vm.PrintCommand.Execute(null);
        await Task.Yield();
        await Task.Delay(50); // the command runs the refresh on the dispatcher-free thread pool path

        Assert.Equal(1, refreshes);
        Assert.Equal(1, requests);
    }

    private static string BuildHtml(int pages)
    {
        var html = new System.Text.StringBuilder("<html><body>\n");
        for (int i = 0; i < pages; i++)
        {
            html.Append($"<div class=\"page\" data-index=\"{i}\" style=\"width: 612pt; height: 792pt\"></div>\n");
        }
        html.Append("</body></html>");
        return html.ToString();
    }
}
