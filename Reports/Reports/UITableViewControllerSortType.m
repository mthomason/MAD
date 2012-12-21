//
//  UITableViewControllerSortType.m
//  TheReportViewer
//
//  Created by Michael Thomason on 2/4/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "UITableViewControllerSortType.h"


#define MNSSortTypeReuseIds [NSArray arrayWithObjects: @"UITableViewCellSortOrderAccending", @"UITableViewCellSortOrderDecending", nil]

#define MNSSortTypeNames [NSArray arrayWithObjects: NSLocalizedString(@"Accending", @"Accending"), NSLocalizedString(@"Decending", @"Decending"), nil]

@implementation UITableViewControllerSortType

@synthesize delegate = _delegate;

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if ([[[tableView cellForRowAtIndexPath:indexPath] reuseIdentifier] isEqualToString:[MNSSortTypeReuseIds objectAtIndex:MNSSortOrderAccending]]) {
        [[self delegate] uITableViewControllerSortTypeDidSelectSortType: MNSSortOrderAccending];
    } else if ([[[tableView cellForRowAtIndexPath:indexPath] reuseIdentifier] isEqualToString:[MNSSortTypeReuseIds objectAtIndex:MNSSortOrderDecending]]) {
        [[self delegate] uITableViewControllerSortTypeDidSelectSortType: MNSSortOrderDecending];
    }
}

@end