//
//  RptqQueryGroup+Extras.h
//  Reports
//
//  Created by Michael Thomason on 3/7/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "RptqQueryGroup+Extras.h"

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
+ (RptqQueryGroup *)createQueryGroupFor:(RptqDatabaseSchemaField *)field  andSort:(MNSSortOrder)sortOrder inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    
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
    
    [queryGroup setHasField:field];
    [queryGroup setField:[field name]];
    [queryGroup setTable:[[field inTable] name]];
    [queryGroup setSort:@(sortOrder)];
    [queryGroup setWeight:@(groupCount - 1)];
    
    RptqDocumentSection *dsHeader = [[RptqDocumentSection alloc] initWithEntity:entityDescriptionDocumentSection insertIntoManagedObjectContext:managedObjectContext];
    [dsHeader setType: [NSNumber numberWithInteger: MNSDocumentSectionTypeGroupHeader]];
    [queryGroup addHasSectionObject:dsHeader];
    [dsHeader release];
  
    RptqDocumentSection *dsFooter = [[RptqDocumentSection alloc] initWithEntity:entityDescriptionDocumentSection insertIntoManagedObjectContext:managedObjectContext];
    [dsFooter setType: [NSNumber numberWithInteger:MNSDocumentSectionTypeGroupFooter]];
    [queryGroup addHasSectionObject:dsFooter];
    [dsFooter release];
    
    NSLog(@"QueryGroup: %@", queryGroup);
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
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqQueryGroup class])];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"inQuery == %@ AND weight == %d", [self objectID], ([[self weight] integerValue] + 1)];
    [request setPredicate:predicate];
    NSError *error = nil;
    NSArray *resultArray = [[self managedObjectContext] executeFetchRequest:request error:&error];
    RptqQueryGroup *nextGroup = error == nil ? [resultArray lastObject] : nil;
    return nextGroup;
}

- (id)previous {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqQueryGroup class])];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"inQuery == %@ AND weight == %d", [self objectID], ([[self weight] integerValue] - 1)];
    [request setPredicate:predicate];
    NSError *error = nil;
    NSArray *resultArray = [[self managedObjectContext] executeFetchRequest:request error:&error];
    RptqQueryGroup *previousGroup = error == nil ? [resultArray lastObject] : nil;
    return previousGroup;
}

- (NSString *)fieldNameNice {
    NSString *fieldNameNice = [[[NSString stringWithFormat:@"%@.%@", [self table], [self field]] lowercaseString] retain];
    return [fieldNameNice autorelease];
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
    if ([self isEqualTo:sender]) {
        result = YES;
    } else {
        RptqQueryGroup *s = sender;
        result = [[self identifier] isEqualToNumber:[s identifier]];
    }
    return result;
}

@end