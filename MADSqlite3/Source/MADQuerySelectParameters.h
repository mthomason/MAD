//
//  MADQuerySelectParameters.h
//  MAD
//
//  Created by Michael Thomason on 5/25/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MADQuerySelectParameters_h
#define MADQuerySelectParameters_h

typedef NS_ENUM(short, MADQuerySelectParameters) {
	MADQuerySelectConnection,
	MADQuerySelectTableName,
	MADQuerySelectFieldKeys,
	MADQuerySelectFieldDescriptors,
	MADQuerySelectLimit,
	MADQuerySelectOffset,
	MADQuerySelectSortDescriptors,
	MADQuerySelectPredicates,
	MADQuerySelectRowId,
	MADQuerySelectRowIds,
	MADQuerySelectSortAccending,
	MADQuerySelectColumns
};

#endif /* MADQuerySelectParameters_h */
