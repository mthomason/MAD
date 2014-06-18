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

- (void)setUp {
    [super setUp];
    Scrimpter *scrimpter = [Scrimpter new];
    [self setScrimpter:scrimpter];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (BOOL)testScript:(NSString *)script forValue:(id)value error:(NSError **)error {
    __block BOOL valid = NO;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    [[self scrimpter] run:script completion:^(BOOL success, id result, NSError *err) {
        NSLog(@"Result: %@", result);
        valid = success && ([result isEqual:value] || (result == nil && value == nil)) && err == nil;
        *error = err;
        dispatch_semaphore_signal(semaphore);
    }];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    return valid;
}

- (void)testEmpty {
    __autoreleasing NSError *error = nil;
    BOOL success = [self testScript:@"" forValue:nil error:&error];
    XCTAssert(success, @"%s failed with error %@.", __PRETTY_FUNCTION__, error);
}

- (void)testNewLine {
    __autoreleasing NSError *error = nil;
    BOOL success = [self testScript:@"\n" forValue:nil error:&error];
    XCTAssert(success, @"%s failed with error %@.", __PRETTY_FUNCTION__, error);
}

- (void)testNewLineSimicolon {
    __autoreleasing NSError *error = nil;
    BOOL success = [self testScript:@"\n;;\n\n;\n" forValue:nil error:&error];
    XCTAssert(success, @"%s failed with error %@.", __PRETTY_FUNCTION__, error);
}

- (void)test2Plus2 {
    __autoreleasing NSError *error = nil;
    BOOL success = [self testScript:@"return 2+2;" forValue:@(4) error:&error];
    XCTAssert(success, @"%s failed with error %@.", __PRETTY_FUNCTION__, error);
}

- (void)testReturn2Plus2 {
    __autoreleasing NSError *error = nil;
    BOOL success = [self testScript:@"return 2+2;" forValue:@(4) error:&error];
    XCTAssert(success, @"%s failed with error %@.", __PRETTY_FUNCTION__, error);
}

- (void)test2Plus2Pern {
    __autoreleasing NSError *error = nil;
    NSString *script = @"return ((( 2+2) -22) +2 + 20);";
    BOOL success = [self testScript:script forValue:@(4) error:&error];
    XCTAssert(success, @"%s failed with error %@.", __PRETTY_FUNCTION__, error);
}

- (void)testNegativeNumber {
    __autoreleasing NSError *error = nil;
    NSString *script = @"((( 2+2) -22) +2 - (-20)); return 5;";
    BOOL success = [self testScript:script forValue:@(5) error:&error];
    XCTAssert(success, @"%s failed with error %@.", __PRETTY_FUNCTION__, error);
}

- (void)testMultplyDivide {
    __autoreleasing NSError *error = nil;
    NSString *script = @"return 2*2/(2+2);";
    BOOL success = [self testScript:script forValue:@(1) error:&error];
    XCTAssert(success, @"%s failed with error %@.", __PRETTY_FUNCTION__, error);

    script = @"return (2+2)*2/2-2;";
    success = [self testScript:script forValue:@(2) error:&error];
    XCTAssert(success, @"%s failed with error %@.", __PRETTY_FUNCTION__, error);

    script = @"return (2+2*2)/2;";
    success = [self testScript:script forValue:@(3) error:&error];
    XCTAssert(success, @"%s failed with error %@.", __PRETTY_FUNCTION__, error);

    script = @"return 2*2/2+2;";
    success = [self testScript:script forValue:@(4) error:&error];
    XCTAssert(success, @"%s failed with error %@.", __PRETTY_FUNCTION__, error);
}

- (void)testComparson {
    
    __autoreleasing NSError *error = nil;
    NSString *script = @"return 7 + 5 >= 10;";
    BOOL success = [self testScript:script forValue:@(YES) error:&error];
    XCTAssert(success, @"%s failed with error %@.", __PRETTY_FUNCTION__, error);

    script = @"return 7 + 5 <= 10;";
    success = [self testScript:script forValue:@(NO) error:&error];
    XCTAssert(success, @"%s failed with error %@.", __PRETTY_FUNCTION__, error);

    script = @"return 5 < 10;";
    success = [self testScript:script forValue:@(YES) error:&error];
    XCTAssert(success, @"%s failed with error %@.", __PRETTY_FUNCTION__, error);

    script = @"return 5 > 10;";
    success = [self testScript:script forValue:@(NO) error:&error];
    XCTAssert(success, @"%s failed with error %@.", __PRETTY_FUNCTION__, error);

    script = @"return 5 == 10;";
    success = [self testScript:script forValue:@(NO) error:&error];
    XCTAssert(success, @"%s failed with error %@.", __PRETTY_FUNCTION__, error);

    script = @"return 10 == 10;";
    success = [self testScript:script forValue:@(YES) error:&error];
    XCTAssert(success, @"%s failed with error %@.", __PRETTY_FUNCTION__, error);
    
    script = @"return 5 >= 10;";
    success = [self testScript:script forValue:@(NO) error:&error];
    XCTAssert(success, @"%s failed with error %@.", __PRETTY_FUNCTION__, error);

    script = @"return 5 <= 10;";
    success = [self testScript:script forValue:@(YES) error:&error];
    XCTAssert(success, @"%s failed with error %@.", __PRETTY_FUNCTION__, error);

}

- (void)testMultiExpressions {
    __autoreleasing NSError *error = nil;
    NSString *script = @"7 + 5 >= 10;return 2+2;";
    BOOL success = [self testScript:script forValue:@(4) error:&error];
    XCTAssert(success, @"%s failed with error %@.", __PRETTY_FUNCTION__, error);
}

- (void)testConditionIf1 {
    __autoreleasing NSError *error = nil;
    NSString *script = @"if (7 + 5 >= 10) then\n"
                        "   return 1;\n"
                        "else return 0;";
    BOOL success = [self testScript:script forValue:@(1) error:&error];
    XCTAssert(success, @"%s failed with error %@.", __PRETTY_FUNCTION__, error);
}

- (void)testConditionIf2 {
    __autoreleasing NSError *error = nil;
    NSString *script = @"if (7 + 5 <= 10) then\n"
                        "   return 10;\n"
                        "else\nreturn 30;";
    BOOL success = [self testScript:script forValue:@(30) error:&error];
    XCTAssert(success, @"%s failed with error %@.", __PRETTY_FUNCTION__, error);
}

@end
