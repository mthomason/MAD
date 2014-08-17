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

#pragma mark - View lifecycle

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if ([[[tableView cellForRowAtIndexPath:indexPath] reuseIdentifier] isEqualToString:MNSPredicateOperatorReuseIds[MNSPredicateOperatorEqual]]) {
        [[self delegate] uITableViewControllerOpperatorsDidSelectOperator: MNSPredicateOperatorEqual];
    } else if ([[[tableView cellForRowAtIndexPath:indexPath] reuseIdentifier] isEqualToString:MNSPredicateOperatorReuseIds[MNSPredicateOperatorNotEqual]]) {
        [[self delegate] uITableViewControllerOpperatorsDidSelectOperator: MNSPredicateOperatorNotEqual];
    } else if ([[[tableView cellForRowAtIndexPath:indexPath] reuseIdentifier] isEqualToString:MNSPredicateOperatorReuseIds[MNSPredicateOperatorGreaterThan]]) {
        [[self delegate] uITableViewControllerOpperatorsDidSelectOperator: MNSPredicateOperatorGreaterThan];
    } else if ([[[tableView cellForRowAtIndexPath:indexPath] reuseIdentifier] isEqualToString:MNSPredicateOperatorReuseIds[MNSPredicateOperatorGreaterThanOrEqualTo]]) {
        [[self delegate] uITableViewControllerOpperatorsDidSelectOperator: MNSPredicateOperatorGreaterThanOrEqualTo];
    } else if ([[[tableView cellForRowAtIndexPath:indexPath] reuseIdentifier] isEqualToString:MNSPredicateOperatorReuseIds[MNSPredicateOperatorLessThan]]) {
        [[self delegate] uITableViewControllerOpperatorsDidSelectOperator: MNSPredicateOperatorLessThan];
    } else if ([[[tableView cellForRowAtIndexPath:indexPath] reuseIdentifier] isEqualToString:MNSPredicateOperatorReuseIds[MNSPredicateOperatorLessThanOrEqualTo]]) {
        [[self delegate] uITableViewControllerOpperatorsDidSelectOperator: MNSPredicateOperatorLessThanOrEqualTo];
    }
}

@end
