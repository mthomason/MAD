//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using System.Globalization;
using System.IO;
using System.Windows.Data;

namespace Mad.Designer.Windows.Infrastructure;

/// <summary>Shows the file name of a recent-report path; the full path stays in the tooltip.</summary>
public sealed class PathFileNameConverter : IValueConverter
{
    public object Convert(object? value, Type targetType, object? parameter, CultureInfo culture)
        => value is string path && path.Length > 0 ? Path.GetFileName(path) : "";

    public object ConvertBack(object? value, Type targetType, object? parameter, CultureInfo culture)
        => throw new NotSupportedException();
}
