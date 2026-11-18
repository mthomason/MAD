# Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

# The MADFileManager subset the Linux build compiles (docs/project/MAD_LINUX.md §9): 10 of
# the framework's 11 implementation files.
#
# The one excluded file and why:
#   MADCloudFileCoordinator.m  the iCloud coordinator: NSMetadataQuery over
#                        ubiquitous scopes.  §4 excludes it -- iCloud is
#                        deleted with the store migration's Phase D -- and
#                        MADFileCoordinator's cloud factory arm throws off
#                        Apple instead of building one.
#
# MADDirectoryMonitor.m comes over with an inotify branch in place of the
# Darwin vnode source: MADLocalFileCoordinator instantiates it, so excluding
# it would have meant guarding its only caller too.  MADMetaDataCloud.m comes
# over as well (the coordinator was its only producer): it is an inert wrapper
# over an NSMetadataItem, and its suite covers the nil-item shape.  The file
# manager's ubiquity calls compile through Compat/NSFileManager+Ubiquity.h,
# whose answers are all "no iCloud"; the cloud paths then take their local
# branches.  MADMetaDataLocal's contentType has no UTI database to consult off
# Apple and answers nil.  Keep this list in step with docs/project/MAD_LINUX.md §4.

set(MADFILEMANAGER_SOURCES
	"${SOURCE_DIR}/MADFileCoordinator.m"
	"${SOURCE_DIR}/MADLocalFileCoordinator.m"
	"${SOURCE_DIR}/MADDirectoryMonitor.m"
	"${SOURCE_DIR}/MADFileUtilities.m"
	"${SOURCE_DIR}/MADFilesController.m"
	"${SOURCE_DIR}/MADFileInfo.m"
	"${SOURCE_DIR}/MADMetaData.m"
	"${SOURCE_DIR}/MADMetaDataLocal.m"
	"${SOURCE_DIR}/MADMetaDataCloud.m"
	"${SOURCE_DIR}/MADStorageState.m"
)
