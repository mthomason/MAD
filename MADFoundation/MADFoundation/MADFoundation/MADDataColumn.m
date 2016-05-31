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
    
    
    [encoder encodeBool: _primaryKey ? YES : NO       forKey: [MADDataColumn keyIsPrimaryKey]];
    [encoder encodeBool: _notNull ? YES : NO          forKey: [MADDataColumn keyIsNotNull]];
    [encoder encodeBool: _autoIncrement ? YES : NO    forKey: [MADDataColumn keyIsAutoIncrement]];

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
        _identifier = identifier.copy;
        
        NSArray *columnImmutable = plist[[MADDataColumn keyColumn]];
        NSMutableArray *column = [[NSMutableArray alloc] initWithArray: columnImmutable];
        _column = column;
        
        NSObject <NSCopying> *defaultValue;
        defaultValue = plist[[MADDataColumn keyDefaultValue]];
        _defaultValue = defaultValue.copy;

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

- (NSDictionary *)copyPlist {
    const NSUInteger plistCapacity = 12;
    NSMutableDictionary *plist = [[NSMutableDictionary alloc] initWithCapacity: plistCapacity];

    id key;
    key = [MADDataColumn keyFieldName];
    plist[key] = [self fieldName];

    key= [MADDataColumn keyIdentifier];
    id obj;
    obj = _identifier.copy;
    plist[key] = obj;

    key = [MADDataColumn keyColumn];
    obj = _column.copy;
    plist[key] = obj;

    key = [MADDataColumn keyDefaultValue];
    obj = _defaultValue.copy;
    if ([obj isEqual:[NSNull null]]) {
        obj = @"~MTNull~";
    }
    plist[key] = obj;

    key = [MADDataColumn keyCaption];
    plist[key] = self.caption;
    
    key = [MADDataColumn keyColumnType];
    obj = [[NSNumber alloc] initWithShort:_type];
    plist[key] = obj;
    
    key = [MADDataColumn keyNativeColumnType];
    obj = [[NSNumber alloc] initWithInteger:_nativeType];
    plist[key] = obj;
    
    key = [MADDataColumn keyDataLength];
    obj = [[NSNumber alloc] initWithInteger:_dataLength];
    plist[key] = obj;
    
    obj = [[NSNumber alloc] initWithInteger:_dataPercision];
    key = [MADDataColumn keyDataPercision];
    plist[key] = obj;
    
    obj = [[NSNumber alloc] initWithBool:_primaryKey];
    key = [MADDataColumn keyIsPrimaryKey];
    plist[key] = obj;

    obj = [[NSNumber alloc] initWithBool:_notNull];
    key = [MADDataColumn keyIsNotNull];
    plist[key] = obj;

    obj = [[NSNumber alloc] initWithBool:_autoIncrement];
    key = [MADDataColumn keyIsAutoIncrement];
    plist[key] = obj;

    NSAssert(plist.count == plistCapacity, @"Need to update dictionary size.");
    
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
    SEL sel = @selector(type);
    return NSStringFromSelector(sel);
}

+ (NSString *)keyNativeColumnType {
    SEL sel = @selector(nativeType);
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
