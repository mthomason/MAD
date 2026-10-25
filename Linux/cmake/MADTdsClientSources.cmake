# Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

# The MADTdsClient subset the Linux build compiles (docs/project/MAD_LINUX.md §9): the 4
# implementation files of the Xcode target's 5.
#
# Excluded, with reason:
#   MADTdsConnectionViewController.m  the connection form: a UIKit view
#                        controller, as §3's table says of MADAPI's pair
#
# It sits on MADTds (the freetds base) and MADAPI, and its suite is the one
# the live SQL Server tests live in -- they skip when no server is reachable,
# which is the same contract the Xcode scheme has.  Keep this list in step
# with docs/project/MAD_LINUX.md §4.

set(MADTDSCLIENT_SOURCES
	"${SOURCE_DIR}/MADDatabaseConnectionSQLServer.m"
	"${SOURCE_DIR}/MADDatabaseProcessSQLServer.m"
	"${SOURCE_DIR}/MADDatabaseSQLServer.m"
)
