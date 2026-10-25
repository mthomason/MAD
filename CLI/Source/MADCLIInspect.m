//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADCLIInspect.m
//  MAD Designer
//
//  `mad inspect` -- reads the container only.  No database connection, no Core Data
//  context; the store is read as bytes and as SQLite, which is what docs/project/MAD_FORMAT.md
//  section 7 asks a reader on another platform to be able to do.
//

#import "MADCLI.h"
#import "MADCLIContainer.h"

#import <MADFoundation/MADURLFactory.h>

#import <sqlite3.h>

static BOOL MADCLICountRows(NSURL *storeURL, NSString *table, unsigned long long *count) {
	sqlite3 *database = NULL;
	if (sqlite3_open_v2(storeURL.path.fileSystemRepresentation, &database,
						SQLITE_OPEN_READONLY, NULL) != SQLITE_OK) {
		if (database) sqlite3_close(database);
		return NO;
	}

	NSString *sql = [NSString stringWithFormat: @"SELECT COUNT(*) FROM %@", table];
	sqlite3_stmt *statement = NULL;
	BOOL ok = NO;
	if (sqlite3_prepare_v2(database, sql.UTF8String, -1, &statement, NULL) == SQLITE_OK) {
		if (sqlite3_step(statement) == SQLITE_ROW) {
			*count = (unsigned long long)sqlite3_column_int64(statement, 0);
			ok = YES;
		}
	}
	sqlite3_finalize(statement);
	sqlite3_close(database);
	return ok;
}

static NSString *MADCLIHumanBytes(unsigned long long bytes) {
	if (bytes < 1024) return [NSString stringWithFormat: @"%llu bytes", bytes];
	if (bytes < 1024 * 1024) return [NSString stringWithFormat: @"%.1f KB", bytes / 1024.0];
	return [NSString stringWithFormat: @"%.1f MB", bytes / (1024.0 * 1024.0)];
}

/// The companion files, grouped by extension.  These are the document's on-disk
/// footprint, regenerated on refresh and deliberately outside the archive --
/// docs/project/MAD_FORMAT.md section 5.  The three kinds are three extensions: .maddb (row
/// data), .mdcache (the virtual-table index) and .madac (the rendered-page cache).
static void MADCLIAppendCacheSummary(NSMutableString *out, NSURL *documentURL, BOOL verbose) {

	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *filename = documentURL.lastPathComponent.stringByDeletingPathExtension;
	NSURL *cacheDirectory = [MADURLFactory newURLCacheFilesDirectoryForFilename: filename];

	BOOL isDirectory = NO;
	if (![fileManager fileExistsAtPath: cacheDirectory.path isDirectory: &isDirectory] || !isDirectory) {
		[out appendString: @"  cache       none (the document has not been refreshed here)\n"];
		return;
	}

	NSArray <NSURL *> *files = [fileManager contentsOfDirectoryAtURL: cacheDirectory
										  includingPropertiesForKeys: @[NSURLIsDirectoryKey]
															 options: NSDirectoryEnumerationSkipsHiddenFiles
															   error: NULL];

	// The cache directory is flat in practice; a subdirectory is a manual artifact
	// (a user-made backup), not part of the document's own footprint, so it is left
	// out of the summary rather than reported as a zero-size file.
	NSMutableArray <NSURL *> *regularFiles = [NSMutableArray array];
	for (NSURL *file in files) {
		NSNumber *isDirectory = nil;
		[file getResourceValue: &isDirectory forKey: NSURLIsDirectoryKey error: NULL];
		if (!isDirectory.boolValue) [regularFiles addObject: file];
	}
	files = regularFiles;

	NSMutableDictionary <NSString *, NSMutableArray <NSURL *> *> *byExtension = [NSMutableDictionary dictionary];
	for (NSURL *file in files) {
		NSString *extension = file.pathExtension.length > 0 ? file.pathExtension : @"(none)";
		NSMutableArray <NSURL *> *group = byExtension[extension];
		if (group == nil) {
			group = [NSMutableArray array];
			byExtension[extension] = group;
		}
		[group addObject: file];
	}

	unsigned long long total = 0;
	for (NSArray <NSURL *> *group in byExtension.allValues) {
		for (NSURL *file in group) {
			total += [[fileManager attributesOfItemAtPath: file.path error: NULL][NSFileSize] unsignedLongLongValue];
		}
	}

	[out appendFormat: @"  cache       %@ (%lu files, %@)\n",
		cacheDirectory.lastPathComponent, (unsigned long)files.count, MADCLIHumanBytes(total)];

	for (NSString *extension in [byExtension.allKeys sortedArrayUsingSelector: @selector(compare:)]) {
		NSArray <NSURL *> *group = byExtension[extension];

		unsigned long long size = 0;
		for (NSURL *file in group) {
			size += [[fileManager attributesOfItemAtPath: file.path error: NULL][NSFileSize] unsignedLongLongValue];
		}

		NSString *kind;
		if ([extension isEqualToString: @"maddb"]) kind = @"row data";
		else if ([extension isEqualToString: @"mdcache"]) kind = @"virtual-table index";
		else if ([extension isEqualToString: @"madac"]) kind = @"rendered-page cache";
		else kind = @"";

		[out appendFormat: @"    %-10@ %lu file%@  %@  %@\n",
			extension, (unsigned long)group.count, group.count == 1 ? @" " : @"s", MADCLIHumanBytes(size), kind];

		if (verbose) {
			for (NSURL *file in group) {
				unsigned long long fileSize =
					[[fileManager attributesOfItemAtPath: file.path error: NULL][NSFileSize] unsignedLongLongValue];
				[out appendFormat: @"      %@  %@\n", file.lastPathComponent, MADCLIHumanBytes(fileSize)];
			}
		}
	}
}

MADCLIExitCode MADCLIRunInspect(MADCLIInvocation *invocation) {

	NSError *error = nil;
	MADCLIContainer *container = [MADCLIContainer containerWithContentsOfURL: invocation.documentURL error: &error];
	if (container == nil) {
		MADCLIError(@"%@", MADCLIDescriptionForError(error));
		return error.code == MADCLIExitBadDocument ? MADCLIExitBadDocument : MADCLIExitUsage;
	}

	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSMutableString *out = [NSMutableString string];
	[out appendFormat: @"%@\n", invocation.documentURL.lastPathComponent];

	if (container.formatVersion == MADCLIFormatVersion0) {
		[out appendFormat: @"  format      v0 (bzip2 tar, no magic header)\n"];
	} else {
		[out appendFormat: @"  format      v%u (MADFILE header, %u flags)\n",
			(unsigned)container.formatVersion, (unsigned)container.formatFlags];
	}

	[out appendFormat: @"  members     %lu\n", (unsigned long)container.memberPaths.count];
	for (NSString *path in container.memberPaths) {
		[out appendFormat: @"                %@\n", path];
	}

	NSDictionary *meta = container.meta;
	[out appendFormat: @"  generator   %@\n", meta[@"generator"] ?: @"(none)"];
	[out appendFormat: @"  version     %@\n", meta[@"version"] ?: @"(none)"];
	if (meta[@"checkpointed"]) {
		[out appendFormat: @"  checkpoint  %@\n", meta[@"checkpointed"]];
	}

	MADCLISQLiteHeader header = [container storeHeader];
	if (container.storeURL == nil) {
		[out appendFormat: @"  store       none\n"];
	} else if (!header.present) {
		[out appendFormat: @"  store       NOT A SQLITE DATABASE\n"];
	} else {
		[out appendFormat: @"  store       %@ (SQLite %@, %u pages, %u-byte pages, %@)\n",
			[NSString stringWithFormat: @"StoreContent/%@", container.storeURL.lastPathComponent],
			MADCLISQLiteVersionString(header.sqliteVersion), header.pageCount, header.pageSize,
			container.storeKind == MADCLIContainerStoreKindPortable ? @"portable" : @"legacy Core Data"];
	}

	NSURL *wal = container.walURL;
	NSURL *shm = container.shmURL;
	if (wal) {
		NSDictionary *attributes = [fileManager attributesOfItemAtPath: wal.path error: NULL];
		unsigned long long size = [attributes[NSFileSize] unsignedLongLongValue];
		[out appendFormat: @"  wal         present, %@ (not checkpointed)\n", MADCLIHumanBytes(size)];
	} else {
		[out appendFormat: @"  wal         none\n"];
	}
	if (shm) {
		NSDictionary *attributes = [fileManager attributesOfItemAtPath: shm.path error: NULL];
		[out appendFormat: @"  shm         present, %@\n",
			MADCLIHumanBytes([attributes[NSFileSize] unsignedLongLongValue])];
	}

	NSURL *thumbnail = [container.additionalContentURL URLByAppendingPathComponent: @"thumbnail@2x.png"];
	[out appendFormat: @"  thumbnail   %@\n",
		[fileManager fileExistsAtPath: thumbnail.path] ? @"present" : @"none"];

	// Counts come straight out of the store's own tables, whose names say which store
	// it is: a legacy Core Data document writes them Z-prefixed, the portable store
	// (docs/project/MAD_STORE_MIGRATION.md) uses the entity names as they are.
	BOOL portable = container.storeKind == MADCLIContainerStoreKindPortable;
	unsigned long long sections = 0, elements = 0;
	BOOL gotSections = MADCLICountRows(container.storeURL, portable ? @"RptqDocumentSection" : @"ZRPTQDOCUMENTSECTION", &sections);
	BOOL gotElements = MADCLICountRows(container.storeURL, portable ? @"RptqDocumentElement" : @"ZRPTQDOCUMENTELEMENT", &elements);
	if (gotSections && gotElements) {
		[out appendFormat: @"  elements    %llu sections, %llu elements\n", sections, elements];
	}

	MADCLIAppendCacheSummary(out, invocation.documentURL, invocation.verbose);

	fputs(out.UTF8String, stdout);
	[container discard];
	return MADCLIExitSuccess;
}
