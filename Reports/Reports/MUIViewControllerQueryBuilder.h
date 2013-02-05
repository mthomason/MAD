//
//  UIViewControllerSchemaTables.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/22/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
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
#import "MUITableViewControllerDatabaseDriverSelector.h"
#import "UITableViewControllerLinkBuilder.h"
#import "UITableViewControllerSectionLayoutSettings.h"
#import "MUIViewControllerReportDesigner.h"
#import "UIColor+PaperPatterns.h"
#import "RptqUserCredentals+Extras.h"
#import "RptqQueryGroup+Extras.h"
#import "RptqQueryPredicate+Extras.h"
#import "RptqQueryLinks+Extras.h"
#import "MTViewTableHeader.h"

@interface MUIViewControllerQueryBuilder : MTViewController
    <UITableViewDataSource,
        UITableViewDelegate,
        NSFetchedResultsControllerDelegate,
        UIViewControllerSchemaAddLinkDelegate,
        UIViewControllerSchemaAddTableDelegate,
        UITableViewControllerSchemaAddGroupDelegate,
        MUIViewControllerDelegate,
        UITableViewControllerLinkBuilderDelegate,
        MUIViewControllerDelegate,
        SectionLayoutSettingsDelegate,
        AddPredicateDelegate>

@property (retain, nonatomic) NSFetchedResultsController *fetchedResultsControllerTables;
@property (retain, nonatomic) NSFetchedResultsController *fetchedResultsControllerLinks;
@property (retain, nonatomic) NSFetchedResultsController *fetchedResultsControllerGroups;
@property (retain, nonatomic) NSFetchedResultsController *fetchedResultsControllerPredicates;

@property (retain, nonatomic) IBOutlet UIToolbar *toolbar;
@property (retain, nonatomic) IBOutlet UIToolbar *toolbarTop;
@property (retain, nonatomic) IBOutlet UITableView *tableViewQueryBuilder;

@property (assign, nonatomic) IBOutlet UITableViewCellInstruction   *tableViewCellInstruction;
@property (assign, nonatomic) IBOutlet UITableViewCellTableName     *tableViewCellTableName;
@property (assign, nonatomic) IBOutlet UITableViewCellQueryLink     *tableViewCellQueryLink;
@property (assign, nonatomic) IBOutlet UITableViewCellOverride      *tableViewCellOverride;
@property (assign, nonatomic) IBOutlet UITableViewCellQueryInput    *tableViewCellQueryInput;

@property (retain, nonatomic) IBOutlet UINavigationItem *navigationItemMain;
@property (nonatomic) BOOL suspendAutomaticTrackingOfChangesInManagedObjectContext;

@property (assign) NSInteger lastSelectedRowNumber;

@property BOOL debug;

- (IBAction)done:(id)sender;
- (IBAction)addTable:(id)sender;
- (IBAction)addLink:(id)sender;
- (IBAction)edit:(id)sender;

- (UIViewControllerSchemaTablesSections)tableSectionTypeForIndexPathSection:(NSUInteger)sec;
- (NSUInteger)sectionPositionForTableSectionType:(UIViewControllerSchemaTablesSections)sec;

@end