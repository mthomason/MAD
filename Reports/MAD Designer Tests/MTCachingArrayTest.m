//
//  MTCachingArrayTest.m
//  MAD
//
//  Created by Michael Thomason on 7/5/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MTArrayCached.h"

@interface MTCachingArrayTest : XCTestCase

@property (nonatomic, strong) MTArrayCached *array;

@property (nonatomic, strong) NSString *identifier;

@property (nonatomic, strong) NSString *cat;
@property (nonatomic, strong) NSString *dog;
@property (nonatomic, strong) NSNumber *pi;
@property (nonatomic, strong) NSNumber *yes;
@property (nonatomic, strong) NSValue *rec;

@end

@implementation MTCachingArrayTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.

    [self setCat:@"Cat"];
    [self setDog:@"dog"];
    [self setPi:@3.14];
    [self setYes:@YES];
    [self setRec:[NSValue valueWithCGSize:CGSizeMake(100.0000f, 300.0000f)]];

    [self setIdentifier:@"2398"];
    
    NSURL *urlToCleanup = [MTArrayCached urlForIdentifier:[self identifier]];
    if ([[NSFileManager defaultManager] fileExistsAtPath:[urlToCleanup path]]) {
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtURL:urlToCleanup error:&error];
    }
    
    MTArrayCached *array = [[MTArrayCached alloc] initWithIdentifier:[self identifier]];
    [array addObject:self.cat];
    [array addObject:self.dog];
    [array addObject:self.pi];
    [array addObject:self.yes];
    [array addObject:self.rec];
    [self setArray:array];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    [[self array] removeAllObjects];
    
}

- (void)testCheckValues {
    XCTAssertEqualObjects([[self array] objectAtIndex:0], self.cat, @"Object value check failed.");
    XCTAssertEqualObjects([[self array] objectAtIndex:1], self.dog, @"Object value check failed.");
    XCTAssertEqualObjects([[self array] objectAtIndex:2], self.pi, @"Object value check failed.");
    XCTAssertEqualObjects([[self array] objectAtIndex:3], self.yes, @"Object value check failed.");
    XCTAssertEqualObjects([[self array] objectAtIndex:4], self.rec, @"Object value check failed.");
}

@end
