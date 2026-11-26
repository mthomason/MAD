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
    private bool _isComposed;
    private IReadOnlyList<QueryInfo> _queries = Array.Empty<QueryInfo>();
    private IReadOnlyList<QueryOption> _componentOptions = Array.Empty<QueryOption>();
    private long _selectedQueryId;

    private bool _isBusy;
    private string _statusText = "";
    private string? _errorText;
    private string? _queryError;
    private string? _designerError;
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
        RefreshCommand = new AsyncRelayCommand(async () => { await RefreshAsync(); }, () => HasDocument);
        ExportCsvCommand = new AsyncRelayCommand(() => ExportAsync("csv"), () => HasDocument);
        ExportJsonCommand = new AsyncRelayCommand(() => ExportAsync("json"), () => HasDocument);
        SaveCommand = new AsyncRelayCommand(SaveAsync, () => HasDocument);
        SaveAsCommand = new AsyncRelayCommand(SaveAsAsync, () => HasDocument);
        Query = new QueryViewModel(engine);
        Designer = new DesignerViewModel(engine);
        Viewer = new ViewerViewModel(engine, exportPath);
        Composition = new CompositionViewModel();
        Composition.NodeSelected += queryId => _ = SelectQueryAsync(queryId);
        Viewer.PropertyChanged += (_, args) =>
        {
            if (args.PropertyName == nameof(ViewerViewModel.IsExporting))
            {
                OnPropertyChanged(nameof(IsBusyOrExporting));
            }
        };

        // Unify feedback: a failed Query or Designer mutation is surfaced on the document
        // toolbar, the one place that stays visible in every workspace, so it is never missed
        // behind a workspace status line. A workspace clears the toolbar error only when it was
        // the one that set it, so a successful edit never hides an unrelated document failure.
        Query.PropertyChanged += (_, args) =>
        {
            if (args.PropertyName == nameof(QueryViewModel.ErrorText)) ForwardWorkspaceError(Query.ErrorText, ref _queryError);
            // The selected query reloads after every edit; keep its graph edges current so an
            // added upstream table appears in the Composition pane without reopening the file.
            if (args.PropertyName == nameof(QueryViewModel.Model) && Query.HasDocument)
            {
                Composition.UpdateModel(Query.QueryId, Query.Model);
            }
        };
        Designer.PropertyChanged += (_, args) =>
        {
            if (args.PropertyName == nameof(DesignerViewModel.ErrorText)) ForwardWorkspaceError(Designer.ErrorText, ref _designerError);
        };
    }

    /// <summary>The Query workspace's view model — the visual query designer and SQL editor.</summary>
    public QueryViewModel Query { get; }

    /// <summary>The Designer workspace's view model — the report-layout studio.</summary>
    public DesignerViewModel Designer { get; }

    /// <summary>The Viewer workspace's view model — the rendered report, page size, navigation,
    /// and export.</summary>
    public ViewerViewModel Viewer { get; }

    /// <summary>The document-level composition graph and selection, shared by the Composition
    /// pane, the Component picker, and the Query workspace. Empty for a Standard Report.</summary>
    public CompositionViewModel Composition { get; }

    /// <summary>Records a failure that happened before a document could be opened (for
    /// example, resolving the default fixture). Kept separate from <see cref="OpenAsync"/>
    /// because that method only catches engine errors once a path is known.</summary>
    public void ReportFailure(string message)
    {
        ErrorText = message;
        StatusText = Localizer.Get("Document.OpenFailed");
    }

    /// <summary>Mirrors a workspace error to the document toolbar. A workspace that clears its
    /// own error clears the toolbar only when it set that same text, so a successful edit never
    /// erases an unrelated document failure.</summary>
    private void ForwardWorkspaceError(string? text, ref string? remembered)
    {
        if (!string.IsNullOrEmpty(text))
        {
            remembered = text;
            ErrorText = text;
        }
        else if (remembered != null && ErrorText == remembered)
        {
            remembered = null;
            ErrorText = null;
        }
    }

    public bool IsBusy
    {
        get => _isBusy;
        private set
        {
            if (Set(ref _isBusy, value))
            {
                OnPropertyChanged(nameof(IsBusyOrExporting));
                RaiseCanExecuteChanged();
            }
        }
    }

    /// <summary>The Viewer's status-bar progress: a document operation (open, refresh, save)
    /// or a Viewer export is in flight. They share one indeterminate bar; the export's own
    /// state lives on <see cref="ViewerViewModel.IsExporting"/>.</summary>
    public bool IsBusyOrExporting => _isBusy || Viewer.IsExporting;

    public string StatusText { get => _statusText; private set => Set(ref _statusText, value); }

    public string? ErrorText
    {
        get => _errorText;
        private set
        {
            if (Set(ref _errorText, value)) OnPropertyChanged(nameof(HasError));
        }
    }

    public bool HasError => !string.IsNullOrEmpty(_errorText);
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

    /// <summary>True when the document is a Composition Report (it has an explicit root),
    /// false for a Standard Report.</summary>
    public bool IsComposed { get => _isComposed; private set => Set(ref _isComposed, value); }

    /// <summary>Every query in the document, the composed root first, then each source.</summary>
    public IReadOnlyList<QueryInfo> Queries { get => _queries; private set => Set(ref _queries, value); }

    /// <summary>The query the Query workspace edits. Distinct from <see cref="IsComposed"/>,
    /// so a user editing a child query still sees the document's type clearly.</summary>
    public long SelectedQueryId
    {
        get => _selectedQueryId;
        set
        {
            if (Set(ref _selectedQueryId, value))
            {
                Query.QueryId = value;
                Composition.SetSelected(value);
                OnPropertyChanged(nameof(SelectedQueryName));
                OnPropertyChanged(nameof(IsRootSelected));
                OnPropertyChanged(nameof(SelectedQueryHint));
            }
        }
    }

    public string? SelectedQueryName
        => _queries.FirstOrDefault(q => q.Id == _selectedQueryId)?.Name;

    /// <summary>True when the selected query is the composition's root (always true for a
    /// Standard Report's single query).</summary>
    public bool IsRootSelected
        => !IsComposed || (_queries.FirstOrDefault(q => q.Id == _selectedQueryId)?.IsRoot ?? false);

    /// <summary>The Component picker's choices: the root is marked Result so its special role
    /// stays visible when the graph is collapsed.</summary>
    public IReadOnlyList<QueryOption> ComponentOptions
    {
        get => _componentOptions;
        private set => Set(ref _componentOptions, value);
    }

    /// <summary>A one-line explanation of the selected report part, shown beside the Component
    /// picker. Empty for a Standard Report.</summary>
    public string SelectedQueryHint
        => !IsComposed
            ? ""
            : IsRootSelected
                ? Localizer.Get("Composition.Role.Result")
                : Localizer.Get("Composition.Role.Source");

    /// <summary>The localized document type, shown across the workspaces.</summary>
    public string DocumentTypeText
        => IsComposed ? Localizer.Get("Document.TypeComposition") : Localizer.Get("Document.TypeStandard");

    /// <summary>The localized tooltip for the document-type badge: a description of the type
    /// currently shown, never an instruction.</summary>
    public string DocumentTypeTooltip
        => IsComposed ? Localizer.Get("Document.TypeComposition.Tooltip") : Localizer.Get("Document.TypeStandard.Tooltip");

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
            StatusText = Localizer.Get("Document.OpenFailed");
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
            StatusText = Localizer.Get("Document.OpenFailed");
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
        Composition.Collapse();
        OnPropertyChanged(nameof(HasDocument));

        var describe = await _engine.DescribeAsync(_handle);
        Driver = describe.Driver;
        Columns = describe.Columns;
        Tables = describe.Tables;

        Sql = await _engine.QueryAsync(_handle);
        // A newly created composition has a root and no source database yet; the connection
        // endpoint reports that as an error. It is the expected state for an empty
        // composition, not a failure to open the document.
        _connection = null;
        try
        {
            _connection = await _engine.ConnectionAsync(_handle);
        }
        catch (Mad.Client.MadEngineException)
        {
            // No source database; sources are imported into the graph instead.
        }
        DocumentInfo info = await _engine.DocumentInfoAsync(_handle);
        ApplyDocumentInfo(info);
        await LoadCompositionAsync(info);
        long selected = info.Composed ? info.RootQuery : (info.Queries.FirstOrDefault()?.Id ?? 0);
        await Query.LoadAsync(_handle, describe.Driver, describe.Tables, selected);
        SelectedQueryId = selected;
        await Designer.LoadAsync(_handle);
        await Viewer.LoadAsync(_handle, RefreshAsync, ApplyPaperSizeAsync);

        DataView = null;
        RowCount = 0;
        StatusText = Localizer.Format("Document.Opened", FileName);
    }

    /// <summary>Runs the query, refreshes the rows and renders the Viewer's preview. Answers
    /// whether the refresh succeeded, so Export/Print can stop instead of exporting stale data
    /// over a red status line.</summary>
    public async Task<bool> RefreshAsync()
    {
        if (!HasDocument) return false;

        IsBusy = true;
        ErrorText = null;
        Viewer.BeginRefresh();
        try
        {
            var refresh = await _engine.RefreshAsync(_handle, credentials: ResolveCredentials(_connection, _credentials));
            RowCount = refresh.RowCount;

            string json = await _engine.ExportAsync(_handle, "json");
            DataView = MadReport.Parse(json).ToDataTable().DefaultView;

            // Phase 6d: lay the report out for the Viewer's selected paper and load its
            // HTML preview. Failures land on the Viewer's status line, not here.
            await Viewer.RenderAsync(refresh.RowCount);

            StatusText = Localizer.Format("Document.RenderedRows", refresh.RowCount);
            return true;
        }
        catch (Exception exception)
        {
            ErrorText = exception.Message;
            StatusText = Localizer.Get("Document.RefreshFailed");
            Viewer.ReportRefreshFailed(exception.Message);
            return false;
        }
        finally
        {
            IsBusy = false;
        }
    }

    /// <summary>Applies a paper size through the document so the Designer's snapshot follows.</summary>
    private async Task ApplyPaperSizeAsync(int paperSize)
    {
        await _engine.SetPaperSizeAsync(_handle, paperSize);
        await Designer.ReloadAsync();
    }

    /// <summary>Re-reads the document's type and query list after a composition mutation.</summary>
    private async Task<DocumentInfo> ReloadDocumentInfoAsync()
    {
        DocumentInfo info = await _engine.DocumentInfoAsync(_handle);
        ApplyDocumentInfo(info);
        await LoadCompositionAsync(info);
        return info;
    }

    /// <summary>Publishes one document-info snapshot to the views that depend on it.</summary>
    private void ApplyDocumentInfo(DocumentInfo info)
    {
        IsComposed = info.Composed;
        Queries = info.Queries;
        Query.SetQueries(info.Queries);
        ComponentOptions = BuildComponentOptions(info.Queries);
        Designer.IsComposition = info.Composed;
        OnPropertyChanged(nameof(DocumentTypeText));
        OnPropertyChanged(nameof(DocumentTypeTooltip));
        OnPropertyChanged(nameof(IsRootSelected));
        OnPropertyChanged(nameof(SelectedQueryHint));
    }

    private static IReadOnlyList<QueryOption> BuildComponentOptions(IReadOnlyList<QueryInfo> queries)
        => queries
            .Select(q => new QueryOption(q.Id, q.IsRoot
                ? Localizer.Format("Composition.Component.Root", q.Name)
                : q.Name))
            .ToList();

    /// <summary>Snapshots every query's own model so the Composition pane can draw the true
    /// dependency graph (a child is known from its parent's upstream tables). A query whose
    /// model cannot be read still appears as a node; it simply has no visible edge.</summary>
    private async Task LoadCompositionAsync(DocumentInfo info)
    {
        var models = new Dictionary<long, QueryModel>();
        if (info.Composed)
        {
            foreach (QueryInfo query in info.Queries)
            {
                try
                {
                    models[query.Id] = await _engine.QueryModelAsync(_handle, query.Id);
                }
                catch
                {
                    // The pane still lists the node; a failed model only loses its edges.
                }
            }
        }
        Composition.Load(info, models);
    }

    public async Task SelectQueryAsync(long queryId)
    {
        if (!HasDocument) return;
        SelectedQueryId = queryId;
    }

    /// <summary>Converts this standard report into a one-child composition.</summary>
    public async Task ConvertToCompositionAsync(string? childName = null)
    {
        if (!HasDocument) return;
        IsBusy = true;
        ErrorText = null;
        try
        {
            var info = await _engine.ConvertAsync(_handle, childName);
            DocumentInfo reloaded = await ReloadDocumentInfoAsync();
            SelectedQueryId = reloaded.RootQuery;
            await Query.ReloadAsync();
            await Designer.ReloadAsync();
            StatusText = Localizer.Get("Document.Converted");
            _ = info;
        }
        catch (Exception exception)
        {
            ErrorText = exception.Message;
            StatusText = Localizer.Get("Document.ConvertFailed");
        }
        finally { IsBusy = false; }
    }

    /// <summary>Imports the query graph of another .mad as a child of the composed root.</summary>
    public async Task ImportChildAsync(string path, string? name = null)
    {
        if (!HasDocument) return;
        IsBusy = true;
        ErrorText = null;
        try
        {
            var info = await _engine.ImportChildAsync(_handle, path, name);
            await ReloadDocumentInfoAsync();
            SelectedQueryId = info.RootQuery;
            await Designer.ReloadAsync();
            StatusText = Localizer.Get("Document.Imported");
        }
        catch (Exception exception)
        {
            ErrorText = exception.Message;
            StatusText = Localizer.Get("Document.ImportFailed");
        }
        finally { IsBusy = false; }
    }

    /// <summary>Adds a source query from a live connection (the connection sheet's
    /// source-picker mode).</summary>
    public async Task AddSourceAsync(string name, ConnectionSpec spec)
    {
        if (!HasDocument) return;
        IsBusy = true;
        ErrorText = null;
        try
        {
            await _engine.AddSourceAsync(_handle, name, spec);
            await ReloadDocumentInfoAsync();
            await Designer.ReloadAsync();
            StatusText = Localizer.Get("Document.SourceAdded");
        }
        catch (Exception exception)
        {
            ErrorText = exception.Message;
            StatusText = Localizer.Get("Document.SourceAddFailed");
        }
        finally { IsBusy = false; }
    }

    public async Task SaveAsync()
    {
        if (!HasDocument)
        {
            ErrorText = Localizer.Get("Document.NoDocument");
            StatusText = Localizer.Get("Document.SaveFailed");
            return;
        }
        if (string.IsNullOrEmpty(FilePath))
        {
            ErrorText = Localizer.Get("Document.NoFile");
            StatusText = Localizer.Get("Document.SaveFailed");
            return;
        }

        IsBusy = true;
        ErrorText = null;
        try
        {
            await _engine.WriteAsync(_handle, FilePath!);
            StatusText = Localizer.Format("Document.Saved", FilePath);
        }
        catch (Exception exception)
        {
            ErrorText = exception.Message;
            StatusText = Localizer.Get("Document.SaveFailed");
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
            StatusText = Localizer.Format("Document.Saved", path);
        }
        catch (Exception exception)
        {
            ErrorText = exception.Message;
            StatusText = Localizer.Get("Document.SaveFailed");
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

            // Phase 6b: re-read the schema and query model so the Query workspace is not stale.
            var describe = await _engine.DescribeAsync(_handle);
            Driver = describe.Driver;
            Columns = describe.Columns;
            Tables = describe.Tables;
            await Query.LoadAsync(_handle, describe.Driver, describe.Tables, SelectedQueryId);
            await Designer.LoadAsync(_handle);

            await RefreshAsync();
        }
        catch (Exception exception)
        {
            ErrorText = exception.Message;
            StatusText = Localizer.Get("Document.ReconnectFailed");
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
            StatusText = Localizer.Format("Document.Exported", format.ToUpperInvariant(), outPath);
        }
        catch (Exception exception)
        {
            ErrorText = exception.Message;
            StatusText = Localizer.Get("Document.ExportFailed");
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

/// <summary>One choice in the Component picker. The root's display carries its "Result" role;
/// a source uses its name alone.</summary>
public sealed record QueryOption(long Id, string Display);
