//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using System.ComponentModel;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using Mad.Designer.Windows.Models;
using Mad.Designer.Windows.ViewModels;

namespace Mad.Designer.Windows.Views;

/// <summary>The MAD Designer canvas: a zoomable, scrollable WPF drawing of the report's paper
/// bands and placed elements. It rebuilds itself from the <see cref="DesignerViewModel"/>'s
/// snapshot. This is the WPF counterpart of the Mac's <c>MADMacDesignerCanvasView</c>.</summary>
public sealed class DesignerCanvas : Canvas
{
    private const double OuterMargin = 28.0;
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

    private DesignerViewModel? _vm;

    public void Attach(DesignerViewModel vm)
    {
        _vm = vm;
        vm.PropertyChanged += OnViewModelChanged;
        Rebuild();
    }

    private void OnViewModelChanged(object? sender, PropertyChangedEventArgs e)
    {
        if (e.PropertyName == nameof(DesignerViewModel.Model))
        {
            Rebuild();
        }
    }

    private void Rebuild()
    {
        Children.Clear();
        if (_vm is not { HasDocument: true }) return;

        double y = OuterMargin;
        foreach (var section in _vm.Sections)
        {
            double contentH = ContentHeight(section);
            double bandH = SectionHeaderHeight + contentH + SectionResizeBarHeight;
            DrawBand(section, OuterMargin, y, contentH, bandH);
            y += bandH + SectionGap;
        }

        Width = PaperWidth + OuterMargin * 2.0;
        Height = Math.Max(420.0, y + OuterMargin);
    }

    private void DrawBand(LayoutSection section, double x, double y, double contentH, double bandH)
    {
        var band = new Border
        {
            Width = PaperWidth,
            Height = bandH,
            CornerRadius = new CornerRadius(4),
            Background = Brushes.White,
            BorderBrush = SystemColors.ActiveBorderBrush,
            BorderThickness = new Thickness(1),
            Tag = section,
        };
        SetLeft(band, x);
        SetTop(band, y);

        band.Child = new TextBlock
        {
            Text = $"{section.Title}  ·  {ElementCount(section)} items  ·  {contentH:0}pt",
            FontSize = 11,
            Foreground = SystemColors.GrayTextBrush,
            Margin = new Thickness(10, 4, 0, 0),
            VerticalAlignment = VerticalAlignment.Top,
            HorizontalAlignment = HorizontalAlignment.Left,
        };
        Children.Add(band);

        foreach (var element in ElementsInSection(section))
        {
            DrawElement(element, x + LeftMargin, y + SectionHeaderHeight);
        }
    }

    private void DrawElement(LayoutElement element, double contentX, double contentY)
    {
        var border = new Border
        {
            Width = Math.Max(4, element.W),
            Height = Math.Max(4, element.H),
            Background = TintFor(element),
            BorderBrush = new SolidColorBrush(Color.FromArgb(0x66, 0x80, 0x80, 0x80)),
            BorderThickness = new Thickness(0.75),
            Tag = element,
        };
        SetLeft(border, contentX + element.X);
        SetTop(border, contentY + element.Y);

        border.Child = new TextBlock
        {
            Text = DisplayText(element),
            FontSize = Math.Max(8.0, Math.Min(48.0, element.FontSize)),
            Foreground = Brushes.Black,
            TextTrimming = TextTrimming.CharacterEllipsis,
            Margin = new Thickness(2, 1, 2, 1),
            VerticalAlignment = VerticalAlignment.Center,
        };
        Children.Add(border);
    }

    private double ContentHeight(LayoutSection section)
    {
        double total = Math.Max(32.0, section.Height);
        foreach (var element in ElementsInSection(section))
        {
            total = Math.Max(total, element.Y + element.H + 6.0);
        }
        return total;
    }

    private int ElementCount(LayoutSection section) => ElementsInSection(section).Count();

    private IEnumerable<LayoutElement> ElementsInSection(LayoutSection section)
        => _vm!.Elements.Where(e => e.Section == section.Id);

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
