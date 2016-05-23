//
//  MADQueryLinkType.h
//  MAD
//
//  Created by Michael Thomason on 5/23/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MADQueryLinkType_h
#define MADQueryLinkType_h

typedef NS_ENUM(short, MNSLinkType) {
    MNSLinkTypeInnerJoin = 0,
    MNSLinkTypeEquiJoin = 1,
    MNSLinkTypeNaturalJoin = 2,
    MNSLinkTypeCrossJoin = 3,
    MNSLinkTypeLeftOuterJoin = 4,
    MNSLinkTypeRightOuterJoin = 5,
    MNSLinkTypeFullOuterJoin = 6,
    MNSLinkTypeUnknown = 7,
};

#endif /* MADQueryLinkType_h */
