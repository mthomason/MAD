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
#import <CoreGraphics/CGBase.h>
#import <CoreGraphics/CGGeometry.h>
#import <MAD/MADDocumentSectionType.h>
#import <MADDataStructures/MTProtocolCompare.h>

typedef NS_ENUM(NSUInteger, RptqDocumentSectionWrappingStyle) {
    RptqDocumentSectionWrappingStyleStandard = 1,
    RptqDocumentSectionWrappingStyleNewPageAfter = 2,
};

@class RptqQuery, RptqDocumentObject, RptqDocumentSectionRows;
@class NSIndexPath;

@interface RptqDocumentSection (Extras) <MTProtocolCompare>

@property (nonatomic, retain, readonly) NSString *sectionKey;

+ (instancetype)documentSectionForObjectID:(NSManagedObjectID *)objid inManagedObjectContext:(NSManagedObjectContext *)moc;

+ (MNSDocumentSectionType)getSectionTypeforRow:(NSUInteger)row withNumberOfGroups:(NSUInteger)numberOfGroups;
+ (RptqDocumentSection *)groupHeaderForLevel:(NSUInteger)groupLevel query:(RptqQuery *)query;
+ (RptqDocumentSection *)groupFooterForLevel:(NSUInteger)groupLevel query:(RptqQuery *)query;

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
