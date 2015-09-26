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

#import "MTDataTableLocation.h"

@interface MTDataTableLocation ()

- (instancetype)init NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithCoder:(NSCoder *)decoder NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithRow:(NSUInteger)row inColumn:(NSUInteger)column NS_DESIGNATED_INITIALIZER;

@end

@implementation MTDataTableLocation

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
    [encoder encodeObject: row
                    forKey: [MTDataTableLocation keyRow]];
    
    [encoder encodeObject: column
                    forKey: [MTDataTableLocation keyColumn]];
    
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    if (self = [super init]) {
        NSNumber *row = [decoder decodeObjectForKey: [MTDataTableLocation keyRow]];
        NSNumber *column = [decoder decodeObjectForKey: [MTDataTableLocation keyColumn]];
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

+ (instancetype)dataTableLocationForRow:(NSUInteger)row inColumn:(NSUInteger)column {
    id result = [[MTDataTableLocation alloc] initWithRow:row inColumn:column];
    return result;
}

+ (NSString *)keyRow {
    return NSStringFromSelector(@selector(identifier));
}

+ (NSString *)keyColumn {
    return NSStringFromSelector(@selector(column));
}

@end
