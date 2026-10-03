//
//  RptqDatabaseSchemaField+Extras.h
//  Reports
//
//  Created by Michael Thomason on 11/11/12.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_RptqDatabaseSchemaField_Extras_h
#define Reports_RptqDatabaseSchemaField_Extras_h

#import <MAD/RptqDatabaseSchemaField.h>
#import <MAD/RptqStoreContext.h>
#import <MADDataStructures/MTProtocolLog.h>

@class MADDatabaseField;

@interface RptqDatabaseSchemaField (Extras) <MTProtocolLog>

	+ (instancetype)newDatabaseSchemaFieldFactoryForManagedObjectContext:(RptqStoreContext *)objectContext
																andField:(MADDatabaseField *)field;

	+ (instancetype)managedObjectForObjectID:(int64_t)objectID
					 andManagedObjectContext:(RptqStoreContext *)managedObjectContext;

	+ (NSString *)dataTypeDisplay:(int16_t)dataType;

	- (NSString *)display;
	- (NSString *)fieldTypeDisplay;

	- (SEL)selectorForSorting;

@end

#endif
