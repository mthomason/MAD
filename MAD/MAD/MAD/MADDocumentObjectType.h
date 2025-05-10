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

static inline NSString *NSStringFromMADPrintPageElementType(MADPrintPageElementType);
static inline NSString *NSStringFromMADPrintPageElementType(MADPrintPageElementType value) {
	switch (value) {
		case MADPrintPageElementTypeLabelDynamic: return @"MADPrintPageElementTypeLabelDynamic";
		case MADPrintPageElementTypeLabelStatic: return @"MADPrintPageElementTypeLabelStatic";
		case MADPrintPageElementTypeImage: return @"MADPrintPageElementTypeImage";
		case MADPrintPageElementTypeChart: return @"MADPrintPageElementTypeChart";
		case MADPrintPageElementTypeFormula: return @"MADPrintPageElementTypeFormula";
		case MADPrintPageElementTypeAggregate: return @"MADPrintPageElementTypeAggregate";
		case MADPrintPageElementTypeGroupKey: return @"MADPrintPageElementTypeGroupKey";
		case MADPrintPageElementTypeAggregateFunctionList: return @"MADPrintPageElementTypeAggregateFunctionList";
		case MADPrintPageElementTypeWhtiespace: return @"MADPrintPageElementTypeWhtiespace";
		case MADPrintPageElementTypeBarcode: return @"MADPrintPageElementTypeBarcode";
		case MADPrintPageElementTypeLabelLink: return @"MADPrintPageElementTypeLabelLink";
		default: return @"Unknown";
	}
}

#endif
