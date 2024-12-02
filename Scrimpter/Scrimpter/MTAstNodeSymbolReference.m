//
//  MTAstNodeSymbolReference.m
//  Scrimpter
//
//  Created by Michael Thomason on 6/21/14.
//  Copyright (c) 2024 Michael Thomason. All rights reserved.
//

#import "MTAstNodeSymbolReference.h"
#import "MADSymbolReference.h"
#import "MADSymbol.h"
#import "MADScrimpter.h"
#import "MADSymbolTable.h"

@interface MTAstNodeSymbolReference ()

@end

@implementation MTAstNodeSymbolReference

- (instancetype)initWithSymbolReference:(MADSymbolReference *)symbolReference {
    MTPair *p = [[MTPair alloc] initWithLeft:symbolReference andRight:nil];
    self = [super initWithNodeType:SCNodeTypeSymbolReference andValues:p];
    if (self) { }
    return self;
}

- (SCNodeType)nodetype {
    return SCNodeTypeSymbolReference;
}

- (NSString *)symbol {
    return [(MADSymbolReference *)[self leftAST] symbol];
}

- (MADValue *)evaluate {
    MADSymbolTable *symbolTable = ScrimptSymbolTable();
    MADSymbol *symbol = [symbolTable symbolForString:[self symbol]];
    return [symbol mvalue];
}

@end
