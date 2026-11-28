#!/usr/bin/env python3
# Copyright © 2026 Michael Thomason. SPDX-License-Identifier: MIT
"""Tests for the version manifest checker.

Run with: python3 -I scripts/dev/versions_test.py
"""

import sys
import tempfile
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

import versions


MANIFEST = """\
schema: "1"
next_release: "0.8.0"
next_tag: "v0.8.0"
published_release: "0.7.0"
published_tag: "v0.7.0"
macos_app_version: "0.8.0"
windows_app_version: "0.8.0"
ios_app_version: "9.0"
ios_build_floor: "0"
engine_version: "9.0"
published_engine_revision: "r4433"
container_major: "1"
container_minor: "0"
store_revision: "2"
serve_protocol_version: "1"
"""


class VersionsTest(unittest.TestCase):
	def setUp(self):
		self._tmp = tempfile.TemporaryDirectory()
		self.root = Path(self._tmp.name)

	def tearDown(self):
		self._tmp.cleanup()

	def write(self, relpath, text):
		path = self.root / relpath
		path.parent.mkdir(parents=True, exist_ok=True)
		path.write_text(text, encoding="utf-8")

	def make_repo(self):
		self.write("Versions.yml", MANIFEST)
		self.write("docs/_data/versions.yml", "\n".join([
			'engine_version: "9.0"',
			'engine_revision: "r4433"',
			'macos_app_version: "0.7"',
			'windows_app_version: "0.7"',
			'ios_app_status: "between releases; returns early 2027"',
			'release_tag: "v0.7.0"',
			'release_base_url: "https://github.com/mthomason/MAD/releases/download/v0.7.0"',
			'headless_frameworks: 12',
			"",
		]))
		self.write("MADDesigner/Resources/Assets/MADMeta.plist", "\n".join([
			'<?xml version="1.0" encoding="UTF-8"?>',
			'<plist version="1.0"><dict>',
			"<key>CFBundleShortVersionString</key><string>9.0</string>",
			"<key>MADRevision</key><string>4230</string>",
			"</dict></plist>",
			"",
		]))
		self.write("MAD/Source/MADConstants.m",
				   "const uint16_t MADFileFormatMajorVersion = 1;\n"
				   "const uint16_t MADFileFormatMinorVersion = 0;\n")
		self.write("MAD/Source/rptq/store/MADStoreSchema.m",
				   "NSInteger const MADStoreCurrentVersion = 2;\n")
		self.write("Windows/package.ps1",
				   "# Values come from Versions.yml.\n"
				   "[string]$Version\n")
		self.write("Windows/App/Mad.Designer.Windows/Infrastructure/AppInfo.cs",
				   "public static class AppInfo { }\n")
		self.write("README.md", "\n".join([
			"[macOS](https://github.com/mthomason/MAD/releases/download/v0.7.0/MAD-Designer-macOS.dmg)",
			"[Windows](https://github.com/mthomason/MAD/releases/download/v0.7.0/MAD-Designer-Windows-0.7.zip)",
			"",
		]))

	def test_manifest_parses_flat_keys(self):
		self.write("Versions.yml", 'next_release: "0.8.0"\n')
		self.assertEqual(versions.parse_flat_yaml(str(self.root / "Versions.yml")),
						 {"next_release": "0.8.0"})

	def test_docs_projection_uses_published_values(self):
		self.write("Versions.yml", MANIFEST)
		manifest = versions.load_manifest(str(self.root))
		projection = versions.docs_projection(manifest)
		self.assertEqual(projection["macos_app_version"], "0.7")
		self.assertEqual(projection["windows_app_version"], "0.7")
		self.assertEqual(projection["release_tag"], "v0.7.0")
		self.assertEqual(projection["engine_version"], "9.0")
		self.assertEqual(projection["engine_revision"], "r4433")
		self.assertEqual(projection["release_base_url"],
						 "https://github.com/mthomason/MAD/releases/download/v0.7.0")

	def test_check_reports_engine_mismatch(self):
		self.make_repo()
		self.write("MADDesigner/Resources/Assets/MADMeta.plist", "\n".join([
			'<?xml version="1.0" encoding="UTF-8"?>',
			'<plist version="1.0"><dict>',
			"<key>CFBundleShortVersionString</key><string>9.1</string>",
			"<key>MADRevision</key><string>4230</string>",
			"</dict></plist>",
			"",
		]))
		problems = versions.check(str(self.root))
		self.assertTrue(any("MADMeta.plist" in problem for problem in problems), problems)

	def test_check_reports_docs_drift(self):
		self.make_repo()
		self.write("docs/_data/versions.yml", 'release_tag: "v0.9.0"\n')
		problems = versions.check(str(self.root))
		self.assertTrue(any("docs/_data/versions.yml" in problem for problem in problems),
						problems)

	def test_check_reports_stale_windows_default(self):
		self.make_repo()
		self.write("Windows/package.ps1",
				   '[string]$Version = "0.7"\n[string]$EngineVersion = "9.0 (r4433)"\n')
		problems = versions.check(str(self.root))
		self.assertTrue(any("package.ps1" in problem for problem in problems), problems)

	def test_check_reports_stale_download_link(self):
		self.make_repo()
		self.write("README.md",
				   "[x](https://github.com/mthomason/MAD/releases/download/v0.9.0/a.zip)\n")
		problems = versions.check(str(self.root))
		self.assertTrue(any("README.md" in problem for problem in problems), problems)

	def test_check_rejects_manifest_build_literal(self):
		self.make_repo()
		self.write("Versions.yml", MANIFEST + 'macos_build: "5000"\n')
		problems = versions.check(str(self.root))
		self.assertTrue(any("macos_build" in problem for problem in problems), problems)

	def test_check_rejects_meta_commit_count(self):
		self.make_repo()
		self.write("MADDesigner/Resources/Assets/MADMeta.plist", "\n".join([
			'<?xml version="1.0" encoding="UTF-8"?>',
			'<plist version="1.0"><dict>',
			"<key>CFBundleShortVersionString</key><string>9.0</string>",
			"<key>MADGitCommitCount</key><string>4433</string>",
			"</dict></plist>",
			"",
		]))
		problems = versions.check(str(self.root))
		self.assertTrue(any("MADGitCommitCount" in problem for problem in problems), problems)

	def test_check_validates_ios_build_floor(self):
		self.make_repo()
		self.write("Versions.yml", MANIFEST.replace('ios_build_floor: "0"', 'ios_build_floor: "abc"'))
		problems = versions.check(str(self.root))
		self.assertTrue(any("ios_build_floor" in problem for problem in problems), problems)

	def test_check_validates_published_engine_revision(self):
		self.make_repo()
		self.write("Versions.yml",
				   MANIFEST.replace('published_engine_revision: "r4433"',
									'published_engine_revision: "4433"'))
		problems = versions.check(str(self.root))
		self.assertTrue(any("published_engine_revision" in problem for problem in problems),
						problems)

	def test_check_passes_on_agreement(self):
		self.make_repo()
		self.assertEqual(versions.check(str(self.root)), [])


if __name__ == "__main__":
	unittest.main()
