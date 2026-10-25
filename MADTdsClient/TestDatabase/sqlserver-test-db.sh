#!/bin/bash
# Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
#
#  sqlserver-test-db.sh -- the pinned SQL Server test server, in Docker.
#
#  The live tests in MADTdsClientTests/MADTdsClientLiveTests.m talk to a real
#  SQL Server on 127.0.0.1:1433 as sa/Root1@Root2 and SKIP when there is not
#  one.  This script supplies that server: one container (`mad-mssql`), created
#  from a digest-pinned image, whose named volume holds the AdventureWorksLT2022
#  sample database restored from a checksum-verified backup.
#
#  The same container serves the Linux image and the CLI fixtures, which reach
#  the Mac's `mac:1433`; the port is published on every interface for that
#  reason.  One server -- do not start a second SQL Server container.
#
#  Usage:
#    sqlserver-test-db.sh up       create/start the server, restore if needed (default)
#    sqlserver-test-db.sh wait     block until the server answers
#    sqlserver-test-db.sh verify   check the database and its pinned row count
#    sqlserver-test-db.sh status   container, port, volume, and what is loaded
#    sqlserver-test-db.sh logs     tail the server log
#    sqlserver-test-db.sh down     stop the container (the volume keeps the data)
#    sqlserver-test-db.sh reset    remove the container and its volume
#
#  `up` is idempotent: it creates the container when it is missing, starts it
#  when it is stopped, leaves it alone when the pinned image, port and volume
#  match, and restores the backup only when the database is absent.
#
#  Environment overrides:
#    MAD_TESTDB_PORT    host port to publish (default 1433, what the tests use)
#    MAD_TESTDB_NAME    container name      (default mad-mssql)
#    MAD_TESTDB_VOLUME  volume name         (default mad-mssql-data)
#    MAD_TESTDB_CACHE   download cache      (default ~/Library/Caches/MADTestDatabase)
#    MAD_TESTDB_BACKUP  use this local .bak instead of the cache/download
#
#  The first `up` pulls the image (~1.5 GB), starts SQL Server, and restores
#  the 8 MB backup (a minute or two).  Later runs take seconds.  Bump the pins
#  in db.conf to move to a new server or a new backup; a mismatched container is
#  recreated on the same volume, and a missing database is restored again.
#
#  Runs on the system bash (3.2 on macOS): no associative arrays, no mapfile.

set -euo pipefail

TESTDB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=db.conf
. "${TESTDB_DIR}/db.conf"

CONTAINER="${MAD_TESTDB_NAME:-mad-mssql}"
VOLUME="${MAD_TESTDB_VOLUME:-mad-mssql-data}"
PORT="${MAD_TESTDB_PORT:-1433}"
CACHE="${MAD_TESTDB_CACHE:-$HOME/Library/Caches/MADTestDatabase}"
BACKUP="${MAD_TESTDB_BACKUP:-${CACHE}/${DATASET_FILENAME}}"
MSSQL_IMAGE="${MSSQL_IMAGE_TAG}@${MSSQL_IMAGE_DIGEST}"

die() {
	echo "error: $*" >&2
	exit 1
}

log() {
	echo "[sqlserver-test-db] $*"
}

usage() {
	awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "$0"
}

require_docker() {
	command -v docker >/dev/null 2>&1 || die "docker is not installed -- see https://docs.docker.com/desktop/"
	docker info >/dev/null 2>&1 || die "the docker daemon is not running"
}

# ---------------------------------------------------------------- dataset ---

fetch_backup() {
	if [ "${MAD_TESTDB_BACKUP:-}" != "" ]; then
		[ -f "${BACKUP}" ] || die "MAD_TESTDB_BACKUP is set but ${BACKUP} does not exist"
		checksum_matches "${BACKUP}" "${DATASET_SHA256}" \
			|| die "backup checksum mismatch: ${BACKUP}"
		return 0
	fi

	mkdir -p "${CACHE}"

	if [ -f "${BACKUP}" ] && ! checksum_matches "${BACKUP}" "${DATASET_SHA256}"; then
		log "cached backup does not match db.conf; downloading again"
		rm -f "${BACKUP}"
	fi

	if [ ! -f "${BACKUP}" ]; then
		log "downloading ${DATASET_URL}"
		curl -fSL --retry 3 --retry-delay 2 -o "${BACKUP}.part" "${DATASET_URL}" \
			|| die "could not download the backup"
		mv "${BACKUP}.part" "${BACKUP}"
	fi

	checksum_matches "${BACKUP}" "${DATASET_SHA256}" \
		|| die "backup checksum mismatch: ${BACKUP}"
}

checksum_matches() { # <file> <sha256>
	local actual
	actual="$(shasum -a 256 "$1" | awk '{print $1}')"
	[ "${actual}" = "$2" ]
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

container_volume() {
	docker inspect --format '{{range .Mounts}}{{if eq .Destination "/var/opt/mssql"}}{{.Name}}{{end}}{{end}}' \
		"${CONTAINER}" 2>/dev/null || echo ""
}

remove_container() {
	docker rm -f "${CONTAINER}" >/dev/null 2>&1 || true
}

# A plain TCP connect, not lsof: another SQL Server may be running as a
# different user and still hold the port.
port_in_use() {
	nc -z 127.0.0.1 "${PORT}" >/dev/null 2>&1
}

container_matches() {
	local ports
	ports=" $(container_ports) "
	[ "$(container_image)" = "${MSSQL_IMAGE}" ] \
		&& [[ "${ports}" == *" ${PORT} "* ]] \
		&& [ "$(container_volume)" = "${VOLUME}" ]
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
	if port_in_use; then
		die "port ${PORT} is already in use on 127.0.0.1.
       Stop the server holding it, or publish the container on another port
       with MAD_TESTDB_PORT=<port> and point the tests at it with
       MAD_TDS_TEST_PORT=<port>."
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

	log "creating ${CONTAINER} from ${MSSQL_IMAGE_TAG} on :${PORT}"
	docker volume create "${VOLUME}" >/dev/null
	if ! docker run -d \
		--name "${CONTAINER}" \
		--env ACCEPT_EULA=Y \
		--env MSSQL_SA_PASSWORD="${SA_PASSWORD}" \
		--env MSSQL_PID=developer \
		--publish "${PORT}:1433" \
		--volume "${VOLUME}:/var/opt/mssql" \
		"${MSSQL_IMAGE}" >/dev/null; then
		# A failed -d leaves a container behind in the created state.
		remove_container
		die "could not start the container (see the docker error above)"
	fi
}

# sqlcmd lives under one of two paths depending on the image revision.
sqlcmd_path() {
	local path
	for path in /opt/mssql-tools18/bin/sqlcmd /opt/mssql-tools/bin/sqlcmd; do
		if docker exec "${CONTAINER}" test -x "${path}" >/dev/null 2>&1; then
			echo "${path}"
			return 0
		fi
	done
	die "sqlcmd is not in ${CONTAINER}"
}

sqlcmd() { # <query> -- trimmed rows, no headers
	docker exec "${CONTAINER}" "$(sqlcmd_path)" \
		-S localhost -U sa -P "${SA_PASSWORD}" -C -h -1 -W \
		-Q "SET NOCOUNT ON; $1"
}

wait_for_server() {
	local attempts=0
	while ! sqlcmd "SELECT 1" >/dev/null 2>&1; do
		attempts=$((attempts + 1))
		if [ "${attempts}" -ge 120 ]; then
			docker logs --tail 30 "${CONTAINER}" >&2 2>/dev/null || true
			die "the server did not become ready within 120s"
		fi
		sleep 1
	done
}

# ---------------------------------------------------------------- loading ---

database_loaded() {
	local id
	id="$(sqlcmd "SELECT DB_ID(N'${DATABASE_NAME}')" 2>/dev/null || true)"
	[ "${id}" != "NULL" ] && [ -n "${id}" ]
}

product_count() {
	sqlcmd "SELECT COUNT(*) FROM [${DATABASE_NAME}].[SalesLT].[Product]" 2>/dev/null || true
}

restore_dataset() {
	log "restoring ${DATABASE_NAME} from ${DATASET_FILENAME} -- a minute or two, once per volume"
	docker exec -u root "${CONTAINER}" mkdir -p /var/opt/mssql/backup
	docker cp "${BACKUP}" "${CONTAINER}:/var/opt/mssql/backup/${DATASET_FILENAME}" >/dev/null
	docker exec -u root "${CONTAINER}" chown -R mssql:mssql /var/opt/mssql/backup

	sqlcmd "RESTORE DATABASE [${DATABASE_NAME}]
		FROM DISK = N'/var/opt/mssql/backup/${DATASET_FILENAME}'
		WITH FILE = 1,
			MOVE N'${DATASET_LOGICAL_DATA}' TO N'/var/opt/mssql/data/${DATABASE_NAME}.mdf',
			MOVE N'${DATASET_LOGICAL_LOG}' TO N'/var/opt/mssql/data/${DATABASE_NAME}_log.ldf',
			NOUNLOAD, REPLACE, STATS = 10" >/dev/null \
		|| die "the restore failed (docker logs ${CONTAINER})"
}

verify_dataset() {
	local count
	count="$(product_count)"
	[ "${count}" = "${DATASET_PRODUCT_COUNT}" ] \
		|| die "expected ${DATASET_PRODUCT_COUNT} products in ${DATABASE_NAME}, found '${count}'"
	log "dataset verified: ${DATABASE_NAME} has its ${DATASET_PRODUCT_COUNT} SalesLT.Product rows"
}

# --------------------------------------------------------------- commands ---

cmd_up() {
	require_docker
	fetch_backup
	create_container
	wait_for_server

	if database_loaded; then
		log "ready on 127.0.0.1:${PORT} (database already loaded)"
		verify_dataset
		return 0
	fi

	restore_dataset
	verify_dataset
	log "ready on 127.0.0.1:${PORT} (dataset restored)"
}

cmd_wait() {
	require_docker
	wait_for_server
	log "the server answers on 127.0.0.1:${PORT}"
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
	log "volume:    $(container_volume)"
	if [ "${state}" = "running" ]; then
		log "port:      ${PORT} -> 1433"
		if database_loaded; then
			log "database:  ${DATABASE_NAME} (products: $(product_count))"
		else
			log "database:  ${DATABASE_NAME} is not loaded"
		fi
	else
		log "port:      not published while stopped"
	fi
	log "backup:    ${BACKUP}"
}

cmd_logs() {
	require_docker
	docker logs --follow --tail 40 "${CONTAINER}"
}

cmd_down() {
	require_docker
	if [ "$(container_state)" = "running" ]; then
		# Ask SQL Server itself to shut down: a plain docker stop under
		# emulation was killed before it finished (exit 137), while its own
		# SHUTDOWN checkpoints and exits with 255 ("shut down by request").
		sqlcmd "SHUTDOWN" >/dev/null 2>&1 || true
		docker stop --time 60 "${CONTAINER}" >/dev/null 2>&1 || true
		log "stopped ${CONTAINER}; the volume keeps the data"
	else
		log "${CONTAINER} is not running"
	fi
}

cmd_reset() {
	require_docker
	remove_container
	docker volume rm "${VOLUME}" >/dev/null 2>&1 || true
	log "removed ${CONTAINER} and ${VOLUME}; the next 'up' restores the database"
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
