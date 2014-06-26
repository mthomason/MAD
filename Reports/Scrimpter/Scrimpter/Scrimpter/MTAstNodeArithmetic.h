//
//  MTAstNodeArithmetic.h
//  Scrimpter
//
//  Created by Michael Thomason on 6/22/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTAbstractSyntaxTree.h"

typedef NS_ENUM(NSInteger, SCArithmetic) {
    SCArithmeticAdd,
    SCArithmeticSubtract,
    SCArithmeticMultiply,
    SCArithmeticDivide,
};

@interface MTAstNodeArithmetic : MTAbstractSyntaxTree

- (id)initWithArithmeticProcedure:(SCArithmetic)procedure withValues:(MTPair *)values;

@end
