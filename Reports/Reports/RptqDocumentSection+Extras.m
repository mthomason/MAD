//
//  RptqDocumentSection+Extras.m
//  Reports
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
    [self setHeight:@44.0000f];
    [self setLayoutHeight:@0.0000f];
    [self setNumberOfRows:@1];
    
    
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

- (void)addHasRowsFixed:(RptqDocumentSectionRows *)value {
    if ([[self hasRows] isKindOfClass:[NSMutableOrderedSet class]]) {
        [(NSMutableOrderedSet *)[self hasRows] addObject:value];
    } else {
        NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self hasRows]];
        [tempSet addObject:value];
        [self setHasRows: tempSet];
    }
}

- (void)removeHasRowsFixed:(RptqDocumentSectionRows *)value {
    if ([[self hasRows] isKindOfClass:[NSMutableOrderedSet class]]) {
        [(NSMutableOrderedSet *)[self hasRows] removeObject:value];
    } else {
        NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:[self hasRows]];
        [tempSet removeObject:value];
        [self setHasRows: tempSet];
    }
}

- (NSString *)sectionKey {
    NSCharacterSet *nonAumericCharacterSet = [[NSCharacterSet alphanumericCharacterSet] invertedSet];
    NSString *objectIdAsUrlString = [[[self objectID] URIRepresentation] absoluteString];
    NSString *section = [NSString stringWithFormat:@"%d", [[self identifier] integerValue]];
    NSArray *components = [objectIdAsUrlString componentsSeparatedByCharactersInSet:nonAumericCharacterSet];
    NSString *key = [components componentsJoinedByString: section];
    return key;
}

- (NSUInteger)nextDropIndexForSection {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqDocumentObject class])];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: NSStringFromSelector(@selector(dropIndex))
                                                                     ascending: NO];
    [request setSortDescriptors: [NSArray arrayWithObject:sortDescriptor]];
    [request setFetchLimit:1];
    NSError *error = nil;
    NSArray *fetchResults = [[self managedObjectContext] executeFetchRequest:request error:&error];
    NSUInteger dropIndex = 0;
    if (error == nil) {
        RptqDocumentObject *lastObject = [fetchResults lastObject];
        BOOL tempObjectId = [[lastObject objectID] isTemporaryID];
        if (tempObjectId == NO) {
            dropIndex = [[lastObject dropIndex] integerValue] + 1;
        }
    }
    return dropIndex;
}

#pragma mark - Static

+ (id)getDocumentSectionForObjectID:(NSManagedObjectID *)objectId fromObjectContext:(NSManagedObjectContext *)managedObjectContext {
    NSManagedObject *result = [managedObjectContext objectRegisteredForID:objectId];
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

+ (RptqDocumentSection *)getDocumentGroupHeaderAtLevel:(NSUInteger)groupLevel forQuery:(RptqQuery *)query {
    RptqDocumentSection *resultSection = nil;
    RptqDocument *document = [[query inDatabase] ownedByQueryAsStaticResource];
    NSSet *groupsUnsorted = [[[[[[document hasDatabaseSchemas] anyObject] hasQueries] anyObject] hasQueryGroups] retain];
    for (RptqQueryGroup *group in groupsUnsorted) {
        if ([[group weight] integerValue] == groupLevel) {
            NSSet *sections = [[group hasSection] retain];
            for (RptqDocumentSection *section in sections) {
                if ([[section type] integerValue] == MNSDocumentSectionTypeGroupHeader) {
                    resultSection = section;
                    break;
                }
            }
            [sections release];
            break;
        }
    }
    [groupsUnsorted release];
    return resultSection;
}

+ (RptqDocumentSection *)getDocumentGroupFooterAtLevel:(NSUInteger)groupLevel forQuery:(RptqQuery *)query {
    RptqDocumentSection *resultSection = nil;
    RptqDocument *document = [[query inDatabase] ownedByQueryAsStaticResource];
    NSSet *groupsUnsorted = [[[[[[document hasDatabaseSchemas] anyObject] hasQueries] anyObject] hasQueryGroups] retain];
    for (RptqQueryGroup *group in groupsUnsorted) {
        if ([[group weight] integerValue] == groupLevel) {
            NSSet *sections = [[group hasSection] retain];
            for (RptqDocumentSection *section in sections) {
                if ([[section type] integerValue] == MNSDocumentSectionTypeGroupFooter) {
                    resultSection = section;
                    break;
                }
            }
            [sections release];
            break;
        }
    }
    [groupsUnsorted release];
    return resultSection;
}

+ (RptqDocumentSection *)getDocumentSectionForRow:(NSInteger)row
                                         forQuery:(RptqQuery *)query {
    
    NSInteger numberOfGroups = [[query hasQueryGroups] count];//[RptqQueryGroup numberOfGroupsForQuery:query];
    RptqDocumentSection *resultSection = nil;
    if (row < (numberOfGroups * 2) + 5) {
        
        RptqDocument *document = [[query inDatabase] ownedByQueryAsStaticResource];

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
                NSSet *groupsUnsorted = [[query hasQueryGroups] retain];
                NSString *weight = NSStringFromSelector(@selector(weight));
                NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:weight ascending:YES];
                NSArray *sortedArray = [groupsUnsorted sortedArrayUsingDescriptors:@[sortDescriptor]];
                RptqQueryGroup *group = sortedArray[groupNumber];

                NSSet *sections = [[group hasSection] retain];
                for (RptqDocumentSection *section in sections) {
                    if ([[section type] integerValue] == MNSDocumentSectionTypeGroupHeader) {
                        resultSection = [[section retain] autorelease];
                        break;
                    }
                }
                [sections release];

                [groupsUnsorted release];
                break;
            }
            
            case MNSDocumentSectionTypeGroupFooter: {
                NSInteger body          = 2 + numberOfGroups;
                NSInteger indentLevel   = body - (row - body);
                NSInteger groupNumber   = indentLevel - 2;
                NSSet *groupsUnsorted   = [[query hasQueryGroups] retain];
                NSString *weight = NSStringFromSelector(@selector(weight));
                NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:weight ascending:YES];
                NSArray *sortedArray = [groupsUnsorted sortedArrayUsingDescriptors:@[sortDescriptor]];
                RptqQueryGroup *group = sortedArray[groupNumber];
                NSSet *sections = [[group hasSection] retain];
                for (RptqDocumentSection *section in sections) {
                    if ([[section type] integerValue] == MNSDocumentSectionTypeGroupFooter) {
                        resultSection = [[section retain] autorelease];
                        break;
                    }
                }
                [sections release];
                [groupsUnsorted release];
                break;
            }
            
            default:
                break;
        }
        
    }

    return resultSection;
}


// This is the layout height for page rendering... the designer section height is stored in the db
+ (CGFloat)layoutHeightForSectionAtRow:(NSUInteger)sectionRow inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext:managedObjectContext];
    RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
    RptqQuery *query = [[database hasQueries] anyObject];
    return [RptqDocumentSection layoutHeightForSection: [RptqDocumentSection getDocumentSectionForRow: sectionRow forQuery: query]];
}

// This is the layout height for page rendering... the designer section height is stored in the db
+ (CGFloat)layoutHeightForSection:(RptqDocumentSection *)section {
    CGFloat resultHeight = CGSizeZero.height;
    for (RptqDocumentSectionRows *row in [section hasRows]) {
        for (RptqDocumentObject *element in [row hasObjects]) {
            
            CGFloat originPointX        = [[element dropPointX] floatValue];
            CGFloat originPointY        = [[element dropPointY] floatValue];
            CGRect elementCanvasRect    = [element frameInSectionForSpacingWithOriginPoint:CGPointMake(originPointX, originPointY)];

            CGFloat totalHeight = elementCanvasRect.size.height + elementCanvasRect.origin.y;
            if (totalHeight > resultHeight) {
                resultHeight = totalHeight;
                [section setLayoutHeight:@(resultHeight)];
            }
        }
    }
    return resultHeight;
}

+ (void)setHeight:(CGFloat)height forSectionAtRow:(NSUInteger)sectionRow inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    
    RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext:managedObjectContext];
    RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
    RptqQuery *query = [[database hasQueries] anyObject];
    RptqDocumentSection *section = [RptqDocumentSection getDocumentSectionForRow: sectionRow forQuery: query];
    [section setHeight: @(height)];
    
}

+ (void)setLayoutHeight:(CGFloat)height forSectionAtRow:(NSUInteger)sectionRow inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    
    RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext:managedObjectContext];
    RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
    RptqQuery *query = [[database hasQueries] anyObject];
    RptqDocumentSection *section = [RptqDocumentSection getDocumentSectionForRow: sectionRow forQuery: query];
    [section setLayoutHeight: @(height)];
    
}

+ (void)setVisibility:(BOOL)isVisible forSectionAtRow:(NSUInteger)sectionRow inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    
    RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext:managedObjectContext];
    RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
    RptqQuery *query = [[database hasQueries] anyObject];
    RptqDocumentSection *section = [RptqDocumentSection getDocumentSectionForRow: sectionRow forQuery: query];
    [section setVisibility: [NSNumber numberWithBool:isVisible]];
    
}

+ (void)setNumberOfRows:(NSUInteger)numberOfRows forSectionAtRow:(NSUInteger)sectionRow inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    
    RptqDocument *document = [RptqDocument getMainDocumentForManagedObjectContext:managedObjectContext];
    RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
    RptqQuery *query = [[database hasQueries] anyObject];
    RptqDocumentSection *section = [RptqDocumentSection getDocumentSectionForRow: sectionRow forQuery: query];
    
    if ([[section numberOfRows] integerValue] == numberOfRows) {
        
        //No change

    } else if (numberOfRows > [[section numberOfRows] integerValue]) {

        //Add row
        RptqDocumentSectionRows *newRowToAppend = [NSEntityDescription insertNewObjectForEntityForName: NSStringFromClass([RptqDocumentSectionRows class])
                                                                                inManagedObjectContext: managedObjectContext];
        NSMutableOrderedSet *hasRows = [[NSMutableOrderedSet alloc] initWithArray:[[section hasRows] array]];
        [newRowToAppend setInSection:section];
        [hasRows addObject:newRowToAppend];
        [section setHasRows:hasRows];
        [hasRows release]; hasRows = nil;
        
    } else if (numberOfRows < [[section numberOfRows] integerValue]) {

        //Remove row
        RptqDocumentSectionRows *rowToDelete = [[section hasRows] lastObject];
        NSMutableOrderedSet *hasRows = [[NSMutableOrderedSet alloc] initWithArray:[[section hasRows] array]];
        [[hasRows lastObject] setInSection:nil];
        [hasRows removeObjectAtIndex:[hasRows count] - 1];
        [section setHasRows:hasRows];
        [hasRows release]; hasRows = nil;
        [rowToDelete setInSection:nil];

    }
    [section setNumberOfRows: [NSNumber numberWithInteger:numberOfRows]];
    
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

+ (NSInteger)getRowForSection:(RptqDocumentSection *)section {
    
    NSInteger result = 0;
    BOOL breakNow = NO;
    SectionEnumerator *enumerator = [[SectionEnumerator alloc] initWithManagedObjectContext:[section managedObjectContext]];
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

- (MNSDocumentSectionType)getDocumentSectionType {
    return [[self type] integerValue];
}

- (NSString *)localizedDisplayName {
    NSString *result = nil;
    switch ([[self type] integerValue]) {
        case MNSDocumentSectionTypeReportHeader:
            result = NSLocalizedString(@"Report Header", @"Report Header");
            break;
        case MNSDocumentSectionTypePageHeader:
            result = NSLocalizedString(@"Page Header", @"Page Header");
            break;
        case MNSDocumentSectionTypeBody:
            result = NSLocalizedString(@"Report Detail", @" Report Detail");
            break;
        case MNSDocumentSectionTypePageFooter:
            result = NSLocalizedString(@"Page Footer", @"Page Footer");
            break;
        case MNSDocumentSectionTypeReportFooter:
            result = NSLocalizedString(@"Report Footer", @"Report Footer");
            break;
        case MNSDocumentSectionTypeGroupHeader:
            result = [[self inGroup] fieldNameQuery];
            result = [NSString stringWithFormat:NSLocalizedString(@"G%d - %@", @"\"Group Header 1\""), [[[self inGroup] weight] integerValue], [[self inGroup] fieldNameQuery]];
            break;
        case MNSDocumentSectionTypeGroupFooter:
            result = [NSString stringWithFormat:NSLocalizedString(@"G%d - %@", @"\"Group Footer 1\""),  [[[self inGroup] weight] integerValue], [[self inGroup] fieldNameQuery]];
            break;
        default:
            break;
    }
    return result;
}

#pragma mark - MTProtocolCompare

- (BOOL)isEqualTo:(id)sender {
    BOOL result;
    if ([self isEqual:sender]) {
        result = YES;
    } else {
        RptqDocumentSection *s = sender;
        result = [[self identifier] isEqualToNumber:[s identifier]];
    }
    return result;
}

@end
