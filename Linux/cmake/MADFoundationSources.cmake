# The MADFoundation subset the Linux build compiles (MAD_LINUX.md §9): 26 of
# the framework's 27 implementation files, plus madlib.c.
#
# The one excluded file and why:
#   MADKeyChain.m        Security.framework SecItem*; §4 excludes it -- the
#                        refresh path never reads the keychain, the credential
#                        comes from an operation dependency, and the CLI takes
#                        --credentials
#
# The umbrella MADFoundation.h stays out with it: it imports MADKeyChain.h.
#
# BDHost, MADApplication and MADURLFactory came in with the Phase C work
# (2026-10-06): BDHost's CFHost lookups are getaddrinfo/getnameinfo behind
# __APPLE__, MADApplication's AppDelegate returns nil in the headless engine,
# and MADURLFactory's UIScreen and app-group-container sites have Linux
# branches (the group path falls back to the per-user directories).  Keep the
# groups in step with MAD_LINUX.md §4 and this directory's README.

set(MADFOUNDATION_SOURCES
	# Foundation-only
	"${SOURCE_DIR}/MADDataType.m"
	"${SOURCE_DIR}/MADNotificationProgress.m"
	"${SOURCE_DIR}/MADProgress.m"
	"${SOURCE_DIR}/MADStringUtilities.m"
	"${SOURCE_DIR}/NSData+Comparison.m"
	"${SOURCE_DIR}/NSOperation+Advanced.m"
	"${SOURCE_DIR}/MADOperationConditionHasResultStringResult.m"
	"${SOURCE_DIR}/MADOperationConditionTestConnectionSuccess.m"
	"${SOURCE_DIR}/BDHost.m"
	"${SOURCE_DIR}/MADApplication.m"
	"${SOURCE_DIR}/MADURLFactory.m"
	"${SOURCE_DIR}/madlib.c"

	# need the madlog/os_log shim
	"${SOURCE_DIR}/madlog.m"
	"${SOURCE_DIR}/MADBlockObserver.m"
	"${SOURCE_DIR}/MADBlockOperation.m"
	"${SOURCE_DIR}/MADCredential.m"
	"${SOURCE_DIR}/MADDataTable.m"
	"${SOURCE_DIR}/MADDataTableVirtual.m"
	"${SOURCE_DIR}/MADExclusivityController.m"
	"${SOURCE_DIR}/MADGroupOperation.m"
	"${SOURCE_DIR}/MADOperation.m"
	"${SOURCE_DIR}/MADOperationBooleanAnd.m"
	"${SOURCE_DIR}/MADOperationConditionHasResultString.m"
	"${SOURCE_DIR}/MADOperationConditionMissingResultString.m"
	"${SOURCE_DIR}/MADOperationConditionResult.m"
	"${SOURCE_DIR}/MADOperationQueue.m"

	# needs the guarded CFNumber branch
	"${SOURCE_DIR}/MADDataColumn.m"
)
