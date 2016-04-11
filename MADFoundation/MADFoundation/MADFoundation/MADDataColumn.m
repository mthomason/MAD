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
#import <CoreFoundation/CFNumber.h>

@interface MADDataColumn ()

@property (nonatomic, copy, readwrite) NSString *identifier;
@property (nonatomic, strong) NSMutableArray *column;

@end

@implementation MADDataColumn

- (void)encodeWithCoder:(NSCoder *)encoder {
    
    [encoder encodeValueOfObjCType:@encode(MTDataType)      at:&_columnType];
    [encoder encodeValueOfObjCType:@encode(NSUInteger)      at:&_dataLength];
    [encoder encodeValueOfObjCType:@encode(NSUInteger)      at:&_dataPercision];

    [encoder encodeObject: self.fieldName                   forKey: [MADDataColumn keyFieldName]];
    [encoder encodeObject: self.identifier                  forKey: [MADDataColumn keyIdentifier]];
    [encoder encodeObject: self.column                      forKey: [MADDataColumn keyColumn]];
    [encoder encodeObject: self.defaultValue                forKey: [MADDataColumn keyDefaultValue]];
    [encoder encodeObject: self.caption                     forKey: [MADDataColumn keyCaption]];

    [encoder encodeInteger: self.nativeColumnType           forKey: [MADDataColumn keyNativeColumnType]];
    
    [encoder encodeBool: self.isPrimaryKey ? YES : NO       forKey: [MADDataColumn keyIsPrimaryKey]];
    [encoder encodeBool: self.isNotNull ? YES : NO          forKey: [MADDataColumn keyIsNotNull]];
    [encoder encodeBool: self.isAutoIncrement ? YES : NO    forKey: [MADDataColumn keyIsAutoIncrement]];

}

- (instancetype)initWithCoder:(NSCoder *)decoder {

    MTDataType datat;
    NSUInteger datav;

    [decoder decodeValueOfObjCType:@encode(MTDataType) at:&datat];
    self.columnType = datat;
    
    [decoder decodeValueOfObjCType: @encode(NSUInteger) at:&datav];
    self.dataLength = datav;
    
    [decoder decodeValueOfObjCType: @encode(NSUInteger) at:&datav];
    self.dataPercision =    datav;

    self.fieldName =        [decoder decodeObjectForKey:    [MADDataColumn keyFieldName]];
    self.identifier =       [decoder decodeObjectForKey:    [MADDataColumn keyIdentifier]];
    self.column =           [decoder decodeObjectForKey:    [MADDataColumn keyColumn]];
    self.defaultValue =     [decoder decodeObjectForKey:    [MADDataColumn keyDefaultValue]];
    self.caption =          [decoder decodeObjectForKey:    [MADDataColumn keyCaption]];
    
    self.nativeColumnType = [decoder decodeIntegerForKey:   [MADDataColumn keyNativeColumnType]];
    
    self.primaryKey =       [decoder decodeBoolForKey:      [MADDataColumn keyIsPrimaryKey]]        ? true : false;
    self.notNull =          [decoder decodeBoolForKey:      [MADDataColumn keyIsNotNull]]           ? true : false;
    self.autoIncrement =    [decoder decodeBoolForKey:      [MADDataColumn keyIsAutoIncrement]]     ? true : false;

    return self;
}

- (instancetype)initWithIdentifier:(NSString *)identifier {

    if (self = [super init]) {

        NSString *identifierW = [[NSString alloc] initWithString:identifier];
        self.identifier = identifierW;
        
        NSString *caption = [[NSString alloc] initWithString:identifier];
        self.caption = caption;
        
        NSMutableArray *column = [[NSMutableArray alloc] init];
        self.column = column;

        _defaultValue = [NSNull null];
        
        self.columnType = 0;
        self.nativeColumnType = 0;
        self.dataLength = 0;
        self.dataPercision = 0;

        _primaryKey     = false;
        _notNull        = false;
        _autoIncrement  = false;
        
    }
    return self;
}

- (instancetype)initWithPlist:(id)plist {

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
        _columnType = columnType.shortValue;

        NSNumber *nativeColumnType = plist[[MADDataColumn keyNativeColumnType]];
        _nativeColumnType = nativeColumnType.integerValue;

        NSNumber *dataLength = plist[[MADDataColumn keyDataLength]];
        _dataLength = dataLength.unsignedIntegerValue;

        NSNumber *dataPercision = plist[[MADDataColumn keyDataPercision]];
        _dataPercision = dataPercision.unsignedIntegerValue;
        
        NSNumber *isPrimaryKey = plist[[MADDataColumn keyIsPrimaryKey]];
        _primaryKey = isPrimaryKey.boolValue ? true : false;

        NSNumber *isNotNull = plist[[MADDataColumn keyIsNotNull]];
        _notNull = isNotNull.boolValue ? true : false;

        NSNumber *isAutoIncrement = plist[[MADDataColumn keyIsAutoIncrement]];
        _autoIncrement = isAutoIncrement.boolValue ? true : false;
        
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
    
    NSNumber *primaryKey = @([self isPrimaryKey]);
    NSNumber *notNull = @([self isNotNull]);
    NSNumber *autoIncrement = @([self isAutoIncrement]);

    id defaultValue = self.defaultValue;
    if ([defaultValue isEqual:[NSNull null]]) {
        defaultValue = @"~MTNull~";
    }
    
    plist[keyIdentifier] = self.identifier;
    plist[keyColumn] = self.column;
    plist[keyDefaultValue] = defaultValue;
    plist[keyCaption] = self.caption;
    
    NSNumber *columnType = [[NSNumber alloc] initWithShort:self.columnType];
    plist[keyColumnType] = columnType;
    
    NSNumber *nativeColumnType = [[NSNumber alloc] initWithUnsignedInteger:self.columnType];
    plist[keyNativeColumnType] = nativeColumnType;

    NSNumber *dataLength = [[NSNumber alloc] initWithUnsignedInteger:self.dataLength];
    plist[keyDataLength] = dataLength;

    NSNumber *dataPercision = [[NSNumber alloc] initWithUnsignedInteger:self.dataPercision];
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
