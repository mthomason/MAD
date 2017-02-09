//
//  MADDataType.m
//  MAD
//
//  Created by Michael Thomason on 3/31/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import <MADFoundation/MADDataType.h>
#import <Foundation/NSObject.h>
#import <Foundation/NSString.h>
#import "NSData+Comparson.h"

SEL MADDataTypeSelectorForSorting(MADDataType dataType) {
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
            //NSAssert(NO, @"Not implemented: selectorForSorted in MADDatabaseField.");
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
