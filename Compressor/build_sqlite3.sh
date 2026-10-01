#!/bin/bash
set -e # Exit on any error

# --- Configuration ---
readonly SQLITE_VERSION="3490200"
readonly SQLITE_YEAR="2025"
readonly SQLITE_ZIP_BASENAME="sqlite-src-${SQLITE_VERSION}"
readonly SQLITE_ZIP_FILENAME="${SQLITE_ZIP_BASENAME}.zip"
readonly SQLITE_DOWNLOAD_URL="https://www.sqlite.org/${SQLITE_YEAR}/${SQLITE_ZIP_FILENAME}"
readonly SQLITE_EXTRACTED_DIR_NAME="sqlite-src-${SQLITE_VERSION}"

# Determine absolute path of script
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Directory structure
readonly MEDIA_DIR="${SCRIPT_DIR}/media"
readonly SRC_BASE_DIR="${SCRIPT_DIR}/src"
readonly SRC_SQLITE_DIR="${SRC_BASE_DIR}/sqlite3"
readonly BUILD_BASE_DIR="${SCRIPT_DIR}/build"
readonly BUILD_SQLITE_DIR="${BUILD_BASE_DIR}/sqlite3"
readonly LIBRARY_BASE_DIR="${SCRIPT_DIR}/library"
readonly OUTPUT_SQLITE_DIR="${LIBRARY_BASE_DIR}/sqlite3"

# --- SQLite compile options ---
# The option list lives in sqlite3.xcconfig, which is also the base
# configuration of the MADSqlite3 target that compiles the amalgamation.  It
# is the one place these are written down.  They used to be written down here
# and nowhere else, with the target passing a different set, so the engine
# writing every .maddb cache was configured by accident: it reported a 4096
# page size where this list asked for 8192, and had no FTS5 or STAT4 at all.
# See LIBRARIES.md section 4.
readonly SQLITE_XCCONFIG="${SCRIPT_DIR}/sqlite3.xcconfig"

if [[ ! -f "${SQLITE_XCCONFIG}" ]]; then
	echo "Error: ${SQLITE_XCCONFIG} not found." >&2
	exit 1
fi

# The file holds bare macro names, because Xcode prepends -D itself.  Add it
# back here, where CFLAGS wants it.
readonly SQLITE_DEFINES="$(sed -n 's/^SQLITE_DEFINES[[:space:]]*=[[:space:]]*//p' "${SQLITE_XCCONFIG}")"

if [[ -z "${SQLITE_DEFINES}" ]]; then
	echo "Error: no SQLITE_DEFINES line in ${SQLITE_XCCONFIG}." >&2
	exit 1
fi

SQLITE_CFLAGS=()
for sqlite_define in ${SQLITE_DEFINES}; do
	SQLITE_CFLAGS+=("-D${sqlite_define}")
done

# Compiler optimization
SQLITE_CFLAGS+=("-Os")

echo "Starting SQLite3 amalgamation build..."
echo "Script directory: ${SCRIPT_DIR}"
echo "Output directory: ${OUTPUT_SQLITE_DIR}"

# --- Step 1: Directory Setup ---
echo "Cleaning and creating directories..."
rm -rf "${MEDIA_DIR}" "${SRC_SQLITE_DIR}" "${BUILD_SQLITE_DIR}" "${OUTPUT_SQLITE_DIR}"
mkdir -p "${MEDIA_DIR}" "${SRC_BASE_DIR}" "${BUILD_SQLITE_DIR}" "${LIBRARY_BASE_DIR}" "${OUTPUT_SQLITE_DIR}"

# --- Step 2: Download SQLite Source ---
echo "Downloading SQLite source..."
curl -L -o "${MEDIA_DIR}/${SQLITE_ZIP_FILENAME}" "${SQLITE_DOWNLOAD_URL}"
if [[ ! -f "${MEDIA_DIR}/${SQLITE_ZIP_FILENAME}" ]]; then
  echo "Error: Failed to download SQLite source."
  exit 1
fi

# --- Step 3: Extract and Validate Source ---
echo "Extracting SQLite source..."
unzip -q "${MEDIA_DIR}/${SQLITE_ZIP_FILENAME}" -d "${SRC_BASE_DIR}"

if [[ ! -d "${SRC_BASE_DIR}/${SQLITE_EXTRACTED_DIR_NAME}" ]]; then
  echo "Error: Expected directory '${SQLITE_EXTRACTED_DIR_NAME}' not found after extraction."
  exit 1
fi

mv "${SRC_BASE_DIR}/${SQLITE_EXTRACTED_DIR_NAME}" "${SRC_SQLITE_DIR}"

if [[ ! -f "${SRC_SQLITE_DIR}/configure" ]]; then
  echo "Error: configure script not found in ${SRC_SQLITE_DIR}"
  exit 1
fi

# --- Step 4: Configure and Build Amalgamation ---
echo "Configuring and building amalgamation..."
cd "${BUILD_SQLITE_DIR}"
export CFLAGS="${SQLITE_CFLAGS[*]}"

echo "Using CFLAGS:"
printf '  %s\n' "${SQLITE_CFLAGS[@]}"

"${SRC_SQLITE_DIR}/configure" --disable-tcl

make sqlite3.c

if [[ ! -f "sqlite3.c" || ! -f "sqlite3.h" ]]; then
  echo "Error: sqlite3.c or sqlite3.h not generated."
  exit 1
fi

# --- Step 5: Copy Output ---
echo "Copying output files to ${OUTPUT_SQLITE_DIR}..."
cp sqlite3.c sqlite3.h "${OUTPUT_SQLITE_DIR}/"

# --- Done ---
echo ""
echo "----------------------------------------------------------"
echo "SQLite3 amalgamation build complete!"
echo "Files:"
echo "  ${OUTPUT_SQLITE_DIR}/sqlite3.c"
echo "  ${OUTPUT_SQLITE_DIR}/sqlite3.h"
echo "----------------------------------------------------------"
cd "${SCRIPT_DIR}"
exit 0
