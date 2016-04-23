//
//  MNSDatabaseField.m
//  Reports
//
//  Created by Michael Thomason on 11/18/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTDatabaseField.h"
#import "NSData+Comparson.h"
#import <Foundation/NSString.h>

static inline bool isDataTypeNumeric(MTDataType type);
static inline bool isDataTypeNumeric(MTDataType type) {
    switch (type) {
        case MTDataTypeBit:
        case MTDataTypeFloat:
        case MTDataTypeInteger:
        case MTDataTypeNumber:
        case MTDataTypeDecimal:
        case MTDataTypeDouble:
        case MTDataTypeEnum:
        case MTDataTypeInt24:
        case MTDataTypeLong:
        case MTDataTypeLongLong:
        case MTDataTypeShort:
            return true;
            break;
        case MTDataTypeBlob:
        case MTDataTypeDate:
        case MTDataTypeDateTime:
        case MTDataTypeGeometry:
        case MTDataTypeImage:
        case MTDataTypeSet:
        case MTDataTypeString:
        case MTDataTypeTime:
        case MTDataTypeTimeStamp:
        case MTDataTypeYear:
        case MTDataTypeUnknown:
        case MTDataTypeVarChar:
        default:
            return false;
            break;
    }
}

@interface MTDatabaseField ()

@end

@implementation MTDatabaseField

- (instancetype)initWithName:(NSString *)name {
    if (self = [self init]) {
        _name = name.copy;
        _calculatedWidth = 0;
    }
    return self;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    MTDatabaseField *copy = [[[self class] allocWithZone:zone] init];
    NSString *name = _name.copy;
    copy.name = name;
    copy.fieldType = _fieldType;
    copy.fieldTypeNative = _fieldTypeNative;
    copy.width = _width;
    copy.decimals = _decimals;
    copy.primaryKey = _primaryKey;
    return copy;
}

- (BOOL)isNumeric { return isDataTypeNumeric(_fieldType) ? YES : NO; }

+ (BOOL)isNumeric:(MTDataType)dataType { return isDataTypeNumeric(dataType) ? YES : NO; }

- (SEL)selectorForSorting {
    return [MADDataType selectorForSorting:self.fieldType];
}

@end
