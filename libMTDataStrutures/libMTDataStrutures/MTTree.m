//
//  MTTree.m
//  libMTDataStrutures
//
//  Created by Michael Thomason on 6/21/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTTree.h"

@implementation MTTree

- (id)initWithLeftTree:(MTTree *)left andRightTree:(MTTree *)right {
    self = [super init];
    if (self) {
        [self setLeftNode:left];
        [self setRightNode:right];
    }
    return self;
}

@end
