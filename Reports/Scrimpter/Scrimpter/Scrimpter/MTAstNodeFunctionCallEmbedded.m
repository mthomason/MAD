//
//  MTAstNodeEmbeddedFunctionCall.m
//  Scrimpter
//
//  Created by Michael Thomason on 6/21/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTAstNodeFunctionCallEmbedded.h"
#import "MTPair.h"

@interface MTAstNodeFunctionCallEmbedded ()

@property (nonatomic, assign) SCFunctionType functionType;

@end

@implementation MTAstNodeFunctionCallEmbedded

- (id)initWithEmbededProcedure:(SCFunctionType)procedure withValue:(MTAbstractSyntaxTree *)value {
    MTPair *pair = [MTPair pairWithLeft:value andRight:nil];
    self = [super initWithNodeType:SCNodeTypeBuiltInFunction andValues:pair];
    if (self) {
        [self setFunctionType:procedure];
    }
    return self;
}

- (SCNodeType)nodetype {
    return SCNodeTypeBuiltInFunction;
}

- (MTTree *)rightNode {
    return nil;
}

- (double)evaluate {
    double result;
    switch (self.functionType) {
        case SCFunctionTypeUniaryMinus:
            result = [MTAstNodeFunctionCallEmbedded uniaryMinus:[[self leftNode] evaluate]];
            break;
        default:
            break;
    }
    return result;
}

+ (double)uniaryMinus:(double)d {
    return -d;
}

@end
