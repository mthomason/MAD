//
//  MTAstNodeSymbolReference.h
//  Scrimpter
//
//  Created by Michael Thomason on 6/21/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADScrimpter_MTAstNodeSymbolReference_h
#define MAD_MADScrimpter_MTAstNodeSymbolReference_h

#import "MTAbstractSyntaxTree.h"

@class MADSymbol, MADSymbolReference;

@interface MTAstNodeSymbolReference : MTAbstractSyntaxTree

@property (nonatomic, strong, readonly) MADSymbolReference *symbolReference;

- (id)initWithSymbolReference:(MADSymbolReference *)symbol;

- (NSString *)symbol;

@end

#endif
