//
//  RptqDocumentElement+Extras.h
//  Reports
//
//  Created by Michael Thomason on 2/22/12.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_RptqDocumentElement_Extras_h
#define Reports_RptqDocumentElement_Extras_h

#import <MAD/RptqDocumentElement.h>

#import <CoreGraphics/CGGeometry.h>

#import <MADDataStructures/MTProtocolLog.h>

#import <MADFoundation/MADDataType.h>

#import <MAD/RptqDocumentElementFactory.h>
#import <MAD/MADDocumentObjectType.h>

extern NSString * const MTDocumentObjectDefinationType;
extern NSString * const MTDocumentObjectDefinationObject;

extern NSString * const MTDocumentObjectDefinationAggregateType;
extern NSString * const MTDocumentObjectDefinationAggregatePivotNumber;
extern NSString * const MTDocumentObjectDefinationAggregatePivotType;
extern NSString * const MTDocumentObjectDefinationAggregateObjectId;
extern NSString * const MTDocumentObjectDefinationAggregateFunctionInputType;
extern NSString * const MTDocumentObjectDefinationField1;
extern NSString * const MTDocumentObjectDefinationField2;

@class MADSectionLayoutManager, UIFontDescriptor, RptqDocumentSection;

@interface RptqDocumentElement (Extras)
    <MTProtocolLog, RptqDocumentElementFactory>

    + (instancetype)newDocumentElementWithIdentifier:(int64_t)identifier
                                   fromObjectContext:(NSManagedObjectContext *)context;
    + (NSFetchRequest <__kindof RptqDocumentElement *> *)fetchRequestElement:(int64_t)identifier;
    + (void)removeDocumentObject:(RptqDocumentElement *)documentObject
               fromParentSection:(RptqDocumentSection *)section
               withLayoutManager:(MADSectionLayoutManager *)layoutManager;

    @property (readonly) MTDocumentObjectType documentObjectType;
    @property (readonly) CGRect frame;
    
    - (CGSize)sizeCalculated;
    - (NSString *)designerRepresentationText;
    - (CGRect)paddingViewFrame;
    - (CGRect)boundsContentView;
    - (CGRect)elementViewFrame;
    - (CGRect)elementViewFrameDesigner;

    - (void)setSizeWidth:(double)width;
    - (void)setSizeHeight:(double)height;

    - (NSString *)formattedString:(MADDataType)dataType forValue:(id)value;

    - (CGSize)sizeContentView;
    - (void)setOriginPoint:(CGPoint)origin;
    - (void)setSizeValue:(CGSize)size;
    - (void)setSizeWidth:(double)w height:(double)h;

    - (void)dropAtRect:(CGRect)rect;

    - (double)spacingLeft;
    - (double)spacingTop;
    - (double)spacingBottom;
    - (double)spacingRight;

@end

#endif
