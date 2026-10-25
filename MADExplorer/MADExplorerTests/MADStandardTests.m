//
//  MADStandardTests.m
//  MADExplorerTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Coverage for MADStandard, the file-size formatting helper. Documents the
//  decimal (10^6) megabyte scale, the fixed three-decimal "X.XXX MB" format,
//  and the missing sub-megabyte fallback.
//

#import <XCTest/XCTest.h>

#import <MADExplorer/MADStandard.h>

@interface MADStandardTests : XCTestCase
@end

@implementation MADStandardTests

- (void)testWholeMegabytes {
	XCTAssertEqualObjects([MADStandard standardStringForFileSize:5000000], @"5.000 MB");
	XCTAssertEqualObjects([MADStandard standardStringForFileSize:1000000], @"1.000 MB");
	XCTAssertEqualObjects([MADStandard standardStringForFileSize:0], @"0.000 MB");
}

- (void)testFractionalMegabytes {
	XCTAssertEqualObjects([MADStandard standardStringForFileSize:1500000], @"1.500 MB");
}

- (void)testRoundsToThreeDecimals {
	// 1234567 bytes is 1.234567 MB; rounded to 3 decimals -> 1.235.
	XCTAssertEqualObjects([MADStandard standardStringForFileSize:1234567], @"1.235 MB");
	// 1000499 bytes is 1.000499 MB; rounded down -> 1.000.
	XCTAssertEqualObjects([MADStandard standardStringForFileSize:1000499], @"1.000 MB");
}

- (void)testTinyFileReportsZero {
	// Quirk: there is no byte/kB fallback, so a 1-byte file shows "0.000 MB".
	XCTAssertEqualObjects([MADStandard standardStringForFileSize:1], @"0.000 MB");
}

- (void)testUsesDecimalMegabytes {
	// 2^20 is the binary megabyte; in the decimal scale it is 1.048576 MB.
	XCTAssertEqualObjects([MADStandard standardStringForFileSize:1048576], @"1.049 MB");
}

- (void)testStandardStringForDouble {
	XCTAssertEqualObjects([MADStandard standardStringForDouble:5.5], @"5.500000");
	XCTAssertEqualObjects([MADStandard standardStringForDouble:0.0], @"0.000000");
}

- (void)testStandardStringForUnsignedLong {
	XCTAssertEqualObjects([MADStandard standardStringForUnsignedLong:42], @"42");
	XCTAssertEqualObjects([MADStandard standardStringForUnsignedLong:0], @"0");
}

@end
