//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using System.ComponentModel;
using System.IO;
using System.Windows;
using System.Windows.Controls;
using Mad.Designer.Windows.Infrastructure;
using Mad.Designer.Windows.ViewModels;
using Microsoft.Web.WebView2.Core;
using Microsoft.Web.WebView2.Wpf;

namespace Mad.Designer.Windows.Views;

/// <summary>The MAD Viewer's rendered-report surface. The engine's HTML facsimile (the exact
/// <c>export --format html</c> bytes, one page box per page) is hosted in a WebView2, which is
/// Windows' interim for the Mac's PDFView: it scales with the zoom controls, scrolls to the
/// page the navigation buttons select, and prints through the browser print path. The browser
/// is created on Load rather than in XAML so the control materialises headlessly for tests.</summary>
public partial class ViewerView : UserControl
{
    private static readonly string PreviewFolder = Path.Combine(Path.GetTempPath(), "mad-viewer");

    private WebView2? _browser;
    private ViewerViewModel? _viewer;
    private string? _pendingHtml;
    private string? _previewFile;

    public ViewerView()
    {
        InitializeComponent();
        // The browser stays alive across workspace switches so the rendered report survives a
        // visit to another workspace; the process exit tears down the WebView2 child processes
        // with it. It is created only once the Viewer is actually visible with a document open:
        // WebView2 is a native surface that paints above every WPF sibling, so creating it for
        // the Welcome screen would cover that screen.
        Loaded += OnLoaded;
        IsVisibleChanged += OnIsVisibleChanged;
        DataContextChanged += OnDataContextChanged;
    }

    private void OnDataContextChanged(object sender, DependencyPropertyChangedEventArgs e)
    {
        if (_viewer != null)
        {
            _viewer.PropertyChanged -= OnViewerPropertyChanged;
            _viewer.PrintRequested -= OnPrintRequested;
        }

        _viewer = (e.NewValue as MainWindowViewModel)?.Document.Viewer;

        if (_viewer != null)
        {
            _viewer.PropertyChanged += OnViewerPropertyChanged;
            _viewer.PrintRequested += OnPrintRequested;
        }
    }

    private async void OnLoaded(object sender, RoutedEventArgs e)
    {
        if (IsVisible) await EnsureBrowserSafelyAsync();
    }

    private async void OnIsVisibleChanged(object sender, DependencyPropertyChangedEventArgs e)
    {
        if (IsVisible) await EnsureBrowserSafelyAsync();
    }

    private async Task EnsureBrowserSafelyAsync()
    {
        try
        {
            await EnsureBrowserAsync();
        }
        catch (Exception exception)
        {
            // The report can still be exported and printed only through the browser, so say
            // why the preview is empty rather than failing silently.
            Placeholder.Text = Localizer.Format("Viewer.PreviewError", exception.Message);
            Placeholder.Visibility = Visibility.Visible;
        }
    }

    private async Task EnsureBrowserAsync()
    {
        if (_browser != null || _viewer is not { HasDocument: true }) return;

        string dataFolder = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
            "MADDesigner", "WebView2");
        Directory.CreateDirectory(dataFolder);

        CoreWebView2Environment environment = await CoreWebView2Environment.CreateAsync(userDataFolder: dataFolder);

        var browser = new WebView2
        {
            DefaultBackgroundColor = ThemeInfo.IsDark
                ? System.Drawing.Color.FromArgb(0x1F, 0x1F, 0x1F)
                : System.Drawing.Color.FromArgb(0x8C, 0x8C, 0x8C),
        };
        PreviewHost.Children.Add(browser);
        await browser.EnsureCoreWebView2Async(environment);

        browser.CoreWebView2.Settings.AreDevToolsEnabled = false;
        browser.CoreWebView2.Settings.AreDefaultContextMenusEnabled = false;
        browser.NavigationCompleted += OnNavigationCompleted;
        browser.ZoomFactor = _viewer.Zoom;
        _browser = browser;

        // A render can land before the browser finishes starting; a later Load (after the
        // workspace was unloaded) shows whatever the view model already holds.
        string? html = _pendingHtml ?? _viewer.PreviewHtml;
        _pendingHtml = null;
        if (html != null)
        {
            ShowPreview(html);
        }
    }

    private void OnViewerPropertyChanged(object? sender, PropertyChangedEventArgs e)
    {
        if (!Dispatcher.CheckAccess())
        {
            Dispatcher.BeginInvoke(() => OnViewerPropertyChanged(sender, e));
            return;
        }
        if (_viewer == null) return;

        switch (e.PropertyName)
        {
            case nameof(ViewerViewModel.HasDocument) when _viewer.HasDocument && IsVisible:
                _ = EnsureBrowserSafelyAsync();
                break;
            case nameof(ViewerViewModel.PreviewHtml):
                ShowPreview(_viewer.PreviewHtml);
                break;
            case nameof(ViewerViewModel.Zoom) when _browser?.CoreWebView2 != null:
                _browser.ZoomFactor = _viewer.Zoom;
                break;
            case nameof(ViewerViewModel.CurrentPage):
                ScrollToCurrentPage();
                break;
        }
    }

    private void OnPrintRequested(object? sender, EventArgs e)
    {
        if (!Dispatcher.CheckAccess())
        {
            Dispatcher.BeginInvoke(() => OnPrintRequested(sender, e));
            return;
        }
        _browser?.CoreWebView2?.ShowPrintUI(CoreWebView2PrintDialogKind.Browser);
    }

    /// <summary>Presents the engine's HTML. A temporary file is used rather than
    /// NavigateToString, whose 2 MB ceiling a large report would hit.</summary>
    private void ShowPreview(string? html)
    {
        if (_browser?.CoreWebView2 == null)
        {
            _pendingHtml = html;
            return;
        }

        if (html == null)
        {
            // An empty preview still needs the desk colour and its instruction: about:blank is
            // white in both themes, would glare in the dark theme, and would cover the WPF
            // placeholder (the WebView2 is a native surface that paints above its WPF siblings).
            string ink = ThemeInfo.IsDark ? "#E6E6E6" : "#555555";
            string hint = System.Net.WebUtility.HtmlEncode(Localizer.Get("Viewer.Placeholder"));
            _browser.CoreWebView2.NavigateToString(
                $"<html><body style=\"background:{ThemeInfo.DeskColor};margin:0;height:100vh;" +
                "display:flex;align-items:center;justify-content:center;" +
                $"color:{ink};font-family:'Segoe UI Variable Text','Segoe UI';font-size:14px\">{hint}</body></html>");
            return;
        }

        Directory.CreateDirectory(PreviewFolder);
        string file = Path.Combine(PreviewFolder, $"preview-{Guid.NewGuid():N}.html");
        File.WriteAllText(file, html);

        string? previous = _previewFile;
        _previewFile = file;
        _browser.CoreWebView2.Navigate(new Uri(file).AbsoluteUri);

        if (previous != null)
        {
            TryDelete(previous);
        }
    }

    private async void OnNavigationCompleted(object? sender, CoreWebView2NavigationCompletedEventArgs e)
    {
        if (!e.IsSuccess || _browser?.CoreWebView2 == null) return;

        // Preview-only chrome: the exported pages are white sheets on the app's grey desk,
        // with a gap and a shadow between them. The exported bytes are never altered.
        string desk = ThemeInfo.DeskColor;
        string outline = ThemeInfo.IsDark ? "#3A3A3A" : "#777777";
        string shadow = ThemeInfo.IsDark ? "rgba(0,0,0,.65)" : "rgba(0,0,0,.45)";
        await _browser.CoreWebView2.ExecuteScriptAsync(
            "(function(){var s=document.createElement('style');" +
            $"s.textContent='html,body{{background:{desk};margin:0}}" +
            "body{padding:24px 0}" +
            ".page{margin:0 auto 24px auto;background:#fff;" +
            $"box-shadow:0 2px 12px {shadow};outline:1px solid {outline}}}';" +
            "document.head.appendChild(s);})()");

        ScrollToCurrentPage();
    }

    private void ScrollToCurrentPage()
    {
        if (_browser?.CoreWebView2 == null || _viewer == null) return;
        int index = _viewer.PreviewPageIndex;
        if (index < 0) return;

        _ = _browser.CoreWebView2.ExecuteScriptAsync(
            $"var p=document.querySelector('.page[data-index=\"{index}\"]');" +
            "if(p){p.scrollIntoView({block:'start'});}");
    }

    private static void TryDelete(string path)
    {
        try
        {
            if (File.Exists(path)) File.Delete(path);
        }
        catch (IOException)
        {
            // The browser may still hold the file briefly; the temp folder is disposable.
        }
    }
}
