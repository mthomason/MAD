//
//  MTAstNodeSymbolAsignNumber.m
//  Scrimpter
//
//  Created by Michael Thomason on 6/21/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTAstNodeSymbolAsignNumber.h"
#import "MTAbstractSyntaxTree.h"
#import "MTPair.h"
#import "MADSymbol.h"

@interface MTAstNodeSymbolAsignNumber ()

@property (nonatomic, strong, readwrite) MADSymbol *symbol;

@end

@implementation MTAstNodeSymbolAsignNumber

- (id)initWithSymbol:(MADSymbol *)symbol andValue:(MTAbstractSyntaxTree *)value {
    MTPair *values = [[MTPair alloc] initWithLeft:nil andRight:value];
    self = [[MTAstNodeSymbolAsignNumber alloc] initWithNodeType:SCNodeTypeAssignemnt andValues:values];
    if (self) {
        [self setSymbol:symbol];
    }
    return self;
}

- (MTTree *)leftNode {
    return nil;
}

- (MADValue *)evaluate {
    MADValue *result = [[self value] evaluate];
    [[self symbol] setMvalue:result];
    return [[self symbol] mvalue];
}

- (MTAbstractSyntaxTree *)value {
    return [self rightNode];
}

@end
