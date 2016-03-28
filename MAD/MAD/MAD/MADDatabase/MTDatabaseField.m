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

- (BOOL)isNumeric { return [MTDatabaseField isNumeric: _fieldType]; }

+ (BOOL)isNumeric:(MTDataType)dataType {
    BOOL result;
    switch (dataType) {
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
            result = YES;
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
            result = NO;
            break;
    }
    return result;
}

- (SEL)selectorForSorting {
    return [MADDataType selectorForSorting:self.fieldType];
}

@end
