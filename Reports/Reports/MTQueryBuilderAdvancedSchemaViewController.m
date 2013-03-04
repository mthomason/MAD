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
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [[self schemaTableViewController] setDataSource:self];
    [[self schemaTableViewController] setDelegate:self];
    [[self schemaTableViewController] reloadData];
    [[self toolbar] setTintColor:[UIColor edaGreenDark]];
    [[[self containerView] layer] setCornerRadius: 25.0000f];
    [[self containerView] setClipsToBounds: YES];
    [[[self view] layer] setShadowColor:[[UIColor grayColor] CGColor]];
    [[[self view] layer] setShadowOpacity:9.0000f];
    [[[self view] layer] setShadowRadius:5.0000f];
    [[[self view] layer] setShadowOffset:CGSizeMake(5.0000f, 5.0000f)];

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    NSLog(@"%@", NSStringFromCGRect([self view].bounds));
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
    NSManagedObjectContext *managedObjectContext = [[AppDelegate activeDocument] managedObjectContext];
    NSManagedObjectID *fieldObjectId = [[self hasFieldsObjectIds] objectAtIndex:[indexPath row]];
    RptqField *field = [RptqField getFieldForObjectID:fieldObjectId fromObjectContext:managedObjectContext];
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
    NSSortDescriptor *namesAccending = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
    NSArray *fields = [[NSArray alloc] initWithArray: [[table hasFields] sortedArrayUsingDescriptors:@[namesAccending]]];
    for (RptqField *field in fields) {
        [[self hasFieldsObjectIds] addObject:[field objectID]];
    }
    [fields release];
    [namesAccending release];
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
    [self setContainerView:nil];
    [super viewDidUnload];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [[self delegate] didMoveFieldRect:self];
}

@end
