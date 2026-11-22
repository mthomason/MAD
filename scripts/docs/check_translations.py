#!/usr/bin/env python3
# Copyright © 2026 Michael Thomason. SPDX-License-Identifier: MIT
"""Check translated pages against the English source.

Run with: python3 -I scripts/docs/check_translations.py [--docs docs]
          [--lang CODE] [--require-complete]

A missing counterpart is only fatal with --require-complete. A code-block
difference or a heading/table/fence count difference is always fatal.
"""

import argparse
import os
import sys
from collections import namedtuple

LANGUAGES = ("zh", "ja", "pt-br", "de", "es")
EXCLUDED_DIRS = {"project", "archive", "superpowers", "assets", "_includes", "_layouts", "_data"}

Findings = namedtuple("Findings", "missing code_drift structure_drift")


def public_pages(docs_root):
	docs_root = os.path.abspath(docs_root)
	pages = []
	for dirpath, dirnames, filenames in os.walk(docs_root):
		rel_dir = os.path.relpath(dirpath, docs_root)
		if rel_dir == ".":
			dirnames[:] = sorted(d for d in dirnames if d not in EXCLUDED_DIRS and d not in LANGUAGES)
		else:
			dirnames[:] = sorted(d for d in dirnames if d not in EXCLUDED_DIRS)
		for name in sorted(filenames):
			if not name.endswith(".md"):
				continue
			rel = os.path.relpath(os.path.join(dirpath, name), docs_root)
			if rel == "404.md":
				continue
			pages.append(rel.replace(os.sep, "/"))
	return sorted(pages)


def code_blocks(path):
	blocks = []
	current = None
	with open(path, encoding="utf-8", errors="replace") as handle:
		for line in handle:
			if line.lstrip().startswith(("```", "~~~")):
				if current is None:
					current = []
				else:
					blocks.append("".join(current))
					current = None
				continue
			if current is not None:
				current.append(line)
	if current is not None:
		blocks.append("".join(current))
	return blocks


def structure_counts(path):
	headings = tables = fences = 0
	with open(path, encoding="utf-8", errors="replace") as handle:
		for line in handle:
			if line.startswith("#"):
				headings += 1
			if line.startswith("|"):
				tables += 1
			if line.startswith("```"):
				fences += 1
	return headings, tables, fences


def check(docs_root, languages=None):
	docs_root = os.path.abspath(docs_root)
	languages = list(languages or LANGUAGES)
	missing, code_drift, structure_drift = [], [], []
	for page in public_pages(docs_root):
		source = os.path.join(docs_root, page)
		for language in languages:
			counterpart = os.path.join(docs_root, language, page)
			if not os.path.exists(counterpart):
				if page not in missing:
					missing.append(page)
				continue
			if code_blocks(source) != code_blocks(counterpart) and page not in code_drift:
				code_drift.append(page)
			if structure_counts(source) != structure_counts(counterpart) and page not in structure_drift:
				structure_drift.append(page)
	return Findings(sorted(missing), sorted(code_drift), sorted(structure_drift))


def main(argv=None):
	parser = argparse.ArgumentParser(description=__doc__)
	parser.add_argument("--docs", default="docs", help="documentation root (default: docs)")
	parser.add_argument("--lang", action="append", choices=LANGUAGES, help="check only this language (repeatable)")
	parser.add_argument("--require-complete", action="store_true", help="fail when a translation is missing")
	args = parser.parse_args(argv)

	findings = check(args.docs, args.lang)
	for name, values in (
		("missing", findings.missing),
		("code-drift", findings.code_drift),
		("structure-drift", findings.structure_drift),
	):
		print(f"{name}: {len(values)}")
		for value in values:
			print(f"  {value}")
	failed = bool(findings.code_drift or findings.structure_drift)
	if args.require_complete and findings.missing:
		failed = True
	return 1 if failed else 0


if __name__ == "__main__":
	sys.exit(main())
