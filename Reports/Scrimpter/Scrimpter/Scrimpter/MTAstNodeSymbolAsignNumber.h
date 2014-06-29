//
//  MTAstNodeSymbolAsignNumber.h
//  Scrimpter
//
//  Created by Michael Thomason on 6/21/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADScrimpter_MTAstNodeSymbolAsignNumber_h
#define MAD_MADScrimpter_MTAstNodeSymbolAsignNumber_h

#import "MTAbstractSyntaxTree.h"

@class MADSymbol, MADValue;

@interface MTAstNodeSymbolAsignNumber : MTAbstractSyntaxTree

- (id)initWithSymbol:(MADSymbol *)symbol andValue:(MTAbstractSyntaxTree *)value;
- (MTAbstractSyntaxTree *)value;

@property (nonatomic, strong, readonly) MADSymbol *symbol;

@end

#endif
