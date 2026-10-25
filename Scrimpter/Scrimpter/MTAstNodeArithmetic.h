//
//  MTAstNodeArithmetic.h
//  Scrimpter
//
//  Created by Michael Thomason on 6/22/14.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_MADScrimpter_MTAstNodeArithmetic_h
#define MAD_MADScrimpter_MTAstNodeArithmetic_h

#import "MTAbstractSyntaxTree.h"

@interface MTAstNodeArithmetic : MTAbstractSyntaxTree

- (instancetype)initWithArithmeticProcedure:(SCArithmetic)procedure withValues:(MTPair *)values;

@end

#endif
