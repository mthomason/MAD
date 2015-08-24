//
//  MTAstNodeFlow.h
//  Scrimpter
//
//  Created by Michael Thomason on 6/21/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
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

- (id)initConditionalWithIfList:(MTAbstractSyntaxTree *)iflist thenList:(MTAbstractSyntaxTree *)thenlist andCondition:(MTAbstractSyntaxTree *)condition;
- (id)initLoopWithList:(MTAbstractSyntaxTree *)list andCondition:(MTAbstractSyntaxTree *)condition;

@end

#endif
