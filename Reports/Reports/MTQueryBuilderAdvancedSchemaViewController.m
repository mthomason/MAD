//
//  MTQueryBuilderAdvancedSchemaViewController.m
//  Reports
//
//  Created by Michael Thomason on 2/15/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTQueryBuilderAdvancedSchemaViewController.h"

@interface MTQueryBuilderAdvancedSchemaViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, retain) IBOutlet MTTitleView *titleView;
@property (nonatomic, retain) IBOutlet UIToolbar *toolbar;
@property (nonatomic, retain) NSMutableArray *hasFieldsObjectIds;

@property (nonatomic, retain) NSManagedObjectID *cachedTableObjectId;
@property (nonatomic, retain) IBOutlet UIView *containerView;

@end

@implementation MTQueryBuilderAdvancedSchemaViewController

- (void)dealloc {
    [_cachedTableObjectId release];
    [_schemaTableViewController release];
    [_hasFieldsObjectIds release];
    [_titleView release];
    [_toolbar release];
    [_containerView release];
    [super dealloc];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        NSMutableArray *hasFieldsObjectIds = [[NSMutableArray alloc] init];
        [self setHasFieldsObjectIds:hasFieldsObjectIds];
        [hasFieldsObjectIds release];
        
        //NSManagedObjectID *emptyId = [[NSManagedObjectID alloc] init];
        //[self setCachedTableObjectId:emptyId];
        //[emptyId release];
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
        NSMutableArray *hasFieldsObjectIds = [[NSMutableArray alloc] init];
        [self setHasFieldsObjectIds:hasFieldsObjectIds];
        [hasFieldsObjectIds release];

        //NSManagedObjectID *emptyId = [[NSManagedObjectID alloc] init];
        //[self setCachedTableObjectId:emptyId];
        //[emptyId release];

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

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    //NSLog(@"%@", NSStringFromCGRect([self view].bounds));
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (NSManagedObjectID *)tableObjectId {
    return [[[self cachedTableObjectId] retain] autorelease];
}

- (void)setTableObjectId:(NSManagedObjectID *)tableObjectId {
    [[self view] setObjectIdTag:tableObjectId];
    [self setCachedTableObjectId:tableObjectId];
    NSManagedObjectContext *managedObjectContext = [[[MTActiveDocument sharedDocument] activeDocument] managedObjectContext];
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
    //NSManagedObjectContext *managedObjectContext = [[[MTActiveDocument sharedDocument] activeDocument] managedObjectContext];
    //RptqDatabaseSchemaTable *table = [RptqDatabaseSchemaTable getTableForObjectID:[self tableObjectId] fromObjectContext:managedObjectContext];
    static NSString *MyIdentifierMTSchemaFieldCell = @"MTSchemaFieldCellIdentifier";
    MTSchemaFieldCell *result = [tableView dequeueReusableCellWithIdentifier: MyIdentifierMTSchemaFieldCell];    
    NSManagedObjectContext *managedObjectContext = [[[MTActiveDocument sharedDocument] activeDocument] managedObjectContext];
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
    NSManagedObjectContext *managedObjectContext = [[[MTActiveDocument sharedDocument] activeDocument] managedObjectContext];
    RptqQueryTable *queryTable = [RptqQueryTable getQueryTableForObjectID:[self cachedTableObjectId] fromObjectContext:managedObjectContext];
    
    if (queryTable != nil) {
        [[self hasFieldsObjectIds] removeAllObjects];
        
        NSSortDescriptor *namesAccending = [[NSSortDescriptor alloc] initWithKey:@"databaseSchemaField.name" ascending:YES];
        NSArray *fields = [[NSArray alloc] initWithArray: [[queryTable hasQueryFields] sortedArrayUsingDescriptors:@[namesAccending]]];
        for (RptqQueryField *field in fields) {
            [[self hasFieldsObjectIds] addObject:[field objectID]];
        }
        [fields release];
        [namesAccending release];
        
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
    NSIndexPath *cellIndexPath = [NSIndexPath indexPathForItem:row inSection:0];
    CGRect rectForRow = [[self schemaTableViewController] rectForRowAtIndexPath:cellIndexPath];
    return [[self schemaTableViewController] convertRect:rectForRow toView:containerView];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [[self delegate] didMoveFieldRect:self animated:YES];
}

@end
