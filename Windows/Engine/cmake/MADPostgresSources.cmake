# Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

# The MADPostgres subset the Windows build compiles (docs/project/MAD_WINDOWS.md §4): the 4
# implementation files of the Xcode target's 5, the same list as
# Linux/cmake/MADPostgresSources.cmake.
#
# Excluded, with reason:
#   MADPostgresConnectionViewController.m  the connection form: a UIKit view
#                        controller, as the Windows §4 table says of the family
#
# It links the libpq the build builds from the pin in Windows/Engine/libraries.conf,
# with openssl beneath it.  Keep this list in step with Linux/cmake/MADPostgresSources.cmake.

set(MADPOSTGRES_SOURCES
	"${SOURCE_DIR}/MADDatabaseConnectionPostgres.m"
	"${SOURCE_DIR}/MADDatabasePostgres.m"
	"${SOURCE_DIR}/MADDataTypePostgres.m"
	"${SOURCE_DIR}/MADPostgresConnection.m"
)
