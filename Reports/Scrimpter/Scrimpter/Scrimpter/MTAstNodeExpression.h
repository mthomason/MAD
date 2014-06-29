//
//  MTAstNodeExpression.h
//  Scrimpter
//
//  Created by Michael Thomason on 6/23/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADScrimpter_MTAstNodeExpression_h
#define MAD_MADScrimpter_MTAstNodeExpression_h

#import "MTAbstractSyntaxTree.h"

@interface MTAstNodeExpression : MTAbstractSyntaxTree

- (id)initWithNode:(MTAbstractSyntaxTree *)node;

@end

#endif
