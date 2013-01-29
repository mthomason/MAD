//
//  RptqQueryResultFields+Extras.m
//  Reports
//
//  Created by Michael Thomason on 1/26/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "RptqQueryResultFields+Extras.h"

@implementation RptqQueryResultFields (Extras)

+ (id)initObjectForManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName: NSStringFromClass([RptqQueryResultFields class]) inManagedObjectContext:managedObjectContext];
    RptqQueryResultFields *queryResultField = [[RptqQueryResultFields alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:managedObjectContext];
    return [queryResultField autorelease];
}

@end