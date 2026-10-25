//
//  MADDataType.h
//  MAD
//
//  Created by Michael Thomason on 9/28/14.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_MADFoundation_MADDataType_h
#define MAD_MADFoundation_MADDataType_h

#import <Foundation/NSObjCRuntime.h>

typedef NS_ENUM(int16_t, MADDataType) {
	MADDataTypeBit           = 0,
	MADDataTypeBlob          = 1,
	MADDataTypeDate          = 2,
	MADDataTypeDateTime      = 3,
	MADDataTypeFloat         = 5,
	MADDataTypeGeometry      = 6,
	MADDataTypeImage         = 7,
	MADDataTypeInteger       = 8,
	MADDataTypeNumber        = 9,
	MADDataTypeSet           = 10,
	MADDataTypeString        = 11,
	MADDataTypeTime          = 12,
	MADDataTypeTimeStamp     = 13,
	MADDataTypeYear          = 14,
	MADDataTypeUnknown       = 15,
	MADDataTypeDecimal       = 16,
	MADDataTypeDouble        = 17,
	MADDataTypeEnum          = 18,
	MADDataTypeInt24         = 19,
	MADDataTypeLong          = 20,
	MADDataTypeLongLong      = 21,
	MADDataTypeVarChar       = 22,
	MADDataTypeShort         = 23,
	MADDataTypeNull          = 24
};

static inline NSString *NSStringFromMADDataType(MADDataType);
static inline NSString *NSStringFromMADDataType(MADDataType type) {
	switch (type) {
		case MADDataTypeBit: return @"MADDataTypeBit";
		case MADDataTypeBlob: return @"MADDataTypeBlob";
		case MADDataTypeDate: return @"MADDataTypeDate";
		case MADDataTypeDateTime: return @"MADDataTypeDateTime";
		case MADDataTypeFloat: return @"MADDataTypeFloat";
		case MADDataTypeGeometry: return @"MADDataTypeGeometry";
		case MADDataTypeImage: return @"MADDataTypeImage";
		case MADDataTypeInteger: return @"MADDataTypeInteger";
		case MADDataTypeNumber: return @"MADDataTypeNumber";
		case MADDataTypeSet: return @"MADDataTypeSet";
		case MADDataTypeString: return @"MADDataTypeString";
		case MADDataTypeTime: return @"MADDataTypeTime";
		case MADDataTypeTimeStamp: return @"MADDataTypeTimeStamp";
		case MADDataTypeYear: return @"MADDataTypeYear";
		case MADDataTypeUnknown: return @"MADDataTypeUnknown";
		case MADDataTypeDecimal: return @"MADDataTypeDecimal";
		case MADDataTypeDouble: return @"MADDataTypeDouble";
		case MADDataTypeEnum: return @"MADDataTypeEnum";
		case MADDataTypeInt24: return @"MADDataTypeInt24";
		case MADDataTypeLong: return @"MADDataTypeLong";
		case MADDataTypeLongLong: return @"MADDataTypeLongLong";
		case MADDataTypeVarChar: return @"MADDataTypeVarChar";
		case MADDataTypeShort: return @"MADDataTypeShort";
		case MADDataTypeNull: return @"MADDataTypeNull";
		default: return @"Unknown";
	}
}

SEL MADDataTypeSelectorForSorting(MADDataType dataType);

#endif

