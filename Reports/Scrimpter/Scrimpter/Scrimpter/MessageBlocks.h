//
//  MessageBlocks.h
//  Scrimpter
//
//  Created by Michael Thomason on 2014-06-16.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

typedef NS_ENUM(NSInteger, SCCompareson) {
    SCComparesonGreaterThan,
    SCComparesonLessThan,
    SCComparesonEqualTo,
    SCComparesonNotEqualTo,
    SCComparesonGreatThanOrEqualTo,
    SCComparesonLessThanOrEqualTo,
};

extern id (^ScrimptData)(NSString *key);
extern void (^Scrimpted)(BOOL success, id result, NSError *error);
