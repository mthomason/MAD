//
//  DataColumn.m
//  libMTDataStrutures
//
//  Created by Michael Thomason on 4/6/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTDataColumn.h"

@interface MTDataColumn ()

@property (nonatomic, copy, readwrite) NSString *identifier;
@property (nonatomic, copy) NSString *caption;
@property (nonatomic, strong) NSMutableArray *column;

@end

@implementation MTDataColumn

- (id)initWithIdentifier:(NSString *)identifier {
    self = [super init];
    if (self) {

        [self setIdentifier:identifier];
        [self setCaption:identifier];
        
        NSMutableArray *column = [[NSMutableArray alloc] init];
        [self setColumn:column];
        
        id defaultValue = [NSNull null];
        [self setDefaultValue:defaultValue];
        
    }
    return self;
}

- (id)objectAtIndex:(NSInteger)index {
    return [[self column] objectAtIndex:index];
}

- (void)addObject:(id)object {
    [[self column] addObject:object];
}

- (void)addRows:(NSUInteger)count {
    for (NSUInteger i = 0; i <= count; i++) {
        [[self column] addObject:[self defaultValue]];
    }
}

@end
