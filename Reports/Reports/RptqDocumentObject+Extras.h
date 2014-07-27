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
#import "MTProtocolCompare.h"
#import "MTProtocolLog.h"
#import "RptqDocumentObjectFactory.h"
#import "MTDatabaseField.h"

typedef NS_ENUM(NSUInteger, MTDocumentObjectType) {
	MTDocumentObjectTypeLabelDynamic = 0,
	MTDocumentObjectTypeLabelStatic = 1,
	MTDocumentObjectTypeImage = 2,
    MTDocumentObjectTypeChart = 3,
    MTDocumentObjectTypeFormula = 4,
    MTDocumentObjectTypeAggregate = 5,
    MTDocumentObjectTypeGroupKey = 6,
    MTDocumentObjectTypeAggregateFunctionList = 7,
    MTDocumentObjectTypeWhtiespace = 8,
    MTDocumentObjectTypeBarcode = 9
};

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

+ (void)removeDocumentObject:(RptqDocumentObject *)documentObject;
+ (instancetype)documentObjectForObject:(NSManagedObject *)managedObject;

- (MTDocumentObjectType)getType;
- (CGSize)size;
- (NSString *)designerRepresentationText;
- (CGRect)paddingViewFrame;
- (CGRect)boundsContentView;
- (CGRect)elementViewFrame;
- (NSString *)formattedString:(MTDataType)dataType forValue:(id)value;
- (CGSize)sizeContentView;
- (CGPoint)dropPoint;
- (void)setDropPoint:(CGPoint)dropPoint;
- (void)setOrigin:(CGPoint)origin;

- (NSDictionary *)attributesForDrawingText;

@end

#endif
