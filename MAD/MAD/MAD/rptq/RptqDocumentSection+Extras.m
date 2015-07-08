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
#import "NSManagedObject+Extras.h"

#import "NSManagedObjectID+Extras.h"

#import "NSObject+DebugDescription.h"

@interface RptqDocumentSection ()

@end

@implementation RptqDocumentSection (Extras)

#pragma mark - Overrides

- (void)awakeFromInsert {
    [super awakeFromInsert];
    
    // MARK: Auto increment row counter.
    NSString *queryField = NSStringFromSelector(@selector(identifier));
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqDocumentSection class])];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: queryField ascending:NO];
    [request setSortDescriptors: @[sortDescriptor]];
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
    
    NSNumber *height = [RptqDocumentSection defaultHeight];
    NSNumber *layoutHeight = @(0.0000f);
    NSNumber *numberOfRows = @(1);
    NSNumber *wrapperStyle = @(RptqDocumentSectionWrappingStyleStandard);
    self.height = height;
    self.layoutHeight = layoutHeight;
    self.numberOfRows = numberOfRows;
    self.wrappingStyle = wrapperStyle;
    
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

- (BOOL)producesFormFeed {
    return [self.wrappingStyle integerValue] == RptqDocumentSectionWrappingStyleNewPageAfter;
}

- (void)setProducesFormFeed:(BOOL)producesFormFeed {
    NSNumber *wrappingStyle = @(producesFormFeed ?
                                    RptqDocumentSectionWrappingStyleNewPageAfter :
                                    RptqDocumentSectionWrappingStyleStandard);
    self.wrappingStyle = wrappingStyle;
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
        NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.hasRows];
        [tempSet addObject:value];
        [self setHasRows: tempSet];
    }
}

- (void)removeHasRowsFixed:(RptqDocumentSectionRows *)value {
    if ([[self hasRows] isKindOfClass:[NSMutableOrderedSet class]]) {
        [(NSMutableOrderedSet *)[self hasRows] removeObject:value];
    } else {
        NSMutableOrderedSet* tempSet = [NSMutableOrderedSet orderedSetWithOrderedSet:self.hasRows];
        [tempSet removeObject:value];
        [self setHasRows: tempSet];
    }
}

- (NSString *)keyForIdentifier {
    return self.objectID.key;
}

- (NSUInteger)nextDropIndexForSection {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqDocumentObject class])];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: NSStringFromSelector(@selector(dropIndex))
                                                                     ascending: NO];
    request.sortDescriptors = @[sortDescriptor];
    request.fetchLimit = 1;
    NSError *error = nil;
    NSArray *fetchResults = [self.managedObjectContext executeFetchRequest: request
                                                                     error: &error];
    NSUInteger dropIndex = 0;
    if (error == nil) {
        RptqDocumentObject *lastObject = fetchResults.lastObject;
        if (lastObject.objectID.isTemporaryID == NO) {
            dropIndex = lastObject.dropIndex.integerValue + 1;
        }
    }
    return dropIndex;
}

- (NSIndexPath *)addDocumentObject:(RptqDocumentObject *)documentObject
                     withDropPoint:(CGPoint)origin {
    
    [documentObject setOrigin:origin];
    
    NSUInteger sectionZero = 0;
    RptqDocumentSectionRows *sectionRow = [self hasRows][sectionZero];
    NSUInteger lastIndex = [[sectionRow hasObjects] count];
    NSIndexPath *indexInsert = [NSIndexPath indexPathForItem:lastIndex inSection:sectionZero];
    
    NSNumber *dropIndex = @([self nextDropIndexForSection]);
    [documentObject setDropIndex:dropIndex];
    
    NSOrderedSet *documentObjects = [sectionRow hasObjects];
    NSMutableOrderedSet *hasObjects = [[NSMutableOrderedSet alloc] initWithOrderedSet:documentObjects];
    
    [hasObjects insertObject:documentObject atIndex:[indexInsert item]];
    [sectionRow setHasObjects:hasObjects];
    
    [self.managedObjectContext save:nil];
    return indexInsert;
    
}

- (void)setInterfaceHeight:(CGFloat)height {
    NSNumber *layoutHeightWrapper = @(height);
    NSNumber *heightWrapper = @(height + 44.0000f);
    self.layoutHeight = layoutHeightWrapper;
    self.height = heightWrapper;
    [self.managedObjectContext save:nil];
}

#pragma mark - Static

+ (instancetype)documentSectionForObjectID:(NSManagedObjectID *)objectId inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    return (RptqDocumentSection *)[managedObjectContext objectRegisteredForID:objectId];
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

+ (RptqDocumentSection *)groupHeaderForLevel:(NSUInteger)groupLevel query:(RptqQuery *)query {
    RptqQueryGroup *group = [query queryGroupForIndex:groupLevel];
    return [RptqDocumentSection headerSectionInSections:[group hasSection]];
}

+ (RptqDocumentSection *)groupFooterForLevel:(NSUInteger)groupLevel query:(RptqQuery *)query {
    RptqQueryGroup *group =  [query queryGroupForIndex:groupLevel];
    return [RptqDocumentSection footerSectionInSections:[group hasSection]];
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

// This is the layout height for page rendering... the designer section height is stored in the db
- (CGFloat)layoutHeightCalculated {
    CGFloat resultHeight = CGSizeZero.height;
    if ([[self visibility] boolValue]) {
        for (RptqDocumentSectionRows *row in [self hasRows]) {
            for (RptqDocumentObject *element in [row hasObjects]) {
                
                CGFloat originPointX        = [element.dropPointX floatValue];
                CGFloat originPointY        = [element.dropPointY floatValue];
                
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

- (RptqDocument *)inRptqDocument {
    return [RptqDocumentSection rptqDocumentForSection:self];
}

+ (RptqDocument *)rptqDocumentForSection:(RptqDocumentSection *)section {
    RptqDocument *result = nil;
    if ([section inGroup]) {
        result = section.inGroup.inQuery.inDatabase.ownedByQueryAsStaticResource;
    } else if (section.inReport) {
        result = section.inReport;
    } else if (section.inReportPageFooter) {
        result = section.inReportPageFooter;
    } else if (section.inReportPageHeader) {
        result = section.inReportPageHeader;
    } else if (section.inReportReportFooter) {
        result = section.inReportReportFooter;
    } else if (section.inReportReportHeader) {
        result = section.inReportReportHeader;
    }
    return result;
}

- (MNSDocumentSectionType)getDocumentSectionType {
    return self.type.integerValue;
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

#pragma mark - Handling Rows

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
    RptqDocument *document = [section inRptqDocument];
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

- (id)debugQuickLookObject {
    NSMutableString *description = [[NSMutableString alloc] init];
    [description appendFormat:@"********** RptqDocumentSection **********\n"];
    [description appendFormat:@"Identifier:             %@\n", self.identifier];
    [description appendFormat:@"Type:                   %@\n", self.type];
    [description appendFormat:@"********** RptqDocumentSection **********"];
    return description;
}

@end
