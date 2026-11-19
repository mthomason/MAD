#!/bin/bash
# Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
#
#  test-databases.sh -- one entry point for the three pinned test servers.
#
#  A thin cross-platform orchestrator over the three canonical scripts:
#
#      MADMySQL/TestDatabase/mysql-test-db.sh        (mad-mysql,    13306)
#      MADTdsClient/TestDatabase/sqlserver-test-db.sh (mad-mssql,    1433)
#      MADPostgres/TestDatabase/postgres-test-db.sh  (mad-postgres, 5432)
#
#  It does not duplicate db.conf or container logic; every verb is delegated to
#  the matching script.  Runs on macOS (system bash 3.2), Linux and Git Bash on
#  Windows.
#
#  Usage:
#    test-databases.sh <up|download|wait|verify|status|logs|down|reset|env> [all|mysql|tds|postgres]
#
#  `all` (the default) runs mysql, tds and postgres in that order and stops on
#  the first hard failure.  For `logs` you will usually pass a service, since it
#  tails with --follow.  `env` prints the complete live-suite environment in
#  both POSIX and PowerShell forms and ignores the service selector.

set -euo pipefail

TESTDB_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

MYSQL_SCRIPT="${TESTDB_ROOT}/../MADMySQL/TestDatabase/mysql-test-db.sh"
TDS_SCRIPT="${TESTDB_ROOT}/../MADTdsClient/TestDatabase/sqlserver-test-db.sh"
POSTGRES_SCRIPT="${TESTDB_ROOT}/../MADPostgres/TestDatabase/postgres-test-db.sh"

die() {
	echo "error: $*" >&2
	exit 1
}

script_for() {
	case "$1" in
		mysql) echo "${MYSQL_SCRIPT}" ;;
		tds|mssql|sqlserver) echo "${TDS_SCRIPT}" ;;
		postgres|pg) echo "${POSTGRES_SCRIPT}" ;;
		*) die "unknown service '$1' (try mysql, tds or postgres)" ;;
	esac
}

usage() {
	awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "$0"
}

cmd_env() {
	cat <<'EOF'
MAD live-suite environment -- POSIX (bash/zsh; paste or source):

export MAD_MYSQL_TEST_HOST=127.0.0.1
export MAD_MYSQL_TEST_PORT=13306
export MAD_MYSQL_TEST_USER=root
export MAD_MYSQL_TEST_PASSWORD=root
export MAD_MYSQL_TEST_SCHEMA=employees
export MAD_TDS_TEST_HOST=127.0.0.1
export MAD_TDS_TEST_USER=sa
export MAD_TDS_TEST_PASSWORD='Root1@Root2'
export MAD_TDS_TEST_DATABASE=AdventureWorksLT2022
export MAD_PG_TEST_HOST=127.0.0.1
export MAD_PG_TEST_PORT=5432
export MAD_PG_TEST_USER=mad
export MAD_PG_TEST_PASSWORD=mad_test_pw
export MAD_PG_TEST_DATABASE=chinook

MAD live-suite environment -- PowerShell (apply in the same session, then run build.ps1):

$env:MAD_MYSQL_TEST_HOST = "127.0.0.1"
$env:MAD_MYSQL_TEST_PORT = "13306"
$env:MAD_MYSQL_TEST_USER = "root"
$env:MAD_MYSQL_TEST_PASSWORD = "root"
$env:MAD_MYSQL_TEST_SCHEMA = "employees"
$env:MAD_TDS_TEST_HOST = "127.0.0.1"
$env:MAD_TDS_TEST_USER = "sa"
$env:MAD_TDS_TEST_PASSWORD = "Root1@Root2"
$env:MAD_TDS_TEST_DATABASE = "AdventureWorksLT2022"
$env:MAD_PG_TEST_HOST = "127.0.0.1"
$env:MAD_PG_TEST_PORT = "5432"
$env:MAD_PG_TEST_USER = "mad"
$env:MAD_PG_TEST_PASSWORD = "mad_test_pw"
$env:MAD_PG_TEST_DATABASE = "chinook"
EOF
}

verb="${1:-}"
service="${2:-all}"

case "${verb}" in
	up|download|wait|verify|status|logs|down|reset)
		if [ "${service}" = "all" ]; then
			services="mysql tds postgres"
		else
			services="${service}"
		fi
		for svc in ${services}; do
			script="$(script_for "${svc}")"
			echo "[test-databases] ${verb} ${svc}"
			"${script}" "${verb}"
		done
		;;
	env)
		cmd_env
		;;
	-h|--help|help)
		usage
		;;
	"")
		usage
		exit 1
		;;
	*)
		die "unknown command '${verb}' (try --help)"
		;;
esac
