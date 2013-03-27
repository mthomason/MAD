//
//  MTDocumentObjectNewAggregateViewController.m
//  Reports
//
//  Created by Michael Thomason on 3/25/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import "MTDocumentObjectNewAggregateViewController.h"

NSString * const MTDocumentObjectNewAggregateViewControllerIdentifier = @"MTDocumentObjectNewAggregateViewControllerIdentifier";

@interface MTDocumentObjectNewAggregateViewController ()

@end

@implementation MTDocumentObjectNewAggregateViewController

- (void)dealloc {
    [_tableViewCellAggrageFunction release];
    [_tableViewCellAggregateInput release];
    [_tableViewCellAggregateGroupBy release];
    [super dealloc];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
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

    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:[AppDelegate storyboardName] bundle:nil];
    MTAggregateFunctionsViewController *aggregateFunctionsViewControllerIdentifier = [storyboard instantiateViewControllerWithIdentifier:MTAggregateFunctionsViewControllerIdentifier];
	[[self navigationController] pushViewController:aggregateFunctionsViewControllerIdentifier animated:YES];

}


@end
