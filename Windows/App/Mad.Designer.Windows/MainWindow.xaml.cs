//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using System.Windows;
using Mad.Designer.Windows.Engine;
using Mad.Designer.Windows.ViewModels;
using Mad.Designer.Windows.Views;

namespace Mad.Designer.Windows;

public partial class MainWindow : Window
{
    private readonly EngineService _engine = new();
    private readonly MainWindowViewModel _viewModel;

    public MainWindow()
    {
        InitializeComponent();
        _viewModel = new MainWindowViewModel(_engine, openAbout: OpenAboutWindow);
        DataContext = _viewModel;
    }

    private void OpenAboutWindow()
    {
        var window = new AboutWindow { DataContext = new AboutViewModel(), Owner = this };
        window.Show();
    }

    protected override void OnContentRendered(EventArgs e)
    {
        base.OnContentRendered(e);
        _ = _viewModel.InitializeAsync();
    }

    protected override void OnClosed(EventArgs e)
    {
        base.OnClosed(e);
        _engine.DisposeAsync().GetAwaiter().GetResult();
    }
}
