//
//  MTAstNodeSymbolAsignNumber.m
//  Scrimpter
//
//  Created by Michael Thomason on 6/21/14.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MTAstNodeSymbolAsignNumber.h"
#import "MTAbstractSyntaxTree.h"
#import "MADSymbol.h"

@interface MTAstNodeSymbolAsignNumber ()

@property (nonatomic, strong, readwrite) MADSymbol *symbol;

@end

@implementation MTAstNodeSymbolAsignNumber

- (instancetype)initWithSymbol:(MADSymbol *)symbol andValue:(MTAbstractSyntaxTree *)value {
    MTPair *values = [[MTPair alloc] initWithLeft:nil andRight:value];
    self = [[MTAstNodeSymbolAsignNumber alloc] initWithNodeType:SCNodeTypeAssignemnt andValues:values];
    if (self) {
        self.symbol = symbol;
    }
    return self;
}

- (MTTree *)leftNode {
    return nil;
}

- (MADValue *)evaluate {
    MADValue *result = [[self value] evaluate];
    [self.symbol setMvalue:result];
    return [self.symbol mvalue];
}

- (MTAbstractSyntaxTree *)value {
    return [self rightAST];
}

@end
