//
//  MTAstNodeResult.m
//  Scrimpter
//
//  Created by Michael Thomason on 6/23/14.
//  Copyright (c) 2024 Michael Thomason. All rights reserved.
//

#import "MTAstNodeResult.h"

@implementation MTAstNodeResult

- (instancetype)initWithResult:(MTAbstractSyntaxTree *)expression {
    self = [super initWithLeftTree:expression andRightTree:nil];
    if (self) {
        [self setNodetype:SCNodeTypeResult];
    }
    return self;
}

- (MTAbstractSyntaxTree *)expression {
    return self.leftAST;
}

- (MADValue *)evaluate {
    return [[self expression] evaluate];
}

@end
