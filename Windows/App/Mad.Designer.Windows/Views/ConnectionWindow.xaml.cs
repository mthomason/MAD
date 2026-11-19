//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using System.Windows;
using Mad.Designer.Windows.Engine;
using Mad.Designer.Windows.Infrastructure;
using Mad.Designer.Windows.Models;
using Mad.Designer.Windows.ViewModels;

namespace Mad.Designer.Windows.Views;

/// <summary>The connection assistant window — the WPF counterpart of the Mac's
/// <c>MADMacConnectionWindowController</c>. It owns its view model and both file dialogs
/// (the SQLite chooser and the create-document save path).</summary>
public partial class ConnectionWindow : Window
{
    public ConnectionWindowViewModel ViewModel { get; }

    public ConnectionWindow(EngineService engine, ICredentialStore credentials, bool isEdit, ConnectionSpec? initial = null)
    {
        InitializeComponent();
        ViewModel = new ConnectionWindowViewModel(engine, credentials, isEdit, initial, createPath: ShowCreateSaveDialog);
        DataContext = ViewModel;

        Title = isEdit ? "Database Connection Settings" : "Create a New Mobile Analytics Document (.mad)";
        SubmitButton.Content = isEdit ? "Save & Refresh" : "Create Document…";
    }

    private string? ShowCreateSaveDialog()
    {
        var dialog = new Microsoft.Win32.SaveFileDialog
        {
            Filter = "MAD documents (*.mad)|*.mad",
            FileName = "Untitled Report.mad",
        };
        return dialog.ShowDialog() == true ? dialog.FileName : null;
    }

    private void ChooseFile_Click(object sender, RoutedEventArgs e)
    {
        var dialog = new Microsoft.Win32.OpenFileDialog
        {
            Filter = "SQLite databases (*.sqlite3;*.db;*.sqlite)|*.sqlite3;*.db;*.sqlite|All files (*.*)|*.*",
        };
        if (dialog.ShowDialog() == true)
        {
            ViewModel.File = dialog.FileName;
        }
    }

    private void PasswordBox_PasswordChanged(object sender, RoutedEventArgs e)
    {
        ViewModel.Password = PasswordBox.Password;
    }
}
