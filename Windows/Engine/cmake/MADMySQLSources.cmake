# Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

# The MADMySQL subset the Windows build compiles (docs/developers/build/windows.md §4): the 18
# implementation files of the Xcode target's 19, the same list as
# Linux/cmake/MADMySQLSources.cmake.
#
# Excluded, with reason:
#   MADMySQLConnectionViewController.m  the connection form: a UIKit view
#                        controller, as the Windows §4 table says of the family
#
# It links the mariadbclient the build builds from the pin in
# Windows/Engine/libraries.conf, with openssl beneath it.  The licence position is
# unchanged by this: the GPL/FOSS-exception blocker and the MariaDB replacement
# are docs/project/LICENSE_COMPLIANCE_PLAN.md's to settle, and nothing here ships
# (docs/developers/build/windows.md §7).
#
# Keep this list in step with Linux/cmake/MADMySQLSources.cmake.

set(MADMYSQL_SOURCES
	"${SOURCE_DIR}/MADDatabaseConnectionMySql.m"
	"${SOURCE_DIR}/MADDatabaseMySQL.m"
	"${SOURCE_DIR}/MADDataTypeMySQL.m"
	"${SOURCE_DIR}/MADMySQLCommitException.m"
	"${SOURCE_DIR}/MADMySQLConnection.m"
	"${SOURCE_DIR}/MADMySQLDelete.m"
	"${SOURCE_DIR}/MADMySQLException.m"
	"${SOURCE_DIR}/MADMySQLFetch.m"
	"${SOURCE_DIR}/MADMySQLFetch+DataTable.m"
	"${SOURCE_DIR}/MADMySQLFetchField.m"
	"${SOURCE_DIR}/MADMySQLIndex.m"
	"${SOURCE_DIR}/MADMySQLInsert.m"
	"${SOURCE_DIR}/MADMySQLLiteral.m"
	"${SOURCE_DIR}/MADMySQLRollbackException.m"
	"${SOURCE_DIR}/MADMySQLServer.m"
	"${SOURCE_DIR}/MADMySQLTruncate.m"
	"${SOURCE_DIR}/MADMySQLUpdate.m"
	"${SOURCE_DIR}/NSString+MADMySQLEscape.m"
)
