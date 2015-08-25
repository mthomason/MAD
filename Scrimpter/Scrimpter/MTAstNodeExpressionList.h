//
//  MTAstNodeExpressionList.h
//  Scrimpter
//
//  Created by Michael Thomason on 6/30/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTAbstractSyntaxTree.h"

@interface MTAstNodeExpressionList : MTAbstractSyntaxTree

- (instancetype)initWithExpression:(MTAbstractSyntaxTree *)expression andList:(MTAbstractSyntaxTree *)list;

@end
