//
//  RptqDocumentElement+Extras.h
//  Reports
//
//  Created by Michael Thomason on 2/22/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_RptqDocumentElement_Extras_h
#define Reports_RptqDocumentElement_Extras_h

#import <MAD/RptqDocumentElement.h>

#import <CoreGraphics/CGGeometry.h>

#import <MADDataStructures/MTProtocolLog.h>

#import <MADFoundation/MADDataType.h>

#import <MAD/RptqDocumentElementFactory.h>
#import <MAD/MADDocumentObjectType.h>
#import <MAD/MTAlignment.h>

extern NSString * const MTDocumentObjectDefinationType;
extern NSString * const MTDocumentObjectDefinationObject;

extern NSString * const MTDocumentObjectDefinationAggregateType;
extern NSString * const MTDocumentObjectDefinationAggregatePivotNumber;
extern NSString * const MTDocumentObjectDefinationAggregatePivotType;
extern NSString * const MTDocumentObjectDefinationAggregateObjectId;
extern NSString * const MTDocumentObjectDefinationAggregateFunctionInputType;
extern NSString * const MTDocumentObjectDefinationField1;
extern NSString * const MTDocumentObjectDefinationField2;

@class MADSectionLayoutManager;
@class UIFontDescriptor;
@class RptqDocumentSection;

@interface RptqDocumentElement (Extras)
    <MTProtocolLog, RptqDocumentElementFactory>

    + (instancetype)documentObjectForObject:(NSManagedObject *)managedObject;

    + (void)removeDocumentObject:(RptqDocumentElement *)documentObject
               fromParentSection:(RptqDocumentSection *)section
               withLayoutManager:(MADSectionLayoutManager *)layoutManager;

    @property (readonly) MTDocumentObjectType documentObjectType;
    @property (readonly) CGRect frame;
    
    - (CGSize)sizeCalculated;
    - (NSString *)copyDesignerRepresentationText;
    - (CGRect)paddingViewFrame;
    - (CGRect)boundsContentView;
    - (CGRect)elementViewFrame;
    - (CGRect)elementViewFrameDesigner;

    - (void)setBold:(BOOL)bold;
    - (void)setItalic:(BOOL)italic;
    - (void)setStrikethrough:(BOOL)strikethrough;
    - (void)setUnderline:(BOOL)underline;

    - (void)setSizeWidth:(double)width;
    - (void)setSizeHeight:(double)height;

    - (void)setHorizontalAlignment:(MADHorizontalAlignment)alignment;
    - (void)setVerticalAlignment:(MADVerticalAlignment)alignment;

    - (void)setPaddingTop:(double)v;
    - (void)setPaddingBottom:(double)v;
    - (void)setPaddingLeft:(double)v;
    - (void)setPaddingRight:(double)v;
    - (void)setMarginTop:(double)v;
    - (void)setMarginBottom:(double)v;
    - (void)setMarginRight:(double)v;
    - (void)setMarginLeft:(double)v;

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
