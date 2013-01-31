//
//  RptqQueryResult+Extras.m
//  Reports
//
//  Created by Michael Thomason on 1/30/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "RptqQueryResult+Extras.h"

@implementation RptqQueryResult (Extras)

+ (id)initObjectForManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName: NSStringFromClass([RptqQueryResult class]) inManagedObjectContext:managedObjectContext];
    RptqQueryResult *queryResult = [[RptqQueryResult alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:managedObjectContext];
    return [queryResult autorelease];
}

@end