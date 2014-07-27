//
//  UITableViewControllerSchemaAddPredicate.m
//  Reports
//
//  Created by Michael Thomason on 2/4/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTQueryBuilderAddPredicateViewController.h"
#import "AppDelegate.h"
#import <CoreData/CoreData.h>
#import "RptqQueryField.h"
#import "RptqQueryField+Extras.h"
#import "MTApplicationInstance.h"
#import "RptqDatabaseSchemaField.h"

@implementation MTQueryBuilderAddPredicateViewController

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

- (void)viewDidLoad {
    [super viewDidLoad];
    [[self tableViewCellRightSide] setUserInteractionEnabled: ([self fieldLeft] == nil) == NO];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[self tableViewCellRightSide] setUserInteractionEnabled: ([self fieldLeft] == nil) == NO];
}

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
        } else if ([[segue destinationViewController] isKindOfClass: [MTViewControllerValueBasedOnField class]]) {
            MTViewControllerValueBasedOnField *tvcEnterString = [segue destinationViewController];
            [tvcEnterString setEnterStringDelegate: self];
            [tvcEnterString setSchemaFieldObjectId:[[[self fieldLeft] databaseSchemaField] objectID]];
        }
    }
}

#pragma mark - Actions

- (IBAction)save:(id)sender {
    
    RptqQueryPredicate *queryPredicate = nil;
    
    id activeDocument = [[AppDelegate app] activeDocument];
    NSManagedObjectContext *managedObjectContext = [activeDocument managedObjectContext];
    
    if ([self leftValue] == nil) {
        if ([self rightValue] == nil) {
            queryPredicate = [RptqQueryPredicate predicateFactoryWithLeftField:[self fieldLeft] comparsonOperator:[self predicateOperator] andRightField:[self fieldRight] forManagedObjectContext: managedObjectContext];
        } else {
            queryPredicate = [RptqQueryPredicate predicateFactoryWithLeftField:[self fieldLeft] comparsonOperator:[self predicateOperator] andRightValue:[self rightValue] forManagedObjectContext: managedObjectContext];
        }
    } else {
        if ([self rightValue] == nil) {
            queryPredicate = [RptqQueryPredicate predicateFactoryWithLeftValue:[self leftValue] comparsonOperator:[self predicateOperator] andRightField:[self fieldRight] forManagedObjectContext: managedObjectContext];
        } else {
            queryPredicate = [RptqQueryPredicate predicateFactoryWithLeftValue:[self leftValue] comparsonOperator:[self predicateOperator] andRightValue:[self rightValue] forManagedObjectContext: managedObjectContext];
        }
    }
    [[self delegate] uITableViewControllerSchemaAddPredicateDidAddPredicate:queryPredicate];
    
}

- (IBAction)cancel:(id)sender {
    [[self delegate] viewControllerDidCancel: self];
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

- (void)tableViewControllerChooseFieldDidFinish:(MTQueryBuilderChooseFieldViewController *)controller withField:(RptqQueryField *)queryField {
    [[self navigationController] popToViewController:self animated:YES];
    if ([self currentlyEditingPart] == MNSPredicateLeft) {
        [self setLeftValue: nil];
        [self setFieldLeft: queryField];
        [[[self tableViewCellLeftSide] detailTextLabel] setText: [queryField display]];
    } else if ([self currentlyEditingPart] == MNSPredicateRight) {
        [self setRightValue: nil];
        [self setFieldRight: queryField];
        [[[self tableViewCellRightSide] detailTextLabel] setText: [queryField display]];
    }
    [[self tableViewCellRightSide] setUserInteractionEnabled: ([self fieldLeft] == nil)];
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
