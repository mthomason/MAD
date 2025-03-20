//
//  MADDataType.h
//  MAD
//
//  Created by Michael Thomason on 9/28/14.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_MADFoundation_MADDataType_h
#define MAD_MADFoundation_MADDataType_h

#import <Foundation/Foundation.h>

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


SEL MADDataTypeSelectorForSorting(MADDataType dataType);

#endif

