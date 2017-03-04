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

#import "MADQueryBuilderAddPredicateController.h"
#import "MADQueryBuilderAddPredicateDelegate.h"
#import "MADTableViewControllerOpperatorsDelegate.h"

#import <CoreData/NSManagedObjectID.h>

#import <UIKit/UINavigationController.h>
#import <UIKit/UINavigationBar.h>
#import <UIKit/UILabel.h>
#import <UIKit/UIStoryboardSegue.h>

#import "MTQueryBuilderChooseFieldViewController.h"
#import "MADViewControllerValueBasedOnField.h"

#import <MAD/MADocument.h>

#import <MAD/RptqQueryPredicate+Extras.h>
#import <MAD/RptqQueryField+Extras.h>
#import <MAD/RptqDatabaseSchemaField.h>

#import "MADTableViewControllerOpperators.h"

@implementation MADQueryBuilderAddPredicateController

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        _currentlyEditingPart = MNSPredicateNone;
    }
    return self;
}

- (instancetype)initWithStyle:(UITableViewStyle)style {
    if (self = [super initWithStyle:style]) {
        _currentlyEditingPart = MNSPredicateNone;
    }
    return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    _tableViewCellRightSide.userInteractionEnabled = (_fieldLeft == nil) == NO;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    _tableViewCellRightSide.userInteractionEnabled = (_fieldLeft == nil) == NO;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    MADocument*document = _document;

    if ([segue.identifier isEqualToString:@"showAddPredicateFovOperator"] ||
        [segue.identifier isEqualToString:@"showAddPredicateFofOperator"]) {
        
        self.currentlyEditingPart = MNSPredicateCenter;
        
        if ([segue.destinationViewController isKindOfClass: [MADTableViewControllerOpperators class]]) {
            MADTableViewControllerOpperators *destinationViewController;
            destinationViewController = segue.destinationViewController;
            destinationViewController.delegate = self;
        }
        
    } else if ([segue.identifier isEqualToString:@"showAddPredicateFovLeftSide"] ||
               [segue.identifier isEqualToString:@"showAddPredicateFofLeftSide"]) {
        
        self.currentlyEditingPart = MNSPredicateLeft;
  
        if ([segue.destinationViewController isKindOfClass: [MTQueryBuilderChooseFieldViewController class]]) {

            MTQueryBuilderChooseFieldViewController *destinationViewController;
            NSArray *excludedTables = [[NSArray alloc] init];
            destinationViewController = segue.destinationViewController;
            destinationViewController.excludeTables = excludedTables;
            destinationViewController.delegate = self;
            destinationViewController.document = document;
            
        }
        
    } else if ([segue.identifier isEqualToString:@"showAddPredicateFovRightSide"] ||
               [segue.identifier isEqualToString:@"showAddPredicateFofRightSide"]) {
        
        self.currentlyEditingPart = MNSPredicateRight;
        
        if ([segue.destinationViewController isKindOfClass: [MTQueryBuilderChooseFieldViewController class]]) {
            
            NSArray *excludedTables = [[NSArray alloc] init];
            MTQueryBuilderChooseFieldViewController *destinationViewController;
            destinationViewController = segue.destinationViewController;
            destinationViewController.excludeTables = excludedTables;
            destinationViewController.delegate = self;
            destinationViewController.document = document;
        
        } else if ([segue.destinationViewController isKindOfClass: [MADViewControllerValueBasedOnField class]]) {

            MADViewControllerValueBasedOnField *destinationViewController;
            destinationViewController = segue.destinationViewController;
            destinationViewController.enterStringDelegate = self;
            destinationViewController.document = document;
            destinationViewController.schemaFieldObjectId = self.fieldLeft.databaseSchemaField.objectID.copy;
        }
    }
}

#pragma mark - Actions

- (IBAction)save:(id)sender {
    
    RptqQueryPredicate *queryPredicate = nil;
    NSManagedObjectContext *managedObjectContext = _document.managedObjectContext;
    if (self.leftValue == nil) {
        if (self.rightValue == nil) {
            queryPredicate = [RptqQueryPredicate newQueryPredicateFactoryWithLeftField: self.fieldLeft
                                                             comparsonOperator: self.predicateOperator
                                                                 andRightField: self.fieldRight
                                                       forManagedObjectContext: managedObjectContext];
        } else {
            queryPredicate = [RptqQueryPredicate newQueryPredicateFactoryWithLeftField: self.fieldLeft
                                                             comparsonOperator: self.predicateOperator
                                                                 andRightValue: self.rightValue
                                                       forManagedObjectContext: managedObjectContext];
        }
    } else {
        if (self.rightValue == nil) {
            queryPredicate = [RptqQueryPredicate newQueryPredicateFactoryWithLeftValue: self.leftValue
                                                             comparsonOperator: self.predicateOperator
                                                                 andRightField: self.fieldRight
                                                       forManagedObjectContext: managedObjectContext];
        } else {
            queryPredicate = [RptqQueryPredicate newQueryPredicateFactoryWithLeftValue: self.leftValue
                                                             comparsonOperator: self.predicateOperator
                                                                 andRightValue: self.rightValue
                                                       forManagedObjectContext: managedObjectContext];
        }
    }
    
    [self.queryPredicateDelegate tableViewControllerSchemaAddPredicateDidAddPredicate:queryPredicate];
    
}

- (IBAction)cancel:(id)sender {
    [self.queryPredicateDelegate viewControllerDidCancel: self];
}

#pragma mark - Delegates

- (void)enterStringDidFinishWithString:(NSString *)userString {

    NSString *userInput = userString.copy;
    if (_currentlyEditingPart == MNSPredicateLeft) {
        self.leftValue = userInput;
        self.fieldLeft = nil;
        _tableViewCellLeftSide.detailTextLabel.text = userInput.lowercaseString;
        
    } else if (_currentlyEditingPart == MNSPredicateRight) {
        self.rightValue = userInput;
        [self setFieldRight: nil];
        _tableViewCellRightSide.detailTextLabel.text = userInput.lowercaseString;
        
    }
    [self.navigationController popToViewController:self animated:YES];
}

- (void)tableViewControllerChooseFieldDidFinish:(MTQueryBuilderChooseFieldViewController *)controller
                                      withField:(RptqQueryField *)queryField {
    UITableViewCell *tableViewCellRightSide = _tableViewCellRightSide;
    [self.navigationController popToViewController:self animated:YES];
    if (_currentlyEditingPart == MNSPredicateLeft) {
        self.leftValue = nil;
        self.fieldLeft = queryField;
        _tableViewCellLeftSide.detailTextLabel.text = queryField.display;
        
    } else if (_currentlyEditingPart == MNSPredicateRight) {
        self.rightValue = nil;
        self.fieldRight = queryField;
        tableViewCellRightSide.detailTextLabel.text = queryField.display;
    }
    tableViewCellRightSide.userInteractionEnabled = (self.fieldLeft == nil);
}

- (void)uITableViewControllerOpperatorsDidSelectOperator:(MADPredicateOperator)operatorType {
    [self.navigationController popToViewController:self animated:YES];
    NSString *label = nil;
    switch ((_predicateOperator = operatorType)) {
        case MADPredicateOperatorEqual:
            label = NSLocalizedString(@"Equal", @"Equal");
            break;
        case MADPredicateOperatorNotEqual:
            label = NSLocalizedString(@"Not Equal", @"Not Equal");
            break;
        case MADPredicateOperatorGreaterThan:
            label = NSLocalizedString(@"Greater Than", @"Greater Than");
            break;
        case MADPredicateOperatorGreaterThanOrEqualTo:
            label = NSLocalizedString(@"Greater Than or Equal To", @"Greater Than or Equal To");
            break;
        case MADPredicateOperatorLessThanOrEqualTo:
            label = NSLocalizedString(@"Less Than or Equal To", @"Less Than or Equal To");
            break;
        case MADPredicateOperatorLessThan:
            label = NSLocalizedString(@"Less Than", @"Less Than");
            break;
        default:
            label = NSLocalizedString(@"Default", @"Default");
            break;
    }
    _tableViewCellOperator.detailTextLabel.text = label.lowercaseString;
}

#pragma mark - Table View Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
