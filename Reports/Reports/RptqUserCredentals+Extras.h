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
#import "MTProtocolCompare.h"

@interface RptqUserCredentals (Extras) <MTProtocolCompare>

+ (instancetype)userCredentalsFactory:(NSManagedObjectContext *)objectContext;
+ (NSArray *)userCredentalsForManagedObjectContext:(NSManagedObjectContext *)objectContext;

- (NSString *)databaseSchemaName;

@end

#endif
