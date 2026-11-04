#!/usr/bin/env python3
# Copyright © 2026 Michael Thomason. SPDX-License-Identifier: MIT
"""Seed Localizable.xcstrings with keys that are defined as string constants.

Several modules define their UI keys once:

	static NSString * const MADTextReadRecords = @"\\nRead %@ records.";

and call NSLocalizedString(MADTextReadRecords, ...). The standard extractors
cannot see through the symbol, so those keys never reach the catalog. This
script adds a manual entry for every used constant, preserving any existing
entry and translation, and reports symbols it cannot resolve.

	python3 -I scripts/localization/sync_constants.py          # write the catalog
	python3 -I scripts/localization/sync_constants.py --check  # fail if missing

--check is the CI-friendly form: it exits 1 when a resolved constant key is
absent from the catalog. Unresolved symbols are reported but do not fail.
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
	used = {}
	for path in audit.iter_source_files(root):
		text = path.read_text(encoding="utf-8", errors="replace")
		relative = path.relative_to(root).as_posix()
		for match in DEFINITION_RE.finditer(text):
			definitions[match.group(1)] = (audit.decode_literal(match.group(2)), relative)
		without_comments, code_only = audit.mask_source(text)
		for match in audit.CALL_RE.finditer(code_only):
			_close, args = audit._split_arguments(without_comments, match.end() - 1)
			first = args[0].strip() if args else ""
			if IDENTIFIER_RE.fullmatch(first):
				used.setdefault(first, []).append(relative)
	return definitions, used


def main(argv=None):
	parser = argparse.ArgumentParser(description="Seed the catalog from string constants.")
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

	definitions, used = scan(root)
	missing = []
	unresolved = []
	for symbol in sorted(used):
		if symbol not in definitions:
			unresolved.append(symbol)
			continue
		value, source = definitions[symbol]
		if not value.strip() or value in strings:
			continue
		missing.append((value, symbol, source))

	if args.check:
		if missing:
			print("Missing constant keys in %s (%d):" % (catalog_path, len(missing)))
			for value, symbol, source in missing:
				print("  %s  <- %s (%s)" % (value, symbol, source))
			return 1
		print("Constant keys: catalog is complete (%d used, %d unresolved)." % (
			len(used) - len(unresolved), len(unresolved)))
		for symbol in unresolved:
			print("  unresolved: %s (no definition in the scanned roots)" % symbol)
		return 0

	for value, symbol, source in missing:
		strings[value] = {
			"comment": "Defined as %s in %s." % (symbol, source),
			"extractionState": "manual",
		}
	data["strings"] = dict(sorted(strings.items()))
	catalog_path.write_text(
		json.dumps(data, indent=2, ensure_ascii=False, sort_keys=True) + "\n",
		encoding="utf-8")
	print("Added %d constant keys to %s." % (len(missing), catalog_path))
	for symbol in unresolved:
		print("  unresolved: %s (no definition in the scanned roots)" % symbol)
	return 0


if __name__ == "__main__":
	sys.exit(main())
