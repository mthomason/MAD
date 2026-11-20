//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using System.IO;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using System.Windows.Threading;
using Mad.Designer.Windows.Engine;
using Mad.Designer.Windows.Infrastructure;
using Mad.Designer.Windows.Models;
using Mad.Designer.Windows.ViewModels;
using Mad.Designer.Windows.Views;

namespace Mad.Designer.Windows.Tests;

/// <summary>The Phase 6f shell: the Welcome surface, the primary navigation, and the first
/// workspace chosen for a created or opened report. Also loads the shared theme dictionary the
/// views merge, so a missing style key fails the suite rather than a window at runtime.</summary>
[Collection("Engine")]
public sealed class ShellSurfaceTests
{
    [Fact]
    public void ThemeDictionary_DefinesTheSharedStylesAndBrand()
    {
        Exception? failure = null;
        var thread = new Thread(() =>
        {
            try
            {
                var view = new WelcomeView();
                ResourceDictionary theme = view.Resources.MergedDictionaries[0];
                foreach (string key in new[]
                {
                    "MAD.FontFamily", "MAD.CommandButton", "MAD.PrimaryButton", "MAD.Card",
                    "MAD.NavItem", "MAD.StatusBar", "MAD.SuccessBrush", "MAD.ErrorBrush",
                })
                {
                    Assert.True(theme.Contains(key), $"the theme is missing {key}");
                }

                var brand = (SolidColorBrush)theme["MAD.BrandBrush"];
                Assert.Equal(Color.FromRgb(0xCC, 0x29, 0x22), brand.Color);
            }
            catch (Exception exception)
            {
                failure = exception;
            }
        });
        thread.SetApartmentState(ApartmentState.STA);
        thread.Start();
        thread.Join();

        Assert.Null(failure);
    }

    [Fact]
    public async Task WelcomeView_BindsTheCommandsAndRecentReports()
    {
        await using var engine = new EngineService();
        int newClicks = 0;
        var viewModel = new MainWindowViewModel(
            engine,
            newDocument: () => newClicks++,
            recentFiles: new[] { @"C:\reports\first.mad", @"C:/reports/first.mad", @"C:\reports\second.mad" });

        Assert.Equal(2, viewModel.RecentFiles.Count); // the two spellings normalise to one entry

        Exception? failure = null;
        var thread = new Thread(() =>
        {
            try
            {
                var view = new WelcomeView { DataContext = viewModel, Width = 900, Height = 700 };
                view.Measure(new Size(900, 700));
                view.Arrange(new Rect(0, 0, 900, 700));
                view.UpdateLayout();

                var recent = (ItemsControl)view.FindName("RecentList")!;
                Assert.Equal(2, recent.Items.Count);

                var create = (Button)view.FindName("NewReportButton")!;
                Assert.NotNull(create.Command);
                create.Command.Execute(null);
                Assert.Equal(1, newClicks);
            }
            catch (Exception exception)
            {
                failure = exception;
            }
        });
        thread.SetApartmentState(ApartmentState.STA);
        thread.Start();
        thread.Join();

        Assert.Null(failure);
    }

    [Fact]
    public void MainWindow_StartsWithTheWelcomeScreenAndDisabledNavigation()
    {
        Exception? failure = null;
        var thread = new Thread(() =>
        {
            try
            {
                var window = new MainWindow
                {
                    WindowStartupLocation = WindowStartupLocation.Manual,
                    Left = 0,
                    Top = 0,
                    Width = 1200,
                    Height = 760,
                };
                window.Show();
                window.UpdateLayout();

                var viewModel = (MainWindowViewModel)window.DataContext;
                Assert.True(viewModel.ShowWelcome);
                Assert.False(viewModel.ShowWorkspace);

                var navigation = (ListBox)window.FindName("WorkspaceList")!;
                Assert.False(navigation.IsEnabled);
                Assert.Equal(-1, viewModel.SelectedWorkspaceIndex);
                Assert.Equal(-1, navigation.SelectedIndex);

                window.Close();
            }
            catch (Exception exception)
            {
                failure = exception;
            }
        });
        thread.SetApartmentState(ApartmentState.STA);
        thread.Start();
        thread.Join();

        Assert.Null(failure);
    }

    [Fact]
    public async Task CreatedReportOpensInTheDesigner_ExistingReportInTheViewer()
    {
        string sqlite = CopyChinookToTemp();
        string created = Path.Combine(Path.GetTempPath(), $"mad-shell-{Guid.NewGuid():N}.mad");
        try
        {
            await using var engine = new EngineService();
            var viewModel = new MainWindowViewModel(engine);
            Assert.Equal(-1, viewModel.SelectedWorkspaceIndex);
            OpenResult open = await engine.CreateAsync(created, new ConnectionSpec(
                ConnectionDriver.Sqlite3, sqlite, null, null, null, null, null, null));

            await viewModel.AdoptCreatedAsync(open, created);
            Assert.Equal(Workspace.Designer, viewModel.SelectedWorkspace);
            Assert.True(viewModel.DesignerVisible);
            Assert.False(viewModel.ViewerVisible);
            Assert.Equal(1, viewModel.SelectedWorkspaceIndex);

            await viewModel.OpenPathAsync(MadPathResolver.DefaultDocument());
            Assert.Equal(Workspace.Viewer, viewModel.SelectedWorkspace);
            Assert.True(viewModel.ViewerVisible);
            Assert.False(viewModel.DesignerVisible);
            Assert.Equal(2, viewModel.SelectedWorkspaceIndex);
        }
        finally
        {
            if (File.Exists(sqlite)) File.Delete(sqlite);
            if (File.Exists(created)) File.Delete(created);
        }
    }

    private static string CopyChinookToTemp()
    {
        string source = Path.Combine(MadPathResolver.RepoRoot(), "MADDesigner", "Resources", "Assets", "Samples.xcassets", "Data", "chinook.dataset", "chinook.sqlite3");
        string temp = Path.Combine(Path.GetTempPath(), $"mad-chinook-{Guid.NewGuid():N}.sqlite3");
        File.Copy(source, temp);
        return temp;
    }
}
