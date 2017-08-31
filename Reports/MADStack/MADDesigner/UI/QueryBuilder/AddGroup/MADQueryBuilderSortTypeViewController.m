//
//  UITableViewControllerSortType.m
//  Reports
//
//  Created by Michael Thomason on 2/4/12.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADQueryBuilderSortTypeViewController.h"
#import <UIKit/UINavigationController.h>
#import <UIKit/UINavigationBar.h>

#import "MADQueryBuilderSortTypeDelegate.h"

@interface MADQueryBuilderSortTypeViewController ()

    @property (weak, nonatomic) IBOutlet UITableViewCell *tableViewCellAccending;
    @property (weak, nonatomic) IBOutlet UITableViewCell *tableViewCellDecending;

@end

@implementation MTQueryBuilderSortTypeViewController

@synthesize delegate = _delegate;

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    if (_initalSortOrder == MADSortOrderAccending) {
        self.tableViewCellAccending.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        self.tableViewCellDecending.accessoryType = UITableViewCellAccessoryCheckmark;
    }
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    UITableViewCell *cellAccending = self.tableViewCellAccending;
    UITableViewCell *cellDecending = self.tableViewCellDecending;
    
    UITableViewCell *cellActive = [tableView cellForRowAtIndexPath:indexPath];
    NSString *reuseID = cellActive.reuseIdentifier;
    if ([reuseID isEqualToString: @"MTTableViewCellSortOrderAccending"]) {
        [self.delegate viewController:self didSelectSortType: MADSortOrderAccending];
        cellAccending.accessoryType = UITableViewCellAccessoryCheckmark;
        cellDecending.accessoryType = UITableViewCellAccessoryNone;
        
    } else if ([reuseID isEqualToString: @"MTTableViewCellSortOrderDecending"]) {
        [self.delegate viewController:self didSelectSortType: MADSortOrderDecending];
        cellAccending.accessoryType = UITableViewCellAccessoryNone;
        cellDecending.accessoryType = UITableViewCellAccessoryCheckmark;

    }
}

@end
