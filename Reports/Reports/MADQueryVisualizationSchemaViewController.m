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
#import <CoreData/CoreData.h>
#import <QuartzCore/QuartzCore.h>
#import "MADocument.h"

#import "AppDelegate.h"
#import "MTApplicationInstance.h"
#import "MTConnectorView.h"
#import "MTTitleView.h"

#import "UIView+NSObjectIdTag.h"

#import "RptqQueryField.h"
#import "RptqQueryField+Extras.h"

#import "RptqQueryTable.h"
#import "RptqQueryTable+Extras.h"

#import "RptqDatabaseSchemaTable.h"
#import "RptqDatabaseSchemaTable+Extras.h"

#import "RptqDatabaseSchemaField.h"

#import "MTSchemaFieldCell.h"

@interface MADQueryVisualizationSchemaViewController ()
    <UITableViewDataSource, UITableViewDelegate, MTSchemaFieldCellDelegate>

@property (nonatomic, strong) IBOutlet MTTitleView *titleView;
@property (nonatomic, strong) IBOutlet UIToolbar *toolbar;
@property (nonatomic, strong) NSMutableArray *hasFieldsObjectIds;
@property (nonatomic, strong) NSManagedObjectID *cachedTableObjectId;
@property (nonatomic, strong) IBOutlet UIView *containerView;
@property (nonatomic, strong) NSArray *sortDescriptorsFields;

@end

@implementation MADQueryVisualizationSchemaViewController

- (void)setCenter:(CGPoint)center {
    self.view.center = center;
    [self.delegate didMoveFieldRect:self animated:NO];
}

- (void)setBounds:(CGRect)bounds {
    self.view.bounds = bounds;
    [self.delegate didMoveFieldRect:self animated:NO];
}

- (void)setTransform:(CGAffineTransform)transform {
    self.view.transform = transform;
    [self.delegate didMoveFieldRect:self animated:NO];
}

- (CGPoint)center {
    return self.view.center;
}

- (CGRect)bounds {
    return self.view.bounds;
}

- (CGAffineTransform)transform {
    return self.view.transform;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    NSMutableArray *hasFieldsObjectIds = [[NSMutableArray alloc] init];
    self.hasFieldsObjectIds = hasFieldsObjectIds;
    
    NSSortDescriptor *namesAccending = [[NSSortDescriptor alloc] initWithKey: @"databaseSchemaField.name"
                                                                   ascending: YES];
    NSArray *fieldsSortDescriptors = @[namesAccending];
    self.sortDescriptorsFields = fieldsSortDescriptors;
}

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.schemaTableViewController.dataSource = self;
    self.schemaTableViewController.delegate = self;
    self.containerView.layer.cornerRadius =  25.0000f;
    self.containerView.clipsToBounds = YES;
    self.view.layer.shadowColor = [[UIColor grayColor] CGColor];
    self.view.layer.shadowOpacity = 1.0000f;
    self.view.layer.shadowRadius = 5.0000f;
    self.view.layer.shadowOffset = CGSizeMake(5.0000f, 5.0000f);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.schemaTableViewController reloadData];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [super prepareForSegue:segue sender:sender];
    
}

- (NSManagedObjectID *)tableObjectId {
    return self.cachedTableObjectId;
}

- (void)setTableObjectId:(NSManagedObjectID *)tableObjectId {
    [self.view setObjectIdTag:tableObjectId];
    self.cachedTableObjectId = tableObjectId;
    
    RptqQueryTable *table = [RptqQueryTable queryTableWithObjectID: self.cachedTableObjectId
                                              managedObjectContext: self.document.managedObjectContext];
    self.titleView.label.text = [table alias];
    self.titleView.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    [self.schemaTableViewController reloadData];
}

- (void)willTransitionToTraitCollection: (UITraitCollection *)newCollection
              withTransitionCoordinator: (id<UIViewControllerTransitionCoordinator>)coordinator {
    
    [super willTransitionToTraitCollection: newCollection
                 withTransitionCoordinator: coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self.containerView setNeedsDisplay];
        [self.navigationItem.titleView sizeToFit];
        [self.navigationItem.titleView setNeedsLayout];
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self.navigationItem.titleView sizeToFit];
    }];
    
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath { }

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 22.0000f;
}

#pragma mark - Table view datasource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *MyIdentifierMTSchemaFieldCell = @"MTSchemaFieldCellIdentifier";
    MTSchemaFieldCell *result = [tableView dequeueReusableCellWithIdentifier: MyIdentifierMTSchemaFieldCell];
    
    NSManagedObjectID *fieldObjectId = self.hasFieldsObjectIds[indexPath.row];
    RptqQueryField *field = [RptqQueryField queryFieldForObjectID: fieldObjectId
                                             managedObjectContext: self.document.managedObjectContext];
    result.detailLabel.text = field.databaseSchemaField.name;
    result.detailLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    return result;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    RptqQueryTable *queryTable = [RptqQueryTable queryTableWithObjectID: self.cachedTableObjectId
                                                   managedObjectContext: self.document.managedObjectContext];
    
    [self.hasFieldsObjectIds removeAllObjects];
    if (queryTable != nil) {
        
        NSArray *fields = [queryTable.hasQueryFields sortedArrayUsingDescriptors:self.sortDescriptorsFields];
        for (RptqQueryField *field in fields) {
            [self.hasFieldsObjectIds addObject:field.objectID];
        }
        
    }
    return self.hasFieldsObjectIds.count;
}

#pragma mark - Methods

- (MTSchemaFieldCell *)cellForFieldWithObjectId:(NSManagedObjectID *)managedObjectID {
    NSUInteger row = [self.hasFieldsObjectIds indexOfObject:managedObjectID];
    NSIndexPath *cellIndexPath = [NSIndexPath indexPathForItem:row inSection:0];
    return (MTSchemaFieldCell *)[self.schemaTableViewController cellForRowAtIndexPath:cellIndexPath];
}

- (CGRect)rectForFieldWithObjectId:(NSManagedObjectID *)managedObjectID {
    NSUInteger row = [self.hasFieldsObjectIds indexOfObject:managedObjectID];
    NSIndexPath *cellIndexPath = [NSIndexPath indexPathForItem:row inSection:0];
    CGRect rectForRow = [self.schemaTableViewController rectForRowAtIndexPath:cellIndexPath];
    return [self.schemaTableViewController convertRect:rectForRow toView:self.view];
}

- (CGRect)rectForFieldWithObjectId:(NSManagedObjectID *)managedObjectID inView:(UIView *)containerView {
    NSUInteger row = [self.hasFieldsObjectIds indexOfObject:managedObjectID];
    CGRect rectForRow;
    if (row == NSNotFound) {
        rectForRow = CGRectZero;
    } else {
        NSIndexPath *cellIndexPath = [NSIndexPath indexPathForItem:row inSection:0];
        rectForRow = [self.schemaTableViewController rectForRowAtIndexPath:cellIndexPath];
    }
    return [self.schemaTableViewController convertRect:rectForRow toView:containerView];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self.delegate didMoveFieldRect:self animated:NO];
}

@end
