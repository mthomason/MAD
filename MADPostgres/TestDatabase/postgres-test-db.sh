#!/bin/bash
# Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
#
#  postgres-test-db.sh -- the pinned PostgreSQL test server, in Docker.
#
#  The live tests in MADPostgresTests/MADPostgresLiveTests.m talk to a real
#  PostgreSQL server on 127.0.0.1:5432 as mad/mad_test_pw against `chinook` and
#  SKIP when there is not one.  This script supplies that server: one container
#  (`mad-postgres`), created from a digest-pinned image, whose named volume
#  holds a checksum-verified copy of the Chinook PostgreSQL sample database.
#
#  The same container serves the Linux image and the CLI fixtures, which reach
#  the Mac's `mac:5432`; the port is published on every interface for that
#  reason.  One server -- do not start a second PostgreSQL container.
#
#  Usage:
#    postgres-test-db.sh up       create/start the server, load data if needed (default)
#    postgres-test-db.sh wait     block until the server answers
#    postgres-test-db.sh verify   check the database and its pinned row counts
#    postgres-test-db.sh status   container, port, volume, and what is loaded
#    postgres-test-db.sh logs     tail the server log
#    postgres-test-db.sh down     stop the container (the volume keeps the data)
#    postgres-test-db.sh reset    remove the container and its volume
#
#  `up` is idempotent: it creates the container when it is missing, starts it
#  when it is stopped, and leaves it alone when the pinned image, port and
#  loaded dataset match.  The MADPostgres scheme calls it from the test
#  action's pre-action (and `down` from the post-action), so the server runs
#  only while the tests do.
#
#  Environment overrides:
#    MAD_TESTDB_PORT     host port to publish (default 5432, what the tests use)
#    MAD_TESTDB_NAME     container name       (default mad-postgres)
#    MAD_TESTDB_VOLUME   volume name          (default mad-postgres-test-data)
#    MAD_TESTDB_CACHE    download cache       (default ~/Library/Caches/MADTestDatabase)
#
#  Runs on the system bash (3.2 on macOS): no associative arrays, no mapfile.

set -euo pipefail
exec </dev/null

export PATH="/Applications/Docker.app/Contents/Resources/bin:/opt/homebrew/bin:/usr/local/bin:${PATH}"

TESTDB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=db.conf
. "${TESTDB_DIR}/db.conf"

CONTAINER="${MAD_TESTDB_NAME:-mad-postgres}"
VOLUME="${MAD_TESTDB_VOLUME:-mad-postgres-test-data}"
PORT="${MAD_TESTDB_PORT:-5432}"
CACHE="${MAD_TESTDB_CACHE:-$HOME/Library/Caches/MADTestDatabase}"

DATASET_SQL="${CACHE}/${DATASET_FILENAME}"
POSTGRES_IMAGE="${POSTGRES_IMAGE_TAG}@${POSTGRES_IMAGE_DIGEST}"

die() {
	echo "error: $*" >&2
	exit 1
}

log() {
	echo "[postgres-test-db] $*"
}

usage() {
	awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "$0"
}

psql_exec() { # <db> [args...]
	local db="$1"
	shift
	docker exec -e PGPASSWORD="${POSTGRES_PASSWORD}" "${CONTAINER}" \
		psql -v ON_ERROR_STOP=1 --username="${POSTGRES_USER}" --dbname="${db}" --tuples-only --no-align --quiet "$@" </dev/null 2>/dev/null
}

require_docker() {
	command -v docker >/dev/null 2>&1 || die "docker is not installed -- see https://docs.docker.com/desktop/"
	docker info >/dev/null 2>&1 || die "the docker daemon is not running"
}

# ---------------------------------------------------------------- dataset ---

checksum_matches() {
	local file="$1" expected="$2" actual
	actual="$(shasum -a 256 "${file}" | awk '{print $1}')"
	[ "${actual}" = "${expected}" ]
}

fetch_dataset() {
	mkdir -p "${CACHE}"

	if [ -f "${DATASET_SQL}" ] && ! checksum_matches "${DATASET_SQL}" "${DATASET_SHA256}"; then
		log "cached SQL file does not match db.conf; downloading again"
		/bin/rm -f "${DATASET_SQL}"
	fi

	if [ ! -f "${DATASET_SQL}" ]; then
		log "downloading ${DATASET_URL}"
		curl -fSL --retry 3 --retry-delay 2 -o "${DATASET_SQL}.part" "${DATASET_URL}" \
			|| die "could not download the dataset"
		/bin/mv -f "${DATASET_SQL}.part" "${DATASET_SQL}"
	fi

	checksum_matches "${DATASET_SQL}" "${DATASET_SHA256}" \
		|| die "dataset checksum mismatch: ${DATASET_SQL}"
}

# -------------------------------------------------------------- container ---

container_state() {
	docker inspect --format '{{.State.Status}}' "${CONTAINER}" 2>/dev/null || echo "missing"
}

container_image() {
	docker inspect --format '{{.Config.Image}}' "${CONTAINER}" 2>/dev/null || echo ""
}

container_ports() {
	docker inspect --format '{{range .HostConfig.PortBindings}}{{range .}}{{.HostPort}} {{end}}{{end}}' \
		"${CONTAINER}" 2>/dev/null || echo ""
}

remove_container() {
	docker rm -f "${CONTAINER}" >/dev/null 2>&1 || true
}

port_in_use() { # <port>
	nc -z 127.0.0.1 "$1" >/dev/null 2>&1
}

port_conflict_message() { # <port>
	local port="$1"
	die "port ${port} is already in use on 127.0.0.1.
       Publish the container on another port with MAD_TESTDB_PORT=<port> and
       set MAD_PG_TEST_PORT to match."
}

container_matches() {
	local ports
	ports=" $(container_ports) "
	[ "$(container_image)" = "${POSTGRES_IMAGE}" ] \
		&& [[ "${ports}" == *" ${PORT} "* ]]
}

create_container() {
	local state
	state="$(container_state)"

	if [ "${state}" = "running" ] && container_matches; then
		log "${CONTAINER} is already running"
		return 0
	fi

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

	log "creating ${CONTAINER} from ${POSTGRES_IMAGE_TAG} on :${PORT}"
	docker volume create "${VOLUME}" >/dev/null
	if ! docker run -d \
		--name "${CONTAINER}" \
		--env POSTGRES_USER="${POSTGRES_USER}" \
		--env POSTGRES_PASSWORD="${POSTGRES_PASSWORD}" \
		--env POSTGRES_DB="postgres" \
		--publish "${PORT}:5432" \
		--volume "${VOLUME}:/var/lib/postgresql/data" \
		--volume "${CACHE}:/dataset:ro" \
		"${POSTGRES_IMAGE}" >/dev/null; then
		remove_container
		die "could not start the container (see the docker error above)"
	fi
}

wait_for_server() {
	local attempts=0
	while ! docker exec -e PGPASSWORD="${POSTGRES_PASSWORD}" "${CONTAINER}" \
			pg_isready --host=127.0.0.1 --username="${POSTGRES_USER}" --dbname="postgres" >/dev/null 2>&1; do
		attempts=$((attempts + 1))
		if [ "${attempts}" -ge 60 ]; then
			docker logs --tail 30 "${CONTAINER}" >&2 2>/dev/null || true
			die "the server did not become ready within 60s"
		fi
		sleep 1
	done
}

# ---------------------------------------------------------------- loading ---

loaded_sha256() {
	psql_exec "postgres" -c "SELECT file_sha256 FROM public.mad_test_dataset ORDER BY loaded_at DESC LIMIT 1;" || true
}

artist_count() {
	psql_exec "${DATABASE_NAME}" -c "SELECT COUNT(*) FROM public.artist;" || true
}

album_count() {
	psql_exec "${DATABASE_NAME}" -c "SELECT COUNT(*) FROM public.album;" || true
}

track_count() {
	psql_exec "${DATABASE_NAME}" -c "SELECT COUNT(*) FROM public.track;" || true
}

load_dataset() {
	log "loading the Chinook dataset into ${DATABASE_NAME}"
	docker exec -e PGPASSWORD="${POSTGRES_PASSWORD}" "${CONTAINER}" \
		psql -v ON_ERROR_STOP=1 --username="${POSTGRES_USER}" --dbname="postgres" --quiet \
		-f "/dataset/${DATASET_FILENAME}" </dev/null >/dev/null \
		|| die "the dataset load failed"

	psql_exec "postgres" -c "
		CREATE TABLE IF NOT EXISTS public.mad_test_dataset (
			dataset_version VARCHAR(32) NOT NULL,
			file_sha256     VARCHAR(64) NOT NULL,
			loaded_at       TIMESTAMPTZ NOT NULL
		);
		DELETE FROM public.mad_test_dataset;
		INSERT INTO public.mad_test_dataset VALUES ('${DATASET_VERSION}', '${DATASET_SHA256}', NOW());" \
		|| die "could not record the loaded dataset"
}

verify_dataset() {
	local artists albums tracks
	artists="$(artist_count)"
	albums="$(album_count)"
	tracks="$(track_count)"

	[ "${artists}" = "${DATASET_ARTIST_COUNT}" ] \
		|| die "expected ${DATASET_ARTIST_COUNT} artists, found '${artists}'"
	[ "${albums}" = "${DATASET_ALBUM_COUNT}" ] \
		|| die "expected ${DATASET_ALBUM_COUNT} albums, found '${albums}'"
	[ "${tracks}" = "${DATASET_TRACK_COUNT}" ] \
		|| die "expected ${DATASET_TRACK_COUNT} tracks, found '${tracks}'"

	log "dataset verified: ${artists} artists, ${albums} albums, ${tracks} tracks"
}

# --------------------------------------------------------------- commands ---

cmd_up() {
	require_docker
	fetch_dataset
	create_container
	wait_for_server

	local loaded
	loaded="$(loaded_sha256)"

	if [ "${loaded}" = "${DATASET_SHA256}" ] && [ "$(artist_count)" = "${DATASET_ARTIST_COUNT}" ]; then
		log "ready on :${PORT} (Chinook ${DATASET_VERSION}, already loaded)"
		return 0
	fi

	load_dataset
	verify_dataset
	log "ready on :${PORT} (Chinook ${DATASET_VERSION})"
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
		log "port:      ${PORT} -> 5432"
		log "loaded:    $(loaded_sha256)"
		log "artists:   $(artist_count)"
		log "albums:    $(album_count)"
		log "tracks:    $(track_count)"
	else
		log "port:      not published while stopped"
	fi
	log "cache:     ${DATASET_SQL}"
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
