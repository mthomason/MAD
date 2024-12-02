//
//  MTAstNodeExpression.m
//  Scrimpter
//
//  Created by Michael Thomason on 6/23/14.
//  Copyright (c) 2024 Michael Thomason. All rights reserved.
//

#import "MTAstNodeExpression.h"

@implementation MTAstNodeExpression

- (instancetype)initWithExpression:(MTAbstractSyntaxTree *)node {
    MTPair *p = [[MTPair alloc] initWithLeft:node andRight:nil];
    self = [super initWithNodeType:SCNodeTypeExpression andValues:p];
    if (self) {

    }
    return self;
}

- (MADValue *)evaluate {
    return [self.leftAST evaluate];
}

@end
