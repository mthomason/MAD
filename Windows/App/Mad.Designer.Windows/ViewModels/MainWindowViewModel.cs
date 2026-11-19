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
/// <see cref="Document"/> and the workspace selection, and exposes the toolbar commands.
/// The About-window action is injected so this class stays free of any direct dependency
/// on the About window.</summary>
public sealed class MainWindowViewModel : ObservableObject
{
    private readonly Action? _openAbout;
    private Workspace _selectedWorkspace = Workspace.Viewer;

    public MainWindowViewModel(EngineService engine, Action? openAbout = null)
    {
        _openAbout = openAbout;
        Document = new DocumentViewModel(engine);
        OpenDocumentCommand = new RelayCommand(OpenDocument);
        OpenAboutCommand = new RelayCommand(() => _openAbout?.Invoke());
    }

    public DocumentViewModel Document { get; }

    public Workspace SelectedWorkspace
    {
        get => _selectedWorkspace;
        set => Set(ref _selectedWorkspace, value);
    }

    public ICommand OpenDocumentCommand { get; }
    public ICommand OpenAboutCommand { get; }

    /// <summary>Auto-opens the London fixture so the shell demos with zero clicks. Failures
    /// land in <see cref="DocumentViewModel.ErrorText"/> rather than throwing.</summary>
    public Task InitializeAsync() => Document.OpenAsync(MadPathResolver.DefaultDocument());

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
}
