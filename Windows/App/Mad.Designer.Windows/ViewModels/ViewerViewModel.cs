//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using System.IO;
using System.Text.RegularExpressions;
using Mad.Designer.Windows.Engine;
using Mad.Designer.Windows.Infrastructure;
using Mad.Designer.Windows.Models;

namespace Mad.Designer.Windows.ViewModels;

/// <summary>How a Viewer status line should be drawn: the neutral waiting text, a green
/// success line, or a red failure line.</summary>
public enum ViewerStatusKind
{
    Neutral,
    Success,
    Error,
}

/// <summary>One selectable paper size, with the engine's <c>MTPaperType</c> value.</summary>
public sealed record PaperOption(int Type, string DisplayName, string ShortName);

/// <summary>One export format the Windows engine can produce, in the Mac viewer's order.</summary>
public sealed record ViewerExportFormat(string Format, string Title, string Extension);

/// <summary>The MAD Viewer workspace's view model — the WPF counterpart of the Mac's
/// <c>MADMacViewerViewController</c>. With no PDFKit on Windows the preview renders the
/// engine's own HTML facsimile (one page box per page) in a WebView2; the page count comes
/// from that export, so the engine stays the only paginator. It owns the page-size selection
/// and its rendered lock, zoom, page navigation, the export format catalogue, and the status
/// line. Refreshing is the document's job: <see cref="LoadAsync"/> receives the document's
/// refresh delegate so the Viewer's Refresh button runs the same live-data path.</summary>
public sealed class ViewerViewModel : ObservableObject
{
    /// <summary>The Mac's status line, with its singular/plural grammar.</summary>
    public static string StatusMessage(int pageCount, int rowCount)
    {
        string pages = pageCount == 1 ? "1 page" : $"{pageCount} pages";
        string rows = rowCount == 1 ? "1 cached row" : $"{rowCount} cached rows";
        return $"Rendered {pages} from {rows}.";
    }

    public const string NotYetRefreshedText =
        "Not yet refreshed. Click “Refresh” to query the database and render the report.";

    public static IReadOnlyList<PaperOption> PaperOptions { get; } = new[]
    {
        new PaperOption((int)PaperSize.Letter, "US Letter (8.5 × 11 in)", "US Letter"),
        new PaperOption((int)PaperSize.Legal, "US Legal (8.5 × 14 in)", "US Legal"),
        new PaperOption((int)PaperSize.A4, "A4 (210 × 297 mm)", "A4"),
    };

    /// <summary>The Windows engine's exporters, minus PDF (an accepted gap).</summary>
    public static IReadOnlyList<ViewerExportFormat> ExportFormats { get; } = new[]
    {
        new ViewerExportFormat("html", "HTML Page (.html)", "html"),
        new ViewerExportFormat("html-flow", "HTML Flow (.html)", "html"),
        new ViewerExportFormat("csv", "CSV Spreadsheet (.csv)", "csv"),
        new ViewerExportFormat("json", "JSON Data (.json)", "json"),
        new ViewerExportFormat("json-report", "JSON Full Report (.json)", "json"),
        new ViewerExportFormat("text", "Plain Text (.txt)", "txt"),
    };

    // The HTML exporter writes one `<div class="page" data-index="N">` per rendered page.
    private static readonly Regex PageDiv = new("<div class=\"page\" data-index=\"", RegexOptions.Compiled);

    private readonly EngineService _engine;
    private readonly Func<string, string?>? _exportPath;
    private int _handle = -1;
    private Func<Task>? _refresh;
    private Func<int, Task>? _setPaperSize;
    private int _selectedPaperIndex;
    private int _selectedFormatIndex;
    private int _renderedPaperType = (int)PaperSize.Letter;
    private double _zoom = 1.0;
    private int _pageCount;
    private int _currentPage;
    private int _rowCount;
    private string? _previewHtml;
    private string _statusText = NotYetRefreshedText;
    private ViewerStatusKind _statusKind = ViewerStatusKind.Neutral;

    public ViewerViewModel(EngineService engine, Func<string, string?>? exportPath = null)
    {
        _engine = engine ?? throw new ArgumentNullException(nameof(engine));
        _exportPath = exportPath;

        ZoomInCommand = new RelayCommand(() => SetZoom(_zoom * 1.25));
        ZoomOutCommand = new RelayCommand(() => SetZoom(_zoom / 1.25));
        ResetZoomCommand = new RelayCommand(() => SetZoom(1.0));
        PreviousPageCommand = new RelayCommand(GoToPreviousPage, () => CanGoPrevious);
        NextPageCommand = new RelayCommand(GoToNextPage, () => CanGoNext);
        RefreshCommand = new AsyncRelayCommand(() => _refresh?.Invoke() ?? Task.CompletedTask, () => HasDocument && _refresh != null);
        ExportCommand = new AsyncRelayCommand(ExportToChosenPathAsync, () => HasDocument);
        PrintCommand = new RelayCommand(() => _ = PrintAsync(), () => HasDocument);
    }

    /// <summary>Raised when the user asks to print; the view prints the preview through the
    /// WebView2 print path (the interim HTML print).</summary>
    public event EventHandler? PrintRequested;

    /// <summary>The page the preview should scroll to, zero-based, or -1 for none.</summary>
    public int PreviewPageIndex => _pageCount > 0 ? _currentPage - 1 : -1;

    public bool HasDocument => _handle >= 0;

    public AsyncRelayCommand RefreshCommand { get; }
    public AsyncRelayCommand ExportCommand { get; }
    public RelayCommand PrintCommand { get; }
    public RelayCommand ZoomInCommand { get; }
    public RelayCommand ZoomOutCommand { get; }
    public RelayCommand ResetZoomCommand { get; }
    public RelayCommand PreviousPageCommand { get; }
    public RelayCommand NextPageCommand { get; }

    public int SelectedPaperIndex
    {
        get => _selectedPaperIndex;
        set
        {
            int index = Math.Clamp(value, 0, PaperOptions.Count - 1);
            if (Set(ref _selectedPaperIndex, index))
            {
                OnPropertyChanged(nameof(SelectedPaperType));
            }
        }
    }

    public int SelectedPaperType => PaperOptions[_selectedPaperIndex].Type;

    /// <summary>The paper the last render used — selection alone never changes it (the Mac
    /// locks it at refresh time).</summary>
    public int RenderedPaperType
    {
        get => _renderedPaperType;
        private set
        {
            if (Set(ref _renderedPaperType, value))
            {
                OnPropertyChanged(nameof(PaperStatusText));
            }
        }
    }

    public string PaperStatusText => $"Rendered Page Size: {OptionForType(_renderedPaperType).ShortName}";

    private static PaperOption OptionForType(int type)
        => PaperOptions.FirstOrDefault(option => option.Type == type) ?? PaperOptions[0];

    public int SelectedFormatIndex
    {
        get => _selectedFormatIndex;
        set
        {
            int index = Math.Clamp(value, 0, ExportFormats.Count - 1);
            if (Set(ref _selectedFormatIndex, index))
            {
                OnPropertyChanged(nameof(SelectedFormat));
            }
        }
    }

    public ViewerExportFormat SelectedFormat => ExportFormats[_selectedFormatIndex];

    public double Zoom
    {
        get => _zoom;
        set => SetZoom(value);
    }

    public string ZoomText => $"{Math.Round(_zoom * 100.0)}%";

    public int PageCount
    {
        get => _pageCount;
        private set
        {
            if (Set(ref _pageCount, value))
            {
                OnPropertyChanged(nameof(PageLabel));
                RaiseNavigationChanged();
            }
        }
    }

    public int CurrentPage
    {
        get => _currentPage;
        private set
        {
            if (Set(ref _currentPage, value))
            {
                OnPropertyChanged(nameof(PageLabel));
                OnPropertyChanged(nameof(PreviewPageIndex));
                RaiseNavigationChanged();
            }
        }
    }

    public string PageLabel => _pageCount == 0 ? "Page 0 of 0" : $"Page {_currentPage} of {_pageCount}";

    public bool CanGoPrevious => _pageCount > 0 && _currentPage > 1;
    public bool CanGoNext => _pageCount > 0 && _currentPage < _pageCount;

    public int RowCount { get => _rowCount; private set => Set(ref _rowCount, value); }

    /// <summary>The report HTML the preview shows — the engine's <c>html</c> export bytes.</summary>
    public string? PreviewHtml { get => _previewHtml; private set => Set(ref _previewHtml, value); }

    public string StatusText { get => _statusText; private set => Set(ref _statusText, value); }
    public ViewerStatusKind StatusKind { get => _statusKind; private set => Set(ref _statusKind, value); }

    /// <summary>Counts the engine's page boxes in an HTML facsimile.</summary>
    public static int CountPages(string html) => PageDiv.Matches(html).Count;

    /// <summary>Binds the view model to an open document. <paramref name="refresh"/> runs the
    /// document's live-data refresh (which calls back into <see cref="RenderAsync"/>);
    /// <paramref name="setPaperSize"/> lets the document apply the paper through its own path
    /// (so the Designer's snapshot stays in step).</summary>
    public Task LoadAsync(int handle, Func<Task> refresh, Func<int, Task>? setPaperSize = null)
    {
        _handle = handle;
        _refresh = refresh;
        _setPaperSize = setPaperSize;

        SelectedPaperIndex = 0;
        SelectedFormatIndex = 0;
        RenderedPaperType = (int)PaperSize.Letter;
        PageCount = 0;
        CurrentPage = 0;
        RowCount = 0;
        PreviewHtml = null;
        SetStatus(NotYetRefreshedText, ViewerStatusKind.Neutral);

        OnPropertyChanged(nameof(HasDocument));
        RaiseCommandsChanged();
        return Task.CompletedTask;
    }

    /// <summary>Presents an already-produced HTML facsimile and its row count. Public so the
    /// render step and tests share the same path the engine export feeds.</summary>
    public void SetRenderedHtml(string html, int rowCount)
    {
        RowCount = rowCount;
        PreviewHtml = html;
        PageCount = CountPages(html);
        CurrentPage = PageCount > 0 ? 1 : 0;
        SetStatus(StatusMessage(PageCount, rowCount), ViewerStatusKind.Success);
    }

    /// <summary>Lays the report out for the selected paper and loads its HTML preview.
    /// Called by the document after a successful refresh.</summary>
    public async Task RenderAsync(int rowCount)
    {
        if (!HasDocument) return;

        int paper = SelectedPaperType;
        try
        {
            if (_setPaperSize != null)
            {
                await _setPaperSize(paper);
            }
            else
            {
                await _engine.SetPaperSizeAsync(_handle, paper);
            }
            RenderedPaperType = paper;

            string html = await _engine.ExportAsync(_handle, "html");
            SetRenderedHtml(html, rowCount);
        }
        catch (Exception exception)
        {
            RenderedPaperType = paper;
            PreviewHtml = null;
            PageCount = 0;
            CurrentPage = 0;
            SetStatus(exception.Message, ViewerStatusKind.Error);
        }
    }

    /// <summary>Shows the in-flight status line while a refresh runs.</summary>
    public void BeginRefresh()
    {
        SetStatus("Executing SQL query and formatting report pages…", ViewerStatusKind.Neutral);
    }

    /// <summary>Reports a refresh failure on the status line.</summary>
    public void ReportRefreshFailed(string message)
    {
        SetStatus(message, ViewerStatusKind.Error);
    }

    /// <summary>Exports the rendered report in the selected format to <paramref name="outPath"/>.
    /// If nothing is rendered yet the report is refreshed first, as the Mac's Export does.</summary>
    public async Task ExportAsync(string outPath)
    {
        if (!HasDocument) return;

        try
        {
            if (_pageCount == 0 && _refresh != null)
            {
                await _refresh();
            }

            string data = await _engine.ExportAsync(_handle, SelectedFormat.Format);
            await File.WriteAllTextAsync(outPath, data);
            SetStatus($"Exported {SelectedFormat.Format.ToUpperInvariant()} to {Path.GetFileName(outPath)}",
                ViewerStatusKind.Success);
        }
        catch (Exception exception)
        {
            SetStatus(exception.Message, ViewerStatusKind.Error);
        }
    }

    private async Task ExportToChosenPathAsync()
    {
        string? path = _exportPath?.Invoke(SelectedFormat.Format);
        if (_exportPath != null && string.IsNullOrEmpty(path))
        {
            return; // the user cancelled the save dialog
        }
        path ??= Path.Combine(Path.GetTempPath(), $"mad-export-{Guid.NewGuid():N}.{SelectedFormat.Extension}");
        await ExportAsync(path);
    }

    private async Task PrintAsync()
    {
        if (!HasDocument) return;
        if (_pageCount == 0 && _refresh != null)
        {
            await _refresh();
        }
        if (_pageCount > 0)
        {
            PrintRequested?.Invoke(this, EventArgs.Empty);
        }
    }

    private void SetZoom(double zoom)
    {
        double clamped = Math.Clamp(zoom, 0.25, 4.0);
        if (Set(ref _zoom, clamped, nameof(Zoom)))
        {
            OnPropertyChanged(nameof(ZoomText));
        }
    }

    private void GoToPreviousPage()
    {
        if (CanGoPrevious) CurrentPage = _currentPage - 1;
    }

    private void GoToNextPage()
    {
        if (CanGoNext) CurrentPage = _currentPage + 1;
    }

    private void SetStatus(string text, ViewerStatusKind kind)
    {
        StatusText = text;
        StatusKind = kind;
    }

    private void RaiseNavigationChanged()
    {
        PreviousPageCommand.RaiseCanExecuteChanged();
        NextPageCommand.RaiseCanExecuteChanged();
    }

    private void RaiseCommandsChanged()
    {
        RefreshCommand.RaiseCanExecuteChanged();
        ExportCommand.RaiseCanExecuteChanged();
        PrintCommand.RaiseCanExecuteChanged();
        RaiseNavigationChanged();
    }
}
