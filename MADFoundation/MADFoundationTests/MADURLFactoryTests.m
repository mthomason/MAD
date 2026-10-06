//
//  MADURLFactoryTests.m
//  MADFoundationTests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Coverage for MADURLFactory: the factory for every directory and file URL the app
//  uses (documents, caches, application support, temporaries, thumbnails), plus the
//  two uniqueness routines that avoid clobbering an existing file.
//
//  Deliberately NOT covered: the group-container paths
//  (newURLLocalDocumentsDirectoryForGroupIdentifier: and friends,
//  newURLLocalDocumentWithName:extention:fileGroup:, newURLApplicationSupportFile:...).
//  They require a real App Group entitlement, which this logic-test bundle does not
//  carry: containerURLForSecurityApplicationGroupIdentifier: answers nil and the
//  factory's NSAssert fires.  The same is true of
//  +newURLForLocalDirectoryForGroupIdentifier:pathComponent:alternativeSelector:.
//
//  The directory-creating factories are exercised against the simulator's real
//  Library directory; everything they create is removed in -tearDown.
//

#import <XCTest/XCTest.h>

#import <UIKit/UIScreen.h>

#import <MADFoundation/MADURLFactory.h>

@interface MADURLFactoryTests : XCTestCase

@property (nonatomic, strong) NSMutableArray<NSURL *> *createdDirectories;
@property (nonatomic, strong) NSMutableArray<NSURL *> *scratchDirectories;

@end

@implementation MADURLFactoryTests

- (void)setUp {
	[super setUp];
	self.createdDirectories = [NSMutableArray array];
	self.scratchDirectories = [NSMutableArray array];
}

- (void)tearDown {
	NSFileManager *fileManager = [NSFileManager defaultManager];
	for (NSURL *url in self.createdDirectories) {
		[fileManager removeItemAtURL:url error:NULL];
	}
	for (NSURL *url in self.scratchDirectories) {
		[fileManager removeItemAtURL:url error:NULL];
	}
	self.createdDirectories = nil;
	self.scratchDirectories = nil;
	[super tearDown];
}

- (NSURL *)scratchDirectory {
	NSURL *url = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:NSUUID.UUID.UUIDString]
							isDirectory:YES];
	[[NSFileManager defaultManager] createDirectoryAtURL:url withIntermediateDirectories:YES attributes:nil error:NULL];
	[self.scratchDirectories addObject:url];
	return url;
}

- (NSString *)hashName:(NSString *)string {
	return [NSString stringWithFormat:@"%lu", (unsigned long)string.hash];
}

#pragma mark - Base directories

- (void)testLocalTemporaryDirectory {
	NSURL *url = [MADURLFactory newURLLocalTemporaryDirectory];

	XCTAssertTrue(url.isFileURL);
	XCTAssertTrue(url.hasDirectoryPath);
	XCTAssertEqualObjects(url.path, [NSHomeDirectory() stringByAppendingPathComponent:@"tmp"]);
}

- (void)testLocalDataDirectory {
	NSURL *url = [MADURLFactory newURLForLocalDataDirectory];

	XCTAssertTrue(url.isFileURL);
	XCTAssertEqualObjects(url.lastPathComponent, @"Data");
	XCTAssertTrue([url.path hasPrefix:NSHomeDirectory()]);
}

- (void)testLocalCacheDirectoryIsStable {
	NSURL *first = [MADURLFactory newURLForLocalCacheDirectory];
	NSURL *second = [MADURLFactory newURLForLocalCacheDirectory];

	XCTAssertNotNil(first);
	XCTAssertTrue(first.isFileURL);
	// Built once under dispatch_once; the same instance comes back afterwards.
	XCTAssertEqual(first, second);
	XCTAssertTrue([first.path containsString:@"Library/Caches"]);
}

- (void)testLocalDocumentsDirectory {
	NSURL *url = [MADURLFactory newURLForLocalDocumentsDirectory];

	XCTAssertNotNil(url);
	XCTAssertTrue([url.path hasSuffix:@"Documents"]);
}

#pragma mark - Cache subdirectories

- (void)testCacheDirectoryNamedCreatesTheDirectory {
	NSURL *url = [MADURLFactory newURLForLocalCacheDirectoryNamed:@"MADURLFactoryTests-one"];
	[self.createdDirectories addObject:url];

	XCTAssertTrue(url.isFileURL);
	XCTAssertTrue(url.hasDirectoryPath);
	XCTAssertEqualObjects(url.lastPathComponent, @"MADURLFactoryTests-one");

	BOOL isDirectory = NO;
	BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:url.path isDirectory:&isDirectory];
	XCTAssertTrue(exists);
	XCTAssertTrue(isDirectory);
}

- (void)testCacheDirectoryNamedIsIdempotent {
	NSURL *first = [MADURLFactory newURLForLocalCacheDirectoryNamed:@"MADURLFactoryTests-two"];
	[self.createdDirectories addObject:first];
	NSURL *second = [MADURLFactory newURLForLocalCacheDirectoryNamed:@"MADURLFactoryTests-two"];

	// The second call finds the directory and returns the same path.
	XCTAssertEqualObjects(first.path, second.path);
}

- (void)testCacheFilesDirectoryIsKeyedByFilenameHash {
	NSString *filename = @"MADURLFactoryTests.mad";
	NSURL *url = [MADURLFactory newURLCacheFilesDirectoryForFilename:filename];
	[self.createdDirectories addObject:url];

	XCTAssertEqualObjects(url.lastPathComponent, [self hashName:filename]);
}

- (void)testCachedDirectoryForFileURLIsKeyedByBasenameHash {
	NSURL *fileURL = [NSURL fileURLWithPath:@"/tmp/MADURLFactoryTests.mad"];
	NSURL *url = [MADURLFactory newURLForLocalCachedDirectoryForFileUrl:fileURL];
	[self.createdDirectories addObject:url];

	// The key is the hash of the basename *without* the extension.
	XCTAssertEqualObjects(url.lastPathComponent, [self hashName:@"MADURLFactoryTests"]);
}

#pragma mark - Thumbnails

- (void)testThumbnailForHandleRetina {
	NSURL *url = [MADURLFactory newURLThumbnailForHandle:@"Report" andRetinaDisplay:YES];
	[self.createdDirectories addObject:[url URLByDeletingLastPathComponent]];

	XCTAssertEqualObjects(url.lastPathComponent, @"Report@2x.png");
	XCTAssertEqualObjects(url.URLByDeletingLastPathComponent.lastPathComponent, [self hashName:@"Report"]);
}

- (void)testThumbnailForHandleNonRetina {
	NSURL *url = [MADURLFactory newURLThumbnailForHandle:@"Report" andRetinaDisplay:NO];
	[self.createdDirectories addObject:[url URLByDeletingLastPathComponent]];

	XCTAssertEqualObjects(url.lastPathComponent, @"Report.png");
}

- (void)testThumbnailForURLUsesTheDocumentName {
	NSURL *documentURL = [NSURL fileURLWithPath:@"/tmp/My Report.mad"];
	NSURL *url = [MADURLFactory newURLThumbnailForURL:documentURL];
	[self.createdDirectories addObject:[url URLByDeletingLastPathComponent]];

	// The handle is the document's basename; the retina suffix follows the screen.
	NSString *expectedName = [UIScreen mainScreen].scale > 1.0 ? @"My Report@2x.png" : @"My Report.png";
	XCTAssertEqualObjects(url.lastPathComponent, expectedName);
}

#pragma mark - Uniqueness

- (void)testUniqueFilenameForURLWhenFree {
	NSURL *directory = [self scratchDirectory];
	NSURL *original = [directory URLByAppendingPathComponent:@"Report.mad"];

	NSURL *unique = [MADURLFactory newURLWithUniqueFilenameForURL:original];

	XCTAssertEqualObjects(unique, original);
}

- (void)testUniqueFilenameForURLSkipsExistingFiles {
	NSURL *directory = [self scratchDirectory];
	NSURL *original = [directory URLByAppendingPathComponent:@"Report.mad"];
	[[NSFileManager defaultManager] createFileAtPath:original.path contents:[NSData data] attributes:nil];

	NSURL *first = [MADURLFactory newURLWithUniqueFilenameForURL:original];
	XCTAssertEqualObjects(first.lastPathComponent, @"Report 1.mad");

	// Occupy the first alternative and ask again.
	NSURL *occupied = [directory URLByAppendingPathComponent:@"Report 1.mad"];
	[[NSFileManager defaultManager] createFileAtPath:occupied.path contents:[NSData data] attributes:nil];

	NSURL *second = [MADURLFactory newURLWithUniqueFilenameForURL:original];
	XCTAssertEqualObjects(second.lastPathComponent, @"Report 2.mad");
}

- (void)testUniqueUrlInDirectoryAppendsZeroFirst {
	NSURL *directory = [self scratchDirectory];
	NSURL *existing = [directory URLByAppendingPathComponent:@"Report.mad"];
	[[NSFileManager defaultManager] createFileAtPath:existing.path contents:[NSData data] attributes:nil];

	NSURL *unique = [MADURLFactory newURLUniqueUrlInDirectory:directory
											withDesiredHandle:@"Report"
												 andExtension:@"mad"];

	// This routine numbers alternatives from zero ("Report 0.mad"), unlike
	// -newURLWithUniqueFilenameForURL: which starts at one.
	XCTAssertEqualObjects(unique.lastPathComponent, @"Report 0.mad");
}

- (void)testUniqueURLForURL {
	NSURL *directory = [self scratchDirectory];
	NSURL *existing = [directory URLByAppendingPathComponent:@"Report.mad"];
	[[NSFileManager defaultManager] createFileAtPath:existing.path contents:[NSData data] attributes:nil];

	NSURL *unique = [MADURLFactory newURLUniqueURLForURL:existing];

	XCTAssertEqualObjects(unique.lastPathComponent, @"Report 0.mad");
	XCTAssertEqualObjects(unique.URLByDeletingLastPathComponent.path, directory.path);
}

#pragma mark - Archives and selectors

- (void)testDocumentArchiveURL {
	NSURL *documentURL = [NSURL fileURLWithPath:@"/tmp/My Report.mad"];

	NSURL *archive = [MADURLFactory newURLDocumentArchiveForFileURL:documentURL extension:@"zip"];

	XCTAssertTrue(archive.hasDirectoryPath);
	XCTAssertEqualObjects(archive.lastPathComponent, @"My Report.zip");
	XCTAssertEqualObjects(archive.URLByDeletingLastPathComponent.path, [MADURLFactory newURLLocalTemporaryDirectory].path);
}

- (void)testURLForSelectorInvokesTheNamedFactory {
	NSURL *viaSelector = [MADURLFactory newURLForURLSelector:@selector(newURLLocalTemporaryDirectory)];

	XCTAssertEqualObjects(viaSelector, [MADURLFactory newURLLocalTemporaryDirectory]);
}

@end
