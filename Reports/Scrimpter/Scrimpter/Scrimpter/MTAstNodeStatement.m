//
//  MTAstNodeStatement.m
//  Scrimpter
//
//  Created by Michael Thomason on 6/23/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTAstNodeStatement.h"
#import "MTPair.h"
#import "MADValue.h"

@implementation MTAstNodeStatement

- (id)initWithNode:(MTAbstractSyntaxTree *)node {
    MTPair *pair = [MTPair pairWithLeft:node andRight:nil];
    self = [super initWithNodeType:SCNodeTypeStatement andValues:pair];
    if (self) {
        
    }
    return self;
}

- (MTAbstractSyntaxTree *)statement {
    return [self leftNode];
}

- (MADValue *)evaluate {
    id result;
    if ([self statement] == nil) {
        result = [MADValue nullValue];
    } else {
        result = [[self statement] evaluate];
    }
    return result;
}

- (SCNodeType)nodetype {
    return SCNodeTypeStatement;
}

@end
