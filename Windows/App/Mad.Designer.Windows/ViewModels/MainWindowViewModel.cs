//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using System.Collections.ObjectModel;
using System.ComponentModel;
using System.IO;
using System.Windows.Input;
using Mad.Designer.Windows.Engine;
using Mad.Designer.Windows.Infrastructure;
using Mad.Designer.Windows.Models;

namespace Mad.Designer.Windows.ViewModels;

public enum Workspace
{
    Query,
    Designer,
    Viewer,
}

/// <summary>The top-level view model for the main window: it owns the shared
/// <see cref="Document"/>, the workspace selection, the Welcome state, and the File-menu
/// commands. The window injects the About/connection/recent-file actions so this class stays
/// free of any direct dependency on those windows and dialogs.</summary>
public sealed class MainWindowViewModel : ObservableObject
{
    private readonly Action? _openAbout;
    private readonly Action? _newDocument;
    private readonly Action? _editConnection;
    private readonly Action<string>? _persistRecent;
    private Workspace _selectedWorkspace = Workspace.Viewer;

    public MainWindowViewModel(
        EngineService engine,
        Action? openAbout = null,
        Func<string, string?>? exportPath = null,
        Action? newDocument = null,
        Action? editConnection = null,
        IReadOnlyList<string>? recentFiles = null,
        Func<string?>? saveAsPath = null,
        ICredentialStore? credentials = null,
        Action<string>? persistRecent = null)
    {
        _openAbout = openAbout;
        _newDocument = newDocument;
        _editConnection = editConnection;
        _persistRecent = persistRecent;
        Document = new DocumentViewModel(engine, exportPath, saveAsPath, credentials);
        RecentFiles = new ObservableCollection<string>(NormalizeRecent(recentFiles));
        Document.PropertyChanged += OnDocumentChanged;

        OpenDocumentCommand = new AsyncRelayCommand(OpenDocumentAsync);
        OpenAboutCommand = new RelayCommand(() => _openAbout?.Invoke());
        NewDocumentCommand = new RelayCommand(() => _newDocument?.Invoke());
        EditConnectionCommand = new RelayCommand(() => _editConnection?.Invoke());
        OpenRecentCommand = new AsyncRelayCommand<string?>(path => OpenPathAsync(path!));
        SelectQueryCommand = new RelayCommand(() => SelectedWorkspace = Workspace.Query, () => HasDocument);
        SelectDesignerCommand = new RelayCommand(() => SelectedWorkspace = Workspace.Designer, () => HasDocument);
        SelectViewerCommand = new RelayCommand(() => SelectedWorkspace = Workspace.Viewer, () => HasDocument);
    }

    public DocumentViewModel Document { get; }

    /// <summary>The recent-documents list shown on the Welcome screen and in File ▸ Recent,
    /// most-recent-first.</summary>
    public ObservableCollection<string> RecentFiles { get; }

    public bool HasDocument => Document.HasDocument;

    /// <summary>True when no report is open: the Welcome/Home screen takes the content area and
    /// the workspace destinations are disabled.</summary>
    public bool ShowWelcome => !HasDocument;
    public bool ShowWorkspace => HasDocument;

    public string WindowTitle => string.IsNullOrEmpty(Document.FileName)
        ? AppInfo.ProductName
        : Localizer.Format("App.TitleWithDocument", Document.FileName);

    /// <summary>The Windows application version, distinct from the engine version.</summary>
    public static string ApplicationVersionText => Localizer.Format("App.Version", AppInfo.Version);

    public Workspace SelectedWorkspace
    {
        get => _selectedWorkspace;
        set
        {
            if (!Set(ref _selectedWorkspace, value)) return;
            OnPropertyChanged(nameof(SelectedWorkspaceIndex));
            OnPropertyChanged(nameof(IsQuerySelected));
            OnPropertyChanged(nameof(IsDesignerSelected));
            OnPropertyChanged(nameof(IsViewerSelected));
            OnPropertyChanged(nameof(QueryVisible));
            OnPropertyChanged(nameof(DesignerVisible));
            OnPropertyChanged(nameof(ViewerVisible));
        }
    }

    /// <summary>The navigation rail's selection (0 Query, 1 Designer, 2 Viewer).</summary>
    public int SelectedWorkspaceIndex
    {
        get => (int)_selectedWorkspace;
        set
        {
            if (!HasDocument) return;
            SelectedWorkspace = (Workspace)Math.Clamp(value, 0, 2);
        }
    }

    public bool IsQuerySelected => _selectedWorkspace == Workspace.Query;
    public bool IsDesignerSelected => _selectedWorkspace == Workspace.Designer;
    public bool IsViewerSelected => _selectedWorkspace == Workspace.Viewer;

    // The workspaces are materialised up front (their state lives in the view models), but a
    // workspace is only visible with a document open; otherwise the Welcome surface owns the
    // content area. This also keeps the Viewer's native WebView2 out of the Welcome screen.
    public bool QueryVisible => HasDocument && IsQuerySelected;
    public bool DesignerVisible => HasDocument && IsDesignerSelected;
    public bool ViewerVisible => HasDocument && IsViewerSelected;

    public ICommand OpenDocumentCommand { get; }
    public ICommand OpenAboutCommand { get; }
    public ICommand NewDocumentCommand { get; }
    public ICommand EditConnectionCommand { get; }
    public AsyncRelayCommand<string?> OpenRecentCommand { get; }
    public RelayCommand SelectQueryCommand { get; }
    public RelayCommand SelectDesignerCommand { get; }
    public RelayCommand SelectViewerCommand { get; }

    /// <summary>Opens a document at a known path (a recent file or a command-line argument) in
    /// the Viewer — the reading default for an existing report.</summary>
    public async Task<bool> OpenPathAsync(string path)
    {
        await Document.OpenAsync(path);
        if (!Document.HasDocument) return false;

        AddRecent(path);
        SelectedWorkspace = Workspace.Viewer;
        return true;
    }

    /// <summary>Adopts a report the connection assistant just created and opens it in the
    /// Designer — a new report starts with its layout.</summary>
    public async Task AdoptCreatedAsync(OpenResult created, string path)
    {
        await Document.AdoptAsync(created, path);
        if (!Document.HasDocument) return;

        AddRecent(path);
        SelectedWorkspace = Workspace.Designer;
    }

    /// <summary>Adds a path to the most-recent-first list, removing an earlier occurrence.</summary>
    public void AddRecent(string path)
    {
        string? normalized = NormalizePath(path);
        if (normalized == null) return;

        for (int i = RecentFiles.Count - 1; i >= 0; i--)
        {
            if (string.Equals(RecentFiles[i], normalized, StringComparison.OrdinalIgnoreCase))
            {
                RecentFiles.RemoveAt(i);
            }
        }
        RecentFiles.Insert(0, normalized);
        while (RecentFiles.Count > 10) RecentFiles.RemoveAt(RecentFiles.Count - 1);
        _persistRecent?.Invoke(normalized);
    }

    private static IEnumerable<string> NormalizeRecent(IReadOnlyList<string>? paths)
    {
        var seen = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        var result = new List<string>();
        foreach (string path in paths ?? Array.Empty<string>())
        {
            string? normalized = NormalizePath(path);
            if (normalized != null && seen.Add(normalized))
            {
                result.Add(normalized);
            }
        }
        return result;
    }

    private static string? NormalizePath(string? path)
    {
        if (string.IsNullOrWhiteSpace(path)) return null;
        try
        {
            return Path.GetFullPath(path);
        }
        catch (Exception exception) when (exception is ArgumentException or NotSupportedException or PathTooLongException)
        {
            return path;
        }
    }

    private async Task OpenDocumentAsync()
    {
        var dialog = new Microsoft.Win32.OpenFileDialog
        {
            Filter = Localizer.Get("Dialog.OpenMadFilter"),
        };
        if (dialog.ShowDialog() == true)
        {
            await OpenPathAsync(dialog.FileName);
        }
    }

    private void OnDocumentChanged(object? sender, PropertyChangedEventArgs e)
    {
        if (e.PropertyName is nameof(DocumentViewModel.HasDocument) or nameof(DocumentViewModel.FileName))
        {
            OnPropertyChanged(nameof(HasDocument));
            OnPropertyChanged(nameof(ShowWelcome));
            OnPropertyChanged(nameof(ShowWorkspace));
            OnPropertyChanged(nameof(WindowTitle));
            OnPropertyChanged(nameof(QueryVisible));
            OnPropertyChanged(nameof(DesignerVisible));
            OnPropertyChanged(nameof(ViewerVisible));
            SelectQueryCommand.RaiseCanExecuteChanged();
            SelectDesignerCommand.RaiseCanExecuteChanged();
            SelectViewerCommand.RaiseCanExecuteChanged();
        }
    }
}
