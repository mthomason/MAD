//
//  MTAstNodeExpressionList.h
//  Scrimpter
//
//  Created by Michael Thomason on 6/30/14.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MTAbstractSyntaxTree.h"
#import <MADDataStructures/MADDataStructures.h>

@interface MTAstNodeExpressionList : MTAbstractSyntaxTree

- (instancetype)initWithExpression:(MTAbstractSyntaxTree *)expression andList:(MTAbstractSyntaxTree *)list;

@end
