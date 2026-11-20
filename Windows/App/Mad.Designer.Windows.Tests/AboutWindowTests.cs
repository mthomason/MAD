//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using System.Windows;
using Mad.Designer.Windows.ViewModels;
using Mad.Designer.Windows.Views;

namespace Mad.Designer.Windows.Tests;

/// <summary>Materialises the About window on an STA thread. It pins the defect that terminated
/// the process from Help &gt; About: a TextBox's Text binding defaults to TwoWay, and the About
/// content properties are read-only, so the binding threw during the window's first layout.</summary>
public sealed class AboutWindowTests
{
    [Fact]
    public void AboutWindow_ShowsAndBindsItsReadOnlyContent()
    {
        Exception? failure = null;

        var thread = new Thread(() =>
        {
            try
            {
                var window = new AboutWindow
                {
                    DataContext = new AboutViewModel(),
                    WindowStartupLocation = WindowStartupLocation.Manual,
                    Left = 0,
                    Top = 0,
                };
                window.Show();
                window.UpdateLayout();
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
}
