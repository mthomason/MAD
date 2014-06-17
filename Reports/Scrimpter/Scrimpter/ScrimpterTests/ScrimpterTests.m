//
//  ScrimpterTests.m
//  ScrimpterTests
//
//  Created by Michael Thomason on 6/16/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Scrimpter.h"

@interface ScrimpterTests : XCTestCase

@end

@implementation ScrimpterTests

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

- (void)testExample
{
    
    Scrimpter *scrimpter = [Scrimpter new];
    [scrimpter run:@"2+2"];
    [scrimpter run:@"2 + 2"];
    [scrimpter run:@"((2 + 2 - 5 + 5) / 4)+3\n"];
    [scrimpter run:@"2+2" completion:^(BOOL success, id result, NSError *error) {
        NSLog(@"Success %d %@ %@", success, result, error);
    }];
    //XCTFail(@"No implementation for \"%s\"", __PRETTY_FUNCTION__);
}

@end
