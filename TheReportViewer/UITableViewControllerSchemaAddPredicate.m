//
//  UITableViewControllerSchemaAddPredicate.m
//  TheReportViewer
//
//  Created by Michael Thomason on 2/4/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "UITableViewControllerSchemaAddPredicate.h"
#import "UITableViewControllerChooseField.h"
#import "UITableViewControllerEnterString.h"
#import "RptqTable.h"
#import "RptqQueryTables.h"
#import "RptqQueryTables+Extras.h"

@implementation UITableViewControllerSchemaAddPredicate

@synthesize delegate = _delegate;
@synthesize tableViewCellLeftSide = _tableViewCellLeftSide, tableViewCellRightSide = _tableViewCellRightSide, tableViewCellOperator = _tableViewCellOperator;
@synthesize managedDocumentQuery = _managedDocumentQuery;

@synthesize leftValue = _leftValue, rightValue = _rightValue, predicateOperator = _predicateOperator;
@synthesize currentlyEditingPart = _currentlyEditingPart;

- (void)dealloc {
    [_tableViewCellLeftSide release];
    [_tableViewCellRightSide release];
    [_tableViewCellOperator release];
    [_managedDocumentQuery release];
    [_leftValue release];
    [_rightValue release];
    [super dealloc];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setCurrentlyEditingPart: MNSPredicateNone];
    }
    return self;
}

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        [self setCurrentlyEditingPart: MNSPredicateNone];
    }
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
    if ([[segue identifier] isEqualToString:@"showAddPredicateFovOperator"] ||
        [[segue identifier] isEqualToString:@"showAddPredicateFofOperator"]) {
        [self setCurrentlyEditingPart: MNSPredicateCenter];
        if ([[segue destinationViewController] isKindOfClass: [UITableViewControllerOpperators class]]) {
            [[segue destinationViewController] setDelegate:self];
        }
    } else if ([[segue identifier] isEqualToString:@"showAddPredicateFovLeftSide"] ||
               [[segue identifier] isEqualToString:@"showAddPredicateFofLeftSide"]) {
        [self setCurrentlyEditingPart: MNSPredicateLeft];
        if ([[segue destinationViewController] isKindOfClass: [UITableViewControllerChooseField class]]) {

            UITableViewControllerChooseField *dvc = [segue destinationViewController];
            if (dvc != nil) {
                [dvc setExcludeTables:[NSArray array]];
                [dvc setManagedDocumentQuery:[self managedDocumentQuery]];
                [dvc setDelegate: self];
            }

        }
    } else if ([[segue identifier] isEqualToString:@"showAddPredicateFovRightSide"] ||
               [[segue identifier] isEqualToString:@"showAddPredicateFofRightSide"]) {
        [self setCurrentlyEditingPart: MNSPredicateRight];
        
        if ([[segue destinationViewController] isKindOfClass: [UITableViewControllerChooseField class]]) {
            UITableViewControllerChooseField *dvc = [[segue destinationViewController] retain];
            if (dvc != nil) {
                [dvc setExcludeTables:[NSArray array]];
                [dvc setManagedDocumentQuery:[self managedDocumentQuery]];
                [dvc setDelegate: self];
            }
            [dvc release];
        } else if ([[segue destinationViewController] isKindOfClass: [UITableViewControllerEnterString class]]) {
            UITableViewControllerEnterString *tvcEnterString = [[segue destinationViewController] retain];
            [tvcEnterString setEnterStringDelegate: self];
            [tvcEnterString release];
        }
    }
}

#pragma mark - Actions

- (IBAction)save:(id)sender {
    [[self delegate] uITableViewControllerSchemaAddPredicateWithLeft:[self leftValue] comparson:[self predicateOperator] andRightValue:[self rightValue]];
}

- (IBAction)cancel:(id)sender {
    [[self delegate] uITableViewControllerSchemaAddPredicateDidFinish: self];
}

#pragma mark - Delegates

- (void)enterStringDidFinishWithString:(NSString *)userInput {
    if ([self currentlyEditingPart] == MNSPredicateLeft) {
        [self setLeftValue: userInput];
        [[[self tableViewCellLeftSide] detailTextLabel] setText:[userInput lowercaseString]];
    } else if ([self currentlyEditingPart] == MNSPredicateRight) {
        [self setRightValue: userInput];
        [[[self tableViewCellRightSide] detailTextLabel] setText:[userInput lowercaseString]];
    }
    [[self navigationController] popToViewController:self animated:YES];
}

- (void)tableViewControllerChooseFieldDidFinish:(UITableViewControllerChooseField *)controller withField:(RptqField *)field {
    [[self navigationController] popToViewController:self animated:YES];
    NSString *fieldName = [[NSString stringWithFormat:@"%@.%@", [[field inTable] name], [field name]] retain];
    if ([self currentlyEditingPart] == MNSPredicateLeft) {
        [self setLeftValue: fieldName];
        [[[self tableViewCellLeftSide] detailTextLabel] setText: [fieldName lowercaseString]];
    } else if ([self currentlyEditingPart] == MNSPredicateRight) {
        [self setRightValue: fieldName];
        [[[self tableViewCellRightSide] detailTextLabel] setText: [fieldName lowercaseString]];
    }
    [fieldName release];
}

- (void)uITableViewControllerOpperatorsDidSelectOperator:(MNSPredicateOperator)operatorType {
    [[self navigationController] popToViewController:self animated:YES];
    NSString *label = nil;
    [self setPredicateOperator: operatorType];
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