//
//  MTAbstractSyntaxTree.h
//  Scrimpter
//
//  Created by Michael Thomason on 6/21/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTTree.h"

typedef NS_ENUM(NSInteger, SCNodeType) {
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
    SCNodeTypeSymbolReference,
    SCNodeTypeAssignemnt,
    SCNodeTypeListOfSymbols,
    SCNodeTypeBuiltInFunction,
    SCNodeTypeUserFunction,
};

typedef NS_ENUM(NSInteger, SCCompareson) {
    SCComparesonGreaterThan,
    SCComparesonLessThan,
    SCComparesonEqualTo,
    SCComparesonNotEqualTo,
    SCComparesonGreatThanOrEqualTo,
    SCComparesonLessThanOrEqualTo,
};

@class MTPair;

@interface MTAbstractSyntaxTree : MTTree

@property (nonatomic, assign) SCNodeType nodetype;

@property (nonatomic, strong) MTAbstractSyntaxTree *leftNode;
@property (nonatomic, strong) MTAbstractSyntaxTree *rightNode;

- (id)initWithNodeType:(SCNodeType)type andValues:(MTPair *)values;
- (double)evaluate;

@end
