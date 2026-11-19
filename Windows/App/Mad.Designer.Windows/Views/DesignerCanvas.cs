//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using System.ComponentModel;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Shapes;
using Mad.Designer.Windows.Engine;
using Mad.Designer.Windows.Models;
using Mad.Designer.Windows.ViewModels;

namespace Mad.Designer.Windows.Views;

/// <summary>The MAD Designer canvas: a zoomable, scrollable WPF drawing of the report's paper
/// bands and placed elements, with click-to-select, drag-to-move, 8-handle resize, rubber-band
/// marquee, inline label editing, grid/rulers, and keyboard delete/duplicate/undo. Mouse input
/// is handled at the canvas level (like the Mac's view-level state machine).</summary>
public sealed class DesignerCanvas : Canvas
{
    private const double OuterMargin = 28.0;
    private const double RulerHeight = 20.0;
    private const double SectionHeaderHeight = 24.0;
    private const double SectionResizeBarHeight = 7.0;
    private const double SectionGap = 12.0;
    private const double PaperWidth = 612.0;
    private const double LeftMargin = 18.0;
    private const double RightMargin = 18.0;

    private static readonly Brush LabelTint = new SolidColorBrush(Color.FromRgb(0xF7, 0xF7, 0xF7));
    private static readonly Brush DataFieldTint = new SolidColorBrush(Color.FromRgb(0xEA, 0xF4, 0xFF));
    private static readonly Brush AggregateTint = new SolidColorBrush(Color.FromRgb(0xEF, 0xF9, 0xEC));
    private static readonly Brush ImageTint = new SolidColorBrush(Color.FromRgb(0xFA, 0xF4, 0xE7));
    private static readonly Brush Accent = new SolidColorBrush(Color.FromRgb(0x0A, 0x84, 0xFF));

    private DesignerViewModel? _vm;
    private double _zoom = 1.0;
    private double _contentHeight;

    private readonly Dictionary<long, Border> _elementBorders = new();
    private readonly Dictionary<long, Rect> _elementRects = new();
    private readonly Dictionary<long, Rect> _bandRects = new();

    private enum DragMode { None, Move, Resize, Marquee }
    private DragMode _dragMode;
    private long _dragElementId;
    private int _dragHandle = -1;
    private Point _dragStartPt;
    private Rect _dragStartRect;
    private long _dragSourceSection;
    private long _dragHoverSection;
    private Rect _marqueeRect;
    private bool _dragMoved;
    private Rectangle? _marqueeVisual;

    public DesignerCanvas()
    {
        Focusable = true;
        ClipToBounds = true;
        Background = new SolidColorBrush(Color.FromRgb(0xE8, 0xE8, 0xE8));
    }

    public void Attach(DesignerViewModel vm)
    {
        if (ReferenceEquals(_vm, vm)) return;
        _vm = vm;
        vm.PropertyChanged += OnViewModelChanged;
        Rebuild();
    }

    private void OnViewModelChanged(object? sender, PropertyChangedEventArgs e)
    {
        if (e.PropertyName is nameof(DesignerViewModel.Model)
            or nameof(DesignerViewModel.Zoom)
            or nameof(DesignerViewModel.ShowGrid)
            or nameof(DesignerViewModel.ShowRulers)
            or nameof(DesignerViewModel.SelectedElementIds))
        {
            Rebuild();
        }
    }

    private void Rebuild()
    {
        Children.Clear();
        _elementBorders.Clear();
        _elementRects.Clear();
        _bandRects.Clear();

        if (_vm is not { HasDocument: true }) return;
        _zoom = _vm.Zoom;

        double y = OuterMargin + (_vm.ShowRulers ? RulerHeight + 6.0 : 0.0);
        foreach (var section in _vm.Sections)
        {
            double contentH = Math.Max(32.0, SectionContentHeight(section));
            double bandH = SectionHeaderHeight + contentH + SectionResizeBarHeight;
            _bandRects[section.Id] = new Rect(OuterMargin, y, PaperWidth, bandH);
            DrawBand(section, y, bandH, contentH);
            y += bandH + SectionGap;
        }

        _contentHeight = y + OuterMargin;
        Width = (PaperWidth + OuterMargin * 2.0) * _zoom;
        Height = Math.Max(420.0, _contentHeight) * _zoom;

        if (_vm.ShowGrid) DrawGrid();
        if (_vm.ShowRulers) DrawRuler();
    }

    private double SectionContentHeight(LayoutSection section)
    {
        double total = Math.Max(32.0, section.Height);
        foreach (var element in _vm!.Elements.Where(e => e.Section == section.Id))
        {
            total = Math.Max(total, element.Y + element.H + 6.0);
        }
        return total;
    }

    private void DrawBand(LayoutSection section, double y, double bandH, double contentH)
    {
        var band = new Border
        {
            Width = PaperWidth * _zoom,
            Height = bandH * _zoom,
            CornerRadius = new CornerRadius(4 * _zoom),
            Background = Brushes.White,
            BorderBrush = SystemColors.ActiveBorderBrush,
            BorderThickness = new Thickness(_zoom),
            Tag = section,
        };
        SetLeft(band, OuterMargin * _zoom);
        SetTop(band, y * _zoom);
        band.Child = new TextBlock
        {
            Text = $"{section.Title}  ·  {_vm!.Elements.Count(e => e.Section == section.Id)} items",
            FontSize = 11 * _zoom,
            Foreground = SystemColors.GrayTextBrush,
            Margin = new Thickness(10 * _zoom, 4 * _zoom, 0, 0),
            VerticalAlignment = VerticalAlignment.Top,
            HorizontalAlignment = HorizontalAlignment.Left,
        };
        Children.Add(band);

        double contentX = OuterMargin + LeftMargin;
        double contentY = y + SectionHeaderHeight;
        foreach (var element in _vm.Elements.Where(e => e.Section == section.Id))
        {
            DrawElement(element, contentX, contentY);
        }
    }

    private void DrawElement(LayoutElement element, double contentX, double contentY)
    {
        double ex = contentX + element.X;
        double ey = contentY + element.Y;
        _elementRects[element.Id] = new Rect(ex, ey, element.W, element.H);

        bool selected = _vm!.SelectedElementIds.Contains(element.Id);
        var border = new Border
        {
            Width = Math.Max(4, element.W) * _zoom,
            Height = Math.Max(4, element.H) * _zoom,
            Background = TintFor(element),
            BorderBrush = selected ? Accent : new SolidColorBrush(Color.FromArgb(0x66, 0x80, 0x80, 0x80)),
            BorderThickness = new Thickness((selected ? 1.5 : 0.75) * _zoom),
            Tag = element,
        };
        SetLeft(border, ex * _zoom);
        SetTop(border, ey * _zoom);

        if (element.IsLineRule)
        {
            border.Child = new Border
            {
                Background = new SolidColorBrush(Color.FromRgb(0x66, 0x66, 0x66)),
                Height = Math.Max(1.0, element.BorderBottom * _zoom),
                VerticalAlignment = VerticalAlignment.Bottom,
            };
        }
        else
        {
            border.Child = new TextBlock
            {
                Text = DisplayText(element),
                FontSize = Math.Max(8.0, Math.Min(48.0, element.FontSize)) * _zoom,
                Foreground = Brushes.Black,
                TextTrimming = TextTrimming.CharacterEllipsis,
                Margin = new Thickness(2 * _zoom, 1 * _zoom, 2 * _zoom, 1 * _zoom),
                VerticalAlignment = VerticalAlignment.Center,
            };
        }

        _elementBorders[element.Id] = border;
        Children.Add(border);

        if (selected && _vm.PrimaryElement?.Id == element.Id)
        {
            DrawResizeHandles(element, ex, ey);
        }
    }

    private void DrawResizeHandles(LayoutElement element, double ex, double ey)
    {
        double w = element.W, h = element.H;
        var corners = new (double x, double y)[]
        {
            (ex, ey), (ex + w / 2, ey), (ex + w, ey),
            (ex + w, ey + h / 2), (ex + w, ey + h),
            (ex + w / 2, ey + h), (ex, ey + h), (ex, ey + h / 2),
        };
        double hs = 6.0;
        for (int i = 0; i < corners.Length; i++)
        {
            var handle = new Rectangle
            {
                Width = hs * _zoom,
                Height = hs * _zoom,
                Fill = Brushes.White,
                Stroke = Accent,
                StrokeThickness = _zoom,
                Tag = i,
                IsHitTestVisible = false,
            };
            SetLeft(handle, (corners[i].x - hs / 2) * _zoom);
            SetTop(handle, (corners[i].y - hs / 2) * _zoom);
            Children.Add(handle);
        }
    }

    private void DrawGrid()
    {
        double spacing = DesignerViewModel.GridSpacing;
        var brush = new SolidColorBrush(Color.FromArgb(0x0B, 0x00, 0x00, 0x00));
        foreach (var section in _vm!.Sections)
        {
            var band = _bandRects[section.Id];
            double contentH = SectionContentHeight(section);
            double contentX = band.X + LeftMargin;
            double contentY = band.Y + SectionHeaderHeight;
            double contentW = PaperWidth - LeftMargin - RightMargin;
            for (double gx = spacing; gx < contentW; gx += spacing)
            {
                Children.Add(Line(contentX + gx, contentY, contentX + gx, contentY + contentH, brush));
            }
            for (double gy = spacing; gy < contentH; gy += spacing)
            {
                Children.Add(Line(contentX, contentY + gy, contentX + contentW, contentY + gy, brush));
            }
        }
    }

    private Line Line(double x1, double y1, double x2, double y2, Brush brush) => new()
    {
        X1 = x1 * _zoom, Y1 = y1 * _zoom, X2 = x2 * _zoom, Y2 = y2 * _zoom,
        Stroke = brush, StrokeThickness = 0.5 * _zoom, IsHitTestVisible = false,
    };

    private void DrawRuler()
    {
        var ruler = new Border
        {
            Width = PaperWidth * _zoom,
            Height = RulerHeight * _zoom,
            Background = Brushes.White,
            BorderBrush = SystemColors.ActiveBorderBrush,
            BorderThickness = new Thickness(0.6 * _zoom),
            IsHitTestVisible = false,
        };
        SetLeft(ruler, OuterMargin * _zoom);
        SetTop(ruler, OuterMargin * _zoom);
        Children.Add(ruler);
    }

    // ---- canvas-level mouse state machine ----

    private Point ToPt(Point p) => new(p.X / _zoom, p.Y / _zoom);

    protected override void OnMouseLeftButtonDown(MouseButtonEventArgs e)
    {
        base.OnMouseLeftButtonDown(e);
        Focus();
        var pt = ToPt(e.GetPosition(this));

        // 1. resize handle on the primary selected element
        if (_vm!.PrimaryElement is { } primary && _vm.SelectedElementIds.Count == 1)
        {
            int handle = HitTestHandle(pt, primary);
            if (handle >= 0)
            {
                _dragMode = DragMode.Resize;
                _dragElementId = primary.Id;
                _dragHandle = handle;
                _dragStartPt = pt;
                _dragStartRect = _elementRects[primary.Id];
                _dragSourceSection = primary.Section;
                _dragMoved = false;
                CaptureMouse();
                e.Handled = true;
                return;
            }
        }

        // 2. element hit
        long elementId = ElementAt(pt);
        if (elementId != 0)
        {
            var element = _vm.Elements.First(el => el.Id == elementId);
            if (e.ClickCount == 2 && element is { IsLabel: true } or { IsDataField: true })
            {
                _vm.SelectElement(elementId, extend: false);
                BeginInlineEdit(elementId);
                e.Handled = true;
                return;
            }

            _vm.SelectElement(elementId, Keyboard.Modifiers.HasFlag(ModifierKeys.Shift));
            _dragMode = DragMode.Move;
            _dragElementId = elementId;
            _dragStartPt = pt;
            _dragStartRect = _elementRects[elementId];
            _dragSourceSection = element.Section;
            _dragHoverSection = element.Section;
            _dragMoved = false;
            CaptureMouse();
            e.Handled = true;
            return;
        }

        // 3. band header (or anywhere on a band) hit -> select the section
        long sectionId = SectionAt(pt);
        if (sectionId != 0)
        {
            _vm.SelectSection(sectionId);
            _vm.ClearElementSelection();
            e.Handled = true;
            return;
        }

        // 4. empty canvas -> marquee
        _vm.ClearElementSelection();
        _dragMode = DragMode.Marquee;
        _dragStartPt = pt;
        _marqueeRect = Rect.Empty;
        _dragMoved = false;
        CaptureMouse();
        e.Handled = true;
    }

    protected override void OnMouseMove(MouseEventArgs e)
    {
        base.OnMouseMove(e);
        if (_dragMode == DragMode.None) return;
        var pt = ToPt(e.GetPosition(this));
        double dx = pt.X - _dragStartPt.X;
        double dy = pt.Y - _dragStartPt.Y;
        if (!_dragMoved && Math.Abs(dx) + Math.Abs(dy) < 1.5) return;
        _dragMoved = true;

        if (_dragMode == DragMode.Move)
        {
            double nx = _dragStartRect.X + dx;
            double ny = _dragStartRect.Y + dy;
            (nx, ny) = SnapToGuides(nx, ny);
            var border = _elementBorders[_dragElementId];
            SetLeft(border, nx * _zoom);
            SetTop(border, ny * _zoom);
            _elementRects[_dragElementId] = new Rect(nx, ny, _dragStartRect.Width, _dragStartRect.Height);
            _dragHoverSection = SectionAt(pt);
        }
        else if (_dragMode == DragMode.Resize)
        {
            var r = ResizeRect(_dragStartRect, _dragHandle, dx, dy);
            var border = _elementBorders[_dragElementId];
            border.Width = r.Width * _zoom;
            border.Height = r.Height * _zoom;
            SetLeft(border, r.X * _zoom);
            SetTop(border, r.Y * _zoom);
            _elementRects[_dragElementId] = r;
        }
        else if (_dragMode == DragMode.Marquee)
        {
            _marqueeRect = new Rect(
                Math.Min(_dragStartPt.X, pt.X), Math.Min(_dragStartPt.Y, pt.Y),
                Math.Abs(pt.X - _dragStartPt.X), Math.Abs(pt.Y - _dragStartPt.Y));
            UpdateMarqueeVisual();
        }
    }

    protected override void OnMouseLeftButtonUp(MouseButtonEventArgs e)
    {
        base.OnMouseLeftButtonUp(e);
        if (_dragMode == DragMode.None) return;
        var mode = _dragMode;
        _dragMode = DragMode.None;
        ReleaseMouseCapture();
        RemoveMarqueeVisual();

        if (mode == DragMode.Marquee)
        {
            if (_dragMoved)
            {
                foreach (var (id, rect) in _elementRects)
                {
                    if (_marqueeRect.IntersectsWith(rect))
                    {
                        _vm!.SelectElement(id, extend: true);
                    }
                }
            }
            return;
        }

        if (!_dragMoved || _vm == null) return;
        var movedRect = _elementRects[_dragElementId];

        if (mode == DragMode.Move && _dragHoverSection != 0 && _dragHoverSection != _dragSourceSection)
        {
            var target = _vm.Sections.FirstOrDefault(s => s.Id == _dragHoverSection);
            if (target != null)
            {
                var content = ContentOrigin(target);
                double nx = Math.Max(0, movedRect.X - content.X);
                double ny = Math.Max(0, movedRect.Y - content.Y);
                _ = _vm.MoveElementToSectionAsync(_dragElementId, _dragHoverSection, nx, ny);
            }
        }
        else
        {
            double mx = Math.Max(0, movedRect.X - (OuterMargin + LeftMargin));
            double my = Math.Max(0, movedRect.Y - ContentOriginY(_dragSourceSection));
            _ = _vm.SetElementGeometryAsync(new[] { new ElementGeometry(_dragElementId, mx, my, movedRect.Width, movedRect.Height) });
        }
    }

    private void UpdateMarqueeVisual()
    {
        if (_marqueeVisual == null)
        {
            _marqueeVisual = new Rectangle
            {
                Fill = new SolidColorBrush(Color.FromArgb(0x1E, 0x0A, 0x84, 0xFF)),
                Stroke = Accent,
                StrokeThickness = 1,
                IsHitTestVisible = false,
            };
            Children.Add(_marqueeVisual);
        }
        _marqueeVisual.Width = _marqueeRect.Width * _zoom;
        _marqueeVisual.Height = _marqueeRect.Height * _zoom;
        SetLeft(_marqueeVisual, _marqueeRect.X * _zoom);
        SetTop(_marqueeVisual, _marqueeRect.Y * _zoom);
    }

    private void RemoveMarqueeVisual()
    {
        if (_marqueeVisual != null)
        {
            Children.Remove(_marqueeVisual);
            _marqueeVisual = null;
        }
    }

    private long ElementAt(Point pt)
    {
        foreach (var (id, rect) in _elementRects.Reverse())
        {
            if (rect.Contains(pt)) return id;
        }
        return 0;
    }

    private long SectionAt(Point pt)
    {
        foreach (var (id, rect) in _bandRects)
        {
            if (rect.Contains(pt)) return id;
        }
        // A point in the gap just below a band also targets that band (the Mac's nearest-section fallback).
        foreach (var (id, rect) in _bandRects)
        {
            if (pt.X >= rect.X && pt.X <= rect.Right && pt.Y >= rect.Bottom && pt.Y <= rect.Bottom + SectionGap)
            {
                return id;
            }
        }
        return 0;
    }

    private int HitTestHandle(Point pt, LayoutElement element)
    {
        var rect = _elementRects[element.Id];
        double w = rect.Width, h = rect.Height;
        double hs = 6.0;
        var corners = new (double x, double y)[]
        {
            (rect.Left, rect.Top), (rect.Left + w / 2, rect.Top), (rect.Right, rect.Top),
            (rect.Right, rect.Top + h / 2), (rect.Right, rect.Bottom),
            (rect.Left + w / 2, rect.Bottom), (rect.Left, rect.Bottom), (rect.Left, rect.Top + h / 2),
        };
        for (int i = 0; i < corners.Length; i++)
        {
            var hr = new Rect(corners[i].x - hs, corners[i].y - hs, hs * 2, hs * 2);
            if (hr.Contains(pt)) return i;
        }
        return -1;
    }

    private double ContentOriginY(long sectionId)
    {
        var band = _bandRects[sectionId];
        return band.Y + SectionHeaderHeight;
    }

    private Point ContentOrigin(LayoutSection section)
    {
        var band = _bandRects[section.Id];
        return new Point(band.X + LeftMargin, band.Y + SectionHeaderHeight);
    }

    private (double x, double y) SnapToGuides(double x, double y)
    {
        double w = _dragStartRect.Width, h = _dragStartRect.Height;
        const double threshold = 4.5;

        // Snap content-relative so snapped elements sit on the per-section grid and align with
        // the client-side NextAvailableOrigin placement.
        if (_vm!.SnapToGrid)
        {
            double originX = OuterMargin + LeftMargin;
            double originY = ContentOriginY(_dragSourceSection);
            double s = DesignerViewModel.GridSpacing;
            x = originX + Math.Round((x - originX) / s) * s;
            y = originY + Math.Round((y - originY) / s) * s;
        }

        double bestX = threshold, bestY = threshold;
        foreach (var (id, r) in _elementRects)
        {
            if (id == _dragElementId) continue;
            foreach (double otherX in new[] { r.Left, r.Left + r.Width / 2, r.Right })
            {
                foreach (double candX in new[] { x, x + w / 2, x + w })
                {
                    double d = Math.Abs(candX - otherX);
                    if (d < bestX) { bestX = d; x = otherX - (candX - x); }
                }
            }
            foreach (double otherY in new[] { r.Top, r.Top + r.Height / 2, r.Bottom })
            {
                foreach (double candY in new[] { y, y + h / 2, y + h })
                {
                    double d = Math.Abs(candY - otherY);
                    if (d < bestY) { bestY = d; y = otherY - (candY - y); }
                }
            }
        }
        return (x, y);
    }

    private static Rect ResizeRect(Rect r, int handle, double dx, double dy)
    {
        double left = r.Left, top = r.Top, right = r.Right, bottom = r.Bottom;
        const double minW = 20, minH = 12;
        if (handle is 0 or 6 or 7) left = Math.Min(right - minW, left + dx);
        if (handle is 2 or 3 or 4) right = Math.Max(left + minW, right + dx);
        if (handle is 0 or 1 or 2) top = Math.Min(bottom - minH, top + dy);
        if (handle is 4 or 5 or 6) bottom = Math.Max(top + minH, bottom + dy);
        return new Rect(left, top, Math.Max(minW, right - left), Math.Max(minH, bottom - top));
    }

    protected override void OnKeyDown(KeyEventArgs e)
    {
        base.OnKeyDown(e);
        if (_vm == null) return;

        if (e.Key == Key.Delete && _vm.SelectedElementIds.Count > 0)
        {
            _ = _vm.RemoveElementsAsync(_vm.SelectedElementIds.ToList());
            _vm.ClearElementSelection();
            e.Handled = true;
        }
        else if (e.Key == Key.D && Keyboard.Modifiers.HasFlag(ModifierKeys.Control))
        {
            _ = _vm.DuplicateElementsAsync(_vm.SelectedElementIds.ToList());
            e.Handled = true;
        }
        else if (e.Key == Key.Z && Keyboard.Modifiers.HasFlag(ModifierKeys.Control))
        {
            _ = _vm.UndoAsync();
            e.Handled = true;
        }
        else if (e.Key == Key.Y && Keyboard.Modifiers.HasFlag(ModifierKeys.Control))
        {
            _ = _vm.RedoAsync();
            e.Handled = true;
        }
        else if (e.Key is Key.Left or Key.Right or Key.Up or Key.Down && _vm.SelectedElementIds.Count > 0)
        {
            double step = Keyboard.Modifiers.HasFlag(ModifierKeys.Shift) ? 10 : 1;
            double dx = e.Key == Key.Left ? -step : e.Key == Key.Right ? step : 0;
            double dy = e.Key == Key.Up ? -step : e.Key == Key.Down ? step : 0;
            if (dx != 0 || dy != 0)
            {
                var geometries = _vm.SelectedElementIds
                    .Select(id => _vm.Elements.FirstOrDefault(el => el.Id == id))
                    .Where(el => el != null)
                    .Select(el => new ElementGeometry(el!.Id, Math.Max(0, el.X + dx), Math.Max(0, el.Y + dy), el.W, el.H))
                    .ToList();
                _ = _vm.SetElementGeometryAsync(geometries);
                e.Handled = true;
            }
        }
    }

    private void BeginInlineEdit(long elementId)
    {
        var element = _vm!.Elements.FirstOrDefault(el => el.Id == elementId);
        if (element is not { IsLabel: true } && element is not { IsDataField: true }) return;

        var rect = _elementRects[elementId];
        var editor = new TextBox
        {
            Text = element.Text,
            FontSize = Math.Max(11.0, element.FontSize * _zoom),
            Background = Brushes.White,
            BorderBrush = Accent,
            BorderThickness = new Thickness(1),
            Width = Math.Max(60, rect.Width * _zoom),
            Height = Math.Max(20, rect.Height * _zoom),
            Tag = elementId,
        };
        SetLeft(editor, rect.X * _zoom);
        SetTop(editor, rect.Y * _zoom);
        editor.KeyDown += async (_, e) =>
        {
            if (e.Key == Key.Enter)
            {
                Children.Remove(editor);
                await _vm.SetElementContentAsync(elementId, new ElementContent(Text: editor.Text));
            }
            else if (e.Key == Key.Escape)
            {
                Children.Remove(editor);
            }
        };
        editor.LostKeyboardFocus += (_, _) => Children.Remove(editor);
        Children.Add(editor);
        editor.Focus();
        editor.SelectAll();
    }

    private static Brush TintFor(LayoutElement element)
        => element.IsDataField ? DataFieldTint
            : element.IsAggregate ? AggregateTint
            : element.IsImage ? ImageTint
            : LabelTint;

    private static string DisplayText(LayoutElement element)
    {
        if (element.IsLineRule) return "";
        if (element.IsLabel) return string.IsNullOrEmpty(element.Text) ? "Static Label" : element.Text;
        if (element.IsDataField) return string.IsNullOrEmpty(element.Text) ? "[Data Field]" : element.Text;
        if (element.IsAggregate) return AggregateDisplay(element);
        if (element.IsImage) return "[Image]";
        return "Element";
    }

    private static string AggregateDisplay(LayoutElement element)
    {
        string function = element.Function switch
        {
            AggregateFunction.Sum => "SUM",
            AggregateFunction.Mean => "MEAN",
            AggregateFunction.Count => "COUNT",
            AggregateFunction.First => "FIRST",
            AggregateFunction.Last => "LAST",
            AggregateFunction.Min => "MIN",
            AggregateFunction.Max => "MAX",
            _ => "AGG",
        };
        return string.IsNullOrEmpty(element.Column) ? $"{function}(...)" : $"{function}({element.Column})";
    }
}
