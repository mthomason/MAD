//
//  RptqUserCredentals+Extras.h
//  Reports
//
//  Created by Michael Thomason on 11/12/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_RptqUserCredentals_Extras_h
#define Reports_RptqUserCredentals_Extras_h

#import <MAD/RptqUserCredentals.h>
#import <CoreData/NSFetchRequest.h>

@interface RptqUserCredentals (Extras)

    + (instancetype)newUserCredentalForManagedObjectContext:(NSManagedObjectContext *)objectContext;

    + (NSFetchRequest<RptqUserCredentals *> *)fetchRequest;

    + (NSArray <RptqUserCredentals *> *)newArrayOfUserCredentalsForManagedObjectContext:(NSManagedObjectContext *)objectContext;
    - (NSString *)copyDatabaseSchemaName;

@end

#endif
