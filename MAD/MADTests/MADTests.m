//
//  MADTests.m
//  MADTests
//
//  Created by Michael Thomason on 9/19/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <MADSqlite3/sqlite3.h>
#import "MTDatabaseSqlite3.h"
#import <objc/runtime.h>
#import <malloc/malloc.h>
#import "MADSectionRepresentation.h"

@interface MADTests : XCTestCase

@end

@implementation MADTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testInstanceSize {
    NSLog(@"size of %@: %zd", NSStringFromClass([MADSectionRepresentation class]), class_getInstanceSize([MADSectionRepresentation class]));
    id sr = [[MADSectionRepresentation alloc] init];
    NSLog(@"size of %@: %zd", NSStringFromClass([MADSectionRepresentation class]), malloc_size((__bridge const void *)sr));
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

- (void)testSqlite3ErrorMessage {
    const char *errorName = NULL, *errorMessage = NULL;
    mad_sqlite3Err(SQLITE_OK, &errorName, &errorMessage);
    NSString *fullMessage = [[NSString alloc] initWithFormat:@"%s: %s", errorName, errorMessage];
    NSLog(@"%@", fullMessage);
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
