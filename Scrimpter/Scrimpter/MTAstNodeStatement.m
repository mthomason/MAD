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

- (id)initWithStatement:(MTAbstractSyntaxTree *)node {
    self = [super initWithNodeType:SCNodeTypeStatement andValues:nil];
    if (self) {
        [self setStatement:node];
    }
    return self;
}

- (void)setStatement:(MTAbstractSyntaxTree *)statment {
    [self setLeftNode:statment];
}

- (MTAbstractSyntaxTree *)statement {
    return self.leftAST;
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
