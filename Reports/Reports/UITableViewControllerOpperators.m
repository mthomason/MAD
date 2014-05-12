//
//  UITableViewControllerOpperators.m
//  Reports
//
//  Created by Michael Thomason on 2/4/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "UITableViewControllerOpperators.h"

@implementation UITableViewControllerOpperators

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
    if ([[[tableView cellForRowAtIndexPath:indexPath] reuseIdentifier] isEqualToString:[MNSPredicateOperatorReuseIds objectAtIndex:MNSPredicateOperatorEqual]]) {
        [[self delegate] uITableViewControllerOpperatorsDidSelectOperator: MNSPredicateOperatorEqual];
    } else if ([[[tableView cellForRowAtIndexPath:indexPath] reuseIdentifier] isEqualToString:[MNSPredicateOperatorReuseIds objectAtIndex:MNSPredicateOperatorNotEqual]]) {
        [[self delegate] uITableViewControllerOpperatorsDidSelectOperator: MNSPredicateOperatorNotEqual];
    } else if ([[[tableView cellForRowAtIndexPath:indexPath] reuseIdentifier] isEqualToString:[MNSPredicateOperatorReuseIds objectAtIndex:MNSPredicateOperatorGreaterThan]]) {
        [[self delegate] uITableViewControllerOpperatorsDidSelectOperator: MNSPredicateOperatorGreaterThan];
    } else if ([[[tableView cellForRowAtIndexPath:indexPath] reuseIdentifier] isEqualToString:[MNSPredicateOperatorReuseIds objectAtIndex:MNSPredicateOperatorGreaterThanOrEqualTo]]) {
        [[self delegate] uITableViewControllerOpperatorsDidSelectOperator: MNSPredicateOperatorGreaterThanOrEqualTo];
    } else if ([[[tableView cellForRowAtIndexPath:indexPath] reuseIdentifier] isEqualToString:[MNSPredicateOperatorReuseIds objectAtIndex:MNSPredicateOperatorLessThan]]) {
        [[self delegate] uITableViewControllerOpperatorsDidSelectOperator: MNSPredicateOperatorLessThan];
    } else if ([[[tableView cellForRowAtIndexPath:indexPath] reuseIdentifier] isEqualToString:[MNSPredicateOperatorReuseIds objectAtIndex:MNSPredicateOperatorLessThanOrEqualTo]]) {
        [[self delegate] uITableViewControllerOpperatorsDidSelectOperator: MNSPredicateOperatorLessThanOrEqualTo];
    }
}

@end
