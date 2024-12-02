//
//  MTAstNodeExpression.h
//  Scrimpter
//
//  Created by Michael Thomason on 6/23/14.
//  Copyright (c) 2024 Michael Thomason. All rights reserved.
//

#ifndef MAD_MADScrimpter_MTAstNodeExpression_h
#define MAD_MADScrimpter_MTAstNodeExpression_h

#import "MTAbstractSyntaxTree.h"
#import <MADDataStructures/MADDataStructures.h>

@interface MTAstNodeExpression : MTAbstractSyntaxTree

- (instancetype)initWithExpression:(MTAbstractSyntaxTree *)node;

@end

#endif
