#!/usr/bin/env python3
# Copyright © 2026 Michael Thomason. SPDX-License-Identifier: MIT
"""Check site facts against the canonical data and scan for leaks.

Run with: python3 -I scripts/docs/check_site_facts.py [--docs docs]
          [--repo .] [--marketing PATH] [--built PATH]

--docs scans the public documentation tree for stale facts.
--marketing compares the marketing copy of versions.yml and scans it.
--repo scans the root and folder READMEs.
--built asserts the built tree contains no internal records or source Markdown.
The local Docker test credentials are intentionally public and are not scanned.
"""

import argparse
import glob
import os
import re
import sys

BANNED = (
	"v9.1.0-macos",
	"1,303",
	"1308",
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
PATH_EXTENSIONS = TEXT_EXTENSIONS | {
	".m", ".h", ".mm", ".c", ".cc", ".cpp", ".hpp", ".sh", ".bash", ".ps1",
	".psm1", ".bat", ".cmake", ".plist", ".pbxproj", ".xcconfig", ".in",
	".conf", ".properties", ".gradle", ".py",
}
SKIP_PATH_PARTS = {
	".git",
	".superpowers",
	"node_modules",
	"ThirdParty",
	os.path.join("Mac", "build"),
	".cli-deriveddata",
	os.path.join("Compressor", "build"),
	os.path.join("Compressor", "src"),
	os.path.join("Windows", "Engine", "build"),
	os.path.join("docs", "assets"),
	os.path.join("docs", ".jekyll-cache"),
	os.path.join("docs", "_site"),
	os.path.join("docs", "superpowers"),
	os.path.join("docs", "zh", "project"),
	os.path.join("docs", "zh", "archive"),
	os.path.join("scripts", "docs"),
}
MOVED_PATHS = {
	"docs/project/BUGS.md",
	"docs/project/BUGS_FIXED.md",
	"docs/project/TASKS.md",
	"docs/project/TODO.md",
	"docs/project/ROADMAP.md",
	"docs/project/FUTURE_FEATURES.md",
	"docs/project/WARNINGS_INVENTORY.md",
	"docs/project/WARNINGS_PLAN.md",
	"docs/project/APPSTORE.md",
	"docs/project/MAD_STRATEGY.md",
	"docs/project/MAD_FUTURE.md",
	"docs/project/MAD_SCRIPTING.md",
	"docs/project/MAD_STORE_MIGRATION.md",
	"docs/project/MAD_STORE_PHASE_C.md",
	"docs/project/MIGRATION_KICKOFF.md",
	"docs/project/DEVELOPER.md",
	"docs/project/TEST-DB-INFO.md",
	"docs/project/LOCALIZATION.md",
	"docs/project/MAD_APP_LOCALIZATION.md",
	"docs/project/MAD_DATASOURCE_AND_CONNECTION_UX.md",
	"docs/project/MAD_CLI.md",
	"docs/project/MAD_DATA_OBJECT.md",
	"docs/project/MAD_MULTI_SOURCE.md",
	"docs/project/MAD_SQL_ENTRY.md",
	"docs/project/SATELLITE_REPOS.md",
	"docs/project/MAD_LINUX.md",
	"docs/project/MAD_WINDOWS.md",
	"docs/project/MAD_MACOS.md",
	"docs/project/LIBRARIES.md",
	"docs/project/MAD_PDF_LINUX.md",
	"docs/project/MADDataTable_Architecture_Report.md",
	"docs/project/MADModel_Layer.md",
	"docs/project/MAD_ARRAY_CACHING.md",
}
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
		if literal == "1,303":
			if re.search(r"\b1[., ]303\b", text):
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
	return sorted(leaks)


def _skip_path(relative):
	relative = relative.replace(os.sep, "/")
	for part in SKIP_PATH_PARTS:
		part = part.replace(os.sep, "/")
		if relative == part or relative.startswith(part + "/"):
			return True
	return False


def moved_path_references(root):
	found = set()
	root = os.path.abspath(root)
	for dirpath, dirnames, filenames in os.walk(root):
		relative_dir = os.path.relpath(dirpath, root)
		if relative_dir == ".":
			relative_dir = ""
		elif _skip_path(relative_dir):
			dirnames[:] = []
			continue
		dirnames[:] = sorted(
			d for d in dirnames if not _skip_path(os.path.join(relative_dir, d))
		)
		for name in filenames:
			extension = os.path.splitext(name)[1].lower()
			if extension not in PATH_EXTENSIONS and name not in {"Dockerfile", ".dockerignore", ".gitignore"}:
				continue
			path = os.path.join(dirpath, name)
			try:
				with open(path, encoding="utf-8", errors="replace") as handle:
					text = handle.read()
			except OSError:
				continue
			for old in MOVED_PATHS:
				if old in text:
					found.add(old)
	return sorted(found)


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
	moved = moved_path_references(args.repo) if args.repo else []

	banned = [literal for literal in BANNED if literal in banned]
	for name, values in (
		("version-mismatch", mismatches),
		("banned", banned),
		("moved-paths", moved),
		("leaks", leaks),
	):
		print(f"{name}: {len(values)}")
		for value in values:
			print(f"  {value}")
	return 1 if mismatches or banned or moved or leaks else 0


if __name__ == "__main__":
	sys.exit(main())
