//
//  RptqQueryGroup+Extras.h
//  Reports
//
//  Created by Michael Thomason on 3/7/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "RptqQueryGroup+Extras.h"
#import <CoreData/NSEntityDescription.h>
#import <CoreData/NSFetchRequest.h>
#import <CoreData/NSManagedObjectContext.h>

#import "RptqDatabaseSchemaField.h"

#import "RptqDocument.h"
#import "RptqDocument+Extras.h"

#import "RptqQueryField.h"
#import "RptqQueryField+Extras.h"

#import "RptqDocumentSection.h"
#import "RptqDocumentSection+Extras.h"

#import "RptqDocumentSectionRows.h"

#import "RptqQuery.h"
#import "RptqQuery+Extras.h"

@implementation RptqQueryGroup (Extras)

+ (instancetype)newQueryGroupQueryWithSortOrder:(MNSSortOrder)sortOrder
                        andManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {

    NSEntityDescription *entityDescriptionQueryGroup = [NSEntityDescription entityForName:NSStringFromClass([RptqQueryGroup class]) inManagedObjectContext: managedObjectContext];
    RptqQueryGroup *queryGroup = [[self alloc] initWithEntity:entityDescriptionQueryGroup insertIntoManagedObjectContext: managedObjectContext];
    
    NSNumber *sort = [[NSNumber alloc] initWithUnsignedInteger:sortOrder];
    queryGroup.sort = sort;
    
    NSNumber *weight = [[NSNumber alloc] initWithInteger: ([queryGroup lastWeightWithManagedObjectContext:managedObjectContext] + 1)];
    queryGroup.weight = weight;

    return queryGroup;
}

#pragma mark - Overrides

- (void)awakeFromInsert {
    [super awakeFromInsert];
    
    // MARK: Auto increment row counter
    NSString *queryField = NSStringFromSelector(@selector(identifier));
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqQueryGroup class])];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: queryField ascending:NO];
    NSArray *sortDescriptors = @[sortDescriptor];
    request.sortDescriptors = sortDescriptors;
    request.fetchLimit = 1;
    NSError *error = nil;
    NSArray *fetchResults = [[self managedObjectContext] executeFetchRequest:request error:&error];
    NSUInteger identifier = 0;
    if (error == nil) {
        RptqQueryGroup *lastObject = [fetchResults lastObject];
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

+ (NSUInteger)numberOfGroupsForQuery:(RptqQuery *)query {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqQueryGroup class])];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"inQuery == %@", [query objectID]];
    request.predicate = predicate;
    NSError *error = nil;
    NSUInteger result = [query.managedObjectContext countForFetchRequest:request error:&error];
    return (error) ? 0 : result;
}

#pragma mark - Member functions

- (NSInteger)lastWeightWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqQueryGroup class])];
    
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: @"weight" ascending: NO];
    NSArray *sortDescriptors = @[sortDescriptor];
    request.sortDescriptors = sortDescriptors;
    request.fetchLimit = 1;

    NSError *error = nil;
    NSArray *queryGroupLast = [managedObjectContext executeFetchRequest: request error: &error];

    NSInteger weight = 0;
    if (queryGroupLast.count > 0) {
        RptqQueryGroup *lastGroup = queryGroupLast[0];
        weight = lastGroup.weight.integerValue;
    }
    return weight;
}

- (NSString *)fieldNameNice {
    return [self.hasField toStringHumanReadable];
}

- (NSString *)fieldNameQuery {
    return [self.hasField toString];
}

- (NSString *)sortDisplayNice {
    switch (self.sort.integerValue) {

        case MNSSortOrderAccending:
            return @"accending";
            break;
        
        case MNSSortOrderDecending:
            return @"decending";
            break;
        
        default:
            return @"";
            break;
    }
}

- (NSInteger)location {
    NSArray *sortedQueryGroups = self.inQuery.sortedQueryGroups;
    NSInteger location = 0;
    for (RptqQueryGroup *queryGroup in sortedQueryGroups) {
        if ([queryGroup isEqual:self]) {
            break;
        }
        location++;
    }
    return location;
}

#pragma mark - MTProtocolCompare

- (id)debugQuickLookObject {
    NSMutableString *description = [[NSMutableString alloc] init];
    [description appendFormat:@"*********\n"];
    [description appendFormat:@"Identifier:         %@\n", self.identifier];
    [description appendFormat:@"Sort:               %@\n", self.sort];
    [description appendFormat:@"Weight              %@\n", self.weight];
    [description appendFormat:@"Field:              %@\n", self.hasField];
    [description appendFormat:@"Section:            %@\n", self.hasSection];
    [description appendFormat:@"Query:              %@\n", self.inQuery];
    [description appendFormat:@"*********"];
    return description;
}

@end
