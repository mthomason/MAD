#!/usr/bin/env python3
# Copyright © 2026 Michael Thomason. SPDX-License-Identifier: MIT
"""Read, project, and check the MAD version manifest.

Run with: python3 -I scripts/dev/versions.py check
          python3 -I scripts/dev/versions.py docs
          python3 -I scripts/dev/versions.py read KEY

`Versions.yml` at the repository root is the single statement of intended
versions.  `check` fails when any surface disagrees with it; `docs` rewrites the
version keys of docs/_data/versions.yml from the published values; `read`
prints one key for build scripts.
"""

import argparse
import glob
import os
import plistlib
import re
import sys

MANIFEST_KEYS = (
	"schema",
	"next_release",
	"next_tag",
	"published_release",
	"published_tag",
	"macos_app_version",
	"windows_app_version",
	"ios_app_version",
	"ios_build_floor",
	"engine_version",
	"published_engine_revision",
	"container_major",
	"container_minor",
	"store_revision",
	"serve_protocol_version",
)

DOCS_KEYS = (
	"engine_version",
	"engine_revision",
	"macos_app_version",
	"windows_app_version",
	"ios_app_status",
	"release_tag",
	"release_base_url",
)

PUBLIC_DOC_DIRS = {"zh", "ja", "de", "es", "pt-br"}


def parse_flat_yaml(path):
	values = {}
	with open(path, encoding="utf-8", errors="replace") as handle:
		for line in handle:
			line = line.split("#", 1)[0].strip()
			if not line or ":" not in line:
				continue
			key, value = line.split(":", 1)
			key = key.strip()
			if key:
				values[key] = value.strip().strip('"').strip("'")
	return values


def load_manifest(repo_root):
	path = os.path.join(repo_root, "Versions.yml")
	if not os.path.exists(path):
		raise SystemExit("missing %s" % path)
	manifest = parse_flat_yaml(path)
	missing = [key for key in MANIFEST_KEYS if key not in manifest]
	if missing:
		raise SystemExit("Versions.yml is missing: %s" % ", ".join(missing))
	return manifest


def _short_release(value):
	parts = value.split(".")
	return ".".join(parts[:2]) if len(parts) >= 2 else value


def docs_projection(manifest):
	tag = manifest["published_tag"]
	# The docs site describes the published download.  When the manifest carries
	# the published engine version separately (the next build is ahead of the last
	# release), project it; the revision is always the published release's record.
	engine_version = manifest.get("published_engine_version",
								  manifest["engine_version"])
	engine_revision = manifest["published_engine_revision"]
	return {
		"engine_version": engine_version,
		"engine_revision": engine_revision,
		"macos_app_version": _short_release(manifest["published_release"]),
		"windows_app_version": _short_release(manifest["published_release"]),
		"ios_app_status": "between releases; returns early 2027",
		"release_tag": tag,
		"release_base_url": "https://github.com/mthomason/MAD/releases/download/%s" % tag,
	}


def _replace_flat_values(path, values):
	with open(path, encoding="utf-8", errors="replace") as handle:
		lines = handle.readlines()
	seen = set()
	output = []
	for line in lines:
		stripped = line.split("#", 1)[0].strip()
		if ":" in stripped:
			key = stripped.split(":", 1)[0].strip()
			if key in values:
				seen.add(key)
				output.append('%s: "%s"\n' % (key, values[key]))
				continue
		output.append(line)
	for key in values:
		if key not in seen:
			output.append('%s: "%s"\n' % (key, values[key]))
	with open(path, "w", encoding="utf-8") as handle:
		handle.writelines(output)


def _plist_value(path, key):
	with open(path, "rb") as handle:
		values = plistlib.load(handle)
	return values.get(key)


def _source_value(path, pattern):
	with open(path, encoding="utf-8", errors="replace") as handle:
		text = handle.read()
	match = re.search(pattern, text)
	return match.group(1) if match else None


def _public_files(repo_root):
	files = [
		os.path.join(repo_root, "README.md"),
	]
	files.extend(glob.glob(os.path.join(repo_root, "Mac", "README*.md")))
	files.extend(glob.glob(os.path.join(repo_root, "translations", "README*.md")))
	files.extend(glob.glob(os.path.join(repo_root, "docs", "*.md")))
	for entry in os.listdir(os.path.join(repo_root, "docs")) if os.path.isdir(
			os.path.join(repo_root, "docs")) else []:
		if entry in PUBLIC_DOC_DIRS:
			files.extend(glob.glob(os.path.join(repo_root, "docs", entry, "*.md")))
	return [path for path in sorted(set(files)) if os.path.exists(path)]


def check(repo_root):
	problems = []
	manifest = load_manifest(repo_root)

	for key in ("macos_build", "windows_build", "ios_build", "engine_revision"):
		if key in manifest:
			problems.append(
				"Versions.yml: %s is a build literal; build numbers are derived "
				"from git" % key)
	if not re.match(r"^\d+$", manifest["ios_build_floor"]):
		problems.append(
			"Versions.yml: ios_build_floor is %r, expected an integer"
			% manifest["ios_build_floor"])
	if not re.match(r"^r\d+$", manifest["published_engine_revision"]):
		problems.append(
			"Versions.yml: published_engine_revision is %r, expected r<N>"
			% manifest["published_engine_revision"])

	docs_path = os.path.join(repo_root, "docs", "_data", "versions.yml")
	if os.path.exists(docs_path):
		docs = parse_flat_yaml(docs_path)
		for key, expected in docs_projection(manifest).items():
			if key in docs and docs[key] != expected:
				problems.append(
					"docs/_data/versions.yml: %s is %r, expected %r"
					% (key, docs[key], expected))

	meta_path = os.path.join(repo_root, "MADDesigner", "Resources", "Assets",
							 "MADMeta.plist")
	if os.path.exists(meta_path):
		engine_version = _plist_value(meta_path, "CFBundleShortVersionString")
		# MADRevision is a separate legacy identifier; the advertised rNNNN is
		# generated per build, so MADMeta must not carry a commit count.
		if engine_version != manifest["engine_version"]:
			problems.append(
				"MADDesigner/Resources/Assets/MADMeta.plist: engine version is %r, "
				"expected %r" % (engine_version, manifest["engine_version"]))
		if _plist_value(meta_path, "MADGitCommitCount") is not None:
			problems.append(
				"MADDesigner/Resources/Assets/MADMeta.plist: MADGitCommitCount is a "
				"stale build-time value; remove it")

	constants_path = os.path.join(repo_root, "MAD", "Source", "MADConstants.m")
	if os.path.exists(constants_path):
		major = _source_value(
			constants_path, r"MADFileFormatMajorVersion\s*=\s*(\d+)")
		minor = _source_value(
			constants_path, r"MADFileFormatMinorVersion\s*=\s*(\d+)")
		if major != manifest["container_major"]:
			problems.append(
				"MAD/Source/MADConstants.m: container major is %r, expected %r"
				% (major, manifest["container_major"]))
		if minor != manifest["container_minor"]:
			problems.append(
				"MAD/Source/MADConstants.m: container minor is %r, expected %r"
				% (minor, manifest["container_minor"]))

	schema_path = os.path.join(repo_root, "MAD", "Source", "rptq", "store",
							   "MADStoreSchema.m")
	if os.path.exists(schema_path):
		revision = _source_value(
			schema_path, r"MADStoreCurrentVersion\s*=\s*(\d+)")
		if revision != manifest["store_revision"]:
			problems.append(
				"MAD/Source/rptq/store/MADStoreSchema.m: store revision is %r, "
				"expected %r" % (revision, manifest["store_revision"]))

	package_path = os.path.join(repo_root, "Windows", "package.ps1")
	if os.path.exists(package_path):
		with open(package_path, encoding="utf-8", errors="replace") as handle:
			text = handle.read()
		if re.search(r'\$Version\s*=\s*"[^"]*"', text):
			problems.append(
				"Windows/package.ps1: $Version carries a literal default; read "
				"Versions.yml instead")
		if "Versions.yml" not in text:
			problems.append("Windows/package.ps1: does not read Versions.yml")

	app_info_path = os.path.join(repo_root, "Windows", "App",
								 "Mad.Designer.Windows", "Infrastructure",
								 "AppInfo.cs")
	if os.path.exists(app_info_path):
		with open(app_info_path, encoding="utf-8", errors="replace") as handle:
			if re.search(r'const\s+string\s+Version\s*=\s*"v', handle.read()):
				problems.append(
					"Windows/App/.../AppInfo.cs: Version is a hardcoded literal; "
					"read the generated build info instead")

	tag_pattern = re.compile(r"releases/download/(v\d+\.\d+\.\d+)")
	windows_pattern = re.compile(
		r"MAD-Designer-Windows-(\d+\.\d+(?:\.\d+)?)\.zip")
	for path in _public_files(repo_root):
		with open(path, encoding="utf-8", errors="replace") as handle:
			text = handle.read()
		for found in set(tag_pattern.findall(text)):
			if found != manifest["published_tag"]:
				problems.append(
					"%s: download link advertises %s, expected %s"
					% (os.path.relpath(path, repo_root), found,
					   manifest["published_tag"]))
		for found in set(windows_pattern.findall(text)):
			if found not in (manifest["published_release"],
							 _short_release(manifest["published_release"])):
				problems.append(
					"%s: Window download advertises %s, expected %s"
					% (os.path.relpath(path, repo_root), found,
					   manifest["published_release"]))

	return problems


def main(argv=None):
	parser = argparse.ArgumentParser(description=__doc__)
	parser.add_argument("--repo", default=os.getcwd())
	subparsers = parser.add_subparsers(dest="command", required=True)
	subparsers.add_parser("check")
	subparsers.add_parser("docs")
	read_parser = subparsers.add_parser("read")
	read_parser.add_argument("key")
	args = parser.parse_args(argv)

	manifest = load_manifest(args.repo)
	if args.command == "read":
		if args.key not in manifest:
			raise SystemExit("unknown key: %s" % args.key)
		print(manifest[args.key])
		return 0

	if args.command == "docs":
		path = os.path.join(args.repo, "docs", "_data", "versions.yml")
		_replace_flat_values(path, docs_projection(manifest))
		print(path)
		return 0

	problems = check(args.repo)
	for problem in problems:
		print(problem)
	return 1 if problems else 0


if __name__ == "__main__":
	sys.exit(main())
