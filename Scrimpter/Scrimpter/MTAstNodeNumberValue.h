//
//  MTAstNodeNumberValue.h
//  Scrimpter
//
//  Created by Michael Thomason on 6/21/14.
//  Copyright (c) 2024 Michael Thomason. All rights reserved.
//

#ifndef MAD_MADScrimpter_MTAstNodeNumberValue_h
#define MAD_MADScrimpter_MTAstNodeNumberValue_h

#import "MTAbstractSyntaxTree.h"
#import <MADDataStructures/MADDataStructures.h>

@interface MTAstNodeNumberValue : MTAbstractSyntaxTree

- (instancetype)initWithNumber:(NSNumber *)number;

@end

#endif
