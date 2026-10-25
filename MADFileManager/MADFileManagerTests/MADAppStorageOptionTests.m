//
//  MADAppStorageOptionTests.m
//  MADFileManagerTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Locks down the raw values of the MADAppStorage enum. These values are the
//  persisted storage-location state and must not drift across a Core Data ->
//  SQL migration.
//

#import <XCTest/XCTest.h>

#import <MADFileManager/MADAppStorageOption.h>

@interface MADAppStorageOptionTests : XCTestCase
@end

@implementation MADAppStorageOptionTests

- (void)testRawValues {
	XCTAssertEqual(MADAppStorageNotSet, (MADAppStorage)0);
	XCTAssertEqual(MADAppStorageCloud, (MADAppStorage)1);
	XCTAssertEqual(MADAppStorageLocal, (MADAppStorage)2);
	XCTAssertEqual(MADAppStorageCloudButSignedOut, (MADAppStorage)3);
	XCTAssertEqual(MADAppStorageStateUnknown, (MADAppStorage)4);
}

@end
