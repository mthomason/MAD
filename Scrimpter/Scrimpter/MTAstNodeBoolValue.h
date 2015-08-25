//
//  MTAstNodeBoolValue.h
//  Scrimpter
//
//  Created by Michael Thomason on 6/29/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADScrimpter_MTAstNodeBoolValue_h
#define MAD_MADScrimpter_MTAstNodeBoolValue_h

#import "MTAbstractSyntaxTree.h"

@interface MTAstNodeBoolValue : MTAbstractSyntaxTree

- (instancetype)initWithBool:(bool)b;

@end

#endif
