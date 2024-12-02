//
//  MTAstNodeExpressionList.m
//  Scrimpter
//
//  Created by Michael Thomason on 6/30/14.
//  Copyright (c) 2024 Michael Thomason. All rights reserved.
//

#import "MTAstNodeExpressionList.h"

@implementation MTAstNodeExpressionList

- (instancetype)initWithExpression:(MTAbstractSyntaxTree *)expression andList:(MTAbstractSyntaxTree *)list {
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
    return self.leftAST;
}

- (MTAbstractSyntaxTree *)expressionList {
    return self.rightAST;
}

- (MADValue *)evaluate {
    MADValue *result = [[self expression] evaluate];
    if (self.expression.nodetype != SCNodeTypeResult) {
        result = [[self expressionList] evaluate];
    }
    return result;
}

@end
