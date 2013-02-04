//
//  RptqDocumentSection+Extras.h
//  TheReportViewer
//
//  Created by Michael Thomason on 2/12/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "RptqDocumentSection.h"
#import "RptqDocument+Extras.h"
#import "SectionEnumerator.h"
#import "MTProtocolCompare.h"
#import "RptqQueryGroup+Extras.h"

//Do not change these enum values, as they are used in core data.
typedef NS_ENUM(NSUInteger, MNSDocumentSectionType) {
	MNSDocumentSectionTypeReportHeader = 1,
	MNSDocumentSectionTypeReportFooter = 2,
	MNSDocumentSectionTypePageHeader = 3,
	MNSDocumentSectionTypePageFooter = 4,
    MNSDocumentSectionTypeBody = 5,
    MNSDocumentSectionTypeGroupHeader = 6,
    MNSDocumentSectionTypeGroupFooter = 7,
};

@interface RptqDocumentSection (Extras) <MTProtocolCompare>

+ (id)getDocumentSectionForObjectID:(NSManagedObjectID *)objid fromObjectContext:(NSManagedObjectContext *)moc;
+ (MNSDocumentSectionType)getSectionTypeforRow:(NSInteger)row withNumberOfGroups:(NSInteger)numberOfGroups;
+ (RptqDocumentSection *)getDocumentSectionForRow:(NSInteger)row forQuery:(RptqQuery *)query;
+ (NSString *)getDocumentSectionNameForRow:(NSInteger)row withNumberOfGroups:(NSInteger)numberOfGroups;
+ (NSInteger)getDocumentSectionIndentLevelForRow:(NSInteger)row withNumberOfGroups:(NSInteger)numberOfGroups;
+ (NSInteger)getRowForSection:(RptqDocumentSection *)section inManagedObjectContext:(UIManagedDocumentReport *)managedDocument;

- (NSString *)localizedDisplayName;

- (void)addHasObjectsObjectFixed:(RptqDocumentObject *)value;
- (void)removeHasObjectsObjectFixed:(RptqDocumentObject *)value;

- (NSString *)sectionKey;

@end