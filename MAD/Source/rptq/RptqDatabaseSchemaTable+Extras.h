//
//  RptqDatabaseSchemaTable+Extras.h
//  Reports
//
//  Created by Michael Thomason on 11/11/12.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_RptqDatabaseSchemaTable_Extras_h
#define Reports_RptqDatabaseSchemaTable_Extras_h

#import <MAD/RptqDatabaseSchemaTable.h>
#import <MAD/RptqStoreContext.h>
#import <MADDataStructures/MTProtocolLog.h>

@class MADDatabaseTable;

@interface RptqDatabaseSchemaTable (Extras) <MTProtocolLog>

	+ (instancetype)newDatabaseSchemaTableFactoryForManagedObjectContext:(RptqStoreContext *)objectContext
																	name:(NSString *)name
															andQueryable:(BOOL)queryable;

	+ (instancetype)newDatabaseSchemaTableFactoryForManagedObjectContext:(RptqStoreContext *)objectContext
																andTable:(MADDatabaseTable *)table;

	+ (RptqDatabaseSchemaTable *)databaseSchemaTableForDatabase:(RptqDatabase *)database andTableName:(NSString *)name;


@end

#endif
