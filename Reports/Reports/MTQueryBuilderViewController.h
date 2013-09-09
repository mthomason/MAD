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

//@property (nonatomic, retain) IBOutlet UITableView *tableViewQueryBuilder;

@property (assign, nonatomic) IBOutlet UITableViewCellInstruction   *tableViewCellInstruction;
@property (assign, nonatomic) IBOutlet UITableViewCellTableName     *tableViewCellTableName;
@property (assign, nonatomic) IBOutlet UITableViewCellQueryLink     *tableViewCellQueryLink;
@property (assign, nonatomic) IBOutlet UITableViewCellOverride      *tableViewCellOverride;
@property (assign, nonatomic) IBOutlet UITableViewCellQueryInput    *tableViewCellQueryInput;

@property (nonatomic) BOOL suspendAutomaticTrackingOfChangesInManagedObjectContext;

@property BOOL debug;

- (void)reloadDocument:(MAReportDocument *)documentReport;

- (IBAction)done:(id)sender;
- (IBAction)addTable:(id)sender;
- (IBAction)addLink:(id)sender;
- (IBAction)edit:(id)sender;

@end
