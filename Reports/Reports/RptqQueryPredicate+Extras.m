//
//  RptqQueryPredicate+Extras.m
//  Reports
//
//  Created by Michael Thomason on 12/7/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "RptqQueryPredicate+Extras.h"

@implementation RptqQueryPredicate (Extras)

+ (id)createPredicateWithLeftField:(NSString *)leftField comparsonOperator:(MNSPredicateOperator)comparsonOperator andRightValue:(NSString *)rightValue forManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    NSEntityDescription *ed = [NSEntityDescription entityForName: NSStringFromClass([RptqQueryPredicate class]) inManagedObjectContext:[[UIManagedDocumentReport activeDocument] managedObjectContext]];
    RptqQueryPredicate *queryPredicate = [[RptqQueryPredicate alloc] initWithEntity:ed insertIntoManagedObjectContext:managedObjectContext];
    [queryPredicate setFieldleftpred: leftField];
    [queryPredicate setComparson: [NSNumber numberWithInt: comparsonOperator]];
    [queryPredicate setFieldrightpred: rightValue];
    return [queryPredicate autorelease];
}

+ (void)addPredicate:(RptqQueryPredicate *)predicate forManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
 
    RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext: managedObjectContext];
    [[[[[document hasDatabaseSchemas] anyObject] hasQueries] anyObject] addHasQueryPredicate:[NSSet setWithObject: predicate]];

}

@end