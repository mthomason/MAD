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
@property (nonatomic, strong) NSMutableArray *arrayControl;

@property (nonatomic, strong) NSString *identifier;

@property (nonatomic, strong) NSString *cat;
@property (nonatomic, strong) NSString *dog;
@property (nonatomic, strong) NSNumber *pi;
@property (nonatomic, strong) NSNumber *yes;
@property (nonatomic, strong) NSValue *rec;

@property (nonatomic, assign) BOOL firstTime;

@end

@implementation MTCachingArrayTest

- (void)setUp {
    [super setUp];
    
    [self setIdentifier:@"2398"];
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self removeDatabaseFile];
    });

    [self setCat:@"Cat"];
    [self setDog:@"dog"];
    [self setPi:@3.14];
    [self setYes:@YES];
    [self setRec:[NSValue valueWithCGSize:CGSizeMake(100.0000f, 300.0000f)]];
    
    NSMutableArray *arrayControl = [[NSMutableArray alloc] init];
    [self addObjectsToArray:&arrayControl];
    [self setArrayControl:arrayControl];
    
    MTArrayCached *array = [[MTArrayCached alloc] initWithIdentifier:[self identifier]];
    static dispatch_once_t onceToken1;
    dispatch_once(&onceToken1, ^{
        [array beginBulkInserts];
        [self addObjectsToArray:(NSMutableArray **) &array];
        [array endBulkInserts];
    });
    [self setArray:array];
}

- (void)addObjectsToArray:(NSMutableArray **)object {
    [*object addObject:self.cat];
    [*object addObject:self.dog];
    [*object addObject:self.pi];
    [*object addObject:self.yes];
    [*object addObject:self.rec];
}

- (void)tearDown {
    [super tearDown];
}

- (void)removeDatabaseFile {
    NSURL *urlToCleanup = [MTArrayCached urlForIdentifier:[self identifier]];
    if ([[NSFileManager defaultManager] fileExistsAtPath:[urlToCleanup path]]) {
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtURL:urlToCleanup error:&error];
    }
}

- (void)testCheckValues {
    XCTAssertEqualObjects([[self array] objectAtIndex:0], self.cat, @"Object value check failed.");
    XCTAssertEqualObjects([[self array] objectAtIndex:1], self.dog, @"Object value check failed.");
    XCTAssertEqualObjects([[self array] objectAtIndex:2], self.pi, @"Object value check failed.");
    XCTAssertEqualObjects([[self array] objectAtIndex:3], self.yes, @"Object value check failed.");
    XCTAssertEqualObjects([[self array] objectAtIndex:4], self.rec, @"Object value check failed.");
}

- (void)testCount {
    XCTAssertEqual([[self array] count], 5, @"Object value check failed.");
}

- (void)testEnum {
    NSUInteger objCtr = 0;
    for (id obj in [self array]) {
        XCTAssertEqualObjects(obj, [[self arrayControl] objectAtIndex:objCtr], @"Object value check failed.");
        objCtr++;
    }
}

@end
