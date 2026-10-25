//
//  MTAstNodeUserFunctionCall.m
//  Scrimpter
//
//  Created by Michael Thomason on 6/21/14.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
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
