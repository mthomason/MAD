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

@end

@implementation MTQueryBuilderAdvancedSchemaViewController

- (void)dealloc {
    [_schemaTableViewController release];
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
}

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"tableObjectId: %@", [self tableObjectId]);
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

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
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
    RptqTable *table = [RptqTable getTableForObjectID:[self tableObjectId] fromObjectContext:managedObjectContext];
    [self setHasFields:[[table hasFields] allObjects]];
    return [[self hasFields] count];
}

- (void)viewDidUnload {
    [self setSchemaFieldCell:nil];
    [super viewDidUnload];
}
@end
