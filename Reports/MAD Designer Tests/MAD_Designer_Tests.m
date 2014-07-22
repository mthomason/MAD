//
//  MAD_Designer_Tests.m
//  MAD Designer Tests
//
//  Created by Michael Thomason on 5/21/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MTDatabaseConnection.h"
#import "MTDataTableFastObjectEnumerator.h"
#import "MTQuery.h"

@interface MAD_Designer_Tests : XCTestCase

@end

@implementation MAD_Designer_Tests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

/*
- (void)testQueryGroupEnumerator {
    NSURL *databaseUrl = [NSURL URLWithString:@""];
    NSArray *columns = @[@"c1", @"c2", @"c3", @"c4", @"c5", @"c6", @"c7"];
    
    NSMutableArray *whereClause = [[NSMutableArray alloc] initWithCapacity:[keys count]];
    for (NSString *key in keys) {
        
        NSInteger sortLevel = groupLevel - 1;
        NSSortDescriptor *sortDescriptor = [[self sortDescriptors] objectAtIndex:sortLevel];
        
        
        NSDictionary *whereStatement = @{@"c" : [sortDescriptor key],
                                         @"v" : key};
        [whereClause addObject:whereStatement];
    }
    
    NSDictionary *querySelect = @{
                                  @(MTQuerySelectFieldKeys) : columnKeys,
                                  @(MTQuerySelectTableName) : [self tableName],
                                  @(MTQuerySelectSortAccending) : @(accending),
                                  @(MTQuerySelectPredicates) : whereClause,
                                  };
    
    MTQuery *query = [[MTQuery alloc] initWithQueryType:MTQueryTypeCacheSelectGroupKeys object: querySelect];
    MTDatabaseConnection *databaseConnection = [MTDatabaseConnection databaseConnectionFactory: databaseUrl];
    MTDataTableFastObjectEnumerator *enumerator = [[MTDataTableFastObjectEnumerator alloc] initWithDatabaseConnection: databaseConnection
                                                                                                              columns: @{}
                                                                                                           columnKeys: @[]
                                                                                                                query: query];
    [enumerator setAddRowId:NO];
    [enumerator setSingleColumnNoWrapper:YES];
    XCTFail(@"No implementation for \"%s\"", __PRETTY_FUNCTION__);
}
 */

@end
