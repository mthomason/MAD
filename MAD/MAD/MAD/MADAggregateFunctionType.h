//
//  MADAggregateFunctionType.h
//  MAD
//
//  Created by Michael Thomason on 5/23/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MADAggregateFunctionType_h
#define MADAggregateFunctionType_h

#import <CoreFoundation/CFAvailability.h>

typedef CF_ENUM(NSUInteger, MTAggregateFunctionType) {
    MTAggregateFunctionTypeSum = 2,
    MTAggregateFunctionTypeMean = 3,
    MTAggregateFunctionTypeFirst = 5,
    MTAggregateFunctionTypeLast = 7,
    MTAggregateFunctionTypeCount = 11,
    MTAggregateFunctionTypeMin = 13,
    MTAggregateFunctionTypeMax = 17,
    MTAggregateFunctionTypeNotSet = 55,
};

#endif /* MADAggregateFunctionType_h */
