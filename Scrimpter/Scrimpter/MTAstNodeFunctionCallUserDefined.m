//
//  MTAstNodeUserFunctionCall.m
//  Scrimpter
//
//  Created by Michael Thomason on 6/21/14.
//  Copyright (c) 2024 Michael Thomason. All rights reserved.
//

#import "MTAstNodeFunctionCallUserDefined.h"

@implementation MTAstNodeFunctionCallUserDefined

- (SCNodeType)nodetype {
    return SCNodeTypeUserFunction;
}

- (MTTree *)rightNode {
    return nil;
}

@end
