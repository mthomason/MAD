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
#import <MADDataStructures/MTProtocolLog.h>

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

@class RptqDocument, RptqQueryLinks;

@interface RptqQueryLinks (Extras) <MTProtocolLog>

+ (instancetype)newQueryLinksWithLeftField:(RptqQueryField *)fieldLeft
                                rightField:(RptqQueryField *)fieldRight
                                  joinType:(MNSLinkType)joinType
                      managedObjectContext:(NSManagedObjectContext *)managedObjectContext;

- (NSString *)copyLinkDescription;

+ (NSString *)ReuseIdForLinkType:(MNSLinkType)type;
+ (NSString *)LocalizedNamesForLinkType:(MNSLinkType)type;
+ (NSString *)SqlForLinkType:(MNSLinkType)type;

@end

#endif
