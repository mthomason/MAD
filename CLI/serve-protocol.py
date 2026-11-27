#!/usr/bin/env python3
#  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
#
#  serve-protocol.py -- drive `mad serve`'s newline-delimited JSON protocol end to
#  end, asserting the query-scoped contract in
#  docs/project/design/MAD_COMPOSITION_NODE_VIEW.md §3.3-3.4b and §0.
#
#  It spawns `mad serve`, converts the London fixture to a composition (one composing
#  root over one leaf), then walks the scoped methods: describe, layout-model and the
#  nine mutations, query-model, node-result, and export with `query`, before and after
#  a refresh, plus the error answers (unknown query, SQL editing on a composed node,
#  and a non-root json-report).
#
#  Runs on Linux (where `mad` is on PATH, inside the runtime image) and on macOS
#  (where the simulator binary is spawned through `xcrun simctl spawn booted`).
#
#  Exit 0 when every check passes, 1 otherwise.
#

import json
import os
import shutil
import subprocess
import sys
import tempfile
import threading


def repo_root():
    return os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def resolve_mad():
    """Returns (argv, env) that spawn `mad serve` on this platform."""
    binary = os.environ.get("MAD_BIN")
    if binary:
        return [binary, "serve"], dict(os.environ)

    if shutil.which("mad"):
        return ["mad", "serve"], dict(os.environ)

    # macOS: the simulator binary, spawned the same way CLI/build.sh --run does.
    simulator = os.path.join(repo_root(), "CLI", "build", "mad")
    if os.path.exists(simulator) and shutil.which("xcrun"):
        env = dict(os.environ)
        env["SIMCTL_CHILD_MAD_HOST_CWD"] = repo_root()
        return ["xcrun", "simctl", "spawn", "booted", simulator, "serve"], env

    sys.stderr.write("FAIL could not locate `mad` (set MAD_BIN, or put `mad` on PATH)\n")
    sys.exit(1)


def resolve_fixture():
    fixtures = os.environ.get("MAD_FIXTURES")
    if fixtures:
        return os.path.join(fixtures, "London.portable.mad")
    return os.path.join(repo_root(), "CLI", "Fixtures", "London.portable.mad")


class ServeClient:
    def __init__(self, argv, env):
        self.proc = subprocess.Popen(
            argv,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            env=env,
            text=True,
            bufsize=1,
        )
        self.next_id = 0
        # Drain stderr on a thread.  `mad serve` logs there (GNUstep on Linux can
        # write a lot), and an unread 64 KB pipe would fill, blocking the child on
        # write(2) while this side waits on stdout -- a deadlock, not a slow test.
        self.stderr_lines = []
        self.stderr_reader = threading.Thread(target=self._drain_stderr, daemon=True)
        self.stderr_reader.start()

    def _drain_stderr(self):
        try:
            for line in self.proc.stderr:
                self.stderr_lines.append(line)
                if len(self.stderr_lines) > 500:
                    del self.stderr_lines[:250]
        except Exception:
            pass

    def _stderr_text(self):
        self.stderr_reader.join(timeout=2)
        return "".join(self.stderr_lines)

    def request(self, method, params=None):
        self.next_id += 1
        payload = {"id": self.next_id, "method": method, "params": params or {}}
        self.proc.stdin.write(json.dumps(payload) + "\n")
        self.proc.stdin.flush()
        line = self.proc.stdout.readline()
        if not line:
            raise RuntimeError("mad serve exited early: " + self._stderr_text().strip())
        return json.loads(line)

    def close(self):
        try:
            self.request("shutdown")
        except Exception:
            pass
        try:
            self.proc.stdin.close()
        except Exception:
            pass
        try:
            self.proc.wait(timeout=30)
        finally:
            self.stderr_reader.join(timeout=2)


def main():
    argv, env = resolve_mad()
    fixture = resolve_fixture()

    passed = 0
    failed = 0

    def check(condition, name):
        nonlocal passed, failed
        if condition:
            passed += 1
            print("PASS " + name)
        else:
            failed += 1
            print("FAIL " + name)

    def ok(response):
        return response.get("ok") is True

    def result(response):
        return response.get("result", {})

    def error_message(response):
        error = response.get("error", {})
        return error.get("message", "")

    client = ServeClient(argv, env)
    workdir = None
    try:
        # --- engine-info advertises the node-scoped members -------------------------
        info = client.request("engine-info")
        capabilities = result(info).get("capabilities", [])
        check(ok(info), "engine-info answers")
        check("node-result" in capabilities, "engine-info advertises node-result")

        # --- open the fixture -------------------------------------------------------
        opened = client.request("open", {"path": fixture})
        check(ok(opened), "open London fixture")
        handle = result(opened).get("handle")
        check(isinstance(handle, int), "open returns a numeric handle")

        # --- convert to a composition: one composing root over one leaf -------------
        before = client.request("document-info", {"handle": handle})
        check(ok(before) and result(before).get("composed") == False, "document-info: not composed before convert")
        check(len(result(before).get("queries", [])) == 1, "document-info: one query before convert")

        # --- an ordinary (non-composed) report keeps its document layout ------------
        # The document's own five structural sections are its layout.  A no-`query`
        # call must not materialize per-query sections or treat the single query as a
        # node: the report root is the document's default query when it has no root.
        workdir = tempfile.mkdtemp(prefix="mad-serve-")
        standard_path = os.path.join(workdir, "standard.mad")
        shutil.copy(fixture, standard_path)
        standard_open = client.request("open", {"path": standard_path})
        check(ok(standard_open), "standard report: open a writable copy")
        standard_handle = result(standard_open).get("handle")

        standard_layout = client.request("layout-model", {"handle": standard_handle})
        check(ok(standard_layout), "standard report: layout-model answers")
        standard_sections = result(standard_layout).get("sections", [])
        standard_elements = result(standard_layout).get("elements", [])
        check(len(standard_sections) >= 5 and len(standard_elements) > 0,
              "standard report: layout-model returns the document's sections and elements")

        again = result(client.request("layout-model", {"handle": standard_handle}))
        check([s["id"] for s in standard_sections] == [s["id"] for s in again.get("sections", [])],
              "standard report: layout-model is stable (no new sections per call)")

        standard_detail = None
        original_detail_height = 0
        for section in standard_sections:
            if section.get("title") == "Report Detail":
                standard_detail = section.get("id")
                original_detail_height = section.get("height", 0)
        check(standard_detail is not None, "standard report: has a document detail section")

        element_count = len(standard_elements)
        standard_add = client.request("add-element", {"handle": standard_handle,
                                                       "section": standard_detail,
                                                       "kind": "data-field"})
        check(ok(standard_add) and len(result(standard_add).get("elements", [])) == element_count + 1,
              "standard report: add-element edits the document detail")

        standard_set = client.request("set-section", {"handle": standard_handle,
                                                       "section": standard_detail,
                                                       "height": 120})
        detail_height = None
        for section in result(standard_set).get("sections", []):
            if section.get("id") == standard_detail:
                detail_height = section.get("height")
        check(ok(standard_set) and abs((detail_height or 0) - 120) < 0.5,
              "standard report: set-section edits the document detail")

        standard_refresh = client.request("refresh", {"handle": standard_handle})
        check(ok(standard_refresh), "standard report: refresh")
        standard_rows = result(standard_refresh).get("rowCount", 0)

        standard_node = client.request("node-result", {"handle": standard_handle})
        check(ok(standard_node) and result(standard_node).get("rowCount") == standard_rows,
              "standard report: node-result (no query) reads the root result")

        for standard_format in ("json", "csv", "text", "html"):
            exported = client.request("export", {"handle": standard_handle, "format": standard_format})
            check(ok(exported) and len(result(exported).get("data", "")) > 0,
                  "standard report: export %s (no query) answers" % standard_format)
        standard_report = client.request("export", {"handle": standard_handle, "format": "json-report"})
        check(ok(standard_report), "standard report: json-report (no query) answers")

        # Save and reopen: the document's own section ids survive (no spurious
        # per-query sections).  The Apple CLI's `write` re-opens the source because
        # its session document is a UIDocument, so only Linux's headless session
        # carries the in-memory edit into the saved copy.
        saved_path = os.path.join(workdir, "standard-saved.mad")
        wrote = client.request("write", {"handle": standard_handle, "out": saved_path})
        check(ok(wrote), "standard report: write")
        reopened = client.request("open", {"path": saved_path})
        check(ok(reopened), "standard report: reopen the saved copy")
        reopened_layout = result(client.request("layout-model", {"handle": result(reopened).get("handle")}))
        check([s["id"] for s in reopened_layout.get("sections", [])] == [s["id"] for s in standard_sections],
              "standard report: save/reopen keeps the document's own section ids")
        expected_elements = element_count + 1 if sys.platform.startswith("linux") else element_count
        check(len(reopened_layout.get("elements", [])) == expected_elements,
              "standard report: save/reopen keeps the document layout")
        reopened_detail = next((s for s in reopened_layout.get("sections", []) if s.get("id") == standard_detail), {})
        expected_height = 120 if sys.platform.startswith("linux") else original_detail_height
        check(abs((reopened_detail.get("height") or 0) - expected_height) < 0.5,
              "standard report: save/reopen keeps the document detail height")

        converted = client.request("convert", {"handle": handle, "childName": "invoices"})
        check(ok(converted), "convert to a composition")
        root_id = result(converted).get("rootQuery", 0)
        queries = result(converted).get("queries", [])
        check(result(converted).get("composed") == True, "document-info: composed after convert")
        check(root_id > 0, "document-info: names the root query")
        check(len(queries) == 2, "document-info: root + one leaf after convert")

        leaf_id = 0
        for q in queries:
            if not q.get("isRoot"):
                leaf_id = q.get("id", 0)
        check(leaf_id > 0 and leaf_id != root_id, "document-info: names the leaf query")

        # --- describe before any refresh -------------------------------------------
        described = client.request("describe", {"handle": handle})
        check(ok(described), "describe (root default) answers before refresh")
        check(len(result(described).get("columns", [])) > 0, "describe: root columns present")
        check(len(result(described).get("tables", [])) > 0, "describe: root tables are the document's schema")

        leaf_described = client.request("describe", {"handle": handle, "query": leaf_id})
        check(ok(leaf_described), "describe?query=leaf answers before refresh")
        check(len(result(leaf_described).get("columns", [])) > 0, "describe: leaf columns present")
        check(len(result(leaf_described).get("tables", [])) > 0, "describe: leaf tables are its own schema")

        root_described = client.request("describe", {"handle": handle, "query": root_id})
        check(ok(root_described), "describe?query=root answers before refresh")
        check(result(root_described).get("tables") == [], "describe: a composing node reports no schema tables")

        # --- layout-model with and without a query ----------------------------------
        root_layout = client.request("layout-model", {"handle": handle})
        check(ok(root_layout), "layout-model (root default) answers")
        root_sections = result(root_layout).get("sections", [])
        check(len(root_sections) >= 5, "layout-model: the root has its structural sections")

        leaf_layout = client.request("layout-model", {"handle": handle, "query": leaf_id})
        check(ok(leaf_layout), "layout-model?query=leaf answers")
        leaf_sections = result(leaf_layout).get("sections", [])
        check(len(leaf_sections) == 5, "layout-model: the leaf materializes five sections")
        check(len(result(leaf_layout).get("fields", [])) > 0, "layout-model: the leaf lists its fields")

        root_scoped_layout = client.request("layout-model", {"handle": handle, "query": root_id})
        check(ok(root_scoped_layout), "layout-model?query=root answers")
        check([s["id"] for s in result(root_scoped_layout).get("sections", [])] == [s["id"] for s in root_sections],
              "layout-model: the root default and ?query=root agree")

        # --- query-model: isComposing + isRoot --------------------------------------
        root_model = client.request("query-model", {"handle": handle})
        check(ok(root_model), "query-model (root default) answers")
        check(result(root_model).get("isRoot") == True, "query-model: root isRoot")
        check(result(root_model).get("isComposing") == True, "query-model: root isComposing")

        leaf_model = client.request("query-model", {"handle": handle, "query": leaf_id})
        check(ok(leaf_model), "query-model?query=leaf answers")
        check(result(leaf_model).get("isRoot") == False, "query-model: leaf is not root")
        check(result(leaf_model).get("isComposing") == False, "query-model: leaf is not composing")

        # --- SQL editing is rejected for a composed node ----------------------------
        validate = client.request("validate-sql", {"handle": handle, "query": root_id, "sql": "SELECT 1"})
        check(not ok(validate), "validate-sql rejects the composed root")
        check("composed node" in error_message(validate), "validate-sql names the composed node")

        apply = client.request("apply-sql", {"handle": handle, "query": root_id, "sql": "SELECT 1"})
        check(not ok(apply), "apply-sql rejects the composed root")
        check("composed node" in error_message(apply), "apply-sql names the composed node")

        # --- a scoped layout mutation ----------------------------------------------
        detail_id = None
        for section in leaf_sections:
            if section.get("title") == "Report Detail":
                detail_id = section.get("id")
        check(detail_id is not None, "the leaf has a detail section id")

        added = client.request("add-element", {"handle": handle, "query": leaf_id, "section": detail_id, "kind": "data-field"})
        check(ok(added), "add-element scoped to the leaf answers")
        check(len(result(added).get("elements", [])) == 1, "add-element: the leaf's layout gains one element")

        # --- refresh materializes every node's result ------------------------------
        refreshed = client.request("refresh", {"handle": handle})
        check(ok(refreshed), "refresh the converted composition")
        row_count = result(refreshed).get("rowCount", 0)
        check(row_count == 76, "refresh: the root has 76 rows")

        # --- node-result reads a node's rows ---------------------------------------
        node_root = client.request("node-result", {"handle": handle})
        check(ok(node_root), "node-result (root default) answers")
        check(result(node_root).get("rowCount") == 76, "node-result: the root's 76 rows")

        node_leaf = client.request("node-result", {"handle": handle, "query": leaf_id})
        check(ok(node_leaf), "node-result?query=leaf answers")
        check(result(node_leaf).get("query") == leaf_id, "node-result: names the leaf")
        check(result(node_leaf).get("rowCount") == 76, "node-result: the leaf's 76 rows")
        check(len(result(node_leaf).get("columns", [])) > 0, "node-result: the leaf has columns")

        # --- export?query for the node-scoped formats ------------------------------
        leaf_json = client.request("export", {"handle": handle, "query": leaf_id, "format": "json"})
        check(ok(leaf_json), "export?query=leaf&format=json answers")
        check(len(result(leaf_json).get("data", "")) > 0, "export?query=leaf&format=json returns bytes")

        leaf_html = client.request("export", {"handle": handle, "query": leaf_id, "format": "html"})
        check(ok(leaf_html), "export?query=leaf&format=html answers")
        check(len(result(leaf_html).get("data", "")) > 0, "export?query=leaf&format=html returns bytes")

        # json-report is not node-scoped yet.
        leaf_report = client.request("export", {"handle": handle, "query": leaf_id, "format": "json-report"})
        check(not ok(leaf_report), "export?query=leaf&format=json-report is refused")

        # --- a node with no materialized layout exports without throwing ------------
        # A fresh conversion: convert and refresh, then export the leaf BEFORE any
        # scoped layout-model call has created its five sections.  The render must
        # return an empty result or a clear error, never an engine exception.
        layoutless_path = os.path.join(workdir, "layoutless.mad")
        shutil.copy(fixture, layoutless_path)
        layoutless_open = client.request("open", {"path": layoutless_path})
        check(ok(layoutless_open), "layoutless node: open a fresh copy")
        layoutless_handle = result(layoutless_open).get("handle")
        layoutless_convert = client.request("convert", {"handle": layoutless_handle, "childName": "invoices"})
        layoutless_leaf = 0
        for q in result(layoutless_convert).get("queries", []):
            if not q.get("isRoot"):
                layoutless_leaf = q.get("id", 0)
        check(ok(layoutless_convert) and layoutless_leaf > 0, "layoutless node: convert")
        check(ok(client.request("refresh", {"handle": layoutless_handle})), "layoutless node: refresh")

        layoutless_export = client.request("export", {"handle": layoutless_handle,
                                                       "query": layoutless_leaf,
                                                       "format": "html"})
        check("engine error" not in error_message(layoutless_export),
              "layoutless node: html export does not raise an engine exception")
        check(ok(layoutless_export) or "not been refreshed" in error_message(layoutless_export),
              "layoutless node: html export returns a result or a clear error")

        # --- unknown query ---------------------------------------------------------
        unknown = client.request("layout-model", {"handle": handle, "query": 987654321})
        check(not ok(unknown), "layout-model?query=unknown is refused")
        check("no query 987654321" in error_message(unknown), "the unknown query error names the id")

        # --- shutdown --------------------------------------------------------------
        client.request("shutdown")
    finally:
        client.close()
        if workdir is not None:
            shutil.rmtree(workdir, ignore_errors=True)

    print("")
    print("MADSERVE %d passed, %d failed" % (passed, failed))
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
