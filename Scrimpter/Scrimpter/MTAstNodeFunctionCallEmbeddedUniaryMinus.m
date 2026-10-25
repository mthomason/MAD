//
//  MTAstNodeEmbeddedFunctionCall.m
//  Scrimpter
//
//  Created by Michael Thomason on 6/21/14.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MTAstNodeFunctionCallEmbeddedUniaryMinus.h"
#import "MADValue.h"

@interface MTAstNodeFunctionCallEmbeddedUniaryMinus ()

@end

@implementation MTAstNodeFunctionCallEmbeddedUniaryMinus

- (instancetype)initWithValueForUniaryMinus:(MTAbstractSyntaxTree *)value {
    MTPair *pair = [MTPair pairWithLeft:value andRight:nil];
    self = [super initWithNodeType:SCNodeTypeBuiltInFunction andValues:pair];
    if (self) {

    }
    return self;
}

- (SCNodeType)nodetype {
    return SCNodeTypeBuiltInFunction;
}

- (MADValue *)evaluate {
    return [MTAstNodeFunctionCallEmbeddedUniaryMinus uniaryMinus:[self.leftAST evaluate]];
}

+ (MADValue *)uniaryMinus:(MADValue *)value {
    NSNumber *um = [NSNumber numberWithDouble: -[[value value] doubleValue]];
    return [MADValue value:um withType:SCVarableTypeDouble];
}

@end
