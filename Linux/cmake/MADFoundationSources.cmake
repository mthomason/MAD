# The MADFoundation subset Phase B compiles and links on Linux (MAD_LINUX.md
# §9): 23 of the framework's 27 implementation files, plus madlib.c.
#
# The four excluded files and why:
#   BDHost.m             CFNetwork/CFHost reverse DNS; the getaddrinfo rewrite
#                        is Phase C (§4)
#   MADApplication.m/.h  UIKit/AppKit delegate access; Phase C's AppKit guard.
#                        The umbrella MADFoundation.h imports it, so the Linux
#                        build never uses the umbrella either
#   MADKeyChain.m        Security.framework SecItem*; §4 excludes it -- the
#                        refresh path never reads the keychain
#   MADURLFactory.m      app-group containers: MADApplication.h, plus
#                        -containerURLForSecurityApplicationGroupIdentifier:
#                        which GNUstep does not implement; Phase C
#
# The first group compiles unmodified; the second needs the madlog/os_log
# shim, the third the guarded CFNumber branch.  Keep the groups in step with
# MAD_LINUX.md §4 and the Phase B status paragraph.

set(MADFOUNDATION_SOURCES
	# Foundation-only today
	"${SOURCE_DIR}/MADDataType.m"
	"${SOURCE_DIR}/MADNotificationProgress.m"
	"${SOURCE_DIR}/MADProgress.m"
	"${SOURCE_DIR}/MADStringUtilities.m"
	"${SOURCE_DIR}/NSData+Comparison.m"
	"${SOURCE_DIR}/NSOperation+Advanced.m"
	"${SOURCE_DIR}/MADOperationConditionHasResultStringResult.m"
	"${SOURCE_DIR}/MADOperationConditionTestConnectionSuccess.m"
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
