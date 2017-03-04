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

#import "MTQueryBuilderSortTypeViewController.h"
#import "MADQueryBuilderSortTypeDelegate.h"

#import <UIKit/UINavigationController.h>
#import <UIKit/UINavigationBar.h>

@interface MTQueryBuilderSortTypeViewController ()

    @property (weak, nonatomic) IBOutlet UITableViewCell *tableViewCellAccending;
    @property (weak, nonatomic) IBOutlet UITableViewCell *tableViewCellDecending;

@end

@implementation MTQueryBuilderSortTypeViewController

@synthesize delegate = _delegate;

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.leftItemsSupplementBackButton = YES;
    self.navigationItem.hidesBackButton = NO;
    if (_initalSortOrder == MADSortOrderAccending) {
        _tableViewCellAccending.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        _tableViewCellDecending.accessoryType = UITableViewCellAccessoryCheckmark;
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    UITableViewCell *cellAccending = self.tableViewCellAccending;
    UITableViewCell *cellDecending = self.tableViewCellDecending;
    
    UITableViewCell *cellActive = [tableView cellForRowAtIndexPath:indexPath];
    NSString *reuseID = cellActive.reuseIdentifier;
    if ([reuseID isEqualToString: @"MTTableViewCellSortOrderAccending"]) {
        [self.delegate uITableViewControllerSortTypeDidSelectSortType: MADSortOrderAccending];
        cellAccending.accessoryType = UITableViewCellAccessoryCheckmark;
        cellDecending.accessoryType = UITableViewCellAccessoryNone;
        
    } else if ([reuseID isEqualToString: @"MTTableViewCellSortOrderDecending"]) {
        [self.delegate uITableViewControllerSortTypeDidSelectSortType: MADSortOrderDecending];
        cellAccending.accessoryType = UITableViewCellAccessoryNone;
        cellDecending.accessoryType = UITableViewCellAccessoryCheckmark;

    }
}

@end
