//
//  UITableViewControllerSchemaAddPredicate.m
//  TheReportViewer
//
//  Created by Michael Thomason on 2/4/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "UITableViewControllerSchemaAddPredicate.h"


@implementation UITableViewControllerSchemaAddPredicate

@synthesize delegate = _delegate;
@synthesize tableViewCellLeftSide = _tableViewCellLeftSide, tableViewCellRightSide = _tableViewCellRightSide, tableViewCellOperator = _tableViewCellOperator;

- (void)dealloc {
    [_tableViewCellLeftSide release];
    [_tableViewCellRightSide release];
    [_tableViewCellOperator release];
    [super dealloc];
}

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) { }
    return self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showAddPredicateOperator"]) {
        if ([[segue destinationViewController] isKindOfClass: [UITableViewControllerOpperators class]]) {
            [[segue destinationViewController] setDelegate:self];
        }
    }
}

#pragma mark - Actions

- (IBAction)save:(id)sender {    
    //[[self delegate] uITableViewControllerSchemaAddPredicateDidAddPredicate:<#(RptqQueryPredicate *)#>];
}

- (IBAction)cancel:(id)sender {
    [[self delegate] uITableViewControllerSchemaAddPredicateDidFinish: self];
}

#pragma mark - Delegates

- (void)uITableViewControllerOpperatorsDidSelectOperator:(MNSPredicateOperator)operatorType {
    [[self navigationController] popToViewController:self animated:YES];
    NSString *label = nil;
    switch (operatorType) {
        case MNSPredicateOperatorEqual:
            label = [MNSPredicateOperatorNames objectAtIndex: MNSPredicateOperatorEqual];
            break;
        case MNSPredicateOperatorNotEqual:
            label = [MNSPredicateOperatorNames objectAtIndex: MNSPredicateOperatorNotEqual];
            break;
        case MNSPredicateOperatorGreaterThan:
            label = [MNSPredicateOperatorNames objectAtIndex: MNSPredicateOperatorGreaterThan];
            break;
        case MNSPredicateOperatorGreaterThanOrEqualTo:
            label = [MNSPredicateOperatorNames objectAtIndex: MNSPredicateOperatorGreaterThanOrEqualTo];
            break;
        case MNSPredicateOperatorLessThanOrEqualTo:
            label = [MNSPredicateOperatorNames objectAtIndex: MNSPredicateOperatorLessThanOrEqualTo];
            break;
        case MNSPredicateOperatorLessThan:
            label = [MNSPredicateOperatorNames objectAtIndex: MNSPredicateOperatorLessThan];
            break;
        default:
            label = NSLocalizedString(@"Default", @"Default");
            break;
    }
    [[[self tableViewCellOperator] detailTextLabel] setText: [label lowercaseString]];
}

#pragma mark - Table View Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end