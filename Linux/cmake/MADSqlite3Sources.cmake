# Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

# The MADSqlite3 subset the Linux build compiles (MAD_LINUX.md §9): the 26
# implementation files of the Xcode target's Sources phase -- the framework
# the CLI's .maddb row cache and .madac render cache are built on.
#
# Excluded, with reasons:
#   MADArrayCachingEnumerator.m       a file reference only: the Xcode target
#   MADDatabaseResultValue.m          never compiles these five, so the Linux
#   MADQueryCacheAddRowParameters.m   build does not either (compiling a dead
#   MADQueryCacheIndexDropParameters.m file would be a guess at its state)
#   MADQuerySelectParameters.m
#
# It links the sqlite3 the image builds from the pin in Linux/libraries.conf;
# the framework imports it as <MADSqlite3/sqlite3.h> (the Xcode target keeps
# the header Public), which the include shim beside this file satisfies.
# Keep this list in step with MAD_LINUX.md §4.

set(MADSQLITE3_SOURCES
	"${SOURCE_DIR}/MADArrayCaching.m"
	"${SOURCE_DIR}/MADDataTableFast.m"
	"${SOURCE_DIR}/MADDataTableObjectEnumerator.m"
	"${SOURCE_DIR}/MADDataTableSingleColumnEnumerator.m"
	"${SOURCE_DIR}/MADDatabaseConnectionSqlite3.m"
	"${SOURCE_DIR}/MADDatabaseSqlite3.m"
	"${SOURCE_DIR}/MADQuery+Sqlite3.m"
	"${SOURCE_DIR}/MADQueryCache.m"
	"${SOURCE_DIR}/MADQueryCacheAddColumn.m"
	"${SOURCE_DIR}/MADQueryCacheAddRow.m"
	"${SOURCE_DIR}/MADQueryCacheBeginTransaction.m"
	"${SOURCE_DIR}/MADQueryCacheDeleteAllFromTable.m"
	"${SOURCE_DIR}/MADQueryCacheDropTable.m"
	"${SOURCE_DIR}/MADQueryCacheEndTransaction.m"
	"${SOURCE_DIR}/MADQueryCacheIndexCreate.m"
	"${SOURCE_DIR}/MADQueryCacheIndexCreateParameters.m"
	"${SOURCE_DIR}/MADQueryCacheIndexDrop.m"
	"${SOURCE_DIR}/MADQueryCacheJournalModeOverride.m"
	"${SOURCE_DIR}/MADQueryCacheSelectLimitOffset.m"
	"${SOURCE_DIR}/MADQueryCacheSelectRowId.m"
	"${SOURCE_DIR}/MADQueryCacheSelectRowIds.m"
	"${SOURCE_DIR}/MADQueryCacheSyncDefault.m"
	"${SOURCE_DIR}/MADQueryCacheSyncOff.m"
	"${SOURCE_DIR}/MADQueryCacheVacuum.m"
	"${SOURCE_DIR}/MADQueryParameters.m"
	"${SOURCE_DIR}/MADQuerySelectItemsForGroup.m"
)
