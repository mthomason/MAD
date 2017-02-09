//
//  MTQueryBuilderAdvancedSchemaViewController.m
//  Reports
//
//  Created by Michael Thomason on 2/15/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADQueryVisualizationSchemaViewController.h"

#import <QuartzCore/CALayer.h>

#import <CoreData/NSManagedObjectContext.h>
#import <CoreData/NSManagedObjectID.h>

#import <UIKit/UIView.h>
#import <UIKit/UIStoryboard.h>
#import <UIKit/UIManagedDocument.h>
#import <UIKit/UITableView.h>
#import <UIKit/UIToolbar.h>
#import <UIKit/UINibLoading.h>
#import <UIKit/UILabel.h>
#import <UIKit/UIViewControllerTransitionCoordinator.h>
#import <UIKit/UINavigationController.h>
#import <UIKit/UINavigationBar.h>
#import <UIKit/UICollectionView.h>

#import <MADCocoaExtensions/UIColor+EverydayApps.h>

#import <MAD/MADocument.h>

#import <MAD/MADModel.h>
#import <MAD/MADModelDocument.h>
#import <MAD/MADModelDatabase.h>
#import <MAD/MADModelTable.h>
#import <MAD/MADModelField.h>
#import <MAD/MADModelQuery.h>
#import <MAD/MADModelQueryTable.h>
#import <MAD/MADModelQueryField.h>

#import <MAD/RptqQueryField.h>
#import <MAD/RptqQueryField+Extras.h>

#import <MAD/RptqQueryTable.h>
#import <MAD/RptqQueryTable+Extras.h>

#import <MAD/RptqDatabaseSchemaField.h>
#import <MAD/RptqDatabaseSchemaField+Extras.h>

#import "MTTitleView.h"
#import "MTSchemaFieldCell.h"
#import "MADConnectorView.h"
#import "NSLayoutConstraint+QueryVisualization.h"

#import "MADManagedObjectViewProtocol.h"

#import "MADQueryVisualizationSchemaView.h"
#import "MADQueryVisualizationSchemaDelegate.h"

@interface MADQueryVisualizationSchemaViewController ()
    <UITableViewDataSource,
        UITableViewDelegate,
        MTSchemaFieldCellDelegate>

    @property (nonatomic, weak) IBOutlet MTTitleView *titleView;
    @property (nonatomic, weak) IBOutlet UIView *containerView;
    @property (nonatomic, weak) IBOutlet UIToolbar *toolbar;

@end

@implementation MADQueryVisualizationSchemaViewController {
    int64_t _identifierQueryTable;
    int64_t _identifierSchemaTable;
}

@synthesize document = _document;
@synthesize identifier = _identifier;
@synthesize root = _root;

static NSString * const MADIdentifierViewControllerQueryVisualizationSchema = @"MADIdentifierViewControllerQueryVisualizationSchema";

+ (instancetype)newQueryVisualizationSchemaViewController {
    UIStoryboard *storyboard;
    id controller;
    storyboard = [UIStoryboard storyboardWithName: @"MADStoryboardDesigner" bundle: NULL];
    controller = [storyboard instantiateViewControllerWithIdentifier: MADIdentifierViewControllerQueryVisualizationSchema];
    return controller;
}

+ (void)initialize {
    [super initialize];
    if (self == [MADQueryVisualizationSchemaViewController self]) {
        @autoreleasepool {
            UILabel <UIAppearance> *appearanceProxy;
            NSArray <Class <UIAppearanceContainer>> *classes;
            classes = [[NSArray alloc] initWithObjects: [MTTitleView class], nil];
            appearanceProxy = [UILabel appearanceWhenContainedInInstancesOfClasses:classes];
            appearanceProxy.textColor = [UIColor whiteColor];
            UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
            appearanceProxy.font = [font fontWithSize:12.0000f];
            font = nil;
        }
    }
}

- (void)dealloc { }

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) { }
    return self;
}

#pragma mark -
#pragma mark UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.containerView.layer.cornerRadius =  3.0000f;
    self.containerView.clipsToBounds = YES;
    
    self.toolbar.backgroundColor = [UIColor darkGrayColor];
    
    self.view.layer.shadowColor = [MADColorEverydayApps newColorBlueDark].CGColor;
    self.view.layer.shadowOpacity = 1.0000f;
    self.view.layer.shadowRadius = 1.0000f;
    self.view.layer.shadowOffset = CGSizeMake(5.0000f, 5.0000f);

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.tableView reloadData];
}

#pragma mark -
#pragma mark MADManagedObjectViewProtocol

- (void)setIdentifier:(int64_t)identifier {

    if (_identifier != identifier) {
        
        ((MADQueryVisualizationSchemaView *)self.view).identifier = identifier;
        _identifierQueryTable = identifier;
        
        MADModelQueryTable *queryTable;
        MADocument *doc = self.document;
        queryTable = [doc.documentModel.firstQuery.tables objectForKey: @(identifier)];
        _identifierSchemaTable = queryTable.schemaTable;

        self.titleView.label.text = [queryTable alias].copy;
        
        _identifier = identifier;
    }
}

#pragma mark -
#pragma mark MADHierarchicalGroupingNodeProtocol

- (void)setRoot:(BOOL)root {
    if ((_root = root)) self.toolbar.barTintColor = [UIColor blueColor];
    else self.toolbar.barTintColor = [UIColor darkGrayColor];
}

- (CGRect)frame {
    return self.tableView.frame;
}

- (CGRect)rectForFieldWithObjectIdentifier:(int64_t)managedObjectID
                                    inView:(UIView *)containerView {
    MADModelTable *table = [_document.documentModel.firstDatabase.tableDictionary objectForKey: @(_identifierSchemaTable)];
    NSUInteger row = [table.fieldIDs indexOfObject:@(managedObjectID)];
    CGRect rectForRow;
    if (row == NSNotFound) {
        rectForRow = CGRectZero;
    } else {
        NSIndexPath *cellIndexPath = [NSIndexPath indexPathForItem:(NSInteger)row inSection:0];
        rectForRow = [self.tableView rectForRowAtIndexPath:cellIndexPath];
    }
    return [self.tableView convertRect:rectForRow toView:containerView];
}

#pragma mark -
#pragma mark UIPresentationController

- (BOOL)shouldPresentInFullscreen { return YES; }

#pragma mark -
#pragma mark UIContentContainer

- (void)willTransitionToTraitCollection: (UITraitCollection *)newCollection
              withTransitionCoordinator: (id<UIViewControllerTransitionCoordinator>)coordinator {
    
    [super willTransitionToTraitCollection: newCollection
                 withTransitionCoordinator: coordinator];
    
    //short circuit
    if (!self.isViewLoaded) return;
    
    UINavigationItem *navigationItem;
    UIView __weak *titleView;

    navigationItem = self.navigationItem;
    titleView = navigationItem.titleView;
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [titleView sizeToFit];
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [titleView sizeToFit];
    }];
    
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath { }

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 16.0000f;
}

#pragma mark - Table view datasource

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    static NSString *MyIdentifierMTSchemaFieldCell = @"MTSchemaFieldCellIdentifier";
    
    MADModelDocument *doc = _document.documentModel;
    MADModelTable *table = [doc.firstDatabase.tableDictionary objectForKey: @(_identifierSchemaTable)];
    NSNumber *schemaFieldID = [table.fieldIDs objectAtIndex:(NSUInteger)indexPath.row];
    MADModelField *field = [table.fields objectForKey:schemaFieldID];
    MTSchemaFieldCell *cell = [tableView dequeueReusableCellWithIdentifier: MyIdentifierMTSchemaFieldCell];
    cell.detailLabel.text = field.name.copy;
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    MADModelDocument *doc = _document.documentModel;
    MADModelTable *table = [doc.firstDatabase.tableDictionary objectForKey: @(_identifierSchemaTable)];
    return (NSInteger)table.fieldIDs.count;
}

#pragma mark - Methods

- (CGRect)rectForFieldWithObjectIdentifier:(int64_t)managedObjectID {
    MADModelDocument *doc = _document.documentModel;
    MADModelTable *table = [doc.firstDatabase.tableDictionary objectForKey: @(_identifierSchemaTable)];
    NSUInteger row = [table.fieldIDs indexOfObject:@(managedObjectID)];
    NSIndexPath *cellIndexPath = [NSIndexPath indexPathForItem:(NSInteger)row inSection:0];
    CGRect rectForRow = [self.tableView rectForRowAtIndexPath:cellIndexPath];
    return [self.tableView convertRect:rectForRow toView:self.view];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    NSLog(@"%s [%@]", __PRETTY_FUNCTION__, scrollView);

    [self.delegate didMoveFieldRect:self animated:NO];
}

@end
