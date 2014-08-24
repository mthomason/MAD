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

typedef NS_ENUM(NSUInteger, RptqDocumentSectionWrappingStyle) {
    RptqDocumentSectionWrappingStyleStandard = 1,
    RptqDocumentSectionWrappingStyleNewPageAfter = 2,
};

@class RptqQuery, RptqDocumentObject, RptqDocumentSectionRows;

@interface RptqDocumentSection (Extras) <MTProtocolCompare>

@property (nonatomic, retain, readonly) NSString *sectionKey;

+ (instancetype)documentSectionForObjectID:(NSManagedObjectID *)objid inManagedObjectContext:(NSManagedObjectContext *)moc;

+ (instancetype)documentSectionForRow:(NSInteger)row query:(RptqQuery *)query;
+ (instancetype)groupHeaderForLevel:(NSUInteger)groupLevel query:(RptqQuery *)query;
+ (instancetype)groupFooterForLevel:(NSUInteger)groupLevel query:(RptqQuery *)query;

- (CGFloat)layoutHeightCalculated;
- (NSString *)localizedDisplayName;
- (NSString *)sectionKey;
- (void)addHasRowsFixed:(RptqDocumentSectionRows *)value;
- (void)removeHasRowsFixed:(RptqDocumentSectionRows *)value;
- (NSIndexPath *)addDocumentObject:(RptqDocumentObject *)documentObject withDropPoint:(CGPoint)origin;
- (void)setInterfaceHeight:(CGFloat)height;
- (MNSDocumentSectionType)getDocumentSectionType;
- (NSUInteger)nextDropIndexForSection;
- (BOOL)producesFormFeed;
- (void)setProducesFormFeed:(BOOL)producesFormFeed;

@end

#endif
