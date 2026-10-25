//
//  MADURLFactoryTests.m
//  Linux/Tests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Ported from MADFoundationTests/MADURLFactoryTests.m: coverage for
//  MADURLFactory, the factory for every directory and file URL the app uses
//  (documents, caches, application support, temporaries, thumbnails), plus
//  the two uniqueness routines that avoid clobbering an existing file.
//
//  Apple's group-container paths depend on the App Group entitlement, which
//  may or may not be present, so the Xcode suite branches on the container.  On
//  Linux there are no app-group containers and no
//  -containerURLForSecurityApplicationGroupIdentifier: on NSFileManager, and
//  MADURLFactory's Linux branch returns the per-user directory instead of
//  asserting; the group test asserts that fallback.
//
//  The directory-creating factories are exercised against the real per-user
//  Library directory; everything a test creates is removed at the end of it.
//

#import "MADTestSupport.h"
#import <MADFoundation/MADApplication.h>
#import <MADFoundation/MADURLFactory.h>

// The Xcode suite's -setUp/-tearDown pair, as a file-scope static: every
// directory URL a test creates is tracked here and removed when that test
// ends.  Each test brackets its body with these calls the way the XCTest
// runner bracketed the method.
static NSMutableArray *gCreatedDirectories = nil;

static void trackCreatedDirectory(NSURL *url) {
	if (gCreatedDirectories == nil) {
		gCreatedDirectories = [[NSMutableArray alloc] init];
	}
	[gCreatedDirectories addObject:url];
}

static void removeCreatedDirectories(void) {
	NSFileManager *fileManager = [NSFileManager defaultManager];
	for (NSURL *url in gCreatedDirectories) {
		[fileManager removeItemAtURL:url error:NULL];
	}
	[gCreatedDirectories removeAllObjects];
}

static NSString *hashName(NSString *string) {
	return [[NSString alloc] initWithFormat:@"%lu", (unsigned long)string.hash];
}

// GNUstep's NSURL has no -hasDirectoryPath; -path never carries the trailing
// slash, but a directory URL's absolute string ends in "/" (NSURL.m puts it
// there for isDirectory:YES), which is the same bit the Xcode suite reads.
static BOOL urlHasDirectoryPath(NSURL *url) {
	return [url.absoluteString hasSuffix:@"/"];
}

static NSURL *scratchDirectory(void) {
	NSURL *url = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]]
							isDirectory:YES];
	[[NSFileManager defaultManager] createDirectoryAtURL:url
							 withIntermediateDirectories:YES
											  attributes:nil
												   error:NULL];
	trackCreatedDirectory(url);
	return url;
}

#pragma mark - Base directories

static void testLocalTemporaryDirectory(void) {
	NSURL *url = [MADURLFactory newURLLocalTemporaryDirectory];

	MAD_PASS(url.isFileURL, "a file URL");
	MAD_PASS(urlHasDirectoryPath(url), "a directory URL");
	MAD_PASS_EQUAL(url.path, [NSHomeDirectory() stringByAppendingPathComponent:@"tmp"], "home + tmp");
}

static void testLocalDataDirectory(void) {
	NSURL *url = [MADURLFactory newURLForLocalDataDirectory];

	MAD_PASS(url.isFileURL, "a file URL");
	MAD_PASS_EQUAL(url.lastPathComponent, @"Data", "the Data component");
	MAD_PASS([url.path hasPrefix:NSHomeDirectory()], "lives under the home directory");
}

static void testLocalCacheDirectoryIsStable(void) {
	NSURL *first = [MADURLFactory newURLForLocalCacheDirectory];
	NSURL *second = [MADURLFactory newURLForLocalCacheDirectory];

	MAD_PASS(first != nil, "the cache directory exists");
	MAD_PASS(first.isFileURL, "a file URL");
	// Built once under dispatch_once; the same instance comes back afterwards.
	MAD_PASS(first == second, "the same instance comes back");
	MAD_PASS([first.path containsString:@"Library/Caches"], "the Library/Caches location");
}

static void testLocalDocumentsDirectory(void) {
	NSURL *url = [MADURLFactory newURLForLocalDocumentsDirectory];

	MAD_PASS(url != nil, "the documents directory exists");
	MAD_PASS([url.path hasSuffix:@"Documents"], "the Documents location");
}

#pragma mark - Group container

static void testDocumentsDirectoryForGroupIdentifier(void) {
	// No app-group container off Apple: MADURLFactory's Linux branch answers the
	// per-user directory through the alternative selector (it neither creates
	// the container the Apple branch expects nor fires its assertion), and the
	// document-name helper goes through the same path.
	NSString *group = [MADApplication groupIdentifier];
	NSURL *documents = [MADURLFactory newURLLocalDocumentsDirectoryForGroupIdentifier:group];

	MAD_PASS_EQUAL(documents, [MADURLFactory newURLForLocalDocumentsDirectory], "the per-user Documents fallback");
	MAD_PASS_EQUAL(documents.lastPathComponent, @"Documents", "the Documents component");

	NSURL *document = [MADURLFactory newURLLocalDocumentWithName:@"Report" extention:@"mad" fileGroup:group];
	MAD_PASS_EQUAL(document.lastPathComponent, @"Report.mad", "the document name");
	MAD_PASS_EQUAL(document.URLByDeletingLastPathComponent.path, documents.path, "the document sits in the documents directory");
}

#pragma mark - Cache subdirectories

static void testCacheDirectoryNamedCreatesTheDirectory(void) {
	NSURL *url = [MADURLFactory newURLForLocalCacheDirectoryNamed:@"MADURLFactoryTests-one"];
	trackCreatedDirectory(url);

	MAD_PASS(url.isFileURL, "a file URL");
	MAD_PASS(urlHasDirectoryPath(url), "a directory URL");
	MAD_PASS_EQUAL(url.lastPathComponent, @"MADURLFactoryTests-one", "the named component");

	BOOL isDirectory = NO;
	BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:url.path isDirectory:&isDirectory];
	MAD_PASS(exists, "the directory exists");
	MAD_PASS(isDirectory, "and it is a directory");
	removeCreatedDirectories();
}

static void testCacheDirectoryNamedIsIdempotent(void) {
	NSURL *first = [MADURLFactory newURLForLocalCacheDirectoryNamed:@"MADURLFactoryTests-two"];
	trackCreatedDirectory(first);
	NSURL *second = [MADURLFactory newURLForLocalCacheDirectoryNamed:@"MADURLFactoryTests-two"];

	// The second call finds the directory and returns the same path.
	MAD_PASS_EQUAL(first.path, second.path, "the same path comes back");
	removeCreatedDirectories();
}

static void testCacheFilesDirectoryIsKeyedByFilenameHash(void) {
	NSString *filename = @"MADURLFactoryTests.mad";
	NSURL *url = [MADURLFactory newURLCacheFilesDirectoryForFilename:filename];
	trackCreatedDirectory(url);

	MAD_PASS_EQUAL(url.lastPathComponent, hashName(filename), "the filename-hash directory");
	removeCreatedDirectories();
}

static void testCachedDirectoryForFileURLIsKeyedByBasenameHash(void) {
	NSURL *fileURL = [NSURL fileURLWithPath:@"/tmp/MADURLFactoryTests.mad"];
	NSURL *url = [MADURLFactory newURLForLocalCachedDirectoryForFileUrl:fileURL];
	trackCreatedDirectory(url);

	// The key is the hash of the basename *without* the extension.
	MAD_PASS_EQUAL(url.lastPathComponent, hashName(@"MADURLFactoryTests"), "the basename-hash directory");
	removeCreatedDirectories();
}

#pragma mark - Thumbnails

static void testThumbnailForHandleRetina(void) {
	NSURL *url = [MADURLFactory newURLThumbnailForHandle:@"Report" andRetinaDisplay:YES];
	trackCreatedDirectory([url URLByDeletingLastPathComponent]);

	MAD_PASS_EQUAL(url.lastPathComponent, @"Report@2x.png", "the retina filename");
	MAD_PASS_EQUAL(url.URLByDeletingLastPathComponent.lastPathComponent, hashName(@"Report"), "the handle-hash directory");
	removeCreatedDirectories();
}

static void testThumbnailForHandleNonRetina(void) {
	NSURL *url = [MADURLFactory newURLThumbnailForHandle:@"Report" andRetinaDisplay:NO];
	trackCreatedDirectory([url URLByDeletingLastPathComponent]);

	MAD_PASS_EQUAL(url.lastPathComponent, @"Report.png", "the non-retina filename");
	removeCreatedDirectories();
}

static void testThumbnailForURLUsesTheDocumentName(void) {
	NSURL *documentURL = [NSURL fileURLWithPath:@"/tmp/My Report.mad"];
	NSURL *url = [MADURLFactory newURLThumbnailForURL:documentURL];
	trackCreatedDirectory([url URLByDeletingLastPathComponent]);

	// The handle is the document's basename; the suffix follows the screen.
	// There is no screen to ask off Apple, and the factory's Linux branch
	// answers retina so the @2x name the Apple targets write is the one read.
	MAD_PASS_EQUAL(url.lastPathComponent, @"My Report@2x.png", "the document name with the retina suffix");
	removeCreatedDirectories();
}

#pragma mark - Uniqueness

static void testUniqueFilenameForURLWhenFree(void) {
	NSURL *directory = scratchDirectory();
	NSURL *original = [directory URLByAppendingPathComponent:@"Report.mad"];

	NSURL *unique = [MADURLFactory newURLWithUniqueFilenameForURL:original];

	MAD_PASS_EQUAL(unique, original, "the original URL comes back while free");
	removeCreatedDirectories();
}

static void testUniqueFilenameForURLSkipsExistingFiles(void) {
	NSURL *directory = scratchDirectory();
	NSURL *original = [directory URLByAppendingPathComponent:@"Report.mad"];
	[[NSFileManager defaultManager] createFileAtPath:original.path contents:[NSData data] attributes:nil];

	NSURL *first = [MADURLFactory newURLWithUniqueFilenameForURL:original];
	MAD_PASS_EQUAL(first.lastPathComponent, @"Report 1.mad", "the first alternative");

	// Occupy the first alternative and ask again.
	NSURL *occupied = [directory URLByAppendingPathComponent:@"Report 1.mad"];
	[[NSFileManager defaultManager] createFileAtPath:occupied.path contents:[NSData data] attributes:nil];

	NSURL *second = [MADURLFactory newURLWithUniqueFilenameForURL:original];
	MAD_PASS_EQUAL(second.lastPathComponent, @"Report 2.mad", "the second alternative");
	removeCreatedDirectories();
}

static void testUniqueUrlInDirectoryAppendsZeroFirst(void) {
	NSURL *directory = scratchDirectory();
	NSURL *existing = [directory URLByAppendingPathComponent:@"Report.mad"];
	[[NSFileManager defaultManager] createFileAtPath:existing.path contents:[NSData data] attributes:nil];

	NSURL *unique = [MADURLFactory newURLUniqueUrlInDirectory:directory
											withDesiredHandle:@"Report"
												 andExtension:@"mad"];

	// This routine numbers alternatives from zero ("Report 0.mad"), unlike
	// -newURLWithUniqueFilenameForURL: which starts at one.
	MAD_PASS_EQUAL(unique.lastPathComponent, @"Report 0.mad", "zero-based numbering");
	removeCreatedDirectories();
}

static void testUniqueURLForURL(void) {
	NSURL *directory = scratchDirectory();
	NSURL *existing = [directory URLByAppendingPathComponent:@"Report.mad"];
	[[NSFileManager defaultManager] createFileAtPath:existing.path contents:[NSData data] attributes:nil];

	NSURL *unique = [MADURLFactory newURLUniqueURLForURL:existing];

	MAD_PASS_EQUAL(unique.lastPathComponent, @"Report 0.mad", "zero-based numbering");
	MAD_PASS_EQUAL(unique.URLByDeletingLastPathComponent.path, directory.path, "the same directory");
	removeCreatedDirectories();
}

#pragma mark - Archives and selectors

static void testDocumentArchiveURL(void) {
	NSURL *documentURL = [NSURL fileURLWithPath:@"/tmp/My Report.mad"];

	NSURL *archive = [MADURLFactory newURLDocumentArchiveForFileURL:documentURL extension:@"zip"];

	MAD_PASS(urlHasDirectoryPath(archive), "a directory URL");
	MAD_PASS_EQUAL(archive.lastPathComponent, @"My Report.zip", "the archive name");
	MAD_PASS_EQUAL(archive.URLByDeletingLastPathComponent.path,
				   [MADURLFactory newURLLocalTemporaryDirectory].path,
				   "in the temporary directory");
}

static void testURLForSelectorInvokesTheNamedFactory(void) {
	NSURL *viaSelector = [MADURLFactory newURLForURLSelector:@selector(newURLLocalTemporaryDirectory)];

	MAD_PASS_EQUAL(viaSelector, [MADURLFactory newURLLocalTemporaryDirectory], "the selector invokes the factory");
}

MAD_TEST_MAIN("MADURLFactoryTests",
	MAD_TEST(testLocalTemporaryDirectory),
	MAD_TEST(testLocalDataDirectory),
	MAD_TEST(testLocalCacheDirectoryIsStable),
	MAD_TEST(testLocalDocumentsDirectory),
	MAD_TEST(testDocumentsDirectoryForGroupIdentifier),
	MAD_TEST(testCacheDirectoryNamedCreatesTheDirectory),
	MAD_TEST(testCacheDirectoryNamedIsIdempotent),
	MAD_TEST(testCacheFilesDirectoryIsKeyedByFilenameHash),
	MAD_TEST(testCachedDirectoryForFileURLIsKeyedByBasenameHash),
	MAD_TEST(testThumbnailForHandleRetina),
	MAD_TEST(testThumbnailForHandleNonRetina),
	MAD_TEST(testThumbnailForURLUsesTheDocumentName),
	MAD_TEST(testUniqueFilenameForURLWhenFree),
	MAD_TEST(testUniqueFilenameForURLSkipsExistingFiles),
	MAD_TEST(testUniqueUrlInDirectoryAppendsZeroFirst),
	MAD_TEST(testUniqueURLForURL),
	MAD_TEST(testDocumentArchiveURL),
	MAD_TEST(testURLForSelectorInvokesTheNamedFactory));
