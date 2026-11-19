//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using System.Data;
using System.IO;
using Mad.Designer.Windows.Engine;
using Mad.Designer.Windows.Infrastructure;
using Mad.Designer.Windows.Models;

namespace Mad.Designer.Windows.ViewModels;

/// <summary>The shared state of one opened .mad document — the WPF counterpart of the Mac
/// app's <c>MADMacDocument</c>. Open populates the schema and generated SQL; Refresh runs the
/// query and loads the rows for the viewer grid; Export writes CSV or JSON. Every engine call
/// is async and marshals off the UI thread, and every failure lands in <see cref="ErrorText"/>
/// rather than crashing.</summary>
public sealed class DocumentViewModel : ObservableObject
{
    private readonly EngineService _engine;
    private readonly Func<string, string?>? _exportPath;
    private int _handle = -1;

    private bool _isBusy;
    private string _statusText = "";
    private string? _errorText;
    private string _driver = "";
    private string _fileName = "";
    private string _sql = "";
    private IReadOnlyList<ReportColumn> _columns = Array.Empty<ReportColumn>();
    private IReadOnlyList<SchemaTable> _tables = Array.Empty<SchemaTable>();
    private int _rowCount;
    private DataView? _dataView;

    public DocumentViewModel(EngineService engine, Func<string, string?>? exportPath = null)
    {
        _engine = engine ?? throw new ArgumentNullException(nameof(engine));
        _exportPath = exportPath;
        RefreshCommand = new AsyncRelayCommand(RefreshAsync, () => HasDocument);
        ExportCsvCommand = new AsyncRelayCommand(() => ExportAsync("csv"), () => HasDocument);
        ExportJsonCommand = new AsyncRelayCommand(() => ExportAsync("json"), () => HasDocument);
    }

    /// <summary>Records a failure that happened before a document could be opened (for
    /// example, resolving the default fixture). Kept separate from <see cref="OpenAsync"/>
    /// because that method only catches engine errors once a path is known.</summary>
    public void ReportFailure(string message)
    {
        ErrorText = message;
        StatusText = "Open failed.";
    }

    public bool IsBusy
    {
        get => _isBusy;
        private set
        {
            if (Set(ref _isBusy, value))
            {
                RaiseCanExecuteChanged();
            }
        }
    }

    public string StatusText { get => _statusText; private set => Set(ref _statusText, value); }
    public string? ErrorText { get => _errorText; private set => Set(ref _errorText, value); }
    public string Driver { get => _driver; private set => Set(ref _driver, value); }
    public string FileName { get => _fileName; private set => Set(ref _fileName, value); }
    public string Sql { get => _sql; private set => Set(ref _sql, value); }
    public IReadOnlyList<ReportColumn> Columns { get => _columns; private set => Set(ref _columns, value); }
    public IReadOnlyList<SchemaTable> Tables { get => _tables; private set => Set(ref _tables, value); }
    public int RowCount { get => _rowCount; private set => Set(ref _rowCount, value); }
    public DataView? DataView { get => _dataView; private set => Set(ref _dataView, value); }

    public bool HasDocument => _handle >= 0;

    public AsyncRelayCommand RefreshCommand { get; }
    public AsyncRelayCommand ExportCsvCommand { get; }
    public AsyncRelayCommand ExportJsonCommand { get; }

    public async Task OpenAsync(string path)
    {
        IsBusy = true;
        ErrorText = null;
        try
        {
            var open = await _engine.OpenAsync(path);
            _handle = open.Handle;
            FileName = open.Filename;
            OnPropertyChanged(nameof(HasDocument));

            var describe = await _engine.DescribeAsync(_handle);
            Driver = describe.Driver;
            Columns = describe.Columns;
            Tables = describe.Tables;

            Sql = await _engine.QueryAsync(_handle);

            DataView = null;
            RowCount = 0;
            StatusText = $"Opened {FileName}";
        }
        catch (Exception exception)
        {
            ErrorText = exception.Message;
            StatusText = "Open failed.";
        }
        finally
        {
            IsBusy = false;
        }
    }

    public async Task RefreshAsync()
    {
        if (!HasDocument) return;

        IsBusy = true;
        ErrorText = null;
        try
        {
            var refresh = await _engine.RefreshAsync(_handle);
            RowCount = refresh.RowCount;

            string json = await _engine.ExportAsync(_handle, "json");
            DataView = MadReport.Parse(json).ToDataTable().DefaultView;

            StatusText = $"Rendered {refresh.RowCount} cached rows";
        }
        catch (Exception exception)
        {
            ErrorText = exception.Message;
            StatusText = "Refresh failed.";
        }
        finally
        {
            IsBusy = false;
        }
    }

    /// <summary>Exports the current report to the destination chosen by the injected path
    /// provider (a save dialog in the app), or a temp file when no provider is set.</summary>
    public async Task ExportAsync(string format)
    {
        string? outPath = _exportPath?.Invoke(format);
        if (string.IsNullOrEmpty(outPath))
        {
            outPath = Path.Combine(Path.GetTempPath(), $"mad-export-{Guid.NewGuid():N}.{format}");
        }
        await ExportAsync(format, outPath);
    }

    public async Task ExportAsync(string format, string outPath)
    {
        if (!HasDocument) return;

        IsBusy = true;
        ErrorText = null;
        try
        {
            string data = await _engine.ExportAsync(_handle, format);
            await File.WriteAllTextAsync(outPath, data);
            StatusText = $"Exported {format.ToUpperInvariant()} to {outPath}";
        }
        catch (Exception exception)
        {
            ErrorText = exception.Message;
            StatusText = "Export failed.";
        }
        finally
        {
            IsBusy = false;
        }
    }

    private void RaiseCanExecuteChanged()
    {
        RefreshCommand.RaiseCanExecuteChanged();
        ExportCsvCommand.RaiseCanExecuteChanged();
        ExportJsonCommand.RaiseCanExecuteChanged();
    }
}
