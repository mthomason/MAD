//
//  MTAstNodeStatementList.m
//  Scrimpter
//
//  Created by Michael Thomason on 6/23/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTAstNodeStatementList.h"
#import "MTPair.h"

@implementation MTAstNodeStatementList

- (id)initWithStatement:(MTAbstractSyntaxTree *)statement andList:(MTAstNodeStatementList *)list {
    MTPair *pair = [MTPair pairWithLeft:statement andRight:list];
    self = [super initWithNodeType:SCNodeTypeStatementList andValues:pair];
    if (self) {
        
    }
    return self;
}

- (SCNodeType)nodetype {
    return SCNodeTypeStatementList;
}

- (MTAbstractSyntaxTree *)statement {
    return [self leftNode];
}

- (MTAbstractSyntaxTree *)statementList {
    return  [self rightNode];
}

- (double)evaluate {
    double result = [[self statement] evaluate];
    if (self.statement.nodetype != SCNodeTypeResult) {
        result = [[self statementList] evaluate];
    }
    return result;
}

@end
