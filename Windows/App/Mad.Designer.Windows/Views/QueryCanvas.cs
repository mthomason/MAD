//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Shapes;
using Mad.Designer.Windows.Infrastructure;
using Mad.Designer.Windows.Models;
using Mad.Designer.Windows.ViewModels;

namespace Mad.Designer.Windows.Views;

/// <summary>The MAD Query visual canvas: floating table cards and bezier join links, drawn
/// as WPF elements. It rebuilds itself from the <see cref="QueryViewModel"/>'s snapshot and
/// reports field-to-field drags back through the view model (which owns every mutation).
/// This is the WPF counterpart of the Mac's <c>MADMacQueryCanvasView</c> and its overlay.</summary>
public sealed class QueryCanvas : Canvas
{
    private const double CardWidth = 188;
    private const double CardHeight = 208;
    private const double TitleBarHeight = 28;
    private const double FieldRowHeight = 20;
    private const double GridX = 48;
    private const double GridY = 44;

    private static readonly Brush ConnectorRed = DesignPalette.ConnectorRed;
    private static readonly Brush AccentBlue = DesignPalette.Accent;
    private static readonly Brush CardBackground = SystemColors.WindowBrush;
    private static readonly Brush RootHeader = DesignPalette.CardRootHeader;

    static QueryCanvas()
    {
        ConnectorRed.Freeze();
        AccentBlue.Freeze();
        RootHeader.Freeze();
    }

    private QueryViewModel? _vm;
    private readonly Dictionary<long, Border> _cards = new();
    private readonly Dictionary<long, List<Border>> _fieldRows = new();
    private readonly Dictionary<long, QueryTable> _tablesById = new();
    private readonly Dictionary<long, Point> _positions = new();
    private readonly ScaleTransform _scale = new(1.0, 1.0);
    private Path? _rubberBand;
    private DragSource? _drag;

    public QueryCanvas()
    {
        LayoutTransform = _scale;
    }

    /// <summary>The unscaled extent of the card layout (the layout transform applies zoom).</summary>
    public double ContentWidth { get; private set; } = 720.0;
    public double ContentHeight { get; private set; } = 480.0;

    public void Attach(QueryViewModel vm)
    {
        _vm = vm;
        vm.PropertyChanged += OnViewModelChanged;
        vm.ArrangeRequested += Arrange;
        Rebuild();
    }

    private void OnViewModelChanged(object? sender, System.ComponentModel.PropertyChangedEventArgs e)
    {
        if (e.PropertyName is nameof(QueryViewModel.Model) or nameof(QueryViewModel.SelectedLinkId))
        {
            Rebuild();
        }
        else if (e.PropertyName == nameof(QueryViewModel.Zoom))
        {
            ApplyZoom();
        }
    }

    private void ApplyZoom()
    {
        double zoom = _vm?.Zoom ?? 1.0;
        _scale.ScaleX = zoom;
        _scale.ScaleY = zoom;
    }

    /// <summary>Grows the canvas to the cards' bounds so the ScrollViewer can pan and the Fit
    /// command can measure the whole layout.</summary>
    private void UpdateExtent()
    {
        double right = 0.0;
        double bottom = 0.0;
        foreach (long id in _tablesById.Keys)
        {
            if (!_positions.TryGetValue(id, out Point position)) continue;
            right = Math.Max(right, position.X + CardWidth);
            bottom = Math.Max(bottom, position.Y + CardHeight);
        }

        ContentWidth = Math.Max(720.0, right + GridX);
        ContentHeight = Math.Max(480.0, bottom + GridY);
        Width = ContentWidth;
        Height = ContentHeight;
    }

    private void Rebuild()
    {
        if (_vm == null) return;

        Children.Clear();
        _cards.Clear();
        _fieldRows.Clear();
        _tablesById.Clear();
        _rubberBand = null;
        _drag = null;

        foreach (var table in _vm.OrderedTables)
        {
            _tablesById[table.Id] = table;
        }

        foreach (var table in _vm.OrderedTables)
        {
            BuildCard(table);
        }

        DrawLinks();

        if (_vm.Tables.Count == 0)
        {
            var hint = new TextBlock
            {
                Text = Localizer.Get("Query.Placeholder"),
                Foreground = SystemColors.GrayTextBrush,
                FontSize = 13.5,
                TextAlignment = TextAlignment.Center,
                TextWrapping = TextWrapping.Wrap,
                Width = 360,
            };
            SetLeft(hint, (ActualWidth - 360) / 2);
            SetTop(hint, ActualHeight * 0.42);
            Children.Add(hint);
        }

        UpdateExtent();
        ApplyZoom();
    }

    private void BuildCard(QueryTable table)
    {
        var position = _positions.TryGetValue(table.Id, out var cached)
            ? cached
            : DefaultPosition(_cards.Count);

        var card = new Border
        {
            Width = CardWidth,
            Height = CardHeight,
            CornerRadius = new CornerRadius(10),
            Background = CardBackground,
            BorderBrush = SystemColors.ActiveBorderBrush,
            BorderThickness = new Thickness(1),
            Effect = new System.Windows.Media.Effects.DropShadowEffect { BlurRadius = 8, ShadowDepth = 3, Opacity = 0.28 },
            Tag = table.Id,
        };
        SetLeft(card, position.X);
        SetTop(card, position.Y);
        _positions[table.Id] = position;

        bool isRoot = _vm!.RootTableIds.Contains(table.Id);
        string alias = string.IsNullOrEmpty(table.Alias) ? table.Name : table.Alias;

        var grid = new Grid();
        grid.RowDefinitions.Add(new RowDefinition { Height = new GridLength(TitleBarHeight) });
        grid.RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Star) });

        var header = BuildHeader(alias, isRoot, table.Id);
        Grid.SetRow(header, 0);
        grid.Children.Add(header);

        var fieldPanel = new StackPanel { Margin = new Thickness(1, 0, 1, 6) };
        var rows = new List<Border>();
        foreach (var field in table.Fields)
        {
            var row = BuildFieldRow(table, field);
            rows.Add(row);
            fieldPanel.Children.Add(row);
        }
        var scroll = new ScrollViewer
        {
            VerticalScrollBarVisibility = ScrollBarVisibility.Auto,
            HorizontalScrollBarVisibility = ScrollBarVisibility.Disabled,
            Content = fieldPanel,
            BorderThickness = new Thickness(0),
        };
        Grid.SetRow(scroll, 1);
        grid.Children.Add(scroll);

        card.Child = grid;
        _cards[table.Id] = card;
        _fieldRows[table.Id] = rows;
        Children.Add(card);
    }

    private Border BuildHeader(string alias, bool isRoot, long tableId)
    {
        var header = new Border
        {
            Background = isRoot ? RootHeader : DesignPalette.CardSubHeader,
            CornerRadius = new CornerRadius(10, 10, 0, 0),
        };

        var grid = new Grid();
        var title = new TextBlock
        {
            Text = alias,
            Foreground = isRoot ? DesignPalette.Paper : DesignPalette.CardSubHeaderText,
            FontWeight = isRoot ? FontWeights.SemiBold : FontWeights.Medium,
            FontSize = isRoot ? 12 : 11.5,
            TextAlignment = TextAlignment.Center,
            TextTrimming = TextTrimming.CharacterEllipsis,
            VerticalAlignment = VerticalAlignment.Center,
            Margin = new Thickness(22, 0, 22, 0),
        };
        grid.Children.Add(title);

        var remove = new Button
        {
            Content = "×",
            Width = 20,
            Height = 20,
            Padding = new Thickness(0),
            BorderThickness = new Thickness(0),
            Background = Brushes.Transparent,
            Foreground = isRoot ? DesignPalette.Paper : DesignPalette.Accent,
            FontSize = 14,
            FontWeight = FontWeights.Bold,
            HorizontalAlignment = HorizontalAlignment.Right,
            VerticalAlignment = VerticalAlignment.Top,
            ToolTip = Localizer.Get("Query.RemoveTable.Tooltip"),
            Tag = tableId,
        };
        remove.Click += async (_, _) => await _vm!.RemoveTableAsync(tableId);
        grid.Children.Add(remove);

        header.Child = grid;

        // Dragging by the title bar moves the card.
        header.MouseLeftButtonDown += (_, e) =>
        {
            var card = _cards[tableId];
            _drag = new DragSource(tableId, 0, e.GetPosition(this), GetLeft(card), GetTop(card));
            header.CaptureMouse();
        };
        header.MouseMove += (_, e) =>
        {
            if (_drag is not { } drag || drag.IsLinkDrag) return;
            var p = e.GetPosition(this);
            SetLeft(_cards[tableId], Math.Max(12, drag.StartLeft + (p.X - drag.Start.X)));
            SetTop(_cards[tableId], Math.Max(12, drag.StartTop + (p.Y - drag.Start.Y)));
            _positions[tableId] = new Point(GetLeft(_cards[tableId]), GetTop(_cards[tableId]));
            UpdateExtent();
            DrawLinks();
        };
        header.MouseLeftButtonUp += (_, _) =>
        {
            if (_drag is { IsLinkDrag: false }) { _drag = null; header.ReleaseMouseCapture(); }
        };

        return header;
    }

    private Border BuildFieldRow(QueryTable table, QueryField field)
    {
        var text = new TextBlock
        {
            FontSize = 11,
            Margin = new Thickness(8, 0, 8, 0),
            VerticalAlignment = VerticalAlignment.Center,
            TextTrimming = TextTrimming.CharacterEllipsis,
        };

        void RefreshText()
        {
            bool linked = _vm!.IsFieldLinked(field.Id);
            bool grouped = _vm.IsFieldGrouped(field.Id);
            bool filtered = _vm.IsFieldFiltered(field.Id);
            string display = $"{(linked ? "●" : "○")}  {field.Name}";
            if (grouped) display += $"  [{Localizer.Get("Query.Badge.Grouped")}]";
            if (filtered) display += $"  [{Localizer.Get("Query.Badge.Filtered")}]";
            text.Text = display;
            text.Foreground = linked ? ConnectorRed : SystemColors.ControlTextBrush;
            text.FontWeight = linked || grouped || filtered ? FontWeights.SemiBold : FontWeights.Normal;
        }
        RefreshText();

        var row = new Border
        {
            Height = FieldRowHeight,
            Child = text,
            Background = Brushes.Transparent,
            Tag = field.Id,
            ToolTip = Localizer.Get("Query.FieldDrag.Tooltip"),
        };

        row.MouseLeftButtonDown += (_, e) =>
        {
            _drag = new DragSource(table.Id, field.Id, e.GetPosition(this), 0, 0) { IsLinkDrag = false };
            row.CaptureMouse();
        };
        row.MouseMove += (_, e) =>
        {
            if (_drag is not { } drag || drag.TableId != table.Id || drag.FieldId != field.Id) return;
            var p = e.GetPosition(this);
            if (!drag.IsLinkDrag)
            {
                if (Math.Abs(p.X - drag.Start.X) + Math.Abs(p.Y - drag.Start.Y) > 3)
                {
                    drag.IsLinkDrag = true;
                }
                else
                {
                    return;
                }
            }
            UpdateRubberBand(drag, p);
        };
        row.MouseLeftButtonUp += async (_, e) =>
        {
            if (_drag is not { } drag || drag.TableId != table.Id || drag.FieldId != field.Id)
            {
                return;
            }
            var p = e.GetPosition(this);
            row.ReleaseMouseCapture();
            bool wasLinkDrag = drag.IsLinkDrag;
            _drag = null;
            RemoveRubberBand();
            if (wasLinkDrag)
            {
                var target = HitTestField(p);
                if (target is { } t && t.TableId != table.Id)
                {
                    await _vm!.ConnectFieldsAsync(field.Id, t.FieldId);
                }
            }
        };

        return row;
    }

    private void UpdateRubberBand(DragSource drag, Point end)
    {
        if (_rubberBand == null)
        {
            _rubberBand = new Path
            {
                Stroke = ConnectorRed,
                StrokeThickness = 3,
                StrokeStartLineCap = PenLineCap.Round,
                StrokeEndLineCap = PenLineCap.Round,
            };
            Children.Add(_rubberBand);
        }
        var start = FieldAnchor(drag.TableId, drag.FieldId);
        _rubberBand.Data = MakeCurve(start, end);
    }

    private void RemoveRubberBand()
    {
        if (_rubberBand != null)
        {
            Children.Remove(_rubberBand);
            _rubberBand = null;
        }
    }

    private void DrawLinks()
    {
        if (_vm == null) return;

        foreach (var child in Children.OfType<FrameworkElement>().Where(c => c.Tag is QueryLink).ToList())
        {
            Children.Remove(child);
        }

        foreach (var link in _vm.Links)
        {
            long leftTable = TableOfField(link.LeftField);
            long rightTable = TableOfField(link.RightField);
            if (leftTable == 0 || rightTable == 0 || !_cards.ContainsKey(leftTable) || !_cards.ContainsKey(rightTable)) continue;

            var origin = FieldAnchor(leftTable, link.LeftField);
            var destination = FieldAnchor(rightTable, link.RightField);
            bool leftIsInitial = GetLeft(_cards[leftTable]) <= GetLeft(_cards[rightTable]);

            var start = new Point(leftIsInitial ? GetLeft(_cards[leftTable]) + CardWidth : GetLeft(_cards[leftTable]), origin.Y);
            var end = new Point(leftIsInitial ? GetLeft(_cards[rightTable]) : GetLeft(_cards[rightTable]) + CardWidth, destination.Y);

            bool selected = _vm.SelectedLinkId == link.Id;
            var brush = selected ? AccentBlue : ConnectorRed;

            var path = new Path
            {
                Data = MakeCurve(start, end),
                Stroke = brush,
                StrokeThickness = selected ? 4 : 3,
                StrokeStartLineCap = PenLineCap.Round,
                StrokeEndLineCap = PenLineCap.Round,
                Tag = link,
                // The curve is visual only; the midpoint badge is the click target, so the
                // stroke never intercepts a click meant for a card underneath it.
                IsHitTestVisible = false,
            };
            Children.Add(path);

            var mid = CubicPoint(start, end, 0.5);
            var badge = new Border
            {
                Background = selected ? AccentBlue : CardBackground,
                BorderBrush = selected ? DesignPalette.Paper : brush,
                BorderThickness = new Thickness(selected ? 1.8 : 1.25),
                CornerRadius = new CornerRadius(8),
                Padding = new Thickness(6, 1, 6, 1),
                Tag = link,
                ToolTip = Localizer.Format(
                    "Query.JoinBadge.Tooltip", link.Type.DisplayName(), AliasOf(leftTable), AliasOf(rightTable)),
                Child = new TextBlock
                {
                    Text = link.Type.ShortBadge(),
                    FontSize = 9.5,
                    FontWeight = FontWeights.Bold,
                    Foreground = selected ? DesignPalette.Paper : brush,
                },
            };
            badge.Measure(new Size(double.PositiveInfinity, double.PositiveInfinity));
            SetLeft(badge, mid.X - badge.DesiredSize.Width / 2);
            SetTop(badge, mid.Y - badge.DesiredSize.Height / 2);
            badge.MouseLeftButtonDown += (_, _) => _vm.SelectLink(link.Id);
            badge.ContextMenu = BuildLinkMenu(link);
            Children.Add(badge);
        }
    }

    private ContextMenu BuildLinkMenu(QueryLink link)
    {
        var menu = new ContextMenu();
        foreach (var type in LinkTypeExtensions.SupportedJoinTypes(_vm!.Driver))
        {
            var item = new MenuItem
            {
                Header = type.DisplayName(),
                IsChecked = link.Type == type,
            };
            item.Click += async (_, _) => await _vm.SetLinkTypeAsync(link.Id, type);
            menu.Items.Add(item);
        }
        menu.Items.Add(new Separator());
        var swap = new MenuItem { Header = Localizer.Get("Query.SwapJoin") };
        swap.Click += async (_, _) => await _vm.SwapLinkAsync(link.Id);
        menu.Items.Add(swap);
        var del = new MenuItem { Header = Localizer.Get("Query.DeleteJoin") };
        del.Click += async (_, _) => await _vm.DeleteLinkAsync(link.Id);
        menu.Items.Add(del);
        return menu;
    }

    private Point FieldAnchor(long tableId, long fieldId)
    {
        var card = _cards[tableId];
        int index = _tablesById[tableId].Fields.ToList().FindIndex(f => f.Id == fieldId);
        if (index < 0) index = 0;
        double y = GetTop(card) + TitleBarHeight + index * FieldRowHeight + FieldRowHeight / 2;
        return new Point(GetLeft(card), y);
    }

    private long TableOfField(long fieldId)
    {
        foreach (var (tableId, table) in _tablesById)
        {
            if (table.Fields.Any(f => f.Id == fieldId)) return tableId;
        }
        return 0;
    }

    private string AliasOf(long tableId)
        => _tablesById.TryGetValue(tableId, out QueryTable? table)
            ? (string.IsNullOrEmpty(table.Alias) ? table.Name : table.Alias)
            : "";

    private (long TableId, long FieldId)? HitTestField(Point p)
    {
        foreach (var (tableId, card) in _cards)
        {
            var left = GetLeft(card);
            var top = GetTop(card);
            if (p.X < left || p.X > left + CardWidth || p.Y < top + TitleBarHeight || p.Y > top + CardHeight)
            {
                continue;
            }
            int index = (int)((p.Y - top - TitleBarHeight) / FieldRowHeight);
            var fields = _tablesById[tableId].Fields;
            if (index < 0) index = 0;
            if (index >= fields.Count) index = fields.Count - 1;
            return (tableId, fields[index].Id);
        }
        return null;
    }

    private static Point CubicPoint(Point start, Point end, double t)
    {
        double dx = Math.Max(Math.Abs(end.X - start.X) * 0.45, 44);
        var c1 = new Point(start.X + dx, start.Y);
        var c2 = new Point(end.X - dx, end.Y);
        double u = 1 - t;
        return new Point(
            u * u * u * start.X + 3 * u * u * t * c1.X + 3 * u * t * t * c2.X + t * t * t * end.X,
            u * u * u * start.Y + 3 * u * u * t * c1.Y + 3 * u * t * t * c2.Y + t * t * t * end.Y);
    }

    private static Geometry MakeCurve(Point start, Point end)
    {
        double dx = Math.Max(Math.Abs(end.X - start.X) * 0.45, 44);
        var c1 = new Point(start.X + dx, start.Y);
        var c2 = new Point(end.X - dx, end.Y);
        var figure = new PathFigure { StartPoint = start };
        figure.Segments.Add(new BezierSegment(c1, c2, end, true));
        var geometry = new StreamGeometry();
        using (var ctx = geometry.Open())
        {
            ctx.BeginFigure(start, false, false);
            ctx.BezierTo(c1, c2, end, true, true);
        }
        return geometry;
    }

    private Point DefaultPosition(int index)
    {
        int column = index % 3;
        int row = index / 3;
        return new Point(GridX + column * (CardWidth + 96), GridY + row * (CardHeight + 52));
    }

    private void Arrange()
    {
        int index = 0;
        foreach (var table in _vm!.OrderedTables)
        {
            var position = DefaultPosition(index++);
            _positions[table.Id] = position;
            if (_cards.TryGetValue(table.Id, out var card))
            {
                SetLeft(card, position.X);
                SetTop(card, position.Y);
            }
        }
        UpdateExtent();
        DrawLinks();
    }

    private sealed class DragSource
    {
        public DragSource(long tableId, long fieldId, Point start, double startLeft, double startTop)
        {
            TableId = tableId;
            FieldId = fieldId;
            Start = start;
            StartLeft = startLeft;
            StartTop = startTop;
        }

        public long TableId { get; }
        public long FieldId { get; }
        public Point Start { get; }
        public double StartLeft { get; }
        public double StartTop { get; }
        public bool IsLinkDrag { get; set; }
    }
}
