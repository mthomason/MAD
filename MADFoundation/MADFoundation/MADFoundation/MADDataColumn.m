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
    
    
    [encoder encodeObject: self.fieldName                   forKey: [MADDataColumn keyFieldName]];
    [encoder encodeObject: self.identifier                  forKey: [MADDataColumn keyIdentifier]];
    [encoder encodeObject: self.column                      forKey: [MADDataColumn keyColumn]];
    [encoder encodeObject: self.defaultValue                forKey: [MADDataColumn keyDefaultValue]];
    [encoder encodeObject: self.caption                     forKey: [MADDataColumn keyCaption]];
    
    NSNumber *type;
    [encoder encodeObject: type                             forKey: [MADDataColumn keyColumnType]];
    self.type = type.shortValue;
    
    NSNumber *nativeType;
    [encoder encodeObject: nativeType                       forKey: [MADDataColumn keyNativeColumnType]];
    self.nativeType = nativeType.integerValue;
    
    NSNumber *dataLength;
    [encoder encodeObject: dataLength                  forKey: [MADDataColumn keyDataLength]];
    self.dataLength = dataLength.integerValue;
    
    NSNumber *dataPercision;
    [encoder encodeObject: dataPercision               forKey: [MADDataColumn keyDataPercision]];
    self.dataPercision = dataPercision.integerValue;
    
    
    [encoder encodeBool: self.isPrimaryKey ? YES : NO       forKey: [MADDataColumn keyIsPrimaryKey]];
    [encoder encodeBool: self.isNotNull ? YES : NO          forKey: [MADDataColumn keyIsNotNull]];
    [encoder encodeBool: self.isAutoIncrement ? YES : NO    forKey: [MADDataColumn keyIsAutoIncrement]];

}

- (instancetype)initWithCoder:(NSCoder *)decoder {

    if (self = [super init]) {

        self.fieldName =            [decoder decodeObjectForKey: [MADDataColumn keyFieldName]];
        self.identifier =           [decoder decodeObjectForKey: [MADDataColumn keyIdentifier]];
        self.column =               [decoder decodeObjectForKey: [MADDataColumn keyColumn]];
        self.defaultValue =         [decoder decodeObjectForKey: [MADDataColumn keyDefaultValue]];
        self.caption =              [decoder decodeObjectForKey: [MADDataColumn keyCaption]];
        
        NSNumber *type =            [decoder decodeObjectForKey: [MADDataColumn keyColumnType]];
        self.type =                 type.shortValue;
        
        NSNumber *nativeType =      [decoder decodeObjectForKey: [MADDataColumn keyNativeColumnType]];
        self.nativeType =           nativeType.integerValue;
        
        NSNumber *dataLength =      [decoder decodeObjectForKey: [MADDataColumn keyDataLength]];
        self.dataLength =           dataLength.integerValue;

        NSNumber *dataPercision =   [decoder decodeObjectForKey: [MADDataColumn keyDataPercision]];
        self.dataPercision =        dataPercision.integerValue;
        
        self.primaryKey =           [decoder decodeBoolForKey: [MADDataColumn keyIsPrimaryKey]] ? true : false;

    }
    return self;
}

/*
- (instancetype)initWithIdentifier:(NSString *)identifier {
    
    if (self = [super init]) {
        
        NSString *identifierW = [[NSString alloc] initWithString:identifier];
        self.identifier = identifierW;
        
        NSString *caption = [[NSString alloc] initWithString:identifier];
        self.caption = caption;
        
        NSMutableArray *column = [[NSMutableArray alloc] init];
        self.column = column;
        
        _defaultValue = [NSNull null];
        
        NSNumber *columnType = [[NSNumber alloc] initWithInteger:0];
        self.columnType = columnType;
        
        NSNumber *nativeType = [[NSNumber alloc] initWithInteger:0];
        self.nativeType = nativeType;
        
        NSNumber *dataLength = [[NSNumber alloc] initWithInteger:0];
        self.dataLength = dataLength;
        
        NSNumber *dataPercision = [[NSNumber alloc] initWithInteger:0];
        self.dataPercision = dataPercision;
        
        _primaryKey = NO;
        _notNull = NO;
        _autoIncrement = NO;
        
    }
    return self;
}
*/

- (instancetype)initWithIdentifier:(NSString *)identifier {

    if (self = [super init]) {

        NSString *identifierW = [[NSString alloc] initWithString:identifier];
        self.identifier = identifierW;
        
        NSString *caption = [[NSString alloc] initWithString:identifier];
        self.caption = caption;
        
        NSMutableArray *column = [[NSMutableArray alloc] init];
        self.column = column;

        _defaultValue = [NSNull null];
        _type = 0;
        _nativeType = 0;
        _dataLength = 0;
        _dataPercision = 0;

        _primaryKey = NO;
        _notNull = NO;
        _autoIncrement = NO;
        
    }
    return self;
}

- (instancetype)initWithPlist:(NSDictionary *)plist {

    if (self = [super init]) {
        
        NSString *fieldName = plist[[MADDataColumn keyFieldName]];
        _fieldName = fieldName.copy;

        NSString *identifier = plist[[MADDataColumn keyIdentifier]];
        _identifier = identifier;
        
        NSArray *columnImmutable = plist[[MADDataColumn keyColumn]];
        NSMutableArray *column = [[NSMutableArray alloc] initWithArray: columnImmutable];
        self.column = column;
        
        id defaultValue = plist[[MADDataColumn keyDefaultValue]];
        self.defaultValue = defaultValue;

        NSString *caption = plist[[MADDataColumn keyCaption]];
        _caption = caption.copy;

        NSNumber *columnType = plist[[MADDataColumn keyColumnType]];
        _type = columnType.shortValue;

        NSNumber *nativeType = plist[[MADDataColumn keyNativeColumnType]];
        _nativeType = nativeType.integerValue;

        NSNumber *dataLength = plist[[MADDataColumn keyDataLength]];
        _dataLength = dataLength.integerValue;

        NSNumber *dataPercision = plist[[MADDataColumn keyDataPercision]];
        _dataPercision = dataPercision.integerValue;
        
        NSNumber *isPrimaryKey = plist[[MADDataColumn keyIsPrimaryKey]];
        _primaryKey = isPrimaryKey.boolValue ? true : false;

        NSNumber *isNotNull = plist[[MADDataColumn keyIsNotNull]];
        _notNull = isNotNull.boolValue ? true : false;

        NSNumber *isAutoIncrement = plist[[MADDataColumn keyIsAutoIncrement]];
        _autoIncrement = isAutoIncrement.boolValue ? true : false;
        
    }
    return self;
}

+ (MADDataColumn *)newDataColumnWithIdentifier:(NSString *)identifier {
    MADDataColumn *column = [[MADDataColumn alloc] initWithIdentifier:identifier];
    column.type = MTDataTypeInteger;
    column.primaryKey = true;
    column.notNull = true;
    column.autoIncrement = false;
    return column;
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
    plist[keyFieldName] = [self fieldName];

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
    
    NSNumber *primaryKey = [[NSNumber alloc] initWithBool:self.isPrimaryKey];
    NSNumber *notNull = [[NSNumber alloc] initWithBool:self.isNotNull];
    NSNumber *autoIncrement = [[NSNumber alloc] initWithBool:self.isAutoIncrement];

    id defaultValue = self.defaultValue;
    if ([defaultValue isEqual:[NSNull null]]) {
        defaultValue = @"~MTNull~";
    }
    
    plist[keyIdentifier] = self.identifier;
    plist[keyColumn] = self.column;
    plist[keyDefaultValue] = defaultValue;
    plist[keyCaption] = self.caption;
    
    id type = [[NSNumber alloc] initWithShort:self.type];
    plist[keyColumnType] = type;
    
    id nativeType = [[NSNumber alloc] initWithInteger:self.nativeType];
    plist[keyNativeColumnType] = nativeType;
    
    id dataLength = [[NSNumber alloc] initWithInteger:self.dataLength];
    plist[keyDataLength] = dataLength;
    
    id dataPercision = [[NSNumber alloc] initWithInteger:self.dataPercision];
    plist[keyDataPercision] = dataPercision;
    
    
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
