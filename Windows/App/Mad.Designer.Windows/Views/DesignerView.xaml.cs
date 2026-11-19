//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using System.Windows;
using System.Windows.Controls;
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
    }
}
