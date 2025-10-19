//
//  MADDesignerUnitTests.m
//  MADDesignerUnitTests
//
//  Created by Michael Thomason on 3/15/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import <XCTest/XCTest.h>

#import <MADAPI/MADDatabaseConnection.h>

#import <MADAPI/MADDatabase.h>
#import <MADAPI/MADQuery.h>
#import <MAD/MADQueryTest.h>

@interface MADDesignerUnitTests : XCTestCase

@end

@implementation MADDesignerUnitTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    
    MADDatabaseConnection *databaseConnection;
    databaseConnection = [MADDatabaseConnection newDatabaseConnectionWithType: MADDatabaseTypeMySQL
                                                                         host: @"edadb.cqyrz0epxrje.us-east-1.rds.amazonaws.com"
                                                                     database: @"employees"
                                                                         port: 3306];
    
    MADQuery *queryTest = [[MADQueryTest alloc] initWithObject: databaseConnection];
    NSError * __autoreleasing error = NULL;
    BOOL success = [queryTest.database executeQuery:queryTest withError: &error];
    XCTAssertNil(error, @"Got an error (%s): %@", __PRETTY_FUNCTION__, error);
    XCTAssertTrue(success, @"No success here!");
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
