//
//  MADQueryLinkType.h
//  MAD
//
//  Created by Michael Thomason on 5/23/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_MADQueryLinkType_h
#define MAD_MADQueryLinkType_h

typedef NS_ENUM(int16_t, MADLinkType) {
	MADLinkTypeInnerJoin = 0,
	MADLinkTypeEquiJoin = 1,
	MADLinkTypeNaturalJoin = 2,
	MADLinkTypeCrossJoin = 3,
	MADLinkTypeLeftOuterJoin = 4,
	MADLinkTypeRightOuterJoin = 5,
	MADLinkTypeFullOuterJoin = 6,
	MADLinkTypeUnknown = 7,
};

#endif /* MADQueryLinkType_h */
