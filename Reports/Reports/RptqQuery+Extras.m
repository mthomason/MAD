//
//  RptqQuery+Extras.m
//  Reports
//
//  Created by Michael Thomason on 12/6/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "RptqQuery+Extras.h"

#import "RptqDocument.h"
#import "MTGraph.h"
#import "MTPair.h"
#import "RptqQueryGroup.h"
#import "RptqQueryLinks.h"
#import "RptqQueryLinks+Extras.h"
#import "RptqDatabase.h"
#import "MTDatabase.h"
#import "MTGraph.h"
#import "RptqQueryTable.h"
#import "RptqDatabaseSchemaTable.h"

@implementation RptqQuery (Extras)

#pragma mark - Overrides

+ (RptqQuery *)RptqQueryForDocument:(RptqDocument *)document {
    return [[[[document hasDatabaseSchemas] anyObject] hasQueries] anyObject];
}

- (void)awakeFromInsert {
    [super awakeFromInsert];
    
    // MARK: Auto increment row counter
    NSString *queryField = NSStringFromSelector(@selector(identifier));
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqQuery class])];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: queryField ascending:NO];
    [request setSortDescriptors: [NSArray arrayWithObject:sortDescriptor]];
    [request setFetchLimit:1];
    NSError *error = nil;
    NSArray *fetchResults = [[self managedObjectContext] executeFetchRequest:request error:&error];
    NSUInteger identifier = 0;
    if (error == nil) {
        RptqQuery *lastObject = [fetchResults lastObject];
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

#pragma mark - Actions

- (RptqQueryGroup *)firstQueryGroup {
    NSArray *queryGroups = [self sortedQueryGroups];
    return ([queryGroups count] >= 1) ? [queryGroups objectAtIndex:0] : nil;
}

- (RptqQueryGroup *)queryGroupForIndex:(NSUInteger)index {
    NSArray *queryGroups = [self sortedQueryGroups];
    return (index < [queryGroups count]) ? [queryGroups objectAtIndex:index] : nil;
}

- (NSArray *)sortedQueryGroups {
    NSString *weight = NSStringFromSelector(@selector(weight));
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:weight ascending:YES];
    NSArray *sortDescriptors = @[sortDescriptor];
    return [[self hasQueryGroups] sortedArrayUsingDescriptors:sortDescriptors];
}

- (void)deleteQueryGroupAtIndex:(NSInteger)index {
    RptqQueryGroup *groupToRemove = [self queryGroupForIndex:index];
    if (groupToRemove) {
        NSSet *sectionsToRemove = [groupToRemove hasSection];
        NSArray *sections = [sectionsToRemove allObjects];
        if ([sections count] == 2) {
            [groupToRemove removeHasSectionObject: [sections objectAtIndex: 0]];
            [groupToRemove removeHasSectionObject: [sections objectAtIndex: 1]];
        }
        [[self managedObjectContext] deleteObject: groupToRemove];
        [self removeHasQueryGroupsObject: groupToRemove];
        
        [[self managedObjectContext] save:nil];
        NSString *weight = NSStringFromSelector(@selector(weight));
        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:weight ascending:YES];
        NSArray *sortedQueryGroups = [[self hasQueryGroups] sortedArrayUsingDescriptors:@[sortDescriptor]];
        NSUInteger counter = 0;
        for (RptqQueryGroup *group in sortedQueryGroups) {
            [group setWeight:@(counter)];
            counter++;
        }
        [[self managedObjectContext] save:nil];
        
    }

}

#pragma mark - MTProtocolCompare

- (BOOL)isEqualTo:(id)sender {
    BOOL result;
    if ([self isEqual:sender]) {
        result = YES;
    } else {
        RptqQuery *s = sender;
        result = [[self identifier] isEqualToNumber:[s identifier]];
    }
    return result;
}

@end
