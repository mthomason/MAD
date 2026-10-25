//
//  MTTableViewControllerStaticSelectTag.m
//  MAD
//
//  Created by Michael Thomason on 11/11/13.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MTTableViewControllerStaticSelectRow.h"

@interface MTTableViewControllerStaticSelectRow ()

@end

@implementation MTTableViewControllerStaticSelectRow

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSInteger row = [self.delegate initalRow];
    NSIndexPath *path = [NSIndexPath indexPathForRow:row inSection:0];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:path];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    NSInteger numberOfRows = [tableView numberOfRowsInSection:0];
    for (NSInteger i = 0; i < numberOfRows; i++) {
        NSIndexPath *path = [NSIndexPath indexPathForRow:i inSection:0];
        UITableViewCell *c = [tableView cellForRowAtIndexPath:path];
        c.accessoryType = UITableViewCellAccessoryNone;
    }
    
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    [self.delegate didSelectTag:cell.tag];
}

@end
