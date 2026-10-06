#
#  MADLinuxFramework.cmake -- the one recipe for putting a MAD framework into
#  the Linux build (Linux/AGENTS.md has the step-by-step).
#
#  MADFoundation is the only framework here today; every function below is the
#  shape its build actually uses, not a speculative generalization.  Adding a
#  framework means: a source list in cmake/ with per-file exclusion reasons, a
#  shim, one mad_add_framework call, and its tests.
#
#  The variables this relies on come from Linux/CMakeLists.txt: SHIM_DIR,
#  MAD_COMPAT_DIR, MAD_OBJC_PRELUDE, GNUSTEP_BASE_LIBS and TESTING_INCLUDE.
#

# mad_make_include_shim(<Framework> <source-dir>)
# The framework imports itself as <Framework/Foo.h>; a symlinked directory of
# that name on the include path satisfies it without a source edit.
function(mad_make_include_shim framework source_dir)
	if (NOT EXISTS "${SHIM_DIR}/${framework}")
		file(CREATE_LINK "${source_dir}" "${SHIM_DIR}/${framework}" SYMBOLIC)
	endif()
endfunction()

# mad_add_framework(<library-target> <sources-variable> [<test> ...])
# Builds the framework's source list (plus the compat prelude's shim) as a
# static library, ARC on, whole-archive at the test link so categories survive,
# and registers each named test file with ctest.  A framework with C++ files
# (MADDataStructures) puts them in the source list as .mm; the language is
# enabled in Linux/CMakeLists.txt, and a file that must not be ARC (the
# framework says so itself) is given -fno-objc-arc with
# set_source_files_properties beside its mad_add_framework call.
function(mad_add_framework library sources_var)
	add_library(${library} STATIC
		${${sources_var}}
		${MAD_COMPAT_SOURCES})
	target_include_directories(${library} PUBLIC "${SHIM_DIR}" PRIVATE "${MAD_COMPAT_DIR}")
	target_compile_definitions(${library} PRIVATE $<$<CONFIG:Debug>:DEBUG=1>)
	target_compile_options(${library} PRIVATE
		-Wall
		$<$<COMPILE_LANGUAGE:OBJC,OBJCXX>:-fobjc-arc>
		${MAD_OBJC_PRELUDE})
	target_link_libraries(${library} PUBLIC ${GNUSTEP_BASE_LIBS} -ldispatch)

	foreach (test IN LISTS ARGN)
		mad_add_test(${test} ${library})
	endforeach()
endfunction()

# mad_add_test(<name> <library-target>)
# One executable per ported test file.  GNUstep's Testing.h is
# manual-retain-release, so the tests compile without ARC while the library
# stays ARC -- a per-translation-unit matter, not an ABI one.  WHOLE_ARCHIVE is
# Apple's -ObjC: the framework's categories (NSData+Comparison,
# NSOperation+Advanced, the NSOperation name shim) and any unreferenced class
# would otherwise be dropped from the static archive before the runtime sees
# them.
function(mad_add_test name library)
	add_executable(${name} "Tests/${name}.m")
	target_include_directories(${name} PRIVATE
		"${SHIM_DIR}" "${MAD_COMPAT_DIR}" "${TESTING_INCLUDE}"
		"${CMAKE_CURRENT_SOURCE_DIR}/Tests/Support")
	target_compile_options(${name} PRIVATE
		-Wall
		$<$<COMPILE_LANGUAGE:OBJC>:-fno-objc-arc>
		${MAD_OBJC_PRELUDE})
	target_link_libraries(${name} PRIVATE "$<LINK_LIBRARY:WHOLE_ARCHIVE,${library}>")
	add_test(NAME ${name} COMMAND ${name})
endfunction()
