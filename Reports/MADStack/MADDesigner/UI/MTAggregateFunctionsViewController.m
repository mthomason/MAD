//
//  MTAggregateFunctionsViewController.m
//  Reports
//
//  Created by Michael Thomason on 3/25/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTAggregateFunctionsViewController.h"
#import "MADAggregateFunctionsViewControllerDelegate.h"

#import <UIKit/UIStoryboardSegue.h>
#import <UIKit/UINavigationController.h>
#import <UIKit/UINavigationBar.h>

#import "MADNavigationBarTitleView.h"

NSString * const MTAggregateFunctionsViewControllerIdentifier = @"MTAggregateFunctionsViewControllerIdentifier";

@interface MTAggregateFunctionsViewController ()

    @property (nonatomic, weak) IBOutletCollection(UITableViewCell) NSArray *tableViewCells;

@end

@implementation MTAggregateFunctionsViewController


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:@"MTSegueSelectAggregateFunction"]) {
        UITableViewCell *tableViewCell = (UITableViewCell *)sender;
        tableViewCell.accessoryType = UITableViewCellAccessoryCheckmark;
        [self setSelectedFunctionType: (MTAggregateFunctionType)tableViewCell.tag];
    }
}

- (void)setSelectedFunctionType:(MTAggregateFunctionType)selectedFunctionType {
    _selectedFunctionType = selectedFunctionType;
    [self updateSelectedFunctionType];
}

- (void)updateSelectedFunctionType {

    NSInteger numberOfSections = (self.tableView).numberOfSections;
    for (NSInteger sectionCtr = 0; sectionCtr < numberOfSections; sectionCtr++) {

        NSInteger numberOfRows = [self.tableView numberOfRowsInSection:sectionCtr];
        for (NSInteger rowCtr = 0; rowCtr < numberOfRows; rowCtr++) {

            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:rowCtr inSection:sectionCtr];
            UITableViewCell *tableViewCell = [self.tableView cellForRowAtIndexPath:indexPath];
            if (tableViewCell.tag == self.selectedFunctionType) {
                tableViewCell.accessoryType = UITableViewCellAccessoryCheckmark;
            } else {
                tableViewCell.accessoryType = UITableViewCellAccessoryNone;
            }
        }
    }
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.leftItemsSupplementBackButton = YES;
    self.navigationItem.hidesBackButton = NO;

    MADNavigationBarTitleView *titleView;
    titleView = [[MADNavigationBarTitleView alloc] initWithFrame:CGRectZero];
    titleView.text = NSLocalizedString(@"Aggregate Functions",
                                       @"Title of form that allows you to choose a type of "
                                       @"aggregate function (count, first, last, max, min, "
                                       @"avg, sum).");
    self.navigationItem.titleView = titleView;

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateSelectedFunctionType];
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

#pragma mark -
#pragma mark Table View Delegate Protocol

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {

}

- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath {
	
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

	[tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    for (UITableViewCell *tableViewCell in self.tableViewCells) {
        tableViewCell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    UITableViewCell *tableViewCell = [tableView cellForRowAtIndexPath:indexPath];
    tableViewCell.accessoryType = UITableViewCellAccessoryCheckmark;
    [self setSelectedFunctionType: (MTAggregateFunctionType)tableViewCell.tag];
    
    [self.functionDelegate didSelectFunction: self.selectedFunctionType];

}

@end
