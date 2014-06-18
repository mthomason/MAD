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

@property (nonatomic, strong) Scrimpter *scrimpter;

@end

@implementation ScrimpterTests

- (void)setUp
{
    [super setUp];
    Scrimpter *scrimpter = [Scrimpter new];
    [self setScrimpter:scrimpter];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testEmpty {
    [[self scrimpter] run:@"" completion:^(BOOL success, id result, NSError *error) {
        XCTAssert(success, @"%s failed with error %@.", __PRETTY_FUNCTION__, error);
    }];
}

- (void)testNewLine {
    [[self scrimpter] run:@"\n" completion:^(BOOL success, id result, NSError *error) {
        XCTAssert(success, @"%s failed with error %@.", __PRETTY_FUNCTION__, error);
    }];
}

- (void)testNewLineSimicolon {
    [[self scrimpter] run:@"\n;;\n\n;\n" completion:^(BOOL success, id result, NSError *error) {
        XCTAssert(success, @"%s failed with error %@.", __PRETTY_FUNCTION__, error);
    }];
}

- (void)test2Plus2 {
    [[self scrimpter] run:@"2+2;" completion:^(BOOL success, id result, NSError *error) {
        XCTAssert(success, @"%s failed with error %@.", __PRETTY_FUNCTION__, error);
        XCTAssert([result integerValue] == 4, @"Invalid result %@", result);
    }];
}

- (void)test2Plus2Pern {
    [[self scrimpter] run:@"((( 2+2) -22) +2 + 20);" completion:^(BOOL success, id result, NSError *error) {
        XCTAssert(success, @"%s failed with error %@.", __PRETTY_FUNCTION__, error);
        XCTAssert([result integerValue] == 4, @"Invalid result %@", result);
    }];
}

- (void)testNegativeNumber {
    [[self scrimpter] run:@"return ((( 2+2) -22) +2 - (-20));" completion:^(BOOL success, id result, NSError *error) {
        XCTAssert(success, @"%s failed with error %@.", __PRETTY_FUNCTION__, error);
        XCTAssert([result integerValue] == 4, @"Invalid result %@", result);
    }];
}

- (void)testMultplyDivide {
    [[self scrimpter] run:@"2*2/(2+2);" completion:^(BOOL success, id result, NSError *error) {
        XCTAssert(success, @"%s failed with error %@.", __PRETTY_FUNCTION__, error);
        XCTAssert([result integerValue] == 1, @"Invalid result %@", result);
    }];
    [[self scrimpter] run:@"(2+2)*2/2-2;" completion:^(BOOL success, id result, NSError *error) {
        XCTAssert(success, @"%s failed with error %@.", __PRETTY_FUNCTION__, error);
        XCTAssert([result integerValue] == 2, @"Invalid result %@", result);
    }];
    [[self scrimpter] run:@"(2+2*2)/2;" completion:^(BOOL success, id result, NSError *error) {
        XCTAssert(success, @"%s failed with error %@.", __PRETTY_FUNCTION__, error);
        XCTAssert([result integerValue] == 3, @"Invalid result %@", result);
    }];
    [[self scrimpter] run:@"2*2/2+2;" completion:^(BOOL success, id result, NSError *error) {
        XCTAssert(success, @"%s failed with error %@.", __PRETTY_FUNCTION__, error);
        XCTAssert([result integerValue] == 4, @"Invalid result %@", result);
    }];
    
}

- (void)testComparson {
    [[self scrimpter] run:@"7 + 5 >= 10;" completion:^(BOOL success, id result, NSError *error) {
        XCTAssert(success, @"%s failed with error %@.", __PRETTY_FUNCTION__, error);
        XCTAssert([result boolValue], @"Invalid result %@", result);
    }];
    [[self scrimpter] run:@"5 < 10;" completion:^(BOOL success, id result, NSError *error) {
        XCTAssert(success, @"%s failed with error %@.", __PRETTY_FUNCTION__, error);
        XCTAssert([result boolValue], @"Invalid result %@", result);
    }];
    [[self scrimpter] run:@"5 > 10;" completion:^(BOOL success, id result, NSError *error) {
        XCTAssert(success, @"%s failed with error %@.", __PRETTY_FUNCTION__, error);
        XCTAssert([result boolValue] == NO, @"Invalid result %@", result);
    }];
    [[self scrimpter] run:@"5 == 10;" completion:^(BOOL success, id result, NSError *error) {
        XCTAssert(success, @"%s failed with error %@.", __PRETTY_FUNCTION__, error);
        XCTAssert([result boolValue] == NO, @"Invalid result %@", result);
    }];
    [[self scrimpter] run:@"5 >= 10;" completion:^(BOOL success, id result, NSError *error) {
        XCTAssert(success, @"%s failed with error %@.", __PRETTY_FUNCTION__, error);
        XCTAssert([result boolValue] == NO, @"Invalid result %@", result);
    }];
    [[self scrimpter] run:@"5 <= 10;" completion:^(BOOL success, id result, NSError *error) {
        XCTAssert(success, @"%s failed with error %@.", __PRETTY_FUNCTION__, error);
        XCTAssert([result boolValue], @"Invalid result %@", result);
    }];

}

- (void)testMultiExpressions {
    [[self scrimpter] run:@"7 + 5 >= 10;2+2;" completion:^(BOOL success, id result, NSError *error) {
        XCTAssert(success, @"%s failed with error %@.", __PRETTY_FUNCTION__, error);
        XCTAssert([result boolValue], @"Invalid result %@", result);
    }];
}

@end
