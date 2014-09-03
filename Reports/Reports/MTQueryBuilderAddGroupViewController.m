
//
//  UITableViewControllerSchemaAddGroup.m
//  Reports
//
//  Created by Michael Thomason on 2/4/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTQueryBuilderAddGroupViewController.h"
#import <CoreData/CoreData.h>
#import "MTQueryBuilderSortTypeViewController.h"
#import "MTQueryBuilderChooseFieldViewController.h"
#import "RptqQueryField.h"
#import "RptqQueryField+Extras.h"
#import "Constants.h"

@interface MTQueryBuilderAddGroupViewController ()

@property (nonatomic, strong) RptqQueryField *field;
@property (nonatomic, strong) NSManagedObjectID *fieldId;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *barButtonItemSave;

@end

@implementation MTQueryBuilderAddGroupViewController

- (instancetype)initWithStyle:(UITableViewStyle)style {
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
    [self setSortOrder:MNSSortOrderAccending];
    NSString *accending = NSLocalizedString(@"Accending", @"Accending");
    NSString *lowercase = [accending lowercaseString];
    [[[self tableViewCellSort] detailTextLabel] setText: lowercase];
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
    return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showGroupSortOrders"]) {
        if ([segue.destinationViewController isKindOfClass: [MTQueryBuilderSortTypeViewController class]]) {
            MTQueryBuilderSortTypeViewController *dvc = segue.destinationViewController;
            [dvc setInitalSortOrder:[self sortOrder]];
            [segue.destinationViewController setDelegate:self];
        }
    } else if ([segue.identifier isEqualToString:@"showAddGroupByField"]) {
        if ([segue.destinationViewController isKindOfClass: [MTQueryBuilderChooseFieldViewController class]]) {
            
            MTQueryBuilderChooseFieldViewController *dvc = segue.destinationViewController;
            if (dvc != nil) {
                [dvc setExcludeTables:@[]];
                dvc.delegate = self;
                dvc.document = self.document;
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
    [self setSortOrder:sortOrderType];
    NSString *label = nil;
    switch (sortOrderType) {
        case MNSSortOrderAccending:
            label = NSLocalizedString(@"Accending", @"Accending");
            [[[self tableViewCellSort] detailTextLabel] setText: [label lowercaseString]];
            [[self detailLabelSort] setText:label];
            break;
        case MNSSortOrderDecending:
            label = NSLocalizedString(@"Decending", @"Decending");
            [[[self tableViewCellSort] detailTextLabel] setText: [label lowercaseString]];
            [[self detailLabelSort] setText:label];
            break;
        default:
            label = NSLocalizedString(@"Default", @"Default");
            [[[self tableViewCellSort] detailTextLabel] setText: [label lowercaseString]];
            [[self detailLabelSort] setText:label];
            break;
    }
    [[self navigationController] popToViewController:self animated:YES];
    //[[[self tableViewCellSort] detailTextLabel] setNeedsDisplay];
}

#pragma mark - Actions

- (IBAction)cancel:(id)sender {
    [self.delegate viewControllerDidCancel:self];
}

- (IBAction)save:(id)sender {
    [self.delegate addQueryGroupWithQueryField:[self fieldId] andSortOrder:[self sortOrder]];
}

#pragma mark - Table View Sort Type Delegate

- (void)uITableViewControllerSortTypeDidFinish:(MTQueryBuilderSortTypeViewController *)controller {
    [[self navigationController] popToViewController:self animated:YES];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath { }

@end
