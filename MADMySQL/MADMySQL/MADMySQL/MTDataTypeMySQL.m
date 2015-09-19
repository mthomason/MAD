//
//  MTDataTypeMySQL.m
//  MAD
//
//  Created by Michael Thomason on 9/19/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import "MTDataTypeMySQL.h"
#import "mysql.h"
#import "mysql_com.h"

@implementation MTDataTypeMySQL

+ (MTDataType)dataTypeForNativeType:(NSInteger)nativeType {
    switch (nativeType) {
        case MYSQL_TYPE_BIT:
            return MTDataTypeBit;
            break;
        case MYSQL_TYPE_BLOB:
            return MTDataTypeBlob;
            break;
        case MYSQL_TYPE_DATE:
            return MTDataTypeDate;
            break;
        case MYSQL_TYPE_DATETIME:
            return MTDataTypeDateTime;
            break;
        case MYSQL_TYPE_DECIMAL:
            return MTDataTypeDecimal;
            break;
        case MYSQL_TYPE_DOUBLE:
            return MTDataTypeDouble;
            break;
        case MYSQL_TYPE_ENUM:
            return MTDataTypeEnum;
            break;
        case MYSQL_TYPE_FLOAT:
            return MTDataTypeFloat;
            break;
        case MYSQL_TYPE_GEOMETRY:
            return MTDataTypeGeometry;
            break;
        case MYSQL_TYPE_INT24:
            return MTDataTypeInteger;
            break;
        case MYSQL_TYPE_LONG:
            return MTDataTypeLong;
            break;
        case MYSQL_TYPE_LONG_BLOB:
            return MTDataTypeBlob;
            break;
        case MYSQL_TYPE_LONGLONG:
            return MTDataTypeLongLong;
            break;
        case MYSQL_TYPE_MEDIUM_BLOB:
            return MTDataTypeBlob;
            break;
        case MYSQL_TYPE_NEWDATE:
            return MTDataTypeDate;
            break;
        case MYSQL_TYPE_NEWDECIMAL:
            return MTDataTypeDecimal;
            break;
        case MYSQL_TYPE_NULL:
            return MTDataTypeNumber;
            break;
        case MYSQL_TYPE_SET:
            return MTDataTypeSet;
            break;
        case MYSQL_TYPE_SHORT:
            return MTDataTypeShort;
            break;
        case MYSQL_TYPE_STRING:
            return MTDataTypeString;
            break;
        case MYSQL_TYPE_TIME:
            return MTDataTypeDateTime;
            break;
        case MYSQL_TYPE_TIMESTAMP:
            return MTDataTypeTimeStamp;
            break;
        case MYSQL_TYPE_TINY:
            return MTDataTypeShort;
            break;
        case MYSQL_TYPE_TINY_BLOB:
            return MTDataTypeBlob;
            break;
        case MYSQL_TYPE_VAR_STRING:
            return MTDataTypeVarChar;
            break;
        case MYSQL_TYPE_VARCHAR:
            return MTDataTypeVarChar;
            break;
        case MYSQL_TYPE_YEAR:
            return MTDataTypeYear;
            break;
        default:
            return MTDataTypeString;
            break;
    }
}

@end
