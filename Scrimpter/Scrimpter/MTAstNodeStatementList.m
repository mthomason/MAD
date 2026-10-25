//
//  MTAstNodeStatementList.m
//  Scrimpter
//
//  Created by Michael Thomason on 6/23/14.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MTAstNodeStatementList.h"

@implementation MTAstNodeStatementList

- (instancetype)initWithStatement:(MTAbstractSyntaxTree *)statement andList:(MTAbstractSyntaxTree *)list {
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
    return self.leftAST;
}

- (MTAbstractSyntaxTree *)statementList {
    return  self.rightAST;
}

- (MADValue *)evaluate {
    MADValue *result = [[self statement] evaluate];
    if (self.statement.nodetype != SCNodeTypeResult) {
        result = [[self statementList] evaluate];
    }
    return result;
}

@end
