//
//  MADAggregateFunctionGroupByType.h
//  MAD
//
//  Created by Michael Thomason on 5/23/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MADAggregateFunctionGroupByType_h
#define MADAggregateFunctionGroupByType_h

#import <stdint.h>
#import <CoreFoundation/CFAvailability.h>
#import <Foundation/NSString.h>

typedef CF_ENUM(int16_t, MTAggregateGroupByType) {
	MTAggregateGroupByUnknown = 0,
	MTAggregateGroupByTypePage = 2,
	MTAggregateGroupByTypeReport = 3,
	MTAggregateGroupByTypeSection = 5,
};

static inline NSString *NSStringFromMADAggregateGroupByType(MTAggregateGroupByType);
static inline NSString *NSStringFromMADAggregateGroupByType(MTAggregateGroupByType value) {
	switch (value) {
		case MTAggregateGroupByTypePage: return @"MTAggregateGroupByTypePage";
		case MTAggregateGroupByTypeReport: return @"MTAggregateGroupByTypeReport";
		case MTAggregateGroupByTypeSection: return @"MTAggregateGroupByTypeSection";
		case MTAggregateGroupByUnknown: default: return @"MTAggregateGroupByUnknown";
	}
}

#endif /* MADAggregateFunctionGroupByType_h */
