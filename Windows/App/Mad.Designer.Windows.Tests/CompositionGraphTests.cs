//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using System.Windows;
using System.Windows.Automation;
using System.Windows.Controls;
using System.Windows.Shapes;
using Mad.Designer.Windows.Models;
using Mad.Designer.Windows.ViewModels;
using Mad.Designer.Windows.Views;
using ShapePath = System.Windows.Shapes.Path;

namespace Mad.Designer.Windows.Tests;

/// <summary>The Composition pane's graph: edges come from each query's own upstream tables,
/// the Result is depth 0 at the top, and the view draws one selectable card per report part.
/// The graph builder is pure, so these checks need no engine or document file.</summary>
public sealed class CompositionGraphTests
{
    private static QueryModel Model(long id, bool isRoot, params long[] upstream)
        => new(
            "sqlite",
            "",
            "",
            upstream
                .Select((child, index) => new QueryTable(
                    1000 + id * 10 + index,
                    $"table{index}",
                    "",
                    index,
                    Array.Empty<QueryField>(),
                    child))
                .ToList(),
            Array.Empty<QueryLink>(),
            Array.Empty<QueryPredicate>(),
            Array.Empty<QueryGroup>(),
            id,
            isRoot);

    private static DocumentInfo Document(params QueryInfo[] queries)
        => new(true, queries.First(q => q.IsRoot).Id, queries);

    [Fact]
    public void Build_ReadsTheEdgesFromEachQuerysUpstreamTables()
    {
        var queries = new[]
        {
            new QueryInfo(100, "Receivables", true),
            new QueryInfo(200, "Invoices", false),
            new QueryInfo(300, "Payments", false),
        };
        var models = new Dictionary<long, QueryModel>
        {
            [100] = Model(100, true, 200, 300),
            [200] = Model(200, false),
            [300] = Model(300, false),
        };

        var (nodes, edges) = CompositionGraph.Build(Document(queries), models);

        Assert.Equal(new long[] { 100, 200, 300 }, nodes.Select(n => n.Id).ToArray());
        Assert.Equal(0, nodes[0].Depth);
        Assert.True(nodes[0].IsRoot);
        Assert.All(nodes.Skip(1), n => Assert.Equal(1, n.Depth));
        Assert.Equal(new[]
        {
            new CompositionEdge(200, 100),
            new CompositionEdge(300, 100),
        }, edges.OrderBy(e => e.FromId).ToArray());
    }

    [Fact]
    public void Build_ComputesDepthThroughNestedComposers()
    {
        var queries = new[]
        {
            new QueryInfo(100, "Receivables", true),
            new QueryInfo(200, "Open balances", false),
            new QueryInfo(300, "Payments", false),
        };
        var models = new Dictionary<long, QueryModel>
        {
            [100] = Model(100, true, 200),
            [200] = Model(200, false, 300),
            [300] = Model(300, false),
        };

        var (nodes, edges) = CompositionGraph.Build(Document(queries), models);

        Assert.Equal(0, nodes.Single(n => n.Id == 100).Depth);
        Assert.Equal(1, nodes.Single(n => n.Id == 200).Depth);
        Assert.Equal(2, nodes.Single(n => n.Id == 300).Depth);
        Assert.Contains(new CompositionEdge(300, 200), edges);
    }

    [Fact]
    public void Build_IsEmptyForAStandardReport()
    {
        var info = new DocumentInfo(false, 0, new[] { new QueryInfo(1, "Query", false) });
        var (nodes, edges) = CompositionGraph.Build(info, new Dictionary<long, QueryModel>());
        Assert.Empty(nodes);
        Assert.Empty(edges);
    }

    [Fact]
    public void Build_IgnoresUnknownUpstreamsDuplicatesAndItself()
    {
        var queries = new[]
        {
            new QueryInfo(100, "Receivables", true),
            new QueryInfo(200, "Invoices", false),
        };
        var model = new QueryModel(
            "sqlite", "", "",
            new[]
            {
                new QueryTable(1, "a", "", 0, Array.Empty<QueryField>(), 200),
                new QueryTable(2, "b", "", 1, Array.Empty<QueryField>(), 200),
                new QueryTable(3, "c", "", 2, Array.Empty<QueryField>(), 999),
                new QueryTable(4, "d", "", 3, Array.Empty<QueryField>(), 100),
            },
            Array.Empty<QueryLink>(), Array.Empty<QueryPredicate>(), Array.Empty<QueryGroup>(), 100, true);

        var (_, edges) = CompositionGraph.Build(Document(queries), new Dictionary<long, QueryModel>
        {
            [100] = model,
            [200] = Model(200, false),
        });

        Assert.Equal(new[] { new CompositionEdge(200, 100) }, edges.ToArray());
    }

    [Fact]
    public void SelectingANode_RaisesTheSelectionEventOnlyForAGesture()
    {
        var vm = new CompositionViewModel();
        vm.Load(Document(
            new QueryInfo(100, "Receivables", true),
            new QueryInfo(200, "Invoices", false)),
            new Dictionary<long, QueryModel> { [100] = Model(100, true, 200), [200] = Model(200, false) });

        long? raised = null;
        vm.NodeSelected += id => raised = id;

        vm.SetSelected(200);
        Assert.Null(raised);
        Assert.Equal(200, vm.SelectedNodeId);

        vm.Select(100);
        Assert.Equal(100, raised);
    }

    [Fact]
    public void GraphView_DrawsACardPerNodeAndConnectorPerEdge()
    {
        var vm = new CompositionViewModel();
        vm.Load(Document(
            new QueryInfo(100, "Receivables", true),
            new QueryInfo(200, "Invoices", false),
            new QueryInfo(300, "Payments", false)),
            new Dictionary<long, QueryModel>
            {
                [100] = Model(100, true, 200, 300),
                [200] = Model(200, false),
                [300] = Model(300, false),
            });

        Exception? failure = null;
        int cards = 0;
        int connectors = 0;
        int arrows = 0;
        List<string> accessibleNames = new();

        var thread = new Thread(() =>
        {
            try
            {
                var view = new CompositionGraphView { Composition = vm };
                view.Measure(new Size(300, 500));
                view.Arrange(new Rect(0, 0, 300, 500));
                view.UpdateLayout();

                cards = view.Children.OfType<Border>().Count(b => b.Tag is long);
                connectors = view.Children.OfType<ShapePath>().Count(p => p.Tag is CompositionEdge);
                arrows = view.Children.OfType<Polygon>().Count();
                accessibleNames = view.Children.OfType<Border>()
                    .Where(b => b.Tag is long)
                    .Select(AutomationProperties.GetName)
                    .ToList();
            }
            catch (Exception exception)
            {
                failure = exception;
            }
        });
        thread.SetApartmentState(ApartmentState.STA);
        thread.Start();
        thread.Join();

        Assert.Null(failure);
        Assert.Equal(3, cards);
        Assert.Equal(4, connectors); // a visible line and a wider hit target per edge
        Assert.Equal(2, arrows);
        Assert.Contains(accessibleNames, n => n.Contains("Result"));
        Assert.Contains(accessibleNames, n => n.Contains("Source"));
    }
}
