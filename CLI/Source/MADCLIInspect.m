//
//  MADCLIInspect.m
//  MAD Designer
//
//  `mad inspect` -- reads the container only.  No database connection, no Core Data
//  context; the store is read as bytes and as SQLite, which is what MAD_FORMAT.md
//  section 7 asks a reader on another platform to be able to do.
//

#import "MADCLI.h"
#import "MADCLIContainer.h"

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
	if (!header.present) {
		[out appendFormat: @"  store       NOT A SQLITE DATABASE\n"];
	} else {
		[out appendFormat: @"  store       StoreContent/analyitics (SQLite %@, %u pages, %u-byte pages)\n",
			MADCLISQLiteVersionString(header.sqliteVersion), header.pageCount, header.pageSize];
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

	// Counts come straight out of the store's own tables.  This is the part of the
	// format MAD_FORMAT.md section 8.1 calls tied to Core Data, so it is the part
	// most likely to need revisiting; the rest of this verb does not depend on it.
	unsigned long long sections = 0, elements = 0;
	BOOL gotSections = MADCLICountRows(container.storeURL, @"ZRPTQDOCUMENTSECTION", &sections);
	BOOL gotElements = MADCLICountRows(container.storeURL, @"ZRPTQDOCUMENTELEMENT", &elements);
	if (gotSections && gotElements) {
		[out appendFormat: @"  elements    %llu sections, %llu elements\n", sections, elements];
	}

	fputs(out.UTF8String, stdout);
	[container discard];
	return MADCLIExitSuccess;
}
