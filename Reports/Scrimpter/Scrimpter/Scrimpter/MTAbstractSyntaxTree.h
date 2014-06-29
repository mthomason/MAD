//
//  MTAbstractSyntaxTree.h
//  Scrimpter
//
//  Created by Michael Thomason on 6/21/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADScrimpter_MTAbstractSyntaxTree_h
#define MAD_MADScrimpter_MTAbstractSyntaxTree_h

#import "MTTree.h"

typedef NS_ENUM(NSUInteger, SCNodeType) {
    SCNodeTypeArithmetic,
    SCNodeTypeComparison,
    SCNodeTypeUnaryMinus,
    SCNodeTypeExpression,
    SCNodeTypeExpressionList,
    SCNodeTypeStatement,
    SCNodeTypeStatementList,
    SCNodeTypeIf,
    SCNodeTypeWhile,
    SCNodeTypeResult,
    SCNodeTypeNumberValue,
    SCNodeTypeStringValue,
    SCNodeTypeBooleanValue,
    SCNodeTypeSymbolReference,
    SCNodeTypeAssignemnt,
    SCNodeTypeListOfSymbols,
    SCNodeTypeBuiltInFunction,
    SCNodeTypeUserFunction,
};

typedef NS_ENUM(NSUInteger, SCCompareson) {
    SCComparesonGreaterThan,
    SCComparesonLessThan,
    SCComparesonEqualTo,
    SCComparesonNotEqualTo,
    SCComparesonGreatThanOrEqualTo,
    SCComparesonLessThanOrEqualTo,
};

@class MTPair, MADValue;

@interface MTAbstractSyntaxTree : MTTree

@property (nonatomic, assign) SCNodeType nodetype;

@property (nonatomic, strong) MTAbstractSyntaxTree *leftNode;
@property (nonatomic, strong) MTAbstractSyntaxTree *rightNode;

- (id)initWithNodeType:(SCNodeType)type andValues:(MTPair *)values;
- (MADValue *)evaluate;

@end

#endif
