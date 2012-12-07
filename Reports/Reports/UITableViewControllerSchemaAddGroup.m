
//
//  UITableViewControllerSchemaAddGroup.m
//  TheReportViewer
//
//  Created by Michael Thomason on 2/4/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "UITableViewControllerSchemaAddGroup.h"
#import "RptqTable.h"
#import "RptqQueryTables.h"
#import "RptqQueryTables+Extras.h"

@interface UITableViewControllerSchemaAddGroup ()

@property (nonatomic, retain) RptqField *field;

@end

@implementation UITableViewControllerSchemaAddGroup

- (void)dealloc {
    [_field release];
    [_fieldName release];
    [_tableViewCellField release];
    [_tableViewCellSort release];
    [super dealloc];
}

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {

    }
    return self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setSortOrder:MNSSortOrderAccending];
    [[[self tableViewCellSort] detailTextLabel] setText: [NSLocalizedString(@"Accending", @"Accending") lowercaseString]];
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
    } else if ([[segue identifier] isEqualToString:@"showAddGroupByField"]) {
        if ([[segue destinationViewController] isKindOfClass: [UITableViewControllerChooseField class]]) {
            
            UITableViewControllerChooseField *dvc = [segue destinationViewController];
            if (dvc != nil) {
                [dvc setExcludeTables:[NSArray array]];
                //[dvc setManagedDocumentQuery:[self managedDocumentQuery]];
                [dvc setDelegate: self];
            }
        }
    }
}

#pragma mark - Delegates

#pragma mark Choose Field

- (void)tableViewControllerChooseFieldDidFinish:(UITableViewControllerChooseField *)controller withField:(RptqField *)field {
    [[self navigationController] popToViewController:self animated:YES];
    NSString *fieldName = [[NSString stringWithFormat:@"%@.%@", [[field inTable] name], [field name]] retain];
    [self setField:field];
    [self setFieldName:fieldName];
    [[[self tableViewCellField] detailTextLabel] setText: [fieldName lowercaseString]];
    [fieldName release];
}

#pragma mark Sort Type

- (void)uITableViewControllerSortTypeDidSelectSortType:(MNSSortOrder)sortOrderType {
    [[self navigationController] popToViewController:self animated:YES];
    [self setSortOrder:sortOrderType];
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

#pragma mark - Actions

- (IBAction)cancel:(id)sender {
    [[self delegate] uITableViewControllerSchemaAddGroupDidFinish:self];
}

- (IBAction)save:(id)sender {
    [[self delegate] addGroupDidAddGroupWithField:[self field] andSort:[self sortOrder]];
}

#pragma mark - Table View Sort Type Delegate

- (void)uITableViewControllerSortTypeDidFinish:(UITableViewControllerSortType *)controller {
    [[self navigationController] popToViewController:self animated:YES];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath { }

@end