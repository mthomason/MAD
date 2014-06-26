//
//  MTAstNodeArithmetic.m
//  Scrimpter
//
//  Created by Michael Thomason on 6/22/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTAstNodeArithmetic.h"

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

- (double)evaluate {
    switch (self.prodcure) {
        case SCArithmeticAdd:
            return self.leftNode.evaluate + self.rightNode.evaluate;
            break;
        case SCArithmeticSubtract:
            return self.leftNode.evaluate - self.rightNode.evaluate;
            break;
        case SCArithmeticMultiply:
            return self.leftNode.evaluate * self.rightNode.evaluate;
            break;
        case SCArithmeticDivide:
            return self.leftNode.evaluate / self.rightNode.evaluate;
            break;
        default:
            return self.leftNode.evaluate + self.rightNode.evaluate;
            break;
    }
}

- (SCNodeType)nodetype {
    return SCNodeTypeArithmetic;
}

@end
