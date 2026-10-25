# Per-library checks for mariadb, beyond the generic slice/arch and version
# gates in build.sh.  MADMySQL talks to MySQL 8.4 servers, which no longer
# enable mysql_native_password by default: the caching_sha2_password auth
# plugin must be compiled into the static library.
slice_lib="$(ls "${xcfw}"/*/libmariadbclient.a 2>/dev/null | head -1)"
if [[ -z "${slice_lib}" ]]; then
	echo "FAIL ${lib}: no libmariadbclient.a in ${xcfw}"
	exit 1
fi
if ! strings "${slice_lib}" | grep -q "caching_sha2_password"; then
	echo "FAIL ${lib}: caching_sha2_password auth plugin not compiled in"
	exit 1
fi
