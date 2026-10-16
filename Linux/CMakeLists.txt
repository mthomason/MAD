#
#  Linux/CMakeLists.txt -- the Phase B Linux build (MAD_LINUX.md §9).
#
#  Compiles the MADFoundation subset against GNUstep and builds the Linux
#  tests.  The flags come from gnustep-config inside the toolchain image; a
#  symlinked include shim makes the framework's <MADFoundation/...>
#  self-imports resolve without touching the sources.
#
#  The per-framework pattern -- library, groups, tests -- lives in
#  cmake/MADLinuxFramework.cmake; Linux/AGENTS.md writes down how to add the
#  next framework.
#
#  Driven by Linux/build.sh; not meant to be configured on macOS, where the
#  frameworks build with Xcode.
#

cmake_minimum_required(VERSION 3.24)	# for $<LINK_LIBRARY:WHOLE_ARCHIVE,...>

# OBJC is enabled below, once CMAKE_OBJC_FLAGS carries the GNUstep runtime
# flags, so CMake's compiler probe does not test the GCC-runtime default path.
project(MADFoundationLinux LANGUAGES C)

set(CMAKE_C_STANDARD 17)	# mirrors the Xcode GCC_C_LANGUAGE_STANDARD = gnu17

set(REPO_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/..")

find_program(GNUSTEP_CONFIG gnustep-config REQUIRED)

execute_process(COMMAND "${GNUSTEP_CONFIG}" --objc-flags
	OUTPUT_VARIABLE _gnustep_flags RESULT_VARIABLE _rc OUTPUT_STRIP_TRAILING_WHITESPACE)
if (NOT _rc EQUAL 0)
	message(FATAL_ERROR "gnustep-config --objc-flags failed; is GNUstep installed?")
endif()
execute_process(COMMAND "${GNUSTEP_CONFIG}" --base-libs
	OUTPUT_VARIABLE _gnustep_libs RESULT_VARIABLE _rc OUTPUT_STRIP_TRAILING_WHITESPACE)
if (NOT _rc EQUAL 0)
	message(FATAL_ERROR "gnustep-config --base-libs failed; is GNUstep installed?")
endif()
execute_process(COMMAND "${GNUSTEP_CONFIG}" --variable=GNUSTEP_MAKEFILES
	OUTPUT_VARIABLE GNUSTEP_MAKEFILES OUTPUT_STRIP_TRAILING_WHITESPACE)

separate_arguments(GNUSTEP_OBJC_FLAGS UNIX_COMMAND "${_gnustep_flags}")
separate_arguments(GNUSTEP_BASE_LIBS UNIX_COMMAND "${_gnustep_libs}")
list(REMOVE_ITEM GNUSTEP_OBJC_FLAGS -fobjc-arc)	# per-target: library ARC, tests MRC
if (NOT "${GNUSTEP_OBJC_FLAGS}" MATCHES "fobjc-runtime")
	message(FATAL_ERROR "gnustep-config gave no -fobjc-runtime -- wrong library combo? ${_gnustep_flags}")
endif()

# CMAKE_<LANG>_FLAGS is split on whitespace, not on CMake's list separator:
# a semicolon-joined list would reach the compiler probe as one argument.
string(REPLACE ";" " " _gnustep_objc_flags "${GNUSTEP_OBJC_FLAGS}")
set(CMAKE_OBJC_FLAGS "${_gnustep_objc_flags}")
# MADDataStructures is Objective-C++ wherever the Xcode target's files are
# .mm; the same GNUstep flags apply, with the C++ dialect Xcode sets.
set(CMAKE_OBJCXX_FLAGS "${_gnustep_objc_flags} -std=gnu++20")
# The compiler probe links a trivial Objective-C program, so libobjc2 has to
# be on that link line; the executable linker flags are the hook that reaches
# it.  The -L is required because ld.lld does not search /usr/local/lib by
# default the way gnustep-config's -L does for real targets.
#
# -lgnustep-base goes first on purpose: libobjc2 exports a weak
# objc_enumerationMutation() that prints and abort()s, and GNUstep Base
# exports the real one (it raises NSGenericException, as Apple does).  The
# dynamic linker binds the first library on the line that defines the symbol,
# so putting Base before libobjc2 here is what keeps a mutation during fast
# enumeration catchable, the way the MADDataStructures tests expect.
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -L/usr/local/lib -lgnustep-base -lobjc")
enable_language(OBJC)
enable_language(OBJCXX)

# The framework's headers import what they use, so the prelude now carries a
# single thing: NSOperation's missing `name` property (Compat/MADCompat.h),
# force-included ahead of every Objective-C translation unit (one -include:
# CMake drops duplicate flags).  Two more flags:
#   __unused is Darwin's <sys/cdefs.h> spelling the framework uses by
#   convention; glibc does not define it.
#   -Wno-format-security: the MADLog shim boxes the call site's C string
#   literal with @(fmt), which the check cannot see through; every call site
#   passes a literal.
set(MAD_OBJC_PRELUDE
	"$<$<COMPILE_LANGUAGE:OBJC,OBJCXX>:-include>"
	"$<$<COMPILE_LANGUAGE:OBJC,OBJCXX>:MADCompat.h>"
	"-D__unused=__attribute__((unused))"
	"-Wno-format-security"
	"-Wno-unused-command-line-argument")

# Shims the Linux build supplies without touching the framework: NSOperation's
# missing `name` property and the NSFileManager ubiquity methods.  See Compat/.
set(MAD_COMPAT_DIR "${CMAKE_CURRENT_SOURCE_DIR}/Compat")
set(MAD_COMPAT_SOURCES
	"${MAD_COMPAT_DIR}/NSOperation+Name.m"
	"${MAD_COMPAT_DIR}/NSFileManager+Ubiquity.m"
	"${MAD_COMPAT_DIR}/NSFileCoordinator+Presenter.m"
	"${MAD_COMPAT_DIR}/NSURL+SecurityScope.m"
	"${MAD_COMPAT_DIR}/NSURL+FileSystem.m"
	"${MAD_COMPAT_DIR}/NSData+ReadingOptions.m"
	"${MAD_COMPAT_DIR}/NSKeyedUnarchiver+TopLevel.m"
	"${MAD_COMPAT_DIR}/NSCoder+TopLevel.m"
	"${MAD_COMPAT_DIR}/NSUndoManager+Handler.m"
	"${MAD_COMPAT_DIR}/NSValue+Geometry.m"
	"${MAD_COMPAT_DIR}/NSPropertyListSerialization+Stream.m")

# The framework imports itself as <MADFoundation/Foo.h> in 100+ places; a
# symlinked directory named MADFoundation on the include path satisfies that
# without a source edit.  mad_make_include_shim adds one per framework.
set(SHIM_DIR "${CMAKE_BINARY_DIR}/shim")
file(MAKE_DIRECTORY "${SHIM_DIR}")

# The C libraries the frameworks link are built by Linux/lib/libraries.sh
# into /usr/local, the image's prefix (MAD_LINUX.md §7).
set(SQLITE3_INCLUDE_DIR "/usr/local/include")
find_library(SQLITE3_LIBRARY sqlite3 REQUIRED)
set(FREETDS_INCLUDE_DIR "/usr/local/include")
find_library(FREETDS_LIBRARY sybdb REQUIRED)
find_library(OPENSSL_SSL_LIBRARY ssl REQUIRED)
find_library(OPENSSL_CRYPTO_LIBRARY crypto REQUIRED)
find_library(MYSQL_LIBRARY mysqlclient REQUIRED)
find_library(ARCHIVE_LIBRARY archive REQUIRED)
find_library(ZLIB_LIBRARY z REQUIRED)
find_library(BZIP2_LIBRARY bz2 REQUIRED)

enable_testing()

set(TESTING_INCLUDE "${GNUSTEP_MAKEFILES}/TestFramework")
if (NOT EXISTS "${TESTING_INCLUDE}/Testing.h")
	message(FATAL_ERROR "Testing.h not found under ${TESTING_INCLUDE}")
endif()

include(cmake/MADLinuxFramework.cmake)

# The compat shims are one archive of their own.  Every framework archive used to
# embed them, which made whole-archiving two archives a duplicate-symbol error --
# and whole-archiving is the only way a category reached by message send survives
# the static link (Apple's -ObjC).  Now the shims are linked once, whole-archive,
# by each executable, and the framework archives are pure: a category in a driver
# can be whole-archived like any other code.  (Found by the CLI: mad refresh over
# MySQL aborted because .objc_category_MysqlFetchDataTable was never linked in.)
add_library(madcompat STATIC ${MAD_COMPAT_SOURCES})
target_include_directories(madcompat PUBLIC "${SHIM_DIR}" "${MAD_COMPAT_DIR}")
target_compile_options(madcompat PRIVATE
	-Wall
	$<$<COMPILE_LANGUAGE:OBJC,OBJCXX>:-fobjc-arc>
	${MAD_OBJC_PRELUDE})
target_link_libraries(madcompat PUBLIC ${GNUSTEP_BASE_LIBS} -ldispatch)

set(SOURCE_DIR "${REPO_ROOT}/MADFoundation/Source")
include(cmake/MADFoundationSources.cmake)
mad_make_include_shim(MADFoundation "${SOURCE_DIR}")
mad_add_framework(madfoundation MADFOUNDATION_SOURCES
	madlogTests
	MADProgressTests
	MADStringUtilitiesTests
	NSDataComparisonTests
	MADDataTypeTests
	MADBlockOperationTests
	MADGroupOperationTests
	MADOperationQueueTests
	MADNotificationProgressTests
	MADExclusivityControllerTests
	MADOperationTests
	MADOperationConditionTests
	MADOperationConditionResultTests
	MADDataColumnTests
	MADCredentialTests
	BDHostTests
	MADApplicationTests
	MADBlockObserverTests
	MADDataTableBaseTests
	MADDataTableVirtualTests
	MADOperationBooleanAndTests
	MADURLFactoryTests
	NSOperationAdvancedTests
	madlibTests
)

set(SOURCE_DIR "${REPO_ROOT}/MADDataStructures/Source")
include(cmake/MADDataStructuresSources.cmake)
mad_make_include_shim(MADDataStructures "${SOURCE_DIR}")
# MADVectorBool.mm says so itself: it is manual-retain-release, as the Xcode
# target's per-file -fno-objc-arc flag has it.
set_source_files_properties("${SOURCE_DIR}/MADVectorBool.mm"
	PROPERTIES COMPILE_OPTIONS "-fno-objc-arc")
mad_add_framework(maddatastructures MADDATASTRUCTURES_SOURCES
	MADDataStructuresTests
	MADMapStringsTests
	MADVectorBoolTests
	MTGraphTests
	MTLinkedListTests
	MTQueueTests
	MTStackTests
)

set(SOURCE_DIR "${REPO_ROOT}/MADFileManager/Source")
include(cmake/MADFileManagerSources.cmake)
mad_make_include_shim(MADFileManager "${SOURCE_DIR}")
mad_add_framework(madfilemanager MADFILEMANAGER_SOURCES
	MADAppStorageOptionTests
	MADDirectoryMonitorTests
	MADFileInfoTests
	MADFileUtilitiesTests
	MADLocalFileCoordinatorTests
	MADMetaDataTests
	MADStorageStateTests
)
# MADFileManager sits on MADFoundation (MADURLFactory, madlog), as it does on
# Apple; the framework's tests reach MADFoundation's objects through this link.
target_link_libraries(madfilemanager PUBLIC madfoundation)

set(SOURCE_DIR "${REPO_ROOT}/MADCocoaExtensions/Source")
include(cmake/MADCocoaExtensionsSources.cmake)
mad_make_include_shim(MADCocoaExtensions "${SOURCE_DIR}")
mad_add_framework(madcocoaextensions MADCOCOAEXTENSIONS_SOURCES
	MADBorderStyleTests
	MADDirectionTests
	MADGeometryExtrasTests
	MADMarginTests
	MADMathAlgebraTests
	MADPaddingTests
	MADTextStyleTests
	MTMathTests
	NSNumberFormatterExtensionsTests
)
target_link_libraries(madcocoaextensions PUBLIC madfoundation)

set(SOURCE_DIR "${REPO_ROOT}/MADAPI/Source")
include(cmake/MADAPISources.cmake)
mad_make_include_shim(MADAPI "${SOURCE_DIR}")
mad_add_framework(madapi MADAPI_SOURCES
	MADAPIEnumsAndConstantsTests
	MADDatabaseDriverRegistryTests
	MADDatabaseConnectionTests
	MADDatabaseDataBindingTests
	MADDatabaseFieldTests
	MADDatabaseTableTests
	MADDatabaseTests
	MADErrorContainerTests
	MADNotificationDidReadRowsTests
	MADQueryTests
)
target_link_libraries(madapi PUBLIC madfoundation madcocoaextensions)

set(SOURCE_DIR "${REPO_ROOT}/MADSqlite3/Source")
include(cmake/MADSqlite3Sources.cmake)
mad_make_include_shim(MADSqlite3 "${SOURCE_DIR}")
# The framework imports the SQLite header as <MADSqlite3/sqlite3.h> -- the
# Xcode target keeps the Compressor-built header Public under that name.  The
# libraries layer installs the amalgamation header in the image, so a second
# shim directory exposes it under the same path.
file(MAKE_DIRECTORY "${CMAKE_BINARY_DIR}/sqlite3-shim/MADSqlite3")
file(CREATE_LINK "${SQLITE3_INCLUDE_DIR}/sqlite3.h"
	"${CMAKE_BINARY_DIR}/sqlite3-shim/MADSqlite3/sqlite3.h" SYMBOLIC)
mad_add_framework(madsqlite3 MADSQLITE3_SOURCES
	MADDatabaseSqlite3DatabaseTests
	MADDatabaseSqlite3ResultValueTests
	MADDatabaseSqlite3Tests
	MADDataTableFastBenchmarkTests
	MADDataTableFastSelectTests
)
target_include_directories(madsqlite3 PUBLIC "${CMAKE_BINARY_DIR}/sqlite3-shim")
target_link_libraries(madsqlite3 PUBLIC madfoundation madapi maddatastructures ${SQLITE3_LIBRARY})

set(SOURCE_DIR "${REPO_ROOT}/MADTds/MADTds")
include(cmake/MADTdsSources.cmake)
mad_make_include_shim(MADTds "${SOURCE_DIR}")
# The framework exposes freetds' sybdb.h as <MADTds/sybdb.h>; the libraries
# layer installs it, and a second shim directory puts it under that name.
file(MAKE_DIRECTORY "${CMAKE_BINARY_DIR}/sybdb-shim/MADTds")
file(CREATE_LINK "${FREETDS_INCLUDE_DIR}/sybdb.h"
	"${CMAKE_BINARY_DIR}/sybdb-shim/MADTds/sybdb.h" SYMBOLIC)
file(CREATE_LINK "${FREETDS_INCLUDE_DIR}/tds_sysdep_public.h"
	"${CMAKE_BINARY_DIR}/sybdb-shim/MADTds/tds_sysdep_public.h" SYMBOLIC)
mad_add_framework(madtds MADTDS_SOURCES
)
target_include_directories(madtds PUBLIC "${CMAKE_BINARY_DIR}/sybdb-shim")
target_link_libraries(madtds PUBLIC madfoundation
	${FREETDS_LIBRARY} ${OPENSSL_SSL_LIBRARY} ${OPENSSL_CRYPTO_LIBRARY})

set(SOURCE_DIR "${REPO_ROOT}/MADTdsClient/Source")
include(cmake/MADTdsClientSources.cmake)
mad_make_include_shim(MADTdsClient "${SOURCE_DIR}")
# The umbrella header sits one level above Source/ in this framework, so a
# second shim directory carries it under the <MADTdsClient/...> name.
file(MAKE_DIRECTORY "${CMAKE_BINARY_DIR}/umbrella-shim/MADTdsClient")
file(CREATE_LINK "${REPO_ROOT}/MADTdsClient/MADTdsClient.h"
	"${CMAKE_BINARY_DIR}/umbrella-shim/MADTdsClient/MADTdsClient.h" SYMBOLIC)
mad_add_framework(madtdsclient MADTDSCLIENT_SOURCES
	MADTdsClientTests
	MADTdsClientLiveTests
)

set(SOURCE_DIR "${REPO_ROOT}/MADMySQL/Source")
include(cmake/MADMySQLSources.cmake)
mad_make_include_shim(MADMySQL "${SOURCE_DIR}")
mad_add_framework(madmysql MADMYSQL_SOURCES
	MADMySQLLiveTests
	MADMySQLTests
	MysqlDeleteTests
	MysqlExceptionTests
	MysqlFetchFieldTests
	MysqlInsertTests
	MysqlSupportTypesTests
	MysqlTruncateTests
	MysqlUpdateTests
)
target_link_libraries(madmysql PUBLIC madfoundation madapi ${MYSQL_LIBRARY} ${OPENSSL_SSL_LIBRARY} ${OPENSSL_CRYPTO_LIBRARY})

set(SOURCE_DIR "${REPO_ROOT}/MAD/Source")
include(cmake/MADSources.cmake)
# MAD exposes its headers flattened as <MAD/Foo.h> -- the Xcode target copies
# them into one framework header dir -- so the shim is a directory of symlinks,
# not the single symlink the other frameworks use.
file(MAKE_DIRECTORY "${SHIM_DIR}/MAD")
file(GLOB _mad_headers "${SOURCE_DIR}/*.h" "${SOURCE_DIR}/model/*.h"
	"${SOURCE_DIR}/rptq/*.h" "${SOURCE_DIR}/rptq/autogen/*.h" "${SOURCE_DIR}/rptq/store/*.h"
	"${SOURCE_DIR}/paper/*.h")
foreach (_mad_header IN LISTS _mad_headers)
	get_filename_component(_mad_header_name "${_mad_header}" NAME)
	file(CREATE_LINK "${_mad_header}" "${SHIM_DIR}/MAD/${_mad_header_name}" SYMBOLIC)
endforeach()
mad_add_framework(mad MAD_SOURCES
	MADCoreLogicTests
	MADDatabaseDriverDispatchTests
	MADHeadlessDocumentTests
	MADDataTableRegressionTests
	MADDesignerQueryTests
	MADDesignerViewerTests
	MADDocumentObjectDataReferenceTests
	MADDocumentObjectDataReferenceAggregateTests
	MADDocumentObjectDataReferenceImageTests
	MADDocumentObjectDataReferenceLabelDynamicTests
	MADDocumentObjectDataReferenceLabelStaticTests
	MADFontTests
	MADLegacyStoreConversionTests
	MADModelQueryFieldTests
	MADModelQueryTableTests
	MADNotificationAndOperationTests
	MADOperationHoldsProtocolsTests
	MADPageOptionsTests
	MADQueryCacheAggregateFunctionTests
	MADQueryDefinitionTests
	MADQueryFullTests
	MADQueryPredicateTests
	MADQuerySampleDataTests
	MADQuerySelectExpressionTests
	MADQueryTestTests
	MADQueryFullTableEnumeratorTests
	MADQueryMaxFieldLengthTests
	MADQuerySimpleTypesTests
	MADReportSectionEnumeratorTests
	MADReportSectionRepresentationTests
	MADReportSectionTests
	MADRptqDatabaseTests
	MADRptqDocumentSectionTests
	MADRptqQueryTests
	MADRptqValueTypeTests
	MADSchemaFieldSelectorModelTests
	MADStoreTests
	RptqDataHelperTests
	RptqDocumentElementFormulaTests
	RptqDocumentElementGroupKeyTests
	RptqDocumentElementLabelLinkTests
	RptqDocumentSectionEnumeratorTests
	RptqStoreContextTests
)
# The framework's own quoted imports reach across its subdirectories, the way
# the Xcode target's header search paths do.
target_include_directories(mad PRIVATE
	"${SOURCE_DIR}" "${SOURCE_DIR}/model" "${SOURCE_DIR}/rptq"
	"${SOURCE_DIR}/rptq/autogen" "${SOURCE_DIR}/rptq/store" "${SOURCE_DIR}/paper")
target_include_directories(mad PUBLIC
	"${CMAKE_BINARY_DIR}/sqlite3-shim" "${CMAKE_BINARY_DIR}/sybdb-shim"
	"${CMAKE_BINARY_DIR}/umbrella-shim")
target_compile_options(mad PRIVATE -I/usr/include/libxml2)
# The driver archives are whole-archived, not merely linked: a driver's work is
# reached through its categories (MysqlFetch+DataTable, MADQuery+Sqlite3), and a
# category is a message send -- no symbol -- so the linker drops its member
# unless the archive is whole.  The expression propagates to every consumer of
# mad, the way a category in a framework survives on Apple only with -ObjC.
# MADTds is not in the list: it is freetds' wrapper with no categories, madtdsclient
# already names it, and whole-archiving it collides with freetds' own err_handler.
target_link_libraries(mad PUBLIC
	madfoundation madapi madcocoaextensions maddatastructures madfilemanager
	"$<LINK_LIBRARY:WHOLE_ARCHIVE,madsqlite3>"
	"$<LINK_LIBRARY:WHOLE_ARCHIVE,madmysql>"
	"$<LINK_LIBRARY:WHOLE_ARCHIVE,madtdsclient>"
	${SQLITE3_LIBRARY} ${FREETDS_LIBRARY} ${MYSQL_LIBRARY} ${OPENSSL_SSL_LIBRARY} ${OPENSSL_CRYPTO_LIBRARY}
	${ARCHIVE_LIBRARY} ${ZLIB_LIBRARY} ${BZIP2_LIBRARY})
target_include_directories(madtdsclient PUBLIC "${CMAKE_BINARY_DIR}/umbrella-shim")
target_link_libraries(madtdsclient PUBLIC madtds madapi madcocoaextensions madfoundation)

# The probe is ARC (proving the ARC environment is the point) and links the
# library for its link-check block.  It is a report, not a unit test.
add_executable(ToolchainProbe Tests/ToolchainProbe.m)
target_include_directories(ToolchainProbe PRIVATE "${SHIM_DIR}" "${MAD_COMPAT_DIR}")
target_compile_options(ToolchainProbe PRIVATE
	-Wall
	$<$<COMPILE_LANGUAGE:OBJC>:-fobjc-arc>
	${MAD_OBJC_PRELUDE})
target_link_libraries(ToolchainProbe PRIVATE
	"$<LINK_LIBRARY:WHOLE_ARCHIVE,madfoundation>"
	"$<LINK_LIBRARY:WHOLE_ARCHIVE,madcompat>")
add_test(NAME ToolchainProbe COMMAND ToolchainProbe)

# ---------------------------------------------------------------------------
# `mad` -- the CLI (MAD_CLI.md).  The same sources build for the iOS Simulator
# through CLI/build.sh; this is the Linux half, and the Phase D checkpoint's
# subject.  inspect/schema/query/refresh are the verbs here; export is PDF and
# stays on Apple (MAD_LINUX.md §5.2).
#
# The target is named mad-cli because `mad` is the framework library; the
# binary is mad, the same name CLI/build.sh writes on the Mac.
# ---------------------------------------------------------------------------
set(CLI_SOURCE_DIR "${REPO_ROOT}/CLI/Source")
add_executable(mad-cli
	"${CLI_SOURCE_DIR}/main.m"
	"${CLI_SOURCE_DIR}/MADCLI.m"
	"${CLI_SOURCE_DIR}/MADCLIContainer.m"
	"${CLI_SOURCE_DIR}/MADCLIDocument.m"
	"${CLI_SOURCE_DIR}/MADCLIInspect.m"
	"${CLI_SOURCE_DIR}/MADCLIQuery.m"
	"${CLI_SOURCE_DIR}/MADCLIRefresh.m"
	"${CLI_SOURCE_DIR}/MADCLISchema.m"
	"${CLI_SOURCE_DIR}/MADCLIExport.m")
set_target_properties(mad-cli PROPERTIES OUTPUT_NAME mad)
# The framework library is whole-archived for the same reason the tests do it:
# categories (MADQuery+Sqlite3, the Rptq +Extras families) are reached by message
# send, so the linker would otherwise drop their archive members.  It also carries
# MADDriverLinkage, which is what registers the drivers.
target_include_directories(mad-cli PRIVATE "${SHIM_DIR}" "${MAD_COMPAT_DIR}")
target_compile_options(mad-cli PRIVATE
	-Wall
	$<$<COMPILE_LANGUAGE:OBJC>:-fobjc-arc>
	${MAD_OBJC_PRELUDE})
target_link_libraries(mad-cli PRIVATE
	"$<LINK_LIBRARY:WHOLE_ARCHIVE,mad>"
	"$<LINK_LIBRARY:WHOLE_ARCHIVE,madcompat>"
	${SQLITE3_LIBRARY})
