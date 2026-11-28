#!/usr/bin/env python3
# Copyright © 2026 Michael Thomason. SPDX-License-Identifier: MIT
"""Tests for scripts/dev/build-info.sh.

Run with: python3 -I scripts/dev/build_info_test.py
"""

import json
import os
import plistlib
import subprocess
import tempfile
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
SCRIPT = HERE / "build-info.sh"

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


class BuildInfoTest(unittest.TestCase):
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

	def make_repo(self):
		manifest = self.write("Versions.yml", MANIFEST)
		subprocess.run(["git", "init", "-q", str(self.root)], check=True)
		subprocess.run(["git", "-C", str(self.root), "add", "."], check=True)
		subprocess.run(
			["git", "-C", str(self.root), "-c", "user.email=t@example.com",
			 "-c", "user.name=T", "commit", "-qm", "base"], check=True)
		return manifest

	def run_script(self, manifest, output, fmt, app_version="0.8.0", app_build="7"):
		return subprocess.run(
			[str(SCRIPT), "--manifest", str(manifest), "--output", str(output),
			 "--format", fmt, "--app-version", app_version,
			 "--app-build", app_build],
			capture_output=True, text=True, cwd=str(self.root))

	def test_plist_contains_identity_from_manifest(self):
		manifest = self.make_repo()
		output = self.root / "identity.plist"
		result = self.run_script(manifest, output, "plist")
		self.assertEqual(result.returncode, 0, result.stderr)
		values = plistlib.loads(output.read_bytes())
		self.assertEqual(values["MADAppVersion"], "0.8.0")
		self.assertEqual(values["MADAppBuild"], "7")
		self.assertEqual(values["MADBuildNumber"], "1")
		self.assertEqual(values["MADEngineVersion"], "9.0")
		self.assertEqual(values["MADEngineRevision"], "r1")
		self.assertEqual(values["MADContainerFormat"], "1.0")
		self.assertEqual(values["MADStoreRevision"], "2")
		self.assertEqual(values["MADServeProtocolVersion"], "1")
		self.assertEqual(len(values["MADSourceCommit"]), 40)
		self.assertEqual(values["MADSourceCommitShort"], values["MADSourceCommit"][:8])
		self.assertFalse(values["MADSourceDirty"])

	def test_json_matches_plist_fields(self):
		manifest = self.make_repo()
		output = self.root / "identity.json"
		result = self.run_script(manifest, output, "json")
		self.assertEqual(result.returncode, 0, result.stderr)
		values = json.loads(output.read_text(encoding="utf-8"))
		self.assertEqual(values["MADAppVersion"], "0.8.0")
		self.assertEqual(values["MADBuildNumber"], "1")
		self.assertEqual(values["MADEngineVersion"], "9.0")
		self.assertEqual(values["MADEngineRevision"], "r1")
		self.assertEqual(values["MADContainerFormat"], "1.0")
		self.assertIs(values["MADSourceDirty"], False)
		self.assertEqual(len(values["MADSourceCommit"]), 40)

	def test_dirty_tree_is_marked(self):
		manifest = self.make_repo()
		self.write("untracked.txt", "x")
		output = self.root / "identity.plist"
		result = self.run_script(manifest, output, "plist")
		self.assertEqual(result.returncode, 0, result.stderr)
		values = plistlib.loads(output.read_bytes())
		self.assertTrue(values["MADSourceDirty"])

	def test_outside_git_reports_unknown(self):
		manifest = self.write("Versions.yml", MANIFEST)
		output = self.root / "identity.plist"
		result = self.run_script(manifest, output, "plist")
		self.assertEqual(result.returncode, 0, result.stderr)
		values = plistlib.loads(output.read_bytes())
		self.assertEqual(values["MADSourceCommit"], "unknown")
		self.assertEqual(values["MADSourceCommitShort"], "unknown")
		self.assertEqual(values["MADBuildNumber"], "0")
		self.assertEqual(values["MADEngineRevision"], "r0")
		self.assertFalse(values["MADSourceDirty"])


if __name__ == "__main__":
	unittest.main()
