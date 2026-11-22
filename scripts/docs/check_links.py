#!/usr/bin/env python3
# Copyright © 2026 Michael Thomason. SPDX-License-Identifier: MIT
"""Check every relative Markdown link in the repository.

Run with: python3 -I scripts/docs/check_links.py [--root PATH]

External URLs, anchors, mailto links, and links inside code are ignored.
"""

import argparse
import os
import re
import sys
from urllib.parse import unquote, urlparse

SKIP_DIRS = {
	".git",
	".superpowers",
	".cli-deriveddata",
	"ThirdParty",
	"node_modules",
	os.path.join("Compressor", "build"),
	os.path.join("Compressor", "src"),
	os.path.join("Mac", "build"),
	os.path.join("docs", ".jekyll-cache"),
	os.path.join("docs", "_site"),
	os.path.join("docs", "superpowers"),
}

LINK_RE = re.compile(r"!?\[[^\]]*\]\(([^)]+)\)")
CODE_SPAN_RE = re.compile(r"`[^`]*`")


def _is_skipped(root, dirpath):
	rel = os.path.relpath(dirpath, root)
	if rel == ".":
		return False
	return any(rel == skip or rel.startswith(skip + os.sep) for skip in SKIP_DIRS)


def _target_path(raw):
	target = raw.strip()
	if target.startswith("<") and target.endswith(">"):
		target = target[1:-1].strip()
	if " " in target:
		target = target.split(" ", 1)[0]
	return target


def _should_check(target):
	if not target:
		return False
	if "{{" in target or "{%" in target:
		return False
	if target.startswith(("#", "http://", "https://", "mailto:", "data:", "//")):
		return False
	return True


def _target_exists(path):
	if os.path.exists(path):
		return True
	if path.endswith(".html"):
		markdown = path[:-5] + ".md"
		if os.path.exists(markdown):
			return True
	return False


def _resolve(root, source, target):
	path = unquote(urlparse(target).path)
	if not path:
		return None
	if path.startswith("/"):
		return os.path.normpath(os.path.join(root, path.lstrip("/")))
	return os.path.normpath(os.path.join(os.path.dirname(source), path))


def check_links(root):
	root = os.path.abspath(root)
	findings = []
	for dirpath, dirnames, filenames in os.walk(root):
		if _is_skipped(root, dirpath):
			dirnames[:] = []
			continue
		dirnames[:] = sorted(d for d in dirnames if not _is_skipped(root, os.path.join(dirpath, d)))
		for name in sorted(filenames):
			if not name.endswith(".md"):
				continue
			path = os.path.join(dirpath, name)
			in_fence = False
			with open(path, encoding="utf-8", errors="replace") as handle:
				for lineno, line in enumerate(handle, 1):
					stripped = line.lstrip()
					if stripped.startswith("```") or stripped.startswith("~~~"):
						in_fence = not in_fence
						continue
					if in_fence:
						continue
					line = CODE_SPAN_RE.sub("", line)
					for match in LINK_RE.finditer(line):
						target = _target_path(match.group(1))
						if not _should_check(target):
							continue
						resolved = _resolve(root, path, target)
						if resolved is None or _target_exists(resolved):
							continue
						findings.append((os.path.relpath(path, root), lineno, target))
	findings.sort()
	return findings


def main(argv=None):
	parser = argparse.ArgumentParser(description=__doc__)
	parser.add_argument("--root", default=".", help="repository root (default: .)")
	args = parser.parse_args(argv)
	findings = check_links(args.root)
	print(f"broken: {len(findings)}")
	for path, lineno, target in findings:
		print(f"  {path}:{lineno} -> {target}")
	return 1 if findings else 0


if __name__ == "__main__":
	sys.exit(main())
