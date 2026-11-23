#!/usr/bin/env python3
# Copyright © 2026 Michael Thomason. SPDX-License-Identifier: MIT
"""Tests for the Linux/Windows source-inventory parity checker.

Run with: python3 -I scripts/dev/check_source_lists_test.py
"""

import io
import sys
import tempfile
import unittest
from contextlib import redirect_stderr, redirect_stdout
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

import check_source_lists


class CheckSourceListsTest(unittest.TestCase):
	def setUp(self):
		self._tmp = tempfile.TemporaryDirectory()
		self.root = Path(self._tmp.name)

	def tearDown(self):
		self._tmp.cleanup()

	def write(self, relpath, text):
		path = self.root / relpath
		path.parent.mkdir(parents=True, exist_ok=True)
		path.write_text(text, encoding="utf-8")
		return path

	def write_inventory(self, relpath, framework, entries, comments=""):
		body = "\n".join('\t"${SOURCE_DIR}/%s"' % entry for entry in entries)
		text = "%s\nset(%s_SOURCES\n%s\n)\n" % (comments, framework, body)
		return self.write(relpath, text)

	def write_pair(self, framework, linux_entries, windows_entries, comments=""):
		self.write_inventory("Linux/cmake/%sSources.cmake" % framework,
			framework, linux_entries, comments)
		self.write_inventory("Windows/Engine/cmake/%sSources.cmake" % framework,
			framework, windows_entries, comments)

	def load(self):
		linux = check_source_lists.load(self.root / "Linux" / "cmake")
		windows = check_source_lists.load(self.root / "Windows" / "Engine" / "cmake")
		return linux, windows

	def test_matching_inventories_agree(self):
		self.write_pair("MAD", ["B.m", "A.mm", "c.c"], ["c.c", "A.mm", "B.m"])
		linux, windows = self.load()
		self.assertEqual(check_source_lists.compare(linux, windows), [])
		with redirect_stdout(io.StringIO()):
			self.assertEqual(check_source_lists.main(["--root", str(self.root)]), 0)

	def test_order_does_not_matter(self):
		self.write_pair("MAD", ["A.m", "B.m"], ["B.m", "A.m"])
		linux, windows = self.load()
		self.assertEqual(check_source_lists.compare(linux, windows), [])

	def test_missing_from_windows_is_reported(self):
		self.write_pair("MAD", ["A.m", "B.m"], ["A.m"])
		linux, windows = self.load()
		self.assertEqual(check_source_lists.compare(linux, windows),
			[("MAD", "missing-windows", "B.m")])

	def test_missing_from_linux_is_reported(self):
		self.write_pair("MAD", ["A.m"], ["A.m", "B.mm"])
		linux, windows = self.load()
		self.assertEqual(check_source_lists.compare(linux, windows),
			[("MAD", "missing-linux", "B.mm")])

	def test_case_difference_is_reported_both_ways(self):
		self.write_pair("MAD", ["Foo.m"], ["foo.m"])
		linux, windows = self.load()
		self.assertEqual(check_source_lists.compare(linux, windows), [
			("MAD", "missing-windows", "Foo.m"),
			("MAD", "missing-linux", "foo.m"),
		])

	def test_comments_are_ignored(self):
		comments = "# Excluded:\n#   NotCompiled.m   a view\n"
		self.write_pair("MAD", ["A.m"], ["A.m"], comments)
		linux, windows = self.load()
		self.assertEqual(check_source_lists.compare(linux, windows), [])

	def test_headers_are_ignored(self):
		self.write_pair("MAD", ["A.m", "A.h"], ["A.m"])
		linux, windows = self.load()
		self.assertEqual(check_source_lists.compare(linux, windows), [])

	def test_non_inventory_is_ignored(self):
		self.write("Linux/cmake/MADLinuxFramework.cmake",
			"function(mad_add_framework name)\nendfunction()\n")
		self.write_pair("MAD", ["A.m"], ["A.m"])
		linux, windows = self.load()
		self.assertNotIn("MADLinuxFramework", linux)
		self.assertEqual(check_source_lists.compare(linux, windows), [])

	def test_missing_inventory_is_reported(self):
		self.write_inventory("Linux/cmake/MADSources.cmake", "MAD", ["A.m"])
		(self.root / "Windows" / "Engine" / "cmake").mkdir(parents=True, exist_ok=True)
		linux, windows = self.load()
		problems = check_source_lists.compare(linux, windows)
		self.assertEqual(len(problems), 1)
		self.assertEqual(problems[0][:2], ("MAD", "missing-inventory"))
		self.assertIn("Windows", problems[0][2])

	def test_missing_directories_exit_two(self):
		err = io.StringIO()
		with redirect_stderr(err):
			status = check_source_lists.main(["--root", str(self.root)])
		self.assertEqual(status, 2)
		self.assertIn("error:", err.getvalue())

	def test_reports_are_clear(self):
		self.write_pair("MAD", ["A.m", "B.m"], ["A.m", "C.m"])
		linux, windows = self.load()
		lines = check_source_lists.describe(linux, windows,
			check_source_lists.compare(linux, windows))
		report = "\n".join(lines)
		self.assertIn("Source inventories disagree", report)
		self.assertIn("missing from Windows/Engine/cmake/MADSources.cmake: B.m", report)
		self.assertIn("missing from Linux/cmake/MADSources.cmake: C.m", report)

	def test_read_only(self):
		paths = [
			self.write_inventory("Linux/cmake/MADSources.cmake", "MAD", ["A.m"]),
			self.write_inventory("Windows/Engine/cmake/MADSources.cmake", "MAD", ["B.m"]),
		]
		before = [path.read_bytes() for path in paths]
		linux, windows = self.load()
		check_source_lists.compare(linux, windows)
		self.assertEqual([path.read_bytes() for path in paths], before)
		files = sorted(path.relative_to(self.root) for path in self.root.rglob("*")
			if path.is_file())
		self.assertEqual(files, sorted(path.relative_to(self.root) for path in paths))


if __name__ == "__main__":
	unittest.main()
