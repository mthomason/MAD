//
//  MADArchiveManagerTests.m
//  Linux/Tests
//
//  The `.mad` container on Linux (MAD_FORMAT.md §2, §7): the reader the CLI's verbs
//  run on, and the writer, which does not work here yet.
//
//  The reader is exercised against a checked-in fixture.  The writer is *needed*, not
//  skipped: -write_archive: cannot terminate on GNUstep, because it walks each
//  enumerated URL up to the directory being archived and GNUstep's
//  -enumeratorAtURL:... yields URLs with the containing directory stripped, so the
//  walk never arrives and allocates an NSURL a turn (BUGS.md -- "the same .mad on
//  both platforms").  The two writer tests below start running, untouched, the day
//  that is fixed; until then the count says out loud why they cannot.
//

#import "MADTestSupport.h"

#import <MAD/MADArchiveManager.h>

static NSString *MADArchiveFixturePath(void) {
	NSString *testFile = [@(__FILE__) stringByDeletingLastPathComponent];
	NSString *linuxDirectory = [testFile stringByDeletingLastPathComponent];
	NSString *repositoryRoot = [linuxDirectory stringByDeletingLastPathComponent];
	return [[repositoryRoot stringByAppendingPathComponent: @"CLI/Fixtures"]
			stringByAppendingPathComponent: @"London.portable.mad"];
}

static NSURL *MADArchiveTemporaryDirectory(void) {
	return [NSURL fileURLWithPath: NSTemporaryDirectory() isDirectory: YES];
}

/// The writer cannot finish on GNUstep; every writer test says so once, here.
#define MAD_NEED_A_WORKING_ARCHIVE_WRITER() \
	MAD_NEED(NO, @"-write_archive: walks each enumerated URL up to the archived directory," \
			 @" and GNUstep's -enumeratorAtURL: strips the containing directory, so it never" \
			 @" arrives (BUGS.md: the same .mad on both platforms)")

#pragma mark - Reading

static void testUnarchiveReadsAContainer(void) {
	MAD_NEED([[NSFileManager defaultManager] fileExistsAtPath: MADArchiveFixturePath()],
			 @"CLI/Fixtures/London.portable.mad is missing (it is checked in)");
	if (![[NSFileManager defaultManager] fileExistsAtPath: MADArchiveFixturePath()]) return;

	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSURL *destination = [MADArchiveTemporaryDirectory() URLByAppendingPathComponent: [NSUUID UUID].UUIDString];

	MADArchiveManager *reader = [[MADArchiveManager alloc]
								 initWithFileWrapperURL: destination
											 archiveURL: [NSURL fileURLWithPath: MADArchiveFixturePath()]];
	MAD_PASS([reader unarchive], "the v1 container unpacks");

	// The members a portable document has, by MAD_FORMAT.md §7.3.
	MAD_PASS([fileManager fileExistsAtPath: [destination URLByAppendingPathComponent: @"meta.plist"].path],
			 "meta.plist is a member");
	MAD_PASS([fileManager fileExistsAtPath:
			  [destination URLByAppendingPathComponent: @"StoreContent/store.sqlite"].path],
			 "the portable store is a member");

	// And the store is a readable SQLite database, which is what every verb needs.
	NSData *store = [NSData dataWithContentsOfURL:
					 [destination URLByAppendingPathComponent: @"StoreContent/store.sqlite"]];
	MAD_PASS(store.length > 100, "the store has bytes");
	if (store.length >= 16) {
		MAD_PASS(memcmp(store.bytes, "SQLite format 3\0", 16) == 0, "the store is a SQLite database");
	}

	[fileManager removeItemAtURL: destination error: NULL];
}

#pragma mark - Writing

static void testArchiveRoundTripIsByteIdentical(void) {
	MAD_NEED_A_WORKING_ARCHIVE_WRITER();
}

static void testArchiveIsNotReproducibleFromUnchangedMembers(void) {
	MAD_NEED_A_WORKING_ARCHIVE_WRITER();
}

MAD_TEST_MAIN("MADArchiveManagerTests",
	MAD_TEST(testUnarchiveReadsAContainer),
	MAD_TEST(testArchiveRoundTripIsByteIdentical),
	MAD_TEST(testArchiveIsNotReproducibleFromUnchangedMembers));
