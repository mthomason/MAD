//
//  UITableViewControllerSchemaAddGroup.m
//  TheReportViewer
//
//  Created by Michael Thomason on 2/4/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "UITableViewControllerSchemaAddGroup.h"


@implementation UITableViewControllerSchemaAddGroup

@synthesize delegate = _delegate;
@synthesize tableViewCellField = _tableViewCellField;
@synthesize tableViewCellSort = _tableViewCellSort;

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload {
    [self setTableViewCellField:nil];
    [self setTableViewCellSort:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showGroupSortOrders"]) {
        if ([[segue destinationViewController] isKindOfClass: [UITableViewControllerSortType class]]) {
            [[segue destinationViewController] setDelegate:self];
        }
    }
}

#pragma mark - Actions

- (IBAction)cancel:(id)sender {
    [[self delegate] uITableViewControllerSchemaAddGroupDidFinish:self];
}

- (IBAction)save:(id)sender {
#warning Do something here?
}

#pragma mark - Table View Sort Type Delegate

- (void)uITableViewControllerSortTypeDidFinish:(UITableViewControllerSortType *)controller {
    [[self navigationController] popToViewController:self animated:YES];
}

- (void)uITableViewControllerSortTypeDidSelectSortType:(MNSSortOrder)sortOrderType {
    [[self navigationController] popToViewController:self animated:YES];
    NSString *label = nil;
    switch (sortOrderType) {
        case MNSSortOrderAccending:
            label = NSLocalizedString(@"Accending", @"Accending");
            break;
        case MNSSortOrderDecending:
            label = NSLocalizedString(@"Decending", @"Decending");
            break;
        default:
            label = NSLocalizedString(@"Default", @"Default");
            break;
    }
    [[[self tableViewCellSort] detailTextLabel] setText: [label lowercaseString]];
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath { }

- (void)dealloc {
    [_tableViewCellField release];
    [_tableViewCellSort release];
    [super dealloc];
}

@end