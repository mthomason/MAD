//
//  RptqQueryGroup+Extras.h
//  Reports
//
//  Created by Michael Thomason on 3/7/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "RptqQueryGroup+Extras.h"
#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Constants.h"
#import "RptqDatabaseSchemaField.h"

#import "RptqDocument.h"
#import "RptqDocument+Extras.h"

#import "RptqQueryField.h"
#import "RptqQueryField+Extras.h"

#import "RptqDocumentSection.h"
#import "RptqDocumentSection+Extras.h"

#import "RptqDocumentSectionRows.h"

@implementation RptqQueryGroup (Extras)

#pragma mark - Overrides

- (void)awakeFromInsert {
    [super awakeFromInsert];
    
    // MARK: Auto increment row counter
    NSString *queryField = NSStringFromSelector(@selector(identifier));
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqQueryGroup class])];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: queryField ascending:NO];
    [request setSortDescriptors: [NSArray arrayWithObject:sortDescriptor]];
    [request setFetchLimit:1];
    NSError *error = nil;
    NSArray *fetchResults = [[self managedObjectContext] executeFetchRequest:request error:&error];
    NSUInteger identifier = 0;
    if (error == nil) {
        RptqQueryGroup *lastObject = [fetchResults lastObject];
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

+ (NSInteger)numberOfGroupsForQuery:(RptqQuery *)query {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqQueryGroup class])];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"inQuery == %@", [query objectID]];
    [request setPredicate:predicate];
    NSError *error = nil;
    NSInteger result = [[query managedObjectContext] countForFetchRequest:request error:&error];
    return (error) ? 0 : result;
}

// MARK: Creating group. Updates document sections to reflect new group.
+ (RptqQueryGroup *)createQueryGroupFor:(RptqQueryField *)queryField andSort:(MNSSortOrder)sortOrder inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    
    NSEntityDescription *entityDescriptionQueryGroup = [NSEntityDescription entityForName:NSStringFromClass([RptqQueryGroup class])
                                                                   inManagedObjectContext:managedObjectContext];
    NSEntityDescription *entityDescriptionDocumentSection = [NSEntityDescription entityForName:NSStringFromClass([RptqDocumentSection class])
                                                                        inManagedObjectContext:managedObjectContext];

    RptqQueryGroup *queryGroup = [[RptqQueryGroup alloc] initWithEntity:entityDescriptionQueryGroup
                                         insertIntoManagedObjectContext:managedObjectContext];
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqQueryGroup class])];
    NSError *error = nil;
    NSInteger groupCount = [managedObjectContext countForFetchRequest:request error:&error];
    groupCount = (error) ? 0 : groupCount;
    
    [queryGroup setHasField:queryField];
    [queryGroup setSort:@(sortOrder)];
    [queryGroup setWeight:@(groupCount - 1)];

    RptqDocumentSectionRows *headerSectionRow = [NSEntityDescription insertNewObjectForEntityForName: NSStringFromClass([RptqDocumentSectionRows class])
                                                                              inManagedObjectContext: managedObjectContext];
    NSOrderedSet *hasRows = [[NSOrderedSet alloc] initWithObject: headerSectionRow];
    
    RptqDocumentSection *dsHeader = [[RptqDocumentSection alloc] initWithEntity:entityDescriptionDocumentSection insertIntoManagedObjectContext:managedObjectContext];
    NSNumber *HeaderType = @(MNSDocumentSectionTypeGroupHeader);
    [dsHeader setType: HeaderType];
    [dsHeader setHasRows:hasRows];
    [dsHeader setVisibility:@YES];
    [headerSectionRow setInSection:dsHeader];
    [queryGroup addHasSectionObject:dsHeader];
    [dsHeader release];
  
    [hasRows release]; hasRows = nil;

    RptqDocumentSectionRows *footerSectionRow = [NSEntityDescription insertNewObjectForEntityForName: NSStringFromClass([RptqDocumentSectionRows class])
                                                                              inManagedObjectContext: managedObjectContext];

    hasRows = [[NSOrderedSet alloc] initWithObject: footerSectionRow];

    RptqDocumentSection *dsFooter = [[RptqDocumentSection alloc] initWithEntity:entityDescriptionDocumentSection insertIntoManagedObjectContext:managedObjectContext];
    NSNumber *type = @(MNSDocumentSectionTypeGroupFooter);
    [dsFooter setType: type];
    [dsFooter setHasRows:hasRows];
    [dsFooter setVisibility:@YES];
    [footerSectionRow setInSection:dsFooter];
    [queryGroup addHasSectionObject:dsFooter];
    [dsFooter release];

    [hasRows release]; hasRows = nil;

    return [queryGroup autorelease];

}

#pragma mark - Member functions

- (id)first {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqQueryGroup class])];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"inQuery == %@ AND weight == 0", [self objectID]];
    [request setPredicate:predicate];
    NSError *error = nil;
    NSArray *resultArray = [[self managedObjectContext] executeFetchRequest:request error:&error];
    RptqQueryGroup *firstGroup = error == nil ? [resultArray lastObject] : nil;
    return firstGroup;
}

- (id)next {
    //RptqQuery *query = [self inQuery];
    //NSArray *hasQueryGroups = [query hasQueryGroups];
    //NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: NSStringFromSelector(@selector(weight)) ascending:YES];
//    [request setSortDescriptors:@[sortDescriptor]];
    //NSArray *hasQueryGroupsSorted = [hasQueryGroups sortedArrayUsingDescriptors:@[sortDescriptor]];
    //return [hasQueryGroupsSorted lastObject];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqQueryGroup class])];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"weight == %d", ([[self weight] integerValue] + 1)];
    [request setPredicate:predicate];
    [request setFetchLimit:1];
    NSError *error = nil;
    NSArray *resultArray = [[self managedObjectContext] executeFetchRequest:request error:&error];
    RptqQueryGroup *nextGroup = error == nil ? [resultArray lastObject] : nil;
    return nextGroup;
}

- (id)previous {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqQueryGroup class])];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"weight == %d", ([[self weight] integerValue] - 1)];
    [request setPredicate:predicate];
    [request setFetchLimit:1];
    NSError *error = nil;
    NSArray *resultArray = [[self managedObjectContext] executeFetchRequest:request error:&error];
    RptqQueryGroup *previousGroup = error == nil ? [resultArray lastObject] : nil;
    return previousGroup;
}

- (NSString *)fieldNameNice {
    return [[[[self hasField] toStringHumanReadable] retain] autorelease];
}

- (NSString *)fieldNameQuery {
    return [[[[self hasField] toString] retain] autorelease];
}

- (NSString *)sortDisplayNice {
    NSString *sort;
    MNSSortOrder sortOrder = [[self sort] integerValue];
    switch (sortOrder) {
        case MNSSortOrderAccending:
            sort = @"accending";
            break;
        case MNSSortOrderDecending:
            sort = @"decending";
            break;
        default:
            sort = @"";
            break;
    }
    return [sort lowercaseString];
}

#pragma mark - MTProtocolCompare

- (BOOL)isEqualTo:(id)sender {
    BOOL result;
    if ([self isEqual:sender]) {
        result = YES;
    } else {
        RptqQueryGroup *s = sender;
        result = [[self identifier] isEqualToNumber:[s identifier]];
    }
    return result;
}

@end