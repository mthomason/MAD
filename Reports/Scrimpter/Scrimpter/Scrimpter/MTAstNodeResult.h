//
//  MTAstNodeResult.h
//  Scrimpter
//
//  Created by Michael Thomason on 6/23/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADScrimpter_MTAstNodeResult_h
#define MAD_MADScrimpter_MTAstNodeResult_h

#import "MTAbstractSyntaxTree.h"

@interface MTAstNodeResult : MTAbstractSyntaxTree

- (id)initWithResult:(MTAbstractSyntaxTree *)expression;

@end

#endif
