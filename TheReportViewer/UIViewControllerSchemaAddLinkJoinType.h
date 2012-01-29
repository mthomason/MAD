//
//  UIViewControllerSchemaAddLink.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/24/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIManagedDocumentQuery.h"

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


@class UIViewControllerSchemaAddLinkJoinType;

@protocol UIViewControllerSchemaAddLinkJoinTypeDelegate
- (void)viewControllerSchemaAddLinkJoinTypeDidFinishWith:(MNSLinkType)result from:(UIManagedDocumentQuery *)document;
@end

@interface UIViewControllerSchemaAddLinkJoinType : UITableViewController
    <UITableViewDelegate>

@property (assign, nonatomic) IBOutlet id <UIViewControllerSchemaAddLinkJoinTypeDelegate> delegate;

@property (retain) UIManagedDocumentQuery *managedDocumentQuery;

@end