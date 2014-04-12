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
@property (nonatomic, strong) NSMutableArray *column;

@end

@implementation MTDataColumn

- (void)encodeWithCoder:(NSCoder *)encoder {
    
    [encoder encodeObject: [self identifier]
                   forKey: [MTDataColumn keyIdentifier]];
    
    [encoder encodeObject: [self column]
                   forKey: [MTDataColumn keyColumn]];
    
    [encoder encodeObject: [self defaultValue]
                   forKey: [MTDataColumn keyDefaultValue]];
    
    [encoder encodeObject: [self caption]
                   forKey: [MTDataColumn keyCaption]];
    
    [encoder encodeObject: [self columnType]
                   forKey: [MTDataColumn keyColumnType]];
    
    [encoder encodeObject: [self nativeColumnType]
                   forKey: [MTDataColumn keyNativeColumnType]];
    
    [encoder encodeObject: [self dataLength]
                   forKey: [MTDataColumn keyDataLength]];

    [encoder encodeObject: [self dataPercision]
                   forKey: [MTDataColumn keyDataPercision]];
    
    [encoder encodeBool: [self isPrimaryKey]
                   forKey: [MTDataColumn keyIsPrimaryKey]];

    [encoder encodeBool: [self isNotNull]
                 forKey: [MTDataColumn keyIsNotNull]];

    [encoder encodeBool: [self isAutoIncrement]
                 forKey: [MTDataColumn keyIsAutoIncrement]];

}

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super init];
    if(self) {
        
        NSString *identifier = [decoder decodeObjectForKey: [MTDataColumn keyIdentifier]];
        [self setIdentifier: identifier];
        
        NSMutableArray *column = [decoder decodeObjectForKey: [MTDataColumn keyColumn]];
        [self setColumn: column];
        
        id defaultValue = [decoder decodeObjectForKey: [MTDataColumn keyDefaultValue]];
        [self setDefaultValue: defaultValue];
        
        NSString *caption = [decoder decodeObjectForKey: [MTDataColumn keyCaption]];
        [self setCaption: caption];
        
        NSNumber *columnType = [decoder decodeObjectForKey: [MTDataColumn keyColumnType]];
        [self setColumnType: columnType];
        
        NSNumber *nativeColumnType = [decoder decodeObjectForKey: [MTDataColumn keyNativeColumnType]];
        [self setNativeColumnType: nativeColumnType];
        
        NSNumber *dataLength = [decoder decodeObjectForKey: [MTDataColumn keyDataLength]];
        [self setDataLength: dataLength];
        
        NSNumber *dataPercision = [decoder decodeObjectForKey: [MTDataColumn keyDataPercision]];
        [self setDataPercision: dataPercision];

        BOOL isPrimaryKey = [decoder decodeBoolForKey: [MTDataColumn keyIsPrimaryKey]];
        [self setPrimaryKey: isPrimaryKey];

    }
    return self;
}

- (id)initWithIdentifier:(NSString *)identifier {
    self = [super init];
    if (self) {

        [self setIdentifier:identifier];
        [self setCaption:identifier];
        
        NSMutableArray *column = [[NSMutableArray alloc] init];
        [self setColumn:column];
        
        id defaultValue = [NSNull null];
        [self setDefaultValue:defaultValue];
        
        [self setColumnType: @(0)];
        [self setNativeColumnType: @(0)];
        [self setDataLength: @(0)];
        [self setDataPercision: @(0)];
        [self setPrimaryKey: NO];
        [self setNotNull: NO];
        [self setAutoIncrement: NO];
        
    }
    return self;
}

- (id)initWithPlist:(id)plist {
    self = [super init];
    if(self) {
        
        NSString *identifier = [plist objectForKey: [MTDataColumn keyIdentifier]];
        NSMutableArray *column = [plist objectForKey: [MTDataColumn keyColumn]];
        id defaultValue = [plist objectForKey: [MTDataColumn keyDefaultValue]];
        NSString *caption = [plist objectForKey: [MTDataColumn keyCaption]];
        NSNumber *columnType = [plist objectForKey: [MTDataColumn keyColumnType]];
        NSNumber *nativeColumnType = [plist objectForKey: [MTDataColumn keyNativeColumnType]];
        NSNumber *dataLength = [plist objectForKey: [MTDataColumn keyDataLength]];
        NSNumber *dataPercision = [plist objectForKey: [MTDataColumn keyDataPercision]];
        
        BOOL isPrimaryKey = [[plist objectForKey: [MTDataColumn keyIsPrimaryKey]] boolValue];
        BOOL isNotNull = [[plist objectForKey: [MTDataColumn keyIsNotNull]] boolValue];
        BOOL isAutoIncrement = [[plist objectForKey: [MTDataColumn keyIsAutoIncrement]] boolValue];
        
        [self setIdentifier: identifier];
        [self setColumn: column];
        [self setDefaultValue: defaultValue];
        [self setCaption: caption];
        [self setColumnType: columnType];
        [self setNativeColumnType: nativeColumnType];
        [self setDataLength: dataLength];
        [self setDataPercision: dataPercision];
        
        [self setPrimaryKey: isPrimaryKey];
        [self setNotNull: isNotNull];
        [self setAutoIncrement: isAutoIncrement];
        
    }
    return self;
}

- (id)objectAtIndex:(NSInteger)index {
    if (index >= [[self column] count]) {
        NSLog(@"ERROR");
    }
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

- (id)plist {
    
    NSMutableDictionary *plist = [[NSMutableDictionary alloc] initWithCapacity:8];
    NSString *keyIdentifier = [MTDataColumn keyIdentifier];
    NSString *keyColumn = [MTDataColumn keyColumn];
    NSString *keyDefaultValue = [MTDataColumn keyDefaultValue];
    NSString *keyCaption = [MTDataColumn keyCaption];
    NSString *keyColumnType = [MTDataColumn keyColumnType];
    NSString *keyNativeColumnType = [MTDataColumn keyNativeColumnType];
    NSString *keyDataLength = [MTDataColumn keyDataLength];
    NSString *keyDataPercision = [MTDataColumn keyDataPercision];
    NSString *keyIsPrimaryKey = [MTDataColumn keyIsPrimaryKey];
    NSString *keyIsNotNull = [MTDataColumn keyIsNotNull];
    NSString *keyIsAutoIncrement = [MTDataColumn keyIsAutoIncrement];
    
    NSNumber *primaryKey = @([self isPrimaryKey]);
    NSNumber *notNull = @([self isNotNull]);
    NSNumber *autoIncrement = @([self isAutoIncrement]);

    id defaultValue = [self defaultValue];
    if ([defaultValue isEqual:[NSNull null]]) {
        defaultValue = @"~MTNull~";
    }
    
    [plist setObject: [self identifier]         forKey: keyIdentifier];
    [plist setObject: [self column]             forKey: keyColumn];
    [plist setObject: defaultValue              forKey: keyDefaultValue];
    [plist setObject: [self caption]            forKey: keyCaption];
    [plist setObject: [self columnType]         forKey: keyColumnType];
    [plist setObject: [self nativeColumnType]   forKey: keyNativeColumnType];
    [plist setObject: [self dataLength]         forKey: keyDataLength];
    [plist setObject: [self dataPercision]      forKey: keyDataPercision];
    [plist setObject: primaryKey                forKey:keyIsPrimaryKey];
    [plist setObject: notNull                   forKey: keyIsNotNull];
    [plist setObject: autoIncrement             forKey: keyIsAutoIncrement];

    return plist;
}

+ (NSString *)keyDefaultValue {
    SEL sel = @selector(defaultValue);
    return NSStringFromSelector(sel);
}

+ (NSString *)keyCaption {
    SEL sel = @selector(caption);
    return NSStringFromSelector(sel);
}

+ (NSString *)keyColumnType {
    SEL sel = @selector(columnType);
    return NSStringFromSelector(sel);
}

+ (NSString *)keyNativeColumnType {
    SEL sel = @selector(nativeColumnType);
    return NSStringFromSelector(sel);
}

+ (NSString *)keyDataLength {
    SEL sel = @selector(dataLength);
    return NSStringFromSelector(sel);
}

+ (NSString *)keyDataPercision {
    SEL sel = @selector(dataPercision);
    return NSStringFromSelector(sel);
}

+ (NSString *)keyIdentifier {
    SEL sel = @selector(identifier);
    return NSStringFromSelector(sel);
}

+ (NSString *)keyColumn {
    SEL sel = @selector(column);
    return NSStringFromSelector(sel);
}

+ (NSString *)keyIsPrimaryKey {
    SEL sel = @selector(isPrimaryKey);
    return NSStringFromSelector(sel);
}

+ (NSString *)keyIsNotNull {
    SEL sel = @selector(isNotNull);
    return NSStringFromSelector(sel);
}

+ (NSString *)keyIsAutoIncrement {
    SEL sel = @selector(isAutoIncrement);
    return NSStringFromSelector(sel);
}

@end
