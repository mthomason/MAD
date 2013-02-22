//
//  MTQueryBuilderAdvancedSchemaViewController.m
//  Reports
//
//  Created by Michael Thomason on 2/15/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTQueryBuilderAdvancedSchemaViewController.h"

@interface MTQueryBuilderAdvancedSchemaViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, retain) IBOutlet UITableView *schemaTableViewController;
@property (nonatomic, retain) IBOutlet MTTitleView *titleView;
@property (nonatomic, retain) IBOutlet UIToolbar *toolbar;
@property (nonatomic, retain) NSMutableArray *hasFieldsObjectIds;

@property (nonatomic, retain) NSManagedObjectID *cachedTableObjectId;

@end

@implementation MTQueryBuilderAdvancedSchemaViewController

- (void)dealloc {
    [_schemaTableViewController release];
    [_hasFieldsObjectIds release];
    [_titleView release];
    [_toolbar release];
    [super dealloc];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        NSMutableArray *hasFieldsObjectIds = [[NSMutableArray alloc] init];
        [self setHasFieldsObjectIds:hasFieldsObjectIds];
        [hasFieldsObjectIds release];
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        NSMutableArray *hasFieldsObjectIds = [[NSMutableArray alloc] init];
        [self setHasFieldsObjectIds:hasFieldsObjectIds];
        [hasFieldsObjectIds release];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [[[self view] layer] setCornerRadius: 25.0000f];
    [[self view] setClipsToBounds:YES];
    [[self view] setBackgroundColor:[UIColor scrollViewTexturedBackgroundColor]];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [[self schemaTableViewController] setDataSource:self];
    [[self schemaTableViewController] setDelegate:self];
    [[self schemaTableViewController] reloadData];
    [[self toolbar] setTintColor:[UIColor edaGreenDark]];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
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
    NSManagedObjectContext *managedObjectContext = [[AppDelegate activeDocument] managedObjectContext];
    RptqTable *table = [RptqTable getTableForObjectID:[self cachedTableObjectId] fromObjectContext:managedObjectContext];
    [[[self titleView] label] setText:[table name]];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 22.0000f;
}

#pragma mark - Table view datasource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    //NSManagedObjectContext *managedObjectContext = [[AppDelegate activeDocument] managedObjectContext];
    //RptqTable *table = [RptqTable getTableForObjectID:[self tableObjectId] fromObjectContext:managedObjectContext];
    static NSString *MyIdentifierMTSchemaFieldCell = @"MTSchemaFieldCellIdentifier";
    MTSchemaFieldCell *result = [tableView dequeueReusableCellWithIdentifier: MyIdentifierMTSchemaFieldCell];
    if (!result) {
        UINib *resultCellNib = [UINib nibWithNibName:MyIdentifierMTSchemaFieldCell bundle:nil];
        [resultCellNib instantiateWithOwner:self options:nil];
        result = [self schemaFieldCell];
        [self setSchemaFieldCell:nil];
    }
    
    NSManagedObjectContext *managedObjectContext = [[AppDelegate activeDocument] managedObjectContext];
    NSManagedObjectID *fieldObjectId = [[self hasFieldsObjectIds] objectAtIndex:[indexPath row]];
    RptqField *field = [RptqField getFieldForObjectID:fieldObjectId fromObjectContext:managedObjectContext];
    //RptqField *field = [[self hasFields] objectAtIndex:[indexPath row]];
    [[result detailLabel] setText:[field name]];
    return result;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSManagedObjectContext *managedObjectContext = [[AppDelegate activeDocument] managedObjectContext];
    
    RptqTable *table = [RptqTable getTableForObjectID:[self cachedTableObjectId] fromObjectContext:managedObjectContext];
    [[self hasFieldsObjectIds] removeAllObjects];
    for (RptqField *field in [table hasFields]) {
        [[self hasFieldsObjectIds] addObject:[field objectID]];
    }
    //[self setHasFields:[[table hasFields] allObjects]];
    return [[self hasFieldsObjectIds] count];
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

- (void)viewDidUnload {
    [self setTitleView:nil];
    [self setToolbar:nil];
    [super viewDidUnload];
}
@end
