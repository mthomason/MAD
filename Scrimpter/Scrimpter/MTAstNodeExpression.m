//
//  MTAstNodeExpression.m
//  Scrimpter
//
//  Created by Michael Thomason on 6/23/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTAstNodeExpression.h"
#import "MTPair.h"

@implementation MTAstNodeExpression

- (id)initWithExpression:(MTAbstractSyntaxTree *)node {
    MTPair *p = [[MTPair alloc] initWithLeft:node.leftNode andRight:node.rightNode];
    self = [super initWithNodeType:SCNodeTypeExpression andValues:p];
    if (self) {

    }
    return self;
}

- (MADValue *)evaluate {
    return [self.leftAST evaluate];
}

@end
