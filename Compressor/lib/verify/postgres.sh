# Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

# Per-library checks for PostgreSQL's libpq, run by build.sh --verify inside
# the driver's verify_lib scope ($xcfw, $LIB and the matrix env are set).
#
# Checks:
#   - libpq-fe.h, postgres_ext.h, and pg_config_ext.h are at the top of
#     library/postgres/include/
#   - Core libpq entry points, OpenSSL TLS initialization, SCRAM-SHA-256
#     authentication, and symbols from libpgcommon and libpgport are all
#     present in the merged static archive.

slice_lib="$(ls "${xcfw}"/*/libpq.a 2>/dev/null | head -1)"
[[ -n "${slice_lib}" ]] || { echo "FAIL postgres: no libpq.a in ${xcfw}"; return 1; }

for hdr in libpq-fe.h libpq-events.h postgres_ext.h pg_config_ext.h pg_type_d.h; do
	[[ -f "${LIBRARY_DIR}/postgres/include/${hdr}" ]] \
		|| { echo "FAIL postgres: ${hdr} missing from include/"; return 1; }
done

for sym in _PQconnectdbParams _PQexec _PQescapeLiteral _pg_char_to_encoding _pg_encoding_to_char _pg_scram_mech _scram_SaltedPassword _pg_strcasecmp _pgtls_init; do
	[[ "$(nm -g "${slice_lib}" | grep -cE " [TDS] ${sym}$")" -gt 0 ]] \
		|| { echo "FAIL postgres: defined symbol ${sym} missing"; return 1; }
done

echo "postgres: symbols and headers verified in $(basename "$(dirname "${slice_lib}")")"
