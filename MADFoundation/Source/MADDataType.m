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

//  The comparison selector for a sort or group level.  The report formatter uses
//  it for group-boundary equality and the cache uses the same sort descriptors to
//  order the rows, so the two sides have to agree (MADReportFormatter
//  -compareValue:withValue:usingSelector:).
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
