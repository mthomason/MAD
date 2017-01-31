//
//  MADDocumentObjectType.h
//  MAD
//
//  Created by Michael Thomason on 9/28/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADDocumentObjectType_h
#define MAD_MADDocumentObjectType_h

#import <CoreFoundation/CFAvailability.h>

typedef CF_ENUM(int64_t, MTDocumentObjectType) {
    MTDocumentObjectTypeLabelDynamic = 0,
    MTDocumentObjectTypeLabelStatic = 1,
    MTDocumentObjectTypeImage = 2,
    MTDocumentObjectTypeChart = 3,
    MTDocumentObjectTypeFormula = 4,
    MTDocumentObjectTypeAggregate = 5,
    MTDocumentObjectTypeGroupKey = 6,
    MTDocumentObjectTypeAggregateFunctionList = 7,
    MTDocumentObjectTypeWhtiespace = 8,
    MTDocumentObjectTypeBarcode = 9,
    MTDocumentObjectTypeLabelLink = 10
};

#endif
