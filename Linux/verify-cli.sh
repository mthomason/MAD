#!/bin/bash
# Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
#
#  verify-cli.sh -- the `mad` runtime image's end-to-end check.
#
#  Runs INSIDE the runtime image, with the repository mounted read-only at
#  /repo (Linux/build.sh --verify does that).  It exercises the verbs the way a
#  caller does -- inspect, schema, query, refresh, export in every format this
#  build offers, and write -- and asserts the pinned digests (docs/project/MAD_CLI.md §3,
#  Linux/README.md).  It also checks that the image really is the runtime layer:
#  no compiler, no build tree, and the sample database in place.
#
#  --live additionally refreshes the MySQL and TDS fixtures, which needs the
#  two containers documented in CLI/Fixtures/README.md and docs/project/DEVELOPER.md.
#
#  Exit code: 0 when every check passes, 1 otherwise.
#

set -u

FIXTURES=/repo/CLI/Fixtures
LONDON="${FIXTURES}/London.portable.mad"
MYSQL_DOC="${FIXTURES}/MySQL.employees.mad"
TDS_DOC="${FIXTURES}/TDS.AdventureWorksLT2022.mad"
SAMPLE_DB="${HOME}/GNUstep/Library/ApplicationSupport/chinook.sqlite3"
WORK="$(mktemp -d)"

PASSED=0
FAILED=0

pass() { PASSED=$((PASSED + 1)); printf 'PASS %s\n' "$1"; }
fail() { FAILED=$((FAILED + 1)); printf 'FAIL %s\n' "$1"; }

check() { # <description> <command...>
	local description="$1"
	shift
	if "$@"; then pass "${description}"; else fail "${description}"; fi
}

check_present() { # <description> <program>
	if command -v "$2" >/dev/null 2>&1; then pass "$1"; else fail "$1"; fi
}

check_absent() { # <description> <program>
	if command -v "$2" >/dev/null 2>&1; then fail "$1"; else pass "$1"; fi
}

digest() { # <file> -> sha256
	sha256sum "$1" | cut -d' ' -f1
}

size() { # <file> -> bytes
	stat -c %s "$1"
}

check_file() { # <name> <path> <bytes> <sha256>
	local name="$1" path="$2" bytes="$3" sha="$4"
	if [[ ! -f "${path}" ]]; then fail "${name} (not written)"; return; fi
	if [[ "$(size "${path}")" != "${bytes}" ]]; then
		fail "${name} (size $(size "${path}"), expected ${bytes})"; return
	fi
	if [[ "$(digest "${path}")" != "${sha}" ]]; then
		fail "${name} (sha256 $(digest "${path}"), expected ${sha})"; return
	fi
	pass "${name} (${bytes} bytes, ${sha:0:8}...)"
}

output() { # <command...> -> stdout+stderr
	"$@" 2>&1
}

export_format() { # <format> <file>
	local status
	mad export "${LONDON}" --format "$1" --out "$2" --deterministic --quiet >/dev/null 2>&1
	status=$?
	if [[ "${status}" -ne 0 ]]; then fail "export $1 (exit ${status})"; return 1; fi
	return 0
}

[[ -f "${LONDON}" ]] || { echo "FAIL fixture missing: ${LONDON}" >&2; exit 1; }

# --- The image's own shape -------------------------------------------------

check_present "mad is on PATH"	mad
check_absent  "no clang in the image"	clang
check_absent  "no cmake in the image"	cmake
check_absent  "no git in the image"	git
check "no build tree in the image"	[ ! -d /src ]
check "sample database installed"	[ -f "${SAMPLE_DB}" ]

# --- help, inspect, schema, query -----------------------------------------

output mad help > "${WORK}/help.txt"
check "mad help"		grep -q 'mad -- MAD Designer command line' "${WORK}/help.txt"
check "help names every format"	grep -q \
	'export: csv, html, html-flow, json, json-report, pdf, text' "${WORK}/help.txt"

# --- the source-database overrides -----------------------------------------
# The document stores the connection (host, port, database name); the flags
# override it for a run, which is what lets one checked-in document run against
# a CI service container.  A Sqlite3 document has no server connection, so it
# refuses them rather than silently ignoring the request.

check "help names --host"		grep -q -- '--host <name>' "${WORK}/help.txt"
check "help names --port"		grep -q -- '--port <n>' "${WORK}/help.txt"
check "help names --database"	grep -q -- '--database <name>' "${WORK}/help.txt"

output mad refresh "${LONDON}" --port nope > "${WORK}/port-nope.txt"
check "--port rejects a non-number"		[ "$?" -eq 1 ]
check "--port says what it wants"		grep -q 'port number between 1 and 65535' "${WORK}/port-nope.txt"

output mad refresh "${LONDON}" --port 70000 > "${WORK}/port-range.txt"
check "--port rejects an out-of-range number"	[ "$?" -eq 1 ]
check "--port range says what it wants"		grep -q 'port number between 1 and 65535' "${WORK}/port-range.txt"

output mad refresh "${LONDON}" --host db.example > "${WORK}/host-sqlite.txt"
check "a Sqlite3 document refuses --host"		[ "$?" -eq 1 ]
check "the --host refusal says why"			grep -q 'only apply to a server database' "${WORK}/host-sqlite.txt"

output mad refresh "${LONDON}" --database other > "${WORK}/database-sqlite.txt"
check "a Sqlite3 document refuses --database"	[ "$?" -eq 1 ]
check "the --database refusal says why"		grep -q 'only apply to a server database' "${WORK}/database-sqlite.txt"

output mad inspect "${LONDON}" > "${WORK}/inspect.txt"
check "inspect: v1 container"		grep -q 'format      v1' "${WORK}/inspect.txt"
check "inspect: four members"		grep -q 'members     4' "${WORK}/inspect.txt"
check "inspect: portable store"		grep -q 'StoreContent/store.sqlite (SQLite' "${WORK}/inspect.txt"
check "inspect: 41 sections, 25 elements" grep -q '41 sections, 25 elements' "${WORK}/inspect.txt"

output mad schema "${LONDON}" > "${WORK}/schema.txt"
check "schema: Sqlite 3 driver"	grep -q 'schema 1   Sqlite 3' "${WORK}/schema.txt"
check "schema: eleven tables"	grep -q 'tables     11' "${WORK}/schema.txt"

output mad query "${LONDON}" > "${WORK}/query.txt"
check "query: SELECT"		grep -q '^SELECT' "${WORK}/query.txt"
check "query: FROM"		grep -q 'FROM' "${WORK}/query.txt"

output mad refresh "${LONDON}" --no-keychain > "${WORK}/refresh.txt"
check "refresh: 76 rows"	grep -q 'refreshed 76 rows' "${WORK}/refresh.txt"

# --- export: every format this build offers -------------------------------

export_format text		"${WORK}/out.text"
export_format csv		"${WORK}/out.csv"
export_format json		"${WORK}/out.json"
export_format html		"${WORK}/out.html"
export_format html-flow		"${WORK}/out.flow.html"
export_format json-report	"${WORK}/out.report.json"

check_file "export text"	"${WORK}/out.text"		40441	7dcee96c45951fac0e0057094a6a142c90a88d6d88a1c03278b273f5140c6e49
check_file "export csv"		"${WORK}/out.csv"		12538	773f6215a5447f72d499282d337a5916b11f0f3b06cb4c5aec134db6f493cb21
check_file "export json"	"${WORK}/out.json"		64595	569c6ee25223c51ecffd15923dd897e75c8362d72f4ece72f8dbeee3e9c8cdbc
check_file "export html"	"${WORK}/out.html"		62007	285541ed59333e0e55b8c7fe5619e4b64dde7aaf8e93a24ba881b40111ab2327
check_file "export html-flow"	"${WORK}/out.flow.html"		54766	0565204a55d02f925602b5c0bf298bb0e41c9cbe56bea6df770e828a35782382
check_file "export json-report"	"${WORK}/out.report.json"	118109	9d01d0daabbb5e38921c0bfbed083b288031c9340e9a4af81679d03b691ce94c

output mad export "${LONDON}" --format pdf --out "${WORK}/out.pdf" > "${WORK}/pdf.txt"
PDF_STATUS=$?
check "pdf refuses with exit 5"		[ "${PDF_STATUS}" -eq 5 ]
check "pdf names its reason"		grep -q 'not available in this build' "${WORK}/pdf.txt"

# --- write ----------------------------------------------------------------

output mad write "${LONDON}" --out "${WORK}/copy.mad" --reproducible --quiet >/dev/null
check_file "write --reproducible" "${WORK}/copy.mad" 16261	09815b24e91e03b6e526008f7c2700074fed10679771b9e1ee4609e54a1192f5

# --- exit codes (docs/project/MAD_CLI.md §3) -------------------------------------------

mad inspect /nonexistent.mad >/dev/null 2>&1
check "bad document exits 2"		[ "$?" -eq 2 ]
mad >/dev/null 2>&1
check "no command exits 1"		[ "$?" -eq 1 ]
mad export "${LONDON}" --format nope >/dev/null 2>&1
check "unknown format exits 1"		[ "$?" -eq 1 ]
mad write "${LONDON}" >/dev/null 2>&1
check "write without --out exits 1"	[ "$?" -eq 1 ]

# --- optionally, the live databases ---------------------------------------

if [[ "${1:-}" == "--live" ]]; then
	output mad refresh "${MYSQL_DOC}" --credentials root:root --rows 50 --no-keychain > "${WORK}/mysql.txt"
	check "refresh MySQL: 50 rows"	grep -q 'refreshed 50 rows' "${WORK}/mysql.txt"
	output mad refresh "${TDS_DOC}" --credentials 'sa:Root1@Root2' --rows 20 --no-keychain > "${WORK}/tds.txt"
	check "refresh TDS: 20 rows"	grep -q 'refreshed 20 rows' "${WORK}/tds.txt"

	# The overrides reach the driver: the fixture's stored server is reachable,
	# so a deliberately wrong override must fail in the refresh, not in the
	# parser (which would say "Unknown option" and exit 1).
	output mad refresh "${MYSQL_DOC}" --database definitely_not_a_database \
		--credentials root:root --rows 5 --no-keychain > "${WORK}/mysql-database.txt"
	check "MySQL --database override reaches the connection"	grep -q 'refresh failed' "${WORK}/mysql-database.txt"
	output mad refresh "${MYSQL_DOC}" --host 127.0.0.1 \
		--credentials root:root --rows 5 --no-keychain > "${WORK}/mysql-host.txt"
	check "MySQL --host override reaches the connection"	grep -q 'refresh failed' "${WORK}/mysql-host.txt"
fi

# --- summary --------------------------------------------------------------

rm -rf "${WORK}"
printf '\nMADVERIFY %d passed, %d failed\n' "${PASSED}" "${FAILED}"
[[ "${FAILED}" -eq 0 ]]
