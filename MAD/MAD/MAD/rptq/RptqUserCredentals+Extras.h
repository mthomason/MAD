//
//  RptqUserCredentals+Extras.h
//  Reports
//
//  Created by Michael Thomason on 11/12/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_RptqUserCredentals_Extras_h
#define Reports_RptqUserCredentals_Extras_h

#import "RptqUserCredentals.h"

@interface RptqUserCredentals (Extras)

    + (instancetype)newUserCredentalsForManagedObjectContext:(NSManagedObjectContext *)objectContext NS_RETURNS_RETAINED;

    + (NSArray *)userCredentalsForManagedObjectContext:(NSManagedObjectContext *)objectContext NS_RETURNS_RETAINED;
    - (NSString *)copyDatabaseSchemaName;

@end

#endif
