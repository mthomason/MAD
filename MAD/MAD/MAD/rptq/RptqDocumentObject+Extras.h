//
//  RptqDocumentObject+Extras.h
//  Reports
//
//  Created by Michael Thomason on 2/22/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_RptqDocumentObject_Extras_h
#define Reports_RptqDocumentObject_Extras_h

#import "RptqDocumentObject.h"
#import "RptqDocumentObjectFactory.h"
#import <MAD/MADDocumentObjectType.h>
#import <MADFoundation/MADDataType.h>
#import <MADDataStructures/MTProtocolLog.h>
#import <Foundation/NSObject.h>
#import <CoreGraphics/CGGeometry.h>


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

@interface RptqDocumentObject (Extras) <MTProtocolLog, RptqDocumentObjectFactory>

    + (instancetype)documentObjectForObject:(NSManagedObject *)managedObject;

    + (void)removeDocumentObject:(RptqDocumentObject *)documentObject fromParentSection:(RptqDocumentSection *)section
               withLayoutManager:(MADSectionLayoutManager *)layoutManager;

    @property (readonly) MTDocumentObjectType getType;
    @property (readonly) CGRect frame;
    
    - (CGSize)size;
    - (NSString *)designerRepresentationText;
    - (CGRect)paddingViewFrame;
    - (CGRect)boundsContentView;
    - (CGRect)elementViewFrame;
    - (NSString *)formattedString:(MTDataType)dataType forValue:(id)value;
    - (CGSize)sizeContentView;
    - (void)setOrigin:(CGPoint)origin;
    - (void)dropAtRect:(CGRect)rect;

    - (CGFloat)spacingLeft;
    - (CGFloat)spacingTop;
    - (CGFloat)spacingBottom;
    - (CGFloat)spacingRight;

    - (NSDictionary *)attributesForDrawingText;

@end

#endif
