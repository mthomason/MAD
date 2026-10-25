//
//  MADLegacyStoreConversionTests.m
//  MADTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Characterization coverage for MADLegacyStoreConversion: the registry the document uses
//  to reach a Core Data converter it must not link itself.  Pinned here: the error
//  domain, the on-disk layout constants (including the load-bearing "analyitics"
//  misspelling), the error code, and the set/get round-trip that leaves the process-wide
//  slot as it was found.
//

#import <XCTest/XCTest.h>

#import "MADLegacyStoreConversion.h"

@interface MADLegacyStoreConversionTestsConverterDouble : NSObject <MADDocumentLegacyStoreConverting>
@end

@implementation MADLegacyStoreConversionTestsConverterDouble

- (BOOL)convertLegacyStoreAtURL:(__unused NSURL *)legacyStoreURL
				  toStoreAtURL:(__unused NSURL *)storeURL
						  error:(__unused NSError * _Nullable __autoreleasing *)error {
	return YES;
}

@end

@interface MADLegacyStoreConversionTests : XCTestCase
@property (nonatomic, strong) id<MADDocumentLegacyStoreConverting> previousConverter;
@end

@implementation MADLegacyStoreConversionTests

- (void)setUp {
	[super setUp];
	// The test host may register the app's real converter in +load; put it back after
	// every test so this file never disturbs another.
	self.previousConverter = [MADLegacyStoreConversion converter];
}

- (void)tearDown {
	[MADLegacyStoreConversion setConverter:self.previousConverter];
	[super tearDown];
}

- (void)testLayoutConstants {
	XCTAssertEqualObjects(MADLegacyStoreConversionErrorDomain, @"MADLegacyStoreConversionErrorDomain");
	XCTAssertEqualObjects(MADLegacyStoreDirectory, @"StoreContent");
	// The misspelling is on disk in every legacy document and is load-bearing.
	XCTAssertEqualObjects(MADLegacyStoreName, @"analyitics");
}

- (void)testConverterUnavailableErrorCode {
	XCTAssertEqual(MADLegacyStoreConversionErrorConverterUnavailable, (NSInteger)1);
}

- (void)testConverterSlotRoundTrips {
	MADLegacyStoreConversionTestsConverterDouble *converter = [[MADLegacyStoreConversionTestsConverterDouble alloc] init];

	[MADLegacyStoreConversion setConverter:converter];
	XCTAssertEqual([MADLegacyStoreConversion converter], converter);

	[MADLegacyStoreConversion setConverter:nil];
	XCTAssertNil([MADLegacyStoreConversion converter]);
}

@end
