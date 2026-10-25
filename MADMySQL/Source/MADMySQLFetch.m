//
//  MADMySQLFetch.m
//  MADMySQL
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADMySQLFetch.h"

#import <mysql.h>

// One entry per MYSQL_TYPE_* value, for diagnostics. Anything the table does
// not name -- including codes this client does not know -- reads "Unknown".

static const struct MADMySQLTypeName {
	enum enum_field_types type;
	const char *name;
} MADMySQLTypeNames[] = {
	{ MYSQL_TYPE_DECIMAL, "MYSQL_TYPE_DECIMAL" },
	{ MYSQL_TYPE_TINY, "MYSQL_TYPE_TINY" },
	{ MYSQL_TYPE_SHORT, "MYSQL_TYPE_SHORT" },
	{ MYSQL_TYPE_LONG, "MYSQL_TYPE_LONG" },
	{ MYSQL_TYPE_FLOAT, "MYSQL_TYPE_FLOAT" },
	{ MYSQL_TYPE_DOUBLE, "MYSQL_TYPE_DOUBLE" },
	{ MYSQL_TYPE_NULL, "MYSQL_TYPE_NULL" },
	{ MYSQL_TYPE_TIMESTAMP, "MYSQL_TYPE_TIMESTAMP" },
	{ MYSQL_TYPE_LONGLONG, "MYSQL_TYPE_LONGLONG" },
	{ MYSQL_TYPE_INT24, "MYSQL_TYPE_INT24" },
	{ MYSQL_TYPE_DATE, "MYSQL_TYPE_DATE" },
	{ MYSQL_TYPE_TIME, "MYSQL_TYPE_TIME" },
	{ MYSQL_TYPE_DATETIME, "MYSQL_TYPE_DATETIME" },
	{ MYSQL_TYPE_YEAR, "MYSQL_TYPE_YEAR" },
	{ MYSQL_TYPE_NEWDATE, "MYSQL_TYPE_NEWDATE" },
	{ MYSQL_TYPE_VARCHAR, "MYSQL_TYPE_VARCHAR" },
	{ MYSQL_TYPE_BIT, "MYSQL_TYPE_BIT" },
	{ MYSQL_TYPE_TIMESTAMP2, "MYSQL_TYPE_TIMESTAMP2" },
	{ MYSQL_TYPE_DATETIME2, "MYSQL_TYPE_DATETIME2" },
	{ MYSQL_TYPE_TIME2, "MYSQL_TYPE_TIME2" },
	{ MYSQL_TYPE_JSON, "MYSQL_TYPE_JSON" },
	{ MYSQL_TYPE_NEWDECIMAL, "MYSQL_TYPE_NEWDECIMAL" },
	{ MYSQL_TYPE_ENUM, "MYSQL_TYPE_ENUM" },
	{ MYSQL_TYPE_SET, "MYSQL_TYPE_SET" },
	{ MYSQL_TYPE_TINY_BLOB, "MYSQL_TYPE_TINY_BLOB" },
	{ MYSQL_TYPE_MEDIUM_BLOB, "MYSQL_TYPE_MEDIUM_BLOB" },
	{ MYSQL_TYPE_LONG_BLOB, "MYSQL_TYPE_LONG_BLOB" },
	{ MYSQL_TYPE_BLOB, "MYSQL_TYPE_BLOB" },
	{ MYSQL_TYPE_VAR_STRING, "MYSQL_TYPE_VAR_STRING" },
	{ MYSQL_TYPE_STRING, "MYSQL_TYPE_STRING" },
	{ MYSQL_TYPE_GEOMETRY, "MYSQL_TYPE_GEOMETRY" },
};

char *mySQLTypeForType(enum enum_field_types type) {
	for (unsigned int i = 0; i < sizeof(MADMySQLTypeNames) / sizeof(MADMySQLTypeNames[0]); i++) {
		if (MADMySQLTypeNames[i].type == type) {
			return (char *)MADMySQLTypeNames[i].name;
		}
	}
	return "Unknown";
}

@implementation MADMySQLFetch

+ (int)fetchStatement:(MYSQL_STMT *)statement {
	return mysql_stmt_fetch(statement);
}

@end
