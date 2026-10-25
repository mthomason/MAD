//
//  MTAstNodeSymbolReference.h
//  Scrimpter
//
//  Created by Michael Thomason on 6/21/14.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_MADScrimpter_MTAstNodeSymbolReference_h
#define MAD_MADScrimpter_MTAstNodeSymbolReference_h

#import "MTAbstractSyntaxTree.h"
#import <MADDataStructures/MADDataStructures.h>

@class MADSymbol, MADSymbolReference;

@interface MTAstNodeSymbolReference : MTAbstractSyntaxTree

- (instancetype)initWithSymbolReference:(MADSymbolReference *)symbol;

- (NSString *)symbol;

@end

#endif
