//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using Mad.Designer.Windows.Models;
using Mad.Designer.Windows.ViewModels;

namespace Mad.Designer.Windows.Views;

public partial class QueryView : UserControl
{
    private QueryViewModel? _query;

    public QueryView()
    {
        InitializeComponent();
        DataContextChanged += OnDataContextChanged;
    }

    private void OnDataContextChanged(object sender, DependencyPropertyChangedEventArgs e)
    {
        // The window's view model owns the document; the query workspace lives inside it.
        if (e.NewValue is MainWindowViewModel windowViewModel)
        {
            AttachQuery(windowViewModel.Document.Query);
        }
    }

    private void AttachQuery(QueryViewModel query)
    {
        if (ReferenceEquals(_query, query)) return;
        _query = query;
        Canvas.Attach(query);
    }

    private async void SchemaList_OnDoubleClick(object sender, MouseButtonEventArgs e)
    {
        if (_query != null && SchemaList.SelectedItem is SchemaTable table)
        {
            await _query.AddTableAsync(table.Name);
        }
    }

    private void ToggleFilters(object sender, RoutedEventArgs e)
    {
        FiltersPopup.PlacementTarget = sender as UIElement;
        FiltersPopup.IsOpen = !FiltersPopup.IsOpen;
    }

    private void ToggleGroups(object sender, RoutedEventArgs e)
    {
        GroupsPopup.PlacementTarget = sender as UIElement;
        GroupsPopup.IsOpen = !GroupsPopup.IsOpen;
    }
}
