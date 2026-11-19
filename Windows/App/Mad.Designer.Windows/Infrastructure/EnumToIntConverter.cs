//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using System.Globalization;
using System.Windows.Data;

namespace Mad.Designer.Windows.Infrastructure;

/// <summary>Binds an enum property to an int-valued control property (e.g. TabControl.SelectedIndex).</summary>
public sealed class EnumToIntConverter : IValueConverter
{
    public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        => value is Enum enumValue ? System.Convert.ToInt32(enumValue) : 0;

    public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        => value is int intValue && targetType.IsEnum ? Enum.ToObject(targetType, intValue) : Binding.DoNothing;
}
