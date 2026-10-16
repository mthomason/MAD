//
//  MADQueryTestTests.m
//  Linux/Tests
//
//  Ported from MAD/MADTests/MADQueryTestTests.m: coverage for MADQueryTest, the
//  trivial connection probe -- it selects the literal 255 under a safe
//  identifier, enough to prove a connection answers.  The mock database is the
//  portable half of MADMock (Tests/Support/MADMock.h); the Xcode suite's
//  Core Data fixture is not needed here.
//

#import "MADTestSupport.h"

#import <MADAPI/MADDatabase.h>
#import <MADAPI/MADQueryType.h>

#import "MADMock.h"
#import <MAD/MADQuery+Extras.h>
#import <MAD/MADQueryTest.h>

static void testSqlSelectsTheLiteral(void) {
	MADQueryTest *query = [[MADQueryTest alloc] initWithObject:nil];
	query.database = [MADMock mockDatabase];

	MAD_PASS_EQUAL([query getSql:NULL], @"SELECT\n 255 AS f1", "the probe selects the literal 255 as f1");
}

static void testTypeAndDefaults(void) {
	MADQueryTest *query = [[MADQueryTest alloc] initWithObject:nil];

	MAD_PASS(query.type == MADQueryTypeConnectionTest, "the probe is the connection-test query type");
	MAD_PASS(query.returnsResults, "the probe returns results");
}

MAD_TEST_MAIN("MADQueryTestTests",
	MAD_TEST(testSqlSelectsTheLiteral),
	MAD_TEST(testTypeAndDefaults));
