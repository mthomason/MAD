//
//  MTAggregateFunctionType.h
//  MAD
//
//  Created by Michael Thomason on 9/28/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MTAggregateFunctionType_h
#define MAD_MTAggregateFunctionType_h

typedef NS_ENUM(NSUInteger, MTAggregateFunctionType) {
    MTAggregateFunctionTypeSum = 2,
    MTAggregateFunctionTypeMean = 3,
    MTAggregateFunctionTypeFirst = 5,
    MTAggregateFunctionTypeLast = 7,
    MTAggregateFunctionTypeCount = 11,
    MTAggregateFunctionTypeMin = 13,
    MTAggregateFunctionTypeMax = 17,
    MTAggregateFunctionTypeNotSet = 55,
};

#endif
