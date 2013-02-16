//
//  MTQueryBuilderAdvancedSchemaViewController.m
//  Reports
//
//  Created by Michael Thomason on 2/15/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTQueryBuilderAdvancedSchemaViewController.h"

@interface MTQueryBuilderAdvancedSchemaViewController () <UITableViewDataSource, UITableViewDelegate>

@property (retain, nonatomic) IBOutlet UITableView *schemaTableViewController;
@property (retain, nonatomic) NSArray *hasFields;
@property (retain, nonatomic) IBOutlet UIBarButtonItem *barButtonItemTitle;
@property (nonatomic, retain) NSManagedObjectID *cachedTableObjectId;

@end

@implementation MTQueryBuilderAdvancedSchemaViewController

- (void)dealloc {
    [_schemaTableViewController release];
    [_barButtonItemTitle release];
    [super dealloc];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {

    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [[self barButtonItemTitle] setEnabled:NO];
    [[self barButtonItemTitle] setBackButtonBackgroundImage:nil forState:UIControlStateHighlighted barMetrics:UIBarMetricsDefault];
    [[[self view] layer] setCornerRadius: 25.0000f];
    [[self view] setClipsToBounds:YES];
    [[self view] setBackgroundColor:[UIColor scrollViewTexturedBackgroundColor]];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"tableObjectId: %@", [self cachedTableObjectId]);
    [[self schemaTableViewController] setDataSource:self];
    [[self schemaTableViewController] setDelegate:self];
    [[self schemaTableViewController] reloadData];
    
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
    [[self barButtonItemTitle] setTitle:[table name]];
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
    RptqField *field = [[self hasFields] objectAtIndex:[indexPath row]];
    [[result detailLabel] setText:[field toString]];
    return result;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSManagedObjectContext *managedObjectContext = [[AppDelegate activeDocument] managedObjectContext];
    RptqTable *table = [RptqTable getTableForObjectID:[self cachedTableObjectId] fromObjectContext:managedObjectContext];
    [self setHasFields:[[table hasFields] allObjects]];
    return [[self hasFields] count];
}

- (void)viewDidUnload {
    [self setSchemaFieldCell:nil];
    [self setBarButtonItemTitle:nil];
    [super viewDidUnload];
}
@end
