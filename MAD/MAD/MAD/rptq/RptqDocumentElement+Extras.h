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

    @property (readonly) MADPrintPageElementType documentObjectType;
    @property (readonly) CGRect frame;

    + (instancetype)newDocumentElementWithIdentifier:(int64_t)identifier
                                   fromObjectContext:(NSManagedObjectContext *)context;

    + (NSFetchRequest <__kindof RptqDocumentElement *> *)fetchRequestElement:(int64_t)identifier;
    + (NSFetchRequest <NSDictionary *> *)fetchRequestElementsInSection:(NSManagedObjectID *)sectionID;
    + (NSFetchRequest <NSDictionary *> *)fetchRequestSectionHeight:(NSManagedObjectID *)sectionID;

    + (void)removeDocumentObject:(RptqDocumentElement *)documentObject
               fromParentSection:(RptqDocumentSection *)section
               withLayoutManager:(MADSectionLayoutManager *)layoutManager;

    + (NSString *)keyBorderWidthTop;
    + (NSString *)keyBorderWidthBottom;
    + (NSString *)keyPaddingTop;
    + (NSString *)keyPaddingBottom;
    + (NSString *)keyMarginTop;
    + (NSString *)keyMarginBottom;
    + (NSString *)keyRectOriginY;
    + (NSString *)keyRectSizeHeight;
    + (NSString *)keyCalculatedHeight;

    - (CGSize)sizeCalculated;
    - (CGSize)sizeContentView;
    - (CGRect)boundsCalculated;
    - (CGRect)paddingViewFrame;
    - (CGRect)boundsContentView;
    - (CGRect)elementViewFrame;
    - (CGRect)elementViewFrameDesigner;
    - (CGRect)elementViewFrameDesignerFrameCalculated;
    - (CGRect)borderRect;
    - (CGRect)paddingRect;
    - (CGRect)innerRect;

    - (void)setOriginPoint:(CGPoint)origin;
    - (void)setSizeValue:(CGSize)size;
    - (void)setSizeWidth:(float)w height:(float)h;

    - (double)spacingLeft;
    - (double)spacingTop;
    - (double)spacingBottom;
    - (double)spacingRight;

    - (NSString *)designerRepresentationText;

    - (CGFloat)borderLineTopAX;
    - (CGFloat)borderLineTopAY;
    - (CGFloat)borderLineTopBX;
    - (CGFloat)borderLineTopBY;
    - (CGFloat)borderLineBottomAX;
    - (CGFloat)borderLineBottomAY;
    - (CGFloat)borderLineBottomBX;
    - (CGFloat)borderLineBottomBY;
    - (CGFloat)borderLineLeftAX;
    - (CGFloat)borderLineLeftAY;
    - (CGFloat)borderLineLeftBX;
    - (CGFloat)borderLineLeftBY;
    - (CGFloat)borderLineRightAX;
    - (CGFloat)borderLineRightAY;
    - (CGFloat)borderLineRightBX;
    - (CGFloat)borderLineRightBY;

    - (void)setSizeWidth:(float)width;
    - (void)setSizeHeight:(float)height;

    - (NSString *)formattedString:(MADDataType)dataType forValue:(id)value;

@end

#endif
