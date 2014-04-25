//
//  RptqQueryPredicate+Extras.m
//  Reports
//
//  Created by Michael Thomason on 12/7/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "RptqQueryPredicate+Extras.h"
#import "RptqDocument.h"
#import "RptqDocument+Extras.h"
#import "RptqDatabase.h"
#import "RptqQuery.h"

@implementation RptqQueryPredicate (Extras)

#pragma mark - Overrides

- (void)awakeFromInsert {
    [super awakeFromInsert];
    
    // MARK: Auto increment row counter
    NSString *queryField = NSStringFromSelector(@selector(identifier));
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqQueryPredicate class])];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: queryField ascending:NO];
    [request setSortDescriptors: [NSArray arrayWithObject:sortDescriptor]];
    [request setFetchLimit:1];
    NSError *error = nil;
    NSArray *fetchResults = [[self managedObjectContext] executeFetchRequest:request error:&error];
    NSUInteger identifier = 0;
    if (error == nil) {
        RptqQueryPredicate *lastObject = [fetchResults lastObject];
        identifier = [[lastObject identifier] integerValue] + 1;
    }
    [self setIdentifier:@(identifier)];
    
}

- (void)awakeFromFetch {
    [super awakeFromFetch];
}

- (void)awakeFromSnapshotEvents:(NSSnapshotEventType)flag {
    [super awakeFromSnapshotEvents:flag];
    switch (flag) {
        case NSSnapshotEventMergePolicy:
            break;
        case NSSnapshotEventRefresh:
            break;
        case NSSnapshotEventRollback:
            break;
        case NSSnapshotEventUndoDeletion:
            break;
        case NSSnapshotEventUndoInsertion:
            break;
        case NSSnapshotEventUndoUpdate:
            break;
        default:
            break;
    }
}

#pragma mark - Static

+ (id)createPredicateWithLeftField:(RptqQueryField *)leftField
                 comparsonOperator:(MNSPredicateOperator)comparsonOperator
                     andRightField:(RptqQueryField *)rightField
           forManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    NSEntityDescription *ed = [NSEntityDescription entityForName: NSStringFromClass([RptqQueryPredicate class]) inManagedObjectContext:managedObjectContext];
    RptqQueryPredicate *queryPredicate = [[RptqQueryPredicate alloc] initWithEntity:ed insertIntoManagedObjectContext:managedObjectContext];
    [queryPredicate setHasRightField:   rightField];
    [queryPredicate setHasLeftField:    leftField];
    [queryPredicate setFieldrightpred:  nil];
    [queryPredicate setFieldleftpred:   nil];
    [queryPredicate setComparson:       @(comparsonOperator)];
    return queryPredicate;
}

+ (id)createPredicateWithLeftField:(RptqQueryField *)leftField
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
    return queryPredicate;
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
    return queryPredicate;
}

+ (id)createPredicateWithLeftValue:(NSString *)leftUserValue
                 comparsonOperator:(MNSPredicateOperator)comparsonOperator
                     andRightField:(RptqQueryField *)rightField
           forManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    NSEntityDescription *ed = [NSEntityDescription entityForName: NSStringFromClass([RptqQueryPredicate class]) inManagedObjectContext:managedObjectContext];
    RptqQueryPredicate *queryPredicate = [[RptqQueryPredicate alloc] initWithEntity:ed insertIntoManagedObjectContext:managedObjectContext];
    [queryPredicate setHasRightField:   rightField];
    [queryPredicate setHasLeftField:    nil];
    [queryPredicate setFieldrightpred:  nil];
    [queryPredicate setFieldleftpred:   leftUserValue];
    [queryPredicate setComparson:       @(comparsonOperator)];
    return queryPredicate;
}


+ (void)addPredicate:(RptqQueryPredicate *)predicate toDocument:(RptqDocument *)document {

    NSSet *predicates = [NSSet setWithObject: predicate];
    [[[[[document hasDatabaseSchemas] anyObject] hasQueries] anyObject] addHasQueryPredicate:predicates];

}

+ (void)deletePredicate:(RptqQueryPredicate *)predicate {
    if (predicate) {
        NSManagedObjectContext *objectContext = [predicate managedObjectContext];
        if (objectContext) {
            [objectContext deleteObject:predicate];
        }
    }
}

- (NSString *)symbolForDisplay {
    return [MNSPredicateOperatorSymbolsDisplay objectAtIndex:[[self comparson] integerValue]];
}

- (NSString *)symbolForComparson {
    return [MNSPredicateOperatorSymbols objectAtIndex:[[self comparson] integerValue]];
}

#pragma mark - MTProtocolCompare

- (BOOL)isEqualTo:(id)sender {
    BOOL result;
    if ([self isEqual:sender]) {
        result = YES;
    } else {
        RptqQueryPredicate *s = sender;
        result = [[self identifier] isEqualToNumber:[s identifier]];
    }
    return result;
}

@end
