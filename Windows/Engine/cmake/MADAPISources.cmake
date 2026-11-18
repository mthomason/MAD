# Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

# The MADAPI subset the Windows build compiles: the 8 implementation files of
# the Xcode target's 11 (the same list as Linux/cmake/MADAPISources.cmake).
#
# MADAPI is not a Phase 2b deliverable of its own; it is the transitive
# dependency MADSqlite3 pulls in -- MADDatabaseSqlite3 is a MADDatabase, and
# MADDatabaseConnectionSqlite3 is a MADDatabaseConnection.  Its tests are not
# ported here (they are not part of Phase 2b).
#
# Excluded, with reasons:
#   MADConnectionViewController.m            the connection form: a UIKit
#   MADConnectionSQLGenericViewController.m  view controller (and its header
#                        imports UIKit); these three files are view
#                        controllers, not headless
#
# The view-controller headers those exclusions drop are not imported by any of
# the 8 files below (grep-verified), so MADAPI compiles here without the
# MADCocoaExtensions headers those view controllers reach for.  Keep this list
# in step with Linux/cmake/MADAPISources.cmake and docs/project/MAD_WINDOWS.md.

set(MADAPI_SOURCES
	"${SOURCE_DIR}/MADDatabase.m"
	"${SOURCE_DIR}/MADDatabaseConnection.m"
	"${SOURCE_DIR}/MADDatabaseDriverRegistry.m"
	"${SOURCE_DIR}/MADDatabaseDataBinding.m"
	"${SOURCE_DIR}/MADDatabaseField.m"
	"${SOURCE_DIR}/MADDatabaseTable.m"
	"${SOURCE_DIR}/MADErrorContainer.m"
	"${SOURCE_DIR}/MADNotificationDidReadRows.m"
	"${SOURCE_DIR}/MADQuery.m"
)
