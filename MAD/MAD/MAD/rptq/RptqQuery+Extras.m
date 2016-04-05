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

#import "MTDatabaseField.h"
#import "MTDatabase.h"

#import "RptqDocument.h"
#import "RptqDocument+Extras.h"

#import "RptqDocumentSection.h"
#import "RptqDocumentSection+Extras.h"

#import "RptqDatabase.h"
#import "RptqDatabase+Extras.h"

#import "RptqQuery.h"

#import "RptqQueryGroup.h"

#import "RptqQueryField.h"
#import "RptqQueryField+Extras.h"

#import "RptqDatabaseSchemaTable.h"

#import "RptqDatabaseSchemaField.h"
#import "RptqDatabaseSchemaField+Extras.h"

#import "RptqQueryLinks.h"
#import "RptqQueryLinks+Extras.h"

#import "RptqDatabase.h"

#import "RptqQueryTable.h"
#import "RptqQueryTable+Extras.h"

#import "MADSortOrder.h"

#import <CoreData/NSFetchRequest.h>
#import <CoreData/NSManagedObjectContext.h>
#import <CoreData/NSEntityDescription.h>
#import <Foundation/NSSortDescriptor.h>
#import <Foundation/NSString.h>

@implementation RptqQuery (Extras)

#pragma mark - Overrides

//+ (RptqQuery *)RptqQueryForDocument:(RptqDocument *)document {
//    return [[[document.hasDatabaseSchemas anyObject] hasQueries] anyObject];
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


- (NSUInteger)sectionCount {
    return 5 + self.hasQueryGroups.count * 2;
}

#pragma mark - Actions

- (RptqDocumentSection *)documentSectionForRow:(NSUInteger)row {
    NSUInteger numberOfGroups = self.hasQueryGroups.count;
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
                NSUInteger groupNumber = row - 2;    //Minus Rpt Header and Page Header
                RptqQueryGroup *group = [self queryGroupForIndex:groupNumber];
                resultSection = [self headerSectionInSections:[group hasSection]];
                break;
            }
                
            case MNSDocumentSectionTypeGroupFooter: {
                NSUInteger body          = 2 + numberOfGroups;
                NSUInteger indentLevel   = body - (row - body);
                NSUInteger groupNumber   = indentLevel - 2;
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
    return (queryGroups.count >= 1) ? queryGroups[0] : nil;
}

- (RptqQueryGroup *)queryGroupForIndex:(NSUInteger)index {
    NSArray *queryGroups = [self sortedQueryGroups];
    return (index < queryGroups.count) ? queryGroups[index] : nil;
}

- (NSArray *)sortedQueryGroups {
    NSString *weight = NSStringFromSelector(@selector(weight));
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:weight ascending:YES];
    NSArray *sortDescriptors = @[sortDescriptor];
    return [self.hasQueryGroups sortedArrayUsingDescriptors:sortDescriptors];
}

- (NSUInteger)numberOfTables {
    return self.hasQueryTables.count;
}

- (NSArray *)sortDescriptorsForDatabase:(MTDatabase *)database {
    NSMutableArray *sortedSortDescriptorsGroup = [[NSMutableArray alloc] init];
    
    for (RptqQueryGroup *queryGroup in [self sortedQueryGroups]) {
        @autoreleasepool {
            BOOL sortAscending = ([[queryGroup sort] integerValue] == MNSSortOrderAccending);
            RptqQueryField *groupField = [queryGroup hasField];
            
            NSString *queryTable = [groupField.inQueryTable queryAlias];
            NSString *safeQueryTable = [database safeIdentifier: queryTable];
            NSString *safeFieldName = [database safeIdentifier: groupField.databaseSchemaField.name];
            NSString *keyFirstPart = [safeQueryTable stringByAppendingString:@"."];
            NSString *key = [keyFirstPart stringByAppendingString: safeFieldName];
            
            SEL sel = [MADDataType selectorForSorting: groupField.databaseSchemaField.dataType.unsignedIntegerValue];
            NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey: key
                                                                           ascending: sortAscending
                                                                            selector: sel];
            [sortedSortDescriptorsGroup addObject:sortDescriptor];
        }
    }
    return sortedSortDescriptorsGroup;
}

- (RptqQueryTable *)addQueryTableBasedOnSchemaTable:(RptqDatabaseSchemaTable *)schemaTable forManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {

    RptqQueryTable *newQueryTable = [RptqQueryTable newQueryTableForSchemaTable:schemaTable database:self.inDatabase forManagedObjectContext:managedObjectContext];

    NSMutableSet *tablesInQuery = [[NSMutableSet alloc] initWithSet: self.hasQueryTables];
    NSMutableSet *newQueryFields = [[NSMutableSet alloc] initWithCapacity:schemaTable.hasFields.count];
    
    for (RptqDatabaseSchemaField *field in schemaTable.hasFields) {
        @autoreleasepool {
            
            RptqQueryField *newQueryField = [RptqQueryField newQueryFieldForManagedObjectContext:managedObjectContext];
            newQueryField.inQueryTable = newQueryTable;
            newQueryField.databaseSchemaField = field;
            newQueryTable.inQuery = self;
            [newQueryFields addObject:newQueryField];
            
        }
    }
    newQueryTable.hasQueryFields = newQueryFields;
    [tablesInQuery addObject:newQueryTable];
    
    self.hasQueryTables = tablesInQuery;
    
    return newQueryTable;
}

- (id)debugQuickLookObject {
    NSMutableString *description = [[NSMutableString alloc] init];
    [description appendFormat:@"*********\n"];
    [description appendFormat:@"Identifier:         %@\n", self.identifier];
    [description appendFormat:@"Sort:               %@\n", self.cachedText];
    [description appendFormat:@"Override:           %@\n", self.override];
    [description appendFormat:@"Override text:      %@\n", self.overrideText];
    [description appendFormat:@"Fields:             %@\n", self.hasFields];
    [description appendFormat:@"Query cache:        %@\n", self.hasQueryCache];
    [description appendFormat:@"Database:           %@\n", self.inDatabase];
    [description appendFormat:@"Query tables (%lu): %@\n", (unsigned long)self.hasQueryTables.count, self.hasQueryTables];
    [description appendFormat:@"Query groups (%lu): %@\n", (unsigned long)self.hasQueryGroups.count, self.hasQueryGroups];
    
    NSArray *sortedQueryGroups = [self sortedQueryGroups];
    for (RptqQueryGroup *group in sortedQueryGroups) {
        [description appendFormat:@"\t\t- %@", group];
    }
    
    [description appendFormat:@"Query links:        %@\n", self.hasQueryLinks];
    [description appendFormat:@"Query predicate:    %@\n", self.hasQueryPredicate];
    [description appendFormat:@"Query sort:         %@\n", self.hasQuerySort];
    [description appendFormat:@"*********"];
    return description;
}

@end
