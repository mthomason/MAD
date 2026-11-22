#!/usr/bin/env python3
# Copyright © 2026 Michael Thomason. SPDX-License-Identifier: MIT
"""Tests for the facts and built-site leak checker.

Run with: python3 -I scripts/docs/check_site_facts_test.py
"""

import sys
import tempfile
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

import check_site_facts


class CheckSiteFactsTest(unittest.TestCase):
	def setUp(self):
		self._tmp = tempfile.TemporaryDirectory()
		self.root = Path(self._tmp.name)
		self.docs = self.root / "docs"
		self.marketing = self.root / "m"
		self.built = self.root / "built"
		for path in (self.docs, self.marketing, self.built):
			path.mkdir(parents=True, exist_ok=True)

	def tearDown(self):
		self._tmp.cleanup()

	def write(self, relpath, text):
		path = self.root / relpath
		path.parent.mkdir(parents=True, exist_ok=True)
		path.write_text(text, encoding="utf-8")

	def test_matching_version_files_pass(self):
		self.write("docs/_data/versions.yml", 'engine_version: "9.0"\n')
		self.write("m/_data/versions.yml", 'engine_version: "9.0"\n')
		self.assertEqual(check_site_facts.version_mismatches(str(self.docs), str(self.marketing)), [])

	def test_mismatched_version_files_fail(self):
		self.write("docs/_data/versions.yml", 'engine_version: "9.0"\n')
		self.write("m/_data/versions.yml", 'engine_version: "9.1"\n')
		self.assertEqual(check_site_facts.version_mismatches(str(self.docs), str(self.marketing)), ["engine_version"])

	def test_banned_literal_in_public_text_fails(self):
		self.write("docs/index.md", "1,303 tests")
		self.assertIn("1,303", check_site_facts.banned_literals(str(self.docs)))

	def test_banned_literal_in_internal_tree_is_ignored(self):
		self.write("docs/project/x.md", "1,303 tests")
		self.assertEqual(check_site_facts.banned_literals(str(self.docs)), [])

	def test_section_number_is_not_a_version_literal(self):
		self.write("docs/a.md", "decision 9.1")
		self.assertEqual(check_site_facts.banned_literals(str(self.docs)), [])

	def test_version_9_1_is_flagged(self):
		self.write("docs/a.md", "engine 9.1")
		self.assertIn("9.1", check_site_facts.banned_literals(str(self.docs)))

	def test_localized_1303_forms_are_flagged(self):
		self.write("docs/a.md", "1.303 pruebas\n1 303 pruebas")
		self.assertIn("1,303", check_site_facts.banned_literals(str(self.docs)))

	def test_built_site_internal_directory_fails(self):
		(self.built / "project").mkdir(parents=True)
		self.assertIn("project", check_site_facts.built_leaks(str(self.built)))

	def test_built_site_credential_fails(self):
		self.write("built/a.html", "Root1@Root2")
		self.assertIn("credential", check_site_facts.built_leaks(str(self.built)))

	def test_built_marketing_source_markdown_fails(self):
		self.write("built/AGENTS.md", "# internal")
		self.assertIn("AGENTS.md", check_site_facts.built_leaks(str(self.built)))


if __name__ == "__main__":
	unittest.main()
