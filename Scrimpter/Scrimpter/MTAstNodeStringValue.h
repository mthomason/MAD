//
//  MTAstNodeStringValue.h
//  Scrimpter
//
//  Created by Michael Thomason on 6/29/14.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_MADScrimpter_MTAstNodeStringValue_h
#define MAD_MADScrimpter_MTAstNodeStringValue_h

#import "MTAbstractSyntaxTree.h"

@interface MTAstNodeStringValue : MTAbstractSyntaxTree

- (instancetype)initWithString:(NSString *)string;

@end

#endif
