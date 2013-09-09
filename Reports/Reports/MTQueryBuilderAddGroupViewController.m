
//
//  UITableViewControllerSchemaAddGroup.m
//  Reports
//
//  Created by Michael Thomason on 2/4/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MTQueryBuilderAddGroupViewController.h"

@interface MTQueryBuilderAddGroupViewController ()

@property (nonatomic, retain) RptqQueryField *field;
@property (nonatomic, retain) NSManagedObjectID *fieldId;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *barButtonItemSave;

@end

@implementation MTQueryBuilderAddGroupViewController

- (void)dealloc {
    [_field release];
    [_fieldName release];
    [_tableViewCellField release];
    [_tableViewCellSort release];
    [_barButtonItemSave release];
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
    [[self barButtonItemSave] setEnabled:NO];
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
    return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showGroupSortOrders"]) {
        if ([[segue destinationViewController] isKindOfClass: [MTQueryBuilderSortTypeViewController class]]) {
            [[segue destinationViewController] setDelegate:self];
        }
    } else if ([[segue identifier] isEqualToString:@"showAddGroupByField"]) {
        if ([[segue destinationViewController] isKindOfClass: [MTQueryBuilderChooseFieldViewController class]]) {
            
            MTQueryBuilderChooseFieldViewController *dvc = [segue destinationViewController];
            if (dvc != nil) {
                [dvc setExcludeTables:[NSArray array]];
                [dvc setDelegate: self];
            }
        }
    }
}

#pragma mark - Delegates

#pragma mark Choose Field

- (void)tableViewControllerChooseFieldDidFinish:(MTQueryBuilderChooseFieldViewController *)controller withField:(RptqQueryField *)queryField {
    [[self navigationController] popToViewController:self animated:YES];
    NSString *fieldName = [queryField tableFieldKey];
    [self setFieldId:[queryField objectID]];
    [self setField:queryField];
    [self setFieldName:fieldName];
    [[[self tableViewCellField] detailTextLabel] setText: [[queryField display] lowercaseString]];
    [[self barButtonItemSave] setEnabled:YES];
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
    [[self delegate] viewControllerDidCancel:self];
}

- (IBAction)save:(id)sender {
    [[self delegate] addQueryGroupWithQueryField:[self fieldId] andSortOrder:[self sortOrder]];
}

#pragma mark - Table View Sort Type Delegate

- (void)uITableViewControllerSortTypeDidFinish:(MTQueryBuilderSortTypeViewController *)controller {
    [[self navigationController] popToViewController:self animated:YES];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath { }

@end