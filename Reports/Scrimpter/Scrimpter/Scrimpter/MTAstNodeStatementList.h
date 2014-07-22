//
//  MTAstNodeStatementList.h
//  Scrimpter
//
//  Created by Michael Thomason on 6/23/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADScrimpter_MTAstNodeStatementList_h
#define MAD_MADScrimpter_MTAstNodeStatementList_h

#import "MTAbstractSyntaxTree.h"

@interface MTAstNodeStatementList : MTAbstractSyntaxTree

- (id)initWithStatement:(MTAbstractSyntaxTree *)statement andList:(MTAbstractSyntaxTree *)list;

@end

#endif
