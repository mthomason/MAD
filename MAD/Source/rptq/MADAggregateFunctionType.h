//
//  MADAggregateFunctionType.h
//  MAD
//
//  Created by Michael Thomason on 5/23/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MADAggregateFunctionType_h
#define MADAggregateFunctionType_h

#import <CoreFoundation/CFAvailability.h>

typedef CF_ENUM(int16_t, MTAggregateFunctionType) {
	MTAggregateFunctionTypeUnknown = 0,
	MTAggregateFunctionTypeSum = 2,
	MTAggregateFunctionTypeMean = 3,
	MTAggregateFunctionTypeFirst = 5,
	MTAggregateFunctionTypeLast = 7,
	MTAggregateFunctionTypeCount = 11,
	MTAggregateFunctionTypeMin = 13,
	MTAggregateFunctionTypeMax = 17,
	MTAggregateFunctionTypeNotSet = 55,
};

static inline NSString *NSStringFromMADAggregateFunctionType(MTAggregateFunctionType);
static inline NSString *NSStringFromMADAggregateFunctionType(MTAggregateFunctionType value) {
	switch (value) {
		case MTAggregateFunctionTypeSum: return @"MTAggregateFunctionTypeSum";
		case MTAggregateFunctionTypeMean: return @"MTAggregateFunctionTypeMean";
		case MTAggregateFunctionTypeFirst: return @"MTAggregateFunctionTypeFirst";
		case MTAggregateFunctionTypeLast: return @"MTAggregateFunctionTypeLast";
		case MTAggregateFunctionTypeCount: return @"MTAggregateFunctionTypeCount";
		case MTAggregateFunctionTypeMin: return @"MTAggregateFunctionTypeMin";
		case MTAggregateFunctionTypeMax: return @"MTAggregateFunctionTypeMax";
		case MTAggregateFunctionTypeNotSet: return @"MTAggregateFunctionTypeNotSet";
		case MTAggregateFunctionTypeUnknown: default: return @"MTAggregateFunctionTypeUnknown";
	}
}


#endif /* MADAggregateFunctionType_h */
