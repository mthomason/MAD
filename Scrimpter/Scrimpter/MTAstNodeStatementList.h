//
//  MTAstNodeStatementList.h
//  Scrimpter
//
//  Created by Michael Thomason on 6/23/14.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_MADScrimpter_MTAstNodeStatementList_h
#define MAD_MADScrimpter_MTAstNodeStatementList_h

#import "MTAbstractSyntaxTree.h"
#import <MADDataStructures/MADDataStructures.h>

@interface MTAstNodeStatementList : MTAbstractSyntaxTree

- (instancetype)initWithStatement:(MTAbstractSyntaxTree *)statement andList:(MTAbstractSyntaxTree *)list;

@end

#endif
