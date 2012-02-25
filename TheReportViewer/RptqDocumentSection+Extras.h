//
//  RptqDocumentSection+Extras.h
//  TheReportViewer
//
//  Created by Michael Thomason on 2/12/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "RptqDocumentSection.h"
#import "UIManagedDocumentQuery.h"

//Do not change these enum values, as they are used in core data.
typedef enum {
	MNSSectionTypeReportHeader = 1,
	MNSSectionTypeReportFooter = 2,
	MNSSectionTypePageHeader = 3,
	MNSSectionTypePageFooter = 4,
    MNSSectionTypeBody = 5,
    MNSSectionTypeGroupHeader = 6,
    MNSSectionTypeGroupFooter = 7,
} MNSSectionType;

@interface RptqDocumentSection (Extras)

+ (MNSSectionType)getSectionTypeforRow:(NSInteger)row withNumberOfGroups:(NSInteger)numberOfGroups;
+ (RptqDocumentSection *)getDocumentSectionForRow:(NSInteger)row
                          forManagedObjectContext:(NSManagedObjectContext *)objectContext;
+ (NSString *)getDocumentSectionNameForRow:(NSInteger)row withNumberOfGroups:(NSInteger)numberOfGroups;
+ (NSInteger)getDocumentSectionIndentLevelForRow:(NSInteger)row withNumberOfGroups:(NSInteger)numberOfGroups;
+ (NSInteger)numberOfGroupsForManagedObjectContext:(NSManagedObjectContext *)objectContext;
+ (NSInteger)getRowForSection:(RptqDocumentSection *)section inManagedObjectContext:(UIManagedDocumentQuery *)managedDocument;

@end