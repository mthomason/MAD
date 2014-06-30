//
//  ScrimpterTests.m
//  ScrimpterTests
//
//  Created by Michael Thomason on 6/16/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MADScrimpter.h"

@interface ScrimpterTests : XCTestCase

@property (nonatomic, strong) MADScrimpter *scrimpter;

@end

@implementation ScrimpterTests

- (void)setUp {
    [super setUp];
    MADScrimpter *scrimpter = [MADScrimpter new];
    [self setScrimpter:scrimpter];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (BOOL)testScript:(NSString *)script forValue:(id)value error:(NSError **)error {
    return [self testScript:script forValue:value error:error expectsError:NO];
}

- (BOOL)testScript:(NSString *)script forValue:(id)value error:(NSError **)error expectsError:(BOOL)builtToSpill {
    __block BOOL valid = NO;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    [[self scrimpter] run:script completion:^(BOOL success, id result, NSError *err) {
        if (builtToSpill) {
            valid = success == NO && err != nil;
            *error = err;
            NSLog(@"%@", err.userInfo[NSLocalizedDescriptionKey]);
        } else {
            NSLog(@"Result: %@", result);
            valid = success && ([result isEqual:value] || (result == nil && value == nil)) && err == nil;
            *error = err;
        }
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
    BOOL success = [self testScript:@"\n;" forValue:nil error:&error];
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

    script = @"return (7 + 5 <= 10);";
    success = [self testScript:script forValue:@(NO) error:&error];
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
    NSString *script = @"if (7 + 5 >= 10) {\n"
                        "   return 1;\n"
                        "} else { return 0; }";
    BOOL success = [self testScript:script forValue:@(1) error:&error];
    XCTAssert(success, @"%s failed with error %@.", __PRETTY_FUNCTION__, error);
}

- (void)testConditionIf2 {
    __autoreleasing NSError *error = nil;
    NSString *script = @"if (7 + 5 <= 10) {\n"
                        "   return 10;\n"
                        "}else{\nreturn 30;}";
    BOOL success = [self testScript:script forValue:@(30) error:&error];
    XCTAssert(success, @"%s failed with error %@.", __PRETTY_FUNCTION__, error);
}

- (void)testVarable1 {
    __autoreleasing NSError *error = nil;
    NSString *script = @"var i = 10;\n"
                        "return i;";
    BOOL success = [self testScript:script forValue:@(10) error:&error];
    XCTAssert(success, @"%s failed with error %@.", __PRETTY_FUNCTION__, error);
}

- (void)testVarable2 {
    __autoreleasing NSError *error = nil;
    NSString *script = @"var i = 10;\nvar j = 11;var k=12;"
                        "return k;";
    BOOL success = [self testScript:script forValue:@(12) error:&error];
    XCTAssert(success, @"%s failed with error %@.", __PRETTY_FUNCTION__, error);
}

- (void)testVarable3 {
    __autoreleasing NSError *error = nil;
    NSString *script = @"var i = 10;\nvar j = 11;var k=12;"
    "return j;";
    BOOL success = [self testScript:script forValue:@(11) error:&error];
    XCTAssert(success, @"%s failed with error %@.", __PRETTY_FUNCTION__, error);
}

- (void)testVarable4 {
    __autoreleasing NSError *error = nil;
    NSString *script = @"var i = 10;\nvar j = 11;var k=12;"
    "return i;";
    BOOL success = [self testScript:script forValue:@(10) error:&error];
    XCTAssert(success, @"%s failed with error %@.", __PRETTY_FUNCTION__, error);
}

- (void)testVarable5 {
    __autoreleasing NSError *error = nil;
    NSString *script = @"var i = 10;\nj = 11;var k=12;j=13;k=14;"
    "return j;";
    BOOL success = [self testScript:script forValue:@(13) error:&error];
    XCTAssert(success, @"%s failed with error %@.", __PRETTY_FUNCTION__, error);
}

- (void)testVarable6 {
    __autoreleasing NSError *error = nil;
    NSString *script = @"var i = 10;\nj = 11;var k=12;j=13;k=14;"
    "return k;";
    BOOL success = [self testScript:script forValue:@(14) error:&error];
    XCTAssert(success, @"%s failed with error %@.", __PRETTY_FUNCTION__, error);
}

- (void)testVarable7 {
    __autoreleasing NSError *error = nil;
    NSString *script = @"i = 10;\nj = 11;k=12;j=13;k=14;"
    "return k;";
    BOOL success = [self testScript:script forValue:@(14) error:&error];
    XCTAssert(success, @"%s failed with error %@.", __PRETTY_FUNCTION__, error);
}

- (void)testVarable8 {
    __autoreleasing NSError *error = nil;
    NSString *script = @"i = 10;\nj = 11;k=12;j=13;k=14;if k == 12 { i = 7;}"
    "return i;";
    BOOL success = [self testScript:script forValue:@(10) error:&error];
    XCTAssert(success, @"%s failed with error %@.", __PRETTY_FUNCTION__, error);
}

- (void)testVarable9 {
    __autoreleasing NSError *error = nil;
    NSString *script = @"i = 10;\nj = 11;k=12;j=13;k=14;if (k == 12) { i = 7; } else { i = 10; }"
    "return i;";
    BOOL success = [self testScript:script forValue:@(10) error:&error];
    XCTAssert(success, @"%s failed with error %@.", __PRETTY_FUNCTION__, error);
}

- (void)testVarable10 {
    __autoreleasing NSError *error = nil;
    NSString *script = @"i = 10;\nj = 11;k=12;j=13;k=14;if (k != 14) { i = 7; } else { i = 10; }"
    "return i;";
    BOOL success = [self testScript:script forValue:@(10) error:&error];
    XCTAssert(success, @"%s failed with error %@.", __PRETTY_FUNCTION__, error);
}

- (void)testVarable11 {
    __autoreleasing NSError *error = nil;
    NSString *script = @"i = 11;\nj = 11;k=12;j=13;k=14;"
    "if (k != 14) { i = 7; } else { i = 20; }"
    "return i;";
    BOOL success = [self testScript:script forValue:@(20) error:&error];
    XCTAssert(success, @"%s failed with error %@.", __PRETTY_FUNCTION__, error);
}

- (void)testVarable12 {
    __autoreleasing NSError *error = nil;
    NSString *script = @"i = 11;\nj = 11;k=12;j=13;k=14;"
    "if (j == 13) { i = 7; } else { i = 20; }"
    "return i;";
    BOOL success = [self testScript:script forValue:@(7) error:&error];
    XCTAssert(success, @"%s failed with error %@.", __PRETTY_FUNCTION__, error);
}

- (void)testStringVarable1 {
    __autoreleasing NSError *error = nil;
    NSString *script = @"i = \"11\"; return i;";
    BOOL success = [self testScript:script forValue:@"11" error:&error];
    XCTAssert(success, @"%s failed with error %@.", __PRETTY_FUNCTION__, error);
}


- (void)testStringVarable2 {
    __autoreleasing NSError *error = nil;
    NSString *script = @"i = \"11\"; if (i == 11) { return true; } else { return false; }";
    BOOL success = [self testScript:script forValue:@NO error:&error];
    XCTAssert(success, @"%s failed with error %@.", __PRETTY_FUNCTION__, error);
}

- (void)testStringVarable3 {
    __autoreleasing NSError *error = nil;
    NSString *script = @"i = \"11\"; j = \"111\"; if (i == j) { return true; } else { return false; }";
    BOOL success = [self testScript:script forValue:@NO error:&error];
    XCTAssert(success, @"%s failed with error %@.", __PRETTY_FUNCTION__, error);
}

- (void)testStringVarable4 {
    __autoreleasing NSError *error = nil;
    NSString *script = @"i = \"11\"; j = \"11\"; if (i == j) { return true; } else { return false; }";
    BOOL success = [self testScript:script forValue:@YES error:&error];
    XCTAssert(success, @"%s failed with error %@.", __PRETTY_FUNCTION__, error);
}

- (void)testStringVarable5 {
    __autoreleasing NSError *error = nil;
    NSString *script = @"i = \"11\"; j = \"111\"; if (i >= j) { return true; } else { return false; }";
    BOOL success = [self testScript:script forValue:@NO error:&error];
    XCTAssert(success, @"%s failed with error %@.", __PRETTY_FUNCTION__, error);
}

- (void)testStringVarable6 {
    __autoreleasing NSError *error = nil;
    NSString *script = @"i = \"11\"; j = \"111\"; if (i < j) { return true; } else { return false; }";
    BOOL success = [self testScript:script forValue:@YES error:&error];
    XCTAssert(success, @"%s failed with error %@.", __PRETTY_FUNCTION__, error);
}

- (void)testStringVarable7 {
    __autoreleasing NSError *error = nil;
    NSString *script = @"i = \"11\"; j = \"111\"; if (i <= j) { return true; } else { return false; }";
    BOOL success = [self testScript:script forValue:@YES error:&error];
    XCTAssert(success, @"%s failed with error %@.", __PRETTY_FUNCTION__, error);
}

- (void)testComment {
    __autoreleasing NSError *error = nil;
    NSString *script = @"i = 11;\n"
                       @"//i = 111;\n"
                       @"return i;";
    BOOL success = [self testScript:script forValue:@(11) error:&error];
    XCTAssert(success, @"%s failed with error %@.", __PRETTY_FUNCTION__, error);
}

- (void)testPower {
    __autoreleasing NSError *error = nil;
    NSString *script = @"return (2.0000+2.00).power(2);";
    BOOL success = [self testScript:script forValue:@(16) error:&error];
    XCTAssert(success, @"%s failed with error %@.", __PRETTY_FUNCTION__, error);
}

- (void)testPower2 {
    __autoreleasing NSError *error = nil;
    NSString *script = @"var i = 2+2-2+2; return i.power(2+2.00-2+2);";
    BOOL success = [self testScript:script forValue:@(256) error:&error];
    XCTAssert(success, @"%s failed with error %@.", __PRETTY_FUNCTION__, error);
}

- (void)testError {
    __autoreleasing NSError *error = nil;
    NSString *script = @"$.$...i = 11;\n"
    @"//i = 111;\n"
    @"return i;";
    BOOL success = [self testScript:script forValue:@(11) error:&error expectsError:YES];
    XCTAssert(success, @"%s failed with error %@.", __PRETTY_FUNCTION__, error);
}

@end
