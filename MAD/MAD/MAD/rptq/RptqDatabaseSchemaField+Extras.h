//
//  RptqDatabaseSchemaField+Extras.h
//  Reports
//
//  Created by Michael Thomason on 11/11/12.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_RptqDatabaseSchemaField_Extras_h
#define Reports_RptqDatabaseSchemaField_Extras_h

#import "RptqDatabaseSchemaField.h"
#import <MADDataStructures/MTProtocolLog.h>

@class MADDatabaseField;

@interface RptqDatabaseSchemaField (Extras) <MTProtocolLog>

    + (instancetype)newDatabaseSchemaFieldFactoryForManagedObjectContext:(NSManagedObjectContext *)objectContext
                                                                andField:(MADDatabaseField *)field;

    + (instancetype)managedObjectForObjectID:(NSManagedObjectID *)objectID
                     andManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

    + (NSString *)dataTypeDisplay:(int16_t)dataType;

    - (NSString *)display;
    - (NSString *)fieldTypeDisplay;

    - (SEL)selectorForSorting;

@end

#endif
