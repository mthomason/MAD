//
//  MADSymbolTable.m
//  Scrimpter
//
//  Created by Michael Thomason on 6/18/14.
//  Copyright (c) 2024 Michael Thomason. All rights reserved.
//

#import "MADSymbolTable.h"
#import "MADSymbol.h"
#import "MADSymbolReference.h"

@interface MADSymbolTable ()

@property (nonatomic, strong) NSMutableDictionary *symbolTable;

@end

@implementation MADSymbolTable

- (instancetype)init {
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
    return symbolReference;
}

- (MADSymbol *)symbolForString:(NSString *)symbol {
    return [self.symbolTable objectForKey:symbol];
}

@end
