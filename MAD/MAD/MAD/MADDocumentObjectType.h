//
//  MADDocumentObjectType.h
//  MAD
//
//  Created by Michael Thomason on 9/28/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_MADDocumentObjectType_h
#define MAD_MADDocumentObjectType_h

#import <CoreFoundation/CFAvailability.h>

typedef CF_ENUM(int64_t, MADPrintPageElementType) {
	MADPrintPageElementTypeLabelDynamic = 0,
	MADPrintPageElementTypeLabelStatic = 1,
	MADPrintPageElementTypeImage = 2,
	MADPrintPageElementTypeChart = 3,
	MADPrintPageElementTypeFormula = 4,
	MADPrintPageElementTypeAggregate = 5,
	MADPrintPageElementTypeGroupKey = 6,
	MADPrintPageElementTypeAggregateFunctionList = 7,
	MADPrintPageElementTypeWhtiespace = 8,
	MADPrintPageElementTypeBarcode = 9,
	MADPrintPageElementTypeLabelLink = 10
};

#endif
