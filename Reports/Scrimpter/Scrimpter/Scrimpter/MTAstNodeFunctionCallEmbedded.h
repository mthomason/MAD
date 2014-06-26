//
//  MTAstNodeEmbeddedFunctionCall.h
//  Scrimpter
//
//  Created by Michael Thomason on 6/21/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTAbstractSyntaxTree.h"

typedef NS_ENUM(NSInteger, SCFunctionType) {
    SCFunctionTypeSqureRoot,
    SCFunctionTypeSqureExp,
    SCFunctionTypeSqureLog,
    SCFunctionTypeAbsoluteValue,
    SCFunctionTypeUniaryMinus
};

@interface MTAstNodeFunctionCallEmbedded : MTAbstractSyntaxTree

- (id)initWithEmbededProcedure:(SCFunctionType)procedure withValue:(MTAbstractSyntaxTree *)value;


@end
