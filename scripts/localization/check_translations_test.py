#!/usr/bin/env python3
# Copyright © 2026 Michael Thomason. SPDX-License-Identifier: MIT
"""Tests for scripts/localization/check_translations.py."""

import importlib.util
import json
import sys
import tempfile
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location("check_translations", HERE / "check_translations.py")
check = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(check)


def translated(value, plural=None):
	localization = {"stringUnit": {"state": "translated", "value": value}}
	if plural:
		localization["substitutions"] = plural
	return localization


def entry(key, translations, should_translate=True, source_value=None, plural=None):
	data = {
		"key": key,
		"extractionState": "manual",
		"localizations": {
			"en": translated(source_value if source_value is not None else key, plural),
		},
	}
	data["localizations"].update(translations)
	if not should_translate:
		data["shouldTranslate"] = False
	return data


def catalog(strings):
	return {"sourceLanguage": "en", "version": "1.0", "strings": strings}


def plural_substitution(categories, prefix="%lu "):
	variations = {}
	for category, noun in categories.items():
		variations[category] = {"stringUnit": {"state": "translated", "value": prefix + noun}}
	return {"items": {"argNum": 1, "formatSpecifier": "lld",
					  "variations": {"plural": variations}}}


class FunctionTests(unittest.TestCase):
	def test_specifiers_ignore_percent_escape(self):
		self.assertEqual(check.specifiers("100%% of %1$@ and %2$lu"),
						 ["%1$@", "%2$lu"])

	def test_specifiers_read_plural_reference(self):
		self.assertEqual(check.specifiers("Page %2$@ %#@pages@"),
						 ["%2$@", "%#@"])

	def test_plural_categories_by_language(self):
		self.assertEqual(check.plural_categories("de"), frozenset(("one", "other")))
		self.assertEqual(check.plural_categories("ja"), frozenset(("other",)))


class CatalogTests(unittest.TestCase):
	def setUp(self):
		self.directory = tempfile.TemporaryDirectory()
		self.path = Path(self.directory.name) / "Localizable.xcstrings"

	def tearDown(self):
		self.directory.cleanup()

	def write(self, data):
		self.path.write_text(json.dumps(data), encoding="utf-8")

	def check(self, data, require_complete=False):
		problems = []
		notes = []
		check.check_catalog(self.path, require_complete, problems, notes)
		return problems

	def test_valid_catalog_passes(self):
		self.write(catalog({
			"Open": entry("Open", {
				"de": translated("Öffnen"), "es": translated("Abrir"),
				"ja": translated("開く"), "pt-BR": translated("Abrir"),
				"zh-Hans": translated("打开")}),
			"Saved %@ ago.": entry("Saved %@ ago.", {
				"de": translated("Vor %@ gespeichert."),
				"es": translated("Guardado hace %@."),
				"ja": translated("%@ 前に保存しました。"),
				"pt-BR": translated("Salvo há %@."),
				"zh-Hans": translated("已保存 %@。")}),
		}))
		self.assertEqual(self.check(json.loads(self.path.read_text())), [])

	def test_dropped_specifier_fails(self):
		self.write(catalog({
			"Saved %@ ago.": entry("Saved %@ ago.", {
				"de": translated("Vor einer Weile gespeichert.")}),
		}))
		problems = self.check(json.loads(self.path.read_text()))
		self.assertTrue(any("format specifiers" in problem for problem in problems))

	def test_reordered_specifiers_fail(self):
		self.write(catalog({
			"%1$@ of %2$@": entry("%1$@ of %2$@", {
				"de": translated("%2$@ von %1$@")}),
		}))
		problems = self.check(json.loads(self.path.read_text()))
		self.assertTrue(any("format specifiers" in problem for problem in problems))

	def test_empty_value_fails(self):
		self.write(catalog({
			"Open": entry("Open", {"de": translated("")}),
		}))
		problems = self.check(json.loads(self.path.read_text()))
		self.assertTrue(any("empty translation" in problem for problem in problems))

	def test_unknown_language_fails(self):
		self.write(catalog({
			"Open": entry("Open", {"fr": translated("Ouvrir")}),
		}))
		problems = self.check(json.loads(self.path.read_text()))
		self.assertTrue(any("not a shipped language" in problem for problem in problems))

	def test_should_translate_false_with_translation_fails(self):
		self.write(catalog({
			"MySQL": entry("MySQL", {"de": translated("MySQL")}, should_translate=False),
		}))
		problems = self.check(json.loads(self.path.read_text()))
		self.assertTrue(any("shouldTranslate false" in problem for problem in problems))

	def test_plural_categories_pass(self):
		source = plural_substitution({"one": "item", "other": "items"})
		self.write(catalog({
			"%lld items": entry("%lld items", {
				"de": translated("Artikel %2$@ %#@items@",
								 plural_substitution({"one": "Artikel", "other": "Artikel"})),
				"es": translated("Artículos %2$@ %#@items@",
								 plural_substitution({"one": "artículo", "other": "artículos"})),
				"ja": translated("項目 %2$@ %#@items@",
								 plural_substitution({"other": "項目"})),
				"pt-BR": translated("Itens %2$@ %#@items@",
									plural_substitution({"one": "item", "other": "itens"})),
				"zh-Hans": translated("项目 %2$@ %#@items@",
									  plural_substitution({"other": "个项目"})),
			}, source_value="%2$@ %#@items@", plural=source),
		}))
		problems = self.check(json.loads(self.path.read_text()))
		self.assertEqual(problems, [])

	def test_plural_missing_category_fails(self):
		source = plural_substitution({"one": "item", "other": "items"})
		self.write(catalog({
			"%lld items": entry("%lld items", {
				"de": translated("Artikel %2$@ %#@items@",
								 plural_substitution({"other": "Artikel"})),
			}, source_value="%2$@ %#@items@", plural=source),
		}))
		problems = self.check(json.loads(self.path.read_text()))
		self.assertTrue(any("requires" in problem for problem in problems))

	def test_japanese_extra_category_fails(self):
		source = plural_substitution({"one": "item", "other": "items"})
		self.write(catalog({
			"%lld items": entry("%lld items", {
				"ja": translated("項目 %2$@ %#@items@",
								 plural_substitution({"one": "項目", "other": "項目"})),
			}, source_value="%2$@ %#@items@", plural=source),
		}))
		problems = self.check(json.loads(self.path.read_text()))
		self.assertTrue(any("ja requires" in problem for problem in problems))

	def test_plural_reference_missing_fails(self):
		source = plural_substitution({"one": "item", "other": "items"})
		self.write(catalog({
			"%lld items": entry("%lld items", {
				"de": translated("Artikel %2$@",
								 plural_substitution({"one": "Artikel", "other": "Artikel"})),
			}, source_value="%2$@ %#@items@", plural=source),
		}))
		problems = self.check(json.loads(self.path.read_text()))
		self.assertTrue(any("plural reference" in problem for problem in problems))

	def test_require_complete_reports_missing_languages(self):
		self.write(catalog({"Open": entry("Open", {"de": translated("Öffnen")})}))
		self.assertEqual(self.check(json.loads(self.path.read_text())), [])
		problems = self.check(json.loads(self.path.read_text()), require_complete=True)
		self.assertTrue(any("missing translations" in problem for problem in problems))


class ResourceTests(unittest.TestCase):
	def setUp(self):
		self.directory = tempfile.TemporaryDirectory()
		self.root = Path(self.directory.name)
		self.original_root = check.ROOT
		check.ROOT = self.root
		(self.root / "scripts/localization/storyboard_strings/MADDesigner/Storyboard").mkdir(parents=True)
		(self.root / "MADDesigner/Resources/Storyboard/de.lproj").mkdir(parents=True)

	def tearDown(self):
		check.ROOT = self.original_root
		self.directory.cleanup()

	def test_storyboard_specifier_mismatch_fails(self):
		template = self.root / "scripts/localization/storyboard_strings/MADDesigner/Storyboard/MADQuery.strings"
		template.write_text('"a.text" = "Page %1$@ of %2$@";\n', encoding="utf-8")
		translation = self.root / "MADDesigner/Resources/Storyboard/de.lproj/MADQuery.strings"
		translation.write_text('"a.text" = "Seite %1$@ von %2$@";\n', encoding="utf-8")
		problems = []
		notes = []
		check.check_storyboards(self.root / "scripts/localization/storyboard_strings", problems, notes)
		self.assertEqual(problems, [])

		translation.write_text('"a.text" = "Seite %2$@ von %1$@";\n', encoding="utf-8")
		problems = []
		check.check_storyboards(self.root / "scripts/localization/storyboard_strings", problems, notes)
		self.assertTrue(any("format specifiers" in problem for problem in problems))

	def test_storyboard_unknown_key_fails(self):
		template = self.root / "scripts/localization/storyboard_strings/MADDesigner/Storyboard/MADQuery.strings"
		template.write_text('"a.text" = "Page";\n', encoding="utf-8")
		translation = self.root / "MADDesigner/Resources/Storyboard/de.lproj/MADQuery.strings"
		translation.write_text('"b.text" = "Seite";\n', encoding="utf-8")
		problems = []
		notes = []
		check.check_storyboards(self.root / "scripts/localization/storyboard_strings", problems, notes)
		self.assertTrue(any("not in the exported template" in problem for problem in problems))

	def test_settings_empty_value_fails(self):
		settings = self.root / "MADDesigner/Resources/Assets/Settings.bundle"
		(settings / "de.lproj").mkdir(parents=True)
		(settings / "de.lproj/Root.strings").write_text('"Title" = "";\n', encoding="utf-8")
		problems = []
		notes = []
		check.check_settings("MADDesigner/Resources/Assets/Settings.bundle", problems, notes)
		self.assertTrue(any("is empty" in problem for problem in problems))


if __name__ == "__main__":
	unittest.main()
