//
//  MADMetaDataTests.m
//  MADFileManagerTests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Coverage for MADMetaData and its Local/Cloud subclasses. Documents the
//  factory-style initializers, the NSDate/NSData return-type lie on the two
//  file-date properties, and the inconsistent downloading-status reporting on
//  the Local subclass.
//

#import <XCTest/XCTest.h>

#import <MADFileManager/MADMetaData.h>
#import "../Source/MADMetaDataLocal.h"
#import "../Source/MADMetaDataCloud.h"

@interface MADMetaDataTests : XCTestCase
@end

@implementation MADMetaDataTests {
	NSURL *_directory;
	NSURL *_textFile;
	NSURL *_noExtensionFile;
}

- (NSURL *)makeTempDirectory {
	NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]];
	[[NSFileManager defaultManager] createDirectoryAtPath:path
							  withIntermediateDirectories:YES
											   attributes:nil
													error:nil];
	return [NSURL fileURLWithPath:path];
}

- (NSURL *)makeFileInDirectory:(NSURL *)directory name:(NSString *)name data:(NSData *)data {
	NSURL *url = [directory URLByAppendingPathComponent:name];
	[data writeToURL:url options:NSDataWritingAtomic error:nil];
	return url;
}

- (void)setUp {
	[super setUp];
	_directory = [self makeTempDirectory];
	NSData *fiveBytes = [@"hello" dataUsingEncoding:NSUTF8StringEncoding];
	_textFile = [self makeFileInDirectory:_directory name:@"report.txt" data:fiveBytes];
	_noExtensionFile = [self makeFileInDirectory:_directory name:@"noextension" data:fiveBytes];
}

- (void)tearDown {
	[[NSFileManager defaultManager] removeItemAtURL:_directory error:nil];
	_directory = nil;
	_textFile = nil;
	_noExtensionFile = nil;
	[super tearDown];
}

#pragma mark - Factory initializers

- (void)testInitWithURLReturnsLocalSubclass {
	// Defect/design: -initWithURL: does not initialize `self`; it allocates a
	// fresh MADMetaDataLocal and returns that instead, so the caller receives a
	// subclass instance (and the original MADMetaData allocation is dropped).
	MADMetaData *meta = [[MADMetaData alloc] initWithURL:_textFile];
	XCTAssertTrue([meta isKindOfClass:[MADMetaDataLocal class]]);
	XCTAssertTrue([meta isKindOfClass:[MADMetaData class]]);
}

- (void)testInitWithMetadataItemReturnsCloudSubclass {
	MADMetaData *meta = [[MADMetaData alloc] initWithMetadataItem:nil];
	XCTAssertTrue([meta isKindOfClass:[MADMetaDataCloud class]]);
	XCTAssertTrue([meta isKindOfClass:[MADMetaData class]]);
}

- (void)testNewMetaDatumForEmptyItems {
	XCTAssertEqualObjects([MADMetaData newMetaDatumForMetadataItems:@[]], @[]);
}

- (void)testNewMetaDatumWrapsEachItemAsCloud {
	// The factory does not type-check; anything passed in is handed to
	// -initWithMetadataItem:, which just stores it. Only the class identity is
	// asserted here (the item is never dereferenced during construction).
	NSArray *items = @[[NSNull null], [NSNull null]];
	NSArray *meta = [MADMetaData newMetaDatumForMetadataItems:items];
	XCTAssertEqual(meta.count, 2u);
	XCTAssertTrue([meta.firstObject isKindOfClass:[MADMetaDataCloud class]]);
	XCTAssertTrue([meta.lastObject isKindOfClass:[MADMetaDataCloud class]]);
}

#pragma mark - MADMetaDataLocal

- (void)testLocalNameStripsExtension {
	MADMetaData *meta = [[MADMetaData alloc] initWithURL:_textFile];
	XCTAssertEqualObjects(meta.name, @"report");
	XCTAssertEqualObjects(meta.fileSystemName, @"report.txt");
}

- (void)testLocalFileSize {
	MADMetaData *meta = [[MADMetaData alloc] initWithURL:_textFile];
	XCTAssertEqual(meta.fileSystemFileSize, (unsigned long long)5);
}

- (void)testLocalContentType {
	MADMetaData *meta = [[MADMetaData alloc] initWithURL:_textFile];
	XCTAssertEqualObjects(meta.contentType, @"public.plain-text");
}

- (void)testLocalContentTypeNilWithoutExtension {
	MADMetaData *meta = [[MADMetaData alloc] initWithURL:_noExtensionFile];
	XCTAssertNil(meta.contentType);
}

- (void)testLocalNameEmptyForNilURL {
	MADMetaData *meta = [[MADMetaData alloc] initWithURL:nil];
	XCTAssertEqualObjects(meta.name, @"");
}

- (void)testLocalCreationDateIsActuallyNSDate {
	// Defect: the header declares these properties as NSDate, but the
	// implementation returns NSData (the compiler sees the wrong type). The
	// object that actually comes back is an NSDate.
	MADMetaData *meta = [[MADMetaData alloc] initWithURL:_textFile];
	XCTAssertTrue([meta.fileSystemFileCreationDate isKindOfClass:[NSDate class]]);
	XCTAssertTrue([meta.fileSystemContentChangeDate isKindOfClass:[NSDate class]]);
}

- (void)testLocalUbiquitousFlags {
	MADMetaData *meta = [[MADMetaData alloc] initWithURL:_textFile];
	XCTAssertFalse(meta.isUbiquitous);
	XCTAssertTrue(meta.isDownloaded);
	XCTAssertFalse(meta.isSyncing);
	XCTAssertEqual(meta.ubiquitousItemPercentDownloaded, 100.0);
	XCTAssertEqual(meta.ubiquitousItemPercentUploaded, 100.0);
}

- (void)testLocalDownloadingStatusIsConsistent {
	// The derived boolean now agrees with the status string.
	MADMetaData *meta = [[MADMetaData alloc] initWithURL:_textFile];
	XCTAssertEqualObjects(meta.ubiquitousItemDownloadingStatus, @"NSMetadataUbiquitousItemDownloadingStatusCurrent");
	XCTAssertTrue(meta.isUbiquitousItemDownloadingStatusCurrent);
}

- (void)testLocalCopy {
	MADMetaData *meta = [[MADMetaData alloc] initWithURL:_textFile];
	MADMetaData *copy = [meta copy];
	XCTAssertNotNil(copy);
	XCTAssertTrue([copy isKindOfClass:[MADMetaDataLocal class]]);
	XCTAssertEqualObjects(copy.fileSystemName, meta.fileSystemName);
	XCTAssertFalse(copy == meta);
}

- (void)testEqualityAndHash {
	MADMetaData *a = [[MADMetaData alloc] initWithURL:_textFile];
	MADMetaData *b = [[MADMetaData alloc] initWithURL:_textFile];
	XCTAssertEqualObjects(a, b);
	XCTAssertEqual(a.hash, b.hash);

	MADMetaData *c = [[MADMetaData alloc] initWithURL:_noExtensionFile];
	XCTAssertNotEqualObjects(a, c);
}

#pragma mark - MADMetaDataCloud (nil metadata item)

- (void)testCloudNilMetadataItem {
	MADMetaDataCloud *cloud = [[MADMetaDataCloud alloc] initWithMetadataItem:nil];
	XCTAssertNil(cloud.name);
	XCTAssertNil(cloud.fileSystemName);
	XCTAssertEqual(cloud.fileSystemFileSize, (unsigned long long)0);
	XCTAssertFalse(cloud.isUbiquitous);
	XCTAssertEqualObjects(cloud.ubiquitousItemDownloadingStatus, @"NSMetadataUbiquitousItemDownloadingStatusCurrent");
	XCTAssertTrue(cloud.isUbiquitousItemDownloadingStatusCurrent);
	XCTAssertTrue(cloud.isDownloaded);
	XCTAssertFalse(cloud.isSyncing);
}

@end
