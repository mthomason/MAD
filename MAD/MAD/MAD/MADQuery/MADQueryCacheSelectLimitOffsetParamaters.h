//
//  MADQueryCacheSelectLimitOffsetParamaters.h
//  MAD
//
//  Created by Michael Thomason on 5/25/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MADQueryCacheSelectLimitOffsetParamaters_h
#define MADQueryCacheSelectLimitOffsetParamaters_h

typedef NS_ENUM(short, MTQueryCacheSelectLimitOffsetParamaters) {
    MTQueryCacheSelectLimitOffsetParamatersLimit,
    MTQueryCacheSelectLimitOffsetParamatersOffset,
    MTQueryCacheSelectLimitOffsetParamatersTableNames,
    MTQueryCacheSelectLimitOffsetParamatersColumnKeys,
    MTQueryCacheSelectLimitOffsetParamatersColumns,
    MTQueryCacheSelectLimitOffsetParamatersSortDesc,
    MTQueryCacheSelectLimitOffsetParamatersWhere,
    MTQueryCacheSelectLimitOffsetParamatersDropRowid
};

#endif /* MADQueryCacheSelectLimitOffsetParamaters_h */
