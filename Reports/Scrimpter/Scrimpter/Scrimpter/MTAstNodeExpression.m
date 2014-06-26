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

- (id)initWithNode:(MTAbstractSyntaxTree *)node {
    MTPair *pair = [MTPair pairWithLeft:node andRight:nil];
    self = [super initWithNodeType:SCNodeTypeExpression andValues:pair];
    if (self) {

    }
    return self;
}

- (MADValue *)evaluate {
    return [[self leftNode] evaluate];
}

@end
