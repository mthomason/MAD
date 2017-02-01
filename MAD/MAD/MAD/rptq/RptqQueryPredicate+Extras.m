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

#import <CoreFoundation/CFNumber.h>

#import <Foundation/NSSortDescriptor.h>
#import <Foundation/NSString.h>

#import <CoreData/NSFetchRequest.h>
#import <CoreData/NSManagedObjectContext.h>
#import <CoreData/NSEntityDescription.h>

#import "RptqDocument.h"
#import "RptqDocument+Extras.h"
#import "RptqDatabase.h"
#import "RptqDatabase+Extras.h"
#import "RptqQuery.h"

#import "RptqDataHelper.h"

@implementation RptqQueryPredicate (Extras)

#pragma mark - Overrides

- (void)awakeFromInsert {
    [super awakeFromInsert];
    self.identifier = [RptqDataHelper nextIdentifierForClass:[self class]
                                        managedObjectContext:self.managedObjectContext];
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

+ (instancetype)newQueryPredicateFactoryWithLeftField:(RptqQueryField *)leftField
                            comparsonOperator:(MADPredicateOperator)comparsonOperator
                                andRightField:(RptqQueryField *)rightField
                      forManagedObjectContext:(NSManagedObjectContext *)managedObjectContext NS_RETURNS_RETAINED {
    NSEntityDescription *ed = [NSEntityDescription entityForName: NSStringFromClass([RptqQueryPredicate class]) inManagedObjectContext:managedObjectContext];
    RptqQueryPredicate *queryPredicate = [[RptqQueryPredicate alloc] initWithEntity:ed insertIntoManagedObjectContext:managedObjectContext];
    queryPredicate.hasRightField    = rightField;
    queryPredicate.hasLeftField     = leftField;
    queryPredicate.rightFieldID   = nil;
    queryPredicate.leftFieldID    = nil;
    queryPredicate.comparson        = comparsonOperator;
    return queryPredicate;
}

+ (instancetype)newQueryPredicateFactoryWithLeftField:(RptqQueryField *)leftField
                            comparsonOperator:(MADPredicateOperator)comparsonOperator
                                andRightValue:(NSString *)rightUserValue
                      forManagedObjectContext:(NSManagedObjectContext *)managedObjectContext NS_RETURNS_RETAINED {
    NSEntityDescription *ed = [NSEntityDescription entityForName: NSStringFromClass([RptqQueryPredicate class]) inManagedObjectContext:managedObjectContext];
    RptqQueryPredicate *queryPredicate = [[RptqQueryPredicate alloc] initWithEntity:ed insertIntoManagedObjectContext:managedObjectContext];
    queryPredicate.hasRightField    = nil;
    queryPredicate.hasLeftField     = leftField;
    queryPredicate.rightFieldID   = rightUserValue;
    queryPredicate.leftFieldID    = nil;
    queryPredicate.comparson        = comparsonOperator;
    return queryPredicate;
}

+ (instancetype)newQueryPredicateFactoryWithLeftValue:(NSString *)leftUserValue
                            comparsonOperator:(MADPredicateOperator)comparsonOperator
                                andRightValue:(NSString *)rightUserValue
                      forManagedObjectContext:(NSManagedObjectContext *)managedObjectContext NS_RETURNS_RETAINED {
    NSEntityDescription *ed = [NSEntityDescription entityForName: NSStringFromClass([RptqQueryPredicate class]) inManagedObjectContext:managedObjectContext];
    RptqQueryPredicate *queryPredicate = [[RptqQueryPredicate alloc] initWithEntity:ed insertIntoManagedObjectContext:managedObjectContext];
    queryPredicate.hasRightField    = nil;
    queryPredicate.hasLeftField     = nil;
    queryPredicate.rightFieldID   = rightUserValue;
    queryPredicate.leftFieldID    = leftUserValue;
    queryPredicate.comparson        = comparsonOperator;
    return queryPredicate;
}

+ (instancetype)newQueryPredicateFactoryWithLeftValue:(NSString *)leftUserValue
                            comparsonOperator:(MADPredicateOperator)comparsonOperator
                                andRightField:(RptqQueryField *)rightField
                      forManagedObjectContext:(NSManagedObjectContext *)managedObjectContext NS_RETURNS_RETAINED {
    NSEntityDescription *ed = [NSEntityDescription entityForName: NSStringFromClass([RptqQueryPredicate class]) inManagedObjectContext:managedObjectContext];
    RptqQueryPredicate *queryPredicate = [[RptqQueryPredicate alloc] initWithEntity:ed insertIntoManagedObjectContext:managedObjectContext];
    queryPredicate.hasRightField    = rightField;
    queryPredicate.hasLeftField     = nil;
    queryPredicate.rightFieldID   = nil;
    queryPredicate.leftFieldID    = leftUserValue;
    queryPredicate.comparson        = comparsonOperator;
    return queryPredicate;
}

+ (void)deletePredicate:(RptqQueryPredicate *)predicate {
    if (predicate) {
        NSManagedObjectContext *objectContext = predicate.managedObjectContext;
        if (objectContext) {
            [objectContext deleteObject:predicate];
        }
    }
}

#pragma mark -
#pragma mark Public

- (NSString *)symbolForDisplay {
    switch (self.comparson) {
        case 0:
            return @"==";
            break;
        case 1:
            return @"!=";
            break;
        case 2:
            return @">";
            break;
        case 3:
            return @">=";
            break;
        case 4:
            return @"<";
            break;
        case 5:
            return @"<=";
            break;
        default:
            return @"==";
            break;
    }
}

- (NSString *)symbolForComparson {
    switch (self.comparson) {
        case 0:
            return @"=";
            break;
        case 1:
            return @"<>";
            break;
        case 2:
            return @">";
            break;
        case 3:
            return @">=";
            break;
        case 4:
            return @"<";
            break;
        case 5:
            return @"<=";
            break;
        default:
            return @"==";
            break;
    }
}

- (id)debugQuickLookObject {
    NSMutableString *description = [[NSMutableString alloc] init];
    [description appendFormat:@"*********\n"];
    [description appendFormat:@"Identifier:         %lld\n", self.identifier];
    [description appendFormat:@"Sort:               %hd\n", self.comparson];
    [description appendFormat:@"Right field:        %@\n", self.hasRightField];
    [description appendFormat:@"Right pred:         %@\n", self.rightFieldID];
    [description appendFormat:@"Left field:         %@\n", self.hasLeftField];
    [description appendFormat:@"Left pred:          %@\n", self.leftFieldID];
    [description appendFormat:@"Query:              %@\n", self.inQuery];
    [description appendFormat:@"*********"];
    return description;
}

@end
