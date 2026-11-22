# Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

# The MADFoundation subset the Windows build compiles (docs/developers/build/windows.md
# §4): the Linux list (27 of the framework's 28 implementation files plus
# madlib.c) minus one file, for Windows.
#
# Excluded, and why (the same exclusion the Linux build makes):
#   MADKeyChain.m        Security.framework SecItem*; the refresh path never
#                        reads the keychain, the credential comes from an
#                        operation dependency, and the CLI takes --credentials
#                        (excluded on Linux too)
#
# BDHost.m is back in: its reverse-DNS lookups now carry a Winsock2 branch
# behind #if defined(_WIN32) (getaddrinfo/getnameinfo, WSAStartup once), so it
# compiles and links here.  It is imported by MADTdsClient
# (MADDatabaseSQLServer.m calls +addressForHostname:), even though nothing in
# MADFoundation itself calls it; BDHostTests is registered in build.ps1.
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
