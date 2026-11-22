#!/usr/bin/env python3
# Copyright © 2026 Michael Thomason. SPDX-License-Identifier: MIT
"""Check site facts against the canonical data and scan for leaks.

Run with: python3 -I scripts/docs/check_site_facts.py [--docs docs]
          [--repo .] [--marketing PATH] [--built PATH]

--docs scans the public documentation tree for stale facts.
--marketing compares the marketing copy of versions.yml and scans it.
--repo scans the root and folder READMEs.
--built asserts the built tree contains no internal records or credentials.
"""

import argparse
import glob
import os
import re
import sys

BANNED = (
	"v9.1.0-macos",
	"9.1",
	"1,303",
	"126 test executables",
	"Eleven of the fourteen",
	"not yet localized",
	"instrumented but not localized",
)

EXCLUDED_DIRS = {
	".git",
	"_site",
	".jekyll-cache",
	"project",
	"archive",
	"superpowers",
	"assets",
	"img",
	"css",
	"js",
}

TEXT_EXTENSIONS = {".md", ".html", ".yml", ".yaml", ".txt", ".js", ".css", ".xml", ".json"}
CREDENTIALS = ("Root1@Root2", "mad_test_pw")
LEAK_DIRS = {"project": "project", "archive": "archive", "superpowers": "superpowers"}
LEAK_PREFIXES = (
	"BUGS",
	"TASKS",
	"ROADMAP",
	"DEVELOPER",
	"TEST-DB-INFO",
	"MAD_DATASOURCE_AND_CONNECTION_UX",
)


def parse_flat_yaml(path):
	values = {}
	with open(path, encoding="utf-8", errors="replace") as handle:
		for line in handle:
			line = line.split("#", 1)[0].strip()
			if not line or ":" not in line:
				continue
			key, value = line.split(":", 1)
			key = key.strip()
			if key:
				values[key] = value.strip().strip('"').strip("'")
	return values


def version_mismatches(docs_root, marketing_root):
	docs_file = os.path.join(docs_root, "_data", "versions.yml")
	marketing_file = os.path.join(marketing_root, "_data", "versions.yml")
	if not (os.path.exists(docs_file) and os.path.exists(marketing_file)):
		return []
	docs = parse_flat_yaml(docs_file)
	marketing = parse_flat_yaml(marketing_file)
	return sorted(key for key in docs.keys() & marketing.keys() if docs[key] != marketing[key])


def _found(text):
	found = []
	for literal in BANNED:
		if literal == "9.1":
			if re.search(r"(?:v9\.1|\bengine\s+9\.1\b|\bapp\s+9\.1\b|9\.1\s+\(r)", text, re.I):
				found.append(literal)
		elif literal in text:
			found.append(literal)
	return found


def _banned_in_files(paths):
	found = set()
	for path in paths:
		if not os.path.exists(path):
			continue
		with open(path, encoding="utf-8", errors="replace") as handle:
			found.update(_found(handle.read()))
	return [literal for literal in BANNED if literal in found]


def banned_literals(root):
	found = set()
	for dirpath, dirnames, filenames in os.walk(root):
		dirnames[:] = sorted(d for d in dirnames if d not in EXCLUDED_DIRS)
		for name in filenames:
			if os.path.splitext(name)[1].lower() not in TEXT_EXTENSIONS:
				continue
			path = os.path.join(dirpath, name)
			with open(path, encoding="utf-8", errors="replace") as handle:
				found.update(_found(handle.read()))
	return [literal for literal in BANNED if literal in found]


def repo_documents(repo):
	patterns = (
		"README.md",
		"translations/*.md",
		"Mac/README*.md",
		"Linux/README*.md",
		"CLI/Fixtures/README*.md",
		"MADFileManager/README*.md",
		"MADTds/README*.md",
		"satellites/mad-action/README*.md",
	)
	paths = []
	for pattern in patterns:
		paths.extend(glob.glob(os.path.join(repo, pattern)))
	return paths


def built_leaks(built_root):
	leaks = set()
	for dirpath, dirnames, filenames in os.walk(built_root):
		for name in dirnames:
			if name in LEAK_DIRS:
				leaks.add(LEAK_DIRS[name])
		for name in filenames:
			if name.startswith(LEAK_PREFIXES):
				leaks.add(name)
			if name.endswith(".md"):
				leaks.add(name)
			extension = os.path.splitext(name)[1].lower()
			if extension not in TEXT_EXTENSIONS:
				continue
			path = os.path.join(dirpath, name)
			with open(path, encoding="utf-8", errors="replace") as handle:
				if any(credential in handle.read() for credential in CREDENTIALS):
					leaks.add("credential")
	return sorted(leaks)


def main(argv=None):
	parser = argparse.ArgumentParser(description=__doc__)
	parser.add_argument("--docs", help="public documentation root")
	parser.add_argument("--repo", help="repository root for the root and folder READMEs")
	parser.add_argument("--marketing", help="marketing repository root")
	parser.add_argument("--built", help="built site to check for leaks")
	args = parser.parse_args(argv)

	mismatches = []
	banned = set()
	if args.docs:
		banned.update(banned_literals(args.docs))
	if args.marketing:
		if args.docs:
			mismatches = version_mismatches(args.docs, args.marketing)
		banned.update(banned_literals(args.marketing))
	if args.repo:
		banned.update(_banned_in_files(repo_documents(args.repo)))
	leaks = built_leaks(args.built) if args.built else []

	banned = [literal for literal in BANNED if literal in banned]
	for name, values in (("version-mismatch", mismatches), ("banned", banned), ("leaks", leaks)):
		print(f"{name}: {len(values)}")
		for value in values:
			print(f"  {value}")
	return 1 if mismatches or banned or leaks else 0


if __name__ == "__main__":
	sys.exit(main())
