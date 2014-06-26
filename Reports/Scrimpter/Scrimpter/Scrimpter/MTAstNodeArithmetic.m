//
//  MTAstNodeArithmetic.m
//  Scrimpter
//
//  Created by Michael Thomason on 6/22/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTAstNodeArithmetic.h"
#import "MADValue.h"

@interface MTAstNodeArithmetic ()

@property (nonatomic, assign) SCArithmetic prodcure;

@end

@implementation MTAstNodeArithmetic

- (id)initWithArithmeticProcedure:(SCArithmetic)procedure withValues:(MTPair *)values {
    self = [super initWithNodeType:SCNodeTypeArithmetic andValues:values];
    if (self) {
        [self setProdcure:procedure];
    }
    return self;
}

- (MADValue *)evaluate {
    MADValue *left = [[self leftNode] evaluate];
    MADValue *right = [[self rightNode] evaluate];
    double leftValue = [[left value] doubleValue];
    double rightValue = [[right value] doubleValue];
    double result;
    switch (self.prodcure) {
        case SCArithmeticAdd:
            result = leftValue + rightValue;
            break;
        case SCArithmeticSubtract:
            result = leftValue - rightValue;
            break;
        case SCArithmeticMultiply:
            result = leftValue * rightValue;
            break;
        case SCArithmeticDivide:
            result = leftValue / rightValue;
            break;
        default:
            result = leftValue + rightValue;
            break;
    }
    NSNumber *nv = [NSNumber numberWithDouble:result];
    return [MADValue value:nv withType:SCVarableTypeDouble];
}

- (SCNodeType)nodetype {
    return SCNodeTypeArithmetic;
}

@end
