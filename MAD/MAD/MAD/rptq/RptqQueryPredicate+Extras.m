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
#import "RptqDatabase+Extras.h"
#import "RptqQuery.h"

@implementation RptqQueryPredicate (Extras)

#pragma mark - Overrides

- (void)awakeFromInsert {
    [super awakeFromInsert];
    
    // MARK: Auto increment row counter
    NSString *queryField = NSStringFromSelector(@selector(identifier));
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqQueryPredicate class])];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: queryField ascending:NO];
    [request setSortDescriptors: @[sortDescriptor]];
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

+ (instancetype)predicateFactoryWithLeftField:(RptqQueryField *)fieldLeft
                                    leftValue:(NSString *)valueLeft
                            comparsonOperator:(MNSPredicateOperator)predicateOperator
                                   rightField:(RptqQueryField *)fieldRight
                                   rightValue:(NSString *)valueRight
                      forManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    
    RptqQueryPredicate *queryPredicate = nil;
    
    if (valueLeft == nil) {
        if (valueRight == nil) {
            queryPredicate = [RptqQueryPredicate predicateFactoryWithLeftField: fieldLeft
                                                             comparsonOperator: predicateOperator
                                                                 andRightField: fieldRight
                                                       forManagedObjectContext: managedObjectContext];
        } else {
            queryPredicate = [RptqQueryPredicate predicateFactoryWithLeftField: fieldLeft
                                                             comparsonOperator: predicateOperator
                                                                 andRightValue: valueRight
                                                       forManagedObjectContext: managedObjectContext];
        }
    } else {
        if (valueRight == nil) {
            queryPredicate = [RptqQueryPredicate predicateFactoryWithLeftValue: valueLeft
                                                             comparsonOperator: predicateOperator
                                                                 andRightField: fieldRight
                                                       forManagedObjectContext: managedObjectContext];
        } else {
            queryPredicate = [RptqQueryPredicate predicateFactoryWithLeftValue: valueLeft
                                                             comparsonOperator: predicateOperator
                                                                 andRightValue: valueRight
                                                       forManagedObjectContext: managedObjectContext];
        }
    }
    return queryPredicate;
}

+ (instancetype)predicateFactoryWithLeftField:(RptqQueryField *)leftField
                            comparsonOperator:(MNSPredicateOperator)comparsonOperator
                                andRightField:(RptqQueryField *)rightField
                      forManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    NSEntityDescription *ed = [NSEntityDescription entityForName: NSStringFromClass([RptqQueryPredicate class]) inManagedObjectContext:managedObjectContext];
    RptqQueryPredicate *queryPredicate = [[RptqQueryPredicate alloc] initWithEntity:ed insertIntoManagedObjectContext:managedObjectContext];
    queryPredicate.hasRightField    = rightField;
    queryPredicate.hasLeftField     = leftField;
    queryPredicate.fieldrightpred   = nil;
    queryPredicate.fieldleftpred    = nil;
    NSNumber *comparson             = @(comparsonOperator);
    queryPredicate.comparson        = comparson;
    return queryPredicate;
}

+ (instancetype)predicateFactoryWithLeftField:(RptqQueryField *)leftField
                            comparsonOperator:(MNSPredicateOperator)comparsonOperator
                                andRightValue:(NSString *)rightUserValue
                      forManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    NSEntityDescription *ed = [NSEntityDescription entityForName: NSStringFromClass([RptqQueryPredicate class]) inManagedObjectContext:managedObjectContext];
    RptqQueryPredicate *queryPredicate = [[RptqQueryPredicate alloc] initWithEntity:ed insertIntoManagedObjectContext:managedObjectContext];
    queryPredicate.hasRightField    = nil;
    queryPredicate.hasLeftField     = leftField;
    queryPredicate.fieldrightpred   = rightUserValue;
    queryPredicate.fieldleftpred    = nil;
    NSNumber *comparson             = @(comparsonOperator);
    queryPredicate.comparson        = comparson;
    return queryPredicate;
}

+ (instancetype)predicateFactoryWithLeftValue:(NSString *)leftUserValue
                            comparsonOperator:(MNSPredicateOperator)comparsonOperator
                                andRightValue:(NSString *)rightUserValue
                      forManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    NSEntityDescription *ed = [NSEntityDescription entityForName: NSStringFromClass([RptqQueryPredicate class]) inManagedObjectContext:managedObjectContext];
    RptqQueryPredicate *queryPredicate = [[RptqQueryPredicate alloc] initWithEntity:ed insertIntoManagedObjectContext:managedObjectContext];
    queryPredicate.hasRightField    = nil;
    queryPredicate.hasLeftField     = nil;
    queryPredicate.fieldrightpred   = rightUserValue;
    queryPredicate.fieldleftpred    = leftUserValue;
    NSNumber *comparson             = @(comparsonOperator);
    queryPredicate.comparson        = comparson;
    return queryPredicate;
}

+ (instancetype)predicateFactoryWithLeftValue:(NSString *)leftUserValue
                            comparsonOperator:(MNSPredicateOperator)comparsonOperator
                                andRightField:(RptqQueryField *)rightField
                      forManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    NSEntityDescription *ed = [NSEntityDescription entityForName: NSStringFromClass([RptqQueryPredicate class]) inManagedObjectContext:managedObjectContext];
    RptqQueryPredicate *queryPredicate = [[RptqQueryPredicate alloc] initWithEntity:ed insertIntoManagedObjectContext:managedObjectContext];
    queryPredicate.hasRightField    = rightField;
    queryPredicate.hasLeftField     = nil;
    queryPredicate.fieldrightpred   = nil;
    queryPredicate.fieldleftpred    = leftUserValue;
    NSNumber *comparson             = @(comparsonOperator);
    queryPredicate.comparson        = comparson;
    return queryPredicate;
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
    return MNSPredicateOperatorSymbolsDisplay[self.comparson.integerValue];
}

- (NSString *)symbolForComparson {
    return MNSPredicateOperatorSymbols[self.comparson.integerValue];
}

#pragma mark - MTProtocolCompare

- (BOOL)isEqualTo:(id)sender {
    
    if ([self isEqual:sender]) {
        return YES;
    } else {
        return [self.identifier isEqualToNumber:((RptqQueryPredicate *)sender).identifier];
    }
}

@end
