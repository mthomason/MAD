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
#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import <MADDataStructures/MADDataStructures.h>
#import <MADFoundation/MADDataType.h>
#import <MAD/MAD.h>
#import <MAD/MADFont.h>
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

@interface RptqDocumentObject (Extras) <MTProtocolCompare, MTProtocolLog, RptqDocumentObjectFactory>

+ (instancetype)documentObjectForObject:(NSManagedObject *)managedObject;

+ (void)removeDocumentObject:(RptqDocumentObject *)documentObject;

@property (readonly) MTDocumentObjectType getType;

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
