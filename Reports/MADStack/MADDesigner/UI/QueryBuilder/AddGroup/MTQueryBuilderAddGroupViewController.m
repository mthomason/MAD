
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

#import <UIKit/UINavigationController.h>
#import <UIKit/UIBarButtonItem.h>
#import <UIKit/UILabel.h>
#import <UIKit/UIStoryboardSegue.h>

#import <MAD/RptqQueryField+CoreDataClass.h>
#import <MAD/RptqQueryField+Extras.h>

#import "MTQueryBuilderSortTypeViewController.h"
#import "MTQueryBuilderChooseFieldViewController.h"

#import "MADQueryBuilderAddGroupDelegate.h"

static NSString * const TextAccending = @"Accending";
static NSString * const TextDecending = @"Decending";
static NSString * const TextDefault = @"Default";

@interface MTQueryBuilderAddGroupViewController ()

    @property (nonatomic, strong) RptqQueryField *field;
    @property (nonatomic, copy) NSManagedObjectID *fieldId;
    @property (nonatomic, weak) IBOutlet UIBarButtonItem *barButtonItemSave;

@end

@implementation MTQueryBuilderAddGroupViewController

- (void)dealloc {
    //NSLog(@"\t%s", __PRETTY_FUNCTION__);
}

- (instancetype)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) { }
    return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.barButtonItemSave.enabled = NO;
    self.sortOrder = MNSSortOrderAccending;
    NSString *accending = NSLocalizedString(@"Accending", @"Accending");
    self.tableViewCellSort.detailTextLabel.text = accending.lowercaseString;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showGroupSortOrders"]) {
        if ([segue.destinationViewController isKindOfClass: [MTQueryBuilderSortTypeViewController class]]) {
            ((MTQueryBuilderSortTypeViewController *)segue.destinationViewController).initalSortOrder = self.sortOrder;
            ((MTQueryBuilderSortTypeViewController *)segue.destinationViewController).delegate = self;
        }
    } else if ([segue.identifier isEqualToString:@"showAddGroupByField"]) {
        if ([segue.destinationViewController isKindOfClass: [MTQueryBuilderChooseFieldViewController class]]) {
            
            MTQueryBuilderChooseFieldViewController *dvc = segue.destinationViewController;
            if (dvc != nil) {
                NSArray *empty = [[NSArray alloc] init];
                dvc.excludeTables = empty;
                dvc.delegate = self;
                dvc.document = self.document;
            }
        }
    }
}

#pragma mark - Delegates

#pragma mark Choose Field

- (void)tableViewControllerChooseFieldDidFinish:(MTQueryBuilderChooseFieldViewController *)controller
                                      withField:(RptqQueryField *)queryField {
    [self.navigationController popToViewController:self animated:YES];

    NSString *fieldName = [queryField tableFieldKey];
    self.fieldId = queryField.objectID;
    self.field = queryField;
    self.fieldName = fieldName;
    self.tableViewCellField.detailTextLabel.text = queryField.display.lowercaseString;
    self.barButtonItemSave.enabled = YES;
}

#pragma mark Sort Type

- (void)uITableViewControllerSortTypeDidSelectSortType:(MNSSortOrder)sortOrderType {
    self.sortOrder = sortOrderType;
    NSString *label = nil;
    switch (sortOrderType) {

        case MNSSortOrderAccending:
            label = NSLocalizedString(TextAccending, TextAccending);
            self.tableViewCellSort.detailTextLabel.text = label.lowercaseString;;
            self.detailLabelSort.text = label;
            break;

        case MNSSortOrderDecending:
            label = NSLocalizedString(TextDecending, TextDecending);
            self.tableViewCellSort.detailTextLabel.text = label.lowercaseString;
            self.detailLabelSort.text = label;
            break;

        default:
            label = NSLocalizedString(TextDefault, TextDefault);
            self.tableViewCellSort.detailTextLabel.text = label.lowercaseString;
            self.detailLabelSort.text = label;
            break;
    }
    [self.navigationController popToViewController:self animated:YES];
}

#pragma mark - Actions

- (IBAction)cancel:(id)sender {
    [self.delegate viewControllerDidCancel: self];
}

- (IBAction)save:(id)sender {
    // FIXME: No validation???
    [self.delegate addQueryGroupWithQueryField: self.fieldId andSortOrder: self.sortOrder];
}

#pragma mark - Table View Sort Type Delegate

- (void)uITableViewControllerSortTypeDidFinish:(MTQueryBuilderSortTypeViewController *)controller {
    [self.navigationController popToViewController:self animated:YES];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath { }

@end
