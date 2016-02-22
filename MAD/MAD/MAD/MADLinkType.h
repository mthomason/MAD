//
//  MADLinkType.h
//  MAD
//
//  Created by Michael Thomason on 9/28/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADLinkType_h
#define MAD_MADLinkType_h

typedef NS_ENUM(unsigned char, MNSLinkType) {
    MNSLinkTypeInnerJoin = 0,
    MNSLinkTypeEquiJoin = 1,
    MNSLinkTypeNaturalJoin = 2,
    MNSLinkTypeCrossJoin = 3,
    MNSLinkTypeLeftOuterJoin = 4,
    MNSLinkTypeRightOuterJoin = 5,
    MNSLinkTypeFullOuterJoin = 6,
    MNSLinkTypeUnknown = 7,
};

#endif
