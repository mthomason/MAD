//
//  MADSymbol.m
//  Scrimpter
//
//  Created by Michael Thomason on 6/18/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADSymbol.h"

@interface MADSymbol ()

@property (nonatomic, weak) NSString *name;
@property (nonatomic, strong) NSArray *symbolReferences;

@end

@implementation MADSymbol

- (id)initWithName:(NSString *)name {
    self = [super init];
    if (self) {
        [self setName:name];
        NSArray *symbolReference = @[];
        [self setSymbolReferences:symbolReference];
    }
    return self;
}

- (void)addReference:(MADSymbolReference *)symbolReference {
    self.symbolReferences = [self.symbolReferences arrayByAddingObject:symbolReference];
}

@end
