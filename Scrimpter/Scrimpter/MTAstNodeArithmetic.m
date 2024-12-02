//
//  MTAstNodeArithmetic.m
//  Scrimpter
//
//  Created by Michael Thomason on 6/22/14.
//  Copyright (c) 2024 Michael Thomason. All rights reserved.
//

#import "MTAstNodeArithmetic.h"
#import "MADValue.h"

@interface MTAstNodeArithmetic ()

@property (nonatomic, assign) SCArithmetic prodcure;

@end

@implementation MTAstNodeArithmetic

- (instancetype)initWithArithmeticProcedure:(SCArithmetic)procedure withValues:(MTPair *)values {
    self = [super initWithNodeType:SCNodeTypeArithmetic andValues:values];
    if (self) {
        [self setProdcure:procedure];
    }
    return self;
}

- (MADValue *)evaluate {
    MADValue *left = [self.leftAST evaluate];
    MADValue *right = [self.rightAST evaluate];
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

- (id)debugQuickLookObject {
    NSMutableString *description = [[NSMutableString alloc] init];
    [description appendFormat:@"********* MTAstNodeArithmetic *********\n"];
    switch (self.prodcure) {
        case SCArithmeticAdd:
            [description appendString:@"Add"];
            break;
        case SCArithmeticSubtract:
            [description appendString:@"Subtract"];
            break;
        case SCArithmeticMultiply:
            [description appendString:@"Multiply"];
            break;
        case SCArithmeticDivide:
            [description appendString:@"Divide"];
            break;
        default:
            [description appendString:@"Unknown"];
            break;
    }
    [description appendFormat:@"*********"];
    return description;
}

@end
