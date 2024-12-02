//
//  MADSymbol.m
//  Scrimpter
//
//  Created by Michael Thomason on 6/18/14.
//  Copyright (c) 2024 Michael Thomason. All rights reserved.
//

#import "MADSymbol.h"

MADSymbolReference *(^ScrimptSymbolReference)(NSString *symbol, NSString *filename, NSInteger flags, NSInteger line, NSInteger columns);
id (^ScrimptData)(NSString *key);    //For gettting values from dictionary
MADSymbol *(^ScrimptSymbol)(NSString *key);
void (^Scrimpted)(BOOL success, id result, NSError *error);

@interface MADSymbol ()

@property (nonatomic, weak) NSString *name;
@property (nonatomic, strong) NSArray *symbolReferences;

@end

@implementation MADSymbol

- (id)initWithName:(NSString *)name {
    self = [super init];
    if (self) {
        self.name = name;
        NSArray *symbolReference = @[];
        [self setSymbolReferences:symbolReference];
    }
    return self;
}

- (void)addReference:(MADSymbolReference *)symbolReference {
    self.symbolReferences = [self.symbolReferences arrayByAddingObject:symbolReference];
}

- (id)debugQuickLookObject {
    NSMutableString *description = [[NSMutableString alloc] init];
    [description appendFormat:@"*********\n"];
    [description appendFormat:@"Name:                 %@\n", self.name];
    [description appendString:@"References:\n"];
    for (id obj in self.symbolReferences) {
        [description appendFormat:@"%@", obj];
    }
    [description appendFormat:@"*********"];
    return description;
}

@end
