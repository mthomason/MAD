//
//  UIViewControllerSchemaTables.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/22/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MUIViewController.h"
#import "QueryBuilderDataModal.h"
#import "UIViewControllerSchemaAddTable.h"
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
#import "UITableViewControllerLinkBuilder.h"
#import "UITableViewControllerSectionLayoutSettings.h"
#import "ReportDesignerViewController.h"
#import "UIColor+PaperPatterns.h"

@interface MUIViewControllerQueryBuilder : MUIViewController
    <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate,
        UIViewControllerSchemaAddLinkDelegate,
        UIViewControllerSchemaAddTableDelegate,
        UITableViewControllerSchemaAddGroupDelegate,
        MUIViewControllerDelegate,
        UITableViewControllerLinkBuilderDelegate,
        UIModalTableViewControllerDelegate,
        MUIViewControllerDelegate,
        SectionLayoutSettingsDelegate,
        AddPredicateDelegate>

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