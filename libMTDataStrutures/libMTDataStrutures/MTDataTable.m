//
//  MTTable.m
//  libMTDataStrutures
//
//  Created by Michael Thomason on 4/6/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTDataTable.h"

@interface MTDataTable ()

@property (nonatomic, retain, readwrite) NSMutableArray *table;

@end

@implementation MTDataTable

- (id)init {
    self = [super init];
    if (self) {
        NSMutableArray *table = [[NSMutableArray alloc] init];
        [self setTable:table];
    }
    return self;
}

- (void)addObject:(id)object {
    [[self table] addObject:object];
}

- (NSInteger)count {
    return [self count];
}

- (id)objectAtIndex:(NSInteger)index {
    return [[self table] objectAtIndex:index];
}

@end
