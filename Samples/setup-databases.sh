#!/bin/bash
# Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
#
#  setup-databases.sh -- stand up the sample databases and seed the
#  cross-database composition table.
#
#  The three SQLite samples need nothing but the checked-in chinook.sqlite3.
#  The cross-database composition sample joins one small table from each of the
#  three live test servers (MySQL, PostgreSQL, SQL Server).  This script:
#
#    1. creates/starts the three pinned containers through
#       TestDatabase/test-databases.sh (their datasets are loaded there), and
#    2. creates and seeds `composition_demo` in each server.
#
#  It is idempotent: rerunning it leaves the containers alone and replaces the
#  five demo rows in place.  The credentials are the public local test-database
#  defaults (docs/project/build/DEVELOPER.md); nothing here is a secret.
#
#  Usage:
#    Samples/setup-databases.sh [up|status|down|sql]
#
#    up      create/start the three servers and seed composition_demo (default)
#    status  show the containers and the seeded row count
#    down    stop the three containers (their volumes keep the data)
#    sql     print the seeding SQL and exit (no Docker needed)
#
#  Environment overrides (the same MAD_* names the live suites use):
#    MAD_MYSQL_TEST_{USER,PASSWORD,SCHEMA}
#    MAD_PG_TEST_{USER,PASSWORD,DATABASE}
#    MAD_TDS_TEST_{USER,PASSWORD,DATABASE}
#    MAD_TESTDB_CONTAINER_PREFIX   container names remain mad-mysql, mad-mssql,
#                                 and mad-postgres unless MAD_SAMPLE_* below
#    MAD_SAMPLE_MYSQL_CONTAINER    default mad-mysql
#    MAD_SAMPLE_PG_CONTAINER       default mad-postgres
#    MAD_SAMPLE_TDS_CONTAINER      default mad-mssql
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TESTDB="${REPO_ROOT}/TestDatabase/test-databases.sh"

MYSQL_CONTAINER="${MAD_SAMPLE_MYSQL_CONTAINER:-mad-mysql}"
PG_CONTAINER="${MAD_SAMPLE_PG_CONTAINER:-mad-postgres}"
TDS_CONTAINER="${MAD_SAMPLE_TDS_CONTAINER:-mad-mssql}"

MYSQL_USER="${MAD_MYSQL_TEST_USER:-root}"
MYSQL_PASSWORD="${MAD_MYSQL_TEST_PASSWORD:-root}"
MYSQL_DATABASE="${MAD_MYSQL_TEST_SCHEMA:-employees}"

PG_USER="${MAD_PG_TEST_USER:-mad}"
PG_PASSWORD="${MAD_PG_TEST_PASSWORD:-mad_test_pw}"
PG_DATABASE="${MAD_PG_TEST_DATABASE:-chinook}"

TDS_USER="${MAD_TDS_TEST_USER:-sa}"
TDS_PASSWORD="${MAD_TDS_TEST_PASSWORD:-Root1@Root2}"
TDS_DATABASE="${MAD_TDS_TEST_DATABASE:-AdventureWorksLT2022}"

die() {
	echo "error: $*" >&2
	exit 1
}

require_docker() {
	command -v docker >/dev/null 2>&1 || die "docker is not installed -- see https://docs.docker.com/desktop/"
	docker info >/dev/null 2>&1 || die "the Docker daemon is not running. Start Docker Desktop (Linux containers)."
}

usage() {
	awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "$0"
}

mysql_sql() {
	cat <<'SQL'
CREATE TABLE IF NOT EXISTS composition_demo (
	demo_id INT NOT NULL PRIMARY KEY,
	label   VARCHAR(64) NOT NULL,
	amount  DECIMAL(10,2) NOT NULL
);
DELETE FROM composition_demo;
INSERT INTO composition_demo (demo_id, label, amount) VALUES
	(1, 'MySQL / North',   101.50),
	(2, 'MySQL / South',   102.50),
	(3, 'MySQL / East',    103.50),
	(4, 'MySQL / West',    104.50),
	(5, 'MySQL / Central', 105.50);
SQL
}

pg_sql() {
	cat <<'SQL'
CREATE TABLE IF NOT EXISTS public.composition_demo (
	demo_id INT NOT NULL PRIMARY KEY,
	label   VARCHAR(64) NOT NULL,
	amount  NUMERIC(10,2) NOT NULL
);
DELETE FROM public.composition_demo;
INSERT INTO public.composition_demo (demo_id, label, amount) VALUES
	(1, 'Postgres / North',   201.00),
	(2, 'Postgres / South',   202.00),
	(3, 'Postgres / East',    203.00),
	(4, 'Postgres / West',    204.00),
	(5, 'Postgres / Central', 205.00);
SQL
}

tds_sql() {
	cat <<'SQL'
IF OBJECT_ID(N'dbo.composition_demo', N'U') IS NULL
BEGIN
	CREATE TABLE dbo.composition_demo (
		demo_id INT NOT NULL PRIMARY KEY,
		label   NVARCHAR(64) NOT NULL,
		amount  DECIMAL(10,2) NOT NULL
	);
END;
DELETE FROM dbo.composition_demo;
INSERT INTO dbo.composition_demo (demo_id, label, amount) VALUES
	(1, N'SQL Server / North',   301.75),
	(2, N'SQL Server / South',   302.75),
	(3, N'SQL Server / East',    303.75),
	(4, N'SQL Server / West',    304.75),
	(5, N'SQL Server / Central', 305.75);
SQL
}

seed_mysql() {
	echo "[samples] MySQL: ${MYSQL_DATABASE}.composition_demo"
	mysql_sql | docker exec -i -e MYSQL_PWD="${MYSQL_PASSWORD}" "${MYSQL_CONTAINER}" \
		mysql --user="${MYSQL_USER}" "${MYSQL_DATABASE}" >/dev/null
}

seed_pg() {
	echo "[samples] PostgreSQL: ${PG_DATABASE}.public.composition_demo"
	pg_sql | docker exec -i -e PGPASSWORD="${PG_PASSWORD}" "${PG_CONTAINER}" \
		psql -v ON_ERROR_STOP=1 --username="${PG_USER}" --dbname="${PG_DATABASE}" \
		     --quiet >/dev/null
}

tds_sqlcmd() {
	docker exec "${TDS_CONTAINER}" sh -c '
		for p in /opt/mssql-tools18/bin/sqlcmd /opt/mssql-tools/bin/sqlcmd; do
			if [ -x "$p" ]; then echo "$p"; exit 0; fi
		done
		exit 1'
}

seed_tds() {
	local sqlcmd
	sqlcmd="$(tds_sqlcmd)" || die "sqlcmd is not in ${TDS_CONTAINER}"
	echo "[samples] SQL Server: ${TDS_DATABASE}.dbo.composition_demo"
	docker exec "${TDS_CONTAINER}" "${sqlcmd}" \
		-S localhost -U "${TDS_USER}" -P "${TDS_PASSWORD}" -C -b \
		-d "${TDS_DATABASE}" -Q "$(tds_sql)" >/dev/null
}

tds_row_count() {
	local sqlcmd
	sqlcmd="$(tds_sqlcmd)" || { echo n/a; return; }
	docker exec "${TDS_CONTAINER}" "${sqlcmd}" \
		-S localhost -U "${TDS_USER}" -P "${TDS_PASSWORD}" -C -h -1 -W \
		-d "${TDS_DATABASE}" -Q "SET NOCOUNT ON; SELECT COUNT(*) FROM dbo.composition_demo"
}

seed_all() {
	require_docker
	bash "${TESTDB}" up >/dev/null
	seed_mysql
	seed_pg
	seed_tds
	echo "[samples] done: composition_demo is loaded in all three servers."
	echo "[samples] Open Samples/Reports/Composition-MySQL-PostgreSQL-SQLServer.mad in MAD Designer,"
	echo "[samples] press Refresh, and answer each source's password prompt."
}

show_status() {
	require_docker
	echo "[samples] containers:"
	for container in "${MYSQL_CONTAINER}" "${PG_CONTAINER}" "${TDS_CONTAINER}"; do
		printf '  %-14s %s\n' "${container}" "$(docker inspect -f '{{.State.Status}}' "${container}" 2>/dev/null || echo missing)"
	done
	printf '[samples] MySQL rows:      %s\n' \
		"$(docker exec -e MYSQL_PWD="${MYSQL_PASSWORD}" "${MYSQL_CONTAINER}" mysql --user="${MYSQL_USER}" -N -B "${MYSQL_DATABASE}" -e 'SELECT COUNT(*) FROM composition_demo' 2>/dev/null || echo n/a)"
	printf '[samples] PostgreSQL rows: %s\n' \
		"$(docker exec -e PGPASSWORD="${PG_PASSWORD}" "${PG_CONTAINER}" psql -A -t --username="${PG_USER}" --dbname="${PG_DATABASE}" -c 'SELECT COUNT(*) FROM public.composition_demo' 2>/dev/null || echo n/a)"
	printf '[samples] SQL Server rows: %s\n' "$(tds_row_count 2>/dev/null || echo n/a)"
}

print_sql() {
	echo "-- MySQL (${MYSQL_DATABASE})"
	mysql_sql
	echo
	echo "-- PostgreSQL (${PG_DATABASE})"
	pg_sql
	echo
	echo "-- SQL Server (${TDS_DATABASE})"
	tds_sql
}

action="${1:-up}"
case "${action}" in
	up) seed_all ;;
	status) show_status ;;
	down) bash "${TESTDB}" down ;;
	sql) print_sql ;;
	-h|--help|help) usage ;;
	*) die "unknown action '${action}' (try up, status, down, sql, or --help)" ;;
esac
