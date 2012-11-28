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

//Do not change these enum values, as they are used in core data.
typedef enum {
	MNSDocumentSectionTypeReportHeader = 1,
	MNSDocumentSectionTypeReportFooter = 2,
	MNSDocumentSectionTypePageHeader = 3,
	MNSDocumentSectionTypePageFooter = 4,
    MNSDocumentSectionTypeBody = 5,
    MNSDocumentSectionTypeGroupHeader = 6,
    MNSDocumentSectionTypeGroupFooter = 7,
} MNSDocumentSectionType;

@interface RptqDocumentSection (Extras)

+ (RptqDocumentSection *)sectionForManagedObjectContext:(NSManagedObjectContext *)objectContext withObjectID:(NSManagedObjectID *)objid;
+ (MNSDocumentSectionType)getSectionTypeforRow:(NSInteger)row withNumberOfGroups:(NSInteger)numberOfGroups;
+ (RptqDocumentSection *)getDocumentSectionForRow:(NSInteger)row
                          forManagedObjectContext:(NSManagedObjectContext *)objectContext;
+ (NSString *)getDocumentSectionNameForRow:(NSInteger)row withNumberOfGroups:(NSInteger)numberOfGroups;
+ (NSInteger)getDocumentSectionIndentLevelForRow:(NSInteger)row withNumberOfGroups:(NSInteger)numberOfGroups;
+ (NSInteger)getRowForSection:(RptqDocumentSection *)section inManagedObjectContext:(UIManagedDocumentReport *)managedDocument;

- (NSString *)localizedDisplayName;

@end