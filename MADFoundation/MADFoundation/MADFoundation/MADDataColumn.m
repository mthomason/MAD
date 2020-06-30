//
//  DataColumn.m
//  libMTDataStrutures
//
//  Created by Michael Thomason on 4/6/14.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADDataColumn.h"
#import <CoreFoundation/CFNumber.h>
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
    
    
    [encoder encodeObject:  self.fieldName      forKey: [MADDataColumn keyFieldName]];
    [encoder encodeObject:  self.identifier     forKey: [MADDataColumn keyIdentifier]];
    [encoder encodeObject:  self.column         forKey: [MADDataColumn keyColumn]];
    [encoder encodeObject:  self.defaultValue   forKey: [MADDataColumn keyDefaultValue]];
    [encoder encodeObject:  self.caption        forKey: [MADDataColumn keyCaption]];
    [encoder encodeInt64:   self.type           forKey: [MADDataColumn keyColumnType]];
    [encoder encodeInt:     self.nativeType     forKey: [MADDataColumn keyNativeColumnType]];
    [encoder encodeInt64:   self.dataLength     forKey: [MADDataColumn keyDataLength]];
    [encoder encodeInteger: self.dataPercision  forKey: [MADDataColumn keyDataPercision]];
    
    
    [encoder encodeBool: _primaryKey       forKey: [MADDataColumn keyIsPrimaryKey]];
    [encoder encodeBool: _notNull          forKey: [MADDataColumn keyIsNotNull]];
    [encoder encodeBool: _autoIncrement    forKey: [MADDataColumn keyIsAutoIncrement]];

}

- (instancetype)initWithCoder:(NSCoder *)decoder {

    if (self = [super init]) {

        self.fieldName =            [decoder decodeObjectForKey: [MADDataColumn keyFieldName]];
        self.identifier =           [decoder decodeObjectForKey: [MADDataColumn keyIdentifier]];
        self.column =               [decoder decodeObjectForKey: [MADDataColumn keyColumn]];
        self.defaultValue =         [decoder decodeObjectForKey: [MADDataColumn keyDefaultValue]];
        self.caption =              [decoder decodeObjectForKey: [MADDataColumn keyCaption]];
        self.type =                 (int16_t)[decoder decodeIntForKey:  [MADDataColumn keyColumnType]];
        self.nativeType =           (int16_t)[decoder decodeIntForKey: [MADDataColumn keyNativeColumnType]];
        self.dataLength =           [decoder decodeIntegerForKey: [MADDataColumn keyDataLength]];
        self.dataPercision =        [decoder decodeIntForKey: [MADDataColumn keyDataPercision]];
        self.primaryKey =           [decoder decodeBoolForKey: [MADDataColumn keyIsPrimaryKey]];

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

- (instancetype)initWithType:(MADDataType)columnType
                        name:(NSString *)name
                      number:(int)columnNumber
                     dataLen:(int)dataLength
                 indexOfType:(int)indexOfType
                      length:(NSInteger)length
                   percision:(int32_t)percision
                  nativeType:(int16_t)nativeType {
    if (self = [super init]) {

        NSMutableArray *column = [[NSMutableArray alloc] init];
        self.column = column;
        self.type = columnType;
        self.identifier = name.copy;
        self.caption = name.copy;
        self.fieldName = name.copy;
        self.nativeType = nativeType;
        self.dataLength = length;
        self.dataPercision = percision;

    }
    return self;
}

- (instancetype)initWithIdentifier:(NSString *)identifier {

    if (self = [super init]) {

        self.identifier = identifier.copy;
        
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

        CFNumberRef nativeType = (__bridge CFNumberRef)(plist[[MADDataColumn keyNativeColumnType]]);
        CFNumberGetValue(nativeType, kCFNumberSInt16Type, &_nativeType);

        NSNumber *dataLength = plist[[MADDataColumn keyDataLength]];
        _dataLength = dataLength.integerValue;

        CFNumberRef dataPercision = (__bridge CFNumberRef)(plist[[MADDataColumn keyDataPercision]]);
        CFNumberGetValue(dataPercision, kCFNumberSInt32Type, &_dataPercision);
        
        NSNumber *isPrimaryKey = plist[[MADDataColumn keyIsPrimaryKey]];
        _primaryKey = isPrimaryKey.boolValue;

        NSNumber *isNotNull = plist[[MADDataColumn keyIsNotNull]];
        _notNull = isNotNull.boolValue;

        NSNumber *isAutoIncrement = plist[[MADDataColumn keyIsAutoIncrement]];
        _autoIncrement = isAutoIncrement.boolValue;
        
    }
    return self;
}

+ (MADDataColumn *)newDataColumnWithIdentifier:(NSString *)identifier {
    MADDataColumn *column = [[MADDataColumn alloc] initWithIdentifier:identifier];
    column.type = MADDataTypeInteger;
    column.primaryKey = YES;
    column.notNull = YES;
    column.autoIncrement = NO;
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
    NSMutableDictionary *plist = [[NSMutableDictionary alloc] initWithCapacity: (plistCapacity + 1)];

    id key;
    key = [MADDataColumn keyFieldName];
    plist[key] = self.fieldName;

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
    CFNumberRef dataLen = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt64Type, &_dataLength);
    plist[key] = (__bridge id _Nullable)(dataLen);
    CFRelease(dataLen);

    key = [MADDataColumn keyDataPercision];
    CFNumberRef dataPer = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &_dataPercision);
    plist[key] = (__bridge id _Nullable)(dataPer);
    CFRelease(dataPer);
    
    obj = [[NSNumber alloc] initWithBool:_primaryKey];
    key = [MADDataColumn keyIsPrimaryKey];
    plist[key] = obj;

    obj = [[NSNumber alloc] initWithBool:_notNull];
    key = [MADDataColumn keyIsNotNull];
    plist[key] = obj;

    obj = [[NSNumber alloc] initWithBool:_autoIncrement];
    key = [MADDataColumn keyIsAutoIncrement];
    plist[key] = obj;

    //NSAssert(plist.count == plistCapacity, @"Need to update dictionary size.");
    
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
