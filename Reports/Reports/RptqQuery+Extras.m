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

#import "RptqDocument.h"
#import "RptqDocument+Extras.h"
#import "RptqDocumentSection.h"
#import "RptqDocumentSection+Extras.h"
#import "RptqDatabase.h"
#import "RptqDatabase+Extras.h"
#import "RptqQuery.h"
#import "RptqQuery+Extras.h"
#import "MTGraph.h"
#import "MTPair.h"
#import "RptqQueryGroup.h"
#import "RptqQueryField.h"
#import "RptqQueryField+Extras.h"
#import "RptqDatabaseSchemaTable.h"
#import "RptqDatabaseSchemaField.h"
#import "RptqDatabaseSchemaField+Extras.h"
#import "RptqQueryLinks.h"
#import "RptqQueryLinks+Extras.h"
#import "RptqDatabase.h"
#import "MTDatabase.h"
#import "MTGraph.h"
#import "RptqQueryTable.h"
#import "RptqQueryTable+Extras.h"


@implementation RptqQuery (Extras)

#pragma mark - Overrides

//+ (RptqQuery *)RptqQueryForDocument:(RptqDocument *)document {
//    return [[[[document hasDatabaseSchemas] anyObject] hasQueries] anyObject];
//}

- (void)awakeFromInsert {
    [super awakeFromInsert];
    
    // MARK: Auto increment row counter
    NSString *queryField = NSStringFromSelector(@selector(identifier));
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqQuery class])];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: queryField ascending:NO];
    [request setSortDescriptors: @[sortDescriptor]];
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

- (RptqDocumentSection *)documentSectionForRow:(NSInteger)row {
    NSInteger numberOfGroups = self.hasQueryGroups.count;
    RptqDocumentSection *resultSection = nil;
    if (row < (numberOfGroups * 2) + 5) {
        
        RptqDocument *document = self.inDatabase.ownedByQueryAsStaticResource;
        
        switch ([RptqDocumentSection getSectionTypeforRow:row withNumberOfGroups:numberOfGroups]) {
                
            case MNSDocumentSectionTypeReportHeader:
                resultSection = [document hasReportHeaderSection];
                break;
                
            case MNSDocumentSectionTypePageHeader:
                resultSection = [document hasPageHeaderSection];
                break;
                
            case MNSDocumentSectionTypeBody:
                resultSection = [document hasDetailSection];
                break;
                
            case MNSDocumentSectionTypePageFooter:
                resultSection = [document hasPageFooterSection];
                break;
                
            case MNSDocumentSectionTypeReportFooter:
                resultSection = [document hasReportFooterSection];
                break;
                
            case MNSDocumentSectionTypeGroupHeader: {
                NSInteger groupNumber = row - 2;    //Minus Rpt Header and Page Header
                RptqQueryGroup *group = [self queryGroupForIndex:groupNumber];
                resultSection = [self headerSectionInSections:[group hasSection]];
                break;
            }
                
            case MNSDocumentSectionTypeGroupFooter: {
                NSInteger body          = 2 + numberOfGroups;
                NSInteger indentLevel   = body - (row - body);
                NSInteger groupNumber   = indentLevel - 2;
                RptqQueryGroup *group = [self queryGroupForIndex:groupNumber];
                resultSection = [self footerSectionInSections:[group hasSection]];
                break;
            }
                
            default:
                break;
        }
        
    }
    
    return resultSection;

}

- (RptqDocumentSection *)footerSectionInSections:(NSSet *)sections {
    RptqDocumentSection *resultSection = nil;
    for (RptqDocumentSection *section in sections) {
        if ([[section type] integerValue] == MNSDocumentSectionTypeGroupFooter) {
            resultSection = section;
            break;
        }
    }
    return resultSection;
}

- (RptqDocumentSection *)headerSectionInSections:(NSSet *)sections {
    RptqDocumentSection *resultSection = nil;
    for (RptqDocumentSection *section in sections) {
        if ([[section type] integerValue] == MNSDocumentSectionTypeGroupHeader) {
            resultSection = section;
            break;
        }
    }
    return resultSection;
}

- (RptqQueryGroup *)firstQueryGroup {
    NSArray *queryGroups = [self sortedQueryGroups];
    return ([queryGroups count] >= 1) ? queryGroups[0] : nil;
}

- (RptqQueryGroup *)queryGroupForIndex:(NSUInteger)index {
    NSArray *queryGroups = [self sortedQueryGroups];
    return (index < [queryGroups count]) ? queryGroups[index] : nil;
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
            [groupToRemove removeHasSectionObject: sections[0]];
            [groupToRemove removeHasSectionObject: sections[1]];
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

- (NSUInteger)numberOfTables {
    return self.hasQueryTables.count;
}

- (NSArray *)sortDescriptorsForDatabase:(MTDatabase *)mainDatabase {
    NSMutableArray *sortedSortDescriptorsGroup = [[NSMutableArray alloc] init];
    
    for (RptqQueryGroup *queryGroup in [self sortedQueryGroups]) {
        @autoreleasepool {
            BOOL sortAscending = ([[queryGroup sort] integerValue] == MNSSortOrderAccending);
            RptqQueryField *groupField = [queryGroup hasField];
            
            NSString *queryTable = [[groupField inQueryTable] queryAlias];
            NSString *safeQueryTable = [mainDatabase safeIdentifier:queryTable];
            NSString *fieldName = [[groupField databaseSchemaField] name];
            NSString *safeFieldName = [mainDatabase safeIdentifier:fieldName];
            NSString *keyFirstPart = [safeQueryTable stringByAppendingString:@"."];
            NSString *key = [keyFirstPart stringByAppendingString: safeFieldName];
            
            SEL sel = [MTDatabaseField selectorForSorting:[[[groupField databaseSchemaField] dataType] integerValue]];
            NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey: key
                                                                           ascending: sortAscending
                                                                            selector: sel];
            [sortedSortDescriptorsGroup addObject:sortDescriptor];
        }
    }
    return sortedSortDescriptorsGroup;
}

#pragma mark - MTProtocolCompare

- (BOOL)isEqualTo:(id)sender {
    BOOL result;
    if ([self isEqual:sender]) {
        result = YES;
    } else {
        RptqQuery *s = sender;
        result = [self.identifier isEqualToNumber:s.identifier];
    }
    return result;
}

@end
