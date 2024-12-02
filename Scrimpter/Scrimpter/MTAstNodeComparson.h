//
//  MTAstNodeComparson.h
//  Scrimpter
//
//  Created by Michael Thomason on 6/22/14.
//  Copyright (c) 2024 Michael Thomason. All rights reserved.
//

#ifndef MAD_MADScrimpter_MTAstNodeComparson_h
#define MAD_MADScrimpter_MTAstNodeComparson_h

#import "MTAbstractSyntaxTree.h"

@interface MTAstNodeComparson : MTAbstractSyntaxTree

- (instancetype)initWithComparson:(SCCompareson)comparson ofValues:(MTPair *)values;

@end

#endif
