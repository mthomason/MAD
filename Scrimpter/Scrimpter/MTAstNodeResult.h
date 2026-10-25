//
//  MTAstNodeResult.h
//  Scrimpter
//
//  Created by Michael Thomason on 6/23/14.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_MADScrimpter_MTAstNodeResult_h
#define MAD_MADScrimpter_MTAstNodeResult_h

#import "MTAbstractSyntaxTree.h"

@interface MTAstNodeResult : MTAbstractSyntaxTree

- (instancetype)initWithResult:(MTAbstractSyntaxTree *)expression;

@end

#endif
