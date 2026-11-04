#!/usr/bin/env python3
# Copyright © 2026 Michael Thomason. SPDX-License-Identifier: MIT
"""Text-based localization audit for the MAD iOS and macOS applications.

This is deliberately pure Python: it needs no Xcode, so the Linux workflow can
run it.  It finds the four classes of problem described in
docs/project/MAD_APP_LOCALIZATION.md §5.3:

	nonliteral-key       NSLocalizedString receives something other than @"..."
	literal-key          NSLocalizedString receives a literal (good; reported)
	raw-ui-literal       @"..." passed to or assigned to a known UI API
	format-no-positional two or more format specifiers, none positional
	string-concat-near-ui  sentence assembled with appendString: near UI code

The check is heuristic on purpose.  Its value is the checked-in baseline: a
finding already in baseline.json is accepted; a new one fails the run.  Regenerate
the baseline deliberately, after reviewing what changed:

	python3 -I scripts/localization/audit.py --write-baseline

Ordinary check, as CI runs it:

	python3 -I scripts/localization/audit.py
"""

import argparse
import json
import os
import re
import sys
from pathlib import Path

BASELINE_VERSION = 1
SOURCE_SUFFIXES = frozenset({".m", ".h", ".mm"})
DEFAULT_ROOTS = (
	"Mac",
	"MAD",
	"MADAPI",
	"MADBarcodes",
	"MADCocoaExtensions",
	"MADDataStructures",
	"MADDesigner",
	"MADExplorer",
	"MADFileManager",
	"MADFoundation",
	"MADMySQL",
	"MADPostgres",
	"MADSqlite3",
	"MADTds",
	"MADTdsClient",
)
EXCLUDED_DIRS = frozenset({
	".git",
	"Archive",
	"Archived",
	"DerivedData",
	"ReceiptModuleAsn1c",
	"build",
})
# Test bundles are not shipped UI; their fixtures are not a translation surface.
EXCLUDED_DIR_SUFFIXES = ("Tests",)

CALL_RE = re.compile(r"\bNSLocalizedString\s*\(")
WINDOW_LINES = 30

# Selectors whose first string argument is user-facing UI copy.  The list
# covers UIKit/NSAlert and the AppKit constructors the Mac app actually uses.
UI_SELECTOR_RE = re.compile(
	r"(?P<keyword>"
	r"alertControllerWithTitle|actionWithTitle|setTitle|setText|setPlaceholder|"
	r"initWithTitle|setMessageText|setInformativeText|addButtonWithTitle|message|"
	r"addItemWithTitle|buttonWithTitle|labelWithString|checkboxWithTitle|"
	r"radioButtonWithTitle|setAccessibilityLabel|setAccessibilityHelp|"
	r"setPlaceholderString|setToolTip|setStringValue"
	r")\s*:\s*@(?P<literal>\"(?:[^\"\\]|\\.)*\")"
)
UI_PROPERTY_RE = re.compile(
	r"\.(?P<keyword>accessibilityLabel|accessibilityHint|accessibilityValue|"
	r"placeholder|placeholderString|stringValue|toolTip|text|title)"
	r"\s*=\s*@(?P<literal>\"(?:[^\"\\]|\\.)*\")"
)
# Array-of-titles selectors need every element, not just the first literal.
UI_ARRAY_SELECTOR_RE = re.compile(
	r"(?P<keyword>addItemsWithTitles|initWithTitles)\s*:\s*@\["
)
UI_ERROR_KEY_RE = re.compile(
	r"\b(?P<keyword>NSLocalizedDescriptionKey|NSLocalizedFailureReasonErrorKey|"
	r"NSLocalizedRecoverySuggestionErrorKey)\s*:\s*@(?P<literal>\"(?:[^\"\\]|\\.)*\")"
)
FORMAT_SPECIFIER_RE = re.compile(
	r"%(?P<positional>\d+\$)?[-+ 0#']*\d*(?:\.\d+)?(?:hh|h|ll|l|q|L|z|t|j)?"
	r"[@dDiuUxXoOfFeEgGcCsSpaA]"
)
CONCAT_RE = re.compile(r"\b(?:stringByAppendingString|appendString)\s*:")
UI_NEARBY_RE = re.compile(
	r"\bUI[A-Z]\w+|NSLocalizedString|accessibility|alertController|setTitle|"
	r"setMessageText|setInformativeText|actionWithTitle|initWithTitle"
)

OFFENDER_CATEGORIES = frozenset({"nonliteral-key", "raw-ui-literal", "format-no-positional"})
WARNING_CATEGORIES = frozenset({"string-concat-near-ui"})


class Finding(object):
	__slots__ = ("category", "file", "line", "text")

	def __init__(self, category, file, line, text):
		self.category = category
		self.file = file
		self.line = line
		self.text = text

	@property
	def warning(self):
		return self.category in WARNING_CATEGORIES

	def as_dict(self):
		return {
			"category": self.category,
			"file": self.file,
			"line": self.line,
			"text": self.text,
			"warning": self.warning,
		}

	def key(self):
		return (self.category, self.file, self.text)


def decode_literal(body):
	"""Decode the body of an Objective-C string literal (without the quotes)."""
	simple = {"n": "\n", "t": "\t", "r": "\r", "0": "\0", "\\": "\\", '"': '"', "'": "'"}
	out = []
	i = 0
	while i < len(body):
		char = body[i]
		if char != "\\" or i + 1 >= len(body):
			out.append(char)
			i += 1
			continue
		escape = body[i + 1]
		if escape == "u" and i + 5 < len(body):
			try:
				out.append(chr(int(body[i + 2:i + 6], 16)))
				i += 6
				continue
			except ValueError:
				pass
		out.append(simple.get(escape, escape))
		i += 2
	return "".join(out)


def _scan_quoted(text, start, quote):
	"""Return the index just past the closing quote."""
	i = start + 1
	while i < len(text):
		char = text[i]
		if char == "\\":
			i += 2
			continue
		if char == quote:
			return i + 1
		i += 1
	return len(text)


def mask_source(text):
	"""Return (no_comments, code_only), both the same length as *text*.

	no_comments replaces comment characters with spaces; code_only also blanks
	string and character literal contents, so identifiers found in strings are
	not mistaken for code.  Newlines are preserved in both.
	"""
	no_comments = list(text)
	code_only = list(text)
	length = len(text)

	def blank(start, end, target):
		for position in range(start, end):
			if target[position] != "\n":
				target[position] = " "

	i = 0
	while i < length:
		char = text[i]
		next_char = text[i + 1] if i + 1 < length else ""
		if char == "/" and next_char == "/":
			end = text.find("\n", i)
			end = length if end < 0 else end
			blank(i, end, no_comments)
			blank(i, end, code_only)
			i = end
		elif char == "/" and next_char == "*":
			end = text.find("*/", i + 2)
			end = length if end < 0 else end + 2
			blank(i, end, no_comments)
			blank(i, end, code_only)
			i = end
		elif char == "@" and next_char == '"':
			end = _scan_quoted(text, i + 1, '"')
			blank(i + 1, end, code_only)
			i = end
		elif char == '"':
			end = _scan_quoted(text, i, '"')
			blank(i, end, code_only)
			i = end
		elif char == "'":
			end = _scan_quoted(text, i, "'")
			blank(i, end, code_only)
			i = end
		else:
			i += 1
	return "".join(no_comments), "".join(code_only)


def _split_arguments(text, open_index):
	"""Split a call's arguments at top-level commas; return (close, args)."""
	args = []
	depth = 0
	start = open_index + 1
	i = start
	length = len(text)
	while i < length:
		char = text[i]
		if char == '"' or char == "'":
			i = _scan_quoted(text, i, char)
			continue
		if char in "([{":
			depth += 1
		elif char in ")]}":
			if depth == 0 and char == ")":
				args.append(text[start:i])
				return i, args
			depth -= 1
		elif char == "," and depth == 0:
			args.append(text[start:i])
			start = i + 1
		i += 1
	return length, args


_LITERAL_PREFIX_RE = re.compile(r'@("(?:[^"\\]|\\.)*")')


def literal_value(segment):
	"""Return the decoded value when *segment* is one or more adjacent @"..." literals."""
	text = segment.strip()
	if not text:
		return None
	values = []
	position = 0
	while position < len(text):
		match = _LITERAL_PREFIX_RE.match(text, position)
		if not match:
			return None
		values.append(decode_literal(match.group(1)[1:-1]))
		position = match.end()
		while position < len(text) and text[position].isspace():
			position += 1
	return "".join(values)


def format_specifiers(value):
	"""Return [(start, positional)], ignoring %%."""
	specifiers = []
	i = 0
	while i < len(value):
		if value[i] != "%":
			i += 1
			continue
		if i + 1 < len(value) and value[i + 1] == "%":
			i += 2
			continue
		match = FORMAT_SPECIFIER_RE.match(value, i)
		if match:
			specifiers.append((i, match.group("positional") is not None))
			i = match.end()
		else:
			i += 1
	return specifiers


def normalize_expression(value):
	return " ".join(value.split())[:200]


def _line_of(text, index):
	return text.count("\n", 0, index) + 1


def _raw_body(literal_with_quotes):
	return literal_with_quotes[1:-1]


def adjacent_literal_body(text, quote_index):
	"""Join @"a" @"b" runs; *quote_index* points at the first opening quote."""
	position = quote_index
	bodies = []
	while position < len(text) and text[position] == '"':
		end = _scan_quoted(text, position, '"')
		bodies.append(text[position + 1:end - 1])
		position = end
		while position < len(text) and text[position].isspace():
			position += 1
		if not (text[position:position + 2] == '@"'):
			break
		position += 1
	return position, "".join(bodies)


def array_literal_end(text, bracket_index):
	"""Return the index of the ']' that closes the '[' at *bracket_index*."""
	depth = 0
	i = bracket_index
	while i < len(text):
		char = text[i]
		if char == '"':
			i = _scan_quoted(text, i, '"')
			continue
		if char == "[":
			depth += 1
		elif char == "]":
			depth -= 1
			if depth == 0:
				return i
		i += 1
	return -1


def has_letters(value):
	"""True when a string has Latin letters; glyphs, numbers and symbols do not."""
	return re.search(r"[A-Za-z]", value) is not None


def audit_text(relative_path, text):
	"""Return (findings, stats) for one source file."""
	findings = []
	stats = {
		"calls": 0,
		"literal_calls": 0,
		"nonliteral_calls": 0,
		"format_keys": 0,
		"format_multiargument_keys": 0,
		"literal_keys": set(),
		"format_key_set": set(),
		"format_multiargument_set": set(),
	}
	no_comments, code_only = mask_source(text)

	for call in CALL_RE.finditer(code_only):
		open_index = call.end() - 1
		_close_index, args = _split_arguments(no_comments, open_index)
		line = _line_of(no_comments, call.start())
		stats["calls"] += 1
		first = args[0] if args else ""
		value = literal_value(first)
		if value is None:
			stats["nonliteral_calls"] += 1
			expression = normalize_expression(first)
			findings.append(Finding("nonliteral-key", relative_path, line, expression))
			continue
		stats["literal_calls"] += 1
		stats["literal_keys"].add(value)
		findings.append(Finding("literal-key", relative_path, line, value))
		specifiers = format_specifiers(value)
		if specifiers:
			stats["format_key_set"].add(value)
		if len(specifiers) >= 2:
			stats["format_multiargument_set"].add(value)
			if not any(positional for _start, positional in specifiers):
				findings.append(Finding("format-no-positional", relative_path, line, value))

	def scan_ui(pattern):
		for match in pattern.finditer(no_comments):
			if code_only[match.start("keyword")] == " ":
				continue
			_end, body = adjacent_literal_body(no_comments, match.start("literal"))
			if not body.strip() or not has_letters(body):
				continue
			text_value = "%s = %s" % (match.group("keyword"), body)
			findings.append(Finding(
				"raw-ui-literal", relative_path,
				_line_of(no_comments, match.start()), text_value,
			))

	def scan_arrays():
		for match in UI_ARRAY_SELECTOR_RE.finditer(no_comments):
			if code_only[match.start("keyword")] == " ":
				continue
			bracket = match.end() - 1
			end = array_literal_end(no_comments, bracket)
			if end < 0:
				continue
			body = no_comments[bracket + 1:end]
			for literal in _LITERAL_PREFIX_RE.finditer(body):
				raw = _raw_body(literal.group(1))
				if not has_letters(raw):
					continue
				position = bracket + 1 + literal.start()
				text_value = "%s = %s" % (match.group("keyword"), raw)
				findings.append(Finding(
					"raw-ui-literal", relative_path,
					_line_of(no_comments, position), text_value,
				))

	scan_ui(UI_SELECTOR_RE)
	scan_ui(UI_PROPERTY_RE)
	scan_ui(UI_ERROR_KEY_RE)
	scan_arrays()

	lines = no_comments.split("\n")
	for match in CONCAT_RE.finditer(code_only):
		line = _line_of(no_comments, match.start())
		first = max(0, line - 1 - WINDOW_LINES)
		last = min(len(lines), line + WINDOW_LINES)
		window = "\n".join(lines[first:last])
		if not UI_NEARBY_RE.search(window):
			continue
		source_line = lines[line - 1].strip() if line - 1 < len(lines) else ""
		findings.append(Finding("string-concat-near-ui", relative_path, line, source_line))

	stats["format_keys"] = len(stats["format_key_set"])
	stats["format_multiargument_keys"] = len(stats["format_multiargument_set"])
	return findings, stats


def iter_source_files(root):
	for root_name in DEFAULT_ROOTS:
		base = root / root_name
		if not base.is_dir():
			continue
		for dirpath, dirnames, filenames in os.walk(base):
			dirnames[:] = sorted(
				name for name in dirnames
				if name not in EXCLUDED_DIRS
				and not name.endswith(EXCLUDED_DIR_SUFFIXES)
			)
			for name in sorted(filenames):
				if Path(name).suffix in SOURCE_SUFFIXES:
					yield Path(dirpath) / name


def audit_repository(root):
	findings = []
	totals = {
		"calls": 0,
		"literal_calls": 0,
		"nonliteral_calls": 0,
		"literal_keys": set(),
		"format_key_set": set(),
		"format_multiargument_set": set(),
		"files": 0,
	}
	for path in iter_source_files(root):
		try:
			text = path.read_text(encoding="utf-8")
		except UnicodeDecodeError:
			text = path.read_text(encoding="latin-1")
		relative = path.relative_to(root).as_posix()
		file_findings, stats = audit_text(relative, text)
		findings.extend(file_findings)
		totals["files"] += 1
		for name in ("calls", "literal_calls", "nonliteral_calls"):
			totals[name] += stats[name]
		totals["literal_keys"].update(stats["literal_keys"])
		totals["format_key_set"].update(stats["format_key_set"])
		totals["format_multiargument_set"].update(stats["format_multiargument_set"])

	findings.sort(key=lambda item: (item.category, item.file, item.line, item.text))
	counts = {
		"files": totals["files"],
		"calls": totals["calls"],
		"literal_calls": totals["literal_calls"],
		"nonliteral_calls": totals["nonliteral_calls"],
		"unique_literal_keys": len(totals["literal_keys"]),
		"format_keys": len(totals["format_key_set"]),
		"format_multiargument_keys": len(totals["format_multiargument_set"]),
		"raw_ui_literals": sum(1 for f in findings if f.category == "raw-ui-literal"),
		"format_no_positional": sum(1 for f in findings if f.category == "format-no-positional"),
		"nonliteral_keys": sum(1 for f in findings if f.category == "nonliteral-key"),
		"string_concat_near_ui": sum(1 for f in findings if f.category == "string-concat-near-ui"),
	}
	return findings, counts


def load_baseline(path):
	data = json.loads(path.read_text(encoding="utf-8"))
	if data.get("version") != BASELINE_VERSION:
		raise ValueError("unsupported baseline version: %r" % (data.get("version"),))
	entries = data.get("entries", [])
	return {
		(entry["category"], entry["file"], entry["text"]): entry.get("count", 1)
		for entry in entries
	}


def baseline_entries(findings):
	counts = {}
	for finding in findings:
		if finding.category not in OFFENDER_CATEGORIES:
			continue
		counts[finding.key()] = counts.get(finding.key(), 0) + 1
	entries = []
	for key in sorted(counts):
		category, file, text = key
		entries.append({
			"category": category,
			"file": file,
			"text": text,
			"count": counts[key],
			"reason": "",
		})
	return entries


def write_baseline(path, findings):
	payload = {
		"version": BASELINE_VERSION,
		"description": (
			"Known and accepted localization-audit findings. Review before "
			"regenerating: python3 -I scripts/localization/audit.py --write-baseline"
		),
		"entries": baseline_entries(findings),
	}
	path.parent.mkdir(parents=True, exist_ok=True)
	path.write_text(json.dumps(payload, indent="\t", ensure_ascii=False) + "\n", encoding="utf-8")


def print_report(findings, counts, baseline, new, excess, stale, fail_on_warnings=False):
	print("Localization audit")
	print("  files scanned:              %d" % counts["files"])
	print("  NSLocalizedString calls:    %d (literal %d, non-literal %d)" % (
		counts["calls"], counts["literal_calls"], counts["nonliteral_calls"]))
	print("  unique literal keys:        %d" % counts["unique_literal_keys"])
	print("  format-bearing keys:        %d (multi-argument %d)" % (
		counts["format_keys"], counts["format_multiargument_keys"]))
	print("  raw UI literals:            %d" % counts["raw_ui_literals"])
	print("  format without positional:  %d" % counts["format_no_positional"])
	print("  non-literal keys:           %d" % counts["nonliteral_keys"])
	print("  concat near UI (warning):   %d" % counts["string_concat_near_ui"])

	if baseline is not None:
		print("  baseline entries matched:   %d" % (len(baseline) - len(stale)))
		print("  baseline entries stale:     %d" % len(stale))

	if new or excess:
		print("")
		if new:
			print("NEW localization findings (%d):" % len(new))
			for finding in new:
				print("  %s:%d: %s: %s" % (finding.file, finding.line, finding.category, finding.text))
		if excess:
			print("OCCURRENCES OVER BASELINE (%d):" % len(excess))
			for key, now, before in excess:
				category, file, text = key
				print("  %s: %s: %s (now %d, baseline %d)" % (
					file, category, text, now, before))
		return 1
	if fail_on_warnings and counts["string_concat_near_ui"]:
		print("")
		print("Warnings treated as errors.")
		return 1
	print("")
	print("OK: no new localization findings.")
	return 0


def main(argv=None):
	parser = argparse.ArgumentParser(description="Audit MAD localization strings.")
	parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[2],
		help="repository root (default: two levels above this script)")
	parser.add_argument("--baseline", type=Path, default=None,
		help="baseline JSON (default: <script dir>/baseline.json)")
	parser.add_argument("--write-baseline", action="store_true",
		help="record the current findings as accepted")
	parser.add_argument("--report", action="store_true",
		help="print every finding, not only new ones")
	parser.add_argument("--json", action="store_true", help="machine-readable output")
	parser.add_argument("--fail-on-warnings", action="store_true",
		help="treat the warning category as a failure")
	args = parser.parse_args(argv)

	root = args.root.resolve()
	baseline_path = (args.baseline or (Path(__file__).resolve().parent / "baseline.json")).resolve()
	findings, counts = audit_repository(root)

	if args.write_baseline:
		write_baseline(baseline_path, findings)
		new, excess, stale = [], [], []
		baseline = load_baseline(baseline_path) if baseline_path.exists() else {}
	else:
		if not baseline_path.exists():
			print("ERROR: baseline not found: %s" % baseline_path, file=sys.stderr)
			print("Run with --write-baseline after reviewing the findings.", file=sys.stderr)
			return 2
		baseline = load_baseline(baseline_path)
		current = {}
		for finding in findings:
			if finding.category not in OFFENDER_CATEGORIES:
				continue
			current[finding.key()] = current.get(finding.key(), 0) + 1
		new_keys = {key for key in current if key not in baseline}
		new = [
			finding for finding in findings
			if finding.category in OFFENDER_CATEGORIES and finding.key() in new_keys
		]
		excess = [
			(key, current[key], baseline[key])
			for key in sorted(current)
			if key in baseline and current[key] > baseline[key]
		]
		stale = sorted(set(baseline) - set(current))

	if args.json:
		payload = {
			"counts": counts,
			"findings": [finding.as_dict() for finding in findings],
			"new": [finding.as_dict() for finding in new],
			"excess": [
				{
					"category": key[0],
					"file": key[1],
					"text": key[2],
					"count": now,
					"baseline": before,
				}
				for key, now, before in excess
			],
			"stale": [list(item) for item in stale],
			"baseline": str(baseline_path),
		}
		print(json.dumps(payload, indent="\t", ensure_ascii=False))
		if args.write_baseline:
			return 0
		if new or excess:
			return 1
		if args.fail_on_warnings and counts["string_concat_near_ui"]:
			return 1
		return 0

	if args.report:
		for finding in findings:
			print("%s:%d: %s: %s" % (finding.file, finding.line, finding.category, finding.text))
		print("")

	return print_report(findings, counts, baseline, new, excess, stale, args.fail_on_warnings)


if __name__ == "__main__":
	sys.exit(main())
