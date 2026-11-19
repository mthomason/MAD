//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using System.Data;
using System.IO;
using Mad.Designer.Windows.Engine;
using Mad.Designer.Windows.Infrastructure;
using Mad.Designer.Windows.Models;

namespace Mad.Designer.Windows.ViewModels;

/// <summary>The shared state of one opened .mad document — the WPF counterpart of the Mac
/// app's <c>MADMacDocument</c>. Open populates the schema and generated SQL; Refresh runs the
/// query and loads the rows for the viewer grid; Export writes CSV or JSON; Save/Save As
/// write the document back through the engine's `write`; ApplyConnection reconnects it. Every
/// engine call is async and marshals off the UI thread, and every failure lands in
/// <see cref="ErrorText"/> rather than crashing.</summary>
public sealed class DocumentViewModel : ObservableObject
{
    private readonly EngineService _engine;
    private readonly Func<string, string?>? _exportPath;
    private readonly Func<string?>? _saveAsPath;
    private readonly ICredentialStore? _credentials;
    private int _handle = -1;
    private string? _filePath;
    private ConnectionSpec? _connection;

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

    public DocumentViewModel(EngineService engine, Func<string, string?>? exportPath = null, Func<string?>? saveAsPath = null, ICredentialStore? credentials = null)
    {
        _engine = engine ?? throw new ArgumentNullException(nameof(engine));
        _exportPath = exportPath;
        _saveAsPath = saveAsPath;
        _credentials = credentials;
        RefreshCommand = new AsyncRelayCommand(RefreshAsync, () => HasDocument);
        ExportCsvCommand = new AsyncRelayCommand(() => ExportAsync("csv"), () => HasDocument);
        ExportJsonCommand = new AsyncRelayCommand(() => ExportAsync("json"), () => HasDocument);
        SaveCommand = new AsyncRelayCommand(SaveAsync, () => HasDocument);
        SaveAsCommand = new AsyncRelayCommand(SaveAsAsync, () => HasDocument);
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

    /// <summary>The document's on-disk path (the file it was opened from, created at, or
    /// last saved to). Null until a document is open.</summary>
    public string? FilePath { get => _filePath; private set => Set(ref _filePath, value); }

    public bool HasDocument => _handle >= 0;

    public AsyncRelayCommand RefreshCommand { get; }
    public AsyncRelayCommand ExportCsvCommand { get; }
    public AsyncRelayCommand ExportJsonCommand { get; }
    public AsyncRelayCommand SaveCommand { get; }
    public AsyncRelayCommand SaveAsCommand { get; }

    public async Task OpenAsync(string path)
    {
        IsBusy = true;
        ErrorText = null;
        try
        {
            var open = await _engine.OpenAsync(path);
            await LoadAsync(open, path);
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

    /// <summary>Adopts an already-created document (from `create`) without re-opening it.</summary>
    public async Task AdoptAsync(OpenResult open, string path)
    {
        IsBusy = true;
        ErrorText = null;
        try
        {
            await LoadAsync(open, path);
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

    private async Task LoadAsync(OpenResult open, string path)
    {
        _handle = open.Handle;
        FileName = open.Filename;
        FilePath = path;
        OnPropertyChanged(nameof(HasDocument));

        var describe = await _engine.DescribeAsync(_handle);
        Driver = describe.Driver;
        Columns = describe.Columns;
        Tables = describe.Tables;

        Sql = await _engine.QueryAsync(_handle);
        _connection = await _engine.ConnectionAsync(_handle);

        DataView = null;
        RowCount = 0;
        StatusText = $"Opened {FileName}";
    }

    public async Task RefreshAsync()
    {
        if (!HasDocument) return;

        IsBusy = true;
        ErrorText = null;
        try
        {
            var refresh = await _engine.RefreshAsync(_handle, credentials: ResolveCredentials(_connection, _credentials));
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

    public async Task SaveAsync()
    {
        if (!HasDocument)
        {
            ErrorText = "No document is open.";
            StatusText = "Save failed.";
            return;
        }
        if (string.IsNullOrEmpty(FilePath))
        {
            ErrorText = "This document has no file to save to.";
            StatusText = "Save failed.";
            return;
        }

        IsBusy = true;
        ErrorText = null;
        try
        {
            await _engine.WriteAsync(_handle, FilePath!);
            StatusText = $"Saved {FilePath}";
        }
        catch (Exception exception)
        {
            ErrorText = exception.Message;
            StatusText = "Save failed.";
        }
        finally
        {
            IsBusy = false;
        }
    }

    public async Task SaveAsAsync()
    {
        string? path = _saveAsPath?.Invoke();
        if (string.IsNullOrEmpty(path))
        {
            return; // the user cancelled the dialog
        }
        await SaveAsAsync(path);
    }

    public async Task SaveAsAsync(string path)
    {
        if (!HasDocument) return;

        IsBusy = true;
        ErrorText = null;
        try
        {
            await _engine.WriteAsync(_handle, path);
            FilePath = path;
            StatusText = $"Saved {path}";
        }
        catch (Exception exception)
        {
            ErrorText = exception.Message;
            StatusText = "Save failed.";
        }
        finally
        {
            IsBusy = false;
        }
    }

    public async Task ApplyConnectionAsync(ConnectionSpec spec)
    {
        if (!HasDocument) return;

        IsBusy = true;
        ErrorText = null;
        try
        {
            await _engine.ApplyConnectionAsync(_handle, spec);
            _connection = spec;
            await RefreshAsync();
        }
        catch (Exception exception)
        {
            ErrorText = exception.Message;
            StatusText = "Reconnect failed.";
        }
        finally
        {
            IsBusy = false;
        }
    }

    public async Task<ConnectionSpec?> GetConnectionAsync()
    {
        if (!HasDocument) return null;
        return await _engine.ConnectionAsync(_handle);
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

    /// <summary>Resolves the <c>user:password</c> string to pass to <c>refresh</c>, from the
    /// active connection's own username/password or from the Credential Manager store.
    /// Answers null for SQLite (no credentials) or when nothing is known.</summary>
    public static string? ResolveCredentials(ConnectionSpec? connection, ICredentialStore? store)
    {
        if (connection == null || connection.CredentialKey == null) return null;

        string user = connection.Username ?? "";
        string pass = connection.Password ?? "";
        if ((string.IsNullOrEmpty(user) || string.IsNullOrEmpty(pass)) &&
            store != null && store.TryRead(connection.CredentialKey, out string savedUser, out string savedPass))
        {
            user = savedUser;
            pass = savedPass;
        }

        if (string.IsNullOrEmpty(user) && string.IsNullOrEmpty(pass)) return null;
        return $"{user}:{pass}";
    }

    private void RaiseCanExecuteChanged()
    {
        RefreshCommand.RaiseCanExecuteChanged();
        ExportCsvCommand.RaiseCanExecuteChanged();
        ExportJsonCommand.RaiseCanExecuteChanged();
        SaveCommand.RaiseCanExecuteChanged();
        SaveAsCommand.RaiseCanExecuteChanged();
    }
}
