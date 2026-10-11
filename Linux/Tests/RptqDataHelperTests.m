//
//  RptqDataHelperTests.m
//  Linux/Tests
//
//  Ported from MAD/MADTests/RptqDataHelperTests.m: RptqDataHelper survives only
//  for its -cleanup entry point (identifier allocation moved into
//  RptqStoreContext), so the test pins that calling it is inert.
//

#import "MADTestSupport.h"

#import <MAD/RptqDataHelper.h>

static void testCleanupIsAnInertNoOp(void) {
	MAD_PASS([RptqDataHelper respondsToSelector:@selector(cleanup)], "the cleanup entry point exists");

	// Nothing to observe but the absence of side effects; the call must simply return.
	[RptqDataHelper cleanup];
}

MAD_TEST_MAIN("RptqDataHelperTests",
	MAD_TEST(testCleanupIsAnInertNoOp));
