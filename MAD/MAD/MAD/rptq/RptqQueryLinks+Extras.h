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
#import "MADQueryLinkType.h"

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

@class RptqDocument, RptqQueryLinks;

@interface RptqQueryLinks (Extras) <MTProtocolLog>

    + (instancetype)newQueryLinksWithLeftField:(RptqQueryField *)fieldLeft
                                    rightField:(RptqQueryField *)fieldRight
                                      joinType:(MNSLinkType)joinType
                          managedObjectContext:(NSManagedObjectContext *)managedObjectContext;

    - (NSString *)copyLinkDescription;

    + (NSString *)ReuseIdForLinkType:(MNSLinkType)type;
    + (NSString *)newLocalizedNameForLinkType:(MNSLinkType)type;
    + (NSString *)SqlForLinkType:(MNSLinkType)type;

@end

#endif
