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

@property (nonatomic, strong) NSString *functionName;

@end

@implementation MTAstNodeFunctionCallEmbedded

- (id)initWithExpression:(MTAbstractSyntaxTree *)expression functionName:(NSString *)functionName andExpressionList:(MTAbstractSyntaxTree *)expressionList {
    MTPair *pair = [MTPair pairWithLeft:expression andRight:expressionList];
    self = [super initWithNodeType:SCNodeTypeBuiltInFunction andValues:pair];
    if (self) {
        NSString *fn = [NSString stringWithString:functionName];
        [self setFunctionName:fn];
    }
    return self;
}

- (SCNodeType)nodetype {
    return SCNodeTypeBuiltInFunction;
}

- (MADValue *)evaluate {
    MADValue *result;
    if ([[self functionName] isEqualToString:@"power"]) {
        MADValue *baseWrapper = [[self leftNode] evaluate];
        MADValue *exponantWrapper = [[self rightNode] evaluate];
        double base = [[baseWrapper value] doubleValue];
        double exponant = [[exponantWrapper value] doubleValue];
        double r = pow(base, exponant);
        
        result = [MADValue value:[NSNumber numberWithDouble:r]
                                  withType:SCVarableTypeDouble];
    }
    return result;
}

+ (MADValue *)uniaryMinus:(MADValue *)value {
    NSNumber *um = [NSNumber numberWithDouble: -[[value value] doubleValue]];
    return [MADValue value:um withType:SCVarableTypeDouble];
}

@end
