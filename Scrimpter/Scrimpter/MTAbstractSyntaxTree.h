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
    SCNodeTypeSymbolList,
    SCNodeTypeIf,
    SCNodeTypeWhile,
    SCNodeTypeResult,
    SCNodeTypeNumberValue,
    SCNodeTypeStringValue,
    SCNodeTypeBooleanValue,
    SCNodeTypeSymbolReference,
    SCNodeTypeAssignemnt,
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

typedef NS_ENUM(NSInteger, SCArithmetic) {
    SCArithmeticAdd,
    SCArithmeticSubtract,
    SCArithmeticMultiply,
    SCArithmeticDivide,
};

@class MTPair, MADValue, MADSymbolReference, MADSymbol;

@interface MTAbstractSyntaxTree : MTTree

@property (nonatomic, assign) SCNodeType nodetype;
@property (readonly) MTAbstractSyntaxTree *leftAST;
@property (readonly) MTAbstractSyntaxTree *rightAST;

- (id)initWithNodeType:(SCNodeType)type andValues:(MTPair *)values;
- (MADValue *)evaluate;


//MTAstNodeFlow
- (instancetype)initConditionalWithIfList:(MTAbstractSyntaxTree *)iflist thenList:(MTAbstractSyntaxTree *)thenlist andCondition:(MTAbstractSyntaxTree *)condition;
- (instancetype)initLoopWithList:(MTAbstractSyntaxTree *)list andCondition:(MTAbstractSyntaxTree *)condition;

//MTAstArithmetic
- (instancetype)initWithArithmeticProcedure:(SCArithmetic)procedure withValues:(MTPair *)values;

//MTAstNodeComparson
- (instancetype)initWithComparson:(SCCompareson)comparson ofValues:(MTPair *)values;

//MTAstNodeNumberValue
- (instancetype)initWithNumber:(NSNumber *)number;

//MTAstNodeStringValue
- (instancetype)initWithString:(NSString *)string;

//MTAstNodeBoolValue
- (instancetype)initWithBool:(bool)b;

//MTAstNodeSymbolReference
- (instancetype)initWithSymbolReference:(MADSymbolReference *)symbol;

//MTAstNodeResult
- (instancetype)initWithResult:(MTAbstractSyntaxTree *)expression;

//MTAstNodeSymbolAsignNumber
- (instancetype)initWithSymbol:(MADSymbol *)symbol andValue:(MTAbstractSyntaxTree *)value;

//MTAstNodeExpression
- (instancetype)initWithExpression:(MTAbstractSyntaxTree *)node;

//MTAstNodeStatement
- (instancetype)initWithStatement:(MTAbstractSyntaxTree *)node;

//MTAstNodeStatementList
- (instancetype)initWithStatement:(MTAbstractSyntaxTree *)statement andList:(MTAbstractSyntaxTree *)list;

//MTAstNodeExpressionList
- (instancetype)initWithExpression:(MTAbstractSyntaxTree *)expression andList:(MTAbstractSyntaxTree *)list;

//MTAstNodeFunctionCallEmbedded
- (instancetype)initWithExpression:(MTAbstractSyntaxTree *)expression functionName:(NSString *)functionName andExpressionList:(MTAbstractSyntaxTree *)expressionList;

//MTAstNodeFunctionCallEmbeddedUniaryMinus
- (instancetype)initWithValueForUniaryMinus:(MTAbstractSyntaxTree *)value;

@end

#endif
