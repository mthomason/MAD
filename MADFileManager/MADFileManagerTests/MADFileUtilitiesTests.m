//
//  MADFileUtilitiesTests.m
//  MADFileManagerTests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Coverage for the pure filesystem helpers on MADFileUtilities. Several of
//  these are not declared in the public header; they are surfaced here via a
//  test-only category. Documents that -removeContentsOfDirectory: also removes
//  the directory itself, not just its contents.
//

#import <XCTest/XCTest.h>

#import <MADFileManager/MADFileUtilities.h>

@interface MADFileUtilities (TestAccess)
+ (BOOL)createDirectoryForUrlIfItDoesNotExist:(NSURL *)url;
+ (NSArray <NSURL *> *)contentsOfDirectory:(NSURL *)directory withPathExtension:(NSString *)extension;
+ (BOOL)removeContentsOfDirectory:(NSURL *)directory;
@end

@interface MADFileUtilitiesTests : XCTestCase
@end

@implementation MADFileUtilitiesTests {
	NSURL *_directory;
}

- (NSURL *)uniqueTempDirectoryURL {
	NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]];
	return [NSURL fileURLWithPath:path];
}

- (void)setUp {
	[super setUp];
	_directory = [self uniqueTempDirectoryURL];
}

- (void)tearDown {
	if (_directory) {
		[[NSFileManager defaultManager] removeItemAtURL:_directory error:nil];
	}
	_directory = nil;
	[super tearDown];
}

- (void)testQueueIsSingleton {
	XCTAssertNotNil([MADFileUtilities queue]);
	XCTAssertEqual([MADFileUtilities queue], [MADFileUtilities queue]);
}

- (void)testCreateDirectoryForUrlIfItDoesNotExist {
	XCTAssertTrue([MADFileUtilities createDirectoryForUrlIfItDoesNotExist:_directory]);

	BOOL isDirectory = NO;
	XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:_directory.path isDirectory:&isDirectory]);
	XCTAssertTrue(isDirectory);

	// Idempotent: creating an existing directory still reports success.
	XCTAssertTrue([MADFileUtilities createDirectoryForUrlIfItDoesNotExist:_directory]);
}

- (void)testContentsOfDirectoryFiltersByExtension {
	XCTAssertTrue([MADFileUtilities createDirectoryForUrlIfItDoesNotExist:_directory]);
	[@"a" writeToURL:[_directory URLByAppendingPathComponent:@"a.txt"] atomically:YES encoding:NSUTF8StringEncoding error:nil];
	[@"b" writeToURL:[_directory URLByAppendingPathComponent:@"b.mad"] atomically:YES encoding:NSUTF8StringEncoding error:nil];
	[@"c" writeToURL:[_directory URLByAppendingPathComponent:@"c.txt"] atomically:YES encoding:NSUTF8StringEncoding error:nil];
	[@"d" writeToURL:[_directory URLByAppendingPathComponent:@"d"] atomically:YES encoding:NSUTF8StringEncoding error:nil];

	NSArray *txt = [MADFileUtilities contentsOfDirectory:_directory withPathExtension:@"txt"];
	XCTAssertEqual(txt.count, 2u);

	NSArray *mad = [MADFileUtilities contentsOfDirectory:_directory withPathExtension:@"mad"];
	XCTAssertEqual(mad.count, 1u);

	NSArray *none = [MADFileUtilities contentsOfDirectory:_directory withPathExtension:@"zzz"];
	XCTAssertEqual(none.count, 0u);
}

- (void)testRemoveContentsOfDirectoryAlsoRemovesDirectory {
	// Defect: the method name promises to remove only the contents, but it also
	// deletes the directory itself.
	XCTAssertTrue([MADFileUtilities createDirectoryForUrlIfItDoesNotExist:_directory]);
	[@"a" writeToURL:[_directory URLByAppendingPathComponent:@"a.txt"] atomically:YES encoding:NSUTF8StringEncoding error:nil];

	XCTAssertTrue([MADFileUtilities removeContentsOfDirectory:_directory]);
	XCTAssertFalse([[NSFileManager defaultManager] fileExistsAtPath:_directory.path]);

	// Do not let tearDown try to remove it again.
	_directory = nil;
}

@end
