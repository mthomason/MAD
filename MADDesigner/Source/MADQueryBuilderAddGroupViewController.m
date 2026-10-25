
//
//  UITableViewControllerSchemaAddGroup.m
//  Reports
//
//  Created by Michael Thomason on 2/4/12.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADQueryBuilderAddGroupViewController.h"


#import <UIKit/UINavigationController.h>
#import <UIKit/UIBarButtonItem.h>
#import <UIKit/UILabel.h>
#import <UIKit/UIStoryboardSegue.h>
#import <UIKit/UINavigationBar.h>

#import <MAD/MADocument.h>
#import <MAD/RptqStoreContext.h>

#import <MAD/RptqQueryField.h>
#import <MAD/RptqQueryField+Extras.h>

#import "MADQueryBuilderSortTypeViewController.h"
#import "MADQueryChooseFieldController.h"

#import "MADQueryBuilderAddGroupDelegate.h"

static NSString * const TextAccending = @"Accending";
static NSString * const TextDecending = @"Decending";
static NSString * const TextDefault = @"Default";

@interface MADQueryBuilderAddGroupViewController ()
@property (nonatomic, assign) int64_t fieldId;
@end

@implementation MADQueryBuilderAddGroupViewController

- (void)dealloc { }

- (instancetype)initWithStyle:(UITableViewStyle)style {
	if (self = [super initWithStyle:style]) { }
	return self;
}

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
	[super viewDidLoad];
	self.sortOrder = MADSortOrderAccending;
	self.tableViewCellSort.detailTextLabel.text = [NSLocalizedString(TextAccending, TextAccending) lowercaseString];
	[self updateSaveButtonState];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"showGroupSortOrders"]) {
		if ([segue.destinationViewController isKindOfClass: [MADQueryBuilderSortTypeViewController class]]) {
			((MADQueryBuilderSortTypeViewController *)segue.destinationViewController).initalSortOrder = self.sortOrder;
			((MADQueryBuilderSortTypeViewController *)segue.destinationViewController).delegate = self;
		}
	} else if ([segue.identifier isEqualToString:@"showAddGroupByField"]) {
		if ([segue.destinationViewController isKindOfClass: [MADQueryChooseFieldController class]]) {
			
			MADQueryChooseFieldController *dvc = segue.destinationViewController;
			if (dvc != nil) {
				NSArray *empty = [[NSArray alloc] init];
				dvc.excludeTables = empty;
				dvc.delegate = self;
				dvc.document = self.document;
			}
		}
	}
}

#pragma mark -
#pragma mark Delegates

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath { }

#pragma mark MADQueryChooseFieldProtocol

- (void)tableViewControllerChooseFieldDidFinish: (MADQueryChooseFieldController *)controller
									withFieldID: (int64_t)fieldID {
	if (fieldID == 0) return;

	RptqStoreContext *context = self.document.storeContext;
	RptqQueryField *queryField = (RptqQueryField *)[context objectForEntity:NSStringFromClass([RptqQueryField class]) identifier:fieldID];

	[self.navigationController popToViewController:self animated:YES];

	NSString *fieldName = [queryField tableFieldKey];
	self.fieldId = queryField.identifier;
	self.fieldName = [fieldName copy];
	self.tableViewCellField.detailTextLabel.text = queryField.display.lowercaseString;

	[self updateSaveButtonState];
}

#pragma mark MADQueryBuilderSortTypeDelegate

- (void)viewController:(UIViewController *)viewController
	 didSelectSortType:(MADSortOrder)sortOrderType {

	self.sortOrder = sortOrderType;
	NSString *label = nil;
	switch (sortOrderType) {

		case MADSortOrderAccending:
			label = NSLocalizedString(TextAccending, TextAccending);
			self.tableViewCellSort.detailTextLabel.text = label.lowercaseString;;
			self.detailLabelSort.text = label;
			break;

		case MADSortOrderDecending:
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

#pragma mark -
#pragma mark Actions

- (IBAction)cancel:(id)sender {
	[self.delegate viewControllerDidCancel: self];
}

- (IBAction)save:(id)sender {
	if (self.fieldId != 0) {
		[self.delegate viewController: self addedGroupOnQueryField: self.fieldId andSortOrder: self.sortOrder];
	}
}

#pragma mark -
#pragma mark Helpers

- (void)updateSaveButtonState {
	self.navigationItem.rightBarButtonItem.enabled = [self fieldId] != 0;
}

@end
