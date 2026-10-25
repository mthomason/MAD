//
//  MTAstNodeStatement.h
//  Scrimpter
//
//  Created by Michael Thomason on 6/23/14.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_MADScrimpter_MTAstNodeStatement_h
#define MAD_MADScrimpter_MTAstNodeStatement_h

#import "MTAbstractSyntaxTree.h"
#import <MADDataStructures/MADDataStructures.h>

@interface MTAstNodeStatement : MTAbstractSyntaxTree

- (instancetype)initWithStatement:(MTAbstractSyntaxTree *)node;

@end

#endif
