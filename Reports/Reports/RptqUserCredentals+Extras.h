//
//  RptqUserCredentals+Extras.h
//  Reports
//
//  Created by Michael Thomason on 11/12/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "RptqUserCredentals.h"
#import "NSError+UserInterface.h"

@interface RptqUserCredentals (Extras)

+ (RptqUserCredentals *)createNewUserCredentalsForManagedObjectContext:(NSManagedObjectContext *)objectContext;
+ (NSArray *)userCredentalsForManagedObjectContext:(NSManagedObjectContext *)objectContext;

@end