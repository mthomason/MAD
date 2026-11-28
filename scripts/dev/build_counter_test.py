#!/usr/bin/env python3
# Copyright © 2026 Michael Thomason. SPDX-License-Identifier: MIT
"""Tests for MADDesigner/buildcounter.sh.

Run with: python3 -I scripts/dev/build_counter_test.py
"""

import os
import plistlib
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[1]
SCRIPT = REPO / "MADDesigner" / "buildcounter.sh"
BUILD_INFO = HERE / "build-info.sh"

MANIFEST = """\
schema: "1"
macos_app_version: "0.8.0"
windows_app_version: "0.8.0"
ios_app_version: "9.0"
ios_build_floor: "{floor}"
engine_version: "9.0"
published_engine_revision: "r4433"
container_major: "1"
container_minor: "0"
store_revision: "2"
serve_protocol_version: "1"
"""

INFO_PLIST = """\
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleShortVersionString</key>
	<string>9.0</string>
	<key>CFBundleVersion</key>
	<string>1</string>
</dict>
</plist>
"""


@unittest.skipUnless(os.path.exists("/usr/libexec/PlistBuddy"), "PlistBuddy is macOS-only")
class BuildCounterTest(unittest.TestCase):
	def setUp(self):
		self._tmp = tempfile.TemporaryDirectory()
		self.root = Path(self._tmp.name)
		(self.root / "app").mkdir()
		scripts = self.root / "scripts" / "dev"
		scripts.mkdir(parents=True)
		shutil.copy2(BUILD_INFO, scripts / "build-info.sh")
		products = self.root / "Products" / "App.app"
		products.mkdir(parents=True)
		(products / "Info.plist").write_text(INFO_PLIST, encoding="utf-8")

	def tearDown(self):
		self._tmp.cleanup()

	def write_manifest(self, floor):
		(self.root / "Versions.yml").write_text(MANIFEST.format(floor=floor),
												encoding="utf-8")

	def commit(self):
		subprocess.run(["git", "init", "-q", str(self.root)], check=True)
		subprocess.run(["git", "-C", str(self.root), "add", "."], check=True)
		subprocess.run(
			["git", "-C", str(self.root), "-c", "user.email=t@example.com",
			 "-c", "user.name=T", "commit", "-qm", "base"], check=True)

	def run_counter(self, platform):
		env = os.environ.copy()
		env.update({
			"PROJECT_DIR": str(self.root / "app"),
			"TARGET_BUILD_DIR": str(self.root / "Products"),
			"UNLOCALIZED_RESOURCES_FOLDER_PATH": "App.app",
			"INFOPLIST_PATH": "App.app/Info.plist",
			"PLATFORM_NAME": platform,
		})
		result = subprocess.run([str(SCRIPT)], cwd=str(self.root), env=env,
								capture_output=True, text=True)
		self.assertEqual(result.returncode, 0, result.stderr)
		info = plistlib.loads(
			(self.root / "Products" / "App.app" / "MADBuildInfo.plist").read_bytes())
		built = plistlib.loads(
			(self.root / "Products" / "App.app" / "Info.plist").read_bytes())
		return info, built

	def test_ios_floor_raises_the_build(self):
		self.write_manifest("5000")
		self.commit()
		info, built = self.run_counter("iphoneos")
		self.assertEqual(info["MADBuildNumber"], "1")
		self.assertEqual(info["MADEngineRevision"], "r1")
		self.assertEqual(info["MADAppBuild"], "5001")
		self.assertEqual(built["CFBundleVersion"], "5001")
		self.assertEqual(info["MADAppVersion"], "9.0")

	def test_macos_ignores_the_ios_floor(self):
		self.write_manifest("5000")
		self.commit()
		info, built = self.run_counter("macosx")
		self.assertEqual(info["MADAppBuild"], "1")
		self.assertEqual(built["CFBundleVersion"], "1")
		self.assertEqual(info["MADAppVersion"], "0.8.0")
		self.assertEqual(info["MADEngineRevision"], "r1")


if __name__ == "__main__":
	unittest.main()
