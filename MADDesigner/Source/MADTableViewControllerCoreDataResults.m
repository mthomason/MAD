//
//  MADTableViewControllerCoreDataResults.m
//  MAD Designer
//
//  Created by Michael Thomason on 1/22/12.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADTableViewControllerCoreDataResults.h"
#import <UIKit/UINavigationController.h>
#import <UIKit/UINavigationBar.h>

@implementation MADTableViewControllerCoreDataResults

#pragma mark - Fetching

- (void)performFetch {
	[self.tableView reloadData];
}

- (void)setResults:(NSArray *)results {
	_results = results;
	[self.tableView reloadData];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return (NSInteger)self.results.count;
}

@end
