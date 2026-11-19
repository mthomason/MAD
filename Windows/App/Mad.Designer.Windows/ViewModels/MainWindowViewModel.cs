//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using System.Windows.Input;
using Mad.Designer.Windows.Engine;
using Mad.Designer.Windows.Infrastructure;

namespace Mad.Designer.Windows.ViewModels;

public enum Workspace
{
    Query,
    Designer,
    Viewer,
}

/// <summary>The top-level view model for the main window: it owns the shared
/// <see cref="Document"/>, the workspace selection, and the File-menu commands. The window
/// injects the About/connection/recent-file actions so this class stays free of any direct
/// dependency on those windows and dialogs.</summary>
public sealed class MainWindowViewModel : ObservableObject
{
    private readonly Action? _openAbout;
    private readonly Action? _newDocument;
    private readonly Action? _editConnection;
    private readonly Action<string>? _openRecent;
    private Workspace _selectedWorkspace = Workspace.Viewer;

    public MainWindowViewModel(
        EngineService engine,
        Action? openAbout = null,
        Func<string, string?>? exportPath = null,
        Action? newDocument = null,
        Action? editConnection = null,
        Action<string>? openRecent = null,
        IReadOnlyList<string>? recentFiles = null,
        Func<string?>? saveAsPath = null)
    {
        _openAbout = openAbout;
        _newDocument = newDocument;
        _editConnection = editConnection;
        _openRecent = openRecent;
        Document = new DocumentViewModel(engine, exportPath, saveAsPath);
        RecentFiles = recentFiles ?? Array.Empty<string>();

        OpenDocumentCommand = new RelayCommand(OpenDocument);
        OpenAboutCommand = new RelayCommand(() => _openAbout?.Invoke());
        NewDocumentCommand = new RelayCommand(() => _newDocument?.Invoke());
        EditConnectionCommand = new RelayCommand(() => _editConnection?.Invoke());
        OpenRecentCommand = new RelayCommand<string?>(OpenRecent);
    }

    public DocumentViewModel Document { get; }

    /// <summary>The client-side recent-documents list, most-recent-first.</summary>
    public IReadOnlyList<string> RecentFiles { get; }

    public Workspace SelectedWorkspace
    {
        get => _selectedWorkspace;
        set => Set(ref _selectedWorkspace, value);
    }

    public ICommand OpenDocumentCommand { get; }
    public ICommand OpenAboutCommand { get; }
    public ICommand NewDocumentCommand { get; }
    public ICommand EditConnectionCommand { get; }
    public RelayCommand<string?> OpenRecentCommand { get; }

    /// <summary>Opens a document at a known path (a recent file or a command-line argument).</summary>
    public async Task OpenPathAsync(string path) => await Document.OpenAsync(path);

    private void OpenDocument()
    {
        var dialog = new Microsoft.Win32.OpenFileDialog
        {
            Filter = "MAD documents (*.mad)|*.mad|All files (*.*)|*.*",
        };
        if (dialog.ShowDialog() == true)
        {
            _ = Document.OpenAsync(dialog.FileName);
        }
    }

    private void OpenRecent(string? path)
    {
        if (!string.IsNullOrEmpty(path))
        {
            _openRecent?.Invoke(path);
        }
    }
}
