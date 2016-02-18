//
//  MADDocumentObjectType.h
//  MAD
//
//  Created by Michael Thomason on 9/28/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADDocumentObjectType_h
#define MAD_MADDocumentObjectType_h

typedef NS_ENUM(short, MTDocumentObjectType) {
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

extern NSString * const MADDocumentObjectTypeTitleDynamic;
extern NSString * const MADDocumentObjectTypeTitleStatic;
extern NSString * const MADDocumentObjectTypeTitleWhitespace;
extern NSString * const MADDocumentObjectTypeTitleAggregate;
extern NSString * const MADDocumentObjectTypeTitleImage;
extern NSString * const MADDocumentObjectTypeTitleBarcode;

extern NSString * const MADDocumentObjectTypeAddDetailDynamic;
extern NSString * const MADDocumentObjectTypeAddDetailStatic;
extern NSString * const MADDocumentObjectTypeAddDetailWhitespace;
extern NSString * const MADDocumentObjectTypeAddDetailAggregate;
extern NSString * const MADDocumentObjectTypeAddDetailImage;
extern NSString * const MADDocumentObjectTypeAddDetailBarcode;

@interface MADDocumentObjectType : NSObject

    + (NSString *)humanReadableStringForType:(MTDocumentObjectType)type;

    + (NSString *)localizedStringForType:(MTDocumentObjectType)type;
    + (NSString *)localizedDetailStringForType:(MTDocumentObjectType)type;
    + (NSString *)localizedAddDetailStringForType:(MTDocumentObjectType)type;

@end

#endif
