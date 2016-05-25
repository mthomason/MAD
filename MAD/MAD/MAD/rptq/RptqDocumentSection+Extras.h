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
#import <MAD/MADReportSectionRepresentation.h>

typedef NS_ENUM(short, RptqDocumentSectionWrappingStyle) {
    RptqDocumentSectionWrappingStyleStandard = 1,
    RptqDocumentSectionWrappingStyleNewPageAfter = 2,
};

@class RptqQuery;
@class RptqDocumentObject;
@class RptqDocumentSectionRows;
@class NSIndexPath;

@interface RptqDocumentSection (Extras)

    - (NSManagedObjectID *)copySectionKey;

    + (instancetype)newDocumentSectionOfType:(MNSDocumentSectionType)type forManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

    + (instancetype)documentSectionForObjectID:(NSManagedObjectID *)objid inManagedObjectContext:(NSManagedObjectContext *)moc;

    + (MNSDocumentSectionType)getSectionTypeforRow:(NSUInteger)row withNumberOfGroups:(NSUInteger)numberOfGroups;
    + (RptqDocumentSection *)groupHeaderForLevel:(NSUInteger)groupLevel query:(RptqQuery *)query;
    + (RptqDocumentSection *)groupFooterForLevel:(NSUInteger)groupLevel query:(RptqQuery *)query;

    - (CGFloat)layoutHeightCalculated;
    - (NSString *)localizedDisplayName;
    - (void)addHasRowsFixed:(RptqDocumentSectionRows *)value;
    - (void)removeHasRowsFixed:(RptqDocumentSectionRows *)value;
    - (void)addDocumentObject:(RptqDocumentObject *)documentObject withDropPoint:(CGPoint)origin
         managedObjectContext:(NSManagedObjectContext *)managedObjectContext;
    - (void)setInterfaceHeight:(CGFloat)height;
    - (MNSDocumentSectionType)getDocumentSectionType;
    - (BOOL)producesFormFeed;
    - (void)setProducesFormFeed:(BOOL)producesFormFeed;

@end

#endif
