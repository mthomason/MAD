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

#import <QuartzCore/CALayer.h>

#import <CoreData/NSManagedObjectContext.h>
#import <CoreData/NSManagedObjectID.h>

#import "MADConnectorView.h"
#import "MTTitleView.h"
#import "MTSchemaFieldCell.h"
#import "NSLayoutConstraint+QueryVisualization.h"

#import <MADCocoaExtensions/UIColor+EverydayApps.h>

#import <MAD/MADocument.h>

#import <MAD/RptqQueryField.h>
#import <MAD/RptqQueryField+Extras.h>

#import <MAD/RptqQueryTable.h>
#import <MAD/RptqQueryTable+Extras.h>

#import <MAD/RptqDatabaseSchemaField.h>
#import <MAD/RptqDatabaseSchemaField+Extras.h>

#import "MADIdentifiersStoryboards.h"

#import "MADManagedObjectViewProtocol.h"

#import "MADQueryVisualizationSchemaView.h"


@interface MADQueryVisualizationSchemaViewController ()
    <UITableViewDataSource,
        UITableViewDelegate,
        MTSchemaFieldCellDelegate>

    @property (nonatomic, weak) IBOutlet MTTitleView *titleView;
    @property (nonatomic, weak) IBOutlet UIView *containerView;
    @property (nonatomic, weak) IBOutlet UIToolbar *toolbar;

    @property (nonatomic, strong) NSMutableArray <NSManagedObjectID *> *hasFieldsObjectIds;
    @property (nonatomic, copy) NSManagedObjectID *cachedTableObjectId;

    @property (nonatomic, strong) NSArray <NSSortDescriptor *> *sortDescriptorsFields;


@end

@implementation MADQueryVisualizationSchemaViewController

@synthesize document = _document;
@synthesize objectIdTag = _objectIdTag;
@synthesize root = _root;

static NSString * const MADIdentifierViewControllerQueryVisualizationSchema = @"MADIdentifierViewControllerQueryVisualizationSchema";

+ (instancetype)newQueryVisualizationSchemaViewController {
    UIStoryboard *storyboard;
    id controller;
    storyboard = [UIStoryboard storyboardWithName: MADStoryboardDesigner bundle: NULL];
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
    if (self = [super initWithCoder:aDecoder]) {
        NSMutableArray *hasFieldsObjectIds;
        NSSortDescriptor *namesAccending;
        NSArray <NSSortDescriptor *> *fieldsSortDescriptors;
        NSString *key;
        
        hasFieldsObjectIds = [[NSMutableArray alloc] init];
        self.hasFieldsObjectIds = hasFieldsObjectIds;
        
        key = [NSStringFromSelector(@selector(databaseSchemaField)) stringByAppendingString: @"."];
        key = [key stringByAppendingString:NSStringFromSelector(@selector(name))];
        
        namesAccending = [[NSSortDescriptor alloc] initWithKey: key
                                                     ascending: YES];
        
        fieldsSortDescriptors = [[NSArray alloc] initWithObjects:namesAccending, nil];
        self.sortDescriptorsFields = fieldsSortDescriptors;
    }
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
    [self.tableView reloadData];
}

#pragma mark -
#pragma mark MADManagedObjectViewProtocol

- (void)setObjectIdTag:(NSManagedObjectID *)objectIdTag {

    if (_objectIdTag != objectIdTag) {
        
        ((MADQueryVisualizationSchemaView *)self.view).objectIdTag = objectIdTag.copy;
        self.cachedTableObjectId = objectIdTag.copy;
        
        RptqQueryTable *table = [self.document.managedObjectContext objectWithID: objectIdTag];
        
        NSString *tableAlias = table.alias.copy;
        self.titleView.label.text = tableAlias;
        
        [self.hasFieldsObjectIds removeAllObjects];
        
        NSArray <RptqQueryField *> *fields;
        fields = [table.hasQueryFields sortedArrayUsingDescriptors:self.sortDescriptorsFields];
        
        for (RptqQueryField *field in fields) {
            NSManagedObjectID *fieldObjectID = field.objectID.copy;
            [self.hasFieldsObjectIds addObject:fieldObjectID];
        }
        _objectIdTag = objectIdTag.copy;
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

- (CGRect)rectForFieldWithObjectId:(NSManagedObjectID *)managedObjectID
                            inView:(UIView *)containerView {
    NSUInteger row = [self.hasFieldsObjectIds indexOfObject:managedObjectID];
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
    
    MTSchemaFieldCell *result = [tableView dequeueReusableCellWithIdentifier: MyIdentifierMTSchemaFieldCell];
    
    NSManagedObjectID *fieldObjectId = self.hasFieldsObjectIds[(NSUInteger)indexPath.row];
    
    RptqQueryField *field = [RptqQueryField queryFieldForObjectID: fieldObjectId
                                             managedObjectContext: self.document.managedObjectContext];
    result.detailLabel.text = field.databaseSchemaField.name.copy;
    return result;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (NSInteger)self.hasFieldsObjectIds.count;
}

#pragma mark - Methods

- (CGRect)rectForFieldWithObjectId:(NSManagedObjectID *)managedObjectID {
    NSUInteger row = [self.hasFieldsObjectIds indexOfObject:managedObjectID];
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
