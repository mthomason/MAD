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
#import <CoreData/NSFetchRequest.h>
#import <CoreData/NSManagedObjectContext.h>
#import <CoreData/NSEntityDescription.h>

#import <Foundation/NSSortDescriptor.h>
#import <Foundation/NSString.h>

@implementation RptqQueryPredicate (Extras)

#pragma mark - Overrides

- (void)awakeFromInsert {
    [super awakeFromInsert];
    
    // MARK: Auto increment row counter
    NSString *queryField = NSStringFromSelector(@selector(identifier));
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqQueryPredicate class])];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: queryField ascending:NO];
    NSArray *sortDescriptors = @[sortDescriptor];
    request.sortDescriptors = sortDescriptors;
    request.fetchLimit = 1;
    NSError *error = nil;
    NSArray *fetchResults = [[self managedObjectContext] executeFetchRequest:request error:&error];
    NSUInteger identifier = 0;
    if (error == nil) {
        RptqQueryPredicate *lastObject = [fetchResults lastObject];
        identifier = lastObject.identifier.unsignedIntegerValue + 1;
    }
    NSNumber *identifierObj = @(identifier);
    self.identifier = identifierObj;
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

+ (instancetype)predicateFactoryWithLeftField:(RptqQueryField *)leftField
                            comparsonOperator:(MNSPredicateOperator)comparsonOperator
                                andRightField:(RptqQueryField *)rightField
                      forManagedObjectContext:(NSManagedObjectContext *)managedObjectContext NS_RETURNS_RETAINED {
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
                      forManagedObjectContext:(NSManagedObjectContext *)managedObjectContext NS_RETURNS_RETAINED {
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
                      forManagedObjectContext:(NSManagedObjectContext *)managedObjectContext NS_RETURNS_RETAINED {
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
                      forManagedObjectContext:(NSManagedObjectContext *)managedObjectContext NS_RETURNS_RETAINED {
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
    return MNSPredicateOperatorSymbolsDisplay[self.comparson.unsignedIntegerValue];
}

- (NSString *)symbolForComparson {
    return MNSPredicateOperatorSymbols[self.comparson.unsignedIntegerValue];
}

- (id)debugQuickLookObject {
    NSMutableString *description = [[NSMutableString alloc] init];
    [description appendFormat:@"*********\n"];
    [description appendFormat:@"Identifier:         %@\n", self.identifier];
    [description appendFormat:@"Sort:               %@\n", self.comparson];
    [description appendFormat:@"Right field:        %@\n", self.hasRightField];
    [description appendFormat:@"Right pred:         %@\n", self.fieldrightpred];
    [description appendFormat:@"Left field:         %@\n", self.hasLeftField];
    [description appendFormat:@"Left pred:          %@\n", self.fieldleftpred];
    [description appendFormat:@"Query:              %@\n", self.inQuery];
    [description appendFormat:@"*********"];
    return description;
}

@end
