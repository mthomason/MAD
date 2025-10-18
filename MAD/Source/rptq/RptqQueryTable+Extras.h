//
//  RptqQueryTable+Extras.h
//  Reports
//
//  Created by Michael Thomason on 3/12/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_RptqQueryTable_Extras_h
#define Reports_RptqQueryTable_Extras_h

#import <MAD/RptqQueryTable.h>
#import <MADDataStructures/MTProtocolCompare.h>

@class NSManagedObjectID, RptqDocument, RptqDatabase, RptqDatabaseSchemaTable;

@interface RptqQueryTable (Extras)
	<MTProtocolCompare>

	+ (instancetype)newQueryTableForSchemaTable:(RptqDatabaseSchemaTable *)databaseSchemaTable
									   database:(RptqDatabase *)database
						forManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

	+ (instancetype)queryTableWithObjectID:(NSManagedObjectID *)objectID
					  managedObjectContext:(NSManagedObjectContext *)managedObjectContext;

	+ (NSString *)keyPathAlias;
	+ (NSString *)keyPathDropIndex;

	- (NSString *)queryAlias;
	+ (NSString *)queryAliasForSchemaTableName:(NSString *)schemaTableName
									 dropIndex:(int64_t)dropIndex;
@end

#endif
