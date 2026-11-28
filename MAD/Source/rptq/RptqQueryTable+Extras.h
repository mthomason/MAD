//
//  RptqQueryTable+Extras.h
//  Reports
//
//  Created by Michael Thomason on 3/12/13.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_RptqQueryTable_Extras_h
#define Reports_RptqQueryTable_Extras_h

#import <MAD/RptqQueryTable.h>
#import <MAD/RptqStoreContext.h>
#import <MADDataStructures/MTProtocolCompare.h>

@class RptqDocument, RptqDatabase, RptqQuery, RptqDatabaseSchemaTable;

@interface RptqQueryTable (Extras)
	<MTProtocolCompare>

	+ (instancetype)newQueryTableForSchemaTable:(RptqDatabaseSchemaTable *)databaseSchemaTable
									   database:(RptqDatabase *)database
						forManagedObjectContext:(RptqStoreContext *)managedObjectContext;

	/// As above, but counts the copies of the schema table in @c query rather than
	/// in the database's default query.  The drop index is a per-query namespace:
	/// two queries may both hold the first copy of @c Orders, and both are
	/// @c Orders0.
	+ (instancetype)newQueryTableForSchemaTable:(RptqDatabaseSchemaTable *)databaseSchemaTable
										 query:(RptqQuery *)query
					   forManagedObjectContext:(RptqStoreContext *)managedObjectContext;

	+ (instancetype)queryTableWithObjectID:(int64_t)objectID
					  managedObjectContext:(RptqStoreContext *)managedObjectContext;

	+ (NSString *)keyPathAlias;
	+ (NSString *)keyPathDropIndex;

	- (NSString *)queryAlias;
	+ (NSString *)queryAliasForSchemaTableName:(NSString *)schemaTableName
									 dropIndex:(int64_t)dropIndex;
@end

#endif
