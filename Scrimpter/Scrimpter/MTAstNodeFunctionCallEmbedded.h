//
//  MTAstNodeEmbeddedFunctionCall.h
//  Scrimpter
//
//  Created by Michael Thomason on 6/21/14.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_MADScrimpter_MTAstNodeFunctionCallEmbedded_h
#define MAD_MADScrimpter_MTAstNodeFunctionCallEmbedded_h

#import "MTAbstractSyntaxTree.h"
#import <MADDataStructures/MADDataStructures.h>

typedef NS_ENUM(NSUInteger, SCFunctionClass) {
    SCFunctionClassString,
    SCFunctionClassNumber,
    SCFunctionClassBoolean,
};

typedef NS_ENUM(NSUInteger, SCFunctionTypeBoolean) {
    SCFunctionTypeBooleanExclusiveOr
};

typedef NS_ENUM(NSUInteger, SCFunctionTypeString) {
    SCFunctionTypeStringUpper,
    SCFunctionTypeStringLower,
    SCFunctionTypeStringConcat,
};

typedef NS_ENUM(NSUInteger, SCFunctionTypeNumber) {
    SCFunctionTypeNumericSqureRoot,
    SCFunctionTypeNumericPower,
    SCFunctionTypeNumericAbsoluteValue,
    SCFunctionTypeNumericFloor,
    SCFunctionTypeNumericCeiling,
    SCFunctionTypeNumericTruncate,
    SCFunctionTypeNumericRound,
    SCFunctionTypeNumericModulus,
};

@interface MTAstNodeFunctionCallEmbedded : MTAbstractSyntaxTree

- (instancetype)initWithExpression:(MTAbstractSyntaxTree *)expression functionName:(NSString *)functionName andExpressionList:(MTAbstractSyntaxTree *)expressionList;

@end

#endif
