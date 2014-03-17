//
//  libTdsClientTests.m
//  libTdsClientTests
//
//  Created by Michael Thomason on 6/6/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "libTdsClientTests.h"

#include "sybfront.h"
#include "sybdb.h"

#import "MTTdsClient.h"

@implementation libTdsClientTests

- (void)setUp {
    [super setUp];
    
    // Set-up code here.
    
    
}

- (void)tearDown {
    // Tear-down code here.
    
    [super tearDown];
}

- (void)initTds {
    if (dbinit() == FAIL) {
        STFail(@"Failed to init TDS.");
    }
}

- (void)initTdsClient {
    MTTdsClient *tdsClient = [[MTTdsClient alloc] initWithCredentals:nil];
    [tdsClient runQuery:@""];
}

@end
