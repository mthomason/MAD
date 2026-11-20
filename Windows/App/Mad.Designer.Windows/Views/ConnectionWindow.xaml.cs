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
        ViewModel = new ConnectionWindowViewModel(engine, credentials, isEdit, initial, createPath: ShowCreateSaveDialog, requestClose: () => DialogResult = true);
        DataContext = ViewModel;
        WindowSizing.FitToWorkArea(this);

        Title = Localizer.Get(isEdit ? "Connection.Title.Edit" : "Connection.Title.Create");
        SubmitButton.Content = Localizer.Get(isEdit ? "Connection.SaveRefresh" : "Connection.Create");
    }

    private string? ShowCreateSaveDialog()
    {
        var dialog = new Microsoft.Win32.SaveFileDialog
        {
            Filter = Localizer.Get("Dialog.SaveMadFilter"),
            FileName = Localizer.Get("Dialog.DefaultNewDocument"),
        };
        return dialog.ShowDialog() == true ? dialog.FileName : null;
    }

    private void ChooseFile_Click(object sender, RoutedEventArgs e)
    {
        var dialog = new Microsoft.Win32.OpenFileDialog
        {
            Filter = Localizer.Get("Dialog.SQLiteFilter"),
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
