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
#import <CoreGraphics/CGGeometry.h>
#import "MADocumentSectionType.h"

typedef NS_ENUM(int16_t, RptqDocumentSectionWrappingStyle) {
    RptqDocumentSectionWrappingStyleStandard = 1,
    RptqDocumentSectionWrappingStyleNewPageAfter = 2,
};

@class RptqQuery;
@class RptqDocumentElement;
@class RptqDocumentSectionRows;
@class NSIndexPath;

@interface RptqDocumentSection (Extras)

    + (instancetype)newDocumentSectionWithIdentifier:(int64_t)identifier
                                   fromObjectContext:(NSManagedObjectContext *)context;

    + (instancetype)newDocumentSectionOfType:(MADDocumentSectionType)type
                     forManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

    + (instancetype)documentSectionForObjectID:(NSManagedObjectID *)objid
                        inManagedObjectContext:(NSManagedObjectContext *)moc;

    + (MADDocumentSectionType)getSectionTypeforRow:(NSUInteger)row
                                withNumberOfGroups:(NSUInteger)numberOfGroups;

    + (RptqDocumentSection *)groupHeaderForLevel:(NSUInteger)groupLevel query:(RptqQuery *)query;
    + (RptqDocumentSection *)groupFooterForLevel:(NSUInteger)groupLevel query:(RptqQuery *)query;
    + (MADDocumentSectionType)getSectionTypeforRow:(NSUInteger)row
                              withNumberOfSections:(NSUInteger)numberOfSections;
    + (RptqDocumentSection *)footerSectionInSections:(NSSet <RptqDocumentSection *> *)sections;
    + (RptqDocumentSection *)headerSectionInSections:(NSSet <RptqDocumentSection *> *)sections;

    - (MADDocumentSectionType)getDocumentSectionType;

    - (CGFloat)layoutHeightCalculated;

    - (NSString *)localizedDisplayName;

    - (BOOL)producesFormFeed;
    - (void)addHasRowsFixed:(RptqDocumentSectionRows *)value;
    - (void)removeHasRowsFixed:(RptqDocumentSectionRows *)value;
    - (void)addDocumentObject:(RptqDocumentElement *)documentObject withDropPoint:(CGPoint)origin
         managedObjectContext:(NSManagedObjectContext *)managedObjectContext;

    - (void)setInterfaceHeight:(double)height;
    - (void)setProducesFormFeed:(BOOL)producesFormFeed;

@end

#endif
