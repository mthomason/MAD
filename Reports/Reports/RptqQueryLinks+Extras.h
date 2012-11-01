//
//  RptqQueryLinks+Extras.h
//  TheReportViewer
//
//  Created by Michael Thomason on 3/13/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "RptqQueryLinks.h"
#import <CoreData/CoreData.h>
#import "RptqDocument+Extras.h"

typedef enum {
	MNSLinkTypeInnerJoin = 0,
	MNSLinkTypeEquiJoin,
	MNSLinkTypeNaturalJoin,
    MNSLinkTypeCrossJoin,
    MNSLinkTypeLeftOuterJoin,
    MNSLinkTypeRightOuterJoin,
    MNSLinkTypeFullOuterJoin,
} MNSLinkType;

#define MNSLinkTypeReuseIds [NSArray arrayWithObjects: @"MNSJoinTypeInnerJoin", @"MNSJoinTypeEquiJoin", @"MNSJoinTypeNaturalJoin", @"MNSJoinTypeCrossJoin", @"MNSJoinTypeLeftOuterJoin", @"MNSJoinTypeRightOuterJoin", @"MNSJoinTypeFullOuterJoin", nil]

#define MNSLinkTypeNames [NSArray arrayWithObjects: NSLocalizedString(@"Inner-Join", @"Inner-Join"), NSLocalizedString(@"Equi-Join", @"Equi-Join"), NSLocalizedString(@"Natural Join", @"Natural Join"), NSLocalizedString(@"Cross Join", @"Cross Join"), NSLocalizedString(@"Left Outer Join", @"Left Outer Join"), NSLocalizedString(@"Right Outer Join", @"Right Outer Join"), NSLocalizedString(@"Full Outer Join", @"Full Outer Join"), nil]

#define MNSLinkTypeSymbols [NSArray arrayWithObjects: NSLocalizedString(@"⟕", @"Inner-Join"), NSLocalizedString(@"θ-join", @"Equi-Join"), NSLocalizedString(@"⋈", @"Natural Join"), NSLocalizedString(@"Cross Join", @"Cross Join"), NSLocalizedString(@"⟕", @"Left Outer Join"), NSLocalizedString(@"⟖", @"Right Outer Join"), NSLocalizedString(@"⟗", @"Full Outer Join"), nil]

@interface RptqQueryLinks (Extras)

+ (id)queryLinkWithID:(NSManagedObjectID *)objid fromObjectContext:(NSManagedObjectContext *)moc;
+ (void)deleteLinkWithID:(NSManagedObjectID *)objid fromObjectContext:(NSManagedObjectContext *)moc;

@end