//
//  MTDataType.h
//  MAD
//
//  Created by Michael Thomason on 9/28/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MTDataType_h
#define MAD_MTDataType_h

typedef NS_ENUM(NSUInteger, MTDataType) {
    MTDataTypeBit           = 0,
    MTDataTypeBlob          = 1,
    MTDataTypeDate          = 2,
    MTDataTypeDateTime      = 3,
    MTDataTypeFloat         = 5,
    MTDataTypeGeometry      = 6,
    MTDataTypeImage         = 7,
    MTDataTypeInteger       = 8,
    MTDataTypeNumber        = 9,
    MTDataTypeSet           = 10,
    MTDataTypeString        = 11,
    MTDataTypeTime          = 12,
    MTDataTypeTimeStamp     = 13,
    MTDataTypeYear          = 14,
    MTDataTypeUnknown       = 15,
    MTDataTypeDecimal       = 16,
    MTDataTypeDouble        = 17,
    MTDataTypeEnum          = 18,
    MTDataTypeInt24         = 19,
    MTDataTypeLong          = 20,
    MTDataTypeLongLong      = 21,
    MTDataTypeVarChar       = 22,
    MTDataTypeShort         = 23,
    MTDataTypeNull          = 24
};

@interface MADDataType : NSObject

+ (SEL)selectorForSorting:(MTDataType)dataType;

@end

#endif

