//
//  UITableViewControllerOpperators.m
//  TheReportViewer
//
//  Created by Michael Thomason on 2/4/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "UITableViewControllerOpperators.h"

typedef enum {
	MNSPredicateOperatorEqual = 0,
	MNSPredicateOperatorNotEqual,
	MNSPredicateOperatorGreaterThan,
	MNSPredicateOperatorGreaterThanOrEqualTo,
	MNSPredicateOperatorLessThan,
	MNSPredicateOperatorLessThanOrEqualTo
} MNSPredicateOperator;

#define MNSPredicateOperatorReuseIds [NSArray arrayWithObjects: @"UITableViewCellPredicateOperatorEqual", @"UITableViewCellPredicateOperatorNotEqual", @"UITableViewCellPredicateOperatorGreaterThan", @"UITableViewCellPredicateOperatorGreaterThanOrEqualTo", @"UITableViewCellPredicateOperatorLessThan", @"UITableViewCellPredicateOperatorLessThanOrEqualTo", nil]

#define MNSPredicateOperatorNames [NSArray arrayWithObjects: NSLocalizedString(@"Equal", @"Equal"), NSLocalizedString(@"Not Equal", @"Not Equal"), NSLocalizedString(@"Greater Than", @"Greater Than"), NSLocalizedString(@"Greater Than or Equal To", @"Greater Than or Equal To"), NSLocalizedString(@"Less Than", @"Less Than"), NSLocalizedString(@"Less Than or Equal To", @"Less Than or Equal To"), nil]

@implementation UITableViewControllerOpperators

@synthesize delegate = _delegate;

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if ([[[tableView cellForRowAtIndexPath:indexPath] reuseIdentifier] isEqualToString:[MNSPredicateOperatorReuseIds objectAtIndex:MNSPredicateOperatorEqual]]) {
        [[self delegate] uITableViewControllerOpperatorsDidSelectOperator: NSEqualToPredicateOperatorType];
    } else if ([[[tableView cellForRowAtIndexPath:indexPath] reuseIdentifier] isEqualToString:[MNSPredicateOperatorReuseIds objectAtIndex:MNSPredicateOperatorNotEqual]]) {
        [[self delegate] uITableViewControllerOpperatorsDidSelectOperator: NSNotEqualToPredicateOperatorType];
    } else if ([[[tableView cellForRowAtIndexPath:indexPath] reuseIdentifier] isEqualToString:[MNSPredicateOperatorReuseIds objectAtIndex:MNSPredicateOperatorGreaterThan]]) {
        [[self delegate] uITableViewControllerOpperatorsDidSelectOperator: NSGreaterThanPredicateOperatorType];
    } else if ([[[tableView cellForRowAtIndexPath:indexPath] reuseIdentifier] isEqualToString:[MNSPredicateOperatorReuseIds objectAtIndex:MNSPredicateOperatorGreaterThanOrEqualTo]]) {
        [[self delegate] uITableViewControllerOpperatorsDidSelectOperator: NSGreaterThanOrEqualToPredicateOperatorType];
    } else if ([[[tableView cellForRowAtIndexPath:indexPath] reuseIdentifier] isEqualToString:[MNSPredicateOperatorReuseIds objectAtIndex:MNSPredicateOperatorLessThan]]) {
        [[self delegate] uITableViewControllerOpperatorsDidSelectOperator: NSLessThanPredicateOperatorType];
    } else if ([[[tableView cellForRowAtIndexPath:indexPath] reuseIdentifier] isEqualToString:[MNSPredicateOperatorReuseIds objectAtIndex:MNSPredicateOperatorLessThanOrEqualTo]]) {
        [[self delegate] uITableViewControllerOpperatorsDidSelectOperator: NSLessThanOrEqualToPredicateOperatorType];
    }
}

@end