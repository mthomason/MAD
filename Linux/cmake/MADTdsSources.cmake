# The MADTds subset the Linux build compiles (MAD_LINUX.md §9): the whole
# framework, one implementation file.  It is the thin base over freetds --
# MADTdsClient sits on it -- and it links the freetds the image builds from
# the pin in Linux/libraries.conf.
#
# The Xcode target keeps freetds' sybdb.h Public as <MADTds/sybdb.h>; the
# include shim beside this file exposes the installed header under that name.
#
# MADTds exposes no test target of its own; MADTdsClient's suite is what
# exercises it.  Keep this list in step with MAD_LINUX.md §4.

set(MADTDS_SOURCES
	"${SOURCE_DIR}/MADTdsDb.m"
)
