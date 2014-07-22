//
//  MTAstNodeExpressionList.m
//  Scrimpter
//
//  Created by Michael Thomason on 6/30/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTAstNodeExpressionList.h"
#import "MTPair.h"

@implementation MTAstNodeExpressionList

- (id)initWithExpression:(MTAbstractSyntaxTree *)expression andList:(MTAbstractSyntaxTree *)list {
    MTPair *pair = [MTPair pairWithLeft:expression andRight:list];
    self = [super initWithNodeType:SCNodeTypeStatementList andValues:pair];
    if (self) {
        
    }
    return self;
}

- (SCNodeType)nodetype {
    return SCNodeTypeExpressionList;
}

- (MTAbstractSyntaxTree *)expression {
    return [self leftNode];
}

- (MTAbstractSyntaxTree *)expressionList {
    return  [self rightNode];
}

- (MADValue *)evaluate {
    MADValue *result = [[self expression] evaluate];
    if (self.expression.nodetype != SCNodeTypeResult) {
        result = [[self expressionList] evaluate];
    }
    return result;
}

@end
