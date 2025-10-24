//
//  UITableViewControllerSchemaAddPredicate.m
//  Reports
//
//  Created by Michael Thomason on 2/4/12.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADQueryAddPredicateController.h"
#import "MADQueryBuilderAddPredicateDelegate.h"
#import "MADTableViewControllerOpperatorsDelegate.h"

#import <CoreData/NSManagedObjectID.h>
#import <CoreData/NSManagedObjectContext.h>

#import <UIKit/UINavigationController.h>
#import <UIKit/UINavigationBar.h>
#import <UIKit/UILabel.h>
#import <UIKit/UIStoryboardSegue.h>

#import "MADQueryChooseFieldController.h"
#import "MADQueryValueFromFieldController.h"

#import <MAD/MADocument.h>

#import <MAD/RptqDocument.h>
#import <MAD/RptqDocument+Extras.h>
#import <MAD/RptqQueryPredicate.h>
#import <MAD/RptqQueryPredicate+Extras.h>
#import <MAD/RptqQueryField.h>
#import <MAD/RptqQueryField+Extras.h>
#import <MAD/RptqDatabaseSchemaField.h>
#import <MADCocoaExtensions/NSError+Constructors.h>
#import "MADTableViewControllerOpperators.h"
#import <os/log.h>

static os_log_t mad_log;

@implementation MADQueryAddPredicateController

+ (void)initialize {
	if (self == [MADQueryAddPredicateController self]) {
		NSString *c = NSStringFromClass([MADQueryAddPredicateController class]);
		mad_log = os_log_create("com.mad", c.UTF8String);
	}
}

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
	_tableViewCellRightSide.userInteractionEnabled = (_fieldLeftID == nil) == NO;
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	_tableViewCellRightSide.userInteractionEnabled = (_fieldLeftID == nil) == NO;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

	MADocument*document = _document;

	if ([segue.identifier isEqualToString:@"showAddPredicateFovOperator"] ||
		[segue.identifier isEqualToString:@"showAddPredicateFofOperator"]) {
		
		self.currentlyEditingPart = MNSPredicateCenter;
		
		if ([segue.destinationViewController isKindOfClass: [MADTableViewControllerOpperators class]]) {
			MADTableViewControllerOpperators *destinationViewController = segue.destinationViewController;
			destinationViewController.delegate = self;
		}
		
	} else if ([segue.identifier isEqualToString:@"showAddPredicateFovLeftSide"] ||
			   [segue.identifier isEqualToString:@"showAddPredicateFofLeftSide"]) {
		
		self.currentlyEditingPart = MNSPredicateLeft;
  
		if ([segue.destinationViewController isKindOfClass: [MADQueryChooseFieldController class]]) {

			MADQueryChooseFieldController *destinationViewController;
			NSArray *excludedTables = [[NSArray alloc] init];
			destinationViewController = segue.destinationViewController;
			destinationViewController.excludeTables = excludedTables;
			destinationViewController.delegate = self;
			destinationViewController.document = document;
			
		}
		
	} else if ([segue.identifier isEqualToString:@"showAddPredicateFovRightSide"] ||
			   [segue.identifier isEqualToString:@"showAddPredicateFofRightSide"]) {
		
		self.currentlyEditingPart = MNSPredicateRight;
		
		if ([segue.destinationViewController isKindOfClass: [MADQueryChooseFieldController class]]) {
			
			NSArray *excludedTables = [[NSArray alloc] init];
			MADQueryChooseFieldController *destinationViewController = segue.destinationViewController;
			destinationViewController.excludeTables = excludedTables;
			destinationViewController.delegate = self;
			destinationViewController.document = document;
		
		} else if ([segue.destinationViewController isKindOfClass: [MADQueryValueFromFieldController class]]) {

			RptqQueryField *leftField = [self.document.managedObjectContext objectWithID:self.fieldLeftID];
			MADQueryValueFromFieldController *destinationViewController = segue.destinationViewController;
			destinationViewController.enterStringDelegate = self;
			destinationViewController.document = document;
			destinationViewController.schemaFieldObjectId = [leftField.databaseSchemaField.objectID copy];
		}
	}
}

#pragma mark - Actions

- (IBAction)save:(id)sender {
	
	RptqQueryPredicate *queryPredicate = nil;
	MADocument *document = self.document;
	NSManagedObjectContext *managedObjectContext = document.managedObjectContext;
	
	NSError *error = nil;
	if (self.leftValue == nil) {
		if (self.rightValue == nil) {
			queryPredicate = [RptqQueryPredicate newQueryPredicateFactoryWithLeftFieldID: self.fieldLeftID
																	   comparsonOperator: self.predicateOperator
																		 andRightFieldID: self.fieldRightID
																 forManagedObjectContext: managedObjectContext
																				   error: &error];
		} else {
			queryPredicate = [RptqQueryPredicate newQueryPredicateFactoryWithLeftFieldID: self.fieldLeftID
																	   comparsonOperator: self.predicateOperator
																		   andRightValue: self.rightValue
																 forManagedObjectContext: managedObjectContext
																				   error: &error];
		}
	} else {
		if (self.rightValue == nil) {
			queryPredicate = [RptqQueryPredicate newQueryPredicateFactoryWithLeftValue: self.leftValue
																	 comparsonOperator: self.predicateOperator
																	   andRightFieldID: self.fieldRightID
															   forManagedObjectContext: managedObjectContext
																				 error: &error];
		} else {
			queryPredicate = [RptqQueryPredicate newQueryPredicateFactoryWithLeftValue: self.leftValue
																	 comparsonOperator: self.predicateOperator
																		 andRightValue: self.rightValue
															   forManagedObjectContext: managedObjectContext
																				 error: &error];
		}
	}
	
	if (error != nil) {
		os_log_error(mad_log, "Error: %@", error);
	}

	if (queryPredicate != nil && error == nil) {
		[document.activeDocumentModel addPredicate:queryPredicate];
		[document saveContext];
		[document autosaveWithCompletionHandler:^(BOOL success) { }];
		[self.queryPredicateDelegate tableViewControllerSchemaAddPredicateDidAddPredicate:queryPredicate];
	} else {
		[NSError presentError:error onViewController:self completion:nil];
	}
	
}

- (IBAction)cancel:(id)sender {
	[self.queryPredicateDelegate viewControllerDidCancel: self];
}

#pragma mark - Delegates

- (void)enterStringDidFinishWithString:(NSString *)userString {

	NSString *userInput = [userString copy];
	if (_currentlyEditingPart == MNSPredicateLeft) {
		self.leftValue = userInput;
		self.fieldLeftID = nil;
		_tableViewCellLeftSide.detailTextLabel.text = userInput.lowercaseString;
		
	} else if (_currentlyEditingPart == MNSPredicateRight) {
		self.rightValue = userInput;
		self.fieldRightID = nil;
		_tableViewCellRightSide.detailTextLabel.text = userInput.lowercaseString;
		
	}
	[self.navigationController popToViewController:self animated:YES];
}

- (void)tableViewControllerChooseFieldDidFinish:(MADQueryChooseFieldController *)controller
									withFieldID:(NSManagedObjectID *)fieldID {
	
	NSManagedObjectContext *context = self.document.managedObjectContext;
	RptqQueryField *queryField = [context objectWithID: fieldID];
	
	UITableViewCell *tableViewCellRightSide = _tableViewCellRightSide;
	[self.navigationController popToViewController:self animated:YES];
	if (_currentlyEditingPart == MNSPredicateLeft) {
		self.leftValue = nil;
		self.fieldLeftID = [fieldID copy];
		_tableViewCellLeftSide.detailTextLabel.text = queryField.display;
		
	} else if (_currentlyEditingPart == MNSPredicateRight) {
		self.rightValue = nil;
		self.fieldRightID = [fieldID copy];
		tableViewCellRightSide.detailTextLabel.text = queryField.display;
	}
	tableViewCellRightSide.userInteractionEnabled = (self.fieldLeftID == nil);
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
