//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using System.Globalization;
using System.IO;
using System.Reflection;
using System.Windows;
using System.Windows.Markup;

namespace Mad.Designer.Windows.Infrastructure;

/// <summary>The WPF app's string table — the counterpart of the Mac app's
/// <c>Localizable.xcstrings</c>. Each supported language is a WPF <see cref="ResourceDictionary"/>
/// (an embedded XAML resource) keyed by the English source string's identifier. The English
/// source is authoritative; a missing key falls back to English and then to the key itself.
/// The language follows the OS UI language at launch, or the <c>MAD_LANGUAGE</c> environment
/// variable for inspection and testing. Licence bodies, component notices and copyright lines
/// stay in English by policy (docs/project/MAD_APP_LOCALIZATION.md §8).</summary>
public static class Localizer
{
    public const string DefaultLanguage = "en";

    /// <summary>The Mac's language set: English source plus the five translations.</summary>
    public static IReadOnlyList<string> SupportedLanguages { get; } =
        new[] { "en", "de", "es", "ja", "pt-BR", "zh-Hans" };

    private static readonly object Gate = new();
    private static readonly Dictionary<string, IReadOnlyDictionary<string, string>> Cache = new(StringComparer.OrdinalIgnoreCase);
    private static string _language = DefaultLanguage;
    private static IReadOnlyDictionary<string, string> _strings = StringsFor(DefaultLanguage);

    /// <summary>The active language code (one of <see cref="SupportedLanguages"/>).</summary>
    public static string Language => _language;

    /// <summary>Selects the language from <c>MAD_LANGUAGE</c> when set, otherwise from the
    /// current UI culture. Called once at startup, before any window is created.</summary>
    public static void ApplyFromEnvironmentOrCulture()
    {
        string? overrideLanguage = Environment.GetEnvironmentVariable("MAD_LANGUAGE");
        if (!string.IsNullOrWhiteSpace(overrideLanguage))
        {
            Apply(overrideLanguage);
            return;
        }
        Apply(CultureInfo.CurrentUICulture);
    }

    /// <summary>Selects a language by culture, mapping the platform's culture names onto the
    /// five shipped translations. Unknown cultures fall back to English.</summary>
    public static void Apply(CultureInfo? culture)
    {
        Apply(ResolveLanguage((culture ?? CultureInfo.CurrentUICulture).Name));
    }

    /// <summary>Selects a language by code (or culture name).</summary>
    public static void Apply(string language)
    {
        string resolved = ResolveLanguage(language);
        lock (Gate)
        {
            _language = resolved;
            _strings = StringsFor(resolved);
        }
    }

    /// <summary>Maps any culture name to one of the supported codes. Chinese always resolves to
    /// Simplified; Brazilian and European Portuguese both use the Brazilian translation.</summary>
    public static string ResolveLanguage(string? name)
    {
        if (string.IsNullOrWhiteSpace(name)) return DefaultLanguage;
        string normalized = name.Trim();

        foreach (string supported in SupportedLanguages)
        {
            if (string.Equals(normalized, supported, StringComparison.OrdinalIgnoreCase))
            {
                return supported;
            }
        }

        string root = normalized.Split('-', '_')[0].ToLowerInvariant();
        return root switch
        {
            "de" => "de",
            "es" => "es",
            "ja" => "ja",
            "pt" => "pt-BR",
            "zh" => "zh-Hans",
            _ => DefaultLanguage,
        };
    }

    /// <summary>The key's text in the active language, falling back to English and then the key.</summary>
    public static string Get(string key)
    {
        if (string.IsNullOrEmpty(key)) return string.Empty;

        IReadOnlyDictionary<string, string> current;
        lock (Gate) current = _strings;
        if (current.TryGetValue(key, out string? value) && value.Length > 0) return value;

        if (!ReferenceEquals(current, StringsFor(DefaultLanguage)) &&
            StringsFor(DefaultLanguage).TryGetValue(key, out value) && value.Length > 0)
        {
            return value;
        }
        return key;
    }

    /// <summary>A formatted message in the active language. Numbers and dates use the user's
    /// regional settings, the same way the Mac uses the current locale for its formatters.</summary>
    public static string Format(string key, params object?[] arguments)
        => string.Format(CultureInfo.CurrentCulture, Get(key), arguments);

    /// <summary>Loads (and caches) one language's resource dictionary. Exposed so the tests can
    /// verify every shipped dictionary without changing the process-wide language.</summary>
    public static IReadOnlyDictionary<string, string> StringsFor(string language)
    {
        string resolved = ResolveLanguage(language);
        lock (Gate)
        {
            if (Cache.TryGetValue(resolved, out IReadOnlyDictionary<string, string>? cached))
            {
                return cached;
            }

            IReadOnlyDictionary<string, string> loaded = LoadStrings(resolved);
            Cache[resolved] = loaded;
            return loaded;
        }
    }

    private static IReadOnlyDictionary<string, string> LoadStrings(string language)
    {
        ResourceDictionary? dictionary = LoadDictionary(language);
        if (dictionary == null && language != DefaultLanguage)
        {
            dictionary = LoadDictionary(DefaultLanguage);
        }
        if (dictionary == null)
        {
            return new Dictionary<string, string>(StringComparer.Ordinal);
        }

        var strings = new Dictionary<string, string>(StringComparer.Ordinal);
        foreach (object key in dictionary.Keys)
        {
            if (key is string name && dictionary[key] is string value)
            {
                strings[name] = value;
            }
        }
        return strings;
    }

    private static ResourceDictionary? LoadDictionary(string language)
    {
        Assembly assembly = typeof(Localizer).Assembly;
        string suffix = $"Strings-{language}.xaml";
        string? resourceName = assembly.GetManifestResourceNames()
            .FirstOrDefault(name => name.EndsWith(suffix, StringComparison.OrdinalIgnoreCase));
        if (resourceName == null) return null;

        using Stream? stream = assembly.GetManifestResourceStream(resourceName);
        if (stream == null) return null;

        try
        {
            return XamlReader.Load(stream) as ResourceDictionary;
        }
        catch (XamlParseException)
        {
            return null;
        }
    }
}

/// <summary>XAML markup extension: <c>Text="{infra:Loc Viewer.PageSize}"</c>. It resolves at
/// load time from the dictionary the app selected at startup, so it also works in the
/// headless tests, which have no WPF <see cref="System.Windows.Application"/>.</summary>
[MarkupExtensionReturnType(typeof(string))]
public sealed class LocExtension : MarkupExtension
{
    public LocExtension()
    {
    }

    public LocExtension(string key)
    {
        Key = key;
    }

    public string Key { get; set; } = string.Empty;

    public override object ProvideValue(IServiceProvider serviceProvider) => Localizer.Get(Key);
}
