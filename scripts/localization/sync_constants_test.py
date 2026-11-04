#!/usr/bin/env python3
# Copyright © 2026 Michael Thomason. SPDX-License-Identifier: MIT
"""Tests for the constant-key catalog sync.

Run with: python3 -I scripts/localization/sync_constants_test.py
"""

import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
SYNC = HERE / "sync_constants.py"


class SyncConstantsTest(unittest.TestCase):
	def setUp(self):
		self._tmp = tempfile.TemporaryDirectory()
		self.root = Path(self._tmp.name)
		self.catalog = self.root / "MADDesigner/Resources/Localizable.xcstrings"
		self.catalog.parent.mkdir(parents=True)
		self.catalog.write_text(json.dumps({
			"sourceLanguage": "en",
			"strings": {"Existing": {"comment": "keep", "extractionState": "manual"}},
			"version": "1.0",
		}), encoding="utf-8")

	def tearDown(self):
		self._tmp.cleanup()

	def write(self, relative, text):
		path = self.root / relative
		path.parent.mkdir(parents=True, exist_ok=True)
		path.write_text(text, encoding="utf-8")

	def run_sync(self, *args):
		return subprocess.run(
			[sys.executable, "-I", str(SYNC), "--root", str(self.root),
			 "--catalog", str(self.catalog), *args],
			capture_output=True, text=True,
		)

	def catalog_data(self):
		return json.loads(self.catalog.read_text(encoding="utf-8"))

	def test_adds_used_constant_and_preserves_existing(self):
		self.write("MADDesigner/Source/Constants.m", """\
NSString * const LocalTitle = @"Local Title";
NSString * value = NSLocalizedString(LocalTitle, nil);
""")
		result = self.run_sync()
		self.assertEqual(result.returncode, 0, result.stderr + result.stdout)
		data = self.catalog_data()

		self.assertEqual(data["version"], "1.0")
		self.assertEqual(data["sourceLanguage"], "en")
		self.assertEqual(data["strings"]["Existing"]["comment"], "keep")
		entry = data["strings"]["Local Title"]
		self.assertEqual(entry["extractionState"], "manual")
		self.assertIn("LocalTitle", entry["comment"])
		self.assertIn("Constants.m", entry["comment"])

	def test_is_idempotent(self):
		self.write("MADDesigner/Source/Constants.m", """\
static NSString * const LocalTitle = @"Local Title";
NSString * value = NSLocalizedString(LocalTitle, nil);
""")
		self.assertEqual(self.run_sync().returncode, 0)
		first = self.catalog_data()
		second_run = self.run_sync()
		self.assertEqual(second_run.returncode, 0, second_run.stderr + second_run.stdout)
		self.assertEqual(self.catalog_data(), first)
		self.assertIn("Added 0", second_run.stdout)

	def test_check_fails_when_a_key_is_missing(self):
		self.write("MADDesigner/Source/Constants.m",
			'NSString * const LocalTitle = @"Local Title";\n'
			'NSString * value = NSLocalizedString(LocalTitle, nil);\n')
		before = self.run_sync("--check")
		self.assertEqual(before.returncode, 1)
		self.assertIn("Local Title", before.stdout)

		self.assertEqual(self.run_sync().returncode, 0)
		after = self.run_sync("--check")
		self.assertEqual(after.returncode, 0, after.stderr + after.stdout)

	def test_unresolved_symbol_is_reported_but_not_fatal(self):
		self.write("MADDesigner/Source/Constants.m",
			'NSString * value = NSLocalizedString(UnknownSymbol, nil);\n')
		result = self.run_sync("--check")
		self.assertEqual(result.returncode, 0, result.stderr + result.stdout)
		self.assertIn("UnknownSymbol", result.stdout)


if __name__ == "__main__":
	unittest.main()
