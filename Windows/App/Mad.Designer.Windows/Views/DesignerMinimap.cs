//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using System.ComponentModel;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;
using Mad.Designer.Windows.Infrastructure;
using Mad.Designer.Windows.Models;
using Mad.Designer.Windows.ViewModels;

namespace Mad.Designer.Windows.Views;

/// <summary>An interactive miniature overview of the report page: the section bands and their
/// elements, scaled to fit. Clicking (or dragging across) a band selects it. This is the WPF
/// counterpart of the Mac's <c>MADMacDesignerMinimapView</c>.</summary>
public sealed class DesignerMinimap : Canvas
{
    private const double OuterMargin = 28.0;
    private const double SectionHeaderHeight = 24.0;
    private const double SectionResizeBarHeight = 7.0;
    private const double SectionGap = 12.0;
    private const double PaperWidth = 612.0;

    private DesignerViewModel? _vm;
    private double _scale;
    private double _offsetX;
    private double _offsetY;

    public DesignerMinimap()
    {
        SizeChanged += (_, _) => Rebuild();
    }

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

        double totalH = ComputeTotalHeight();
        double availableW = Math.Max(1.0, ActualWidth - 12.0);
        double availableH = Math.Max(1.0, ActualHeight - 12.0);
        _scale = Math.Min(availableW / PaperWidth, availableH / totalH);
        _offsetX = 6.0;
        _offsetY = 6.0;

        double y = OuterMargin;
        foreach (var section in _vm.Sections)
        {
            double contentH = Math.Max(32.0, section.Height);
            double bandH = SectionHeaderHeight + contentH + SectionResizeBarHeight;
            DrawBand(section, y, bandH, contentH);
            y += bandH + SectionGap;
        }
    }

    private void DrawBand(LayoutSection section, double y, double bandH, double contentH)
    {
        var band = new Border
        {
            Width = PaperWidth * _scale,
            Height = Math.Max(3.0, bandH * _scale),
            Background = section.Visible ? DesignPalette.MinimapBand : DesignPalette.MinimapHiddenBand,
            BorderBrush = SystemColors.ActiveBorderBrush,
            BorderThickness = new Thickness(0.6),
            Tag = section,
        };
        SetLeft(band, _offsetX);
        SetTop(band, _offsetY + y * _scale);
        Children.Add(band);

        double contentX = OuterMargin + 18.0;
        double contentY = y + SectionHeaderHeight;
        foreach (var element in _vm!.Elements.Where(e => e.Section == section.Id))
        {
            var el = new Border
            {
                Width = Math.Max(2.0, element.W * _scale),
                Height = Math.Max(1.5, element.H * _scale),
                Background = DesignPalette.MinimapElement,
                Tag = element,
            };
            SetLeft(el, _offsetX + (contentX + element.X) * _scale);
            SetTop(el, _offsetY + (contentY + element.Y) * _scale);
            Children.Add(el);
        }
    }

    private double ComputeTotalHeight()
    {
        double y = OuterMargin;
        foreach (var section in _vm!.Sections)
        {
            double contentH = Math.Max(32.0, section.Height);
            y += SectionHeaderHeight + contentH + SectionResizeBarHeight + SectionGap;
        }
        return y + OuterMargin;
    }

    protected override void OnMouseLeftButtonDown(MouseButtonEventArgs e)
    {
        base.OnMouseLeftButtonDown(e);
        SelectAt(e.GetPosition(this));
    }

    protected override void OnMouseMove(MouseEventArgs e)
    {
        base.OnMouseMove(e);
        if (e.LeftButton == MouseButtonState.Pressed)
        {
            SelectAt(e.GetPosition(this));
        }
    }

    private void SelectAt(Point point)
    {
        if (_vm == null || _scale <= 0.0) return;
        double canvasY = (point.Y - _offsetY) / _scale;

        double y = OuterMargin;
        foreach (var section in _vm.Sections)
        {
            double contentH = Math.Max(32.0, section.Height);
            double bandH = SectionHeaderHeight + contentH + SectionResizeBarHeight;
            if (canvasY >= y && canvasY <= y + bandH)
            {
                _vm.SelectSection(section.Id);
                break;
            }
            y += bandH + SectionGap;
        }
    }
}
