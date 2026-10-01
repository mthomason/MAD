//
//  MADFileInfoTests.m
//  MADFileManagerTests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Coverage for MADFileInfo. Documents that -isEqual: compares by URL but no
//  -hash override is provided, so two equal MADFileInfo instances hash
//  differently and misbehave in NSSet/NSDictionary.
//

#import <XCTest/XCTest.h>

#import <MADFileManager/MADFileInfo.h>

@interface MADFileInfoTests : XCTestCase
@end

@implementation MADFileInfoTests {
	NSURL *_directory;
	NSURL *_file;
}

- (void)setUp {
	[super setUp];
	NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]];
	[[NSFileManager defaultManager] createDirectoryAtPath:path
							  withIntermediateDirectories:YES
											   attributes:nil
													error:nil];
	_directory = [NSURL fileURLWithPath:path];
	_file = [_directory URLByAppendingPathComponent:@"doc.mad"];
	[@"data" writeToURL:_file atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

- (void)tearDown {
	[[NSFileManager defaultManager] removeItemAtURL:_directory error:nil];
	_directory = nil;
	_file = nil;
	[super tearDown];
}

- (void)testInitStoresURL {
	MADFileInfo *info = [[MADFileInfo alloc] initWithURL:_file];
	XCTAssertEqualObjects(info.URL, _file);
}

- (void)testNameStripsExtension {
	MADFileInfo *info = [[MADFileInfo alloc] initWithURL:_file];
	XCTAssertEqualObjects(info.name, @"doc");
}

- (void)testNameEmptyForNilURL {
	MADFileInfo *info = [[MADFileInfo alloc] initWithURL:nil];
	XCTAssertEqualObjects(info.name, @"");
}

- (void)testCopy {
	MADFileInfo *info = [[MADFileInfo alloc] initWithURL:_file];
	MADFileInfo *copy = [info copy];
	XCTAssertNotNil(copy);
	XCTAssertEqualObjects(copy.URL, info.URL);
	XCTAssertFalse(copy == info);
}

- (void)testEquality {
	MADFileInfo *a = [[MADFileInfo alloc] initWithURL:_file];
	MADFileInfo *b = [[MADFileInfo alloc] initWithURL:_file];
	XCTAssertEqualObjects(a, b);

	NSURL *other = [_directory URLByAppendingPathComponent:@"other.mad"];
	MADFileInfo *c = [[MADFileInfo alloc] initWithURL:other];
	XCTAssertNotEqualObjects(a, c);
}

- (void)testEqualObjectsHaveDifferentHashes {
	// Defect: -isEqual: is overridden to compare URLs, but -hash is not. Two
	// equal MADFileInfo instances therefore produce different hash values,
	// which breaks their use as NSSet members / NSDictionary keys.
	MADFileInfo *a = [[MADFileInfo alloc] initWithURL:_file];
	MADFileInfo *b = [[MADFileInfo alloc] initWithURL:_file];
	XCTAssertEqualObjects(a, b);
	XCTAssertNotEqual(a.hash, b.hash);
}

- (void)testFetchInfoCallsCompletion {
	XCTestExpectation *done = [self expectationWithDescription:@"fetch completion"];
	MADFileInfo *info = [[MADFileInfo alloc] initWithURL:_file];
	__block BOOL called = NO;
	[info fetchInfoWithCompletionHandler:^{
		called = YES;
		[done fulfill];
	}];
	[self waitForExpectations:@[done] timeout:5.0];
	XCTAssertTrue(called);
}

@end
