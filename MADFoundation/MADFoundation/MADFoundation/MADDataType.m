//
//  MTDataType.m
//  MAD
//
//  Created by Michael Thomason on 3/31/15.
//  Copyright (c) 2015 Everyday Apps LLC. All rights reserved.
//

#import <MADFoundation/MADDataType.h>
#import <Foundation/NSData.h>
#import <Foundation/NSString.h>
#import "NSData+Comparson.h"

@implementation MADDataType

+ (SEL)selectorForSorting:(MTDataType)dataType {
    SEL result;
    switch (dataType) {
        case MTDataTypeDate:
        case MTDataTypeDateTime:
        case MTDataTypeGeometry:
        case MTDataTypeImage:
        case MTDataTypeSet:
        case MTDataTypeTime:
        case MTDataTypeTimeStamp:
        case MTDataTypeYear:
        case MTDataTypeUnknown:
            //NSAssert(false, @"Not implemented: selectorForSorted in MTDatabaseField.");
        case MTDataTypeBit:
        case MTDataTypeFloat:
        case MTDataTypeInteger:
        case MTDataTypeNumber:
            result = @selector(compare:);
            break;
        case MTDataTypeBlob:
            result = @selector(compareData:);
            break;
        case MTDataTypeString:
            result = @selector(localizedCaseInsensitiveCompare:);
            break;
        default:
            result = @selector(compare:);
            break;
    }
    return result;
}

@end
