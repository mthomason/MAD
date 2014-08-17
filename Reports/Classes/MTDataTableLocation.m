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

- (instancetype)initWithCoder:(NSCoder *)decoder NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithRow:(NSUInteger)row inColumn:(NSUInteger)column NS_DESIGNATED_INITIALIZER;

@end

@implementation MTDataTableLocation

- (void)encodeWithCoder:(NSCoder *)encoder {
    
    [encoder encodeInteger: [self row]
                    forKey: [MTDataTableLocation keyRow]];
    
    [encoder encodeInteger: [self column]
                    forKey: [MTDataTableLocation keyColumn]];
    
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    self = [super init];
    if(self) {
        
        NSUInteger row = [decoder decodeIntegerForKey: [MTDataTableLocation keyRow]];
        NSUInteger column = [decoder decodeIntegerForKey: [MTDataTableLocation keyColumn]];
        [self setRow: row];
        [self setColumn: column];
    }
    
    return self;
}

- (instancetype)initWithRow:(NSUInteger)row inColumn:(NSUInteger)column {
    self = [super init];
    if (self) {
        [self setRow:row];
        [self setColumn:column];
    }
    return self;
}

+ (instancetype)dataTableLocationForRow:(NSUInteger)row inColumn:(NSUInteger)column {
    id result = [[MTDataTableLocation alloc] initWithRow:row inColumn:column];
    return result;
}

+ (NSString *)keyRow {
    SEL sel = @selector(identifier);
    return NSStringFromSelector(sel);
}

+ (NSString *)keyColumn {
    SEL sel = @selector(column);
    return NSStringFromSelector(sel);
}

@end
