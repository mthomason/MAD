//
//  MADQueryCacheSelectLimitOffsetParamaters.h
//  MAD
//
//  Created by Michael Thomason on 5/25/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MADQueryCacheSelectLimitOffsetParamaters_h
#define MADQueryCacheSelectLimitOffsetParamaters_h

typedef NS_ENUM(short, MADQueryCacheSelectLimitOffsetParamaters) {
	MADQueryCacheSelectLimitOffsetParamatersLimit,
	MADQueryCacheSelectLimitOffsetParamatersOffset,
	MADQueryCacheSelectLimitOffsetParamatersTableNames,
	MADQueryCacheSelectLimitOffsetParamatersColumnKeys,
	MADQueryCacheSelectLimitOffsetParamatersColumns,
	MADQueryCacheSelectLimitOffsetParamatersSortDesc,
	MADQueryCacheSelectLimitOffsetParamatersDropRowid
};

#endif /* MADQueryCacheSelectLimitOffsetParamaters_h */
