//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using Mad.Designer.Windows.Infrastructure;
using Mad.Designer.Windows.Models;

namespace Mad.Designer.Windows.ViewModels;

/// <summary>One card in the composition graph: a query the document contains. The root is the
/// report the user designs and views; every other node is a source that feeds it directly or
/// through another composing node. <see cref="IsComposing"/> is true for the root and for any
/// node built from other nodes, so the Designer's field caption can be set synchronously from
/// the selection without waiting on the async query-model reload.</summary>
public sealed record CompositionNode(long Id, string Name, bool IsRoot, int Depth, bool IsComposing);

/// <summary>One composition dependency. The arrow points at the consumer: <see cref="FromId"/>
/// feeds <see cref="ToId"/>.</summary>
public sealed record CompositionEdge(long FromId, long ToId);

/// <summary>Builds the composition graph from the document's query list and each query's own
/// model. A node's upstream tables name its children, so the edges are read from the models
/// rather than inferred from the document order. Pure and engine-free so the layout rules are
/// unit-testable.</summary>
public static class CompositionGraph
{
    public static (IReadOnlyList<CompositionNode> Nodes, IReadOnlyList<CompositionEdge> Edges) Build(
        DocumentInfo info,
        IReadOnlyDictionary<long, QueryModel> models)
    {
        if (!info.Composed || info.Queries.Count == 0)
        {
            return (Array.Empty<CompositionNode>(), Array.Empty<CompositionEdge>());
        }

        var known = info.Queries.Select(q => q.Id).ToHashSet();
        var edges = new List<CompositionEdge>();
        var seen = new HashSet<(long From, long To)>();

        foreach (QueryInfo query in info.Queries)
        {
            if (!models.TryGetValue(query.Id, out QueryModel? model)) continue;
            foreach (QueryTable table in model.Tables)
            {
                long from = table.UpstreamQuery;
                if (from == 0 || from == query.Id || !known.Contains(from)) continue;
                if (seen.Add((from, query.Id)))
                {
                    edges.Add(new CompositionEdge(from, query.Id));
                }
            }
        }

        // Depth is the distance from the root over the "feeds" edges; the root is depth 0.
        // A node not reachable from the root (a cycle, or a disconnected residual node) is
        // still shown one level down rather than hidden.
        var children = edges
            .GroupBy(e => e.ToId)
            .ToDictionary(g => g.Key, g => g.Select(e => e.FromId).Distinct().ToList());

        var depth = new Dictionary<long, int>();
        long rootId = info.RootQuery;
        if (rootId == 0 || !known.Contains(rootId))
        {
            rootId = info.Queries.FirstOrDefault(q => q.IsRoot)?.Id ?? info.Queries[0].Id;
        }

        depth[rootId] = 0;
        var queue = new Queue<long>();
        queue.Enqueue(rootId);
        while (queue.Count > 0)
        {
            long parent = queue.Dequeue();
            if (!children.TryGetValue(parent, out List<long>? kids)) continue;
            foreach (long child in kids)
            {
                int candidate = depth[parent] + 1;
                if (depth.TryGetValue(child, out int existing) && existing <= candidate) continue;
                depth[child] = candidate;
                queue.Enqueue(child);
            }
        }

        foreach (QueryInfo query in info.Queries)
        {
            depth.TryAdd(query.Id, 1);
        }

        // Root first, then shallow nodes before deep ones, keeping the document's order
        // within a level so the graph is stable across reloads.
        var order = info.Queries
            .Select((query, index) => (query, index))
            .OrderBy(x => depth[x.query.Id])
            .ThenBy(x => x.query.IsRoot ? 0 : 1)
            .ThenBy(x => x.index)
            .Select(x => new CompositionNode(
                x.query.Id, x.query.Name, x.query.IsRoot, depth[x.query.Id],
                models.TryGetValue(x.query.Id, out QueryModel? model) && model.IsComposing))
            .ToList();

        return (order, edges);
    }
}

/// <summary>The document-level composition state shared by the Composition pane, the Component
/// picker, and the Query workspace. It holds only the graph snapshot and the selection; the
/// document view model owns loading and mutation.</summary>
public sealed class CompositionViewModel : ObservableObject
{
    private IReadOnlyList<CompositionNode> _nodes = Array.Empty<CompositionNode>();
    private IReadOnlyList<CompositionEdge> _edges = Array.Empty<CompositionEdge>();
    private long _selectedNodeId;
    private bool _isExpanded;
    private DocumentInfo? _info;
    private readonly Dictionary<long, QueryModel> _models = new();

    /// <summary>Raised when the user picks a node, so the document can make it the selected
    /// query. Loading or externally synchronising the selection does not raise it.</summary>
    public event Action<long>? NodeSelected;

    public IReadOnlyList<CompositionNode> Nodes { get => _nodes; private set => Set(ref _nodes, value); }
    public IReadOnlyList<CompositionEdge> Edges { get => _edges; private set => Set(ref _edges, value); }

    public bool HasNodes => _nodes.Count > 0;
    public bool HasSources => _nodes.Any(n => !n.IsRoot);

    /// <summary>True for a composition that has a root but no sources yet: the pane shows its
    /// "import a report to begin" guidance instead of an empty graph.</summary>
    public bool ShowEmptyState => HasNodes && !HasSources;

    /// <summary>True when there is a graph to draw. It is hidden behind the empty-state
    /// guidance until the first source exists, so the two never overlap.</summary>
    public bool ShowGraph => HasNodes && !ShowEmptyState;

    /// <summary>True when the pane is taking the content area to arrange the graph.</summary>
    public bool IsExpanded
    {
        get => _isExpanded;
        private set
        {
            if (!Set(ref _isExpanded, value)) return;
            OnPropertyChanged(nameof(ExpandGlyph));
            OnPropertyChanged(nameof(ExpandTooltip));
            OnPropertyChanged(nameof(ExpandName));
        }
    }

    public string ExpandGlyph => ((char)(IsExpanded ? 0xE73F : 0xE740)).ToString();
    public string ExpandTooltip => Localizer.Get(IsExpanded ? "Composition.Collapse.Tooltip" : "Composition.Expand.Tooltip");
    public string ExpandName => Localizer.Get(IsExpanded ? "Composition.Collapse" : "Composition.Expand");

    public long SelectedNodeId
    {
        get => _selectedNodeId;
        private set
        {
            if (!Set(ref _selectedNodeId, value)) return;
            OnPropertyChanged(nameof(SelectedNode));
            OnPropertyChanged(nameof(IsSourceSelected));
            OnPropertyChanged(nameof(IsRootSelected));
        }
    }

    public CompositionNode? SelectedNode => _nodes.FirstOrDefault(n => n.Id == _selectedNodeId);
    public bool IsSourceSelected => SelectedNode is { IsRoot: false };
    public bool IsRootSelected => SelectedNode is null || SelectedNode.IsRoot;

    /// <summary>Replaces the graph with the document's current definition.</summary>
    public void Load(DocumentInfo info, IReadOnlyDictionary<long, QueryModel> models)
    {
        _info = info;
        _models.Clear();
        foreach ((long id, QueryModel model) in models) _models[id] = model;
        Rebuild();
    }

    /// <summary>Updates one query's model (the selected query reloads on every edit) and
    /// recomputes the edges, so adding an upstream table appears in the pane immediately.</summary>
    public void UpdateModel(long queryId, QueryModel model)
    {
        if (queryId == 0 || _info == null) return;
        _models[queryId] = model;
        Rebuild();
    }

    /// <summary>Sets the highlight without raising <see cref="NodeSelected"/> (the document is
    /// reporting the selection it already made).</summary>
    public void SetSelected(long nodeId)
    {
        if (_selectedNodeId == nodeId) return;
        if (_nodes.All(n => n.Id != nodeId)) return;
        SelectedNodeId = nodeId;
    }

    /// <summary>A user gesture: highlight the node and ask the document to select its query.</summary>
    public void Select(long nodeId)
    {
        SetSelected(nodeId);
        NodeSelected?.Invoke(nodeId);
    }

    public void ToggleExpanded() => IsExpanded = !IsExpanded;

    public void Collapse() => IsExpanded = false;

    private void Rebuild()
    {
        if (_info == null)
        {
            Nodes = Array.Empty<CompositionNode>();
            Edges = Array.Empty<CompositionEdge>();
            OnPropertyChanged(nameof(HasNodes));
            OnPropertyChanged(nameof(HasSources));
            OnPropertyChanged(nameof(ShowEmptyState));
            OnPropertyChanged(nameof(ShowGraph));
            return;
        }

        var (nodes, edges) = CompositionGraph.Build(_info, _models);
        Nodes = nodes;
        Edges = edges;
        OnPropertyChanged(nameof(HasNodes));
        OnPropertyChanged(nameof(HasSources));
        OnPropertyChanged(nameof(ShowEmptyState));
        OnPropertyChanged(nameof(ShowGraph));
        OnPropertyChanged(nameof(SelectedNode));
        OnPropertyChanged(nameof(IsSourceSelected));
        OnPropertyChanged(nameof(IsRootSelected));
    }
}
