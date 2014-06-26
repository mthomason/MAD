//
//  MTAstNodeSymbolReference.m
//  Scrimpter
//
//  Created by Michael Thomason on 6/21/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTAstNodeSymbolReference.h"
#import "MADSymbolReference.h"

@interface MTAstNodeSymbolReference ()

@property (nonatomic, strong, readwrite) MADSymbolReference *symbolReference;

@end

@implementation MTAstNodeSymbolReference

- (id)initWithSymbolReference:(MADSymbolReference *)symbolReference {
    self = [super initWithNodeType:SCNodeTypeSymbolReference andValues:nil];
    if (self) {
        [self setSymbolReference:symbolReference];
    }
    return self;
}

- (MTTree *)rightNode {
    return nil;
}

- (MTTree *)leftNode {
    return nil;
}

- (SCNodeType)nodetype {
    return SCNodeTypeSymbolReference;
}

- (NSString *)symbol {
    return [[self symbolReference] symbol];
}

@end
