//
//  RptqQueryLinks+Extras.h
//  Reports
//
//  Created by Michael Thomason on 3/13/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_RptqQueryLinks_Extras_h
#define Reports_RptqQueryLinks_Extras_h

#import "RptqQueryLinks.h"
#import <MADDataStructures/MADDataStructures.h>

extern NSString * const MNSJoinTypeInnerJoin;
extern NSString * const MNSJoinTypeEquiJoin;
extern NSString * const MNSJoinTypeNaturalJoin;
extern NSString * const MNSJoinTypeCrossJoin;
extern NSString * const MNSJoinTypeLeftOuterJoin;
extern NSString * const MNSJoinTypeRightOuterJoin;
extern NSString * const MNSJoinTypeFullOuterJoin;

extern NSString * const MTLinkTypeNameInnerJoin;
extern NSString * const MTLinkTypeNameEquiJoin;
extern NSString * const MTLinkTypeNameNaturalJoin;
extern NSString * const MTLinkTypeNameCrossJoin;
extern NSString * const MTLinkTypeNameLeftOuterJoin;
extern NSString * const MTLinkTypeNameRightOuterJoin;
extern NSString * const MTLinkTypeNameFullOuterJoin;

extern NSString * const MTLinkSqlInnerJoin;
extern NSString * const MTLinkSqlEquiJoin;
extern NSString * const MTLinkSqlNaturalJoin;
extern NSString * const MTLinkSqlCrossJoin;
extern NSString * const MTLinkSqlLeftOuterJoin;
extern NSString * const MTLinkSqlRightOuterJoin;
extern NSString * const MTLinkSqlFullOuterJoin;

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

//#define MNSLinkTypeSymbols [NSArray arrayWithObjects: NSLocalizedString(/*@"⟕"*/@"", @"Inner-Join"), NSLocalizedString(/*@"θ-join"*/@"", @"Equi-Join"), NSLocalizedString(/*@"⋈"*/@"", @"Natural Join"), NSLocalizedString(/*@"Cross Join"*/@"", @"Cross Join"), NSLocalizedString(/*@"⟕"*/@"", @"Left Outer Join"), NSLocalizedString(/*@"⟖"*/, @"Right Outer Join"), NSLocalizedString(/*@"⟗"*/, @"Full Outer Join"), nil]

//#define MNSLinkTypeSymbolsDesired [NSArray arrayWithObjects: NSLocalizedString(@"⟕", @"Inner-Join"), NSLocalizedString(@"θ-join", @"Equi-Join"), NSLocalizedString(@"⋈", @"Natural Join"), NSLocalizedString(@"Cross Join", @"Cross Join"), NSLocalizedString(@"⟕", @"Left Outer Join"), NSLocalizedString(@"⟖", @"Right Outer Join"), NSLocalizedString(@"⟗", @"Full Outer Join"), nil]

@class RptqDocument, RptqQueryLinks;

@interface RptqQueryLinks (Extras) <MTProtocolCompare, MTProtocolLog>

+ (instancetype)queryLinkFactoryWithLeftField:(RptqQueryField *)fieldLeft
                                   rightField:(RptqQueryField *)fieldRight
                                     joinType:(MNSLinkType)joinType NS_RETURNS_RETAINED;

- (NSString *)linkDescription;

+ (NSString *)ReuseIdForLinkType:(MNSLinkType)type;
+ (NSString *)LocalizedNamesForLinkType:(MNSLinkType)type;
+ (NSString *)SqlForLinkType:(MNSLinkType)type;

@end

#endif
