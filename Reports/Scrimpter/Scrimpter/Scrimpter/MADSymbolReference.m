//
//  MADSymbolReference.m
//  Scrimpter
//
//  Created by Michael Thomason on 6/18/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MADSymbolReference.h"

@interface MADSymbolReference ()

@property (nonatomic, weak, readwrite) NSString *symbol;
@property (nonatomic, weak) NSString *filename;
@property (nonatomic, assign) NSInteger flasgs;
@property (nonatomic, assign) NSInteger line;
@property (nonatomic, assign) NSInteger column;

@end

@implementation MADSymbolReference

- (id)init {
    self = [super init];
    if (self) {
        
    }
    return self;
}

+ (id)symbolReferenceWithSymbol:(NSString *)symbol filename:(NSString *)filename flags:(NSInteger)flags line:(NSInteger)line andColumns:(NSInteger)columns {
    MADSymbolReference *result = [MADSymbolReference new];
    if (result) {
        [result setSymbol:symbol];
        [result setFilename:filename];
        result.flasgs = flags;
        result.line = line;
        result.column = columns;
    }
    return result;
}

@end
