//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using Mad.Designer.Windows.Engine;
using Mad.Designer.Windows.Infrastructure;
using Mad.Designer.Windows.Models;

namespace Mad.Designer.Windows.ViewModels;

public enum QueryMode
{
    Designer,
    Sql,
}

/// <summary>A flattened query field for the filter/grouping editors' dropdowns.</summary>
public sealed record QueryFieldRef(long Id, string Display);

/// <summary>A display row for the filter editor's list.</summary>
public sealed record PredicateRow(long Id, string Display);

/// <summary>A display row for the grouping editor's list.</summary>
public sealed record GroupRow(long Id, string Display);

/// <summary>The MAD Query workspace's view model — the WPF counterpart of the Mac's
/// <c>MADMacQueryViewController</c>. It owns the query model snapshot, the two mutually
/// exclusive modes (visual designer vs. SQL editor), the join/filter/grouping mutations, and
/// the SQL validate/apply path. Every mutation round-trips through the engine and replaces
/// the snapshot atomically, so the generated SQL and the visual model always agree.</summary>
public sealed class QueryViewModel : ObservableObject
{
    private readonly EngineService _engine;
    private int _handle = -1;
    private long _queryId;
    private IReadOnlyList<SchemaTable> _schemaTables = Array.Empty<SchemaTable>();
    private QueryModel _model = new("", "", "", Array.Empty<QueryTable>(), Array.Empty<QueryLink>(), Array.Empty<QueryPredicate>(), Array.Empty<QueryGroup>(), 0, false);
    private IReadOnlyList<QueryTable> _orderedTables = Array.Empty<QueryTable>();
    private IReadOnlySet<long> _rootTableIds = new HashSet<long>();

    private QueryMode _mode = QueryMode.Designer;
    private long _selectedLinkId;
    private string _sqlEditorText = "";
    private string _statusText = "";
    private string? _errorText;
    private bool _isBusy;
    private double _zoom = 1.0;

    private QueryFieldRef? _selectedFilterField;
    private int _selectedFilterOperatorIndex;
    private string _filterValue = "";
    private QueryFieldRef? _selectedGroupField;
    private int _selectedGroupSortIndex;

    public QueryViewModel(EngineService engine)
    {
        _engine = engine ?? throw new ArgumentNullException(nameof(engine));

        SwitchToDesignerCommand = new RelayCommand(() => SwitchToMode(QueryMode.Designer));
        SwitchToSqlCommand = new RelayCommand(() => SwitchToMode(QueryMode.Sql));
        AddTableCommand = new AsyncRelayCommand<string?>(name => AddTableAsync(name!));
        RemoveTableCommand = new AsyncRelayCommand<long>(RemoveTableAsync);
        SetLinkTypeCommand = new AsyncRelayCommand<LinkSet>(set => SetLinkTypeAsync(set.LinkId, set.Type));
        SwapLinkCommand = new AsyncRelayCommand<long>(SwapLinkAsync);
        DeleteLinkCommand = new AsyncRelayCommand<long>(DeleteLinkAsync);
        AddPredicateCommand = new AsyncRelayCommand(AddPredicateAsync);
        RemovePredicateCommand = new AsyncRelayCommand<long>(RemovePredicateAsync);
        AddGroupCommand = new AsyncRelayCommand(AddGroupAsync);
        RemoveGroupCommand = new AsyncRelayCommand<long>(RemoveGroupAsync);
        ArrangeTablesCommand = new RelayCommand(ArrangeTables);
        RevertSqlCommand = new RelayCommand(RevertSql);
        ValidateSqlCommand = new AsyncRelayCommand(ValidateSqlAsync);
        CompileAndApplySqlCommand = new AsyncRelayCommand(CompileAndApplySqlAsync);
        ZoomInCommand = new RelayCommand(() => Zoom = _zoom * 1.2);
        ZoomOutCommand = new RelayCommand(() => Zoom = _zoom / 1.2);
        FitCommand = new RelayCommand(() => FitRequested?.Invoke());
    }

    public bool HasDocument => _handle >= 0;

    /// <summary>The queries the document offers, in authoring order.</summary>
    public void SetQueries(IReadOnlyList<QueryInfo> queries)
    {
        Queries = queries ?? Array.Empty<QueryInfo>();
        OnPropertyChanged(nameof(Queries));
    }

    /// <summary>The query this workspace edits (its store identifier). Selecting a
    /// different query reloads the model so every mutation applies to that query.</summary>
    public long QueryId
    {
        get => _queryId;
        set
        {
            if (Set(ref _queryId, value))
            {
                OnPropertyChanged(nameof(IsRoot));
                _ = ReloadAsync();
            }
        }
    }

    /// <summary>True when the selected query is the composed root (no schema tables to
    /// add; its inputs are the other queries).</summary>
    public bool IsRoot => _model.IsRoot;

    /// <summary>Every query in the document, for the query selector. Set by the
    /// document when it loads the document-info.</summary>
    public IReadOnlyList<QueryInfo> Queries { get; private set; } = Array.Empty<QueryInfo>();

    public QueryMode Mode
    {
        get => _mode;
        private set => Set(ref _mode, value);
    }

    public bool IsDesigner => Mode == QueryMode.Designer;
    public bool IsSql => Mode == QueryMode.Sql;

    /// <summary>Two-way bindings for the segmented mode switch. Clicking the active segment
    /// unchecks its ToggleButton; re-reading the source makes it check itself again instead of
    /// leaving both segments unselected.</summary>
    public bool DesignerSelected
    {
        get => _mode == QueryMode.Designer;
        set
        {
            if (value) SwitchToMode(QueryMode.Designer);
            else OnPropertyChanged(nameof(DesignerSelected));
        }
    }

    public bool SqlSelected
    {
        get => _mode == QueryMode.Sql;
        set
        {
            if (value) SwitchToMode(QueryMode.Sql);
            else OnPropertyChanged(nameof(SqlSelected));
        }
    }

    public string StatusText { get => _statusText; private set => Set(ref _statusText, value); }
    public string? ErrorText { get => _errorText; private set => Set(ref _errorText, value); }

    /// <summary>The visual canvas zoom. The query canvas scales itself with a layout transform,
    /// so the model coordinates and the pointer hit-testing stay in unscaled units.</summary>
    public double Zoom
    {
        get => _zoom;
        set
        {
            if (Set(ref _zoom, Math.Clamp(value, 0.4, 2.0)))
            {
                OnPropertyChanged(nameof(ZoomText));
            }
        }
    }

    public string ZoomText => $"{Math.Round(_zoom * 100.0)}%";

    public bool IsBusy
    {
        get => _isBusy;
        private set
        {
            if (Set(ref _isBusy, value)) RaiseCanExecuteChanged();
        }
    }

    /// <summary>The stored schema (the left-hand table list), from `describe`.</summary>
    public IReadOnlyList<SchemaTable> SchemaTables => _schemaTables;

    public QueryModel Model => _model;
    public string Sql => _model.Sql;
    public string SqlSourceText => _model.SqlSourceText;
    public string Driver => _model.Driver;
    public IReadOnlyList<QueryTable> Tables => _model.Tables;
    public IReadOnlyList<QueryLink> Links => _model.Links;
    public IReadOnlyList<QueryPredicate> Predicates => _model.Predicates;
    public IReadOnlyList<QueryGroup> Groups => _model.Groups;

    /// <summary>The tables in topological order (roots first), for canvas layout.</summary>
    public IReadOnlyList<QueryTable> OrderedTables => _orderedTables;

    /// <summary>The table ids that are join roots (not the right side of any link).</summary>
    public IReadOnlySet<long> RootTableIds => _rootTableIds;

    /// <summary>Every query field, flattened as "alias.field", for the editors' dropdowns.</summary>
    public IReadOnlyList<QueryFieldRef> AllFields => BuildAllFields();

    public long SelectedLinkId { get => _selectedLinkId; private set => Set(ref _selectedLinkId, value); }

    public string SqlEditorText { get => _sqlEditorText; set => Set(ref _sqlEditorText, value); }

    public QueryFieldRef? SelectedFilterField { get => _selectedFilterField; set => Set(ref _selectedFilterField, value); }
    public int SelectedFilterOperatorIndex { get => _selectedFilterOperatorIndex; set => Set(ref _selectedFilterOperatorIndex, value); }
    public string FilterValue { get => _filterValue; set => Set(ref _filterValue, value); }
    public QueryFieldRef? SelectedGroupField { get => _selectedGroupField; set => Set(ref _selectedGroupField, value); }
    public int SelectedGroupSortIndex { get => _selectedGroupSortIndex; set => Set(ref _selectedGroupSortIndex, value); }

    public IReadOnlyList<string> FilterOperatorSymbols { get; } = new[] { "=", "!=", "<", "<=", ">", ">=" };
    public IReadOnlyList<string> GroupSortLabels => new[]
    {
        Localizer.Get("Query.Sort.Ascending"),
        Localizer.Get("Query.Sort.Descending"),
    };

    public string FiltersLabel => _model.Predicates.Count > 0
        ? Localizer.Format("Query.Filters.Count", _model.Predicates.Count)
        : Localizer.Get("Query.Filters.None");
    public string GroupsLabel => _model.Groups.Count > 0
        ? Localizer.Format("Query.Groups.Count", _model.Groups.Count)
        : Localizer.Get("Query.Groups.None");

    public IReadOnlyList<PredicateRow> PredicateRows { get; private set; } = Array.Empty<PredicateRow>();
    public IReadOnlyList<GroupRow> GroupRows { get; private set; } = Array.Empty<GroupRow>();

    public RelayCommand SwitchToDesignerCommand { get; }
    public RelayCommand SwitchToSqlCommand { get; }
    public AsyncRelayCommand<string?> AddTableCommand { get; }
    public AsyncRelayCommand<long> RemoveTableCommand { get; }
    public AsyncRelayCommand<LinkSet> SetLinkTypeCommand { get; }
    public AsyncRelayCommand<long> SwapLinkCommand { get; }
    public AsyncRelayCommand<long> DeleteLinkCommand { get; }
    public AsyncRelayCommand AddPredicateCommand { get; }
    public AsyncRelayCommand<long> RemovePredicateCommand { get; }
    public AsyncRelayCommand AddGroupCommand { get; }
    public AsyncRelayCommand<long> RemoveGroupCommand { get; }
    public RelayCommand ArrangeTablesCommand { get; }
    public RelayCommand RevertSqlCommand { get; }
    public AsyncRelayCommand ValidateSqlCommand { get; }
    public AsyncRelayCommand CompileAndApplySqlCommand { get; }
    public RelayCommand ZoomInCommand { get; }
    public RelayCommand ZoomOutCommand { get; }
    public RelayCommand FitCommand { get; }

    /// <summary>Raised when "Arrange Tables" is clicked; the view re-lays the cards out.</summary>
    public event Action? ArrangeRequested;

    /// <summary>Raised when "Fit" is clicked; the view measures its viewport and sets
    /// <see cref="Zoom"/> through <see cref="FitToViewport"/>.</summary>
    public event Action? FitRequested;

    /// <summary>Chooses the zoom that shows the whole query canvas in the viewport.</summary>
    public void FitToViewport(double viewportWidth, double viewportHeight, double contentWidth, double contentHeight)
    {
        if (viewportWidth <= 0 || viewportHeight <= 0 || contentWidth <= 0 || contentHeight <= 0) return;
        const double margin = 32.0;
        Zoom = Math.Min((viewportWidth - margin) / contentWidth, (viewportHeight - margin) / contentHeight);
    }

    /// <summary>Populates the workspace after a document opens (or its connection changes).</summary>
    public async Task LoadAsync(int handle, string driver, IReadOnlyList<SchemaTable> schemaTables, long queryId)
    {
        _handle = handle;
        _schemaTables = schemaTables;
        _queryId = queryId;
        OnPropertyChanged(nameof(SchemaTables));
        OnPropertyChanged(nameof(HasDocument));
        _ = driver; // the model's driver token is authoritative; kept for symmetry

        await ReloadAsync();
    }

    /// <summary>Re-reads the query model from the engine.  Call after `apply-connection`, too.</summary>
    public async Task ReloadAsync()
    {
        if (!HasDocument) return;
        try
        {
            ApplyModel(await _engine.QueryModelAsync(_handle, _queryId));
            if (Mode == QueryMode.Designer)
            {
                SqlEditorText = string.IsNullOrEmpty(_model.SqlSourceText) ? _model.Sql : _model.SqlSourceText;
            }
        }
        catch (Exception exception)
        {
            ErrorText = exception.Message;
        }
    }

    public void SwitchToMode(QueryMode mode)
    {
        Mode = mode;
        OnPropertyChanged(nameof(IsDesigner));
        OnPropertyChanged(nameof(IsSql));
        OnPropertyChanged(nameof(DesignerSelected));
        OnPropertyChanged(nameof(SqlSelected));
        if (mode == QueryMode.Sql)
        {
            SqlEditorText = string.IsNullOrEmpty(_model.SqlSourceText) ? _model.Sql : _model.SqlSourceText;
        }
    }

    public void SelectLink(long? linkId)
    {
        SelectedLinkId = linkId ?? 0;
    }

    public async Task AddTableAsync(string tableName)
        => await MutateAsync(() => _engine.AddTableAsync(_handle, tableName, _queryId));

    public async Task RemoveTableAsync(long tableId)
        => await MutateAsync(() => _engine.RemoveTableAsync(_handle, tableId, _queryId));

    public async Task ConnectFieldsAsync(long leftField, long rightField)
        => await MutateAsync(() => _engine.AddLinkAsync(_handle, leftField, rightField, _queryId));

    public async Task SetLinkTypeAsync(long linkId, LinkType type)
        => await MutateAsync(() => _engine.SetLinkTypeAsync(_handle, linkId, (int)type, _queryId));

    public async Task SwapLinkAsync(long linkId)
        => await MutateAsync(() => _engine.SwapLinkAsync(_handle, linkId, _queryId));

    public async Task DeleteLinkAsync(long linkId)
        => await MutateAsync(() => _engine.DeleteLinkAsync(_handle, linkId, _queryId));

    public async Task AddPredicateAsync()
    {
        if (SelectedFilterField is not { } field || string.IsNullOrEmpty(FilterValue)) return;
        var op = (PredicateOperator)Math.Clamp(SelectedFilterOperatorIndex, 0, 5);
        await MutateAsync(() => _engine.AddPredicateAsync(_handle, field.Id, (int)op, FilterValue, _queryId));
        FilterValue = "";
    }

    public async Task RemovePredicateAsync(long predicateId)
        => await MutateAsync(() => _engine.RemovePredicateAsync(_handle, predicateId, _queryId));

    public async Task AddGroupAsync()
    {
        if (SelectedGroupField is not { } field) return;
        var sort = SelectedGroupSortIndex == 1 ? GroupSort.Descending : GroupSort.Ascending;
        await MutateAsync(() => _engine.AddGroupAsync(_handle, field.Id, (int)sort, _queryId));
    }

    public async Task RemoveGroupAsync(long groupId)
        => await MutateAsync(() => _engine.RemoveGroupAsync(_handle, groupId, _queryId));

    public void ArrangeTables() => ArrangeRequested?.Invoke();

    public void RevertSql() => SqlEditorText = _model.Sql;

    public async Task ValidateSqlAsync()
    {
        if (!HasDocument) return;
        IsBusy = true;
        ErrorText = null;
        try
        {
            var result = await _engine.ValidateSqlAsync(_handle, SqlEditorText);
            StatusText = Localizer.Format("Query.ValidSql",
                result.Tables, result.Links, result.Predicates, result.Groups);
        }
        catch (Exception exception)
        {
            StatusText = exception.Message;
        }
        finally
        {
            IsBusy = false;
        }
    }

    public async Task CompileAndApplySqlAsync()
    {
        if (!HasDocument) return;
        IsBusy = true;
        ErrorText = null;
        try
        {
            var result = await _engine.ApplySqlAsync(_handle, SqlEditorText);
            StatusText = Localizer.Format("Query.AppliedSql",
                result.Tables, result.Links, result.Predicates, result.Groups);
            await ReloadAsync();
        }
        catch (Exception exception)
        {
            StatusText = exception.Message;
        }
        finally
        {
            IsBusy = false;
        }
    }

    // ---- field-state queries (for the canvas indicators) ----

    public bool IsFieldLinked(long fieldId) => _model.Links.Any(l => l.LeftField == fieldId || l.RightField == fieldId);
    public bool IsFieldGrouped(long fieldId) => _model.Groups.Any(g => g.Field == fieldId);
    public bool IsFieldFiltered(long fieldId) => _model.Predicates.Any(p => p.LeftField == fieldId || p.RightField == fieldId);

    // ---- display helpers ----

    public string FieldDisplay(long fieldId)
    {
        if (_fieldToTable is null)
        {
            var map = new Dictionary<long, string>();
            foreach (var table in _model.Tables)
            {
                string alias = string.IsNullOrEmpty(table.Alias) ? table.Name : table.Alias;
                foreach (var field in table.Fields) map[field.Id] = $"{alias}.{field.Name}";
            }
            _fieldToTable = map;
        }
        return _fieldToTable.TryGetValue(fieldId, out var display) ? display : "";
    }

    public string PredicateDisplay(QueryPredicate p)
    {
        string lhs = p.LeftField != 0 ? FieldDisplay(p.LeftField) : p.LeftValue ?? "";
        string rhs = p.RightField != 0 ? FieldDisplay(p.RightField) : p.RightValue ?? "";
        return $"{lhs} {p.Operator.Symbol()} {rhs}";
    }

    public string GroupDisplay(QueryGroup g, int index)
    {
        string field = FieldDisplay(g.Field);
        string sort = g.Sort == GroupSort.Descending
            ? Localizer.Get("Query.Sort.Descending")
            : Localizer.Get("Query.Sort.Ascending");
        return $"{index + 1}. {field} ({sort})";
    }

    // ---- internals ----

    private Dictionary<long, string>? _fieldToTable;

    private async Task MutateAsync(Func<Task<QueryModel>> mutation)
    {
        if (!HasDocument) return;
        IsBusy = true;
        ErrorText = null;
        try
        {
            ApplyModel(await mutation());
        }
        catch (Exception exception)
        {
            ErrorText = exception.Message;
        }
        finally
        {
            IsBusy = false;
        }
    }

    private void ApplyModel(QueryModel model)
    {
        _model = model;
        _fieldToTable = null;

        var (ordered, roots) = ComputeTopologicalOrder();
        _orderedTables = ordered;
        _rootTableIds = roots;

        PredicateRows = _model.Predicates.Select(p => new PredicateRow(p.Id, PredicateDisplay(p))).ToList();
        GroupRows = _model.Groups.Select((g, i) => new GroupRow(g.Id, GroupDisplay(g, i))).ToList();

        OnPropertyChanged(nameof(Model));
        OnPropertyChanged(nameof(Sql));
        OnPropertyChanged(nameof(SqlSourceText));
        OnPropertyChanged(nameof(Driver));
        OnPropertyChanged(nameof(Tables));
        OnPropertyChanged(nameof(Links));
        OnPropertyChanged(nameof(Predicates));
        OnPropertyChanged(nameof(Groups));
        OnPropertyChanged(nameof(OrderedTables));
        OnPropertyChanged(nameof(RootTableIds));
        OnPropertyChanged(nameof(AllFields));
        OnPropertyChanged(nameof(FiltersLabel));
        OnPropertyChanged(nameof(GroupsLabel));
        OnPropertyChanged(nameof(PredicateRows));
        OnPropertyChanged(nameof(GroupRows));
    }

    private IReadOnlyList<QueryFieldRef> BuildAllFields()
    {
        var list = new List<QueryFieldRef>();
        foreach (var table in _model.Tables)
        {
            string alias = string.IsNullOrEmpty(table.Alias) ? table.Name : table.Alias;
            foreach (var field in table.Fields)
            {
                list.Add(new QueryFieldRef(field.Id, $"{alias}.{field.Name}"));
            }
        }
        return list;
    }

    private (List<QueryTable> ordered, HashSet<long> roots) ComputeTopologicalOrder()
    {
        var byId = _model.Tables.ToDictionary(t => t.Id);
        var fieldToTable = new Dictionary<long, long>();
        foreach (var table in _model.Tables)
            foreach (var field in table.Fields)
                fieldToTable[field.Id] = table.Id;

        var adjacency = _model.Tables.ToDictionary(t => t.Id, _ => new List<long>());
        var indegree = _model.Tables.ToDictionary(t => t.Id, _ => 0);
        foreach (var link in _model.Links)
        {
            if (!fieldToTable.TryGetValue(link.LeftField, out var left) || !fieldToTable.TryGetValue(link.RightField, out var right)) continue;
            if (left == right) continue;
            if (!adjacency[left].Contains(right))
            {
                adjacency[left].Add(right);
                indegree[right]++;
            }
        }

        var roots = new HashSet<long>(_model.Tables.Where(t => indegree[t.Id] == 0).Select(t => t.Id));
        if (roots.Count == 0 && _model.Tables.Count > 0) roots.Add(_model.Tables[0].Id);

        var ordered = new List<QueryTable>();
        var queue = new Queue<long>(indegree.Where(kv => kv.Value == 0).OrderBy(kv => kv.Key).Select(kv => kv.Key));
        var visited = new HashSet<long>();
        while (queue.Count > 0)
        {
            long id = queue.Dequeue();
            if (!visited.Add(id)) continue;
            if (byId.TryGetValue(id, out var table)) ordered.Add(table);
            foreach (long next in adjacency[id].OrderBy(x => x))
            {
                if (--indegree[next] == 0) queue.Enqueue(next);
            }
        }
        foreach (var table in _model.Tables)
            if (!visited.Contains(table.Id)) ordered.Add(table);

        return (ordered, roots);
    }

    private void RaiseCanExecuteChanged()
    {
        AddTableCommand.RaiseCanExecuteChanged();
        RemoveTableCommand.RaiseCanExecuteChanged();
        SetLinkTypeCommand.RaiseCanExecuteChanged();
        SwapLinkCommand.RaiseCanExecuteChanged();
        DeleteLinkCommand.RaiseCanExecuteChanged();
        AddPredicateCommand.RaiseCanExecuteChanged();
        RemovePredicateCommand.RaiseCanExecuteChanged();
        AddGroupCommand.RaiseCanExecuteChanged();
        RemoveGroupCommand.RaiseCanExecuteChanged();
        ValidateSqlCommand.RaiseCanExecuteChanged();
        CompileAndApplySqlCommand.RaiseCanExecuteChanged();
    }
}

/// <summary>The (link, join type) pair for the link-type editor.</summary>
public readonly record struct LinkSet(long LinkId, LinkType Type);
