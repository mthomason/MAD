//
//  MTAbstractSyntaxTree.m
//  Scrimpter
//
//  Created by Michael Thomason on 6/21/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTAbstractSyntaxTree.h"
#import "MTPair.h"
#import "MTAstNodeSymbolAsignNumber.h"
#import "MADValue.h"
#import "MTAstNodeFlow.h"
#import "MTAstNodeArithmetic.h"
#import "MTAstNodeComparson.h"
#import "MTAstNodeNumberValue.h"
#import "MTAstNodeStringValue.h"
#import "MTAstNodeBoolValue.h"
#import "MTAstNodeSymbolReference.h"
#import "MTAstNodeResult.h"
#import "MTAstNodeExpression.h"
#import "MTAstNodeStatement.h"
#import "MTAstNodeStatementList.h"
#import "MTAstNodeExpressionList.h"
#import "MTAstNodeFunctionCallEmbedded.h"
#import "MTAstNodeFunctionCallEmbeddedUniaryMinus.h"

@implementation MTAbstractSyntaxTree

- (id)initWithNodeType:(SCNodeType)type andValues:(MTPair *)values {
    self = [super initWithLeftTree:[values left] andRightTree:[values right]];
    if (self) {
        [self setNodetype:type];
    }
    return self;
}

- (MADValue *)evaluate {
    return [MADValue value:nil withType:SCVarableTypeNull];
}

// MARK: MTAstNodeFlow

- (instancetype)initConditionalWithIfList:(MTAbstractSyntaxTree *)iflist thenList:(MTAbstractSyntaxTree *)thenlist andCondition:(MTAbstractSyntaxTree *)condition {
    MTAstNodeFlow *result = [[MTAstNodeFlow alloc] initConditionalWithIfList:iflist thenList:thenlist andCondition:condition];
    return result;
}
- (instancetype)initLoopWithList:(MTAbstractSyntaxTree *)list andCondition:(MTAbstractSyntaxTree *)condition {
    MTAstNodeFlow *result = [[MTAstNodeFlow alloc] initLoopWithList:list andCondition:condition];
    return result;
}

// MARK: MTAstNodeArithmetic

- (instancetype)initWithArithmeticProcedure:(SCArithmetic)procedure withValues:(MTPair *)values {
    MTAstNodeArithmetic *result = [[MTAstNodeArithmetic alloc] initWithArithmeticProcedure:procedure withValues:values];
    return result;
}

// MARK: MTAstNodeComparson

- (instancetype)initWithComparson:(SCCompareson)comparson ofValues:(MTPair *)values {
    MTAstNodeComparson *result = [[MTAstNodeComparson alloc] initWithComparson:comparson ofValues:values];
    return result;
}

// MARK: MTAstNodeNumberValue
- (instancetype)initWithNumber:(double)number {
    MTAstNodeNumberValue *node = [[MTAstNodeNumberValue alloc] initWithNumber:number];
    return node;
}

// MARK: MTAstNodeStringValue
- (instancetype)initWithString:(NSString *)string {
    MTAstNodeStringValue *node = [[MTAstNodeStringValue alloc] initWithString:string];
    return node;
}

// MARK: MTAstNodeBoolValue
- (instancetype)initWithBool:(bool)boolean {
    MTAstNodeBoolValue *node = [[MTAstNodeBoolValue alloc] initWithBool:boolean];
    return node;
}

// MARK: MTAstNodeSymbolReference
- (instancetype)initWithSymbolReference:(MADSymbolReference *)symbol {
    MTAstNodeSymbolReference *node = [[MTAstNodeSymbolReference alloc] initWithSymbolReference:symbol];
    return node;
}

// MARK: MTAstNodeResult
- (instancetype)initWithResult:(MTAbstractSyntaxTree *)expression {
    MTAstNodeResult *node = [[MTAstNodeResult alloc] initWithResult:expression];
    return node;
}

// MARK: MTAstNodeSymbolAsignNumber
- (instancetype)initWithSymbol:(MADSymbol *)symbol andValue:(MTAbstractSyntaxTree *)value {
    MTAstNodeSymbolAsignNumber *node = [[MTAstNodeSymbolAsignNumber alloc] initWithSymbol:symbol andValue:value];
    return node;
}

//MTAstNodeExpression
- (instancetype)initWithExpression:(MTAbstractSyntaxTree *)expression {
    MTAstNodeExpression *node = [[MTAstNodeExpression alloc] initWithExpression:expression];
    return node;
}

//MTAstNodeStatement
- (instancetype)initWithStatement:(MTAbstractSyntaxTree *)statement {
    MTAstNodeStatement *node = [[MTAstNodeStatement alloc] initWithStatement:statement];
    return node;
}

//MTAstNodeStatementList
- (instancetype)initWithStatement:(MTAbstractSyntaxTree *)statement andList:(MTAbstractSyntaxTree *)list {
    MTAstNodeStatementList *node = [[MTAstNodeStatementList alloc] initWithStatement:statement andList:list];
    return node;
}

//MTAstNodeExpressionList
- (instancetype)initWithExpression:(MTAbstractSyntaxTree *)expression andList:(MTAbstractSyntaxTree *)list {
    MTAstNodeStatementList *node = [[MTAstNodeStatementList alloc] initWithExpression:expression andList:list];
    return node;
}

//MTAstNodeFunctionCallEmbedded
- (instancetype)initWithExpression:(MTAbstractSyntaxTree *)expression functionName:(NSString *)functionName andExpressionList:(MTAbstractSyntaxTree *)expressionList {
    MTAstNodeFunctionCallEmbedded *node = [[MTAstNodeFunctionCallEmbedded alloc] initWithExpression:expression functionName:functionName andExpressionList:expressionList];
    return node;
}

//MTAstNodeFunctionCallEmbeddedUniaryMinus
- (instancetype)initWithValueForUniaryMinus:(MTAbstractSyntaxTree *)value {
    MTAstNodeFunctionCallEmbeddedUniaryMinus *node = [[MTAstNodeFunctionCallEmbeddedUniaryMinus alloc] initWithValueForUniaryMinus:value];
    return node;
}

@end
