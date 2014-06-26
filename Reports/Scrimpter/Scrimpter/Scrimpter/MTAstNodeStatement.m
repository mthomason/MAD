//
//  MTAstNodeStatement.m
//  Scrimpter
//
//  Created by Michael Thomason on 6/23/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTAstNodeStatement.h"
#import "MTPair.h"

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

- (double)evaluate {
    return [self statement] == nil ? NSNotFound : [[self statement] evaluate];
}

- (SCNodeType)nodetype {
    return SCNodeTypeStatement;
}

@end
