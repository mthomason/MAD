//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADLegacyStoreConversionTests.m
//  Linux/Tests
//
//  Ported from MAD/MADTests/MADLegacyStoreConversionTests.m: the registry the
//  document uses to reach a Core Data converter it must not link itself.  Pinned
//  here: the error domain, the on-disk layout constants (including the
//  load-bearing "analyitics" misspelling), the error code, and the set/get
//  round-trip.  The Xcode setUp/tearDown pair saved and restored the process-wide
//  slot around every test; only the round-trip test mutates it, so it saves and
//  restores in place.
//

#import "MADTestSupport.h"

#import <MAD/MADLegacyStoreConversion.h>

@interface MADLegacyStoreConversionTestsConverterDouble : NSObject <MADDocumentLegacyStoreConverting>
@end

@implementation MADLegacyStoreConversionTestsConverterDouble

- (BOOL)convertLegacyStoreAtURL:(__unused NSURL *)legacyStoreURL
				  toStoreAtURL:(__unused NSURL *)storeURL
						  error:(__unused NSError * _Nullable __autoreleasing *)error {
	return YES;
}

@end

static void testLayoutConstants(void) {
	MAD_PASS_EQUAL(MADLegacyStoreConversionErrorDomain, @"MADLegacyStoreConversionErrorDomain", "the error domain");
	MAD_PASS_EQUAL(MADLegacyStoreDirectory, @"StoreContent", "the store directory");
	// The misspelling is on disk in every legacy document and is load-bearing.
	MAD_PASS_EQUAL(MADLegacyStoreName, @"analyitics", "the store's on-disk name keeps its misspelling");
}

static void testConverterUnavailableErrorCode(void) {
	MAD_PASS(MADLegacyStoreConversionErrorConverterUnavailable == (NSInteger)1, "the converter-unavailable code is 1");
}

static void testConverterSlotRoundTrips(void) {
	// Put the process-wide slot back as it was found, the way the Xcode tearDown did.
	id<MADDocumentLegacyStoreConverting> previous = [MADLegacyStoreConversion converter];

	MADLegacyStoreConversionTestsConverterDouble *converter = [[MADLegacyStoreConversionTestsConverterDouble alloc] init];

	[MADLegacyStoreConversion setConverter:converter];
	MAD_PASS([MADLegacyStoreConversion converter] == converter, "the slot hands back what was set");

	[MADLegacyStoreConversion setConverter:nil];
	MAD_PASS([MADLegacyStoreConversion converter] == nil, "the slot clears");

	[MADLegacyStoreConversion setConverter:previous];
	[converter release];
}

MAD_TEST_MAIN("MADLegacyStoreConversionTests",
	MAD_TEST(testLayoutConstants),
	MAD_TEST(testConverterUnavailableErrorCode),
	MAD_TEST(testConverterSlotRoundTrips));
