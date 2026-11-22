#!/usr/bin/env python3
# Copyright © 2026 Michael Thomason. SPDX-License-Identifier: MIT
"""Tests for the translation parity checker.

Run with: python3 -I scripts/docs/check_translations_test.py
"""

import sys
import tempfile
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

import check_translations


class CheckTranslationsTest(unittest.TestCase):
	def setUp(self):
		self._tmp = tempfile.TemporaryDirectory()
		self.root = Path(self._tmp.name)
		self.docs = self.root / "docs"
		self.docs.mkdir()

	def tearDown(self):
		self._tmp.cleanup()

	def write(self, relpath, text):
		path = self.root / relpath
		path.parent.mkdir(parents=True, exist_ok=True)
		path.write_text(text, encoding="utf-8")

	def test_public_pages_excludes_internal(self):
		self.write("docs/index.md", "# Home")
		self.write("docs/project/BUGS.md", "# B")
		self.write("docs/superpowers/x.md", "# X")
		self.write("docs/404.md", "# 404")
		self.write("docs/de/index.md", "# Start")
		self.assertEqual(check_translations.public_pages(str(self.docs)), ["index.md"])

	def test_missing_counterpart_is_reported(self):
		self.write("docs/a.md", "# A\n")
		findings = check_translations.check(str(self.docs), languages=["de"])
		self.assertIn("a.md", findings.missing)

	def test_code_block_drift_is_reported(self):
		self.write("docs/a.md", "```\nx\n```\n")
		self.write("docs/de/a.md", "```\ny\n```\n")
		findings = check_translations.check(str(self.docs), languages=["de"])
		self.assertIn("a.md", findings.code_drift)

	def test_structure_drift_is_reported(self):
		self.write("docs/a.md", "# A\n")
		self.write("docs/de/a.md", "# A\n## B\n")
		findings = check_translations.check(str(self.docs), languages=["de"])
		self.assertIn("a.md", findings.structure_drift)

	def test_identical_translation_passes(self):
		self.write("docs/a.md", "# A\n```\nx\n```\n")
		self.write("docs/de/a.md", "# A\n```\nx\n```\n")
		findings = check_translations.check(str(self.docs), languages=["de"])
		self.assertEqual((findings.missing, findings.code_drift, findings.structure_drift), ([], [], []))

	def test_lang_filter_checks_one_language(self):
		self.write("docs/a.md", "# A\n")
		self.write("docs/de/a.md", "# A\n")
		findings = check_translations.check(str(self.docs), languages=["de"])
		self.assertEqual(findings.missing, [])


if __name__ == "__main__":
	unittest.main()
