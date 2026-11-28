//
//  MADArchiveManager.m
//  MAD
//
//  Created by Michael Thomason on 6/24/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADArchiveManager.h"

#import <stdlib.h>
#import <string.h>
#import <stdio.h>
#if __APPLE__
#import <copyfile.h>
#else
#import <MADCompatFileCopy.h>
#endif
#import <unistd.h>
#import <fcntl.h>
#import <errno.h>
#import <libgen.h>
#import <MADFoundation/madlog.h>
#import <stdlib.h>

#import <Foundation/NSURL.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSData.h>
#import <Foundation/NSException.h>
#import <Foundation/NSFileWrapper.h>
#import <Foundation/NSUUID.h>
#import <Foundation/NSError.h>
#import <Foundation/NSBundle.h>

#import <MADFileManager/MADFileUtilities.h>
#import "MADConstants.h"
#import "MADPathUtilities.h"
#import "madtar.h"

size_t m_malloc(char **str, size_t len);
int backup_file(char *, char *);
int write_archive(char *, NSURL *, int);
int restore_backup(char *, char *, char *);
int mad_file_remove_if_exist(char *);
// Left over from an earlier path-handling pass: nothing calls these two, so they are
// parked as static and marked rather than left bare or deleted outright.
static int mad_path_is_absolute(const char *) __attribute__((unused));
static int mad_path_is_relative(const char *) __attribute__((unused));

int mad_file_remove_if_exist(char *path) { return (access(path, F_OK) == 0) ? remove(path) : -1; }
static int mad_path_is_absolute(const char *path) { return strlen(path) > 1 && path[0] == '/' ? 1 : 0; }
static int mad_path_is_relative(const char *path) { return mad_path_is_absolute(path) ? 0 : 1; }

// The v1 document header, per docs/project/MAD_FORMAT.md section 7.1: 8 magic bytes, two
// little-endian version words, then four flags bytes (bit 0 records whether the store
// was checkpointed).  It sits ahead of the bzip2 stream so a document is identified by
// content, not by its extension.  The minor word is 0 for an ordinary report and 1 for
// a composed one.
static NSData *MADFileFormatHeader(BOOL checkpointed, uint16_t minorVersion) {
	uint8_t bytes[MADFileFormatHeaderLength] = { 0 };
	memcpy(bytes, MADFileFormatMagic, 8);
	bytes[8]  = (uint8_t)(MADFileFormatMajorVersion & 0xFF);
	bytes[9]  = (uint8_t)((MADFileFormatMajorVersion >> 8) & 0xFF);
	bytes[10] = (uint8_t)(minorVersion & 0xFF);
	bytes[11] = (uint8_t)((minorVersion >> 8) & 0xFF);
	bytes[12] = (uint8_t)(checkpointed ? 1 : 0);
	return [NSData dataWithBytes: bytes length: sizeof(bytes)];
}

// Write the header, then the archive body, into `archivePath`.
static BOOL MADComposeV1Archive(const char *archivePath, const char *bodyPath, BOOL checkpointed, uint16_t minorVersion) {
	NSString *bodyFile = [NSString stringWithUTF8String: bodyPath];
	NSData *body = bodyFile ? [NSData dataWithContentsOfFile: bodyFile] : nil;
	if (body == nil) return NO;

	NSMutableData *composed = [NSMutableData dataWithData: MADFileFormatHeader(checkpointed, minorVersion)];
	[composed appendData: body];

	NSString *archiveFile = [NSString stringWithUTF8String: archivePath];
	return archiveFile ? [composed writeToFile: archiveFile atomically: NO] : NO;
}

// The versioned requirements record a composed document carries beside meta.plist,
// and the capabilities this build declares it supports.
static NSString * const MADRequirementsRecordName = @"requirements.plist";

/// Whether this build supports a required capability, keyed to the requirements
/// record names and consistent with `engine-info`.
static BOOL MADEngineSupportsCapability(NSString *capability) {
	return [capability isEqualToString: MADDocumentCapabilityQueryComposition];
}

size_t m_malloc(char **str, size_t len) {
	size_t result = len * sizeof(char);
	*str = (char *)malloc(result);
	if (*str == NULL && len > 0) {
		fprintf(stderr, "failed to allocate memory.\n");
		result = 0;
	}
	return result;
}

// Backup a file.
// 1. Change directory to the origional directory.
// 1. Does a previous backup exist exist?
// 2. If a previous backup exist, delete it.
// 3. Copy file to backup location... that is, create the backup.
int backup_file(char *path_origin, char *path_destination) {

	int r;
	// dirname(3) and basename(3) may modify their argument, and glibc's do: the
	// caller's path is used again after this returns, and a path truncated at its last
	// slash made the composed document write over its own directory -- measured on
	// Linux as "Open (/tmp/out) failed - Is a directory", and it cost a write that
	// Apple's implementations, which leave the buffer alone, never noticed (docs/project/registers/BUGS.md,
	// the .mad byte-identity entry).
	char *directory_copy = strdup(path_origin);
	char *name_copy = strdup(path_origin);
	char *path_origin_dirname = dirname(directory_copy);
	char *path_origin_basename = basename(name_copy);
	if ((r = chdir(path_origin_dirname)) < 0) {
		os_log_error(OS_LOG_DEFAULT, "Error: Change directory returned %d. Error (%d): %s", r, errno, strerror(errno));
	} else {
		// 1. Does a previous backup exist exist?
		if (access(path_destination, F_OK) < 0)
			os_log_info(OS_LOG_DEFAULT, "No backup file to delete (%d): %s\n\t%s)", errno, strerror(errno), path_destination);
		else
			// 2. If a previous backup exist, delete it.
			if (remove(path_destination) < 0)
				os_log_error(OS_LOG_DEFAULT, "Error removing file: %s\n\t%d: %s)", path_destination, errno, strerror(errno));
		
		// 3. Copy file to backup location... that is, create the backup.
#if __APPLE__
		if (copyfile(path_origin_basename, path_destination, NULL,
						  COPYFILE_SECURITY | COPYFILE_ALL | COPYFILE_COPY_DATA |
						  COPYFILE_COPY_XATTR) < 0)
#else
		// POSIX copyfile, single file (Compat/MADCompatFileCopy.h).
		if (MADCompatCopyFile(path_origin_basename, path_destination) < 0)
#endif
			os_log_error(OS_LOG_DEFAULT, "Error: Copyfile %s.\n\tGot %d: %s.\n\t\n\tStore is migration directory?", path_origin, errno, strerror(errno));
	}

	free(directory_copy);
	free(name_copy);

	return r;
}

// The old walk skipped hidden members (NSDirectoryEnumerationSkipsHiddenFiles) and
// this one keeps that: docs/project/MAD_FORMAT.md §6 H4 records that a hidden member is dropped
// silently, which is a hazard to be decided, not a behaviour to change by rewriting
// the walk.
static int mad_path_is_hidden(NSString *relativePath) {
	for (NSString *component in relativePath.pathComponents) {
		if ([component hasPrefix: @"."]) return 1;
	}
	return 0;
}

int write_archive(char *outname, NSURL *filewrapper, int reproducible) {
	int r = 0;
	struct archive *archive = archive_write_new();

	if ((r = archive_write_set_format_pax_restricted(archive)) != ARCHIVE_OK) {
		os_log_error(OS_LOG_DEFAULT, "Error: archive_write_set_format_pax_restricted() returned %d: %s.",
					 r, archive_error_string(archive) ?: "no error string");
		archive_write_free(archive);
		return r;
	}

	if ((r = archive_write_add_filter_bzip2(archive)) != ARCHIVE_OK) {
		os_log_error(OS_LOG_DEFAULT, "Error: archive_write_add_filter_bzip2() returned %d: %s.",
					 r, archive_error_string(archive) ?: "no error string");
		archive_write_free(archive);
		return r;
	}

	// A failed open leaves the archive in its new state.  Carrying on writes every
	// member into that state and fails every time; on Apple that error storm has
	// taken the caller down (a document save whose directory was removed while the
	// save was still pending).  Stop here and report the failure instead.
	if ((r = archive_write_open_filename(archive, outname)) != ARCHIVE_OK) {
		os_log_error(OS_LOG_DEFAULT, "Error: archive_write_open_filename() returned %d: %s.",
					 r, archive_error_string(archive) ?: "no error string");
		archive_write_free(archive);
		return r;
	}

	// The members are the files below the directory, named by their paths relative to
	// it, and they are read with -subpathsAtPath: rather than a URL enumerator:
	// GNUstep's -enumeratorAtURL: yields URLs with the containing directory stripped,
	// which is what used to send the old walk-up loop to "/" and never let it return
	// (docs/project/registers/BUGS.md, the byte-identity entry; Linux/README.md).
	NSString *basePath = filewrapper.path;
	NSMutableArray <NSString *> *relativePaths = [NSMutableArray array];
	for (NSString *relativePath in [[NSFileManager defaultManager] subpathsAtPath: basePath]) {
		if (!mad_path_is_hidden(relativePath)) {
			[relativePaths addObject: relativePath];
		}
	}

	// A reproducible archive walks its members in one order.  The enumerator's is the
	// filesystem's, and two filesystems do not have to agree on it.
	if (reproducible) {
		[relativePaths sortUsingSelector: @selector(compare:)];
	}

	int archive_status;
	for (NSString *relativePath in relativePaths) {
		NSString *absolutePath = [basePath stringByAppendingPathComponent: relativePath];

		// UTF8String, not -fileSystemRepresentation: GNUstep's NSString spelling
		// returns GSNativeChar (UTF-16) on Windows, which strdup would truncate at
		// the first NUL.  Windows-only; the Apple/Linux spelling is unchanged.
#if defined(_WIN32)
		char *source_filepath_fsr = strdup(absolutePath.UTF8String);
		char *source_path_relative_fsr = strdup(relativePath.UTF8String);
#else
		char *source_filepath_fsr = strdup(absolutePath.fileSystemRepresentation);
		char *source_path_relative_fsr = strdup(relativePath.fileSystemRepresentation);
#endif

		if ((archive_status = mad_archive_write_file(archive, source_filepath_fsr,
													 source_path_relative_fsr, reproducible)) < 0) {
			os_log_error(OS_LOG_DEFAULT, "Error %d in archive.", archive_status);
			r = archive_status;
			free(source_path_relative_fsr); free(source_filepath_fsr);
			break;
		}
		free(source_path_relative_fsr); free(source_filepath_fsr);
	}
	
	archive_write_close(archive);
	archive_write_free(archive);
	return r;
}

int restore_backup(char *origional_path, char *backup_path, char *backup_name) {
	int r = 0;
	if ((r = chdir(origional_path)) < 0) {
		os_log_error(OS_LOG_DEFAULT, "Error: Change directory returned %d. Error (%d): %s", r, errno, strerror(errno));
	} else {
		if ((r = access(backup_path, F_OK)) < 0) {
			os_log_error(OS_LOG_DEFAULT, "Can't access file that we want to backup.\n\t%s", backup_path);
		} else {
#if __APPLE__
			if ((r = copyfile(backup_path, backup_name, NULL,
							  COPYFILE_SECURITY | COPYFILE_ALL | COPYFILE_COPY_DATA |
							  COPYFILE_COPY_XATTR | COPYFILE_DATA)) < 0)
#else
			if ((r = MADCompatCopyFile(backup_path, backup_name)) < 0)
#endif
				os_log_error(OS_LOG_DEFAULT, "Copyfile %s error %d - %s", backup_name, errno, strerror(errno));
			
		}
	}

	return r;
}

@interface MADArchiveManager ()

	@property (nonatomic, copy) NSURL *filewrapper;
	@property (nonatomic, copy) NSURL *archive;

@end

@implementation MADArchiveManager

- (instancetype)initWithFileWrapperURL:(NSURL *)fileWrapper archiveURL:(NSURL *)archive {
	if (self = [super init]) {
		_filewrapper = fileWrapper.copy;
		_archive = archive.copy;
	}
	return self;
}

#pragma mark - Required capabilities

/// Writes the versioned requirements record into the guts directory, so the
/// archive walk carries it like any other member.
- (BOOL)writeRequirementsRecordWithError:(NSError * __autoreleasing *)error {
	NSDictionary *record = @{ @"format": @1,
							  @"requiredCapabilities": @[ MADDocumentCapabilityQueryComposition ] };
	NSURL *url = [self.filewrapper URLByAppendingPathComponent: MADRequirementsRecordName isDirectory: NO];
	return [record writeToURL: url atomically: YES];
}

/// Reads the requirements record a 1.1 container carries and checks every
/// required capability against this build.  A missing or malformed record, or an
/// unknown required capability, fills `error` with an actionable message.
- (BOOL)checkRequirementsWithError:(NSError * __autoreleasing *)error {
	NSURL *url = [self.filewrapper URLByAppendingPathComponent: MADRequirementsRecordName isDirectory: NO];
	NSDictionary *record = [NSDictionary dictionaryWithContentsOfURL: url];
	if (record == nil) {
		if (error != NULL) {
			*error = [NSError errorWithDomain: MADFileFormatErrorDomain code: 2 userInfo: @{
				NSLocalizedDescriptionKey:
					NSLocalizedString(@"This document requires capabilities this build cannot read (its requirements record is missing). Upgrade MAD Designer to open it.", @"Requirements record missing error.") }];
		}
		return NO;
	}
	NSArray *required = record[@"requiredCapabilities"];
	if (![required isKindOfClass:[NSArray class]]) {
		if (error != NULL) {
			*error = [NSError errorWithDomain: MADFileFormatErrorDomain code: 3 userInfo: @{
				NSLocalizedDescriptionKey:
					NSLocalizedString(@"This document's requirements record is malformed. Upgrade MAD Designer to open it.", @"Requirements record malformed error.") }];
		}
		return NO;
	}
	for (id capability in required) {
		if (![capability isKindOfClass:[NSString class]] ||
			!MADEngineSupportsCapability(capability)) {
			if (error != NULL) {
				*error = [NSError errorWithDomain: MADFileFormatErrorDomain code: 4 userInfo: @{
					NSLocalizedDescriptionKey: [[NSString alloc] initWithFormat:
						@"This document requires the %@ capability, which this version of MAD Designer does not support. Upgrade MAD Designer to open it.", capability] }];
			}
			return NO;
		}
	}
	return YES;
}

///
/// 1. Remove Backup
/// 2. Copy archive to backup location
/// 3. Restore backup on failure.
///

- (BOOL)archive:(BOOL)overwrite {

	BOOL success = NO;
	int r;

	//Change directory to the location to archive.
	char *origin_path = strdup(self.filewrapper.fileSystemRepresentation);
	char *archive_path = strdup(self.archive.fileSystemRepresentation);
	char *backup_path;
	size_t backup_size = m_malloc(&backup_path, strlen(archive_path) + 2);
	backup_path[0] = '\n';
	strlcpy(backup_path, archive_path, backup_size);
	strlcat(backup_path, "~", backup_size);
	
	// 1. Back up the current archive before overwriting it.  backup_file drops any
	// stale backup, then copies the archive beside it with a "~" suffix; a first save
	// has nothing to copy, so the backup simply does not exist yet.
	if ((r = backup_file(archive_path, backup_path)) < 0) {
		os_log_error(OS_LOG_DEFAULT, "Failed to backup file with %d.", r);
	}

	// A composed document carries a requirements record and a 1.1 header; an
	// ordinary one is 1.0 with no record.  The record is a regular member of the
	// guts directory, so write it before the archive walk.  A failure here must
	// abort the save -- not fall through to the archive walk, which would overwrite
	// `r` and hide it.
	BOOL requirementsWritten = !self.composed || [self writeRequirementsRecordWithError: NULL];
	if (!requirementsWritten) {
		r = -1;
		os_log_error(OS_LOG_DEFAULT, "Failed to write the requirements record.");
	} else {
		// 2. Write the archive body to a sibling temp file, then compose the v1 header
		// and the body into the document URL.  libarchive opens its own output, so the
		// header cannot simply be written first and have libarchive append to it.
		char *body_path;
		size_t body_size = m_malloc(&body_path, strlen(archive_path) + 5);
		strlcpy(body_path, archive_path, body_size);
		strlcat(body_path, ".tmp", body_size);

		uint16_t minorVersion = self.composed ? MADFileFormatCompositionMinorVersion : MADFileFormatMinorVersion;
		if ((r = write_archive(body_path, self.filewrapper, self.reproducible)) < 0) {
			os_log_error(OS_LOG_DEFAULT, "Failed to archive file with %d.", r);
		} else if (!MADComposeV1Archive(archive_path, body_path, self.checkpointed, minorVersion)) {
			r = -1;
			os_log_error(OS_LOG_DEFAULT, "Failed to write the document header.");
		}
		mad_file_remove_if_exist(body_path);
		free(body_path);
	}

	success = r == ARCHIVE_OK;

	// 3. Put the previous archive back on failure.  access() answers 0 when the file
	// is present, which is what guards the restore -- a first save has no backup, and
	// a stale backup must not be restored.  On success the backup is dropped instead.
	if (!success && access(backup_path, F_OK) == 0) {
		if (restore_backup(origin_path, backup_path, archive_path) < 0) {
			os_log_error(OS_LOG_DEFAULT, "Error in restore_backup.");
		}
	}
	mad_file_remove_if_exist(backup_path);

	free(archive_path);
	free(origin_path);
	free(backup_path);

	if (!success) os_log_error(OS_LOG_DEFAULT, "Failed to write archive.");

	return success;
}

- (BOOL)unarchive {
	return [self unarchiveWithError: NULL];
}

- (BOOL)unarchiveWithError:(NSError * __autoreleasing *)error {
	// Refuse a newer container before any extraction.  A v0 document has no
	// header and is accepted; a 1.x newer than this build is not.
	NSData *header = [NSData dataWithContentsOfURL: self.archive
										   options: NSDataReadingMappedIfSafe
											 error: NULL];
	if (header != nil && !MADFileFormatHeaderIsSupported(header.bytes, header.length, error)) {
		return NO;
	}

	// A v1 document carries the 16-byte header ahead of the bzip2 stream; libarchive
	// does not know about it, so hand the extractors a headerless copy when one is
	// present.  A v0 document has no header and is extracted as-is.
	NSURL *stripped = [self strippedArchiveURL];
	NSURL *source = stripped ?: self.archive;

	int success = 0;
	@autoreleasepool {
		success = [self unarchiveV8FromURL: source];
	}

	if (success != 0) {
		@autoreleasepool {
			success = [self unarchiveLegacyFromURL: source];
		}
	}

	if (stripped) {
		[[NSFileManager defaultManager] removeItemAtURL: stripped error: NULL];
	}
	if (success != 0) return NO;

	// A 1.1 container is composed and must declare its required capabilities; check
	// them before the store is opened, so an unsupported document is refused with the
	// file untouched.
	if ([self containerMinorVersion] == MADFileFormatCompositionMinorVersion) {
		return [self checkRequirementsWithError: error];
	}
	return YES;
}

/// The header's minor version word, or 0 for a v0 / headerless document.
- (uint16_t)containerMinorVersion {
	NSData *data = [NSData dataWithContentsOfURL: self.archive
										 options: NSDataReadingMappedIfSafe
										   error: NULL];
	if (data.length < MADFileFormatHeaderLength) return 0;
	if (memcmp(data.bytes, MADFileFormatMagic, 8) != 0) return 0;
	return (uint16_t)(((const uint8_t *)data.bytes)[10] | (((const uint8_t *)data.bytes)[11] << 8));
}

// Returns nil for a v0 document (no header), or a temporary headerless copy for a
// v1 document, so the extractor sees a plain bzip2 tar.
- (NSURL *)strippedArchiveURL {
	NSData *data = [NSData dataWithContentsOfURL: self.archive
										options: NSDataReadingMappedIfSafe
										  error: NULL];
	if (data.length < MADFileFormatHeaderLength) return nil;
	if (memcmp(data.bytes, MADFileFormatMagic, 8) != 0) return nil;

	NSData *body = [data subdataWithRange: NSMakeRange(MADFileFormatHeaderLength, data.length - MADFileFormatHeaderLength)];
	NSURL *stripped = [NSURL fileURLWithPath:
		[NSTemporaryDirectory() stringByAppendingPathComponent:
			[NSString stringWithFormat: @"mad-stripped-%@.tar.bz2", NSUUID.UUID.UUIDString]]];
	if (![body writeToURL: stripped atomically: YES]) return nil;
	return stripped;
}

- (int)unarchiveV8FromURL:(NSURL *)sourceArchive {
	__block int success = 0;
	int r;
	BOOL isDirectory, fileExist;

	NSString *destinationPath = _filewrapper.path;
	NSString *destinationLastPathComponent = _filewrapper.lastPathComponent;
	NSURL *destinationURL = _filewrapper.URLByDeletingLastPathComponent.copy;

	NSError * __autoreleasing errorCreate = nil;
	[MADFileUtilities deleteCoreDataFilesAtDirectory: _filewrapper withCoordinator:NO];
	
	fileExist = [[NSFileManager defaultManager] fileExistsAtPath: destinationPath
													 isDirectory: &isDirectory];

	if (!fileExist || !isDirectory) {
		BOOL successCreate, sucessExist;
		successCreate = [[NSFileManager defaultManager] createDirectoryAtPath: destinationPath
												  withIntermediateDirectories: YES
																   attributes: nil
																		error: &errorCreate];
		if (successCreate) {
			sucessExist = [[NSFileManager defaultManager] fileExistsAtPath: destinationPath
															   isDirectory: &isDirectory];
		} else {
			sucessExist = NO;
		}
		
		if (!sucessExist) success = -1;
	}
	if (success >= 0) {
		
		if (((r = chdir(destinationURL.fileSystemRepresentation))) != 0) {
			os_log_error(OS_LOG_DEFAULT, "Error %d: %s. Chdir (%s) failed.", errno, strerror(errno), destinationURL.fileSystemRepresentation);
			success = -1;
		} else {
			char *source = 0, *dest = 0, *filename = 0;
			dest = strdup(destinationURL.fileSystemRepresentation);
			// UTF8String, not -fileSystemRepresentation (GNUstep NSString returns
			// UTF-16 on Windows); see the note at write_archive.
#if defined(_WIN32)
			filename = strdup(destinationLastPathComponent.UTF8String);
#else
			filename = strdup(destinationLastPathComponent.fileSystemRepresentation);
#endif
			source = strdup(sourceArchive.fileSystemRepresentation);
			success = mad_extract(source, dest, filename);
			if (dest != 0) free(dest);
			if (filename != 0) free(filename);
			if (source != 0) free(source);
		}
	}
	return success;
}

- (int)unarchiveLegacyFromURL:(NSURL *)sourceArchive {
	int success = 0;
	//Test to see if it's it's not a compressed  archive
	NSError * __autoreleasing errorReading = NULL;
	NSData *data = [[NSData alloc] initWithContentsOfURL: sourceArchive
												 options: NSDataReadingUncached
												   error: &errorReading];
	if (errorReading != nil) {
		os_log_error(OS_LOG_DEFAULT, "Error: %s.", errorReading.localizedDescription.UTF8String);
		success = -2;
	}
	
	if (success == 0) {
		NSFileWrapper *fileWrapper = [[NSFileWrapper alloc] initWithSerializedRepresentation:data];
		
		NSError *errorWriting = NULL;
		success = [fileWrapper writeToURL: _filewrapper
								  options: NSFileWrapperWritingAtomic
					  originalContentsURL: _archive
									error: &errorWriting] ? 0 : -1;
		
		if (success < 0 && errorWriting != nil) {
			os_log_error(OS_LOG_DEFAULT, "Error: %s.", errorWriting.localizedDescription.UTF8String);
		}
		NSAssert(success >= 0, @"Failed to write at %s.", __PRETTY_FUNCTION__);
	}
	return success;
}

@end
