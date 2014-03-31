//
//  MTQueryBuilderAdvancedSchemaViewController.m
//  Reports
//
//  Created by Michael Thomason on 2/15/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTQueryBuilderAdvancedSchemaViewController.h"
#import <CoreData/CoreData.h>
#import <QuartzCore/QuartzCore.h>
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

@interface MTQueryBuilderAdvancedSchemaViewController () <UITableViewDataSource, UITableViewDelegate, MTSchemaFieldCellDelegate>

@property (nonatomic, strong) IBOutlet MTTitleView *titleView;
@property (nonatomic, strong) IBOutlet UIToolbar *toolbar;
@property (nonatomic, strong) NSMutableArray *hasFieldsObjectIds;
@property (nonatomic, strong) NSManagedObjectID *cachedTableObjectId;
@property (nonatomic, strong) IBOutlet UIView *containerView;

@end

@implementation MTQueryBuilderAdvancedSchemaViewController

- (void)setCenter:(CGPoint)center {
    //NSLog(@"Set Center :%@", NSStringFromCGPoint(center));
    //NSLog(@"View %@)", [self view]);
    [[self view] setCenter:center];
    [[self delegate] didMoveFieldRect:self animated:NO];
}

- (void)setBounds:(CGRect)bounds {
    [[self view] setBounds:bounds];
    [[self delegate] didMoveFieldRect:self animated:NO];
}

- (void)setTransform:(CGAffineTransform)transform {
    [[self view] setTransform:transform];
    [[self delegate] didMoveFieldRect:self animated:NO];
}

- (CGPoint)center {
    return [[self view] center];
}

- (CGRect)bounds {
    return [[self view] bounds];
}

- (CGAffineTransform)transform {
    return [[self view] transform];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        NSMutableArray *hasFieldsObjectIds = [[NSMutableArray alloc] init];
        [self setHasFieldsObjectIds:hasFieldsObjectIds];
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        NSMutableArray *hasFieldsObjectIds = [[NSMutableArray alloc] init];
        [self setHasFieldsObjectIds:hasFieldsObjectIds];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [[self schemaTableViewController] setDataSource:self];
    [[self schemaTableViewController] setDelegate:self];
    [[self schemaTableViewController] reloadData];
    [[[self containerView] layer] setCornerRadius: 25.0000f];
    [[self containerView] setClipsToBounds: YES];
    [[[self view] layer] setShadowColor:[[UIColor grayColor] CGColor]];
    [[[self view] layer] setShadowOpacity:1.0000f];
    [[[self view] layer] setShadowRadius:5.0000f];
    [[[self view] layer] setShadowOffset:CGSizeMake(5.0000f, 5.0000f)];
}

- (NSManagedObjectID *)tableObjectId {
    return [self cachedTableObjectId];
}

- (void)setTableObjectId:(NSManagedObjectID *)tableObjectId {
    [[self view] setObjectIdTag:tableObjectId];
    [self setCachedTableObjectId:tableObjectId];
    
    id activeDocument = [[AppDelegate app] activeDocument];
    NSManagedObjectContext *managedObjectContext = [activeDocument managedObjectContext];
    RptqQueryTable *table = [RptqQueryTable getQueryTableForObjectID:[self cachedTableObjectId] fromObjectContext:managedObjectContext];
    UILabel *titleLabel = [[self titleView] label];
    [titleLabel setText:[table alias]];
    [titleLabel setFont:[UIFont preferredFontForTextStyle:UIFontTextStyleHeadline]];

    [[self schemaTableViewController] reloadData];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 22.0000f;
}

#pragma mark - Table view datasource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *MyIdentifierMTSchemaFieldCell = @"MTSchemaFieldCellIdentifier";
    MTSchemaFieldCell *result = [tableView dequeueReusableCellWithIdentifier: MyIdentifierMTSchemaFieldCell];
    
    id activeDocument = [[AppDelegate app] activeDocument];
    NSManagedObjectContext *managedObjectContext = [activeDocument managedObjectContext];
    NSManagedObjectID *fieldObjectId = [[self hasFieldsObjectIds] objectAtIndex:[indexPath row]];
    RptqQueryField *field = [RptqQueryField getQueryFieldForObjectID:fieldObjectId fromObjectContext:managedObjectContext];
    UILabel *detailLabel = [result detailLabel];
    [detailLabel setText:[[field databaseSchemaField] name]];
    [detailLabel setFont:[UIFont preferredFontForTextStyle:UIFontTextStyleCaption1]];
    return result;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    NSUInteger result = 0;
    
    id activeDocument = [[AppDelegate app] activeDocument];
    NSManagedObjectContext *managedObjectContext = [activeDocument managedObjectContext];
    RptqQueryTable *queryTable = [RptqQueryTable getQueryTableForObjectID:[self cachedTableObjectId] fromObjectContext:managedObjectContext];
    
    if (queryTable != nil) {
        [[self hasFieldsObjectIds] removeAllObjects];
        
        NSSortDescriptor *namesAccending = [[NSSortDescriptor alloc] initWithKey:@"databaseSchemaField.name" ascending:YES];
        NSArray *fields = [[NSArray alloc] initWithArray: [[queryTable hasQueryFields] sortedArrayUsingDescriptors:@[namesAccending]]];
        for (RptqQueryField *field in fields) {
            [[self hasFieldsObjectIds] addObject:[field objectID]];
        }
        
        result = [[self hasFieldsObjectIds] count];
    }
    
    return result;
}

#pragma mark - Methods

- (MTSchemaFieldCell *)cellForFieldWithObjectId:(NSManagedObjectID *)managedObjectID {
    NSUInteger row = [[self hasFieldsObjectIds] indexOfObject:managedObjectID];
    NSIndexPath *cellIndexPath = [NSIndexPath indexPathForItem:row inSection:0];
    return (MTSchemaFieldCell *)[[self schemaTableViewController] cellForRowAtIndexPath:cellIndexPath];
}

- (CGRect)rectForFieldWithObjectId:(NSManagedObjectID *)managedObjectID {
    NSUInteger row = [[self hasFieldsObjectIds] indexOfObject:managedObjectID];
    NSIndexPath *cellIndexPath = [NSIndexPath indexPathForItem:row inSection:0];
    CGRect rectForRow = [[self schemaTableViewController] rectForRowAtIndexPath:cellIndexPath];
    return [[self schemaTableViewController] convertRect:rectForRow toView:[self view]];
}

- (CGRect)rectForFieldWithObjectId:(NSManagedObjectID *)managedObjectID inView:(UIView *)containerView {
    NSUInteger row = [[self hasFieldsObjectIds] indexOfObject:managedObjectID];
    CGRect rectForRow;
    if (row == NSNotFound) {
        rectForRow = CGRectZero;
    } else {
        NSIndexPath *cellIndexPath = [NSIndexPath indexPathForItem:row inSection:0];
        rectForRow = [[self schemaTableViewController] rectForRowAtIndexPath:cellIndexPath];
    }
    return [[self schemaTableViewController] convertRect:rectForRow toView:containerView];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [[self delegate] didMoveFieldRect:self animated:NO];
}

@end
