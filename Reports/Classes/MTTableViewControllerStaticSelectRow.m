//
//  MTTableViewControllerStaticSelectTag.m
//  MAD
//
//  Created by Michael Thomason on 11/11/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTTableViewControllerStaticSelectRow.h"

@interface MTTableViewControllerStaticSelectRow ()

@end

@implementation MTTableViewControllerStaticSelectRow

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSInteger row = [[self delegate] initalRow];
    UITableViewCell *cell = [[self tableView] cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
    [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    NSInteger numberOfRows = [tableView numberOfRowsInSection:0];
    for (NSInteger i = 0; i < numberOfRows; i++) {
        UITableViewCell *c = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
        [c setAccessoryType:UITableViewCellAccessoryNone];
    }
    [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
    [[self delegate] didSelectTag:[cell tag]];
}

@end
