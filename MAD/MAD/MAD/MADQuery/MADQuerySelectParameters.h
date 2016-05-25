//
//  MTQuerySelectParameters.h
//  MAD
//
//  Created by Michael Thomason on 5/25/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MTQuerySelectParameters_h
#define MTQuerySelectParameters_h

typedef NS_ENUM(short, MTQuerySelectParameters) {
    MTQuerySelectConnection,
    MTQuerySelectTableName,
    MTQuerySelectFieldKeys,
    MTQuerySelectFieldDescriptors,
    MTQuerySelectLimit,
    MTQuerySelectOffset,
    MTQuerySelectSortDescriptors,
    MTQuerySelectPredicates,
    MTQuerySelectRowId,
    MTQuerySelectRowIds,
    MTQuerySelectSortAccending,
    MTQuerySelectColumns
};

#endif /* MTQuerySelectParameters_h */
