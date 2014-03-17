//
//  RptqDatabaseSchemaField+Extras.h
//  Reports
//
//  Created by Michael Thomason on 11/11/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_RptqDatabaseSchemaField_Extras_h
#define Reports_RptqDatabaseSchemaField_Extras_h

#import "RptqDatabaseSchemaField.h"
#import "MTDatabaseField.h"
#import "MTProtocolLog.h"
#import "MTProtocolCompare.h"

@interface RptqDatabaseSchemaField (Extras) <MTProtocolCompare, MTProtocolLog>

+ (RptqDatabaseSchemaField *)createNewFieldForManagedObjectContext:(NSManagedObjectContext *)objectContext
                                            andField:(MTDatabaseField *)field;
+ (MTDatabaseField *)databaseFieldForSchemaField:(RptqDatabaseSchemaField *)schemaField;
+ (id)getFieldForObjectID:(NSManagedObjectID *)objectID
        fromObjectContext:(NSManagedObjectContext *)managedObjectContext;

- (NSString *)display;
- (NSString *)fieldTypeDisplay;

- (SEL)selectorForSorting;

@end

#endif
