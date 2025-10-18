//
//  MADDataType.m
//  MAD
//
//  Created by Michael Thomason on 3/31/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import <MADFoundation/MADDataType.h>
#import <MADFoundation/NSData+Comparison.h>
#import <Foundation/NSString.h>

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
