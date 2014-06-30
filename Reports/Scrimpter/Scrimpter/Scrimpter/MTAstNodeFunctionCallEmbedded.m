//
//  MTAstNodeEmbeddedFunctionCall.m
//  Scrimpter
//
//  Created by Michael Thomason on 6/21/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTAstNodeFunctionCallEmbedded.h"
#import "MTPair.h"
#import "MADValue.h"

@interface MTAstNodeFunctionCallEmbedded ()

@property (nonatomic, assign) SCFunctionType functionType;

@end

@implementation MTAstNodeFunctionCallEmbedded

- (id)initWithExpression:(MTAbstractSyntaxTree *)expression functionName:(NSString *)functionName andExpressionList:(MTAbstractSyntaxTree *)expressionList {
    MTPair *pair = [MTPair pairWithLeft:expression andRight:expressionList];
    self = [super initWithNodeType:SCNodeTypeBuiltInFunction andValues:pair];
    if (self) {
        
    }
    return self;
}

- (SCNodeType)nodetype {
    return SCNodeTypeBuiltInFunction;
}

- (MADValue *)evaluate {
    MADValue *result;
    switch (self.functionType) {
        case SCFunctionTypeUniaryMinus:
            result = [MTAstNodeFunctionCallEmbedded uniaryMinus:[[self leftNode] evaluate]];
            break;
        default:
            result = [[self leftNode] evaluate];
            break;
    }
    return result;
}

+ (MADValue *)uniaryMinus:(MADValue *)value {
    NSNumber *um = [NSNumber numberWithDouble: -[[value value] doubleValue]];
    return [MADValue value:um withType:SCVarableTypeDouble];
}

@end
