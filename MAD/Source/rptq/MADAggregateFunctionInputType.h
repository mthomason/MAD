//
//  MADAggregateFunctionInputType.h
//  MAD
//
//  Created by Michael Thomason on 5/23/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MADAggregateFunctionInputType_h
#define MADAggregateFunctionInputType_h

#import <stdint.h>
#import <CoreFoundation/CFAvailability.h>
#import <Foundation/NSString.h>

typedef CF_ENUM(short, MTAggregateFunctionInputType) {
	MTAggregateFunctionInputTypeField = 0,
	MTAggregateFunctionInputTypeFormula
};

#endif /* MADAggregateFunctionInputType_h */
