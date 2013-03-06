//
//  RptqQueryLinks+Extras.h
//  Reports
//
//  Created by Michael Thomason on 3/13/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_RptqQueryLinks_Extras_h
#define Reports_RptqQueryLinks_Extras_h

#import "RptqQueryLinks.h"
#import <CoreData/CoreData.h>
#import "RptqDocument+Extras.h"
#import "MTProtocolLog.h"
#import "MTProtocolCompare.h"

typedef NS_ENUM(NSUInteger, MNSLinkType) {
	MNSLinkTypeInnerJoin = 0,
	MNSLinkTypeEquiJoin = 1,
	MNSLinkTypeNaturalJoin = 2,
    MNSLinkTypeCrossJoin = 3,
    MNSLinkTypeLeftOuterJoin = 4,
    MNSLinkTypeRightOuterJoin = 5,
    MNSLinkTypeFullOuterJoin = 6,
};

#define MNSLinkTypeReuseIds [NSArray arrayWithObjects: @"MNSJoinTypeInnerJoin", @"MNSJoinTypeEquiJoin", @"MNSJoinTypeNaturalJoin", @"MNSJoinTypeCrossJoin", @"MNSJoinTypeLeftOuterJoin", @"MNSJoinTypeRightOuterJoin", @"MNSJoinTypeFullOuterJoin", nil]

#define MNSLinkTypeNames [NSArray arrayWithObjects: NSLocalizedString(@"Inner-Join", @"Inner-Join"), NSLocalizedString(@"Equi-Join", @"Equi-Join"), NSLocalizedString(@"Natural Join", @"Natural Join"), NSLocalizedString(@"Cross Join", @"Cross Join"), NSLocalizedString(@"Left Outer Join", @"Left Outer Join"), NSLocalizedString(@"Right Outer Join", @"Right Outer Join"), NSLocalizedString(@"Full Outer Join", @"Full Outer Join"), nil]

#define MNSLinkTypeSymbols [NSArray arrayWithObjects: NSLocalizedString(@"⟕", @"Inner-Join"), NSLocalizedString(@"θ-join", @"Equi-Join"), NSLocalizedString(@"⋈", @"Natural Join"), NSLocalizedString(@"Cross Join", @"Cross Join"), NSLocalizedString(@"⟕", @"Left Outer Join"), NSLocalizedString(@"⟖", @"Right Outer Join"), NSLocalizedString(@"⟗", @"Full Outer Join"), nil]

#define MNSLinkTypeSqlRepresentation [NSArray arrayWithObjects: @"INNER JOIN", @"EQUI JOIN", @"NATURAL JOIN", @"CROSS JOIN", @"LEFT OUTER JOIN", @"RIGHT OUTER JOIN", @"FULL OUTER JOIN", nil]


@interface RptqQueryLinks (Extras) <MTProtocolCompare, MTProtocolLog>

+ (id)getQueryLinkWithID:(NSManagedObjectID *)objid fromObjectContext:(NSManagedObjectContext *)moc;
+ (void)deleteLinkWithID:(NSManagedObjectID *)objid fromObjectContext:(NSManagedObjectContext *)moc;

+ (id)createQueryLinkWithLeftField:(RptqField *)fieldLeft
                        rightField:(RptqField *)fieldRight
                       andJoinType:(MNSLinkType)joinType;

+ (void)insertQueryLink:(RptqQueryLinks *)queryLink intoManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;
+ (NSArray *)queriesForManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

@end

#endif
