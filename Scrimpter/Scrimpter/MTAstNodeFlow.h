//
//  MTAstNodeFlow.h
//  Scrimpter
//
//  Created by Michael Thomason on 6/21/14.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_MADScrimpter_MTAstNodeFlow_h
#define MAD_MADScrimpter_MTAstNodeFlow_h

#import "MTAbstractSyntaxTree.h"

typedef NS_ENUM(NSInteger, SCFlowType) {
    SCFlowTypeIf,
    SCFlowTypeWhile,
};

@class MTAstNodeComparson;

@interface MTAstNodeFlow : MTAbstractSyntaxTree

@property (nonatomic, strong, readonly) MTAbstractSyntaxTree *condition;

- (instancetype)initConditionalWithIfList:(MTAbstractSyntaxTree *)iflist thenList:(MTAbstractSyntaxTree *)thenlist andCondition:(MTAbstractSyntaxTree *)condition;
- (instancetype)initLoopWithList:(MTAbstractSyntaxTree *)list andCondition:(MTAbstractSyntaxTree *)condition;

@end

#endif
