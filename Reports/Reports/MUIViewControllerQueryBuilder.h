//
//  UIViewControllerSchemaTables.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/22/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "QueryBuilderDataModal.h"
#import "MUIViewControllerQueryBuilder.h"
#import "UIViewControllerSchemaAddTable.h"
#import "UIViewControllerSchemaAddLinkFirstTable.h"
#import "UITableViewControllerSchemaAddGroup.h"
#import "UITableViewControllerPredicateFormat.h"
#import "UITableViewCellInstruction.h"
#import "UITableViewCellTableName.h"
#import "UITableViewCellQueryLink.h"
#import "UITableViewCellOverride.h"
#import "UITableViewCellQueryInput.h"
#import "UITableViewCellQueryGroup.h"
#import "UITableViewCellQueryPredicate.h"
#import "UITableViewControllerDataSourceTypes.h"
#import "UIViewControllerSchemaAddLinkFirstTable.h"
#import "UITableViewControllerLinkBuilder.h"
#import "UITableViewControllerPredicateFormat.h"
#import "UITableViewControllerSectionLayoutSettings.h"
#import "ReportDesignerViewController.h"
#import "Constants.h"
#import "RptqQueryPredicate.h"
#import "RptqUserCredentals.h"
#import "RptqQuery.h"
#import "RptqQueryTables+Extras.h"
#import "RptqDocument+Extras.h"
#import "RptqDocumentSection+Extras.h"
#import "UIColor+PaperPatterns.h"

@protocol MUIViewControllerQueryBuilderDelegate
- (void)uIViewControllerSchemaTablesDelegateDidFinish:(UIViewController *)controller;
@end

@interface MUIViewControllerQueryBuilder : UIViewController
    <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate,
        UIViewControllerSchemaAddLinkDelegate,
        UIViewControllerSchemaAddTableDelegate,
        UITableViewControllerSchemaAddGroupDelegate,
        UITableViewControllerDataSourceTypesDelegate,
        UITableViewControllerLinkBuilderDelegate,
        UIModalTableViewControllerDelegate,
        ReportDesignerViewControllerDelegate,
        SectionLayoutSettingsDelegate,
        AddPredicateDelegate>

@property (assign, nonatomic) IBOutlet id <MUIViewControllerQueryBuilderDelegate> delegate;

@property (retain, nonatomic) NSFetchedResultsController *fetchedResultsControllerTables;
@property (retain, nonatomic) NSFetchedResultsController *fetchedResultsControllerLinks;
@property (retain, nonatomic) NSFetchedResultsController *fetchedResultsControllerGroups;
@property (retain, nonatomic) NSFetchedResultsController *fetchedResultsControllerPredicates;

@property (retain, nonatomic) IBOutlet UIToolbar *toolbar;

@property (retain, nonatomic) IBOutlet UITableView *tableViewQueryBuilder;

@property (assign, nonatomic) IBOutlet UITableViewCellInstruction   *uITableViewCellInstruction;
@property (assign, nonatomic) IBOutlet UITableViewCellTableName     *uITableViewCellTableName;
@property (assign, nonatomic) IBOutlet UITableViewCellQueryLink     *uITableViewCellQueryLink;
@property (assign, nonatomic) IBOutlet UITableViewCellOverride      *uITableViewCellOverride;
@property (assign, nonatomic) IBOutlet UITableViewCellQueryInput    *uITableViewCellQueryInput;

@property (retain, nonatomic) IBOutlet UINavigationItem *navigationItemMain;
@property (nonatomic) BOOL suspendAutomaticTrackingOfChangesInManagedObjectContext;

@property (assign) NSInteger lastSelectedRowNumber;

@property BOOL debug;

- (IBAction)done:(id)sender;
- (IBAction)addTable:(id)sender;
- (IBAction)addLink:(id)sender;
- (IBAction)edit:(id)sender;

- (NSInteger)getNumberOfGroups;

- (UIViewControllerSchemaTablesSections)tableSectionTypeForIndexPathSection:(NSUInteger)sec;
- (NSUInteger)sectionPositionForTableSectionType:(UIViewControllerSchemaTablesSections)sec;

@end