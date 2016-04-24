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
#import "MADConnectorView.h"
#import "MTTitleView.h"
#import "MTSchemaFieldCell.h"
#import "NSLayoutConstraint+QueryVisualization.h"
#import "MADManagedObjectView.h"

@interface MADQueryVisualizationSchemaViewController ()
    <UITableViewDataSource, UITableViewDelegate, MTSchemaFieldCellDelegate>

@property (nonatomic, weak) IBOutlet MTTitleView *titleView;
@property (nonatomic, weak) IBOutlet UIView *containerView;
@property (nonatomic, strong) NSMutableArray <NSManagedObjectID *> *hasFieldsObjectIds;
@property (nonatomic, copy) NSManagedObjectID *cachedTableObjectId;
@property (nonatomic, strong) NSArray <NSSortDescriptor *> *sortDescriptorsFields;
@property (nonatomic, strong) UIFont *titleFont;
@property (nonatomic, strong) UIFont *detailFont;
@property (nonatomic, strong) IBOutlet MADManagedObjectView *view;

@end

const CGFloat MADSchemaViewDefaultWidth = 120.0000f;
const CGFloat MADSchemaViewDefaultHeight = 140.0000f;

@implementation MADQueryVisualizationSchemaViewController

@dynamic view;

- (void)dealloc {
    _document = nil;
}

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
    UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    UIFont *detalFont = [font fontWithSize:8.0000f];
    UIFont *headLineFont = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    UIFont *titleFont = [headLineFont fontWithSize:12.0000f];
    self.detailFont = detalFont;
    self.titleFont = titleFont;
    
    NSMutableArray *hasFieldsObjectIds = [[NSMutableArray alloc] init];
    self.hasFieldsObjectIds = hasFieldsObjectIds;
    
    NSSortDescriptor *namesAccending = [[NSSortDescriptor alloc] initWithKey: @"databaseSchemaField.name"
                                                                   ascending: YES];
    NSArray <NSSortDescriptor *> *fieldsSortDescriptors =
                    [[NSArray <NSSortDescriptor *> alloc] initWithObjects:namesAccending, nil];
    self.sortDescriptorsFields = fieldsSortDescriptors;
}

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (BOOL)shouldPresentInFullscreen { return YES; }

- (void)viewDidLoad {
    [super viewDidLoad];
    self.schemaTableViewController.dataSource = self;
    self.schemaTableViewController.delegate = self;
    self.containerView.layer.cornerRadius =  3.0000f;
    self.containerView.clipsToBounds = YES;
    
    UIColor *color = [UIColor darkGrayColor];
    self.toolbar.backgroundColor = color;
    
    UIColor *darkBlue = [MADColorEverydayApps newColorBlueDark];
    self.view.layer.shadowColor = [darkBlue CGColor];
    self.view.layer.shadowOpacity = 1.0000f;
    self.view.layer.shadowRadius = 1.0000f;
    self.view.layer.shadowOffset = CGSizeMake(5.0000f, 5.0000f);
    
    NSLayoutConstraint *width = [NSLayoutConstraint schemaViewWidthForView:self.view andWidth:MADSchemaViewDefaultWidth];
    NSLayoutConstraint *height = [NSLayoutConstraint schemaViewHeightForView:self.view andHeight:MADSchemaViewDefaultHeight];
    NSArray *constraints = @[width, height];
    [self.view addConstraints:constraints];
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
    self.view.objectIdTag = tableObjectId.copy;
    self.cachedTableObjectId = tableObjectId.copy;
    RptqQueryTable *table = [self.document.managedObjectContext objectWithID: tableObjectId];
   
    NSString *tableAlias = table.alias.copy;
    self.titleView.label.text = tableAlias;
    
    UIFont *titleFont = self.titleFont.copy;
    self.titleView.label.font = titleFont;
    
    UIColor *color = [UIColor whiteColor];
    self.titleView.label.textColor = color;
    
    [self.hasFieldsObjectIds removeAllObjects];

    NSArray <RptqQueryField *> *fields = [table.hasQueryFields sortedArrayUsingDescriptors:self.sortDescriptorsFields];
    for (RptqQueryField *field in fields) {
        NSManagedObjectID *fieldObjectID = field.objectID.copy;
        [self.hasFieldsObjectIds addObject:fieldObjectID];
    }
}

- (void)willTransitionToTraitCollection: (UITraitCollection *)newCollection
              withTransitionCoordinator: (id<UIViewControllerTransitionCoordinator>)coordinator {
    
    [super willTransitionToTraitCollection: newCollection
                 withTransitionCoordinator: coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        //[self.containerView setNeedsDisplay];
        [self.navigationItem.titleView sizeToFit];
        [self.navigationItem.titleView setNeedsLayout];
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self.navigationItem.titleView sizeToFit];
    }];
    
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath { }

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 16.0000f;
}

#pragma mark - Table view datasource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *MyIdentifierMTSchemaFieldCell = @"MTSchemaFieldCellIdentifier";
    MTSchemaFieldCell *result = [tableView dequeueReusableCellWithIdentifier: MyIdentifierMTSchemaFieldCell];
    
    NSManagedObjectID *fieldObjectId = self.hasFieldsObjectIds[indexPath.row];
    RptqQueryField *field = [RptqQueryField queryFieldForObjectID: fieldObjectId
                                             managedObjectContext: self.document.managedObjectContext];
    result.detailLabel.text = field.databaseSchemaField.name;
    result.detailLabel.font = self.detailFont;
    return result;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
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
