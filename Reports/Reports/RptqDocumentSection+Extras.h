//
//  RptqDocumentSection+Extras.h
//  Reports
//
//  Created by Michael Thomason on 2/12/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_RptqDocumentSection_Extras_h
#define Reports_RptqDocumentSection_Extras_h

#import "RptqDocumentSection.h"
#import "MTProtocolCompare.h"

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

@class RptqQuery, RptqDocumentObject, RptqDocumentSectionRows;

@interface RptqDocumentSection (Extras) <MTProtocolCompare>

+ (id)getDocumentSectionForObjectID:(NSManagedObjectID *)objid fromObjectContext:(NSManagedObjectContext *)moc;
+ (MNSDocumentSectionType)getSectionTypeforRow:(NSInteger)row withNumberOfGroups:(NSInteger)numberOfGroups;
+ (RptqDocumentSection *)getDocumentSectionForRow:(NSInteger)row forQuery:(RptqQuery *)query;
+ (NSString *)getDocumentSectionNameForRow:(NSInteger)row withNumberOfGroups:(NSInteger)numberOfGroups;
+ (NSInteger)getDocumentSectionIndentLevelForRow:(NSInteger)row withNumberOfGroups:(NSInteger)numberOfGroups;
+ (NSInteger)getRowForSection:(RptqDocumentSection *)section;

+ (RptqDocumentSection *)getDocumentGroupHeaderAtLevel:(NSUInteger)groupLevel forQuery:(RptqQuery *)query;
+ (RptqDocumentSection *)getDocumentGroupFooterAtLevel:(NSUInteger)groupLevel forQuery:(RptqQuery *)query;

// (RptqDocumentSection *)

+ (void)setHeight:(CGFloat)height forSectionAtRow:(NSUInteger)sectionRow inDocument:(RptqDocument *)document;
+ (void)setVisibility:(BOOL)isVisible forSectionAtRow:(NSUInteger)sectionRow inDocument:(RptqDocument *)document;
+ (void)setNumberOfRows:(NSUInteger)numberOfRows forSectionAtRow:(NSUInteger)sectionRow inDocument:(RptqDocument *)document;

+ (void)batchUpdateSectionLayoutHeights:(RptqDocument *)document;
+ (CGFloat)layoutHeightForSection:(RptqDocumentSection *)section;

- (NSString *)localizedDisplayName;
- (NSString *)sectionKey;

- (void)addHasRowsFixed:(RptqDocumentSectionRows *)value;
- (void)removeHasRowsFixed:(RptqDocumentSectionRows *)value;
- (NSIndexPath *)addDocumentObject:(RptqDocumentObject *)documentObject
                     withDropPoint:(CGPoint)origin;
- (void)setInterfaceHeight:(CGFloat)height;
- (MNSDocumentSectionType)getDocumentSectionType;
- (NSUInteger)nextDropIndexForSection;

@end

#endif
