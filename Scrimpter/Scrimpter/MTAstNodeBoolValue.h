//
//  MTAstNodeBoolValue.h
//  Scrimpter
//
//  Created by Michael Thomason on 6/29/14.
//  Copyright (c) 2024 Michael Thomason. All rights reserved.
//

#ifndef MAD_MADScrimpter_MTAstNodeBoolValue_h
#define MAD_MADScrimpter_MTAstNodeBoolValue_h

#import "MTAbstractSyntaxTree.h"

@interface MTAstNodeBoolValue : MTAbstractSyntaxTree

- (instancetype)initWithBool:(bool)b;

@end

#endif
