//
//  MADSchemaFieldSelectorModelTests.m
//  MADTests
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//
//  Characterization coverage for MADSchemaFieldSelectorModel: the schema field selector's
//  per-table folding state.  The only behaviour is that a fresh model starts closed and
//  that -open round-trips.
//

#import <XCTest/XCTest.h>

#import "MADSchemaFieldSelectorModel.h"

@interface MADSchemaFieldSelectorModelTests : XCTestCase
@end

@implementation MADSchemaFieldSelectorModelTests

- (void)testInitStartsClosed {
	MADSchemaFieldSelectorModel *model = [[MADSchemaFieldSelectorModel alloc] init];

	XCTAssertFalse(model.open);
}

- (void)testOpenRoundTrips {
	MADSchemaFieldSelectorModel *model = [[MADSchemaFieldSelectorModel alloc] init];

	model.open = YES;
	XCTAssertTrue(model.open);

	model.open = NO;
	XCTAssertFalse(model.open);
}

@end
