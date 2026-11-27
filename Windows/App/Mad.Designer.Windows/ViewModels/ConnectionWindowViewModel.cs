//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using Mad.Designer.Windows.Engine;
using Mad.Designer.Windows.Infrastructure;
using Mad.Designer.Windows.Models;

namespace Mad.Designer.Windows.ViewModels;

/// <summary>The connection assistant's view model — the WPF counterpart of the Mac's
/// <c>MADMacConnectionWindowController</c>. It holds the driver-specific form fields, shows
/// and hides them by driver, tests the connection, and either creates a new document or
/// (in edit mode) returns the collected spec for the caller to apply.</summary>
public sealed class ConnectionWindowViewModel : ObservableObject
{
    private readonly EngineService _engine;
    private readonly ICredentialStore _credentials;
    private readonly Func<string?>? _createPath;
    private readonly Action? _requestClose;

    private ConnectionDriver _driver;
    private string _file = "";
    private string _host = "127.0.0.1";
    private int _port;
    private string _database = "";
    private string _serverInstance = "";
    private string _username = "";
    private string _password = "";
    private bool _saveCredentials = true;
    private string _statusText = "";
    private bool _isBusy;

    /// <param name="statusPrompt">Replaces the default status line; a composition source
    /// prompt uses it to name the source being asked about.</param>
    /// <param name="prefillStoredCredentials">When true (an edit), the saved username and
    /// password are prefilled; a first-run source prompt passes false so the password is
    /// empty and the user chooses whether to reuse the stored one.</param>
    public ConnectionWindowViewModel(
        EngineService engine,
        ICredentialStore credentials,
        bool isEdit,
        ConnectionSpec? initial = null,
        Func<string?>? createPath = null,
        Action? requestClose = null,
        string? statusPrompt = null,
        bool prefillStoredCredentials = true)
    {
        _engine = engine ?? throw new ArgumentNullException(nameof(engine));
        _credentials = credentials ?? throw new ArgumentNullException(nameof(credentials));
        _createPath = createPath;
        _requestClose = requestClose;
        IsEdit = isEdit;

        Driver = initial?.Driver ?? ConnectionDriver.Sqlite3;
        File = initial?.File ?? "";
        Host = initial?.Host ?? "127.0.0.1";
        if (initial?.Port is int port) Port = port;
        Database = initial?.Database ?? "";
        ServerInstance = initial?.ServerInstance ?? "";
        Username = initial?.Username ?? "";
        Password = initial?.Password ?? "";

        if (prefillStoredCredentials
            && initial?.CredentialKey is string key
            && _credentials.TryRead(key, out string? savedUser, out string? savedPass))
        {
            if (string.IsNullOrEmpty(Username)) Username = savedUser;
            if (string.IsNullOrEmpty(Password)) Password = savedPass;
        }

        StatusText = string.IsNullOrWhiteSpace(statusPrompt)
            ? Localizer.Get(isEdit ? "Connection.StatusEdit" : "Connection.StatusCreate")
            : statusPrompt;

        TestConnectionCommand = new AsyncRelayCommand(TestConnectionAsync, () => !IsBusy);
        SubmitCommand = new AsyncRelayCommand(SubmitAsync, () => !IsBusy);
    }

    public bool IsEdit { get; }

    public ConnectionDriver Driver
    {
        get => _driver;
        set
        {
            if (!Set(ref _driver, value)) return;

            OnPropertyChanged(nameof(IsSqlite));
            OnPropertyChanged(nameof(IsServer));
            OnPropertyChanged(nameof(IsSqlServer));

            // Bump the port to the new driver's default when it is unset or another
            // driver's default — the same behaviour as the Mac's driver-popup change.
            int current = Port;
            if (value == ConnectionDriver.MySql && (current == 0 || current == 1433 || current == 5432)) Port = 3306;
            else if (value == ConnectionDriver.SqlServer && (current == 0 || current == 3306 || current == 5432)) Port = 1433;
            else if (value == ConnectionDriver.Postgres && (current == 0 || current == 3306 || current == 1433)) Port = 5432;
        }
    }

    public string File { get => _file; set => Set(ref _file, value); }
    public string Host { get => _host; set => Set(ref _host, value); }
    public int Port { get => _port; set => Set(ref _port, value); }
    public string Database { get => _database; set => Set(ref _database, value); }
    public string ServerInstance { get => _serverInstance; set => Set(ref _serverInstance, value); }
    public string Username { get => _username; set => Set(ref _username, value); }
    public string Password { get => _password; set => Set(ref _password, value); }
    public bool SaveCredentials { get => _saveCredentials; set => Set(ref _saveCredentials, value); }
    public string StatusText { get => _statusText; private set => Set(ref _statusText, value); }

    public bool IsBusy
    {
        get => _isBusy;
        private set
        {
            if (Set(ref _isBusy, value))
            {
                TestConnectionCommand.RaiseCanExecuteChanged();
                SubmitCommand.RaiseCanExecuteChanged();
            }
        }
    }

    public bool IsSqlite => Driver == ConnectionDriver.Sqlite3;
    public bool IsServer => Driver != ConnectionDriver.Sqlite3;
    public bool IsSqlServer => Driver == ConnectionDriver.SqlServer;

    /// <summary>The form's current state as a <see cref="ConnectionSpec"/>.</summary>
    public ConnectionSpec Spec => new(Driver, File, Host, Port, Database, ServerInstance, Username, Password);

    /// <summary>Create mode: the created document's open result, once submitted.</summary>
    public OpenResult? Created { get; private set; }

    /// <summary>Create mode: the path the document was created at.</summary>
    public string? CreatePath { get; private set; }

    /// <summary>Edit mode: the collected spec, once submitted.</summary>
    public ConnectionSpec? ResultSpec { get; private set; }

    /// <summary>Edit mode: true once the user submitted.</summary>
    public bool Submitted { get; private set; }

    public AsyncRelayCommand TestConnectionCommand { get; }
    public AsyncRelayCommand SubmitCommand { get; }

    private async Task TestConnectionAsync()
    {
        IsBusy = true;
        try
        {
            int count = await _engine.TestConnectionAsync(Spec);
            StatusText = Localizer.Format("Connection.Connected", count);
        }
        catch (Exception exception)
        {
            StatusText = exception.Message;
        }
        finally
        {
            IsBusy = false;
        }
    }

    private async Task SubmitAsync()
    {
        if (IsEdit)
        {
            ResultSpec = Spec;
            Submitted = true;
            _requestClose?.Invoke();
            return;
        }

        string? path = _createPath?.Invoke();
        if (string.IsNullOrEmpty(path))
        {
            return; // the user cancelled the save dialog
        }
        if (!path.EndsWith(".mad", StringComparison.OrdinalIgnoreCase))
        {
            path += ".mad";
        }

        IsBusy = true;
        try
        {
            Created = await _engine.CreateAsync(path, Spec);
            CreatePath = path;
            SaveCredentialsIfRequested();
            _requestClose?.Invoke();
        }
        catch (Exception exception)
        {
            StatusText = exception.Message;
        }
        finally
        {
            IsBusy = false;
        }
    }

    private void SaveCredentialsIfRequested()
    {
        if (!SaveCredentials || Spec.CredentialKey == null) return;
        _credentials.Save(Spec.CredentialKey, Username ?? "", Password ?? "");
    }
}
