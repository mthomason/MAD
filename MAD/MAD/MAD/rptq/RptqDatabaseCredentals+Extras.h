//
//  RptqDatabaseCredentals+Extras.h
//  Reports
//
//  Created by Michael Thomason on 11/12/12.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_RptqUserCredentals_Extras_h
#define Reports_RptqUserCredentals_Extras_h

#import <CoreData/NSFetchRequest.h>
#import <MAD/RptqDatabaseCredentals.h>
#import <MAD/MADDatabaseConnectionsPropertiesCredentals.h>

@interface RptqDatabaseCredentals (Extras)
    <MADDatabaseConnectionsPropertiesCredentals>

    + (instancetype)newDatabaseCredental:(NSManagedObjectContext *)objectContext;
    + (NSArray <RptqDatabaseCredentals *> *)newDatabaseCredentals:(NSManagedObjectContext *)objectContext;

    + (NSFetchRequest<RptqDatabaseCredentals *> *)fetchRequest;

    - (NSString *)databaseSchemaName;

@end

#endif
