//
//  RptqDatabaseCredentals+Extras.h
//  Reports
//
//  Created by Michael Thomason on 11/12/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_RptqUserCredentals_Extras_h
#define Reports_RptqUserCredentals_Extras_h

#import <MAD/RptqDatabaseCredentals.h>
#import <CoreData/NSFetchRequest.h>

@interface RptqDatabaseCredentals (Extras)

    + (instancetype)newDatabaseCredental:(NSManagedObjectContext *)objectContext;
    + (NSArray <RptqDatabaseCredentals *> *)newDatabaseCredentals:(NSManagedObjectContext *)objectContext;

    + (NSFetchRequest<RptqDatabaseCredentals *> *)fetchRequest;

    - (NSString *)databaseSchemaName;

@end

#endif
