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
#  The container publishes 13306 on every interface.  The iOS scheme points the
#  tests at it with MAD_MYSQL_TEST_PORT=13306, and the Linux image and the CLI
#  fixtures connect to the Mac's `mac:13306`.  One port, one server, one
#  container -- do not start a second MySQL container.  (3306 is left alone
#  because the Oracle MySQL installer's launchd service may own it; see
#  docs/project/DEVELOPER.md.)
#
#  Usage:
#    mysql-test-db.sh up        create/start the server, load the data if needed (default)
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
#    MAD_TESTDB_CACHE    download cache      (default ~/Library/Caches/MADTestDatabase)
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
CACHE="${MAD_TESTDB_CACHE:-$HOME/Library/Caches/MADTestDatabase}"

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

# Echo the SQL passed on stdin (or with --execute) into the container as root,
# over the Unix socket -- root@localhost, which always exists.
mysql_root() {
	docker exec -i "${CONTAINER}" \
		mysql --user=root --password="${ROOT_PASSWORD}" --silent --skip-column-names "$@" 2>/dev/null
}

require_docker() {
	command -v docker >/dev/null 2>&1 || die "docker is not installed -- see https://docs.docker.com/desktop/"
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

checksum_matches() {
	local file="$1" expected="$2" actual
	actual="$(shasum -a 256 "${file}" | awk '{print $1}')"
	[ "${actual}" = "${expected}" ]
}

# -------------------------------------------------------------- container ---

container_state() {
	docker inspect --format '{{.State.Status}}' "${CONTAINER}" 2>/dev/null || echo "missing"
}

container_image() {
	docker inspect --format '{{.Config.Image}}' "${CONTAINER}" 2>/dev/null || echo ""
}

# From the container's config, not `docker port`: a stopped container publishes
# nothing, and `up` after `down` must restart it rather than recreate it.
container_ports() {
	docker inspect --format '{{range .HostConfig.PortBindings}}{{range .}}{{.HostPort}} {{end}}{{end}}' \
		"${CONTAINER}" 2>/dev/null || echo ""
}

remove_container() {
	docker rm -f "${CONTAINER}" >/dev/null 2>&1 || true
}

# A plain TCP connect, not lsof: a server running as another user (a stock
# MySQL install runs as _mysql) is not visible to lsof here but certainly
# holds the port.
port_in_use() { # <port>
	nc -z 127.0.0.1 "$1" >/dev/null 2>&1
}

port_conflict_message() { # <port>
	local port="$1" local_mysqld=""
	if pgrep -x mysqld >/dev/null 2>&1 || pgrep -x mysqld_safe >/dev/null 2>&1; then
		local_mysqld="
       This Mac is running its own mysqld (the Oracle installer's launchd
       service is the usual holder), and the tests use this container, not it."
	fi
	die "port ${port} is already in use on 127.0.0.1.${local_mysqld}
       Publish the container on another port with MAD_TESTDB_PORT=<port> and
       change the MADMySQL scheme's MAD_MYSQL_TEST_PORT to match."
}

container_matches() {
	local ports
	ports=" $(container_ports) "
	[ "$(container_image)" = "${MYSQL_IMAGE}" ] \
		&& [[ "${ports}" == *" ${PORT} "* ]]
}

create_container() {
	local state
	state="$(container_state)"

	if [ "${state}" = "running" ] && container_matches; then
		log "${CONTAINER} is already running"
		return 0
	fi

	# Check the port before touching anything: a conflict must not destroy a
	# container that is running happily on some other port.
	if port_in_use "${PORT}"; then
		port_conflict_message "${PORT}"
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

	log "creating ${CONTAINER} from ${MYSQL_IMAGE_TAG} on :${PORT}"
	docker volume create "${VOLUME}" >/dev/null
	if ! docker run -d \
		--name "${CONTAINER}" \
		--env MYSQL_ROOT_PASSWORD="${ROOT_PASSWORD}" \
		--env MYSQL_ROOT_HOST='%' \
		--publish "${PORT}:3306" \
		--volume "${VOLUME}:/var/lib/mysql" \
		--volume "${DATASET_DIR}:/dataset:ro" \
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
		log "port:      ${PORT} -> 3306"
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
	wait) cmd_wait ;;
	verify) cmd_verify ;;
	status) cmd_status ;;
	logs) cmd_logs ;;
	down) cmd_down ;;
	reset) cmd_reset ;;
	-h | --help | help) usage ;;
	*) die "unknown command '$1' (try --help)" ;;
esac
