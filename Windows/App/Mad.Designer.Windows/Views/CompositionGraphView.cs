//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using System.ComponentModel;
using System.Windows;
using System.Windows.Automation;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Shapes;
using Mad.Designer.Windows.Infrastructure;
using Mad.Designer.Windows.ViewModels;

namespace Mad.Designer.Windows.Views;

/// <summary>The Composition pane's graph: one card per report part, with the Result at the top
/// and each source below the node it feeds. Clicking a card selects that query for the
/// workspace. The card and connector drawing matches <see cref="QueryCanvas"/>'s hand-drawn
/// approach, but the composition graph is a navigation surface, not an editable diagram, so
/// there is nothing to drag here.</summary>
public sealed class CompositionGraphView : Canvas
{
    private const double CardHeight = 50.0;
    private const double RowGap = 14.0;
    private const double MarginX = 10.0;
    private const double IndentStep = 16.0;
    private const double GutterOffset = 9.0;

    public static readonly DependencyProperty CompositionProperty = DependencyProperty.Register(
        nameof(Composition),
        typeof(CompositionViewModel),
        typeof(CompositionGraphView),
        new PropertyMetadata(null, OnCompositionChanged));

    private CompositionViewModel? _composition;
    private double _lastWidth = -1;
    private readonly Dictionary<long, Rect> _rects = new();

    public CompositionGraphView()
    {
        SnapsToDevicePixels = true;
        HorizontalAlignment = HorizontalAlignment.Stretch;
        VerticalAlignment = VerticalAlignment.Top;
        SizeChanged += (_, _) =>
        {
            if (Math.Abs(ActualWidth - _lastWidth) > 0.5) Rebuild();
        };
    }

    /// <summary>The graph model. Bound in XAML to <c>Document.Composition</c>.</summary>
    public CompositionViewModel? Composition
    {
        get => (CompositionViewModel?)GetValue(CompositionProperty);
        set => SetValue(CompositionProperty, value);
    }

    private static void OnCompositionChanged(DependencyObject d, DependencyPropertyChangedEventArgs e)
    {
        var view = (CompositionGraphView)d;
        if (view._composition != null)
        {
            view._composition.PropertyChanged -= view.OnCompositionPropertyChanged;
        }
        view._composition = e.NewValue as CompositionViewModel;
        if (view._composition != null)
        {
            view._composition.PropertyChanged += view.OnCompositionPropertyChanged;
        }
        view.Rebuild();
    }

    private void OnCompositionPropertyChanged(object? sender, PropertyChangedEventArgs e)
    {
        if (e.PropertyName is nameof(CompositionViewModel.Nodes)
            or nameof(CompositionViewModel.Edges)
            or nameof(CompositionViewModel.SelectedNodeId))
        {
            Rebuild();
        }
    }

    private void Rebuild()
    {
        Children.Clear();
        _rects.Clear();
        if (_composition == null) return;

        IReadOnlyList<CompositionNode> nodes = _composition.Nodes;
        if (nodes.Count == 0)
        {
            Width = double.NaN;
            Height = 0;
            return;
        }

        double available = Math.Max(220.0, ActualWidth > 0 ? ActualWidth : 300.0);
        _lastWidth = available;

        // A readable column: the docked pane uses its width; the expanded pane caps the graph
        // and centres it instead of stretching a card across the whole window.
        double columnWidth = Math.Min(available - MarginX * 2, 460.0);
        double left = Math.Max(MarginX, (available - columnWidth) / 2);

        // Lay the cards out first so the connectors can use their exact edges.
        double y = 0.0;
        foreach (CompositionNode node in nodes)
        {
            int depth = Math.Max(0, node.Depth);
            double x = left + depth * IndentStep;
            double cardWidth = Math.Max(150.0, columnWidth - depth * IndentStep);
            _rects[node.Id] = new Rect(x, y, cardWidth, CardHeight);
            y += CardHeight + RowGap;
        }

        DrawEdges();

        foreach (CompositionNode node in nodes)
        {
            Border card = BuildCard(node, _rects[node.Id].Width);
            SetLeft(card, _rects[node.Id].X);
            SetTop(card, _rects[node.Id].Y);
            Children.Add(card);
        }

        // Leave Width unset so HorizontalAlignment=Stretch gives the canvas the viewport
        // width (including after the pane expands); SizeChanged re-lays it out.
        Height = Math.Max(0, y - RowGap);
    }

    private void DrawEdges()
    {
        if (_composition == null) return;

        foreach (CompositionEdge edge in _composition.Edges)
        {
            if (!_rects.TryGetValue(edge.FromId, out Rect from) || !_rects.TryGetValue(edge.ToId, out Rect to))
            {
                continue;
            }

            double gutterX = Math.Max(2.0, Math.Min(from.X, to.X) - GutterOffset);
            var start = new Point(from.X, from.Y + from.Height / 2);
            var end = new Point(to.X, to.Y + to.Height / 2);

            var figure = new PathFigure { StartPoint = start, IsFilled = false };
            figure.Segments.Add(new PolyLineSegment(
                new[] { new Point(gutterX, start.Y), new Point(gutterX, end.Y), end },
                isStroked: true));

            var geometry = new PathGeometry();
            geometry.Figures.Add(figure);

            Brush accent = ThemeBrush("AccentFillColorDefaultBrush", DesignPalette.Accent);
            string tooltip = Localizer.Format(
                "Composition.Edge.Tooltip", NameOf(edge.FromId), NameOf(edge.ToId));

            // A transparent, thicker copy carries the tooltip; the visible line stays thin.
            var hit = new Path
            {
                Data = geometry,
                Stroke = Brushes.Transparent,
                StrokeThickness = 9,
                ToolTip = tooltip,
                IsHitTestVisible = true,
                Tag = edge,
            };
            Children.Add(hit);

            Children.Add(new Path
            {
                Data = geometry,
                Stroke = accent,
                StrokeThickness = 1.4,
                StrokeLineJoin = PenLineJoin.Round,
                IsHitTestVisible = false,
                Tag = edge,
            });

            var arrow = new Polygon
            {
                Points = new PointCollection
                {
                    new(end.X, end.Y),
                    new(end.X - 6, end.Y - 3.5),
                    new(end.X - 6, end.Y + 3.5),
                },
                Fill = accent,
                IsHitTestVisible = false,
            };
            Children.Add(arrow);
        }
    }

    private Border BuildCard(CompositionNode node, double width)
    {
        bool selected = _composition?.SelectedNodeId == node.Id;
        Brush accent = ThemeBrush("AccentFillColorDefaultBrush", DesignPalette.Accent);
        Brush cardBackground = ThemeBrush("CardBackgroundFillColorDefaultBrush", SystemColors.WindowBrush);
        Brush cardStroke = ThemeBrush("CardStrokeColorDefaultBrush", SystemColors.ActiveBorderBrush);
        Brush primaryText = ThemeBrush("TextFillColorPrimaryBrush", SystemColors.ControlTextBrush);
        Brush secondaryText = ThemeBrush("TextFillColorSecondaryBrush", SystemColors.GrayTextBrush);
        Brush onAccent = ThemeBrush("TextOnAccentFillColorPrimaryBrush", DesignPalette.Paper);

        var grid = new Grid();
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(4) });
        grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });

        var bar = new Border
        {
            Background = node.IsRoot ? accent : Brushes.Transparent,
            CornerRadius = new CornerRadius(5, 0, 0, 5),
        };
        grid.Children.Add(bar);

        var content = new Grid { Margin = new Thickness(9, 4, 8, 4) };
        content.RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Star) });
        content.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });

        var title = new TextBlock
        {
            Text = node.Name,
            FontSize = 12.5,
            FontWeight = selected || node.IsRoot ? FontWeights.SemiBold : FontWeights.Medium,
            Foreground = primaryText,
            TextTrimming = TextTrimming.CharacterEllipsis,
            VerticalAlignment = VerticalAlignment.Center,
        };
        content.Children.Add(title);

        var rolePill = new Border
        {
            HorizontalAlignment = HorizontalAlignment.Left,
            VerticalAlignment = VerticalAlignment.Center,
            Background = node.IsRoot ? accent : ThemeBrush("SubtleFillColorSecondaryBrush", SystemColors.ControlBrush),
            CornerRadius = new CornerRadius(7),
            Padding = new Thickness(6, 0, 6, 1),
            Margin = new Thickness(0, 2, 0, 0),
            Child = new TextBlock
            {
                Text = Localizer.Get(node.IsRoot ? "Composition.Root" : "Composition.Source"),
                FontSize = 9.5,
                FontWeight = FontWeights.SemiBold,
                Foreground = node.IsRoot ? onAccent : secondaryText,
            },
        };
        Grid.SetRow(rolePill, 1);
        content.Children.Add(rolePill);

        Grid.SetColumn(content, 1);
        grid.Children.Add(content);

        var card = new Border
        {
            Width = width,
            Height = CardHeight,
            Background = cardBackground,
            BorderBrush = selected ? accent : cardStroke,
            BorderThickness = new Thickness(selected ? 2 : 1),
            CornerRadius = new CornerRadius(6),
            Child = grid,
            Cursor = Cursors.Hand,
            Focusable = true,
            ToolTip = Localizer.Format("Composition.Node.Tooltip", node.Name),
            Tag = node.Id,
        };
        AutomationProperties.SetName(card, $"{node.Name}, {Localizer.Get(node.IsRoot ? "Composition.Root" : "Composition.Source")}");

        card.MouseLeftButtonUp += (_, _) => _composition?.Select(node.Id);
        card.KeyDown += (_, e) =>
        {
            if (e.Key is Key.Enter or Key.Space)
            {
                _composition?.Select(node.Id);
                e.Handled = true;
            }
        };

        return card;
    }

    private string NameOf(long nodeId)
        => _composition?.Nodes.FirstOrDefault(n => n.Id == nodeId)?.Name ?? "";

    private Brush ThemeBrush(string key, Brush fallback)
        => TryFindResource(key) as Brush ?? fallback;
}
