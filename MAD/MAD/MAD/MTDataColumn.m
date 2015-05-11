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
    
    [encoder encodeObject: [self fieldName]
                   forKey: [MTDataColumn keyFieldName]];
    
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

- (instancetype)initWithCoder:(NSCoder *)decoder {
    self = [super init];
    if(self) {

        NSString *fieldName = [decoder decodeObjectForKey: [MTDataColumn keyFieldName]];
        [self setIdentifier: fieldName];

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

- (instancetype)initWithIdentifier:(NSString *)identifier {
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

- (instancetype)initWithPlist:(id)plist {
    self = [super init];
    if(self) {
        
        NSString *fieldName = plist[[MTDataColumn keyFieldName]];
        NSString *identifier = plist[[MTDataColumn keyIdentifier]];
        
        NSArray *columnImmutable = plist[[MTDataColumn keyColumn]];
        NSMutableArray *column = [[NSMutableArray alloc] initWithArray: columnImmutable];
        
        id defaultValue = plist[[MTDataColumn keyDefaultValue]];
        NSString *caption = plist[[MTDataColumn keyCaption]];
        NSNumber *columnType = plist[[MTDataColumn keyColumnType]];
        NSNumber *nativeColumnType = plist[[MTDataColumn keyNativeColumnType]];
        NSNumber *dataLength = plist[[MTDataColumn keyDataLength]];
        NSNumber *dataPercision = plist[[MTDataColumn keyDataPercision]];
        
        BOOL isPrimaryKey = [plist[[MTDataColumn keyIsPrimaryKey]] boolValue];
        BOOL isNotNull = [plist[[MTDataColumn keyIsNotNull]] boolValue];
        BOOL isAutoIncrement = [plist[[MTDataColumn keyIsAutoIncrement]] boolValue];
        
        [self setFieldName:fieldName];
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
    NSAssert(index < [[self column] count], @"Column doesn't exit!");
    return [self column][index];
}

- (void)addObject:(id)object {
    [[self column] addObject:object];
}

- (void)addRows:(NSUInteger)count {
    for (NSUInteger i = 0; i <= count; i++) {
        [[self column] addObject:[self defaultValue]];
    }
}

- (NSDictionary *)plist {
    
    NSMutableDictionary *plist = [[NSMutableDictionary alloc] initWithCapacity:8];
    NSString *keyFieldName = [MTDataColumn keyFieldName];
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
    
    plist[keyFieldName] = [self fieldName];
    plist[keyIdentifier] = [self identifier];
    plist[keyColumn] = [self column];
    plist[keyDefaultValue] = defaultValue;
    plist[keyCaption] = [self caption];
    plist[keyColumnType] = [self columnType];
    plist[keyNativeColumnType] = [self nativeColumnType];
    plist[keyDataLength] = [self dataLength];
    plist[keyDataPercision] = [self dataPercision];
    plist[keyIsPrimaryKey] = primaryKey;
    plist[keyIsNotNull] = notNull;
    plist[keyIsAutoIncrement] = autoIncrement;

    return plist;
}

- (void)removeAllObjects {
    [[self column] removeAllObjects];
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

+ (NSString *)keyFieldName {
    SEL sel = @selector(fieldName);
    return NSStringFromSelector(sel);
}

@end
