# Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

# The MADAPI subset the Linux build compiles (MAD_LINUX.md §9): the 8
# implementation files of the Xcode target's 11.
#
# Excluded, with reasons:
#   MADConnectionViewController.m            the connection form: a UIKit
#                        view controller (and its header imports UIKit)
#   MADConnectionSQLGenericViewController.m  the same form for the SQL
#                        drivers; §3 is explicit that these three files are
#                        view controllers, not headless
#
# Everything else here is the connection layer -- the database base class,
# connection, field, table, data binding, the query model, the error
# container and the read notification -- which is what the drivers and the
# refresh path sit on.  Keep this list in step with MAD_LINUX.md §4.

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
