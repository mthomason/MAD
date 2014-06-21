//
//  MADSymbolTable.m
//  Scrimpter
//
//  Created by Michael Thomason on 6/18/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADSymbolTable.h"
#import "MADSymbol.h"
#import "MADSymbolReference.h"

@interface MADSymbolTable ()

@property (nonatomic, strong) NSMutableDictionary *symbolTable;

@end

@implementation MADSymbolTable

- (id)init {
    self = [super init];
    if (self) {
        NSMutableDictionary *symbolTable = [NSMutableDictionary new];
        [self setSymbolTable:symbolTable];
    }
    return self;
}

- (MADSymbolReference *)addSymbolReference:(NSString *)key reference:(MADSymbolReference *)symbolReference {
    MADSymbol *symbol = self.symbolTable[key];
    if (symbol == nil) {
        symbol = [[MADSymbol alloc] initWithName:key];
    }
    [symbol addReference:symbolReference];
    self.symbolTable[key] = symbol;
    return self.symbolTable[key];
}

- (MADSymbol *)symbolForString:(NSString *)symbol {
    return [[self symbolTable] objectForKey:symbol];
}

@end
