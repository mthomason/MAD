# Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

# The MADPostgres subset the Linux build compiles (docs/project/MAD_LINUX.md §9): the 4
# implementation files of the Xcode target's 5.
#
# Excluded, with reason:
#   MADPostgresConnectionViewController.m  the connection form: a UIKit view
#                        controller, as §3's table says of the family
#
# It links the libpq (plus libpgcommon and libpgport) the image builds from the
# pin in Linux/libraries.conf, with openssl beneath it.

set(MADPOSTGRES_SOURCES
	"${SOURCE_DIR}/MADDatabaseConnectionPostgres.m"
	"${SOURCE_DIR}/MADDatabasePostgres.m"
	"${SOURCE_DIR}/MADDataTypePostgres.m"
	"${SOURCE_DIR}/MADPostgresConnection.m"
)
