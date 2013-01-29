//
//  RptqQueryResultValues+Extras.m
//  Reports
//
//  Created by Michael Thomason on 1/26/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "RptqQueryResultValues+Extras.h"

@implementation RptqQueryResultValues (Extras)

+ (id)initObjectForManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName: NSStringFromClass([RptqQueryResultValues class]) inManagedObjectContext:managedObjectContext];
    RptqQueryResultValues *queryResultValue = [[RptqQueryResultValues alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:managedObjectContext];
    return [queryResultValue autorelease];
}

@end