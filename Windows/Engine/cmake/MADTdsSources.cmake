# Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

# The MADTds subset the Windows build compiles (docs/developers/build/windows.md §4): the whole
# framework, one implementation file.  It is the thin base over freetds --
# MADTdsClient sits on it -- and it links the freetds the build builds from the
# pin in Windows/Engine/libraries.conf.
#
# The Xcode target keeps freetds' sybdb.h Public as <MADTds/sybdb.h>; the
# include shim in build.ps1 exposes the installed header under that name.
#
# MADTds exposes no test target of its own; MADTdsClient's suite is what
# exercises it.  Keep this list in step with Linux/cmake/MADTdsSources.cmake.

set(MADTDS_SOURCES
	"${SOURCE_DIR}/MADTdsDb.m"
)
