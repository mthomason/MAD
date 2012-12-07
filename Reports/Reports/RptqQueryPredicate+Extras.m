//
//  RptqQueryPredicate+Extras.m
//  Reports
//
//  Created by Michael Thomason on 12/7/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "RptqQueryPredicate+Extras.h"

@implementation RptqQueryPredicate (Extras)

+ (void)addPredicate:(RptqQueryPredicate *)predicate forManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
 
    RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext: [[UIManagedDocumentReport activeDocument] managedObjectContext]];
    [[[[[document hasDatabaseSchemas] anyObject] hasQueries] anyObject] addHasQueryPredicate:[NSSet setWithObject: predicate]];

}

@end