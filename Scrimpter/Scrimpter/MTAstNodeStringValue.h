//
//  MTAstNodeStringValue.h
//  Scrimpter
//
//  Created by Michael Thomason on 6/29/14.
//  Copyright (c) 2024 Michael Thomason. All rights reserved.
//

#ifndef MAD_MADScrimpter_MTAstNodeStringValue_h
#define MAD_MADScrimpter_MTAstNodeStringValue_h

#import "MTAbstractSyntaxTree.h"

@interface MTAstNodeStringValue : MTAbstractSyntaxTree

- (instancetype)initWithString:(NSString *)string;

@end

#endif
