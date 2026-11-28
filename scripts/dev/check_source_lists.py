#!/usr/bin/env python3
# Copyright © 2026 Michael Thomason. SPDX-License-Identifier: MIT
"""Check that the Linux and Windows headless source inventories agree.

MAD compiles the same headless engine on Linux (GNUstep) and Windows
(Clang/MSVC), and each build carries its own per-framework inventory:

	Linux/cmake/<Framework>Sources.cmake
	Windows/Engine/cmake/<Framework>Sources.cmake

The two inventories must name the same implementation files.  Only the
comments may differ: they carry the exclusion reasons, which are written per
platform.  This script compares the two file sets and prints, normed by
framework, what is missing from either side.

It is read-only.  It opens the inventories, never writes, and never invokes a
build.

Run with:
	python3 -I scripts/dev/check_source_lists.py
	python3 -I scripts/dev/check_source_lists.py --root /path/to/repo

Exit status: 0 when the inventories agree, 1 when they differ, 2 on a usage or
I/O error.
"""

import argparse
import re
import sys
from pathlib import Path

# A set block is `set(NAME_SOURCES` at the start of a line through the closing
# `)` on its own line.  Anchoring the close keeps a stray `)` in a comment from
# ending the block early.
SOURCES_RE = re.compile(r"^set\(\s*([A-Za-z0-9_]+)_SOURCES\b.*?^\)\s*$", re.S | re.M)

# Only implementation files are compiled; a header in the list changes nothing.
ENTRY_RE = re.compile(r'"([^"]+\.(?:m|mm|c))"')
SOURCE_PREFIX = "${SOURCE_DIR}/"


def parse_inventory(path):
	"""Return (framework, sorted implementation paths), or None.

	None means the file is not a source inventory (for example
	MADLinuxFramework.cmake, the build helper), not that the list is empty.
	"""
	text = Path(path).read_text(encoding="utf-8")
	match = SOURCES_RE.search(text)
	if match is None:
		return None

	files = []
	for entry in ENTRY_RE.findall(match.group(0)):
		if entry.startswith(SOURCE_PREFIX):
			entry = entry[len(SOURCE_PREFIX):]
		files.append(entry.replace("\\", "/").lstrip("./"))
	return match.group(1), sorted(files)


def load(tree):
	"""Map framework name to (path, files) for every inventory in a tree."""
	if not tree.is_dir():
		raise FileNotFoundError(str(tree))
	inventories = {}
	for path in sorted(tree.glob("*.cmake")):
		parsed = parse_inventory(path)
		if parsed is None:
			continue
		framework, files = parsed
		inventories[framework] = (path, files)
	return inventories


def compare(linux, windows):
	"""Return (framework, kind, detail) problems between two inventories.

	kind is one of:
		missing-inventory  one tree has no inventory for the framework
		missing-windows    named by Linux, absent from the Windows list
		missing-linux      named by Windows, absent from the Linux list
	"""
	problems = []
	for framework in sorted(set(linux) | set(windows)):
		if framework not in windows:
			problems.append((framework, "missing-inventory",
				"Windows/Engine/cmake has no %sSources.cmake" % framework))
			continue
		if framework not in linux:
			problems.append((framework, "missing-inventory",
				"Linux/cmake has no %sSources.cmake" % framework))
			continue

		linux_files = set(linux[framework][1])
		windows_files = set(windows[framework][1])
		for name in sorted(linux_files - windows_files):
			problems.append((framework, "missing-windows", name))
		for name in sorted(windows_files - linux_files):
			problems.append((framework, "missing-linux", name))
	return problems


def describe(linux, windows, problems):
	"""Return the report lines for a comparison."""
	if not problems:
		files = sum(len(entry[1]) for entry in linux.values())
		return ["Source inventories agree: %d frameworks, %d files total."
			% (len(linux), files)]

	lines = ["Source inventories disagree (%d problem%s):"
		% (len(problems), "" if len(problems) == 1 else "s")]
	current = None
	for framework, kind, detail in problems:
		if framework != current:
			lines.append("")
			lines.append(framework)
			current = framework
		if kind == "missing-inventory":
			lines.append("  " + detail)
		elif kind == "missing-windows":
			lines.append("  missing from Windows/Engine/cmake/%sSources.cmake: %s"
				% (framework, detail))
		else:
			lines.append("  missing from Linux/cmake/%sSources.cmake: %s"
				% (framework, detail))
	return lines


def main(argv=None):
	parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
	parser.add_argument("--root", default=None,
		help="repository root (default: the parent of scripts/)")
	args = parser.parse_args(argv)

	root = Path(args.root).resolve() if args.root else Path(__file__).resolve().parents[2]
	try:
		linux = load(root / "Linux" / "cmake")
		windows = load(root / "Windows" / "Engine" / "cmake")
	except (OSError, UnicodeDecodeError) as error:
		print("error: %s" % error, file=sys.stderr)
		return 2

	problems = compare(linux, windows)
	for line in describe(linux, windows, problems):
		print(line)
	return 0 if not problems else 1


if __name__ == "__main__":
	sys.exit(main())
