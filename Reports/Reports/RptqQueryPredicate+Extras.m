//
//  RptqQueryPredicate+Extras.m
//  Reports
//
//  Created by Michael Thomason on 12/7/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "RptqQueryPredicate+Extras.h"

@implementation RptqQueryPredicate (Extras)

- (void)awakeFromInsert {
    [super awakeFromInsert];
}

- (void)awakeFromFetch {
    [super awakeFromFetch];
}

- (void)awakeFromSnapshotEvents:(NSSnapshotEventType)flag {
    [super awakeFromSnapshotEvents:flag];
}

+ (id)createPredicateWithLeftField:(RptqField *)leftField
                 comparsonOperator:(MNSPredicateOperator)comparsonOperator
                     andRightField:(RptqField *)rightField
           forManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    NSEntityDescription *ed = [NSEntityDescription entityForName: NSStringFromClass([RptqQueryPredicate class]) inManagedObjectContext:managedObjectContext];
    RptqQueryPredicate *queryPredicate = [[RptqQueryPredicate alloc] initWithEntity:ed insertIntoManagedObjectContext:managedObjectContext];
    [queryPredicate setHasRightField:   rightField];
    [queryPredicate setHasLeftField:    leftField];
    [queryPredicate setFieldrightpred:  nil];
    [queryPredicate setFieldleftpred:   nil];
    [queryPredicate setComparson:       @(comparsonOperator)];
    return [queryPredicate autorelease];
}

+ (id)createPredicateWithLeftField:(RptqField *)leftField
                 comparsonOperator:(MNSPredicateOperator)comparsonOperator
                     andRightValue:(NSString *)rightUserValue
           forManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    NSEntityDescription *ed = [NSEntityDescription entityForName: NSStringFromClass([RptqQueryPredicate class]) inManagedObjectContext:managedObjectContext];
    RptqQueryPredicate *queryPredicate = [[RptqQueryPredicate alloc] initWithEntity:ed insertIntoManagedObjectContext:managedObjectContext];
    [queryPredicate setHasRightField:   nil];
    [queryPredicate setHasLeftField:    leftField];
    [queryPredicate setFieldrightpred:  rightUserValue];
    [queryPredicate setFieldleftpred:   nil];
    [queryPredicate setComparson:       @(comparsonOperator)];
    return [queryPredicate autorelease];
}

+ (id)createPredicateWithLeftValue:(NSString *)leftUserValue
                 comparsonOperator:(MNSPredicateOperator)comparsonOperator
                     andRightValue:(NSString *)rightUserValue
           forManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    NSEntityDescription *ed = [NSEntityDescription entityForName: NSStringFromClass([RptqQueryPredicate class]) inManagedObjectContext:managedObjectContext];
    RptqQueryPredicate *queryPredicate = [[RptqQueryPredicate alloc] initWithEntity:ed insertIntoManagedObjectContext:managedObjectContext];
    [queryPredicate setHasRightField:   nil];
    [queryPredicate setHasLeftField:    nil];
    [queryPredicate setFieldrightpred:  rightUserValue];
    [queryPredicate setFieldleftpred:   leftUserValue];
    [queryPredicate setComparson:       @(comparsonOperator)];
    return [queryPredicate autorelease];
}

+ (id)createPredicateWithLeftValue:(NSString *)leftUserValue
                 comparsonOperator:(MNSPredicateOperator)comparsonOperator
                     andRightField:(RptqField *)rightField
           forManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    NSEntityDescription *ed = [NSEntityDescription entityForName: NSStringFromClass([RptqQueryPredicate class]) inManagedObjectContext:managedObjectContext];
    RptqQueryPredicate *queryPredicate = [[RptqQueryPredicate alloc] initWithEntity:ed insertIntoManagedObjectContext:managedObjectContext];
    [queryPredicate setHasRightField:   rightField];
    [queryPredicate setHasLeftField:    nil];
    [queryPredicate setFieldrightpred:  nil];
    [queryPredicate setFieldleftpred:   leftUserValue];
    [queryPredicate setComparson:       @(comparsonOperator)];
    return [queryPredicate autorelease];    
}


+ (void)addPredicate:(RptqQueryPredicate *)predicate forManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
 
    RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext: managedObjectContext];
    [[[[[document hasDatabaseSchemas] anyObject] hasQueries] anyObject] addHasQueryPredicate:[NSSet setWithObject: predicate]];

}

@end