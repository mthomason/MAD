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

- (instancetype)init {
    if (self = [super init]) {
        self.row = 0;
        self.column = 0;
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    
    NSNumber *row = @(self.row);
    NSNumber *column = @(self.column);
    
    [encoder encodeObject: row forKey: [MADDataTableLocation keyRow]];
    [encoder encodeObject: column forKey: [MADDataTableLocation keyColumn]];
    
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    if (self = [super init]) {
        NSNumber *row = [decoder decodeObjectForKey: [MADDataTableLocation keyRow]];
        NSNumber *column = [decoder decodeObjectForKey: [MADDataTableLocation keyColumn]];
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

+ (instancetype)newDataTableLocationForRow:(NSUInteger)row inColumn:(NSUInteger)column {
    id result = [[MADDataTableLocation alloc] initWithRow:row inColumn:column];
    return result;
}

+ (NSString *)keyRow {
    return NSStringFromSelector(@selector(row));
}

+ (NSString *)keyColumn {
    return NSStringFromSelector(@selector(column));
}

@end
