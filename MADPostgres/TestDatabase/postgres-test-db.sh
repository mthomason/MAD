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
#  On macOS/Linux the same container serves the Linux image and the CLI fixtures,
#  which reach the Mac's `mac:5432`; the port is published on every interface for
#  that reason.  On Windows it binds loopback by default so the test server is
#  not exposed on the LAN.  One server -- do not start a second PostgreSQL
#  container.
#
#  Usage:
#    postgres-test-db.sh up       create/start the server, load data if needed (default)
#    postgres-test-db.sh download fetch + checksum-verify the dataset into the cache (no Docker)
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
#    MAD_TESTDB_CACHE    download cache       (default is per-platform, see below)
#    MAD_TESTDB_BIND     host IP to bind the published port to (default "" on
#                        macOS/Linux = all interfaces; "127.0.0.1" on Windows)
#
#  The download cache defaults to $HOME/Library/Caches/MADTestDatabase on macOS,
#  ${XDG_CACHE_HOME:-$HOME/.cache}/MADTestDatabase on Linux and
#  ${LOCALAPPDATA}/MADTestDatabase on Windows.
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

psql_exec() { # <db> [args...]
	local db="$1"
	shift
	docker exec -e PGPASSWORD="${POSTGRES_PASSWORD}" "${CONTAINER}" \
		psql -v ON_ERROR_STOP=1 --username="${POSTGRES_USER}" --dbname="${db}" --tuples-only --no-align --quiet "$@" </dev/null 2>/dev/null
}

require_docker() {
	[ -n "${DOCKER_BIN}" ] || die "docker is not installed -- see https://docs.docker.com/desktop/"
	docker info >/dev/null 2>&1 || die "the docker daemon is not running"
}

# ---------------------------------------------------------------- dataset ---

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

# A plain TCP connect, not lsof: another PostgreSQL may be running as a
# different user and still hold the port.  Prefers nc; on Windows without nc it
# falls back to PowerShell's Test-NetConnection; if neither can answer it
# reports "could not pre-check" and lets Docker report a real conflict.
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
	local port="$1"
	die "port ${port} is already in use on 127.0.0.1.
	       Publish the container on another port with MAD_TESTDB_PORT=<port> and
	       set MAD_PG_TEST_PORT to match."
}

container_matches() {
	[ "$(container_image)" = "${POSTGRES_IMAGE}" ] \
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

	log "creating ${CONTAINER} from ${POSTGRES_IMAGE_TAG} on $(publish_arg 5432)"
	docker volume create "${VOLUME}" >/dev/null
	if ! docker run -d \
		--name "${CONTAINER}" \
		--env POSTGRES_USER="${POSTGRES_USER}" \
		--env POSTGRES_PASSWORD="${POSTGRES_PASSWORD}" \
		--env POSTGRES_DB="postgres" \
		--publish "$(publish_arg 5432)" \
		--volume "${VOLUME}:/var/lib/postgresql/data" \
		--volume "$(docker_host_path "${CACHE}"):/dataset:ro" \
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

cmd_download() {
	if [ -f "${DATASET_SQL}" ] && checksum_matches "${DATASET_SQL}" "${DATASET_SHA256}"; then
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
		log "port:      ${PORT} -> 5432 (bind: ${BIND:-all interfaces})"
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
