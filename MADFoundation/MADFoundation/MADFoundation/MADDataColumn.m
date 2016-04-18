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

#import "MADDataColumn.h"
#import <Foundation/NSArray.h>
#import <Foundation/NSString.h>
#import <Foundation/NSNull.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSException.h>
#import <Foundation/NSCoder.h>

@interface MADDataColumn ()

@property (nonatomic, copy, readwrite) NSString *identifier;
@property (nonatomic, strong) NSMutableArray *column;

@end

@implementation MADDataColumn

- (void)encodeWithCoder:(NSCoder *)encoder {
    
    [encoder encodeObject: [self fieldName]
                   forKey: [MADDataColumn keyFieldName]];
    
    [encoder encodeObject: [self identifier]
                   forKey: [MADDataColumn keyIdentifier]];
    
    [encoder encodeObject: self.column
                   forKey: [MADDataColumn keyColumn]];
    
    [encoder encodeObject: [self defaultValue]
                   forKey: [MADDataColumn keyDefaultValue]];
    
    [encoder encodeObject: [self caption]
                   forKey: [MADDataColumn keyCaption]];
    
    [encoder encodeObject: [self columnType]
                   forKey: [MADDataColumn keyColumnType]];
    
    [encoder encodeObject: [self nativeColumnType]
                   forKey: [MADDataColumn keyNativeColumnType]];
    
    [encoder encodeObject: [self dataLength]
                   forKey: [MADDataColumn keyDataLength]];

    [encoder encodeObject: [self dataPercision]
                   forKey: [MADDataColumn keyDataPercision]];
    
    [encoder encodeBool: self.isPrimaryKey ? YES : NO
                   forKey: [MADDataColumn keyIsPrimaryKey]];

    [encoder encodeBool: self.isNotNull ? YES : NO
                 forKey: [MADDataColumn keyIsNotNull]];

    [encoder encodeBool: self.isAutoIncrement ? YES : NO
                 forKey: [MADDataColumn keyIsAutoIncrement]];

}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    if( self = [super init]) {

        NSString *fieldName = [decoder decodeObjectForKey: [MADDataColumn keyFieldName]];
        self.identifier = fieldName;

        NSString *identifier = [decoder decodeObjectForKey: [MADDataColumn keyIdentifier]];
        self.identifier = identifier;
        
        NSMutableArray *column = [decoder decodeObjectForKey: [MADDataColumn keyColumn]];
        self.column = column;
        
        id defaultValue = [decoder decodeObjectForKey: [MADDataColumn keyDefaultValue]];
        self.defaultValue = defaultValue;
        
        NSString *caption = [decoder decodeObjectForKey: [MADDataColumn keyCaption]];
        self.caption = caption;
        
        NSNumber *columnType = [decoder decodeObjectForKey: [MADDataColumn keyColumnType]];
        self.columnType = columnType;
        
        NSNumber *nativeColumnType = [decoder decodeObjectForKey: [MADDataColumn keyNativeColumnType]];
        self.nativeColumnType = nativeColumnType;
        
        NSNumber *dataLength = [decoder decodeObjectForKey: [MADDataColumn keyDataLength]];
        self.dataLength = dataLength;
        
        NSNumber *dataPercision = [decoder decodeObjectForKey: [MADDataColumn keyDataPercision]];
        self.dataPercision = dataPercision;

        self.primaryKey = [decoder decodeBoolForKey: [MADDataColumn keyIsPrimaryKey]] ? true : false;

    }
    return self;
}

- (instancetype)initWithIdentifier:(NSString *)identifier {
    if (self = [super init]) {

        _identifier = [[NSString alloc] initWithString:identifier];
        _caption = [[NSString alloc] initWithString:identifier];
        
        _column = [[NSMutableArray alloc] init];

        _defaultValue = [NSNull null];
        
        _columnType = @(0);
        _nativeColumnType = @(0);
        _dataLength = @(0);
        _dataPercision = @(0);
        _primaryKey = NO;
        _notNull = NO;
        _autoIncrement = NO;
        
    }
    return self;
}

- (instancetype)initWithPlist:(id)plist {
    self = [super init];
    if(self) {
        
        NSString *fieldName = plist[[MADDataColumn keyFieldName]];
        NSString *identifier = plist[[MADDataColumn keyIdentifier]];
        
        NSArray *columnImmutable = plist[[MADDataColumn keyColumn]];
        NSMutableArray *column = [[NSMutableArray alloc] initWithArray: columnImmutable];
        
        id defaultValue = plist[[MADDataColumn keyDefaultValue]];
        NSString *caption = plist[[MADDataColumn keyCaption]];
        NSNumber *columnType = plist[[MADDataColumn keyColumnType]];
        NSNumber *nativeColumnType = plist[[MADDataColumn keyNativeColumnType]];
        NSNumber *dataLength = plist[[MADDataColumn keyDataLength]];
        NSNumber *dataPercision = plist[[MADDataColumn keyDataPercision]];
        
        BOOL isPrimaryKey = [plist[[MADDataColumn keyIsPrimaryKey]] boolValue];
        BOOL isNotNull = [plist[[MADDataColumn keyIsNotNull]] boolValue];
        BOOL isAutoIncrement = [plist[[MADDataColumn keyIsAutoIncrement]] boolValue];
        
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

- (id)objectAtIndex:(NSUInteger)index {
    NSAssert(index < [self.column count], @"Column doesn't exit!");
    return self.column[index];
}

- (void)addObject:(id)object {
    [self.column addObject:object];
}

- (void)addRows:(NSUInteger)count {
    for (NSUInteger i = 0; i <= count; i++) {
        [self.column addObject:self.defaultValue];
    }
}

- (NSDictionary *)plist {
    
    NSMutableDictionary *plist = [[NSMutableDictionary alloc] initWithCapacity:8];
    NSString *keyFieldName = [MADDataColumn keyFieldName];
    NSString *keyIdentifier = [MADDataColumn keyIdentifier];
    NSString *keyColumn = [MADDataColumn keyColumn];
    NSString *keyDefaultValue = [MADDataColumn keyDefaultValue];
    NSString *keyCaption = [MADDataColumn keyCaption];
    NSString *keyColumnType = [MADDataColumn keyColumnType];
    NSString *keyNativeColumnType = [MADDataColumn keyNativeColumnType];
    NSString *keyDataLength = [MADDataColumn keyDataLength];
    NSString *keyDataPercision = [MADDataColumn keyDataPercision];
    NSString *keyIsPrimaryKey = [MADDataColumn keyIsPrimaryKey];
    NSString *keyIsNotNull = [MADDataColumn keyIsNotNull];
    NSString *keyIsAutoIncrement = [MADDataColumn keyIsAutoIncrement];
    
    NSNumber *primaryKey = @([self isPrimaryKey]);
    NSNumber *notNull = @([self isNotNull]);
    NSNumber *autoIncrement = @([self isAutoIncrement]);

    id defaultValue = [self defaultValue];
    if ([defaultValue isEqual:[NSNull null]]) {
        defaultValue = @"~MTNull~";
    }
    
    plist[keyFieldName] = [self fieldName];
    plist[keyIdentifier] = [self identifier];
    plist[keyColumn] = self.column;
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
    [self.column removeAllObjects];
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
