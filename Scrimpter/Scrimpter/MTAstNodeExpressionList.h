//
//  MTAstNodeExpressionList.h
//  Scrimpter
//
//  Created by Michael Thomason on 6/30/14.
//  Copyright (c) 2024 Michael Thomason. All rights reserved.
//

#import "MTAbstractSyntaxTree.h"
#import <MADDataStructures/MADDataStructures.h>

@interface MTAstNodeExpressionList : MTAbstractSyntaxTree

- (instancetype)initWithExpression:(MTAbstractSyntaxTree *)expression andList:(MTAbstractSyntaxTree *)list;

@end
