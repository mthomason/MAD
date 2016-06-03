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
#import <MADFoundation/MADDataType.h>

static inline bool isDataTypeNumeric(MADDataType type);
static inline bool isDataTypeNumeric(MADDataType type) {
    switch (type) {
        case MADDataTypeBit:
        case MADDataTypeFloat:
        case MADDataTypeInteger:
        case MADDataTypeNumber:
        case MADDataTypeDecimal:
        case MADDataTypeDouble:
        case MADDataTypeEnum:
        case MADDataTypeInt24:
        case MADDataTypeLong:
        case MADDataTypeLongLong:
        case MADDataTypeShort:
            return true;
            break;
        case MADDataTypeBlob:
        case MADDataTypeDate:
        case MADDataTypeDateTime:
        case MADDataTypeGeometry:
        case MADDataTypeImage:
        case MADDataTypeSet:
        case MADDataTypeString:
        case MADDataTypeTime:
        case MADDataTypeTimeStamp:
        case MADDataTypeYear:
        case MADDataTypeUnknown:
        case MADDataTypeVarChar:
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

+ (BOOL)isNumeric:(MADDataType)dataType { return isDataTypeNumeric(dataType) ? YES : NO; }

- (SEL)selectorForSorting {
    return MADDataTypeSelectorForSorting(self.fieldType);
}

@end
