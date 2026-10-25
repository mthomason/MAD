//
//  MADDataTableBaseTests.m
//  MADFoundationTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Coverage for the pieces of the MADDataTable base class the MAD-bundle regression
//  suite does not reach: the plist contract (copyPlist's exact shape, and each of
//  loadWithPlist:'s rejection paths with its error code), the base class's NSCoding
//  round trip, and the two nil-URL crashes in the caching pair.
//
//  MADDataTable is a class cluster; the row storage lives in MADDataTableVirtual /
//  MADDataTableFast, whose behaviour is covered by MADDataTableRegressionTests.  What
//  the base owns is metadata, the plist shape and the coding, which is what is pinned
//  here.
//
//  The nil-URL paths are pinned as characterization: both methods @throw an NSError
//  object (not an NSException), so a @catch (NSException *) will not see them.
//  See BUGS.md.
//

#import <XCTest/XCTest.h>

#import <MADFoundation/MADDataColumn.h>
#import <MADFoundation/MADDataTable.h>

@interface MADDataTableBaseTests : XCTestCase

@property (nonatomic, copy) NSURL *scratchFileURL;

@end

@implementation MADDataTableBaseTests

- (void)setUp {
	[super setUp];
	self.scratchFileURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:
												   [NSString stringWithFormat:@"MADDataTableBaseTests-%@.mdcache", NSUUID.UUID.UUIDString]]];
}

- (void)tearDown {
	[[NSFileManager defaultManager] removeItemAtURL:self.scratchFileURL error:NULL];
	[super tearDown];
}

- (MADDataColumn *)columnNamed:(NSString *)name {
	MADDataColumn *column = [MADDataColumn newDataColumnWithIdentifier:name];
	column.type = MADDataTypeString;
	[column addObject:@"alpha"];
	[column addObject:@"beta"];
	return column;
}

#pragma mark - Initializers

- (void)testInitWithNumberOfColumnsDefaults {
	MADDataTable *table = [[MADDataTable alloc] initWithNumberOfColumns:3];

	XCTAssertEqualObjects(table.name, @"");
	XCTAssertNotNil(table.columnKeys);
	XCTAssertNotNil(table.columns);
	XCTAssertNotNil(table.sortDescriptors);
	XCTAssertEqual(table.columnKeys.count, (NSUInteger)0);
	XCTAssertEqual(table.columns.count, (NSUInteger)0);
	XCTAssertEqual(table.rowCounter, (NSUInteger)0);
	XCTAssertEqual(table.tag, (NSUInteger)0);
}

#pragma mark - Plist shape

- (void)testCopyPlistShape {
	MADDataTable *table = [[MADDataTable alloc] initWithId:7];
	table.name = @"MADDataTableBaseTests";
	table.rowCounter = 2;
	MADDataColumn *column = [self columnNamed:@"title"];
	[table.columnKeys addObject:@"title"];
	table.columns[@"title"] = column;

	NSDictionary *plist = [table copyPlist];

	XCTAssertEqual(plist.count, (NSUInteger)4);
	XCTAssertEqualObjects(plist[@"name"], @"MADDataTableBaseTests");
	XCTAssertEqualObjects(plist[@"columnKeys"], (@[@"title"]));
	XCTAssertEqualObjects(plist[@"rowCounter"], @2);
	NSDictionary *columnsPlist = plist[@"columns"];
	XCTAssertTrue([columnsPlist isKindOfClass:[NSDictionary class]]);
	XCTAssertTrue([columnsPlist[@"title"] isKindOfClass:[NSDictionary class]]);
	XCTAssertEqualObjects(columnsPlist[@"title"][@"identifier"], @"title");
}

- (void)testLoadWithPlistRejectsNonDictionary {
	MADDataTable *table = [[MADDataTable alloc] initWithId:0];
	NSError *error = nil;

	BOOL success = [table loadWithPlist:(NSDictionary *)@"not a plist" error:&error];

	XCTAssertFalse(success);
	XCTAssertEqual(error.code, -4);
	XCTAssertEqualObjects(error.domain, MADDataTableErrorDomain);
}

- (void)testLoadWithPlistRejectsMissingColumnKeys {
	MADDataTable *table = [[MADDataTable alloc] initWithId:0];
	NSError *error = nil;

	BOOL success = [table loadWithPlist:@{ @"name": @"x" } error:&error];

	XCTAssertFalse(success);
	XCTAssertEqual(error.code, -5);
}

- (void)testLoadWithPlistRejectsMissingColumnData {
	MADDataTable *table = [[MADDataTable alloc] initWithId:0];
	NSError *error = nil;

	BOOL success = [table loadWithPlist:@{ @"name": @"x", @"columnKeys": @[@"a"] } error:&error];

	XCTAssertFalse(success);
	XCTAssertEqual(error.code, -6);
}

- (void)testLoadWithPlistBuildsColumnsAndRestoresMetadata {
	MADDataTable *source = [[MADDataTable alloc] initWithId:3];
	source.name = @"MADDataTableBaseTests";
	source.rowCounter = 2;
	MADDataColumn *column = [self columnNamed:@"title"];
	[source.columnKeys addObject:@"title"];
	source.columns[@"title"] = column;

	MADDataTable *restored = [[MADDataTable alloc] initWithId:0];
	NSError *error = nil;
	BOOL success = [restored loadWithPlist:[source copyPlist] error:&error];

	XCTAssertTrue(success);
	XCTAssertNil(error);
	XCTAssertEqualObjects(restored.name, @"MADDataTableBaseTests");
	XCTAssertEqual(restored.rowCounter, (NSUInteger)2);
	XCTAssertEqualObjects(restored.columnKeys, (@[@"title"]));
	XCTAssertTrue([restored.columns[@"title"] isKindOfClass:[MADDataColumn class]]);
	XCTAssertEqualObjects([restored.columns[@"title"] objectAtIndex:1], @"beta");
}

#pragma mark - NSCoding

- (void)testBaseNSCodingRoundTrip {
	MADDataTable *table = [[MADDataTable alloc] initWithId:9];
	table.name = @"MADDataTableBaseTests";
	table.rowCounter = 4;
	MADDataColumn *column = [self columnNamed:@"title"];
	[table.columnKeys addObject:@"title"];
	table.columns[@"title"] = column;

	// MADDataTable is NSCoding-only, so the insecure path is the only one it can
	// satisfy (the same shape as MADDatabase; see BUGS.md).
	NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initRequiringSecureCoding:NO];
	[archiver encodeObject:table forKey:NSKeyedArchiveRootObjectKey];
	NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingFromData:archiver.encodedData error:NULL];
	unarchiver.requiresSecureCoding = NO;
	MADDataTable *decoded = [unarchiver decodeObjectForKey:NSKeyedArchiveRootObjectKey];
	[unarchiver finishDecoding];

	XCTAssertNotNil(decoded);
	XCTAssertEqualObjects(decoded.name, @"MADDataTableBaseTests");
	XCTAssertEqual(decoded.rowCounter, (NSUInteger)4);
	XCTAssertEqual(decoded.tag, (NSUInteger)9);
	XCTAssertEqualObjects(decoded.columnKeys, (@[@"title"]));
	XCTAssertTrue([decoded.columns[@"title"] isKindOfClass:[MADDataColumn class]]);
}

#pragma mark - Caching

- (void)testCacheAndLoadRoundTripThroughAFile {
	MADDataTable *table = [[MADDataTable alloc] initWithId:5];
	table.name = @"MADDataTableBaseTests";
	table.rowCounter = 1;
	MADDataColumn *column = [self columnNamed:@"title"];
	[table.columnKeys addObject:@"title"];
	table.columns[@"title"] = column;

	NSError *error = nil;
	XCTAssertTrue([table cacheWithUrl:self.scratchFileURL error:&error], @"cache failed: %@", error);

	MADDataTable *restored = [[MADDataTable alloc] initWithId:0];
	NSError *loadError = nil;
	XCTAssertTrue([restored loadFromCacheWithUrl:self.scratchFileURL error:&loadError], @"load failed: %@", loadError);

	XCTAssertEqualObjects(restored.name, @"MADDataTableBaseTests");
	XCTAssertEqual(restored.rowCounter, (NSUInteger)1);
	XCTAssertEqualObjects(restored.columnKeys, (@[@"title"]));
	XCTAssertTrue([restored.columns[@"title"] isKindOfClass:[MADDataColumn class]]);
}

// Characterization of a defect documented in BUGS.md: these two throw the NSError
// object itself, so `@catch (NSException *)` will not catch them.
- (void)testCacheWithNilUrlThrowsTheErrorObject {
	MADDataTable *table = [[MADDataTable alloc] initWithId:0];

	@try {
		[table cacheWithUrl:(NSURL *)nil error:NULL];
		XCTFail(@"Expected a throw");
	} @catch (id thrown) {
		XCTAssertTrue([thrown isKindOfClass:[NSError class]]);
		XCTAssertEqual(((NSError *)thrown).code, -22);
		XCTAssertEqualObjects(((NSError *)thrown).domain, @"MADDataTable");
	}
}

- (void)testLoadFromCacheWithNilUrlThrowsTheErrorObject {
	MADDataTable *table = [[MADDataTable alloc] initWithId:0];

	@try {
		[table loadFromCacheWithUrl:(NSURL *)nil error:NULL];
		XCTFail(@"Expected a throw");
	} @catch (id thrown) {
		XCTAssertTrue([thrown isKindOfClass:[NSError class]]);
		XCTAssertEqual(((NSError *)thrown).code, -213);
	}
}

@end
