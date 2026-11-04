#!/usr/bin/env python3
# Copyright © 2026 Michael Thomason. SPDX-License-Identifier: MIT
"""Tests for the text-based localization audit.

Run with: python3 -I scripts/localization/audit_test.py
"""

import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
AUDIT = HERE / "audit.py"


class AuditTest(unittest.TestCase):
	def setUp(self):
		self._tmp = tempfile.TemporaryDirectory()
		self.root = Path(self._tmp.name)
		self.baseline = self.root / "baseline.json"

	def tearDown(self):
		self._tmp.cleanup()

	def write(self, relative, text):
		path = self.root / relative
		path.parent.mkdir(parents=True, exist_ok=True)
		path.write_text(text, encoding="utf-8")
		return path

	def run_cli(self, *args):
		return subprocess.run(
			[sys.executable, "-I", str(AUDIT), "--root", str(self.root),
			 "--baseline", str(self.baseline), *args],
			capture_output=True, text=True,
		)

	def results(self, *args):
		"""Run with --write-baseline --json and return the parsed report."""
		completed = self.run_cli("--write-baseline", "--json", *args)
		self.assertEqual(completed.returncode, 0, completed.stderr + completed.stdout)
		return json.loads(completed.stdout)

	@staticmethod
	def by_category(report, category):
		return [f for f in report["findings"] if f["category"] == category]

	def test_literal_and_nonliteral_keys(self):
		self.write("MAD/Source/Foo.m", """\
#import <Foundation/Foundation.h>
NSString *a = NSLocalizedString(@"Open Document", @"Opens it.");
NSString *b = NSLocalizedString(MADTextFoo, @"Context.");
NSString *c = NSLocalizedString(fooString, nil);
// NSString *d = NSLocalizedString(@"Commented Out", nil);
/* NSString *e = NSLocalizedString(@"Also Commented", nil); */
""")
		report = self.results()

		self.assertEqual(report["counts"]["calls"], 3)
		self.assertEqual(report["counts"]["literal_calls"], 1)
		self.assertEqual(report["counts"]["nonliteral_calls"], 2)
		self.assertEqual(report["counts"]["unique_literal_keys"], 1)

		texts = sorted(f["text"] for f in self.by_category(report, "nonliteral-key"))
		self.assertEqual(texts, ["MADTextFoo", "fooString"])

	def test_multiline_literal_and_escaped_quote(self):
		self.write("MAD/Source/Multi.m", """\
NSString *a = NSLocalizedString(@"A \\"quoted\\" key",
	@"Context on the next line.");
NSString *b = NSLocalizedString(@"First" @" second", nil);
""")
		report = self.results()

		self.assertEqual(report["counts"]["literal_calls"], 2)
		keys = sorted(f["text"] for f in self.by_category(report, "literal-key"))
		self.assertEqual(keys, ['A "quoted" key', "First second"])

	def test_raw_ui_literals(self):
		self.write("MADDesigner/Source/UI.m", r"""[UIAlertController alertControllerWithTitle:@"Error" message:@"Failed" preferredStyle:UIAlertControllerStyleAlert];
[button setTitle:@"Go" forState:UIControlStateNormal];
label.accessibilityLabel = @"Close";
label.accessibilityLabel = NSLocalizedString(@"Close", nil);
[textField setText:@""];
NSDictionary *d = @{NSLocalizedDescriptionKey: @"Oops"};
[alert setMessageText:@"Something\n\nwent wrong"];
[alert setMessageText:@"First line. "
	@"Second line."];
""")
		report = self.results()

		texts = sorted(f["text"] for f in self.by_category(report, "raw-ui-literal"))
		self.assertEqual(texts, [
			"NSLocalizedDescriptionKey = Oops",
			"accessibilityLabel = Close",
			"alertControllerWithTitle = Error",
			"message = Failed",
			"setMessageText = First line. Second line.",
			"setMessageText = Something\\n\\nwent wrong",
			"setTitle = Go",
		])

	def test_literals_inside_strings_and_comments_are_ignored(self):
		self.write("MADDesigner/Source/Noise.m", """\
NSString *doc = @"call setTitle:@\\"Not UI\\" to see it";
// [button setTitle:@"Commented" forState:0];
/* label.accessibilityLabel = @"Blocked"; */
""")
		report = self.results()
		self.assertEqual(self.by_category(report, "raw-ui-literal"), [])

	def test_format_strings_without_positional_specifiers(self):
		self.write("MAD/Source/Format.m", """\
NSLocalizedString(@"%@ of %@", nil);
NSLocalizedString(@"%1$@ of %2$@", nil);
NSLocalizedString(@"Page %1@ of %2@ pages.", nil);
NSLocalizedString(@"Only %@", nil);
""")
		report = self.results()

		texts = sorted(f["text"] for f in self.by_category(report, "format-no-positional"))
		self.assertEqual(texts, ["%@ of %@", "Page %1@ of %2@ pages."])

	def test_concat_near_ui_is_a_warning_not_a_failure(self):
		self.write("MADDesigner/Source/Concat.m", """\
void f(UIButton *button, NSString *a, NSString *b) {
	[button setTitle:a forState:0];
	NSString *title = [a stringByAppendingString:b];
}
""")
		report = self.results()
		warnings = self.by_category(report, "string-concat-near-ui")
		self.assertEqual(len(warnings), 1)
		self.assertNotIn(warnings[0], self._baseline_entries())

		# Warnings alone never fail the check.
		completed = self.run_cli()
		self.assertEqual(completed.returncode, 0, completed.stdout + completed.stderr)

	def test_concat_far_from_ui_is_not_reported(self):
		lines = ["void f(NSString *a, NSString *b) {"]
		lines += ["\tint x%d = %d;" % (i, i) for i in range(60)]
		lines += ["\tNSString *s = [a stringByAppendingString:b];", "}"]
		self.write("MAD/Source/Far.m", "\n".join(lines) + "\n")

		report = self.results()
		self.assertEqual(self.by_category(report, "string-concat-near-ui"), [])

	def test_baseline_suppresses_known_and_fails_on_new(self):
		self.write("MADDesigner/Source/UI.m",
			'[button setTitle:@"Go" forState:0];\n')
		first = self.run_cli("--write-baseline")
		self.assertEqual(first.returncode, 0, first.stderr + first.stdout)
		self.assertTrue(self.baseline.exists())

		second = self.run_cli()
		self.assertEqual(second.returncode, 0, second.stdout + second.stderr)

		self.write("MADDesigner/Source/More.m",
			'[button setTitle:@"New" forState:0];\n')
		third = self.run_cli()
		self.assertEqual(third.returncode, 1)
		self.assertIn("More.m", third.stdout)
		self.assertIn("New", third.stdout)

	def test_baseline_is_sorted_and_stable(self):
		self.write("MADDesigner/Source/UI.m", """\
[button setTitle:@"Zulu" forState:0];
[button setTitle:@"Alpha" forState:0];
""")
		self.assertEqual(self.run_cli("--write-baseline").returncode, 0)
		data = json.loads(self.baseline.read_text(encoding="utf-8"))
		self.assertEqual(data["version"], 1)
		texts = [entry["text"] for entry in data["entries"]]
		self.assertEqual(texts, sorted(texts))

	def test_excluded_trees_are_not_scanned(self):
		self.write("Compressor/build/vendor/Foo.m",
			'[button setTitle:@"Vendor" forState:0];\n')
		self.write("ThirdParty/Thing.m",
			'[button setTitle:@"Third Party" forState:0];\n')
		report = self.results()
		self.assertEqual(self.by_category(report, "raw-ui-literal"), [])

	def test_json_findings_carry_file_and_line(self):
		self.write("MAD/Source/Lines.m", """\
int a = 1;
int b = 2;
[button setTitle:@"Here" forState:0];
""")
		report = self.results()
		finding = self.by_category(report, "raw-ui-literal")[0]
		self.assertEqual(finding["file"], "MAD/Source/Lines.m")
		self.assertEqual(finding["line"], 3)

	def _baseline_entries(self):
		if not self.baseline.exists():
			return []
		data = json.loads(self.baseline.read_text(encoding="utf-8"))
		return [entry for entry in data["entries"] if entry["category"] == "string-concat-near-ui"]


if __name__ == "__main__":
	unittest.main()
