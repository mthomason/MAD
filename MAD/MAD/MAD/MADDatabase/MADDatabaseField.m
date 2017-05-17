//
//  MNSDatabaseField.m
//  Reports
//
//  Created by Michael Thomason on 11/18/12.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADDatabaseField.h"
#import "NSData+Comparson.h"
#import <Foundation/NSString.h>
#import <MADFoundation/MADDataType.h>
#import "RptqDatabaseSchemaField.h"

static inline BOOL isDataTypeNumeric(MADDataType type);
static inline BOOL isDataTypeNumeric(MADDataType type) {
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
            return YES;
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
            return NO;
            break;
    }
}

@interface MADDatabaseField ()

@end

@implementation MADDatabaseField

- (instancetype)initWithName:(NSString *)name {
    if (self = [self init]) {
        _name = name.copy;
        _calculatedWidth = 0;
    }
    return self;
}

+ (instancetype)newDatabaseFieldWithSchemaField:(RptqDatabaseSchemaField *)schemaField {
    MADDatabaseField *result = [[MADDatabaseField alloc] init];
    result.name = schemaField.name.copy;
    result.fieldType = schemaField.dataType;
    result.fieldTypeNative = schemaField.dataTypeNative;
    result.decimals = schemaField.decimals;
    result.primaryKey = schemaField.primaryKey;
    return result;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    MADDatabaseField *copy = [[[self class] allocWithZone:zone] init];
    copy.name = _name.copy;
    copy.fieldType = _fieldType;
    copy.fieldTypeNative = _fieldTypeNative;
    copy.width = _width;
    copy.decimals = _decimals;
    copy.primaryKey = _primaryKey;
    return copy;
}

- (BOOL)isNumeric { return isDataTypeNumeric(_fieldType); }

+ (BOOL)isNumeric:(MADDataType)dataType { return isDataTypeNumeric(dataType); }

- (SEL)selectorForSorting {
    return MADDataTypeSelectorForSorting(self.fieldType);
}

@end
