//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using Mad.Designer.Windows.Infrastructure;
using Mad.Designer.Windows.Models;
using Mad.Designer.Windows.ViewModels;

namespace Mad.Designer.Windows.Views;

public partial class DesignerView : UserControl
{
    private DesignerViewModel? _designer;

    public DesignerView()
    {
        InitializeComponent();
        DataContextChanged += OnDataContextChanged;
    }

    private void OnDataContextChanged(object sender, DependencyPropertyChangedEventArgs e)
    {
        // The window's view model owns the document; the designer workspace lives inside it.
        if (e.NewValue is MainWindowViewModel windowViewModel)
        {
            AttachDesigner(windowViewModel.Document.Designer);
        }
    }

    private void AttachDesigner(DesignerViewModel designer)
    {
        if (ReferenceEquals(_designer, designer)) return;
        _designer = designer;
        Canvas.Attach(designer);
        Minimap.Attach(designer);
    }

    private async void SectionsList_OnDoubleClick(object sender, MouseButtonEventArgs e)
    {
        if (_designer != null && SectionsList.SelectedItem is LayoutSection section)
        {
            await _designer.ToggleSectionVisibilityAsync(section.Id);
        }
    }

    /// <summary>Prepares the band context menu for the band under the pointer. Right-clicking a
    /// band selects it (in the list and in the inspector), and the visibility item's label
    /// follows the band's current state. Right-clicking empty space closes the menu.</summary>
    private void SectionsList_OnContextMenuOpening(object sender, ContextMenuEventArgs e)
    {
        if (ItemsControl.ContainerFromElement(SectionsList, e.OriginalSource as DependencyObject)
            is not ListBoxItem item || item.DataContext is not LayoutSection section)
        {
            e.Handled = true;
            return;
        }

        SectionsList.SelectedItem = section;
        _designer?.SelectSection(section.Id);
        ToggleSectionVisibilityItem.Header =
            Localizer.Get(section.Visible ? "Designer.Section.Hide" : "Designer.Section.Show");
    }

    private void SelectSection_OnClick(object sender, RoutedEventArgs e)
    {
        if (_designer != null && SectionsList.SelectedItem is LayoutSection section)
        {
            _designer.SelectSection(section.Id);
        }
    }

    private async void ToggleSectionVisibility_OnClick(object sender, RoutedEventArgs e)
    {
        if (_designer != null && SectionsList.SelectedItem is LayoutSection section)
        {
            await _designer.ToggleSectionVisibilityAsync(section.Id);
        }
    }

    private async void FieldsList_OnDoubleClick(object sender, MouseButtonEventArgs e)
    {
        if (_designer != null && FieldsList.SelectedItem is LayoutField field)
        {
            await _designer.InsertDataFieldAsync(field.Id);
        }
    }

    private async void ChooseImage_OnClick(object sender, RoutedEventArgs e)
    {
        if (_designer?.PrimaryElement is not { IsImage: true } element) return;

        var dialog = new Microsoft.Win32.OpenFileDialog
        {
            Filter = Localizer.Get("Designer.Image.Filter"),
            CheckFileExists = true,
            Multiselect = false,
        };
        if (dialog.ShowDialog() != true) return;

        try
        {
            // The engine's image column holds PNG; re-encode whatever was chosen.
            byte[] png = ImageFileEncoder.ReadPng(dialog.FileName);
            await _designer.SetImageDataAsync(element.Id, png);
        }
        catch (Exception exception)
        {
            _designer.ReportError(exception.Message);
        }
    }
}
