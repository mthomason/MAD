//
//  MTAstNodeSymbolReference.m
//  Scrimpter
//
//  Created by Michael Thomason on 6/21/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTAstNodeSymbolReference.h"
#import "MADSymbolReference.h"
#import "MADSymbol.h"
#import "MADScrimpter.h"
#import "MADSymbolTable.h"
#import "MTPair.h"

@interface MTAstNodeSymbolReference ()

@end

@implementation MTAstNodeSymbolReference

- (id)initWithSymbolReference:(MADSymbolReference *)symbolReference {
    MTPair *p = [[MTPair alloc] initWithLeft:symbolReference andRight:nil];
    self = [super initWithNodeType:SCNodeTypeSymbolReference andValues:p];
    if (self) { }
    return self;
}

- (MTAbstractSyntaxTree *)rightNode {
    return nil;
}

- (MTAbstractSyntaxTree *)leftNode {
    return nil;
}

- (SCNodeType)nodetype {
    return SCNodeTypeSymbolReference;
}

- (NSString *)symbol {
    return [(MADSymbolReference *)[self leftNode] symbol];
}

- (MADValue *)evaluate {
    MADSymbolTable *symbolTable = ScrimptSymbolTable();
    MADSymbol *symbol = [symbolTable symbolForString:[self symbol]];
    return [symbol mvalue];
}

@end
