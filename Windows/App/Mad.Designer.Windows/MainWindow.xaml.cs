//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

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
            editConnection: () => OpenConnectionWindow(true),
            recentFiles: _recentFiles.Get(),
            saveAsPath: ShowSaveDocumentDialog,
            credentials: _credentials,
            persistRecent: _recentFiles.Add);
        DataContext = _viewModel;
        WindowSizing.FitToWorkArea(this);
    }

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
