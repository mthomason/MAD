//
//  RptqDocumentObject+Extras.h
//  Reports
//
//  Created by Michael Thomason on 2/22/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_RptqDocumentObject_Extras_h
#define Reports_RptqDocumentObject_Extras_h

#import "RptqDocumentObject.h"
#import "MTProtocolCompare.h"
#import "MTProtocolLog.h"
#import "RptqDocumentObjectFactory.h"
#import "RptqDocument.h"
#import "MTFont.h"
#import "Constants.h"
#import "RptqDatabaseSchemaField.h"
#import "RptqQueryField+Extras.h"
#import "RptqDocumentObjectLabelDataField+Extras.h"
#import "RptqDocumentObjectLabel+Extras.h"
#import "RptqDocumentObjectLabelLink+Extras.h"
#import "RptqDocumentObjectAggregate+Extras.h"
#import "RptqDocumentObjectChart+Extras.h"
#import "RptqDocumentObjectGroupKey+Extras.h"
#import "RptqDocumentObjectImage+Extras.h"
#import "RptqDocumentObjectFormula+Extras.h"
#import "RptqDocumentObjectBarcode+Extras.h"
#import <CoreData/CoreData.h>

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

- (MTDocumentObjectType)getType;
- (CGSize)size;
- (NSString *)designerRepresentationText;
+ (void)removeDocumentObject:(RptqDocumentObject *)documentObject;
- (CGRect)paddingViewFrame;
- (CGRect)boundsContentView;
- (CGRect)elementViewFrame;
- (NSString *)formattedString:(MTDataType)dataType forValue:(id)value;
- (CGSize)sizeContentView;

@end

#endif
