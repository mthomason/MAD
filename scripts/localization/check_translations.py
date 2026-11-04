#!/usr/bin/env python3
# Copyright © 2026 Michael Thomason. SPDX-License-Identifier: MIT
"""Check the translation products for mechanical errors.

The String Catalog is the source of truth for the app's own strings, and the
storyboard/xib .strings files carry the interface translations.  This script is
pure text, needs no Xcode, and is safe to run in the Linux workflow:

	python3 -I scripts/localization/check_translations.py
	python3 -I scripts/localization/check_translations.py --require-complete
	python3 -I scripts/localization/check_translations.py --report

It enforces four rules:

* every translated value preserves the source's format specifiers, in the same
  order;
* every plural entry carries exactly the plural categories its language
  requires (one and other for de, es, pt-BR; only other for ja, zh-Hans);
* no translated value is empty;
* only en and the five shipped language codes appear.

--require-complete additionally fails when an entry that should be translated
has no localization in one of the five languages.  The CI check does not use it
so that a new key can land with the English source before its translations do.
"""

import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
LANGUAGES = ("de", "es", "ja", "pt-BR", "zh-Hans")
ALLOWED = ("en",) + LANGUAGES
ONE_AND_OTHER_LANGUAGES = frozenset(("de", "es", "pt-BR"))
OTHER_ONLY_LANGUAGES = frozenset(("ja", "zh-Hans"))
ONE_AND_OTHER = frozenset(("one", "other"))
OTHER_ONLY = frozenset(("other",))

# A printf-style conversion, including the positional and flags forms the app
# uses (%1$@, %2$lu, %#.1f, %lld, %%).  The plural reference %#@name@ is
# captured as far as %#@; the name is checked separately.
SPEC_RE = re.compile(
	r"%(?:\d+\$)?[-+ #0']*(?:\d+|\*)?(?:\.(?:\d+|\*))?(?:hh|h|ll|l|q|L|j|z|t)?[diouxXeEfFgGaAcspn@%]"
)
ENTRY_RE = re.compile(
	r'^"(?P<key>(?:[^"\\]|\\.)*)"\s*=\s*"(?P<value>(?:[^"\\]|\\.)*)";\s*$'
)
STORYBOARD_DIRS = (
	("MADDesigner/Storyboard", "MADDesigner/Resources/Storyboard"),
	("MADDesigner/Nibs", "MADDesigner/Resources/Nibs"),
	("MADMySQL", "MADMySQL/Resources"),
	("MADPostgres", "MADPostgres/Resources"),
	("MADTdsClient", "MADTdsClient/Resources"),
)
SETTINGS_BUNDLE = "MADDesigner/Resources/Assets/Settings.bundle"


def specifiers(value):
	"""Return the conversion specifiers in value, in order, ignoring %%."""
	return [match.group(0) for match in SPEC_RE.finditer(value) if match.group(0) != "%%"]


def plural_categories(language):
	return ONE_AND_OTHER if language in ONE_AND_OTHER_LANGUAGES else OTHER_ONLY


def decode_strings_value(raw):
	"""Undo the .strings escaping that matters for a text check."""
	return raw.replace(r"\"", '"').replace(r"\n", "\n").replace(r"\t", "\t")


def read_strings(path):
	"""Return an ordered list of (key, value) pairs from a .strings file."""
	raw = path.read_bytes()
	text = raw.decode("utf-16") if raw[:2] in (b"\xff\xfe", b"\xfe\xff") else raw.decode("utf-8")
	entries = []
	for line in text.splitlines():
		match = ENTRY_RE.match(line)
		if match:
			entries.append((decode_strings_value(match.group("key")),
							decode_strings_value(match.group("value"))))
	return entries


def english_value(entry, key):
	"""The source text a translation must mirror for format specifiers."""
	localization = entry.get("localizations", {}).get("en", {})
	unit = localization.get("stringUnit", {})
	return unit.get("value", key)


def check_catalog(path, require_complete, problems, notes):
	data = json.loads(path.read_text(encoding="utf-8"))
	strings = data.get("strings", {})
	if not isinstance(strings, dict):
		problems.append("%s: 'strings' is not an object" % path)
		return
	untranslated = 0
	for key, entry in sorted(strings.items()):
		localizations = entry.get("localizations", {})
		for language in localizations:
			if language not in ALLOWED:
				problems.append("%s: key %r has a localization for %r, which is not a shipped language"
								% (path, key, language))
		should_translate = entry.get("shouldTranslate", True) is not False
		if should_translate:
			missing = [language for language in LANGUAGES if language not in localizations]
			if missing:
				untranslated += 1
				if require_complete:
					problems.append("%s: key %r is missing translations for %s"
									% (path, key, ", ".join(missing)))
		elif any(language in localizations for language in LANGUAGES):
			problems.append("%s: key %r is marked shouldTranslate false but has translations"
							% (path, key))

		source = english_value(entry, key)
		source_specifiers = specifiers(source)
		source_plural = localizations.get("en", {}).get("substitutions", {})
		for language in LANGUAGES:
			localization = localizations.get(language)
			if localization is None:
				continue
			unit = localization.get("stringUnit", {})
			value = unit.get("value", "")
			where = "%s: %s %r" % (path, language, key)
			if not value.strip():
				problems.append("%s: empty translation" % where)
			elif specifiers(value) != source_specifiers:
				problems.append("%s: format specifiers %r do not match source %r"
								% (where, specifiers(value), source_specifiers))
			substitutions = localization.get("substitutions", {})
			if not source_plural and substitutions:
				problems.append("%s: has plural substitutions but the source does not" % where)
				continue
			if not source_plural:
				continue
			required = plural_categories(language)
			if set(substitutions) != set(source_plural):
				problems.append("%s: plural names %r do not match source %r"
								% (where, sorted(substitutions), sorted(source_plural)))
			for name, source_substitution in sorted(source_plural.items()):
				substitution = substitutions.get(name)
				if substitution is None:
					problems.append("%s: missing plural substitution %r" % (where, name))
					continue
				if substitution.get("argNum") != source_substitution.get("argNum"):
					problems.append("%s: substitution %r changes argNum %r to %r"
									% (where, name, source_substitution.get("argNum"),
									   substitution.get("argNum")))
				if substitution.get("formatSpecifier") != source_substitution.get("formatSpecifier"):
					problems.append("%s: substitution %r changes formatSpecifier %r to %r"
									% (where, name, source_substitution.get("formatSpecifier"),
									   substitution.get("formatSpecifier")))
				variations = substitution.get("variations", {}).get("plural", {})
				if set(variations) != set(required):
					problems.append("%s: substitution %r has categories %r; %s requires %r"
									% (where, name, sorted(variations), language, sorted(required)))
				source_variations = source_substitution.get("variations", {}).get("plural", {})
				for category in sorted(required & set(variations)):
					translated = variations[category].get("stringUnit", {}).get("value", "")
					source_variation = source_variations.get(category)
					if not translated.strip():
						problems.append("%s: plural %r/%r is empty" % (where, name, category))
						continue
					if source_variation is None:
						continue
					expected = source_variation.get("stringUnit", {}).get("value", "")
					if specifiers(translated) != specifiers(expected):
						problems.append("%s: plural %r/%r specifiers %r do not match source %r"
										% (where, name, category, specifiers(translated),
										   specifiers(expected)))
				if "#@%s@" % name not in value:
					problems.append("%s: the plural reference %%#@%s@ is missing from the value"
									% (where, name))
	if untranslated:
		notes.append("%s: %d entries are not complete in all five languages" % (path, untranslated))


def template_values(template_root):
	values = {}
	for project, _resource in STORYBOARD_DIRS:
		directory = template_root / project
		if not directory.is_dir():
			continue
		for path in sorted(directory.glob("*.strings")):
			for key, value in read_strings(path):
				values[(project, path.stem, key)] = value
	return values


def check_storyboards(template_root, problems, notes):
	values = template_values(template_root)
	translated = 0
	for project, resource in STORYBOARD_DIRS:
		directory = ROOT / resource
		if not directory.is_dir():
			continue
		for language_directory in sorted(directory.glob("*.lproj")):
			language = language_directory.name[:-len(".lproj")]
			if language == "Base":
				continue
			if language not in LANGUAGES:
				problems.append("%s: %s.lproj is not a shipped language"
								% (language_directory, language))
				continue
			for path in sorted(language_directory.glob("*.strings")):
				if not any(k[0] == project and k[1] == path.stem for k in values):
					problems.append("%s: no exported template for %s/%s"
									% (path, project, path.stem))
					continue
				for key, value in read_strings(path):
					where = "%s: %s" % (path, key)
					source = values.get((project, path.stem, key))
					if source is None:
						problems.append("%s: key is not in the exported template" % where)
						continue
					translated += 1
					if not value.strip():
						problems.append("%s: empty translation" % where)
					elif specifiers(value) != specifiers(source):
						problems.append("%s: format specifiers %r do not match source %r"
										% (where, specifiers(value), specifiers(source)))
	notes.append("Checked %d storyboard/xib translated entries." % translated)


def check_settings(bundle, problems, notes):
	directory = ROOT / bundle
	if not directory.is_dir():
		notes.append("No Settings.bundle at %s; skipped." % bundle)
		return
	checked = 0
	for language_directory in sorted(directory.glob("*.lproj")):
		language = language_directory.name[:-len(".lproj")]
		if language not in ALLOWED:
			problems.append("%s: %s.lproj is not a shipped language"
							% (language_directory, language))
			continue
		for path in sorted(language_directory.glob("*.strings")):
			for key, value in read_strings(path):
				checked += 1
				if not value.strip():
					problems.append("%s: %s is empty" % (path, key))
	notes.append("Checked %d settings entries." % checked)


def main(argv=None):
	parser = argparse.ArgumentParser(description="Check translation mechanics.")
	parser.add_argument("--catalog", type=Path,
						default=ROOT / "MADDesigner/Resources/Localizable.xcstrings")
	parser.add_argument("--storyboards", type=Path,
						default=ROOT / "scripts/localization/storyboard_strings")
	parser.add_argument("--require-complete", action="store_true",
						help="fail when a translatable key lacks one of the five languages")
	parser.add_argument("--report", action="store_true", help="print the notes as well")
	args = parser.parse_args(argv)

	problems = []
	notes = []
	check_catalog(args.catalog.resolve(), args.require_complete, problems, notes)
	check_storyboards(args.storyboards.resolve(), problems, notes)
	check_settings(SETTINGS_BUNDLE, problems, notes)

	if problems:
		print("Translation check failed (%d problem%s):" % (
			len(problems), "" if len(problems) == 1 else "s"))
		for problem in problems:
			print("  %s" % problem)
		return 1
	if args.report:
		for note in notes:
			print(note)
	print("Translations check clean: format specifiers, plural categories, empty values, "
		  "and language codes.")
	return 0


if __name__ == "__main__":
	sys.exit(main())
