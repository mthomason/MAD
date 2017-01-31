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

#import "RptqDocumentSection+Extras.h"

#import <CoreData/NSFetchRequest.h>
#import <CoreData/NSManagedObjectContext.h>
#import <CoreData/NSEntityDescription.h>

#import <Foundation/NSSortDescriptor.h>
#import <Foundation/NSIndexPath.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSIndexPath.h>

#import <UIKit/UICollectionView.h>

#import "RptqDocument+Extras.h"
#import "RptqDocumentSectionEnumerator.h"

#import "RptqDatabase.h"
#import "RptqDatabase+Extras.h"

#import "RptqDatabaseSchemaTable.h"

#import "RptqQuery.h"
#import "RptqQuery+Extras.h"

#import "RptqQueryGroup.h"
#import "RptqQueryGroup+Extras.h"

#import "RptqDocumentSectionRows.h"
#import "RptqDocumentSectionRows+Extras.h"

#import "RptqDocumentElement.h"
#import "RptqDocumentElement+Extras.h"
#import "NSManagedObject+Extras.h"

#import "NSManagedObjectID+Extras.h"

#import "RptqDataHelper.h"

@interface RptqDocumentSection ()

@end

@implementation RptqDocumentSection (Extras)

#pragma mark - Overrides

- (void)awakeFromInsert {
    [super awakeFromInsert];
    self.identifier = [RptqDataHelper nextIdentifierForClass:[self class]
                                        managedObjectContext:self.managedObjectContext];
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
    return (self.wrappingStyle) == RptqDocumentSectionWrappingStyleNewPageAfter;
}

- (void)setProducesFormFeed:(BOOL)producesFormFeed {
    self.wrappingStyle = producesFormFeed ?
                                RptqDocumentSectionWrappingStyleNewPageAfter :
                                RptqDocumentSectionWrappingStyleStandard;
}

- (NSManagedObjectID *)copySectionKey {
    return self.objectID.copy;
}

+ (NSNumber *)defaultHeight {
    return @44.0000f;
}

- (void)addHasRowsFixed:(RptqDocumentSectionRows *)value {
    if ([self.hasRows isKindOfClass:[NSMutableOrderedSet class]]) {
        [(NSMutableOrderedSet *)self.hasRows addObject:value];
    } else {
        NSOrderedSet<RptqDocumentSectionRows *> *hasRows = self.hasRows;
        NSMutableOrderedSet *tempSet = hasRows != nil ? [NSMutableOrderedSet orderedSetWithOrderedSet: hasRows] :
                                                        [[NSMutableOrderedSet alloc] init];
        [tempSet addObject:value];
        self.hasRows = tempSet;
    }
}

- (void)removeHasRowsFixed:(RptqDocumentSectionRows *)value {
    if ([self.hasRows isKindOfClass:[NSMutableOrderedSet class]]) {
        [(NSMutableOrderedSet *)self.hasRows removeObject:value];
    } else {
        NSOrderedSet<RptqDocumentSectionRows *> *hasRows = self.hasRows;
        NSMutableOrderedSet *tempSet = hasRows != nil ? [NSMutableOrderedSet orderedSetWithOrderedSet: hasRows] :
                                                        [[NSMutableOrderedSet alloc] init];
        [tempSet removeObject:value];
        self.hasRows = tempSet;
    }
}

- (NSManagedObjectID *)copyKeyForIdentifier {
    return self.objectID.copy;
}

- (int64_t)nextDropIndexForSectionWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {

    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([RptqDocumentElement class])];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: NSStringFromSelector(@selector(dropIndex)) ascending: NO];
    id sortDescriptors = [[NSArray alloc] initWithObjects: sortDescriptor, nil];
    request.sortDescriptors = sortDescriptors;
    request.fetchLimit = 1;

    NSError *error = nil;
    NSArray *fetchResults = [managedObjectContext executeFetchRequest: request
                                                                error: &error];
    int64_t dropIndex = 0;
    if (error == nil) {
        RptqDocumentElement *lastObject = fetchResults.lastObject;
        if (lastObject.objectID.isTemporaryID == NO) {
            dropIndex = lastObject.dropIndex + 1;
        }
    }
    return dropIndex;
}

- (void)addDocumentObject:(RptqDocumentElement *)documentObject withDropPoint:(CGPoint)origin
     managedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    
    [documentObject setOriginPoint: origin];
    
    NSUInteger sectionZero = 0;
    RptqDocumentSectionRows *sectionRow = self.hasRows.firstObject;
    
    NSIndexPath *indexPathForInsert = [NSIndexPath indexPathForItem:(NSInteger)sectionRow.hasObjects.count
                                                          inSection:(NSInteger)sectionZero];
    
    documentObject.dropIndex = [self nextDropIndexForSectionWithManagedObjectContext:managedObjectContext];
    
    NSMutableOrderedSet *hasObjects = sectionRow.hasObjects.mutableCopy;
    [hasObjects insertObject: documentObject atIndex: (NSUInteger)indexPathForInsert.item];
    sectionRow.hasObjects = hasObjects;
}

- (void)setInterfaceHeight:(float)height {
    self.layoutHeight = height;
    self.height = height + 44.0000f;
}

#pragma mark - Static

+ (instancetype)documentSectionForObjectID:(NSManagedObjectID *)objectID
                    inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    return (RptqDocumentSection *)[managedObjectContext objectWithID:objectID];
}


+ (MADDocumentSectionType)getSectionTypeforRow:(NSUInteger)row
                          withNumberOfSections:(NSUInteger)numberOfSections {
    return [self getSectionTypeforRow: row
                   withNumberOfGroups: (numberOfSections > 5 ? (numberOfSections - 2 - 2 - 1) / 2 : 0)];
}

+ (MADDocumentSectionType)getSectionTypeforRow:(NSUInteger)row
                            withNumberOfGroups:(NSUInteger)numberOfGroups {
    NSUInteger documentHeader    = 0;
    NSUInteger pageHeader        = 1;
    NSUInteger body              = 2 + numberOfGroups;       //6
    NSUInteger pageFooter        = 3 + (2 * numberOfGroups); //11
    NSUInteger documentFooter    = 4 + (2 * numberOfGroups); //12
    MADDocumentSectionType result;

    if (row == body) {
        result = MADDocumentSectionTypeBody;
        
    } else  if (row == pageHeader) {
        result = MADDocumentSectionTypePageHeader;
        
    } else if (row == pageFooter) {
        result = MADDocumentSectionTypePageFooter;
        
    } else if (row == documentHeader) {
        result = MADDocumentSectionTypeReportHeader;
        
    } else if (row == documentFooter) {
        result = MADDocumentSectionTypeReportFooter;
        
    } else {
    
        result = ((row - pageHeader) <= numberOfGroups) ?
                MADDocumentSectionTypeGroupHeader :
                MADDocumentSectionTypeGroupFooter;
    }
    
    return result;
}

+ (RptqDocumentSection *)groupHeaderForLevel:(NSUInteger)groupLevel query:(RptqQuery *)query {
    RptqQueryGroup *group = [query queryGroupForIndex:groupLevel];
    return [RptqDocumentSection headerSectionInSections:group.hasSection];
}

+ (RptqDocumentSection *)groupFooterForLevel:(NSUInteger)groupLevel query:(RptqQuery *)query {
    RptqQueryGroup *group =  [query queryGroupForIndex:groupLevel];
    return [RptqDocumentSection footerSectionInSections:group.hasSection];
}

// This is the layout height for page rendering... the designer section height is stored in the db
- (CGFloat)layoutHeightCalculated {
    CGFloat resultHeight = CGSizeZero.height;
    CGPoint dropPoint; CGSize marginSize; CGRect elementCanvasRect; CGFloat totalHeight;
    if (self.visibility) {
        for (RptqDocumentSectionRows *row in self.hasRows) {
            for (RptqDocumentElement *element in row.hasObjects) {
                [(NSValue *)element.dropPoint getValue:&dropPoint];
                marginSize           = [element sizeCalculated];
                elementCanvasRect    = CGRectMake(dropPoint.x, dropPoint.y,
                                                  marginSize.width, marginSize.height);
                
                totalHeight = elementCanvasRect.size.height + elementCanvasRect.origin.y;
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
    if (section.inGroup) {
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

- (MADDocumentSectionType)getDocumentSectionType {
    return self.type;
}

- (NSString *)localizedDisplayName {
    NSString *result = nil;
    switch (self.type) {
    
        case MADDocumentSectionTypeReportHeader:
            result = NSLocalizedString(@"Report Header",
                                       @"Report Header");
            break;

        case MADDocumentSectionTypePageHeader:
            result = NSLocalizedString(@"Page Header", @"Page Header");
            break;

        case MADDocumentSectionTypeBody:
            result = NSLocalizedString(@"Report Detail", @" Report Detail");
            break;

        case MADDocumentSectionTypePageFooter:
            result = NSLocalizedString(@"Page Footer", @"Page Footer");
            break;

        case MADDocumentSectionTypeReportFooter:
            result = NSLocalizedString(@"Report Footer", @"Report Footer");
            break;

        case MADDocumentSectionTypeGroupHeader:
            result = [NSString stringWithFormat:NSLocalizedString(@"Group Header (%@)", @"\"Group Header 1\""), [self.inGroup fieldNameQuery]];
            break;

        case MADDocumentSectionTypeGroupFooter:
            result = [NSString stringWithFormat:NSLocalizedString(@"Group Footer - (%@)", @"\"Group Footer 1\""),  [self.inGroup fieldNameQuery]];
            break;

        default:
            break;

    }
    return result;
}

+ (instancetype)newDocumentSectionOfType:(MADDocumentSectionType)type
                 forManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {

    NSEntityDescription *entity;
    entity = [NSEntityDescription entityForName: NSStringFromClass([RptqDocumentSection class])
                         inManagedObjectContext: managedObjectContext];

    RptqDocumentSection *section = [[self alloc] initWithEntity: entity
                                 insertIntoManagedObjectContext: managedObjectContext];
    NSNumber *sectionType = [[NSNumber alloc] initWithShort:type];
    section.visibility = @YES;
    section.type = sectionType;
    
    return section;
}

#pragma mark - Handling Rows

static inline NSInteger MADDocumentSectionIndexLevel(NSInteger row, NSInteger body);
static inline NSInteger MADDocumentSectionIndexLevel(NSInteger row, NSInteger body) {
    return (row <= body) ? row : body - (row - body);
}

+ (NSString *)getDocumentSectionNameForRow: (NSInteger)row
                        withNumberOfGroups: (NSInteger)numberOfGroups {
    
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

        NSString *format = isGroupHeader ? NSLocalizedString(@"Group Header %d", @"") :
                                           NSLocalizedString(@"Group Footer %d", @"");
        groupText = [[NSString alloc] initWithFormat:format,
                                                     MADDocumentSectionIndexLevel(row, body) - 1];
        

    }
    return groupText;
}

+ (NSInteger)getDocumentSectionIndentLevelForRow:(NSInteger)row
                              withNumberOfGroups:(NSInteger)numberOfGroups {
    NSInteger body = 2 + numberOfGroups;
    return (row <= body) ? row : body - (row - body);
}

+ (NSInteger)getRowForSection:(RptqDocumentSection *)section {
    
    RptqDocument *document = [section inRptqDocument];

    RptqDocumentSectionEnumerator *enumerator;
    enumerator = [[RptqDocumentSectionEnumerator alloc] initWithDocument:document];
    RptqDocumentSection *sec;
    NSInteger result = 0;
    for (sec in enumerator) {
        if ([section.objectID isEqual:sec.objectID]) break;
        result++;
    }
    return result;
}

+ (RptqDocumentSection *)footerSectionInSections:(NSSet <RptqDocumentSection *> *)sections {
    for (RptqDocumentSection *section in sections) {
        if (section.type == MADDocumentSectionTypeGroupFooter) {
            return section;
            break;
        }
    }
    return nil;
}

+ (RptqDocumentSection *)headerSectionInSections:(NSSet <RptqDocumentSection *> *)sections {
    for (RptqDocumentSection *section in sections) {
        if (section.type == MADDocumentSectionTypeGroupHeader) {
            return section;
            break;
        }
    }
    return nil;
}

- (id)debugQuickLookObject {
    NSMutableString *description = [[NSMutableString alloc] init];
    [description appendFormat:@"********** RptqDocumentSection **********\n"];
    [description appendFormat:@"Identifier:             %lld\n", self.identifier];
    [description appendFormat:@"Type:                   %@\n", self.type];
    [description appendFormat:@"********** RptqDocumentSection **********"];
    return description;
}

@end
