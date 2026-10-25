//
//  MADMySQLFetch.h
//  MADMySQL
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_MADMySQLFetch_h
#define MAD_MADMySQLFetch_h

#import <Foundation/NSObject.h>
#import <mysql.h>

@class MADMySQLConnection, MADQuery, MADDataTable;

/*
	The delegate receives progress from a fetch: the finished data table, and
	every row as it lands.
 */
@protocol MADMySQLFetchProtocol
@optional
	- (MADDataTable *)dataTableForQuery:(MADQuery *)query;
	- (void)didFetchRow:(NSUInteger)row;
@end

/*
	A prepared-statement fetch: the result columns in fieldNames and fields,
	and the C-API helpers the MADMySQLFetch (DataTable) category builds on.
 */
@interface MADMySQLFetch : NSObject

	@property(nonatomic, weak) id <MADMySQLFetchProtocol> delegate;

	@property(nonatomic, strong, readwrite) NSArray *fieldNames;
	@property(nonatomic, strong, readwrite) NSArray *fields;

	+ (int)fetchStatement:(MYSQL_STMT *)statement;

@end

/*
	The name of a MYSQL_TYPE_* value, for diagnostics. Returns "Unknown" for
	values outside the table.
 */
char *mySQLTypeForType(enum enum_field_types type);

#endif
