//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using System.Text.RegularExpressions;
using System.Windows.Controls;
using Mad.Designer.Windows.Engine;
using Mad.Designer.Windows.Infrastructure;
using Mad.Designer.Windows.ViewModels;
using Mad.Designer.Windows.Views;

namespace Mad.Designer.Windows.Tests;

/// <summary>The localization gate: every shipped dictionary carries every English key with the
/// same format placeholders, the culture mapping follows the Mac's language set, and the app's
/// XAML renders the selected language. The translations are machine-assisted and unreviewed
/// (MAD_APP_LOCALIZATION.md D14); this suite checks completeness and mechanical safety, not
/// linguistic quality.</summary>
public sealed class LocalizerTests
{
    private static readonly Regex Placeholder = new(@"\{\d+\}", RegexOptions.Compiled);

    [Fact]
    public void EveryShippedDictionary_HasEveryEnglishKey()
    {
        IReadOnlyDictionary<string, string> english = Localizer.StringsFor("en");
        Assert.Equal(416, english.Count);

        foreach (string language in Localizer.SupportedLanguages)
        {
            IReadOnlyDictionary<string, string> dictionary = Localizer.StringsFor(language);
            foreach (string key in english.Keys)
            {
                Assert.True(dictionary.ContainsKey(key), $"{language} is missing {key}");
                Assert.False(string.IsNullOrWhiteSpace(dictionary[key]), $"{language} has an empty {key}");
            }
        }
    }

    [Fact]
    public void Translations_PreserveFormatPlaceholders()
    {
        IReadOnlyDictionary<string, string> english = Localizer.StringsFor("en");
        foreach (string language in Localizer.SupportedLanguages)
        {
            IReadOnlyDictionary<string, string> dictionary = Localizer.StringsFor(language);
            foreach ((string key, string source) in english)
            {
                string[] expected = Placeholder.Matches(source).Select(m => m.Value).OrderBy(v => v).ToArray();
                string[] actual = Placeholder.Matches(dictionary[key]).Select(m => m.Value).OrderBy(v => v).ToArray();
                Assert.Equal(expected, actual);
            }
        }
    }

    [Theory]
    [InlineData("en-US", "en")]
    [InlineData("de-DE", "de")]
    [InlineData("es-ES", "es")]
    [InlineData("es-419", "es")]
    [InlineData("ja-JP", "ja")]
    [InlineData("pt", "pt-BR")]
    [InlineData("pt-BR", "pt-BR")]
    [InlineData("zh-CN", "zh-Hans")]
    [InlineData("zh-Hant", "zh-Hans")]
    [InlineData("fr-FR", "en")]
    public void ResolveLanguage_MapsTheMacsLanguageSet(string culture, string expected)
        => Assert.Equal(expected, Localizer.ResolveLanguage(culture));

    [Fact]
    public void UnknownKey_FallsBackToTheKey()
        => Assert.Equal("No.Such.Key", Localizer.Get("No.Such.Key"));

    [Fact]
    public void English_IsTheSourceAndTheDefault()
    {
        Assert.Equal("en", Localizer.DefaultLanguage);
        Assert.Equal("Page Size:", Localizer.Get("Viewer.PageSize"));
        Assert.Equal("This report queries one database.", Localizer.Get("Document.TypeStandard.Tooltip"));
        Assert.Equal("This report combines other reports into one result.", Localizer.Get("Document.TypeComposition.Tooltip"));
        Assert.Equal("Add an element to the selected band.", Localizer.Get("Designer.Insert.Tooltip"));
        Assert.Equal("Edit", Localizer.Get("Designer.Edit"));
        Assert.Equal("Refine", Localizer.Get("Query.Refine"));
        Assert.Equal("Text", Localizer.Get("Designer.Insert.Text"));
        Assert.Equal("Graphics", Localizer.Get("Designer.Insert.Graphics"));
        Assert.Equal("Rendered 5 pages from 76 cached rows.", ViewerViewModel.StatusMessage(5, 76));
    }

    [Fact]
    public void German_ChangesTheViewModelAndTheXaml()
    {
        try
        {
            Localizer.Apply("de");

            Assert.Equal("Seitengröße:", Localizer.Get("Viewer.PageSize"));
            Assert.Equal("Aktualisieren", Localizer.Get("Viewer.Refresh"));
            Assert.Contains("Seiten", ViewerViewModel.StatusMessage(5, 76));
            var viewer = new ViewerViewModel(new EngineService());
            viewer.SetRenderedHtml(
                "<div class=\"page\" data-index=\"0\"></div><div class=\"page\" data-index=\"1\"></div>" +
                "<div class=\"page\" data-index=\"2\"></div><div class=\"page\" data-index=\"3\"></div>" +
                "<div class=\"page\" data-index=\"4\"></div>", rowCount: 76);
            Assert.Equal("Seite 1 von 5", viewer.PageLabel);
            Assert.Contains("Open-Source-Business-Intelligence", new AboutViewModel().Overview);

            Exception? failure = null;
            var thread = new Thread(() =>
            {
                try
                {
                    var view = new ViewerView();
                    var placeholder = (TextBlock)view.FindName("Placeholder")!;
                    Assert.Equal("Zum Rendern des Berichts aktualisieren.", placeholder.Text);
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
        finally
        {
            Localizer.Apply("en");
        }
    }
}
