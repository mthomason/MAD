# Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

# The MADTdsClient subset the Windows build compiles (docs/developers/build/windows.md §4): the 3
# implementation files of the Xcode target's 4, the same list as
# Linux/cmake/MADTdsClientSources.cmake.
#
# Excluded, with reason:
#   MADTdsConnectionViewController.m  the connection form: a UIKit view
#                        controller, as the Windows §4 table says of the family
#
# It sits on MADTds (the freetds base) and MADAPI, and its suite is the one the
# live SQL Server tests live in -- they skip when no server is reachable, which
# is the same contract the Xcode scheme has.  Keep this list in step with
# Linux/cmake/MADTdsClientSources.cmake.

set(MADTDSCLIENT_SOURCES
	"${SOURCE_DIR}/MADDatabaseConnectionSQLServer.m"
	"${SOURCE_DIR}/MADDatabaseProcessSQLServer.m"
	"${SOURCE_DIR}/MADDatabaseSQLServer.m"
)
