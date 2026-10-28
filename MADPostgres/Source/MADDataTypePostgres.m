//
//  MADDataTypePostgres.m
//  MADPostgres
//
//  Created by Michael Thomason on 10/28/26.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADDataTypePostgres.h"

#import <Foundation/NSCharacterSet.h>
#import <Foundation/NSString.h>
#import <Foundation/NSValue.h>

@implementation MADDataTypePostgres

+ (MADDataType)madDataTypeFromPostgresOID:(unsigned int)oid {
	switch (oid) {
		case BOOLOID:
			return MADDataTypeBit;

		case INT2OID:
		case INT4OID:
		case INT8OID:
		case OIDOID:
		case REGPROCOID:
		case XIDOID:
		case CIDOID:
			return MADDataTypeInteger;

		case FLOAT4OID:
		case FLOAT8OID:
		case CASHOID:
			return MADDataTypeFloat;

		case NUMERICOID:
			return MADDataTypeDecimal;

		case DATEOID:
			return MADDataTypeDate;

		case TIMEOID:
		case TIMETZOID:
			return MADDataTypeTime;

		case TIMESTAMPOID:
		case TIMESTAMPTZOID:
			return MADDataTypeDateTime;

		case BYTEAOID:
			return MADDataTypeBlob;

		case CHAROID:
		case BPCHAROID:
		case VARCHAROID:
		case TEXTOID:
		case NAMEOID:
		case UUIDOID:
		case JSONOID:
		case JSONBOID:
		case XMLOID:
		case INETOID:
		case CIDROID:
		case MACADDROID:
		case MACADDR8OID:
		case INTERVALOID:
		default:
			return MADDataTypeString;
	}
}

+ (MADDataType)madDataTypeFromPostgresTypeName:(nullable NSString *)typeName {
	if (typeName == nil) return MADDataTypeUnknown;
	NSString *lower = [[typeName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] lowercaseString];
	if (lower.length == 0) return MADDataTypeUnknown;

	if ([lower isEqualToString:@"boolean"] ||
		[lower isEqualToString:@"bool"] ||
		[lower isEqualToString:@"bit"]) {
		return MADDataTypeBit;
	}

	if ([lower isEqualToString:@"smallint"] ||
		[lower isEqualToString:@"integer"] ||
		[lower isEqualToString:@"bigint"] ||
		[lower isEqualToString:@"int"] ||
		[lower isEqualToString:@"int2"] ||
		[lower isEqualToString:@"int4"] ||
		[lower isEqualToString:@"int8"] ||
		[lower isEqualToString:@"serial"] ||
		[lower isEqualToString:@"smallserial"] ||
		[lower isEqualToString:@"bigserial"] ||
		[lower isEqualToString:@"serial2"] ||
		[lower isEqualToString:@"serial4"] ||
		[lower isEqualToString:@"serial8"] ||
		[lower isEqualToString:@"oid"]) {
		return MADDataTypeInteger;
	}

	if ([lower isEqualToString:@"real"] ||
		[lower isEqualToString:@"double precision"] ||
		[lower isEqualToString:@"float4"] ||
		[lower isEqualToString:@"float8"] ||
		[lower isEqualToString:@"float"] ||
		[lower isEqualToString:@"money"]) {
		return MADDataTypeFloat;
	}

	if ([lower isEqualToString:@"numeric"] ||
		[lower isEqualToString:@"decimal"]) {
		return MADDataTypeDecimal;
	}

	if ([lower isEqualToString:@"date"]) {
		return MADDataTypeDate;
	}

	if ([lower isEqualToString:@"time"] ||
		[lower isEqualToString:@"time without time zone"] ||
		[lower isEqualToString:@"time with time zone"] ||
		[lower isEqualToString:@"timetz"]) {
		return MADDataTypeTime;
	}

	if ([lower isEqualToString:@"timestamp"] ||
		[lower isEqualToString:@"timestamp without time zone"] ||
		[lower isEqualToString:@"timestamp with time zone"] ||
		[lower isEqualToString:@"timestamptz"]) {
		return MADDataTypeDateTime;
	}

	if ([lower isEqualToString:@"bytea"]) {
		return MADDataTypeBlob;
	}

	return MADDataTypeString;
}

+ (NSNumber *)madDataTypeNumberFromPostgresOID:(unsigned int)oid {
	return [[NSNumber alloc] initWithShort:[self madDataTypeFromPostgresOID:oid]];
}

+ (NSNumber *)madDataTypeNumberFromPostgresTypeName:(nullable NSString *)typeName {
	return [[NSNumber alloc] initWithShort:[self madDataTypeFromPostgresTypeName:typeName]];
}

@end
