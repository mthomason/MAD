//
//  MTTree.m
//  libMTDataStrutures
//
//  Created by Michael Thomason on 6/21/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTTree.h"

@implementation MTTree

- (instancetype)initWithLeftTree:(MTTree *)left andRightTree:(MTTree *)right {
    if (self = [self init]) {
        self.leftNode = left;
        self.rightNode = right;
    }
    return self;
}

@end
