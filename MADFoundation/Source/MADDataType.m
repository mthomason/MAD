//
//  MADDataType.m
//  MAD
//
//  Created by Michael Thomason on 3/31/15.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import <MADFoundation/MADDataType.h>
#import <MADFoundation/NSData+Comparison.h>
#import <Foundation/NSString.h>

//  The comparison selector for a sort or group level.  The cache's sort
//  descriptors carry it and the in-memory tables sort by it; the report
//  formatter compares group keys directly from the level's MADDataType
//  (MADReportFormatter +compareValue:withValue:forDataType:), which must agree
//  with the collation the cache's ORDER BY picks
//  (+[MADDatabaseSqlite3 sortDescriptionForColumnType:ascending:]).
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
