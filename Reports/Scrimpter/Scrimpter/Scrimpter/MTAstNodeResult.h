//
//  MTAstNodeResult.h
//  Scrimpter
//
//  Created by Michael Thomason on 6/23/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTAbstractSyntaxTree.h"

@interface MTAstNodeResult : MTAbstractSyntaxTree

- (id)initWithExpression:(MTAbstractSyntaxTree *)expression;

@end
