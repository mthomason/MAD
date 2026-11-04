#!/usr/bin/env python3
# Copyright © 2026 Michael Thomason. SPDX-License-Identifier: MIT
"""Seed Localizable.xcstrings from the source strings.

The catalog is the source of truth, but xcstringstool sync only updates entries
that already exist; it does not add new ones, and it cannot see through a
constant key. This script adds a manual entry for every missing source string,
preserving any existing entry and translation:

* every literal NSLocalizedString(@"Key", @"Context.") key, using the second
  argument as the comment when it is meaningful;
* every used NSString * const NAME = @"Key"; definition, with the symbol and
  file as the comment.

	python3 -I scripts/localization/sync_catalog.py          # write the catalog
	python3 -I scripts/localization/sync_catalog.py --check  # fail if missing

--check is the CI-friendly form: it exits 1 when a key is absent. Unresolved
constant symbols are reported but do not fail, because a definition can live
outside the scanned roots.
"""

import argparse
import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import audit

DEFINITION_RE = re.compile(
	r'(?:static\s+)?NSString\s*\*\s*const\s+(\w+)\s*=\s*@"((?:[^"\\]|\\.)*)"\s*;'
)
IDENTIFIER_RE = re.compile(r"[A-Za-z_]\w*")


def scan(root):
	definitions = {}
	constants_used = {}
	literal_keys = {}
	for path in audit.iter_source_files(root):
		text = path.read_text(encoding="utf-8", errors="replace")
		relative = path.relative_to(root).as_posix()
		for match in DEFINITION_RE.finditer(text):
			definitions[match.group(1)] = (audit.decode_literal(match.group(2)), relative)
		without_comments, code_only = audit.mask_source(text)
		for match in audit.CALL_RE.finditer(code_only):
			_close, args = audit._split_arguments(without_comments, match.end() - 1)
			first = args[0].strip() if args else ""
			value = audit.literal_value(first)
			if value is not None:
				comment = ""
				if len(args) > 1:
					candidate = audit.literal_value(args[1])
					if candidate and candidate != value and audit.has_letters(candidate):
						comment = candidate
				if value not in literal_keys or len(comment) > len(literal_keys[value]):
					literal_keys[value] = comment
				continue
			if IDENTIFIER_RE.fullmatch(first):
				constants_used.setdefault(first, []).append(relative)
	return definitions, constants_used, literal_keys


def main(argv=None):
	parser = argparse.ArgumentParser(description="Seed the String Catalog from source.")
	parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[2],
		help="repository root (default: two levels above this script)")
	parser.add_argument("--catalog", type=Path, default=None,
		help="catalog path (default: MADDesigner/Resources/Localizable.xcstrings)")
	parser.add_argument("--check", action="store_true",
		help="report missing keys and exit 1 without writing")
	args = parser.parse_args(argv)

	root = args.root.resolve()
	catalog_path = (args.catalog or (root / "MADDesigner/Resources/Localizable.xcstrings")).resolve()
	data = json.loads(catalog_path.read_text(encoding="utf-8"))
	strings = data.setdefault("strings", {})

	definitions, constants_used, literal_keys = scan(root)
	missing = {}
	for key in sorted(literal_keys):
		if key.strip() and key not in strings:
			missing[key] = literal_keys[key] or "Localized UI string."

	unresolved = []
	for symbol in sorted(constants_used):
		if symbol not in definitions:
			unresolved.append(symbol)
			continue
		value, source = definitions[symbol]
		if not value.strip() or value in strings or value in literal_keys:
			continue
		missing[value] = "Defined as %s in %s." % (symbol, source)

	if args.check:
		if missing:
			print("Missing catalog keys in %s (%d):" % (catalog_path, len(missing)))
			for key, comment in sorted(missing.items()):
				print("  %s  <- %s" % (key, comment))
			return 1
		print("Catalog is complete (%d literal keys, %d constants, %d unresolved)." % (
			len(literal_keys), len(constants_used) - len(unresolved), len(unresolved)))
		for symbol in unresolved:
			print("  unresolved: %s (no definition in the scanned roots)" % symbol)
		return 0

	literal_added = sum(1 for key in missing if key in literal_keys)
	for key, comment in sorted(missing.items()):
		strings[key] = {"comment": comment, "extractionState": "manual"}
	data["strings"] = dict(sorted(strings.items()))
	catalog_path.write_text(
		json.dumps(data, indent=2, ensure_ascii=False, sort_keys=True) + "\n",
		encoding="utf-8")
	print("Added %d keys to %s (%d literal, %d constant)." % (
		len(missing), catalog_path, literal_added, len(missing) - literal_added))
	for symbol in unresolved:
		print("  unresolved: %s (no definition in the scanned roots)" % symbol)
	return 0


if __name__ == "__main__":
	sys.exit(main())
