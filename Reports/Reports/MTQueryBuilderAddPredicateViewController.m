//
//  UITableViewControllerSchemaAddPredicate.m
//  Reports
//
//  Created by Michael Thomason on 2/4/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MTQueryBuilderAddPredicateViewController.h"
#import "MTQueryBuilderChooseFieldViewController.h"
#import "UITableViewControllerEnterString.h"
#import "RptqDatabaseSchemaTable.h"
#import "AppDelegate.h"

@implementation MTQueryBuilderAddPredicateViewController

@synthesize tableViewCellLeftSide = _tableViewCellLeftSide, tableViewCellRightSide = _tableViewCellRightSide, tableViewCellOperator = _tableViewCellOperator;
@synthesize currentlyEditingPart = _currentlyEditingPart;

- (void)dealloc {
    if (_fieldLeft != nil) [_fieldLeft release];
    if (_fieldRight != nil) [_fieldRight release];
    if (_leftValue != nil) [_leftValue release];
    if (_rightValue != nil) [_rightValue release];
    [_tableViewCellLeftSide release];
    [_tableViewCellRightSide release];
    [_tableViewCellOperator release];
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
    return YES;
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
        if ([[segue destinationViewController] isKindOfClass: [MTQueryBuilderChooseFieldViewController class]]) {

            MTQueryBuilderChooseFieldViewController *dvc = [segue destinationViewController];
            if (dvc != nil) {
                [dvc setExcludeTables:[NSArray array]];
                [dvc setDelegate: self];
            }

        }
    } else if ([[segue identifier] isEqualToString:@"showAddPredicateFovRightSide"] ||
               [[segue identifier] isEqualToString:@"showAddPredicateFofRightSide"]) {
        [self setCurrentlyEditingPart: MNSPredicateRight];
        
        if ([[segue destinationViewController] isKindOfClass: [MTQueryBuilderChooseFieldViewController class]]) {
            MTQueryBuilderChooseFieldViewController *dvc = [segue destinationViewController];
            if (dvc != nil) {
                [dvc setExcludeTables:[NSArray array]];
                [dvc setDelegate: self];
            }
        } else if ([[segue destinationViewController] isKindOfClass: [UITableViewControllerEnterString class]]) {
            UITableViewControllerEnterString *tvcEnterString = [segue destinationViewController];
            [tvcEnterString setEnterStringDelegate: self];
        }
    }
}

#pragma mark - Actions

- (IBAction)save:(id)sender {
    
    RptqQueryPredicate *queryPredicate = nil;
    NSManagedObjectContext *managedObjectContext = [[[MTActiveDocument sharedDocument] activeDocument] managedObjectContext];
    
    if ([self leftValue] == nil) {
        if ([self rightValue] == nil) {
            queryPredicate = [RptqQueryPredicate createPredicateWithLeftField:[self fieldLeft] comparsonOperator:[self predicateOperator] andRightField:[self fieldRight] forManagedObjectContext: managedObjectContext];
        } else {
            queryPredicate = [RptqQueryPredicate createPredicateWithLeftField:[self fieldLeft] comparsonOperator:[self predicateOperator] andRightValue:[self rightValue] forManagedObjectContext: managedObjectContext];
        }
    } else {
        if ([self rightValue] == nil) {
            queryPredicate = [RptqQueryPredicate createPredicateWithLeftValue:[self leftValue] comparsonOperator:[self predicateOperator] andRightField:[self fieldRight] forManagedObjectContext: managedObjectContext];
        } else {
            queryPredicate = [RptqQueryPredicate createPredicateWithLeftValue:[self leftValue] comparsonOperator:[self predicateOperator] andRightValue:[self rightValue] forManagedObjectContext: managedObjectContext];
        }
    }
    [[self delegate] uITableViewControllerSchemaAddPredicateDidAddPredicate:queryPredicate];
    
}

- (IBAction)cancel:(id)sender {
    [[self delegate] uITableViewControllerSchemaAddPredicateDidFinish: self];
}

#pragma mark - Delegates

- (void)enterStringDidFinishWithString:(NSString *)userInput {
    if ([self currentlyEditingPart] == MNSPredicateLeft) {
        [self setLeftValue: userInput];
        [self setFieldLeft: nil];
        [[[self tableViewCellLeftSide] detailTextLabel] setText:[userInput lowercaseString]];
    } else if ([self currentlyEditingPart] == MNSPredicateRight) {
        [self setRightValue: userInput];
        [self setFieldRight: nil];
        [[[self tableViewCellRightSide] detailTextLabel] setText:[userInput lowercaseString]];
    }
    [[self navigationController] popToViewController:self animated:YES];
}

- (void)tableViewControllerChooseFieldDidFinish:(MTQueryBuilderChooseFieldViewController *)controller withField:(RptqDatabaseSchemaField *)field {
    [[self navigationController] popToViewController:self animated:YES];
    if ([self currentlyEditingPart] == MNSPredicateLeft) {
        [self setLeftValue: nil];
        [self setFieldLeft: field];
        [[[self tableViewCellLeftSide] detailTextLabel] setText: [field display]];
    } else if ([self currentlyEditingPart] == MNSPredicateRight) {
        [self setRightValue: nil];
        [self setFieldRight: field];
        [[[self tableViewCellRightSide] detailTextLabel] setText: [field display]];
    }
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