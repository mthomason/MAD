//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

//
//  MADSchemaFieldSelectorModelTests.m
//  Linux/Tests
//
//  Ported from MAD/MADTests/MADSchemaFieldSelectorModelTests.m: the schema field
//  selector's per-table folding state -- a fresh model starts closed, and -open
//  round-trips.
//

#import "MADTestSupport.h"

#import <MAD/MADSchemaFieldSelectorModel.h>

static void testInitStartsClosed(void) {
	MADSchemaFieldSelectorModel *model = [[MADSchemaFieldSelectorModel alloc] init];

	MAD_PASS(!model.open, "a fresh model starts closed");

	[model release];
}

static void testOpenRoundTrips(void) {
	MADSchemaFieldSelectorModel *model = [[MADSchemaFieldSelectorModel alloc] init];

	model.open = YES;
	MAD_PASS(model.open, "the model opens");

	model.open = NO;
	MAD_PASS(!model.open, "the model closes");

	[model release];
}

MAD_TEST_MAIN("MADSchemaFieldSelectorModelTests",
	MAD_TEST(testInitStartsClosed),
	MAD_TEST(testOpenRoundTrips));
