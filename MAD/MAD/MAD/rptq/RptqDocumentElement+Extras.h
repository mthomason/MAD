//
//  RptqDocumentElement+Extras.h
//  Reports
//
//  Created by Michael Thomason on 2/22/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_RptqDocumentElement_Extras_h
#define Reports_RptqDocumentElement_Extras_h

#import <MAD/RptqDocumentElement+CoreDataClass.h>
#import <CoreGraphics/CGGeometry.h>
#import <MADDataStructures/MTProtocolLog.h>
#import <MAD/RptqDocumentElementFactory.h>
#import <MADFoundation/MADDataType.h>
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
    
    - (CGSize)size;
    - (NSString *)copyDesignerRepresentationText;
    - (CGRect)paddingViewFrame;
    - (CGRect)boundsContentView;
    - (CGRect)elementViewFrame;
    - (CGRect)elementViewFrameDesigner;

    - (NSString *)formattedString:(MADDataType)dataType forValue:(id)value;

    - (CGSize)sizeContentView;
    - (void)setOrigin:(CGPoint)origin;
    - (void)dropAtRect:(CGRect)rect;

    - (CGFloat)spacingLeft;
    - (CGFloat)spacingTop;
    - (CGFloat)spacingBottom;
    - (CGFloat)spacingRight;

@end

#endif
