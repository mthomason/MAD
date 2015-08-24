//
//  MTAstNodeStringValue.h
//  Scrimpter
//
//  Created by Michael Thomason on 6/29/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADScrimpter_MTAstNodeStringValue_h
#define MAD_MADScrimpter_MTAstNodeStringValue_h

#import "MTAbstractSyntaxTree.h"

@interface MTAstNodeStringValue : MTAbstractSyntaxTree

- (id)initWithString:(NSString *)string;

@end

#endif
