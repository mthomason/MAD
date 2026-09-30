//
//  MADTests.m
//  MADTests
//
//  Created by Michael Thomason on 9/19/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <objc/runtime.h>
#import <malloc/malloc.h>
#import "MADSectionRepresentation.h"

@interface MADTests : XCTestCase

@end

@implementation MADTests

- (void)setUp {
	[super setUp];
}

- (void)tearDown {
	[super tearDown];
}

- (void)testInstanceSize {
	NSLog(@"size of %@: %zd", NSStringFromClass([MADSectionRepresentation class]), class_getInstanceSize([MADSectionRepresentation class]));
	id sr = [[MADSectionRepresentation alloc] init];
	NSLog(@"size of %@: %zd", NSStringFromClass([MADSectionRepresentation class]), malloc_size((__bridge const void *)sr));
}

@end
