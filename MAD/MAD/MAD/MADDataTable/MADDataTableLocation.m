//
//  MTDataTableLocation.m
//  libMTDataStrutures
//
//  Created by Michael Thomason on 4/7/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADDataTableLocation.h"
#import <Foundation/NSValue.h>
#import <Foundation/NSCoder.h>

@interface MADDataTableLocation ()

    - (instancetype)init;
    - (instancetype)initWithCoder:(NSCoder *)decoder;
    - (instancetype)initWithRow:(NSUInteger)row inColumn:(NSUInteger)column;

@end

@implementation MADDataTableLocation

static NSString *_keyRow;
static NSString *_keyColumn;

+ (NSString *)keyRow {
    if (_keyRow == nil) _keyRow = NSStringFromSelector(@selector(row));
    return _keyRow;
}

+ (NSString *)keyColumn {
    if (_keyColumn == nil) _keyColumn = NSStringFromSelector(@selector(column));
    return _keyColumn;
}

+ (instancetype)newDataTableLocationForRow:(NSUInteger)row inColumn:(NSUInteger)column {
    id result = [[self alloc] initWithRow:row inColumn:column];
    return result;
}

- (instancetype)init {
    if (self = [super init]) {
        self.row = 0;
        self.column = 0;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    if (self = [super init]) {
        NSNumber *row = [decoder decodeObjectForKey: [self.class keyRow]];
        NSNumber *column = [decoder decodeObjectForKey: [self.class keyColumn]];
        self.row = row.unsignedIntegerValue;
        self.column = column.unsignedIntegerValue;
    }
    
    return self;
}

- (instancetype)initWithRow:(NSUInteger)row inColumn:(NSUInteger)column {
    self = [super init];
    if (self) {
        self.row = row;
        self.column = column;
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    
    NSNumber *row = [[NSNumber alloc] initWithUnsignedInteger: self.row];
    NSNumber *column = [[NSNumber alloc] initWithUnsignedInteger: self.column];
    
    [encoder encodeObject: row forKey: [self.class keyRow]];
    [encoder encodeObject: column forKey: [self.class keyColumn]];
    
}

@end
