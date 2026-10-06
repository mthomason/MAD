#
#  Linux/CMakeLists.txt -- the Phase B Linux build (MAD_LINUX.md §9).
#
#  Compiles the MADFoundation subset against GNUstep and builds the Linux
#  tests.  The flags come from gnustep-config inside the toolchain image; a
#  symlinked include shim makes the framework's <MADFoundation/...>
#  self-imports resolve without touching the sources.
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
set(SOURCE_DIR "${REPO_ROOT}/MADFoundation/Source")

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
# The compiler probe links a trivial Objective-C program, so libobjc2 has to
# be on that link line; the executable linker flags are the hook that reaches
# it.  The -L is required because ld.lld does not search /usr/local/lib by
# default the way gnustep-config's -L does for real targets.
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -L/usr/local/lib -lobjc")
enable_language(OBJC)

# The sources lean on Apple's Foundation transitively providing Foundation
# types (NSError, NSNumber...) and dispatch_*, and on NSOperation's `name`;
# Compat/MADCompat.h is the one header that supplies all three, force-included
# ahead of every Objective-C translation unit (one -include: CMake drops
# duplicate flags).  Two more flags:
#   __unused is Darwin's <sys/cdefs.h> spelling the framework uses by
#   convention; glibc does not define it.
#   -Wno-format-security: the MADLog shim boxes the call site's C string
#   literal with @(fmt), which the check cannot see through; every call site
#   passes a literal.
set(MAD_OBJC_PRELUDE
	"$<$<COMPILE_LANGUAGE:OBJC>:-include>"
	"$<$<COMPILE_LANGUAGE:OBJC>:MADCompat.h>"
	"-D__unused=__attribute__((unused))"
	"-Wno-format-security"
	"-Wno-unused-command-line-argument")

# Shims the Linux build supplies without touching the framework: currently
# NSOperation's missing `name` property.  See Compat/.
set(MAD_COMPAT_DIR "${CMAKE_CURRENT_SOURCE_DIR}/Compat")

# The framework imports itself as <MADFoundation/Foo.h> in 100+ places; a
# symlinked directory named MADFoundation on the include path satisfies that
# without a source edit.
set(SHIM_DIR "${CMAKE_BINARY_DIR}/shim")
file(MAKE_DIRECTORY "${SHIM_DIR}")
if (NOT EXISTS "${SHIM_DIR}/MADFoundation")
	file(CREATE_LINK "${SOURCE_DIR}" "${SHIM_DIR}/MADFoundation" SYMBOLIC)
endif()

include(cmake/MADFoundationSources.cmake)

add_library(madfoundation STATIC
	${MADFOUNDATION_SOURCES}
	"${MAD_COMPAT_DIR}/NSOperation+Name.m")
target_include_directories(madfoundation PUBLIC "${SHIM_DIR}" PRIVATE "${MAD_COMPAT_DIR}")
target_compile_definitions(madfoundation PRIVATE $<$<CONFIG:Debug>:DEBUG=1>)
target_compile_options(madfoundation PRIVATE
	-Wall
	$<$<COMPILE_LANGUAGE:OBJC>:-fobjc-arc>
	${MAD_OBJC_PRELUDE})
target_link_libraries(madfoundation PUBLIC ${GNUSTEP_BASE_LIBS} -ldispatch)

enable_testing()

set(TESTING_INCLUDE "${GNUSTEP_MAKEFILES}/TestFramework")
if (NOT EXISTS "${TESTING_INCLUDE}/Testing.h")
	message(FATAL_ERROR "Testing.h not found under ${TESTING_INCLUDE}")
endif()

# One executable per ported MADFoundationTests file.  GNUstep's Testing.h is
# manual-retain-release, so the tests compile without ARC while the library
# stays ARC -- a per-translation-unit matter, not an ABI one.
function(mad_test name)
	add_executable(${name} "Tests/${name}.m")
	target_include_directories(${name} PRIVATE
		"${SHIM_DIR}" "${MAD_COMPAT_DIR}" "${TESTING_INCLUDE}" "${CMAKE_CURRENT_SOURCE_DIR}/Tests")
	target_compile_options(${name} PRIVATE
		-Wall
		$<$<COMPILE_LANGUAGE:OBJC>:-fno-objc-arc>
		${MAD_OBJC_PRELUDE})
	# WHOLE_ARCHIVE is Apple's -ObjC: the framework's categories
	# (NSData+Comparison, NSOperation+Advanced, the NSOperation name shim) and
	# any unreferenced class would otherwise be dropped from the static
	# archive before the runtime ever sees them.
	target_link_libraries(${name} PRIVATE "$<LINK_LIBRARY:WHOLE_ARCHIVE,madfoundation>")
	add_test(NAME ${name} COMMAND ${name})
endfunction()

# The probe is ARC (proving the ARC environment is the point) and links the
# library for its link-check block.  It is a report, not a unit test.
add_executable(ToolchainProbe Tests/ToolchainProbe.m)
target_include_directories(ToolchainProbe PRIVATE "${SHIM_DIR}" "${MAD_COMPAT_DIR}")
target_compile_options(ToolchainProbe PRIVATE
	-Wall
	$<$<COMPILE_LANGUAGE:OBJC>:-fobjc-arc>
	${MAD_OBJC_PRELUDE})
target_link_libraries(ToolchainProbe PRIVATE "$<LINK_LIBRARY:WHOLE_ARCHIVE,madfoundation>")
add_test(NAME ToolchainProbe COMMAND ToolchainProbe)

mad_test(MADProgressTests)
mad_test(MADStringUtilitiesTests)
mad_test(NSDataComparisonTests)
mad_test(MADDataTypeTests)
mad_test(MADBlockOperationTests)
mad_test(MADGroupOperationTests)
mad_test(MADOperationQueueTests)
mad_test(MADNotificationProgressTests)
mad_test(MADExclusivityControllerTests)
mad_test(MADOperationTests)
mad_test(MADOperationConditionTests)
mad_test(MADOperationConditionResultTests)
mad_test(MADDataColumnTests)
mad_test(MADCredentialTests)
