//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADArchiveManagerTests.m
//  Linux/Tests
//
//  The `.mad` container on Linux (MAD_FORMAT.md §2, §7): the reader the CLI's verbs
//  run on, and the writer, which works here since 2026-10-16 -- -write_archive: walks
//  the directory with -subpathsAtPath: rather than the URL enumerator GNUstep strips
//  the containing directory from (BUGS.md -- "the same .mad on both platforms").
//
//  The writer is pinned three ways: the round trip (unpack, repack, unpack again, and
//  every member's bytes are unchanged -- MAD_CLI.md §6.1), the ordinary mode's
//  characterisation (two writes of a changed directory differ, because the metadata
//  is the filesystem's), and the reproducible mode (two writes are equal, and equal
//  to the Mac's bytes for the same document -- the user's byte-identity requirement).
//

#import "MADTestSupport.h"

#import <MAD/MADArchiveManager.h>
#import <MAD/MADConstants.h>
#import <MAD/MADHeadlessDocument.h>
#import <MAD/MADStore.h>

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

static NSURL *MADArchiveTemporaryURL(NSString *name) {
	NSURL *directory = [MADArchiveTemporaryDirectory() URLByAppendingPathComponent: [NSUUID UUID].UUIDString];
	[[NSFileManager defaultManager] createDirectoryAtURL: directory
							 withIntermediateDirectories: YES
											  attributes: nil
												   error: NULL];
	return [directory URLByAppendingPathComponent: name];
}

/// Unpacks the fixture into a fresh directory and answers it, or nil.
static NSURL *MADArchiveUnpackedFixture(void) {
	NSURL *destination = MADArchiveTemporaryURL(@"unpacked");
	MADArchiveManager *reader = [[MADArchiveManager alloc] initWithFileWrapperURL: destination
																	   archiveURL: [NSURL fileURLWithPath: MADArchiveFixturePath()]];
	if (![reader unarchive]) return nil;
	return destination;
}

/// Every file under `directory`, by relative path, with its bytes.
static NSDictionary <NSString *, NSData *> *MADArchiveMembersAtURL(NSURL *directory) {
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSMutableDictionary <NSString *, NSData *> *members = [NSMutableDictionary dictionary];
	for (NSString *relativePath in [fileManager subpathsAtPath: directory.path]) {
		NSString *absolute = [directory.path stringByAppendingPathComponent: relativePath];
		BOOL isDirectory = NO;
		[fileManager fileExistsAtPath: absolute isDirectory: &isDirectory];
		if (isDirectory) continue;
		NSData *contents = [NSData dataWithContentsOfFile: absolute];
		if (contents != nil) members[relativePath] = contents;
	}
	return members;
}

/// FNV-1a, 64 bit: the whole file's bytes in one number, so a byte that differs
/// between GNUstep and Apple -- a header field, a tar field, a compression choice --
/// fails here rather than going unnoticed.  The constant is the Mac's `mad write
/// --reproducible` output for the same document (Linux/README.md).
static uint64_t MADArchiveChecksum(NSData *data) {
	uint64_t hash = 14695981039346656037ULL;
	const uint8_t *bytes = data.bytes;
	for (NSUInteger index = 0; index < data.length; index++) {
		hash ^= (uint64_t)bytes[index];
		hash *= 1099511628211ULL;
	}
	return hash;
}

#pragma mark - Reading

static void testUnarchiveReadsAContainer(void) {
	MAD_NEED([[NSFileManager defaultManager] fileExistsAtPath: MADArchiveFixturePath()],
			 @"CLI/Fixtures/London.portable.mad is missing (it is checked in)");
	if (![[NSFileManager defaultManager] fileExistsAtPath: MADArchiveFixturePath()]) return;

	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSURL *destination = MADArchiveTemporaryURL(@"unpacked");

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

/// MAD_CLI.md §6.1's container fidelity: unpack, repack, unpack again, and the member
/// list and every member's bytes are unchanged.
static void testArchiveRoundTripIsByteIdentical(void) {
	MAD_NEED([[NSFileManager defaultManager] fileExistsAtPath: MADArchiveFixturePath()],
			 @"CLI/Fixtures/London.portable.mad is missing (it is checked in)");
	if (![[NSFileManager defaultManager] fileExistsAtPath: MADArchiveFixturePath()]) return;

	NSURL *guts = MADArchiveUnpackedFixture();
	MAD_NEED(guts != nil, @"the fixture did not unpack");
	if (guts == nil) return;

	NSURL *repacked = MADArchiveTemporaryURL(@"repacked.mad");
	MADArchiveManager *writer = [[MADArchiveManager alloc] initWithFileWrapperURL: guts
																	   archiveURL: repacked];
	MAD_PASS([writer archive: YES], "the writer finishes on this platform");

	NSData *written = [NSData dataWithContentsOfURL: repacked];
	MAD_PASS(written.length > MADFileFormatHeaderLength, "the document has bytes");
	MAD_PASS(written.length >= 8 && memcmp(written.bytes, MADFileFormatMagic, 8) == 0,
			 "the v1 magic is the first thing in it");

	// Unpack what was written and compare it with what was written from.
	NSURL *roundTripped = MADArchiveTemporaryURL(@"round-tripped");
	MADArchiveManager *reader = [[MADArchiveManager alloc] initWithFileWrapperURL: roundTripped
																	   archiveURL: repacked];
	MAD_PASS([reader unarchive], "the document it wrote unpacks");

	NSDictionary <NSString *, NSData *> *before = MADArchiveMembersAtURL(guts);
	NSDictionary <NSString *, NSData *> *after = MADArchiveMembersAtURL(roundTripped);
	MAD_PASS([[NSSet setWithArray: after.allKeys] isEqualToSet: [NSSet setWithArray: before.allKeys]],
			 "the same members, by path");
	MAD_PASS(after.count == 2, "the portable fixture's two files (the two directories are members too)");
	for (NSString *relativePath in before) {
		MAD_PASS_EQUAL(after[relativePath], before[relativePath],
					   "the member's bytes are unchanged: %s", [relativePath UTF8String]);
	}

	NSFileManager *fileManager = [NSFileManager defaultManager];
	[fileManager removeItemAtURL: guts error: NULL];
	[fileManager removeItemAtURL: roundTripped error: NULL];
}

/// The ordinary mode is the characterisation the Apple suite pins too: the archive
/// carries the members' own modification times, so a changed directory is changed
/// bytes.  That is what the reproducible mode exists to avoid.
static void testTheOrdinaryWriterKeepsTheRealMetadata(void) {
	MAD_NEED([[NSFileManager defaultManager] fileExistsAtPath: MADArchiveFixturePath()],
			 @"CLI/Fixtures/London.portable.mad is missing (it is checked in)");
	if (![[NSFileManager defaultManager] fileExistsAtPath: MADArchiveFixturePath()]) return;

	NSURL *guts = MADArchiveUnpackedFixture();
	MAD_NEED(guts != nil, @"the fixture did not unpack");
	if (guts == nil) return;

	NSURL *first = MADArchiveTemporaryURL(@"first.mad");
	NSURL *second = MADArchiveTemporaryURL(@"second.mad");
	MADArchiveManager *writer = [[MADArchiveManager alloc] initWithFileWrapperURL: guts archiveURL: first];
	MAD_PASS([writer archive: YES], "the first write finishes");

	// Age one member: an ordinary archive records what the filesystem says.
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *member = [guts.path stringByAppendingPathComponent: @"meta.plist"];
	[fileManager setAttributes: @{ NSFileModificationDate: [NSDate dateWithTimeIntervalSince1970: 1000000000] }
				  ofItemAtPath: member error: NULL];

	writer = [[MADArchiveManager alloc] initWithFileWrapperURL: guts archiveURL: second];
	MAD_PASS([writer archive: YES], "the second write finishes");

	NSData *firstBytes = [NSData dataWithContentsOfURL: first];
	NSData *secondBytes = [NSData dataWithContentsOfURL: second];
	MAD_PASS(firstBytes.length != secondBytes.length || ![firstBytes isEqualToData: secondBytes],
			 "an ordinary write records the members' own times, so the bytes changed");

	[fileManager removeItemAtURL: guts error: NULL];
}

/// The user's requirement, as a test: the same document written twice, and written on
/// the other platform, is the same file.
static void testTheReproducibleWriterIsByteIdentical(void) {
	MAD_NEED([[NSFileManager defaultManager] fileExistsAtPath: MADArchiveFixturePath()],
			 @"CLI/Fixtures/London.portable.mad is missing (it is checked in)");
	if (![[NSFileManager defaultManager] fileExistsAtPath: MADArchiveFixturePath()]) return;

	NSURL *guts = MADArchiveUnpackedFixture();
	MAD_NEED(guts != nil, @"the fixture did not unpack");
	if (guts == nil) return;

	// The Mac's `mad write` opens the document before it archives, and opening
	// migrates the store to the current version (MAD_SQL_ENTRY.md §8.2) -- so the
	// bytes the pin names are the opened store's.  Open and close here for the
	// same reason; the fixture itself is a version-1 store and stays one.
	MADStore *store = [MADStore storeWithURL: [guts URLByAppendingPathComponent: @"StoreContent/store.sqlite"]];
	NSError *openError = nil;
	MAD_PASS([store openWithError: &openError], "the fixture's store opens: %s",
			 openError != nil ? [[openError description] UTF8String] : "no error");
	[store close];

	// Age a member: a reproducible archive must not care.
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *member = [guts.path stringByAppendingPathComponent: @"meta.plist"];
	[fileManager setAttributes: @{ NSFileModificationDate: [NSDate dateWithTimeIntervalSince1970: 1000000000] }
				  ofItemAtPath: member error: NULL];

	NSURL *first = MADArchiveTemporaryURL(@"first.mad");
	NSURL *second = MADArchiveTemporaryURL(@"second.mad");
	// checkpointed as a document's write sets it, so this is the same file the
	// document-level test -- and the Mac -- produces.
	MADArchiveManager *writer = [[MADArchiveManager alloc] initWithFileWrapperURL: guts archiveURL: first];
	writer.checkpointed = YES;
	writer.reproducible = YES;
	MAD_PASS([writer archive: YES], "the first reproducible write finishes");

	writer = [[MADArchiveManager alloc] initWithFileWrapperURL: guts archiveURL: second];
	writer.checkpointed = YES;
	writer.reproducible = YES;
	MAD_PASS([writer archive: YES], "the second finishes");

	NSData *firstBytes = [NSData dataWithContentsOfURL: first];
	NSData *secondBytes = [NSData dataWithContentsOfURL: second];
	MAD_PASS([firstBytes isEqualToData: secondBytes], "two reproducible writes of one directory are one file");
	MAD_PASS_EQUAL(@(MADArchiveChecksum(firstBytes)), @(0x7A7978D6C388EE44ULL),
				   "and they are the bytes the Mac writes for the same document (Linux/README.md)");

	[fileManager removeItemAtURL: guts error: NULL];
}

/// `mad write`'s path: a headless document writes a copy of what it read, and the
/// document it read is not touched.
static void testTheHeadlessDocumentWritesACopy(void) {
	MAD_NEED([[NSFileManager defaultManager] fileExistsAtPath: MADArchiveFixturePath()],
			 @"CLI/Fixtures/London.portable.mad is missing (it is checked in)");
	if (![[NSFileManager defaultManager] fileExistsAtPath: MADArchiveFixturePath()]) return;

	NSData *sourceBefore = [NSData dataWithContentsOfFile: MADArchiveFixturePath()];

	NSError *error = nil;
	MADHeadlessDocument *document =
		[MADHeadlessDocument documentWithContentsOfURL: [NSURL fileURLWithPath: MADArchiveFixturePath()]
												 error: &error];
	MAD_NEED(document != nil, @"could not open the London fixture");
	if (document == nil) return;

	NSURL *copy = MADArchiveTemporaryURL(@"copy.mad");
	MAD_PASS([document writeToURL: copy reproducible: YES error: &error],
			 "the document writes: %s", error != nil ? [[error description] UTF8String] : "no error");

	NSData *written = [NSData dataWithContentsOfURL: copy];
	MAD_PASS(written.length > 0, "the copy has bytes");
	MAD_PASS_EQUAL(@(MADArchiveChecksum(written)), @(0x7A7978D6C388EE44ULL),
				   "the copy is the same file the Mac writes for this document");

	NSData *sourceAfter = [NSData dataWithContentsOfFile: MADArchiveFixturePath()];
	MAD_PASS_EQUAL(sourceAfter, sourceBefore, "the document that was read is unchanged");

	[[NSFileManager defaultManager] removeItemAtURL: copy error: NULL];
}

MAD_TEST_MAIN("MADArchiveManagerTests",
	MAD_TEST(testUnarchiveReadsAContainer),
	MAD_TEST(testArchiveRoundTripIsByteIdentical),
	MAD_TEST(testTheOrdinaryWriterKeepsTheRealMetadata),
	MAD_TEST(testTheReproducibleWriterIsByteIdentical),
	MAD_TEST(testTheHeadlessDocumentWritesACopy));
