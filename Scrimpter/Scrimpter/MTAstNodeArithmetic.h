//
//  MTAstNodeArithmetic.h
//  Scrimpter
//
//  Created by Michael Thomason on 6/22/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADScrimpter_MTAstNodeArithmetic_h
#define MAD_MADScrimpter_MTAstNodeArithmetic_h

#import "MTAbstractSyntaxTree.h"

@interface MTAstNodeArithmetic : MTAbstractSyntaxTree

- (instancetype)initWithArithmeticProcedure:(SCArithmetic)procedure withValues:(MTPair *)values;

@end

#endif
