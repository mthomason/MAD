//
//  MADDataTypeMySQL.m
//  MAD
//
//  Created by Michael Thomason on 9/19/15.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#import "MADDataTypeMySQL.h"
#import <MADFoundation/MADFoundation.h>
#import <mysql.h>

@implementation MADDataTypeMySQL

+ (short)dataTypeForNativeType:(NSInteger)nativeType {
	switch (nativeType) {
		case MYSQL_TYPE_BIT:
			return MADDataTypeBit;
			break;
		case MYSQL_TYPE_BLOB:
			return MADDataTypeBlob;
			break;
		case MYSQL_TYPE_DATE:
			return MADDataTypeDate;
			break;
		case MYSQL_TYPE_DATETIME:
			return MADDataTypeDateTime;
			break;
		case MYSQL_TYPE_DECIMAL:
			return MADDataTypeDecimal;
			break;
		case MYSQL_TYPE_DOUBLE:
			return MADDataTypeDouble;
			break;
		case MYSQL_TYPE_ENUM:
			return MADDataTypeEnum;
			break;
		case MYSQL_TYPE_FLOAT:
			return MADDataTypeFloat;
			break;
		case MYSQL_TYPE_GEOMETRY:
			return MADDataTypeGeometry;
			break;
		case MYSQL_TYPE_INT24:
			return MADDataTypeInteger;
			break;
		case MYSQL_TYPE_LONG:
			return MADDataTypeLong;
			break;
		case MYSQL_TYPE_LONG_BLOB:
			return MADDataTypeBlob;
			break;
		case MYSQL_TYPE_LONGLONG:
			return MADDataTypeLongLong;
			break;
		case MYSQL_TYPE_MEDIUM_BLOB:
			return MADDataTypeBlob;
			break;
		case MYSQL_TYPE_NEWDATE:
			return MADDataTypeDate;
			break;
		case MYSQL_TYPE_NEWDECIMAL:
			return MADDataTypeDecimal;
			break;
		case MYSQL_TYPE_NULL:
			return MADDataTypeNumber;
			break;
		case MYSQL_TYPE_SET:
			return MADDataTypeSet;
			break;
		case MYSQL_TYPE_SHORT:
			return MADDataTypeShort;
			break;
		case MYSQL_TYPE_STRING:
			return MADDataTypeString;
			break;
		case MYSQL_TYPE_TIME:
			return MADDataTypeDateTime;
			break;
		case MYSQL_TYPE_TIMESTAMP:
			return MADDataTypeTimeStamp;
			break;
		case MYSQL_TYPE_TINY:
			return MADDataTypeShort;
			break;
		case MYSQL_TYPE_TINY_BLOB:
			return MADDataTypeBlob;
			break;
		case MYSQL_TYPE_VAR_STRING:
			return MADDataTypeVarChar;
			break;
		case MYSQL_TYPE_VARCHAR:
			return MADDataTypeVarChar;
			break;
		case MYSQL_TYPE_YEAR:
			return MADDataTypeYear;
			break;
		default:
			return MADDataTypeString;
			break;
	}
}

@end
