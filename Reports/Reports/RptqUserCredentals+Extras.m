//
//  RptqUserCredentals+Extras.m
//  Reports
//
//  Created by Michael Thomason on 11/12/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "RptqUserCredentals+Extras.h"

@implementation RptqUserCredentals (Extras)

+ (RptqUserCredentals *)createNewUserCredentalsForManagedObjectContext:(NSManagedObjectContext *)objectContext {
    NSEntityDescription *ed = [NSEntityDescription entityForName:NSStringFromClass([RptqUserCredentals class]) inManagedObjectContext: objectContext];
    RptqUserCredentals *userCredentals = [[RptqUserCredentals alloc] initWithEntity:ed insertIntoManagedObjectContext:objectContext];
    NSLog(@"User Credentals, %@", userCredentals);
    return [userCredentals autorelease];
}

@end