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
#import "MTProtocolLog.h"
#import "MTProtocolCompare.h"

@class MTDatabaseField;

@interface RptqDatabaseSchemaField (Extras) <MTProtocolCompare, MTProtocolLog>

+ (instancetype)databaseSchemaFieldFactoryForManagedObjectContext:(NSManagedObjectContext *)objectContext
                                                  andField:(MTDatabaseField *)field;

- (MTDatabaseField *)databaseFieldWrapper;
+ (instancetype)managedObjectForObjectID:(NSManagedObjectID *)objectID
       andManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

- (NSString *)display;
- (NSString *)fieldTypeDisplay;

- (SEL)selectorForSorting;

@end

#endif
