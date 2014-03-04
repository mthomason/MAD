//
//  UIViewControllerSchemaTables.h
//  Reports
//
//  Created by Michael Thomason on 1/22/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MTQueryBuilderAddTableViewController.h"
#import "MTQueryBuilderAddGroupViewController.h"
#import "MTQueryBuilderPredicateFormatViewController.h"
#import "UITableViewCellInstruction.h"
#import "UITableViewCellTableName.h"
#import "UITableViewCellQueryLink.h"
#import "UITableViewCellOverride.h"
#import "UITableViewCellQueryInput.h"
#import "UITableViewCellQueryGroup.h"
#import "MTTableViewCellQueryPredicate.h"
#import "MTDatabaseDriverSelectorViewController.h"
#import "MTQueryBuilderLinkBuilderViewController.h"
#import "MTReportDesignerSectionLayoutSettingsViewController.h"
#import "MTReportDesignerViewController.h"
#import "UIColor+PaperPatterns.h"
#import "RptqUserCredentals+Extras.h"
#import "RptqQueryGroup+Extras.h"
#import "RptqQueryPredicate+Extras.h"
#import "RptqQueryLinks+Extras.h"
#import "MTViewTableHeader.h"
#import "MAReportDocument.h"
#import "UIDevice+Hack.h"
#import "MTLog.h"
#import "MTStoreKitController+NonRenewableLicensing.h"

extern NSString * const NSFetchedResultsCacheName;
extern NSString * const NSFetchedResultsCacheTables;
extern NSString * const NSFetchedResultsCacheLinks;
extern NSString * const NSFetchedResultsCacheGroups;
extern NSString * const NSFetchedResultsCachePredicates;

@interface MTQueryBuilderViewController : UITableViewController
    <UITableViewDataSource,
        UITableViewDelegate,
        NSFetchedResultsControllerDelegate,
        MTQueryBuilderAddLinkFirstTableDelegate,
        MTQueryBuilderAddTableDelegate,
        MTQueryBuilderAddGroupDelegate,
        MTViewControllerProtocol,
        MTQueryBuilderLinkBuilderDelegate,
        MTViewControllerProtocol,
        MTReportDesignerSectionLayoutSettingsDelegate,
        MTQueryBuilderPredicateFormatDelegate>

@property (nonatomic, assign) BOOL suspendAutomaticTrackingOfChangesInManagedObjectContext;

@property BOOL debug;

- (void)reloadDocument:(MAReportDocument *)documentReport animated:(BOOL)animated;
- (void)reloadActiveDocumentAnimated:(BOOL)animated;

- (IBAction)edit:(id)sender;

@end
