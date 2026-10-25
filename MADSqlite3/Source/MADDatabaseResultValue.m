//
//  MADDatabaseResultValue.m
//  MADSqlite3
//
//  Created by Michael on 5/8/25.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADDatabaseResultValue.h"
#import <MADSqlite3/sqlite3.h>

@implementation MADDatabaseResultValue

- (id)copyWithZone:(NSZone *)zone {
	@throw [NSException exceptionWithName: NSInternalInconsistencyException
								   reason: @""
								 userInfo: nil];
}

+ (instancetype)newDatabaseResultValue:(void *)statement columnNumber:(int)columnNumber {
	id value = nil;
	switch (sqlite3_column_type(statement, columnNumber)) { //http://www.sqlite.org/c3ref/c_blob.html
		case SQLITE_INTEGER: {
			value = [[NSNumber alloc] initWithLongLong: sqlite3_column_int64(statement, columnNumber)];
			break;
		}
		case SQLITE_FLOAT: {
			value = [[NSNumber alloc] initWithDouble: sqlite3_column_double(statement, columnNumber)];
			break;
		}
		case SQLITE_BLOB: {
			const void *blob = sqlite3_column_blob(statement, columnNumber);
			value = [[NSData alloc] initWithBytes: blob
										   length: (NSUInteger)sqlite3_column_bytes16(statement, columnNumber)];
			break;
		}
		case SQLITE_NULL: {
			value = [NSNull null];
			break;
		}
		case SQLITE3_TEXT: {
			const char *resultString = (char *)sqlite3_column_text(statement, columnNumber);
			value = [[NSString alloc] initWithCString: resultString
											 encoding: NSUTF8StringEncoding];
			break;
		}
		default:
			NSAssert(NO, @"Unhandled case");
			break;
	}
	
	if (value == nil) {
		value = [NSNull null];
	}
	return value;
}

+ (instancetype)newDatabaseResultValueCast: (void * /* sqlite3_stmt * */)statement
						   forColumnNumber: (int)columnCounter
								  withType: (MADDataType)type {
	
	id columnValue;
	switch (type) {
			
		case MADDataTypeLong:
			columnValue = [[NSNumber alloc] initWithLongLong: sqlite3_column_int64(statement, columnCounter)];
			break;
			
		case MADDataTypeLongLong:
			columnValue = [[NSNumber alloc] initWithLongLong: sqlite3_column_int64(statement, columnCounter)];
			break;
			
		case MADDataTypeInt24:
		case MADDataTypeInteger:
			columnValue = [[NSNumber alloc] initWithLongLong: sqlite3_column_int64(statement, columnCounter)];
			break;
			
		case MADDataTypeShort:
			columnValue = [[NSNumber alloc] initWithInt:sqlite3_column_int(statement, columnCounter)];
			break;
			
		case MADDataTypeImage:
		case MADDataTypeBlob: {
			const void *blob = sqlite3_column_blob(statement, columnCounter);
			columnValue = [[NSData alloc] initWithBytes: blob
												 length: (NSUInteger)sqlite3_column_bytes(statement, columnCounter)];
			break;
		}
			
		case MADDataTypeFloat:
			columnValue = [[NSNumber alloc] initWithDouble: sqlite3_column_double(statement, columnCounter)];
			break;
			
		case MADDataTypeNumber:
		case MADDataTypeDouble:
		case MADDataTypeDecimal:
			columnValue = [[NSNumber alloc] initWithDouble: sqlite3_column_double(statement, columnCounter)];
			break;
			
		case MADDataTypeBit:
		case MADDataTypeVarChar:
		case MADDataTypeString:
		case MADDataTypeEnum:
		case MADDataTypeYear:
		case MADDataTypeSet: {
			const unsigned char *text = sqlite3_column_text(statement, columnCounter);
			if (text == NULL) {
				columnValue = [NSNull null];
			} else {
				columnValue = [[NSString alloc] initWithCString: (const char *) text
													   encoding: NSUTF8StringEncoding];
			}
			break;
		}
			
		case MADDataTypeUnknown:
		case MADDataTypeNull: {
			columnValue = [NSNull null];
			break;
		}
			
		case MADDataTypeTimeStamp:
		case MADDataTypeTime:
		case MADDataTypeDate:
		case MADDataTypeDateTime:
		case MADDataTypeGeometry:
		default: {
			//NSAssert(NO, @"Type is not expected...  Should really be encapsulated in MADDatabaseSqlite3: %lu", (unsigned long)type);
			if (sqlite3_column_type(statement, columnCounter) == SQLITE3_TEXT) {
				const unsigned char *text = sqlite3_column_text(statement, columnCounter);
				if (text == NULL) {
					columnValue = [NSNull null];
				} else {
					columnValue = [[NSString alloc] initWithCString: (const char *) text
														   encoding: NSUTF8StringEncoding];
				}
			}
			break;
		}
	}
	return columnValue;
}

@end
