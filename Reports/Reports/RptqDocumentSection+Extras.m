//
//  RptqDocumentSection+Extras.m
//  TheReportViewer
//
//  Created by Michael Thomason on 2/12/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "RptqDocumentSection+Extras.h"

@implementation RptqDocumentSection (Extras)

#pragma mark - Overrides

- (void)awakeFromInsert {
    [super awakeFromInsert];
    
    // MARK: Auto increment row counter.
    NSString *queryField = NSStringFromSelector(@selector(identifier));
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqDocumentSection class])];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: queryField ascending:NO];
    [request setSortDescriptors: [NSArray arrayWithObject:sortDescriptor]];
    [request setFetchLimit:1];
    NSError *error = nil;
    NSArray *fetchResults = [[self managedObjectContext] executeFetchRequest:request error:&error];
    NSUInteger identifier = 0;
    if (error == nil) {
        RptqDocumentSection *lastObject = [fetchResults lastObject];
        identifier = [[lastObject identifier] integerValue] + 1;
    }
    [self setIdentifier:@(identifier)];
    
    // MARK: Initalize section height.
    [self setHeight:@(44.0000f)];
    
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

- (void)addHasObjectsObjectFixed:(RptqDocumentObject *)value {
    NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.hasObjects];
    [tempSet addObject:value];
    self.hasObjects = tempSet;
}

#pragma mark - Static

+ (id)getDocumentSectionForObjectID:(NSManagedObjectID *)objid fromObjectContext:(NSManagedObjectContext *)moc {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqDocumentSection class])];
    request.predicate = [NSPredicate predicateWithFormat:@"self == %@", objid];
    NSError *error = nil;
    NSArray *results = [moc executeFetchRequest:request error:&error];
    RptqDocumentSection *result = nil;
    if (results) result = [results lastObject];
    return result;
}

+ (MNSDocumentSectionType)getSectionTypeforRow:(NSInteger)row withNumberOfGroups:(NSInteger)numberOfGroups {
    NSInteger documentHeader    = 0;
    NSInteger pageHeader        = 1;
    NSInteger body              = 2 + numberOfGroups;       //6
    NSInteger pageFooter        = 3 + (2 * numberOfGroups); //11
    NSInteger documentFooter    = 4 + (2 * numberOfGroups); //12
    MNSDocumentSectionType result;

    if (row == documentHeader) {
        result = MNSDocumentSectionTypeReportHeader;
    } else if (row == pageHeader) {
        result = MNSDocumentSectionTypePageHeader;
    } else if (row == body) {
        result = MNSDocumentSectionTypeBody;
    } else if (row == pageFooter) {
        result = MNSDocumentSectionTypePageFooter;
    } else if (row == documentFooter) {
        result = MNSDocumentSectionTypeReportFooter;
    } else {
        NSInteger locationRelitaveToGroup = row - pageHeader;
        BOOL isGroupHeader = locationRelitaveToGroup <= numberOfGroups;
        if (isGroupHeader) {
            result = MNSDocumentSectionTypeGroupHeader;
        } else {
            result = MNSDocumentSectionTypeGroupFooter;
        }
    }
    
    return result;
}

+ (RptqDocumentSection *)getDocumentSectionForRow:(NSInteger)row
                          forManagedObjectContext:(NSManagedObjectContext *)objectContext {
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqQueryGroup class])];
    NSError *error = nil;
    NSInteger result = [objectContext countForFetchRequest:request error:&error];
    NSInteger numberOfGroups = (error) ? 0 : result;

    RptqDocumentSection *resultSection = nil;
    if (row < (numberOfGroups * 2) + 5) {
        RptqDocument *document = [[RptqDocument getMainDocumentForManagedObjectContext:objectContext] retain];
        //NSLog(@"Row: %d, Number of Groups: %d", row, numberOfGroups);
        switch ([RptqDocumentSection getSectionTypeforRow:row withNumberOfGroups:numberOfGroups]) {
            case MNSDocumentSectionTypeReportHeader:
                resultSection = [[[document hasReportHeaderSection] retain] autorelease];
                break;
            case MNSDocumentSectionTypePageHeader:
                resultSection = [[[document hasPageHeaderSection] retain] autorelease];
                break;
            case MNSDocumentSectionTypeBody:
                resultSection = [[[document hasDetailSection] retain] autorelease];
                break;
            case MNSDocumentSectionTypePageFooter:
                resultSection = [[[document hasPageFooterSection] retain] autorelease];
                break;
            case MNSDocumentSectionTypeReportFooter:
                resultSection = [[[document hasReportFooterSection] retain] autorelease];
                break;
            case MNSDocumentSectionTypeGroupHeader: {
                NSInteger groupNumber = row - 2;    //Minus Rpt Header and Page Header
                NSSet *groupsUnsorted = [[[[[[document hasDatabaseSchemas] anyObject] hasQueries] anyObject] hasQueryGroups] retain];
                //NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey: @"weight"
                //                                                               ascending: YES];
                //NSArray *groupSorted = [[[groupsUnsorted allObjects] sortedArrayUsingDescriptors: [NSArray arrayWithObject:sortDescriptor]] retain];
                for (RptqQueryGroup *group in groupsUnsorted) {
                    NSLog(@"Group Header Section, %@, %@,\nGroupNumber: %d", group, ([[group weight] integerValue] == groupNumber)?@"YES":@"NO", groupNumber);
                    if ([[group weight] integerValue] == groupNumber) {
                        NSSet *sections = [[group hasSection] retain];
                        for (RptqDocumentSection *section in sections) {
                            if ([[section type] integerValue] == MNSDocumentSectionTypeGroupHeader) {
                                resultSection = [[section retain] autorelease];
                                break;
                            }
                        }                    
                        [sections release];
                        break;
                    }
                }
                [groupsUnsorted release];
                //[groupSorted release];
                break;
            }
            case MNSDocumentSectionTypeGroupFooter: {
                NSLog(@"Get GF, %d", row);
                NSInteger body              = 2 + numberOfGroups;
                NSInteger indentLevel = body - (row - body);
                NSInteger groupNumber = indentLevel - 2;
                NSSet *groupsUnsorted = [[[[[document hasDatabaseSchemas] anyObject] hasQueries] anyObject] hasQueryGroups];
                for (RptqQueryGroup *group in groupsUnsorted) {
                    //NSLog(@"Group Footer Section, %@, %@,\nGroupNumber: %d", group, ([[group weight] integerValue] == groupNumber)?@"YES":@"NO", groupNumber);
                    if ([[group weight] integerValue] == groupNumber) {
                        NSSet *sections = [[group hasSection] retain];
                        for (RptqDocumentSection *section in sections) {
                            if ([[section type] integerValue] == MNSDocumentSectionTypeGroupFooter) {
                                resultSection = [[section retain] autorelease];
                                break;
                            }
                        }                    
                        [sections release];
                        break;
                    }
                }
                break;
            }
            default:
                NSLog(@"Get Default, %d", row);
                
                break;
        }
        
        //NSLog(@"Document Sections: %@", resultSection);
        
        [document autorelease];
    }

    return resultSection;
}

+ (NSString *)getDocumentSectionNameForRow:(NSInteger)row withNumberOfGroups:(NSInteger)numberOfGroups {
    NSInteger documentHeader    = 0;
    NSInteger pageHeader        = 1;
    NSInteger body              = 2 + numberOfGroups;       //6
    NSInteger pageFooter        = 3 + (2 * numberOfGroups); //11
    NSInteger documentFooter    = 4 + (2 * numberOfGroups); //12
    NSString *groupText = nil;
    if (row == documentHeader) {
        groupText = NSLocalizedString(@"Report Header", @"Report Header");
    } else if (row == pageHeader) {
        groupText = NSLocalizedString(@"Page Header", @"Page Header");
    } else if (row == body) {
        groupText = NSLocalizedString(@"Report Detail", @" Report Detail");
    } else if (row == pageFooter) {
        groupText = NSLocalizedString(@"Page Footer", @"Page Footer");
    } else if (row == documentFooter) {
        groupText = NSLocalizedString(@"Report Footer", @"Report Footer");
    } else {
        NSInteger locationRelitaveToGroup = row - pageHeader;
        BOOL isGroupHeader = locationRelitaveToGroup <= numberOfGroups;
        NSInteger indentLevel = (row <= body) ? row : body - (row - body);
        if (isGroupHeader) {
            groupText = [NSString stringWithFormat:NSLocalizedString(@"Group Header %d", @""), indentLevel - 1];
        } else {
            groupText = [NSString stringWithFormat:NSLocalizedString(@"Group Footer %d", @""), indentLevel - 1];
        }
    }
    return groupText;
}

+ (NSInteger)getDocumentSectionIndentLevelForRow:(NSInteger)row withNumberOfGroups:(NSInteger)numberOfGroups {
    NSInteger body = 2 + numberOfGroups;
    return (row <= body) ? row : body - (row - body);
}

+ (NSInteger)getRowForSection:(RptqDocumentSection *)section inManagedObjectContext:(UIManagedDocumentReport *)managedDocument {
    
    NSInteger result = 0;
    BOOL breakNow = NO;
    SectionEnumerator *enumerator = [[SectionEnumerator alloc] initWithManagedDocumentQuery: managedDocument];
    NSURL *urlNeedle = [[[section objectID] URIRepresentation] retain];

    for (RptqDocumentSection *sec in enumerator) {
        NSURL *urlInHaystack = [[[sec objectID] URIRepresentation] retain];
        breakNow = [urlNeedle isEqual:urlInHaystack];
        [urlInHaystack release];
        if (breakNow) break;
        result++;
    }
    [enumerator release];
    [urlNeedle release];
    return result;
}

- (NSString *)localizedDisplayName {
    NSString *result = nil;
    switch ([[self type] integerValue]) {
        case MNSDocumentSectionTypeReportHeader:
            result = [[NSLocalizedString(@"Report Header", @"Report Header") retain] autorelease];
            break;
        case MNSDocumentSectionTypePageHeader:
            result = [[NSLocalizedString(@"Page Header", @"Page Header") retain] autorelease];
            break;
        case MNSDocumentSectionTypeBody:
            result = [[NSLocalizedString(@"Report Detail", @" Report Detail") retain] autorelease];
            break;
        case MNSDocumentSectionTypePageFooter:
            result = [[NSLocalizedString(@"Page Footer", @"Page Footer") retain] autorelease];
            break;
        case MNSDocumentSectionTypeReportFooter:
            result = [[NSLocalizedString(@"Report Footer", @"Report Footer") retain] autorelease];
            break;
        case MNSDocumentSectionTypeGroupHeader:
            result = [[[NSString stringWithFormat:NSLocalizedString(@"Group Header %d", @""), [[[self inGroup] weight] integerValue]] retain] autorelease];
            break;
        case MNSDocumentSectionTypeGroupFooter:
            result = [[[NSString stringWithFormat:NSLocalizedString(@"Group Footer %d", @""),  [[[self inGroup] weight] integerValue]] retain] autorelease];
            break;
        default:
            break;
    }
    return result;
}

#pragma mark - MTProtocolCompare

- (BOOL)isEqualTo:(id)sender {
    BOOL result;
    if ([self isEqualTo:sender]) {
        result = YES;
    } else {
        RptqDocumentSection *s = sender;
        result = [[self identifier] isEqualToNumber:[s identifier]];
    }
    return result;
}

@end