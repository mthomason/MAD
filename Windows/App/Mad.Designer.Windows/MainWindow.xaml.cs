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
            openRecent: OpenRecentPath,
            recentFiles: _recentFiles.Get(),
            saveAsPath: ShowSaveDocumentDialog,
            credentials: _credentials);
        DataContext = _viewModel;
    }

    private void OpenAboutWindow()
    {
        var window = new AboutWindow { DataContext = new AboutViewModel(), Owner = this };
        window.Show();
    }

    private static readonly IReadOnlyDictionary<string, (string Filter, string Extension)> ExportDialogs =
        new Dictionary<string, (string Filter, string Extension)>
        {
            ["html"] = ("HTML page (*.html)|*.html", "html"),
            ["html-flow"] = ("HTML flow (*.html)|*.html", "html"),
            ["csv"] = ("CSV spreadsheet (*.csv)|*.csv", "csv"),
            ["json"] = ("JSON data (*.json)|*.json", "json"),
            ["json-report"] = ("JSON full report (*.json)|*.json", "json"),
            ["text"] = ("Plain text (*.txt)|*.txt", "txt"),
        };

    private string? ShowExportSaveDialog(string format)
    {
        (string Filter, string Extension) entry =
            ExportDialogs.TryGetValue(format, out var known) ? known : ("All files (*.*)|*.*", format);

        string stem = Path.GetFileNameWithoutExtension(_viewModel.Document.FileName);
        if (string.IsNullOrEmpty(stem)) stem = "report";

        var dialog = new Microsoft.Win32.SaveFileDialog
        {
            Filter = entry.Filter,
            DefaultExt = entry.Extension,
            AddExtension = true,
            FileName = $"{stem}.{entry.Extension}",
        };
        return dialog.ShowDialog() == true ? dialog.FileName : null;
    }

    private string? ShowSaveDocumentDialog()
    {
        var dialog = new Microsoft.Win32.SaveFileDialog
        {
            Filter = "MAD documents (*.mad)|*.mad",
            FileName = "report.mad",
        };
        return dialog.ShowDialog() == true ? dialog.FileName : null;
    }

    private void OpenRecentPath(string path)
    {
        _ = OpenPathAsync(path);
    }

    private async Task OpenPathAsync(string path)
    {
        await _viewModel.Document.OpenAsync(path);
        _recentFiles.Add(path);
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
                await _viewModel.Document.AdoptAsync(created, path);
                _recentFiles.Add(path);
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

    protected override void OnClosed(EventArgs e)
    {
        base.OnClosed(e);
        _engine.DisposeAsync().GetAwaiter().GetResult();
    }
}
