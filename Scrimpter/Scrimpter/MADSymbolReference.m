//
//  MADSymbolReference.m
//  Scrimpter
//
//  Created by Michael Thomason on 6/18/14.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
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

- (id)debugQuickLookObject {
    NSMutableString *description = [[NSMutableString alloc] init];
    [description appendFormat:@"*********\n"];
    [description appendFormat:@"Symbol:                 %@\n", self.symbol];
    [description appendFormat:@"Text:                   %@\n", self.filename];
    [description appendFormat:@"Flags:                  %ld\n", (long)self.flasgs];
    [description appendFormat:@"Lines & Columns:        (%ld, %ld)\n", (long)self.line, (long)self.column];
    [description appendFormat:@"*********"];
    return description;
}

@end
