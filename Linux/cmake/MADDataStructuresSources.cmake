# The MADDataStructures subset the Linux build compiles (MAD_LINUX.md §9):
# all 15 implementation files of the Xcode target, plus its two Objective-C++
# files, which is every file the target builds.
#
# Excluded, with reasons:
#   madmap.cpp   not in the Xcode target's Sources phase either -- a stray
#                template definition madmap.hpp (empty) never exposes; the
#                map wrappers MADMapStrings.mm defines their own
#   MADDataStructures.h  the umbrella, as on MADFoundation: its headers are
#                reached directly here
#
# MADVectorBool.mm must compile without ARC -- the file says so itself
# (#error), and the Xcode target carries the per-file -fno-objc-arc flag;
# mad_add_framework applies the same flag to it below.

set(MADDATASTRUCTURES_SOURCES
	"${SOURCE_DIR}/MADAlgorithmElementProperties.m"
	"${SOURCE_DIR}/MADBfsProperties.m"
	"${SOURCE_DIR}/MADDfsProperties.m"
	"${SOURCE_DIR}/MADIndex.m"
	"${SOURCE_DIR}/MADSortProperties.m"
	"${SOURCE_DIR}/MTEdge.m"
	"${SOURCE_DIR}/MTGraph.m"
	"${SOURCE_DIR}/MTLinkedList.m"
	"${SOURCE_DIR}/MTLinkedListNode.m"
	"${SOURCE_DIR}/MTObject.m"
	"${SOURCE_DIR}/MTPair.m"
	"${SOURCE_DIR}/MTQueue.m"
	"${SOURCE_DIR}/MTStack.m"
	"${SOURCE_DIR}/MTTree.m"
	"${SOURCE_DIR}/MTVertex.m"

	# Objective-C++ (needs libc++ and the OBJCXX language enabled)
	"${SOURCE_DIR}/MADMapStrings.mm"
	"${SOURCE_DIR}/MADVectorBool.mm"
)
