//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using System.Data;
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
        string pages = pageCount == 1
            ? Localizer.Get("Viewer.Pages.One")
            : Localizer.Format("Viewer.Pages.Many", pageCount);
        string rows = rowCount == 1
            ? Localizer.Get("Viewer.Rows.One")
            : Localizer.Format("Viewer.Rows.Many", rowCount);
        return Localizer.Format("Viewer.Status", pages, rows);
    }

    public static string NotYetRefreshedText => Localizer.Get("Viewer.NotYetRefreshed");

    public static IReadOnlyList<PaperOption> PaperOptions => new[]
    {
        new PaperOption((int)PaperSize.Letter, Localizer.Get("Paper.Letter.Display"), Localizer.Get("Paper.Letter")),
        new PaperOption((int)PaperSize.Legal, Localizer.Get("Paper.Legal.Display"), Localizer.Get("Paper.Legal")),
        new PaperOption((int)PaperSize.A4, Localizer.Get("Paper.A4.Display"), Localizer.Get("Paper.A4")),
    };

    /// <summary>The engine's exporters in the Mac viewer's order, PDF first.</summary>
    public static IReadOnlyList<ViewerExportFormat> ExportFormats => new[]
    {
        new ViewerExportFormat("pdf", Localizer.Get("Format.Pdf"), "pdf"),
        new ViewerExportFormat("html", Localizer.Get("Format.Html"), "html"),
        new ViewerExportFormat("html-flow", Localizer.Get("Format.HtmlFlow"), "html"),
        new ViewerExportFormat("csv", Localizer.Get("Format.Csv"), "csv"),
        new ViewerExportFormat("json", Localizer.Get("Format.Json"), "json"),
        new ViewerExportFormat("json-report", Localizer.Get("Format.JsonReport"), "json"),
        new ViewerExportFormat("text", Localizer.Get("Format.Text"), "txt"),
    };

    // The HTML exporter writes one `<div class="page" data-index="N">` per rendered page.
    private static readonly Regex PageDiv = new("<div class=\"page\" data-index=\"", RegexOptions.Compiled);

    private readonly EngineService _engine;
    private readonly Func<string, string?>? _exportPath;
    private int _handle = -1;
    private long _queryId;
    private bool _isNodeReportRoot = true;
    private Func<Task<bool>>? _refresh;
    private Func<int, Task>? _setPaperSize;
    private int _selectedPaperIndex;
    private int _selectedFormatIndex;
    private int _renderedPaperType = (int)PaperSize.Letter;
    private double _zoom = 1.0;
    private int _pageCount;
    private int _currentPage;
    private int _rowCount;
    private string? _previewHtml;
    private DataView? _nodeRows;
    private bool _isRowGrid;
    private string _statusText = NotYetRefreshedText;
    private ViewerStatusKind _statusKind = ViewerStatusKind.Neutral;
    private bool _isExporting;

    public ViewerViewModel(EngineService engine, Func<string, string?>? exportPath = null)
    {
        _engine = engine ?? throw new ArgumentNullException(nameof(engine));
        _exportPath = exportPath;

        ZoomInCommand = new RelayCommand(() => SetZoom(_zoom * 1.25));
        ZoomOutCommand = new RelayCommand(() => SetZoom(_zoom / 1.25));
        ResetZoomCommand = new RelayCommand(() => SetZoom(1.0));
        PreviousPageCommand = new RelayCommand(GoToPreviousPage, () => CanGoPrevious);
        NextPageCommand = new RelayCommand(GoToNextPage, () => CanGoNext);
        RefreshCommand = new AsyncRelayCommand(RefreshCoreAsync, () => HasDocument && _refresh != null && !_isExporting);
        ExportCommand = new AsyncRelayCommand(ExportToChosenPathAsync, () => HasDocument && !_isExporting);
        PrintCommand = new RelayCommand(() => _ = PrintAsync(), () => HasDocument && !_isExporting);
    }

    /// <summary>Raised when the user asks to print; the view prints the preview through the
    /// WebView2 print path (the interim HTML print).</summary>
    public event EventHandler? PrintRequested;

    /// <summary>The page the preview should scroll to, zero-based, or -1 for none.</summary>
    public int PreviewPageIndex => _pageCount > 0 ? _currentPage - 1 : -1;

    public bool HasDocument => _handle >= 0;

    /// <summary>The node the Viewer shows. Selecting another node clears the previous node's
    /// HTML/rows first, so one report never flashes through while the next loads.</summary>
    public long QueryId
    {
        get => _queryId;
        set
        {
            if (Set(ref _queryId, value)) ClearRendered();
        }
    }

    /// <summary>Discards the previous render (pages, HTML, and row grid) and returns the status
    /// line to its neutral waiting text. Called when the selected node changes.</summary>
    public void ClearRendered()
    {
        PreviewHtml = null;
        PageCount = 0;
        CurrentPage = 0;
        SetNodeRows(null);
        SetStatus(NotYetRefreshedText, ViewerStatusKind.Neutral);
    }

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

    public string PaperStatusText => Localizer.Format("Viewer.PaperStatus", OptionForType(_renderedPaperType).ShortName);

    private static PaperOption OptionForType(int type)
        => PaperOptions.FirstOrDefault(option => option.Type == type) ?? PaperOptions[0];

    /// <summary>The selected node's report identity: the Result (or a Standard Report's single
    /// query) is the report root. Only the root may export <c>json-report</c>; a source's export
    /// list drops it.</summary>
    public bool IsNodeReportRoot
    {
        get => _isNodeReportRoot;
        set
        {
            if (Set(ref _isNodeReportRoot, value))
            {
                // Keep the chosen index inside the (possibly shorter) list, then republish it.
                if (_selectedFormatIndex >= AvailableExportFormats.Count)
                {
                    _selectedFormatIndex = AvailableExportFormats.Count - 1;
                }
                OnPropertyChanged(nameof(AvailableExportFormats));
                OnPropertyChanged(nameof(SelectedFormatIndex));
                OnPropertyChanged(nameof(SelectedFormat));
            }
        }
    }

    /// <summary>The formats offered for the selected node, in the catalogue's order. A source
    /// (a non-root node) drops <c>json-report</c>, which the engine refuses for it.</summary>
    public IReadOnlyList<ViewerExportFormat> AvailableExportFormats
        => _isNodeReportRoot
            ? ExportFormats
            : ExportFormats.Where(f => f.Format != "json-report").ToList();

    public int SelectedFormatIndex
    {
        get => _selectedFormatIndex;
        set
        {
            int index = Math.Clamp(value, 0, AvailableExportFormats.Count - 1);
            if (Set(ref _selectedFormatIndex, index))
            {
                OnPropertyChanged(nameof(SelectedFormat));
            }
        }
    }

    public ViewerExportFormat SelectedFormat => AvailableExportFormats[_selectedFormatIndex];

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

    public string PageLabel => _pageCount == 0
        ? Localizer.Get("Viewer.PageZero")
        : Localizer.Format("Viewer.PageLabel", _currentPage, _pageCount);

    public bool CanGoPrevious => _pageCount > 0 && _currentPage > 1;
    public bool CanGoNext => _pageCount > 0 && _currentPage < _pageCount;

    public int RowCount { get => _rowCount; private set => Set(ref _rowCount, value); }

    /// <summary>A layout-less node's rows, or null when the node renders its HTML report. The
    /// ViewerView shows this as a grid and hides the HTML preview.</summary>
    public DataView? NodeRows { get => _nodeRows; private set => Set(ref _nodeRows, value); }

    /// <summary>True when the Viewer is showing the row grid for a layout-less node.</summary>
    public bool IsRowGrid { get => _isRowGrid; private set => Set(ref _isRowGrid, value); }

    /// <summary>The report HTML the preview shows — the engine's <c>html</c> export bytes.</summary>
    public string? PreviewHtml { get => _previewHtml; private set => Set(ref _previewHtml, value); }

    public string StatusText { get => _statusText; private set => Set(ref _statusText, value); }
    public ViewerStatusKind StatusKind { get => _statusKind; private set => Set(ref _statusKind, value); }

    /// <summary>True while an export runs. The status bar shows its indeterminate progress
    /// bar from this, and the other engine commands stay disabled because `serve` serialises
    /// every request behind the same gate.</summary>
    public bool IsExporting
    {
        get => _isExporting;
        private set
        {
            if (Set(ref _isExporting, value))
            {
                RaiseCommandsChanged();
            }
        }
    }

    /// <summary>Counts the engine's page boxes in an HTML facsimile.</summary>
    public static int CountPages(string html) => PageDiv.Matches(html).Count;

    /// <summary>Binds the view model to an open document. <paramref name="refresh"/> runs the
    /// document's live-data refresh (which calls back into <see cref="RenderAsync"/>) and
    /// answers whether it succeeded; <paramref name="setPaperSize"/> lets the document apply
    /// the paper through its own path (so the Designer's snapshot stays in step).</summary>
    public Task LoadAsync(int handle, long queryId, Func<Task<bool>> refresh, Func<int, Task>? setPaperSize = null)
    {
        _handle = handle;
        _queryId = queryId;
        _refresh = refresh;
        _setPaperSize = setPaperSize;

        SelectedPaperIndex = 0;
        SelectedFormatIndex = 0;
        RenderedPaperType = (int)PaperSize.Letter;
        PageCount = 0;
        CurrentPage = 0;
        RowCount = 0;
        PreviewHtml = null;
        SetNodeRows(null);
        SetStatus(NotYetRefreshedText, ViewerStatusKind.Neutral);

        OnPropertyChanged(nameof(HasDocument));
        RaiseCommandsChanged();
        return Task.CompletedTask;
    }

    /// <summary>Presents an already-produced HTML facsimile and its row count. Public so the
    /// render step and tests share the same path the engine export feeds.</summary>
    public void SetRenderedHtml(string html, int rowCount)
    {
        // Clear any row-grid state first, so the HTML preview's property change is not
        // suppressed by IsRowGrid still being true from a previously selected node.
        SetNodeRows(null);
        RowCount = rowCount;
        PreviewHtml = html;
        PageCount = CountPages(html);
        CurrentPage = PageCount > 0 ? 1 : 0;
        SetStatus(StatusMessage(PageCount, rowCount), ViewerStatusKind.Success);
    }

    /// <summary>Shows a layout-less node as a row grid: its columns and rows become a bound
    /// <see cref="DataView"/> and the HTML preview is hidden.</summary>
    public void SetNodeRows(NodeResult? node)
    {
        if (node == null)
        {
            NodeRows = null;
            IsRowGrid = false;
            return;
        }

        RowCount = node.RowCount;
        NodeRows = node.ToDataTable().DefaultView;
        IsRowGrid = true;
        PreviewHtml = null;
        PageCount = 0;
        CurrentPage = 0;
        SetStatus(Localizer.Format("Viewer.NodeRows", node.RowCount), ViewerStatusKind.Success);
    }

    /// <summary>Renders the selected node for the Viewer's paper: a node with elements renders
    /// its HTML report, and a layout-less node shows a row grid from its retained result.
    /// <paramref name="hasLayout"/> is the selected node's "has any element".</summary>
    public async Task RenderAsync(bool hasLayout)
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

            NodeResult node;
            try
            {
                node = await _engine.NodeResultAsync(_handle, _queryId);
            }
            catch (Exception)
            {
                // A node has no retained result until the document has been refreshed, and a
                // failed refresh leaves every node's previous result untouched. Say so plainly
                // rather than surfacing the transport error.
                RenderedPaperType = paper;
                PreviewHtml = null;
                SetNodeRows(null);
                PageCount = 0;
                CurrentPage = 0;
                SetStatus(Localizer.Get("Viewer.NodeNotRefreshed"), ViewerStatusKind.Neutral);
                return;
            }

            if (hasLayout)
            {
                string html = await _engine.ExportAsync(_handle, "html", _queryId);
                SetRenderedHtml(html, node.RowCount);
            }
            else
            {
                SetNodeRows(node);
            }
        }
        catch (Exception exception)
        {
            RenderedPaperType = paper;
            PreviewHtml = null;
            SetNodeRows(null);
            PageCount = 0;
            CurrentPage = 0;
            SetStatus(exception.Message, ViewerStatusKind.Error);
        }
    }

    /// <summary>Shows the in-flight status line while a refresh runs.</summary>
    public void BeginRefresh()
    {
        SetStatus(Localizer.Get("Viewer.BeginRefresh"), ViewerStatusKind.Neutral);
    }

    /// <summary>Reports a refresh failure on the status line.</summary>
    public void ReportRefreshFailed(string message)
    {
        SetStatus(message, ViewerStatusKind.Error);
    }

    /// <summary>Exports the rendered report in the selected format to <paramref name="outPath"/>.
    /// If nothing is rendered yet the report is refreshed first, as the Mac's Export does.
    /// PDF goes through the engine's path export so the binary bytes are never round-tripped
    /// through the serve protocol's UTF-8 <c>data</c> field; the text formats keep the read-back
    /// path. Progress is indeterminate on purpose: `serve` streams no export progress and the
    /// whole operation is one request.</summary>
    public async Task ExportAsync(string outPath)
    {
        if (!HasDocument) return;

        // Capture the selection before the first await: the selector stays usable while the
        // export runs, and re-reading it would let the file's extension, its bytes and the
        // success line disagree.
        ViewerExportFormat format = SelectedFormat;
        if (format.Format == "json-report" && !_isNodeReportRoot)
        {
            // The export list already hides it for a source; this is the direct-call guard,
            // which surfaces the reason instead of letting the engine's error bubble up.
            SetStatus(Localizer.Get("Viewer.JsonReportUnavailable"), ViewerStatusKind.Error);
            return;
        }
        string? stagedPath = null;
        bool targetExisted = File.Exists(outPath);
        bool succeeded = false;
        IsExporting = true;
        SetStatus(Localizer.Format("Viewer.Exporting", format.Format.ToUpperInvariant()), ViewerStatusKind.Neutral);
        try
        {
            if (_pageCount == 0 && _refresh != null && !await _refresh())
            {
                return; // the failed refresh already put its error on the status line
            }

            // The report may have been rendered before something else (the Designer's own
            // paper selector) changed the engine's layout. The Mac re-applies the rendered
            // paper before every export; so does this, so the file matches the preview.
            await ApplyRenderedPaperAsync();

            if (format.Format == "pdf")
            {
                // The engine writes the bytes itself. Stage beside the target and move on
                // success, so a failure can never delete a file the user already had.
                stagedPath = $"{outPath}.{Guid.NewGuid():N}.part";
                long bytes = await _engine.ExportToPathAsync(_handle, format.Format, stagedPath, _queryId);
                File.Move(stagedPath, outPath, overwrite: true);
                stagedPath = null;
                succeeded = true;
                SetStatus(Localizer.Format("Viewer.ExportStatusBytes",
                        format.Format.ToUpperInvariant(), Path.GetFileName(outPath),
                        bytes.ToString("N0")),
                    ViewerStatusKind.Success);
            }
            else
            {
                string data = await _engine.ExportAsync(_handle, format.Format, _queryId);
                await File.WriteAllTextAsync(outPath, data);
                succeeded = true;
                SetStatus(Localizer.Format("Viewer.ExportStatus",
                        format.Format.ToUpperInvariant(), Path.GetFileName(outPath)),
                    ViewerStatusKind.Success);
            }
        }
        catch (Exception exception)
        {
            // The engine may have left a partial file. Delete the staged PDF, or a text
            // file this export created; never a file that was already there before it.
            if (stagedPath != null)
            {
                TryDelete(stagedPath);
            }
            else if (!succeeded && !targetExisted)
            {
                TryDelete(outPath);
            }
            SetStatus(exception.Message, ViewerStatusKind.Error);
        }
        finally
        {
            IsExporting = false;
        }
    }

    private static void TryDelete(string path)
    {
        try
        {
            File.Delete(path);
        }
        catch (IOException)
        {
        }
        catch (UnauthorizedAccessException)
        {
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

    private Task RefreshCoreAsync() => _refresh?.Invoke() ?? Task.FromResult(false);

    /// <summary>Re-applies the paper the preview was rendered with. The engine's layout is
    /// shared with the Designer, whose paper selector writes it directly, so an export has to
    /// restore the Viewer's paper first (as the Mac's export panel does).</summary>
    private async Task ApplyRenderedPaperAsync()
    {
        if (_setPaperSize != null)
        {
            await _setPaperSize(RenderedPaperType);
        }
        else
        {
            await _engine.SetPaperSizeAsync(_handle, RenderedPaperType);
        }
    }

    private async Task PrintAsync()
    {
        if (!HasDocument) return;
        if (_pageCount == 0 && _refresh != null && !await _refresh())
        {
            return; // the failed refresh already put its error on the status line
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
