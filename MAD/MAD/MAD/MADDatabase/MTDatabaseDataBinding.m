//
//  MTDatabaseDataBinding.m
//  MAD
//
//  Created by Michael Thomason on 4/19/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTDatabaseDataBinding.h"
#import "MTDatabaseField.h"
#import <Foundation/NSNull.h>
#import <Foundation/NSString.h>

static inline MTDataType DataTypeLimited(MTDataType expandedDataType) {
    switch (expandedDataType) {
        case MTDataTypeBit:
        case MTDataTypeInteger:
        case MTDataTypeShort:
        case MTDataTypeLong:
        case MTDataTypeLongLong:
        case MTDataTypeInt24:
        case MTDataTypeEnum: {
            return MTDataTypeInteger;
            break;
        }
        case MTDataTypeSet:
        case MTDataTypeTime:
        case MTDataTypeTimeStamp:
        case MTDataTypeYear:
        case MTDataTypeDate:
        case MTDataTypeDateTime:
        case MTDataTypeString:
        case MTDataTypeVarChar:
        case MTDataTypeGeometry: {
            return MTDataTypeString;
            break;
        }
        case MTDataTypeImage:
        case MTDataTypeBlob: {
            return MTDataTypeBlob;
            break;
        }
        case MTDataTypeFloat: {
            return MTDataTypeFloat;
            break;
        }
        case MTDataTypeDouble:
        case MTDataTypeDecimal:
        case MTDataTypeNumber: {
            return MTDataTypeDouble;
            break;
        }
        case MTDataTypeUnknown:
        default: {
            return MTDataTypeUnknown;
            break;
        }
    }
}

@interface MTDatabaseDataBinding ()

    - (instancetype)init NS_DESIGNATED_INITIALIZER;

    @property (nonatomic, strong, readwrite) id value;
    @property (nonatomic, assign, readwrite) MTDataType datatype;
    @property (nonatomic, assign, readwrite) int fieldIndex;

@end

@implementation MTDatabaseDataBinding

- (int)columnNumber {
    return self.fieldIndex + 1;
}

- (instancetype)init {
    if (self = [super init]) {
        self.value = nil;
        self.datatype = MTDataTypeNull;
        self.fieldIndex = 0;
    }
    return self;
}

- (instancetype)initWithDataType:(MTDataType)datatype fieldIndex:(NSUInteger)fieldIndex
                           value:(id)value {

    if (self = [super init]) {
        
        if (value == nil || value == [NSNull null]) {
            datatype = MTDataTypeNull;
            value = [NSNull null];
        } else {
            datatype = DataTypeLimited(datatype);
            if (datatype == MTDataTypeUnknown) {
                value = [NSString stringWithFormat:@"%@", value];
                datatype = MTDataTypeString;
            }
        }
        self.datatype = datatype;
        self.fieldIndex = (int)fieldIndex;
        self.value = value;
    }
    return self;
}

@end
