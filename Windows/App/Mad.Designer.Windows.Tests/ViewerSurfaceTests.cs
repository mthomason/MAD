//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using Mad.Designer.Windows.Engine;
using Mad.Designer.Windows.ViewModels;
using Mad.Designer.Windows.Views;

namespace Mad.Designer.Windows.Tests;

/// <summary>Materialises the Viewer workspace on an STA thread — the headless stand-in for the
/// interactive visual check that the toolbar, status bar and preview host render and follow the
/// view model. The WebView2 browser itself is created on Load, so the XAML composes without it.</summary>
public sealed class ViewerSurfaceTests
{
    [Fact]
    public void ViewerView_ShowsTheToolbarStatusAndPreviewHost()
    {
        Exception? failure = null;

        var thread = new Thread(() =>
        {
            try
            {
                var engine = new EngineService(); // never started: this test opens no document
                var main = new MainWindowViewModel(engine);
                var view = new ViewerView { DataContext = main, Width = 1000, Height = 720 };
                view.Measure(new Size(1000, 720));
                view.Arrange(new Rect(0, 0, 1000, 720));
                view.UpdateLayout();

                var pageSize = (ComboBox)view.FindName("PageSizeBox")!;
                var formats = (ComboBox)view.FindName("FormatBox")!;
                var status = (TextBlock)view.FindName("StatusText")!;
                var pageLabel = (TextBlock)view.FindName("PageLabelText")!;
                var zoomLabel = (Button)view.FindName("ZoomLabel")!;
                var paperStatus = (TextBlock)view.FindName("PaperStatusText")!;
                var placeholder = (TextBlock)view.FindName("Placeholder")!;
                var print = (Button)view.FindName("PrintButton")!;
                var export = (Button)view.FindName("ExportButton")!;

                Assert.Equal(3, pageSize.Items.Count);
                Assert.Equal(0, pageSize.SelectedIndex);
                Assert.Equal(7, formats.Items.Count);
                Assert.Equal(0, formats.SelectedIndex);
                Assert.Equal(ViewerViewModel.NotYetRefreshedText, status.Text);
                Assert.Equal("Page 0 of 0", pageLabel.Text);
                Assert.Equal("100%", zoomLabel.Content);
                Assert.Equal("Rendered Page Size: US Letter", paperStatus.Text);
                Assert.Equal(Visibility.Visible, placeholder.Visibility);

                // Nothing is open, so the document-dependent commands are disabled.
                Assert.False(print.IsEnabled);
                Assert.False(export.IsEnabled);

                // Selecting a format drives the view model (the export dialog's extension).
                formats.SelectedIndex = 4; // JSON Data (PDF is first)
                Assert.Equal(4, main.Document.Viewer.SelectedFormatIndex);

                // A render turns the status line green and fills the page label.
                main.Document.Viewer.SetRenderedHtml(
                    "<div class=\"page\" data-index=\"0\"></div><div class=\"page\" data-index=\"1\"></div>" +
                    "<div class=\"page\" data-index=\"2\"></div>", rowCount: 42);
                view.UpdateLayout();

                Assert.Equal("Rendered 3 pages from 42 cached rows.", status.Text);
                Assert.Equal(Color.FromRgb(0x10, 0x7C, 0x10), ((SolidColorBrush)status.Foreground).Color);
                Assert.Equal("Page 1 of 3", pageLabel.Text);
                Assert.Equal(Visibility.Collapsed, placeholder.Visibility);

                // Zoom steps update the toolbar label.
                main.Document.Viewer.ZoomInCommand.Execute(null);
                view.UpdateLayout();
                Assert.Equal("125%", zoomLabel.Content);

                // Page navigation updates the label.
                main.Document.Viewer.NextPageCommand.Execute(null);
                Assert.Equal("Page 2 of 3", pageLabel.Text);

                // A failed render turns it red.
                main.Document.Viewer.ReportRefreshFailed("the database is unreachable");
                view.UpdateLayout();
                Assert.Equal("the database is unreachable", status.Text);
                Assert.Equal(Color.FromRgb(0xC4, 0x2B, 0x1C), ((SolidColorBrush)status.Foreground).Color);
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
}
