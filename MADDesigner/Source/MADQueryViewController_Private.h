//
//  MADQueryViewController_Private.h
//  Reports
//
//  Created by Michael Thomason on 1/22/12.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_MADQueryViewController_Private_h
#define MAD_MADQueryViewController_Private_h

#import "MADQueryViewController.h"
#import "MADQueryViewSectionDelegate.h"
#import "MADTabBarController.h"
#import "MADQueryBuilderAddTableViewController.h"
#import "MADQueryBuilderAddGroupViewController.h"
#import "MADQueryPredicateFormatController.h"
#import "MADTableViewCellQueryTableName.h"
#import "MADTableViewCellQueryLink.h"
#import "MADTableViewCellQueryGroup.h"
#import "MADTableViewCellQueryPredicate.h"
#import "MTTableController.h"
#import "MADQueryLinkBuilderController.h"
#import "MADTableViewHeader.h"
#import "MADDesignerSectionLayoutController.h"
#import "MADNavigationController.h"
#import "MADViewControllerSQL.h"
#import "UIViewController+tabBarItem.h"
#import "MADQueryViewDataSource.h"
#import "MADQueryBuilderAddGroupDelegate.h"
#import "MADQueryViewControllerTableLayout.h"
#import "MADQueryViewControllerLayoutSectionSelectorProtocol.h"
#import "MTStoreKitController+Features.h"
#import "MTStoreKitController+NonRenewableLicensing.h"
#import "MADQueryViewDelegate.h"
#import "MADTabBarItemProtocol.h"
#import "MADQueryViewDatasourceProtocol.h"
#import "MADOperationGetCredentials.h"
#import "MADThemeManager.h"
#import <MADFoundation/madlog.h>

#import <MADAPI/MADQuery.h>
#import <MADCocoaExtensions/UIColor+EverydayApps.h>
#import <MADCocoaExtensions/MADLabelTitle.h>
#import <MAD/MADocument.h>
#import <MAD/RptqStoreContext.h>
#import <MAD/MADQuery+Extras.h>
#import <MAD/MADDatabaseConnection+Constructor.h>
#import <MAD/MADDatabase+Constructor.h>
#import <MAD/RptqDatabaseSchemaField.h>
#import <MAD/RptqDocument+Extras.h>
#import <MAD/RptqDatabase+Extras.h>
#import <MAD/RptqQuery+Extras.h>
#import <MAD/RptqQueryTable.h>
#import <MAD/RptqQueryTable+Extras.h>
#import <MAD/RptqQueryPredicate+Extras.h>
#import <MAD/RptqQueryField+Extras.h>
#import <MAD/RptqQueryGroup+Extras.h>
#import <MAD/RptqQueryLinks+Extras.h>
#import <MAD/RptqDatabaseCredentals+Extras.h>
#import <MAD/RptqDocumentSection.h>
#import <MAD/RptqDatabaseSchemaTable.h>
#import <MAD/MADModel.h>
#import <MAD/MADModelDocument.h>
#import <MAD/MADModelDatabase.h>
#import <MAD/MADModelQuery.h>

#import <MADFoundation/MADOperationObserver.h>
#import <MADFoundation/MADOperationQueue.h>

#import <UIKit/UIPopoverPresentationController.h>
#import <UIKit/UISwitch.h>
#import <UIKit/UIStoryboard.h>
#import <UIKit/UILabel.h>
#import <UIKit/UIImage.h>

static inline BOOL storeEnabled(void) {
	return [MADStoreKitController sharedObject].reportingEnabled;
}

@interface MADQueryViewController () <UIPopoverPresentationControllerDelegate, UIViewControllerTransitioningDelegate, MADOperationQueueDelegate, MADOperationObserver, MADQueryViewDelegateProtocol, MADQueryViewControllerDatasourceProtocol> {
	@package
	NSUInteger _lastSelectedRowNumber;
	CGFloat _headerSectionHeight;
	BOOL _suspendAutomaticTrackingOfChangesInManagedObjectContext;
	BOOL _firstTimeViewWillLayoutSubviews;
	BOOL _beganUpdates;
}

@property (nonatomic, assign) NSInteger showingTableIndex;
@property (nonatomic, strong) MADQueryViewDataSource *queryViewDataSource;
@property (nonatomic, strong) MADQueryViewDelegate *queryViewDelegate;
@property (nonatomic, strong) MADQueryViewCellConfigureHandler handleConfigureCell;
@property (nonatomic, strong) MADOperationQueue *credentailsQueue;
@property (nonatomic, readonly) MADTabBarController *tabBarController;
@property (nonatomic, weak) UIPresentationController *showSQLPresentationController;

- (void)ingnoreManagedObjectContextChanges:(RptqStoreContext *)context;
- (void)observeManagedObjectContextChanges:(RptqStoreContext *)context;
- (void)enableUserInteraction;
- (void)disableUserInteraction;

@end

#endif
