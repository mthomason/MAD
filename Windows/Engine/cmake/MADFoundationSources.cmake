# Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

# The MADFoundation subset the Windows build compiles (docs/project/MAD_WINDOWS.md
# §4): the Linux list (26 of the framework's 27 implementation files plus
# madlib.c) minus one more file, for Windows.
#
# Excluded, and why (the same two exclusions the Linux build makes, plus one):
#   MADKeyChain.m        Security.framework SecItem*; the refresh path never
#                        reads the keychain, the credential comes from an
#                        operation dependency, and the CLI takes --credentials
#                        (excluded on Linux too)
#   BDHost.m             POSIX-socket reverse DNS (sys/socket.h,
#                        netpacket/packet.h, ifaddrs.h, arpa/inet.h).  On Linux
#                        these exist and BDHost compiles behind __APPLE__; on
#                        Windows they do not, so BDHost is excluded here until a
#                        Winsock2 port lands.  BDHost.h is imported by nothing
#                        else in this framework.
#
# The umbrella MADFoundation.h stays out with MADKeyChain: it imports
# MADKeyChain.h.
#
# Keep the groups in step with Linux/cmake/MADFoundationSources.cmake and this
# directory's README.

set(MADFOUNDATION_SOURCES
	# Foundation-only
	"${SOURCE_DIR}/MADDataType.m"
	"${SOURCE_DIR}/MADNotificationProgress.m"
	"${SOURCE_DIR}/MADProgress.m"
	"${SOURCE_DIR}/MADStringUtilities.m"
	"${SOURCE_DIR}/NSData+Comparison.m"
	"${SOURCE_DIR}/NSString+Comparison.m"
	"${SOURCE_DIR}/NSOperation+CompletionBlock.m"
	"${SOURCE_DIR}/MADOperationConditionHasResultStringResult.m"
	"${SOURCE_DIR}/MADOperationConditionTestConnectionSuccess.m"
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
