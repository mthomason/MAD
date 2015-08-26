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

@interface MTDatabaseField ()

@end

@implementation MTDatabaseField

- (instancetype)initWithName:(NSString *)name {
    self = [self init];
    if (self) {
        self.label = name;
        self.name = name;
        self.calculatedWidth = 0;
    }
    return self;
}



- (BOOL)isNumeric {
    return [MTDatabaseField isNumeric:[self fieldType]];
}

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
    return [MTDataTypeObject selectorForSorting:self.fieldType];
}

@end
