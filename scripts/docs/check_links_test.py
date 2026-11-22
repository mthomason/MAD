#!/usr/bin/env python3
# Copyright © 2026 Michael Thomason. SPDX-License-Identifier: MIT
"""Tests for the repository-wide Markdown link checker.

Run with: python3 -I scripts/docs/check_links_test.py
"""

import sys
import tempfile
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

import check_links


class CheckLinksTest(unittest.TestCase):
	def setUp(self):
		self._tmp = tempfile.TemporaryDirectory()
		self.root = Path(self._tmp.name)

	def tearDown(self):
		self._tmp.cleanup()

	def write(self, relpath, text):
		path = self.root / relpath
		path.parent.mkdir(parents=True, exist_ok=True)
		path.write_text(text, encoding="utf-8")

	def test_valid_relative_link(self):
		self.write("a.md", "[b](b.md)")
		self.write("b.md", "# b")
		self.assertEqual(check_links.check_links(str(self.root)), [])

	def test_broken_relative_link(self):
		self.write("a.md", "[b](missing.md)")
		self.assertEqual(check_links.check_links(str(self.root)), [("a.md", 1, "missing.md")])

	def test_ignores_fenced_code(self):
		self.write("a.md", "```\n[x](missing.md)\n```\n")
		self.assertEqual(check_links.check_links(str(self.root)), [])

	def test_ignores_external_anchor_and_mailto(self):
		self.write("a.md", "[x](https://e)\n[y](#a)\n[z](mailto:a@b)\n")
		self.assertEqual(check_links.check_links(str(self.root)), [])

	def test_resolves_absolute_repo_path(self):
		self.write("sub/a.md", "[x](/b.md)")
		self.write("b.md", "# b")
		self.assertEqual(check_links.check_links(str(self.root)), [])

	def test_image_link(self):
		self.write("a.md", "![x](missing.png)")
		self.assertEqual(check_links.check_links(str(self.root)), [("a.md", 1, "missing.png")])

	def test_anchor_is_stripped(self):
		self.write("a.md", "[x](b.md#s)")
		self.write("b.md", "# b")
		self.assertEqual(check_links.check_links(str(self.root)), [])

	def test_html_resolves_to_markdown_source(self):
		self.write("a.md", "[b](b.html)")
		self.write("b.md", "# b")
		self.assertEqual(check_links.check_links(str(self.root)), [])

	def test_ignores_liquid_links(self):
		self.write("a.md", '[x]({{ "/" | relative_url }})')
		self.assertEqual(check_links.check_links(str(self.root)), [])

	def test_skips_internal_superpowers_tree(self):
		self.write("docs/superpowers/x.md", "[x](missing.md)")
		self.assertEqual(check_links.check_links(str(self.root)), [])


if __name__ == "__main__":
	unittest.main()
