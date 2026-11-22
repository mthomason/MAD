#!/bin/bash
# Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
#
#  mysql-test-db.sh -- the pinned MySQL test server, in Docker.
#
#  The live tests in MADMySQLTests/MADMySQLLiveTests.m talk to a real server as
#  root/root and SKIP when there is not one.  This script supplies that server
#  without touching whatever MySQL is installed on the Mac: one container
#  (`mad-mysql`), created from a digest-pinned image, whose named volume holds a
#  checksum-verified copy of the standard `employees` sample database.
#
#  The container publishes 13306.  On macOS/Linux it publishes on every
#  interface (the iOS scheme points the tests at it with MAD_MYSQL_TEST_PORT=13306,
#  and the Linux image and the CLI fixtures connect to the Mac's `mac:13306`); on
#  Windows it binds loopback by default so the test server is not exposed on the
#  LAN.  One port, one server, one container -- do not start a second MySQL
#  container.  (3306 is left alone because the Oracle MySQL installer's launchd
#  service may own it; see docs/project/build/DEVELOPER.md.)
#
#  Usage:
#    mysql-test-db.sh up        create/start the server, load the data if needed (default)
#    mysql-test-db.sh download  fetch + checksum-verify the dataset into the cache (no Docker)
#    mysql-test-db.sh wait      block until the server answers
#    mysql-test-db.sh verify    check every table against the upstream checksums
#    mysql-test-db.sh status    container, port, and what dataset is loaded
#    mysql-test-db.sh logs      tail the server log
#    mysql-test-db.sh down      stop the container (the volume keeps the data)
#    mysql-test-db.sh reset     remove the container and its volume
#
#  `up` is idempotent: it creates the container when it is missing, starts it
#  when it is stopped, and leaves it alone when the pinned image, the port and
#  the loaded dataset match.  The MADMySQL scheme calls it from the test
#  action's pre-action (and `down` from the post-action), so the server runs
#  only while the tests do.
#
#  Environment overrides:
#    MAD_TESTDB_PORT     host port to publish (default 13306, what the tests use)
#    MAD_TESTDB_NAME     container name      (default mad-mysql)
#    MAD_TESTDB_VOLUME   volume name         (default mad-mysql-test-data)
#    MAD_TESTDB_CACHE    download cache      (default is per-platform, see below)
#    MAD_TESTDB_BIND     host IP to bind the published port to (default "" on
#                        macOS/Linux = all interfaces; "127.0.0.1" on Windows)
#
#  The download cache defaults to $HOME/Library/Caches/MADTestDatabase on macOS,
#  ${XDG_CACHE_HOME:-$HOME/.cache}/MADTestDatabase on Linux and
#  ${LOCALAPPDATA}/MADTestDatabase on Windows.
#
#  The first `up` pulls the image (~600 MB) and imports the dataset (a few
#  minutes, ~168 MB of SQL).  Later runs take seconds.  Bump the pins in
#  db.conf to move to a new server or a new dataset revision; the loader
#  notices and re-imports.
#
#  Runs on the system bash (3.2 on macOS): no associative arrays, no mapfile.

set -euo pipefail

TESTDB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=db.conf
. "${TESTDB_DIR}/db.conf"

CONTAINER="${MAD_TESTDB_NAME:-mad-mysql}"
VOLUME="${MAD_TESTDB_VOLUME:-mad-mysql-test-data}"
PORT="${MAD_TESTDB_PORT:-13306}"

# ---------------------------------------------------------------- platform ---
# One script, three platforms: macOS (system bash 3.2), Linux, and Git Bash on
# Windows.  The cache lives in a per-platform location; the sha256 helper and
# the host-port check degrade gracefully; and Docker host paths are converted
# with cygpath on Windows, where MSYS_NO_PATHCONV also stops MSYS from rewriting
# container-side paths such as /dataset.
detect_platform() {
	case "$(uname -s)" in
		Darwin) echo "mac" ;;
		MINGW*|MSYS*|CYGWIN*) echo "windows" ;;
		*) echo "linux" ;;
	esac
}
PLATFORM="$(detect_platform)"

if [ "${PLATFORM}" = "windows" ]; then
	if [ -n "${LOCALAPPDATA:-}" ]; then
		CACHE_DEFAULT="$(cygpath -u "${LOCALAPPDATA}")/MADTestDatabase"
	else
		CACHE_DEFAULT="$HOME/AppData/Local/MADTestDatabase"
	fi
elif [ "${PLATFORM}" = "mac" ]; then
	CACHE_DEFAULT="$HOME/Library/Caches/MADTestDatabase"
else
	CACHE_DEFAULT="${XDG_CACHE_HOME:-$HOME/.cache}/MADTestDatabase"
fi
CACHE="${MAD_TESTDB_CACHE:-${CACHE_DEFAULT}}"

# macOS/Linux publish on every interface so the Linux image and the CLI fixtures
# reach the Mac's containers by name; Windows binds loopback so the test servers
# are not exposed on the LAN.  MAD_TESTDB_BIND overrides ("" = all interfaces).
if [ -n "${MAD_TESTDB_BIND:-}" ]; then
	BIND="${MAD_TESTDB_BIND}"
elif [ "${PLATFORM}" = "windows" ]; then
	BIND="127.0.0.1"
else
	BIND=""
fi

# Capture the real docker binary before the function below shadows the name, and
# wrap it so Docker invocations on Windows never get their arguments rewritten
# by MSYS path conversion (which would mangle /dataset and container:/path).
DOCKER_BIN="$(command -v docker 2>/dev/null || true)"
docker() {
	if [ "${PLATFORM}" = "windows" ]; then
		MSYS_NO_PATHCONV=1 "${DOCKER_BIN}" "$@"
	else
		"${DOCKER_BIN}" "$@"
	fi
}

DATASET_TARBALL="${CACHE}/test_db.tar.gz"
DATASET_DIR="${CACHE}/${DATASET_DIRNAME}"
MARKER_SCHEMA="mad_test_database"
ROOT_PASSWORD="root"
MYSQL_IMAGE="${MYSQL_IMAGE_TAG}@${MYSQL_IMAGE_DIGEST}"

die() {
	echo "error: $*" >&2
	exit 1
}

log() {
	echo "[mysql-test-db] $*"
}

usage() {
	awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "$0"
}

# A portable sha256: shasum first, then sha256sum, then PowerShell/certutil on
# Windows.  Never assume shasum exists on Windows.
sha256_of() { # <file> -> lowercase hex digest
	if command -v shasum >/dev/null 2>&1; then
		shasum -a 256 "$1" | awk '{print $1}'
	elif command -v sha256sum >/dev/null 2>&1; then
		sha256sum "$1" | awk '{print $1}'
	elif [ "${PLATFORM}" = "windows" ]; then
		local win
		win="$(cygpath -w "$1" 2>/dev/null || echo "$1")"
		if command -v powershell.exe >/dev/null 2>&1; then
			powershell.exe -NoProfile -NonInteractive -Command \
				"(Get-FileHash -Algorithm SHA256 -LiteralPath '${win}').Hash.ToLowerInvariant()" \
				| tr -d '\r\n'
		else
			certutil -hashfile "${win}" SHA256 2>/dev/null \
				| awk 'tolower($0) ~ /^[0-9a-f]{64}$/ { print; exit }'
		fi
	else
		die "no sha256 tool found (shasum or sha256sum)"
	fi
}

checksum_matches() { # <file> <sha256>
	local actual
	actual="$(sha256_of "$1")"
	[ "${actual}" = "$2" ]
}

# The path Docker must see for a host path.  On Windows the Docker daemon is a
# Windows process and needs a Windows path; Git Bash's own /c/... spelling is
# meaningless to it.
docker_host_path() { # <host-path>
	if [ "${PLATFORM}" = "windows" ]; then
		cygpath -w "$1" 2>/dev/null || echo "$1"
	else
		echo "$1"
	fi
}

# The --publish argument for this container's port, honouring the bind address.
publish_arg() { # <container-port>
	local container_port="$1"
	if [ -n "${BIND}" ]; then
		echo "${BIND}:${PORT}:${container_port}"
	else
		echo "${PORT}:${container_port}"
	fi
}

# Echo the SQL passed on stdin (or with --execute) into the container as root,
# over the Unix socket -- root@localhost, which always exists.
mysql_root() {
	docker exec -i "${CONTAINER}" \
		mysql --user=root --password="${ROOT_PASSWORD}" --silent --skip-column-names "$@" 2>/dev/null
}

require_docker() {
	[ -n "${DOCKER_BIN}" ] || die "docker is not installed -- see https://docs.docker.com/desktop/"
	docker info >/dev/null 2>&1 || die "the docker daemon is not running"
}

# ---------------------------------------------------------------- dataset ---

fetch_dataset() {
	if [ -d "${DATASET_DIR}" ]; then
		return 0
	fi

	mkdir -p "${CACHE}"

	if [ -f "${DATASET_TARBALL}" ] && ! checksum_matches "${DATASET_TARBALL}" "${DATASET_SHA256}"; then
		log "cached archive does not match db.conf; downloading again"
		rm -f "${DATASET_TARBALL}"
	fi

	if [ ! -f "${DATASET_TARBALL}" ]; then
		log "downloading ${DATASET_URL}"
		curl -fSL --retry 3 --retry-delay 2 -o "${DATASET_TARBALL}.part" "${DATASET_URL}" \
			|| die "could not download the dataset"
		mv "${DATASET_TARBALL}.part" "${DATASET_TARBALL}"
	fi

	checksum_matches "${DATASET_TARBALL}" "${DATASET_SHA256}" \
		|| die "dataset archive checksum mismatch: ${DATASET_TARBALL}"

	log "extracting the dataset into ${CACHE}"
	tar xzf "${DATASET_TARBALL}" -C "${CACHE}" || die "could not extract the dataset"
	[ -d "${DATASET_DIR}" ] || die "unexpected archive layout: ${DATASET_DIRNAME} is missing"
}

# -------------------------------------------------------------- container ---

container_state() {
	docker inspect --format '{{.State.Status}}' "${CONTAINER}" 2>/dev/null || echo "missing"
}

container_image() {
	docker inspect --format '{{.Config.Image}}' "${CONTAINER}" 2>/dev/null || echo ""
}

# The normalised host bind address of the binding that publishes <port>, from
# the container's config (a stopped container publishes nothing, and `up` after
# `down` must restart rather than recreate).  Empty HostIp and "0.0.0.0" are
# both "all interfaces" and are normalised to "" so an existing Mac container is
# not recreated merely because Docker renders the value differently.  Returns
# "_none_" when the container does not publish <port> at all.
container_bind() { # <port>
	local port="$1" line ip host_port
	while IFS= read -r line; do
		ip="${line%% *}"
		host_port="${line##* }"
		[ "${host_port}" = "${port}" ] || continue
		case "${ip}" in
			""|"0.0.0.0"|"::") echo "" ;;
			*) echo "${ip}" ;;
		esac
		return 0
	done < <(docker inspect --format '{{range .HostConfig.PortBindings}}{{range .}}{{.HostIp}} {{.HostPort}}{{println}}{{end}}{{end}}' "${CONTAINER}" 2>/dev/null || true)
	echo "_none_"
}

remove_container() {
	docker rm -f "${CONTAINER}" >/dev/null 2>&1 || true
}

# A plain TCP connect, not lsof: a server running as another user (a stock
# MySQL install runs as _mysql) is not visible to lsof here but certainly
# holds the port.  Prefers nc; on Windows without nc it falls back to
# PowerShell's Test-NetConnection; if neither can answer it reports "could not
# pre-check" and lets Docker report a real conflict.
port_in_use() { # <port> -> 0 when something is listening
	local port="$1" result
	if command -v nc >/dev/null 2>&1; then
		nc -z 127.0.0.1 "${port}" >/dev/null 2>&1
		return
	fi
	if command -v powershell.exe >/dev/null 2>&1; then
		result="$(powershell.exe -NoProfile -NonInteractive -Command \
			"(Test-NetConnection -ComputerName 127.0.0.1 -Port ${port} -WarningAction SilentlyContinue).TcpTestSucceeded" \
			2>/dev/null | tr -d '\r\n ')"
		if [ "${result}" = "True" ]; then return 0; fi
		if [ "${result}" = "False" ]; then return 1; fi
	fi
	log "could not pre-check port ${port} (no nc or Test-NetConnection); Docker will report a real conflict"
	return 1
}

port_conflict_message() { # <port>
	local port="$1" local_mysqld=""
	if command -v pgrep >/dev/null 2>&1; then
		if pgrep -x mysqld >/dev/null 2>&1 || pgrep -x mysqld_safe >/dev/null 2>&1; then
			local_mysqld="
	       This Mac is running its own mysqld (the Oracle installer's launchd
	       service is the usual holder), and the tests use this container, not it."
		fi
	fi
	die "port ${port} is already in use on 127.0.0.1.${local_mysqld}
	       Publish the container on another port with MAD_TESTDB_PORT=<port> and
	       change the MADMySQL scheme's MAD_MYSQL_TEST_PORT to match."
}

container_matches() {
	[ "$(container_image)" = "${MYSQL_IMAGE}" ] \
		&& [ "$(container_bind "${PORT}")" = "${BIND}" ]
}

create_container() {
	local state
	state="$(container_state)"

	if [ "${state}" = "running" ] && container_matches; then
		log "${CONTAINER} is already running"
		return 0
	fi

	# A port held by a *foreign* process is a hard conflict; a port held by our
	# own (mismatched) container is not -- it is recreated below on the same
	# volume.  Only pre-check the port when the container is not the one holding
	# it, so a running all-interface container (Windows now wants loopback) is
	# not mistaken for a conflict.
	if [ "${state}" != "running" ] || [ "$(container_bind "${PORT}")" = "_none_" ]; then
		if port_in_use "${PORT}"; then
			port_conflict_message "${PORT}"
		fi
	fi

	if [ "${state}" != "missing" ] && ! container_matches; then
		log "the container does not match db.conf; recreating it (the volume keeps the data)"
		remove_container
		state="missing"
	fi

	if [ "${state}" = "exited" ] || [ "${state}" = "created" ]; then
		log "starting ${CONTAINER}"
		docker start "${CONTAINER}" >/dev/null
		return 0
	fi

	log "creating ${CONTAINER} from ${MYSQL_IMAGE_TAG} on $(publish_arg 3306)"
	docker volume create "${VOLUME}" >/dev/null
	if ! docker run -d \
		--name "${CONTAINER}" \
		--env MYSQL_ROOT_PASSWORD="${ROOT_PASSWORD}" \
		--env MYSQL_ROOT_HOST='%' \
		--publish "$(publish_arg 3306)" \
		--volume "${VOLUME}:/var/lib/mysql" \
		--volume "$(docker_host_path "${DATASET_DIR}"):/dataset:ro" \
		"${MYSQL_IMAGE}" >/dev/null; then
		# A failed -d leaves a container behind in the created state.
		remove_container
		die "could not start the container (see the docker error above)"
	fi
}

wait_for_server() {
	local attempts=0
	# The published port is what the tests use, so wait on TCP rather than the
	# socket: during first-run initialisation the entrypoint's temporary server
	# answers on the socket only, and a socket ping there would be a false start.
	while ! docker exec "${CONTAINER}" \
			mysqladmin --host=127.0.0.1 --user=root --password="${ROOT_PASSWORD}" ping >/dev/null 2>&1; do
		attempts=$((attempts + 1))
		if [ "${attempts}" -ge 90 ]; then
			docker logs --tail 30 "${CONTAINER}" >&2 2>/dev/null || true
			die "the server did not become ready within 90s"
		fi
		sleep 1
	done
}

# ---------------------------------------------------------------- loading ---

loaded_commit() {
	mysql_root --execute "SELECT commit_sha FROM ${MARKER_SCHEMA}.dataset ORDER BY loaded_at DESC LIMIT 1;" || true
}

employee_count() {
	mysql_root --execute "SELECT COUNT(*) FROM employees.employees;" || true
}

load_dataset() {
	log "loading the employees dataset -- a few minutes, once per volume"
	docker exec -i "${CONTAINER}" \
		sh -c 'cd /dataset && mysql --user=root --password=root < employees.sql' >/dev/null \
		|| die "the dataset load failed"

	mysql_root --execute "
		CREATE DATABASE IF NOT EXISTS ${MARKER_SCHEMA};
		CREATE TABLE IF NOT EXISTS ${MARKER_SCHEMA}.dataset (
			commit_sha      VARCHAR(40) NOT NULL,
			archive_sha256  VARCHAR(64) NOT NULL,
			loaded_at       DATETIME    NOT NULL
		);
		DELETE FROM ${MARKER_SCHEMA}.dataset;
		INSERT INTO ${MARKER_SCHEMA}.dataset VALUES ('${DATASET_COMMIT}', '${DATASET_SHA256}', NOW());" \
		|| die "could not record the loaded dataset"
}

verify_dataset() {
	local output
	output="$(docker exec -i "${CONTAINER}" \
		sh -c "cd /dataset && mysql --user=root --password=root --table < ${DATASET_CHECKSUM_SQL}" 2>&1)" \
		|| die "the checksum script failed to run"

	if echo "${output}" | grep -q "FAIL"; then
		echo "${output}" >&2
		die "the dataset does not match the upstream checksums"
	fi

	local count
	count="$(employee_count)"
	[ "${count}" = "${DATASET_EMPLOYEE_COUNT}" ] \
		|| die "expected ${DATASET_EMPLOYEE_COUNT} employees, found '${count}'"

	log "dataset verified: every table matches the upstream row counts and checksums"
}

# --------------------------------------------------------------- commands ---

cmd_up() {
	require_docker
	fetch_dataset
	create_container
	wait_for_server

	local loaded
	loaded="$(loaded_commit)"

	if [ "${loaded}" = "${DATASET_COMMIT}" ]; then
		log "ready on :${PORT} (dataset ${DATASET_COMMIT:0:8}, already loaded)"
		return 0
	fi

	load_dataset
	verify_dataset
	log "ready on :${PORT} (dataset ${DATASET_COMMIT:0:8})"
}

cmd_download() {
	if [ -d "${DATASET_DIR}" ]; then
		log "dataset already cached and verified in ${CACHE}"
		return 0
	fi
	fetch_dataset
	log "downloaded and verified the dataset into ${CACHE}"
}

cmd_wait() {
	require_docker
	wait_for_server
	log "the server answers on :${PORT}"
}

cmd_verify() {
	require_docker
	wait_for_server
	verify_dataset
}

cmd_status() {
	require_docker
	local state
	state="$(container_state)"
	if [ "${state}" = "missing" ]; then
		log "no container named ${CONTAINER}; run 'up' to create it"
		return 0
	fi
	log "container: ${CONTAINER} (${state})"
	log "image:     $(container_image)"
	if [ "${state}" = "running" ]; then
		log "port:      ${PORT} -> 3306 (bind: ${BIND:-all interfaces})"
		log "loaded:    $(loaded_commit)"
		log "employees: $(employee_count)"
	else
		log "port:      not published while stopped"
	fi
	log "cache:     ${DATASET_DIR}"
}

cmd_logs() {
	require_docker
	docker logs --follow --tail 40 "${CONTAINER}"
}

cmd_down() {
	require_docker
	if [ "$(container_state)" = "running" ]; then
		docker stop "${CONTAINER}" >/dev/null
		log "stopped ${CONTAINER}; the volume keeps the data"
	else
		log "${CONTAINER} is not running"
	fi
}

cmd_reset() {
	require_docker
	remove_container
	docker volume rm "${VOLUME}" >/dev/null 2>&1 || true
	log "removed ${CONTAINER} and ${VOLUME}; the next 'up' loads the dataset again"
}

case "${1:-up}" in
	up) cmd_up ;;
	download) cmd_download ;;
	wait) cmd_wait ;;
	verify) cmd_verify ;;
	status) cmd_status ;;
	logs) cmd_logs ;;
	down) cmd_down ;;
	reset) cmd_reset ;;
	-h | --help | help) usage ;;
	*) die "unknown command '$1' (try --help)" ;;
esac
