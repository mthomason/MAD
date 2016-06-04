//
//  MADDataType.h
//  MAD
//
//  Created by Michael Thomason on 9/28/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MADFoundation_MADDataType_h
#define MADFoundation_MADDataType_h

#import <Foundation/NSObjCRuntime.h>
#import <Foundation/NSObject.h>
#import <Foundation/NSString.h>
#import "NSData+Comparson.h"

typedef NS_ENUM(short, MADDataType) {
    MADDataTypeBit           = 0,
    MADDataTypeBlob          = 1,
    MADDataTypeDate          = 2,
    MADDataTypeDateTime      = 3,
    MADDataTypeFloat         = 5,
    MADDataTypeGeometry      = 6,
    MADDataTypeImage         = 7,
    MADDataTypeInteger       = 8,
    MADDataTypeNumber        = 9,
    MADDataTypeSet           = 10,
    MADDataTypeString        = 11,
    MADDataTypeTime          = 12,
    MADDataTypeTimeStamp     = 13,
    MADDataTypeYear          = 14,
    MADDataTypeUnknown       = 15,
    MADDataTypeDecimal       = 16,
    MADDataTypeDouble        = 17,
    MADDataTypeEnum          = 18,
    MADDataTypeInt24         = 19,
    MADDataTypeLong          = 20,
    MADDataTypeLongLong      = 21,
    MADDataTypeVarChar       = 22,
    MADDataTypeShort         = 23,
    MADDataTypeNull          = 24
};


static inline SEL MADDataTypeSelectorForSorting(MADDataType dataType);
static inline SEL MADDataTypeSelectorForSorting(MADDataType dataType) {
    switch (dataType) {
        case MADDataTypeDate:
        case MADDataTypeDateTime:
        case MADDataTypeGeometry:
        case MADDataTypeImage:
        case MADDataTypeSet:
        case MADDataTypeTime:
        case MADDataTypeTimeStamp:
        case MADDataTypeYear:
        case MADDataTypeUnknown:
            //NSAssert(NO, @"Not implemented: selectorForSorted in MTDatabaseField.");
        case MADDataTypeBit:
        case MADDataTypeFloat:
        case MADDataTypeInteger:
        case MADDataTypeNumber:
            return @selector(compare:);
            break;

        case MADDataTypeBlob:
            return @selector(compareData:);
            break;

        case MADDataTypeString:
            return @selector(localizedCaseInsensitiveCompare:);
            break;
            
        default:
            return @selector(compare:);
            break;
    }
}

#endif

