//
//  MTAstNodeEmbeddedFunctionCall.h
//  Scrimpter
//
//  Created by Michael Thomason on 6/21/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADScrimpter_MTAstNodeFunctionCallEmbeddedUniaryMinus_h
#define MAD_MADScrimpter_MTAstNodeFunctionCallEmbeddedUniaryMinus_h

#import "MTAbstractSyntaxTree.h"

@interface MTAstNodeFunctionCallEmbeddedUniaryMinus : MTAbstractSyntaxTree

- (instancetype)initWithValueForUniaryMinus:(MTAbstractSyntaxTree *)value;

@end

#endif
