# Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

# Per-library checks for sqlite3, run by build.sh --verify inside the
# driver's verify_lib scope ($xcfw, $LIB and the matrix env are set).
#
# The compile-option strings are the §9 checks from docs/project/LIBRARIES.md: they are
# what pins the .maddb cache format (page size, DQS, TEMP_STORE, …).  FTS5
# presence is checked by its init symbol, not by counting symbols named
# fts5: at -Os the optimizer inlines away most of fts5's static functions,
# so the count varies with optimization (345 at -Os, ~599 at -O0) while
# sqlite3Fts5Init always survives because the core initializer calls it.

slice_lib="$(ls "${xcfw}"/*/libsqlite3.a 2>/dev/null | head -1)"
[[ -n "${slice_lib}" ]] || { echo "FAIL sqlite3: no libsqlite3.a in ${xcfw}"; return 1; }

# Note: grep -q/-m1 would exit on first match and SIGPIPE the producer,
# which pipefail then reports as a failure.  Count instead.
[[ "$(nm "${slice_lib}" | grep -c '_sqlite3Fts5Init')" -gt 0 ]] \
	|| { echo "FAIL sqlite3: no FTS5 code (sqlite3Fts5Init missing)"; return 1; }
echo "sqlite3: $(nm "${slice_lib}" | grep -ci fts5 || true) fts5-named symbols in $(basename "$(dirname "${slice_lib}")")"

for option in DEFAULT_PAGE_SIZE=8192 ENABLE_FTS5 ENABLE_STAT4 DQS=0 TEMP_STORE=2 THREADSAFE=1; do
	[[ "$(strings "${slice_lib}" | grep -cx "${option}")" -ge 1 ]] \
		|| { echo "FAIL sqlite3: compile option '${option}' missing"; return 1; }
done

[[ "$(strings "${slice_lib}" | grep -c "${VERSION}")" -ge 1 ]] \
	|| { echo "FAIL sqlite3: version string ${VERSION} missing"; return 1; }

echo "sqlite3: compile options verified in $(basename "$(dirname "${slice_lib}")")"
