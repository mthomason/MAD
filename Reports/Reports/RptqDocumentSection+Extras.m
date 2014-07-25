//
//  RptqDocumentSection+Extras.m
//  Reports
//
//  Created by Michael Thomason on 2/12/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import <objc/runtime.h>
#import "RptqDocumentSection+Extras.h"
#import "RptqDocument+Extras.h"
#import "SectionEnumerator.h"
#import "MTProtocolCompare.h"
#import "MAReportDocument.h"

#import "RptqDatabase.h"
#import "RptqDatabase+Extras.h"

#import "RptqDatabaseSchemaTable.h"

#import "RptqQuery.h"
#import "RptqQuery+Extras.h"

#import "RptqQueryGroup.h"
#import "RptqQueryGroup+Extras.h"

#import "RptqDocumentSectionRows.h"
#import "RptqDocumentSectionRows+Extras.h"

#import "RptqDocumentObject.h"
#import "RptqDocumentObject+Extras.h"

@interface RptqDocumentSection ()

//@property (nonatomic, retain) NSString *secKey;

@end

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
    NSNumber *identiferNumber = @(identifier);
    [self setIdentifier:identiferNumber];
    
    // MARK: Initalize section height.
    NSNumber *height = [RptqDocumentSection defaultHeight];
    NSNumber *layoutHeight = @(0.0000f);
    NSNumber *numberOfRows = @(1);
    [self setHeight:height];
    [self setLayoutHeight:layoutHeight];
    [self setNumberOfRows:numberOfRows];
    
    
}

- (void)awakeFromFetch {
    [super awakeFromFetch];

    //NSString *keyForIdentifier = [self keyForIdentifier];
    //[self setSecKey: keyForIdentifier];
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

- (NSString *)sectionKey {
    return [self keyForIdentifier];
}

+ (NSNumber *)defaultHeight {
    return @(44.0000f);
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

- (NSString *)keyForIdentifier {
    char buf[18];
    snprintf(buf, 18, "s%lu", (unsigned long)[[self objectID] hash]);
    return [NSString stringWithUTF8String:buf];
    
    //NSManagedObjectID *objectID = [[self objectID] hash];
    //NSURL *url = [objectID URIRepresentation];
    //return [url absoluteString];
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

- (NSIndexPath *)addDocumentObject:(RptqDocumentObject *)documentObject
                     withDropPoint:(CGPoint)origin {
    
    
    [documentObject setOrigin:origin];
    [documentObject setDropPoint:origin];
    
    NSUInteger sectionZero = 0;
    RptqDocumentSectionRows *sectionRow = [[self hasRows] objectAtIndex: sectionZero];
    NSUInteger lastIndex = [[sectionRow hasObjects] count];
    NSIndexPath *indexInsert = [NSIndexPath indexPathForItem:lastIndex inSection:sectionZero];
    
    NSNumber *dropIndex = @([self nextDropIndexForSection]);
    [documentObject setDropIndex:dropIndex];
    
    NSOrderedSet *documentObjects = [sectionRow hasObjects];
    NSMutableOrderedSet *hasObjects = [[NSMutableOrderedSet alloc] initWithOrderedSet:documentObjects];
    
    [hasObjects insertObject:documentObject atIndex:[indexInsert item]];
    [sectionRow setHasObjects:hasObjects];
    
    [[self managedObjectContext] save:nil];
    return indexInsert;
    
}

- (void)setInterfaceHeight:(CGFloat)height {
    [self setLayoutHeight:@(height)];
    [self setHeight:@(height + 44.0000f)];
    [[self managedObjectContext] save:nil];
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
    RptqQueryGroup *group = [query queryGroupForIndex:groupLevel];
    return [RptqDocumentSection headerSectionInSections:[group hasSection]];
}

+ (RptqDocumentSection *)getDocumentGroupFooterAtLevel:(NSUInteger)groupLevel forQuery:(RptqQuery *)query {
    RptqQueryGroup *group =  [query queryGroupForIndex:groupLevel];
    return [RptqDocumentSection footerSectionInSections:[group hasSection]];
}

+ (RptqDocumentSection *)getDocumentSectionForDocument:(RptqDocument *)document {
    RptqDatabase *database = [document defaultDatabase];
    RptqQuery *query = [database defaultQuery];
    return [RptqDocumentSection getDocumentSectionForRow:0
                                                forQuery:query];
}

+ (RptqDocumentSection *)getDocumentSectionForRow:(NSInteger)row
                                         forQuery:(RptqQuery *)query {
    
    NSInteger numberOfGroups = [[query hasQueryGroups] count];
    RptqDocumentSection *resultSection = nil;
    if (row < (numberOfGroups * 2) + 5) {
        
        RptqDocument *document = [[query inDatabase] ownedByQueryAsStaticResource];

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
                RptqQueryGroup *group = [query queryGroupForIndex:groupNumber];
                resultSection = [RptqDocumentSection headerSectionInSections:[group hasSection]];
                break;
            }
            
            case MNSDocumentSectionTypeGroupFooter: {
                NSInteger body          = 2 + numberOfGroups;
                NSInteger indentLevel   = body - (row - body);
                NSInteger groupNumber   = indentLevel - 2;
                RptqQueryGroup *group = [query queryGroupForIndex:groupNumber];
                resultSection = [RptqDocumentSection footerSectionInSections:[group hasSection]];
                break;
            }
            
            default:
                break;
        }
        
    }

    return resultSection;
}

+ (RptqDocumentSection *)footerSectionInSections:(NSSet *)sections {
    RptqDocumentSection *resultSection = nil;
    for (RptqDocumentSection *section in sections) {
        if ([[section type] integerValue] == MNSDocumentSectionTypeGroupFooter) {
            resultSection = section;
            break;
        }
    }
    return resultSection;
}

+ (RptqDocumentSection *)headerSectionInSections:(NSSet *)sections {
    RptqDocumentSection *resultSection = nil;
    for (RptqDocumentSection *section in sections) {
        if ([[section type] integerValue] == MNSDocumentSectionTypeGroupHeader) {
            resultSection = section;
            break;
        }
    }
    return resultSection;
}

- (CGFloat)layoutHeightCalculated {
    return [RptqDocumentSection layoutHeightForSection:self];
}

+ (NSDictionary *)layoutHeightsBySectionKey:(RptqDocument *)document {
    NSMutableDictionary *dictionary = [NSMutableDictionary new];
    SectionEnumerator *enumerator = [[SectionEnumerator alloc] initWithDocument:document];
    for (RptqDocumentSection *sec in enumerator) {
        @autoreleasepool {
            [sec fireFault];
            NSString *sectionKey = [sec sectionKey];
            CGFloat layoutHight = [RptqDocumentSection layoutHeightForSection:sec];
            dictionary[sectionKey] = @(layoutHight);
        }
    }
    return dictionary;
}

- (void)fireFault {
    NSString *marginLeftMethod = NSStringFromSelector(@selector(marginLeft));
    [self valueForKey:marginLeftMethod];
}

// This is the layout height for page rendering... the designer section height is stored in the db
+ (CGFloat)layoutHeightForSection:(RptqDocumentSection *)section {
    CGFloat resultHeight = CGSizeZero.height;
    if ([[section visibility] boolValue]) {
        for (RptqDocumentSectionRows *row in [section hasRows]) {
            for (RptqDocumentObject *element in [row hasObjects]) {
                
                CGFloat originPointX        = [[element dropPointX] floatValue];
                CGFloat originPointY        = [[element dropPointY] floatValue];
                
                CGSize marginSize           = [element size];
                CGRect elementCanvasRect    = CGRectMake(originPointX, originPointY, marginSize.width, marginSize.height);
                
                CGFloat totalHeight = elementCanvasRect.size.height + elementCanvasRect.origin.y;
                if (totalHeight > resultHeight) {
                    resultHeight = totalHeight;
                }
            }
        }
    }
    return resultHeight;
}

+ (void)setHeight:(CGFloat)height forSectionAtRow:(NSUInteger)sectionRow inDocument:(RptqDocument *)document {
    
    RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
    RptqQuery *query = [[database hasQueries] anyObject];
    RptqDocumentSection *section = [RptqDocumentSection getDocumentSectionForRow: sectionRow forQuery: query];
    [section setHeight: @(height)];
    
}

+ (void)setLayoutHeight:(CGFloat)height forSectionAtRow:(NSUInteger)sectionRow inDocument:(RptqDocument *)document {
    
    RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
    RptqQuery *query = [[database hasQueries] anyObject];
    RptqDocumentSection *section = [RptqDocumentSection getDocumentSectionForRow: sectionRow forQuery: query];
    [section setLayoutHeight: @(height)];
    
}

+ (void)setVisibility:(BOOL)isVisible forSectionAtRow:(NSUInteger)sectionRow inDocument:(RptqDocument *)document {
    
    RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
    RptqQuery *query = [[database hasQueries] anyObject];
    RptqDocumentSection *section = [RptqDocumentSection getDocumentSectionForRow: sectionRow forQuery: query];
    [section setVisibility: [NSNumber numberWithBool:isVisible]];
    
}

+ (void)setNumberOfRows:(NSUInteger)numberOfRows forSectionAtRow:(NSUInteger)sectionRow inDocument:(RptqDocument *)document {
    
    RptqDatabase *database = [[document hasDatabaseSchemas] anyObject];
    RptqQuery *query = [[database hasQueries] anyObject];
    RptqDocumentSection *section = [RptqDocumentSection getDocumentSectionForRow: sectionRow forQuery: query];
    
    if ([[section numberOfRows] integerValue] == numberOfRows) {
        
        //No change

    } else if (numberOfRows > [[section numberOfRows] integerValue]) {

        //Add row
        NSManagedObjectContext *managedObjectContext = [document managedObjectContext];
        RptqDocumentSectionRows *newRowToAppend = [NSEntityDescription insertNewObjectForEntityForName: NSStringFromClass([RptqDocumentSectionRows class])
                                                                                inManagedObjectContext: managedObjectContext];
        NSMutableOrderedSet *hasRows = [[NSMutableOrderedSet alloc] initWithArray:[[section hasRows] array]];
        [newRowToAppend setInSection:section];
        [hasRows addObject:newRowToAppend];
        [section setHasRows:hasRows];
        
    } else if (numberOfRows < [[section numberOfRows] integerValue]) {

        //Remove row
        RptqDocumentSectionRows *rowToDelete = [[section hasRows] lastObject];
        NSMutableOrderedSet *hasRows = [[NSMutableOrderedSet alloc] initWithArray:[[section hasRows] array]];
        [[hasRows lastObject] setInSection:nil];
        [hasRows removeObjectAtIndex:[hasRows count] - 1];
        [section setHasRows:hasRows];
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
        groupText = NSLocalizedString(@"Report Detail", @"Report Detail");
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
    RptqDocument *document = [RptqDocumentSection rptqDocumentForSection:section];
    SectionEnumerator *enumerator = [[SectionEnumerator alloc] initWithDocument:document];
    NSURL *urlNeedle = [[section objectID] URIRepresentation];
    for (RptqDocumentSection *sec in enumerator) {
        @autoreleasepool {
            NSURL *urlInHaystack = [[sec objectID] URIRepresentation];
            breakNow = [urlNeedle isEqual:urlInHaystack];
            if (breakNow) break;
            result++;
        }
    }
    return result;
}

- (RptqDocument *)inRptqDocument {
    return [RptqDocumentSection rptqDocumentForSection:self];
}

+ (RptqDocument *)rptqDocumentForSection:(RptqDocumentSection *)section {
    RptqDocument *result = nil;
    if ([section inGroup]) {
        result = [[[[section inGroup] inQuery] inDatabase] ownedByQueryAsStaticResource];
    } else if ([section inReport]) {
        result = [section inReport];
    } else if ([section inReportPageFooter]) {
        result = [section inReportPageFooter];
    } else if ([section inReportPageHeader]) {
        result = [section inReportPageHeader];
    } else if ([section inReportReportFooter]) {
        result = [section inReportReportFooter];
    } else if ([section inReportReportHeader]) {
        result = [section inReportReportHeader];
    }
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
            result = [NSString stringWithFormat:NSLocalizedString(@"Group Header (%@)", @"\"Group Header 1\""), [[self inGroup] fieldNameQuery]];
            break;
        case MNSDocumentSectionTypeGroupFooter:
            result = [NSString stringWithFormat:NSLocalizedString(@"Group Footer - (%@)", @"\"Group Footer 1\""),  [[self inGroup] fieldNameQuery]];
            break;
        default:
            break;
    }
    return result;
}

+ (RptqDocumentSection *)RptqDocumentSectionForDocument:(RptqDocument *)document andType:(MNSDocumentSectionType)typeDocumentSection andLevel:(NSUInteger)level {
    
    RptqDocumentSection *documentSection = nil;
    switch (typeDocumentSection) {
            
        case MNSDocumentSectionTypeBody:
            documentSection = [document hasDetailSection];
            break;
            
        case MNSDocumentSectionTypePageHeader:
            documentSection = [document hasPageHeaderSection];
            break;
            
        case MNSDocumentSectionTypePageFooter:
            documentSection = [document hasPageFooterSection];
            break;
            
        case MNSDocumentSectionTypeReportHeader:
            documentSection = [document hasReportHeaderSection];
            break;
            
        case MNSDocumentSectionTypeReportFooter:
            documentSection = [document hasReportFooterSection];
            break;
            
        case MNSDocumentSectionTypeGroupHeader: {
            RptqDatabase *database = [document defaultDatabase];
            RptqQuery *query = [database defaultQuery];
            documentSection = [RptqDocumentSection getDocumentGroupHeaderAtLevel: level
                                                                        forQuery: query];
            break;
        }
        case MNSDocumentSectionTypeGroupFooter: {
            RptqDatabase *database = [document defaultDatabase];
            RptqQuery *query = [database defaultQuery];
            documentSection = [RptqDocumentSection getDocumentGroupFooterAtLevel: level
                                                                        forQuery: query];
            break;
        }
        default:
            NSAssert(false, @"Unknown type");
            break;
    }
    return documentSection;
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
