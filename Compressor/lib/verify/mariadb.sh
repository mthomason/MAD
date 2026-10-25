# Per-library checks for mariadb, beyond the generic slice/arch and version
# gates in build.sh.  MADMySQL talks to MySQL 8.4 servers, which no longer
# enable mysql_native_password by default: the caching_sha2_password auth
# plugin must be compiled into the static library.
slice_lib="$(ls "${xcfw}"/*/libmariadbclient.a 2>/dev/null | head -1)"
if [[ -z "${slice_lib}" ]]; then
	echo "FAIL ${lib}: no libmariadbclient.a in ${xcfw}"
	exit 1
fi
# grep -c reads the whole stream: grep -q would close the pipe at the first
# match, and under pipefail the SIGPIPE in strings would fail the check.
plugin_hits="$(strings "${slice_lib}" | grep -c "caching_sha2_password" || true)"
if [[ "${plugin_hits}" -lt 1 ]]; then
	echo "FAIL ${lib}: caching_sha2_password auth plugin not compiled in"
	exit 1
fi
