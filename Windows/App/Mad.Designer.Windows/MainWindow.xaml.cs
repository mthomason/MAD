//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using System.ComponentModel;
using System.IO;
using System.Windows;
using Mad.Designer.Windows.Engine;
using Mad.Designer.Windows.Infrastructure;
using Mad.Designer.Windows.Models;
using Mad.Designer.Windows.ViewModels;
using Mad.Designer.Windows.Views;

namespace Mad.Designer.Windows;

public partial class MainWindow : Window
{
    private readonly EngineService _engine = new();
    private readonly ICredentialStore _credentials = new WindowsCredentialStore();
    private readonly RecentFilesService _recentFiles = new();
    private readonly MainWindowViewModel _viewModel;

    public MainWindow()
    {
        InitializeComponent();
        _viewModel = new MainWindowViewModel(
            _engine,
            openAbout: OpenAboutWindow,
            exportPath: ShowExportSaveDialog,
            newDocument: () => OpenConnectionWindow(false),
            newComposition: NewComposition,
            editConnection: () => OpenConnectionWindow(true),
            importChild: ImportChild,
            recentFiles: _recentFiles.Get(),
            saveAsPath: ShowSaveDocumentDialog,
            credentials: _credentials,
            persistRecent: _recentFiles.Add);
        DataContext = _viewModel;
        _viewModel.Document.PropertyChanged += OnDocumentPropertyChanged;
        _viewModel.Document.Composition.PropertyChanged += OnCompositionPropertyChanged;
        ApplyCompositionLayout();
        WindowSizing.FitToWorkArea(this);
    }

    private const double CompositionDockedWidth = 300.0;
    private double _dockedCompositionWidth = CompositionDockedWidth;

    /// <summary>The Composition pane is absent for a Standard Report, docked at a sensible
    /// width for a composition, and takes the content area when expanded.</summary>
    private void ApplyCompositionLayout()
    {
        bool composed = _viewModel.Document.HasDocument && _viewModel.Document.IsComposed;
        if (!composed)
        {
            CompositionColumn.Width = new GridLength(0);
            CompositionSplitterColumn.Width = new GridLength(0);
            WorkspaceColumn.Width = new GridLength(1, GridUnitType.Star);
            return;
        }

        if (_viewModel.Document.Composition.IsExpanded)
        {
            if (CompositionColumn.ActualWidth > 0) _dockedCompositionWidth = CompositionColumn.ActualWidth;
            CompositionColumn.Width = new GridLength(1, GridUnitType.Star);
            CompositionSplitterColumn.Width = new GridLength(0);
            WorkspaceColumn.Width = new GridLength(0);
        }
        else
        {
            CompositionColumn.Width = new GridLength(Math.Max(240, _dockedCompositionWidth));
            CompositionSplitterColumn.Width = new GridLength(5);
            WorkspaceColumn.Width = new GridLength(1, GridUnitType.Star);
        }
    }

    private void OnDocumentPropertyChanged(object? sender, PropertyChangedEventArgs e)
    {
        if (e.PropertyName is not (nameof(DocumentViewModel.IsComposed) or nameof(DocumentViewModel.HasDocument)))
        {
            return;
        }
        if (!_viewModel.Document.IsComposed)
        {
            _viewModel.Document.Composition.Collapse();
        }
        ApplyCompositionLayout();
    }

    private void OnCompositionPropertyChanged(object? sender, PropertyChangedEventArgs e)
    {
        if (e.PropertyName == nameof(CompositionViewModel.IsExpanded)) ApplyCompositionLayout();
    }

    private void CompositionExpand_Click(object sender, RoutedEventArgs e)
        => _viewModel.Document.Composition.ToggleExpanded();

    private async void OpenAboutWindow()
    {
        // Ask the engine this app launched for its identity.  A null answer -- an older
        // engine, an engine that failed to start -- makes the About line read "unknown".
        var engine = await _engine.EngineInfoAsync();
        var window = new AboutWindow
        {
            DataContext = new AboutViewModel(BuildInfo.Load(), engine),
            Owner = this,
        };
        window.Show();
    }

    /// <summary>The save dialog for the Viewer's export format selector. The extension comes
    /// from the same catalogue the view model exports with, so the dialog and the engine
    /// cannot disagree about a format's file type.</summary>
    private string? ShowExportSaveDialog(string format)
    {
        var metadata = ViewerViewModel.ExportFormats.FirstOrDefault(f => f.Format == format);
        string extension = metadata?.Extension ?? "txt";

        string stem = Path.GetFileNameWithoutExtension(_viewModel.Document.FileName);
        if (string.IsNullOrEmpty(stem)) stem = Localizer.Get("Dialog.DefaultReport");

        var dialog = new Microsoft.Win32.SaveFileDialog
        {
            Filter = Localizer.Format("Dialog.ReportFilter", extension),
            DefaultExt = extension,
            AddExtension = true,
            FileName = $"{stem}.{extension}",
        };
        return dialog.ShowDialog() == true ? dialog.FileName : null;
    }

    private string? ShowSaveDocumentDialog()
    {
        var dialog = new Microsoft.Win32.SaveFileDialog
        {
            Filter = Localizer.Get("Dialog.SaveMadFilter"),
            FileName = Localizer.Get("Dialog.DefaultReportFile"),
        };
        return dialog.ShowDialog() == true ? dialog.FileName : null;
    }

    private async Task OpenPathAsync(string path)
    {
        await _viewModel.OpenPathAsync(path);
    }

    /// <summary>File ▸ New Composition…: creates an empty composition (a root, no children),
    /// then opens it in the Query workspace so the author can add sources and join them.</summary>
    private async void NewComposition()
    {
        var dialog = new Microsoft.Win32.SaveFileDialog
        {
            Filter = Localizer.Get("Dialog.SaveMadFilter"),
            FileName = Localizer.Get("Dialog.DefaultReportFile"),
        };
        if (dialog.ShowDialog() != true) return;

        try
        {
            OpenResult created = await _engine.CreateEmptyAsync(dialog.FileName);
            await _engine.AddRootAsync(created.Handle, "root");
            await _viewModel.AdoptCreatedAsync(created, dialog.FileName);
        }
        catch (Exception exception)
        {
            _viewModel.Document.ReportFailure(exception.Message);
        }
    }

    /// <summary>File ▸ Import…: imports an existing .mad as a child of the composed root.</summary>
    private async void ImportChild()
    {
        var dialog = new Microsoft.Win32.OpenFileDialog
        {
            Filter = Localizer.Get("Dialog.OpenMadFilter"),
        };
        if (dialog.ShowDialog() != true) return;

        await _viewModel.Document.ImportChildAsync(dialog.FileName);
    }

    /// <summary>Opens the connection assistant in create mode (New Document) or edit mode
    /// (Database Connection…), and adopts the result back into the open document.</summary>
    private async void OpenConnectionWindow(bool isEdit)
    {
        try
        {
            ConnectionSpec? initial = null;
            if (isEdit)
            {
                initial = await _viewModel.Document.GetConnectionAsync();
                if (initial == null)
                {
                    return; // no document is open
                }
            }

            var window = new ConnectionWindow(_engine, _credentials, isEdit, initial) { Owner = this };
            window.ShowDialog();

            if (isEdit)
            {
                if (window.ViewModel.Submitted && window.ViewModel.ResultSpec is ConnectionSpec spec)
                {
                    await _viewModel.Document.ApplyConnectionAsync(spec);
                }
            }
            else if (window.ViewModel.Created is OpenResult created && window.ViewModel.CreatePath is string path)
            {
                await _viewModel.AdoptCreatedAsync(created, path);
            }
        }
        catch (Exception exception)
        {
            _viewModel.Document.ReportFailure(exception.Message);
        }
    }

    protected override void OnContentRendered(EventArgs e)
    {
        base.OnContentRendered(e);

        // Launch into the empty main window; open a document only when one was
        // passed on the command line (double-click association). No auto-open, no
        // file dialog.
        string? document = FindCommandLineDocument();
        if (document != null)
        {
            _ = OpenPathAsync(document);
        }
    }

    private static string? FindCommandLineDocument()
    {
        string[] args = Environment.GetCommandLineArgs();
        for (int i = 1; i < args.Length; i++)
        {
            if (args[i].EndsWith(".mad", StringComparison.OrdinalIgnoreCase))
            {
                return args[i];
            }
        }
        return null;
    }

    private void Exit_Click(object sender, RoutedEventArgs e) => Close();

    protected override void OnClosed(EventArgs e)
    {
        base.OnClosed(e);
        _engine.DisposeAsync().GetAwaiter().GetResult();
    }
}
