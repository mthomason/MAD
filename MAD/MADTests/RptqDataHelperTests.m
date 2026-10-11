//
//  RptqDataHelperTests.m
//  MADTests
//
//  Copyright © 2026 Michael Thomason. All rights reserved.
//
//  Characterization coverage for RptqDataHelper.  The class survives only for its
//  -cleanup entry point: identifier allocation moved into RptqStoreContext, so the
//  method is a deliberate no-op today.  The test pins that calling it is inert.
//

#import <XCTest/XCTest.h>

#import "RptqDataHelper.h"

@interface RptqDataHelperTests : XCTestCase
@end

@implementation RptqDataHelperTests

- (void)testCleanupIsAnInertNoOp {
	XCTAssertTrue([RptqDataHelper respondsToSelector:@selector(cleanup)]);

	// Nothing to observe but the absence of side effects; the call must simply return.
	[RptqDataHelper cleanup];
}

@end
