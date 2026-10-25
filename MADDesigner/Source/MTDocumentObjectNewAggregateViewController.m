//
//  MTDocumentObjectNewAggregateViewController.m
//  Reports
//
//  Created by Michael Thomason on 3/25/13.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTDocumentObjectNewAggregateViewController.h"
#import "MADAggregateFunctionsViewControllerDelegate.h"
#import "MADGroupByViewControllerDelegate.h"
#import "MADQueryChooseFieldProtocol.h"
#import "MTGroupByViewController.h"
#import "MADQueryChooseFieldController.h"
#import "MTAggregateFunctionsViewController.h"

#import <MAD/MADocument.h>
#import <MAD/RptqQueryField+Extras.h>
#import <MAD/RptqDocumentElementAggregate+Extras.h>
#import <MADCocoaExtensions/MADLabelTitle.h>

#import <UIKit/UIStoryboardSegue.h>
#import <UIKit/UINavigationController.h>
#import <UIKit/UINavigationBar.h>
#import <UIKit/UILabel.h>

@interface MTDocumentObjectNewAggregateViewController () <MADAggregateFunctionsViewControllerDelegate, MADGroupByViewControllerDelegate, MADQueryChooseFieldProtocol>

@end

@implementation MTDocumentObjectNewAggregateViewController

@synthesize unwindViewController;

#pragma mark - MADQueryChooseFieldProtocol

- (void)tableViewControllerChooseFieldDidFinish: (MADQueryChooseFieldController *)controller
									withFieldID: (int64_t)fieldID {
	self.fieldObjectID = fieldID;
	RptqQueryField *field = (RptqQueryField *)[self.document.storeContext objectForEntity:NSStringFromClass([RptqQueryField class]) identifier:fieldID];
	self.tableViewCellAggregateInput.detailTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Field: %@", @"Field: %@"), [field display]];
	[self updateDisplay];
	[self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - MADGroupByViewControllerDelegate

- (void)didSelectGroupByPage {
	NSString *detail = [RptqDocumentElementAggregate newStringDisplayForGroupByType: MTAggregateGroupByTypePage];
	self.groupTypeSectionNumber = 0;
	self.aggregateGroupByType = MTAggregateGroupByTypePage;
	self.tableViewCellAggregateGroupBy.detailTextLabel.text = detail;

	[self updateDisplay];
	[self.navigationController popViewControllerAnimated:YES];
}

- (void)didSelectGroupByReport {
	NSString *detail = [RptqDocumentElementAggregate newStringDisplayForGroupByType: MTAggregateGroupByTypeReport];
	self.groupTypeSectionNumber = 0;
	self.aggregateGroupByType = MTAggregateGroupByTypeReport;
	self.tableViewCellAggregateGroupBy.detailTextLabel.text = detail;

	[self updateDisplay];
	[self.navigationController popViewControllerAnimated:YES];
}

- (void)didSelectGroupBySectionNumber:(int32_t)groupNumber {
	NSString *format = [RptqDocumentElementAggregate newStringDisplayForGroupByType: MTAggregateGroupByTypeSection];
	NSString *detail = [[NSString alloc] initWithFormat:format, groupNumber];
	self.groupTypeSectionNumber = groupNumber;
	self.aggregateGroupByType = MTAggregateGroupByTypeSection;
	self.tableViewCellAggregateGroupBy.detailTextLabel.text = detail;

	[self updateDisplay];
	[self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - MADAggregateFunctionsViewControllerDelegate

- (void)didSelectFunction:(MTAggregateFunctionType)aggregateFunctionType {
	if (aggregateFunctionType != MTAggregateFunctionTypeNotSet) {
		self.aggregateFunctionType = aggregateFunctionType;
		self.tableViewCellAggrageFunction.detailTextLabel.text = [[RptqDocumentElementAggregate newStringDisplayForType:aggregateFunctionType] stringByAppendingString:@"()"];
	}
	
	[self updateDisplay];
	[self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Exit

- (IBAction)unwindToNewAggregateFunction:(UIStoryboardSegue *)action {
	
	//[self performSegueWithIdentifier:@"MTSegueNewDocumentObjectAggregateLabelSaveIdentifer" sender:self];
	
	MTAggregateFunctionType aggregateFunctionType = MTAggregateFunctionTypeNotSet;
	
	if ([action.identifier isEqualToString:@"MTSegueAggregateFunctionCount"]) {
		
		aggregateFunctionType = MTAggregateFunctionTypeCount;
		
	} else if ([action.identifier isEqualToString:@"MTSegueAggregateFunctionFirst"]) {
		
		aggregateFunctionType = MTAggregateFunctionTypeFirst;
		
	} else if ([action.identifier isEqualToString:@"MTSegueAggregateFunctionLast"]) {
		
		aggregateFunctionType = MTAggregateFunctionTypeLast;
		
	} else if ([action.identifier isEqualToString:@"MTSegueAggregateFunctionMaximum"]) {
		
		aggregateFunctionType = MTAggregateFunctionTypeMax;
		
	} else if ([action.identifier isEqualToString:@"MTSegueAggregateFunctionMean"]) {
		
		aggregateFunctionType = MTAggregateFunctionTypeMean;
		
	} else if ([action.identifier isEqualToString:@"MTSegueAggregateFunctionMinimum"]) {
		
		aggregateFunctionType = MTAggregateFunctionTypeMin;
		
	} else if ([action.identifier isEqualToString:@"MTSegueAggregateFunctionSum"]) {
		
		aggregateFunctionType = MTAggregateFunctionTypeSum;
		
	} else if ([action.identifier isEqualToString:@"MTSegueAggregateGroupTypeSave"]) {
		
		MADGroupByViewController *groupByViewController = action.sourceViewController;
		self.aggregateGroupByType = groupByViewController.aggregateGroupType;
		self.groupTypeSectionNumber = groupByViewController.aggregateGroupNumber;
		
		switch (self.aggregateGroupByType) {
			case MTAggregateGroupByTypeSection: {
				
				int32_t group = self.groupTypeSectionNumber;
				NSString *format = [RptqDocumentElementAggregate newStringDisplayForGroupByType: MTAggregateGroupByTypeSection];
				NSString *detail = [NSString stringWithFormat:format, group];
				self.tableViewCellAggregateGroupBy.detailTextLabel.text = detail;
				break;
				
			}
			case MTAggregateGroupByTypeReport: {
				
				NSString *detailText = [RptqDocumentElementAggregate newStringDisplayForGroupByType: MTAggregateGroupByTypeReport];
				self.tableViewCellAggregateGroupBy.detailTextLabel.text = detailText;
				break;
				
			}
			case MTAggregateGroupByTypePage: {
				
				NSString *detailText = [RptqDocumentElementAggregate newStringDisplayForGroupByType: MTAggregateGroupByTypePage];
				self.tableViewCellAggregateGroupBy.detailTextLabel.text = detailText;
				break;
				
			}
			default:
				self.tableViewCellAggregateGroupBy.detailTextLabel.text = @"";
				break;
		}
		
		
	} else if ([action.identifier isEqualToString:@"MTSegueAggregateFieldSave"]) {
		
		MADQueryChooseFieldController *dynamicFieldController = action.sourceViewController;
		self.fieldObjectID = dynamicFieldController.queryFieldID;
		
		NSString *formatString = NSLocalizedString(@"Field: %@", @"Field: %@");
		RptqQueryField *queryField = (RptqQueryField *)[self.document.storeContext objectForEntity:NSStringFromClass([RptqQueryField class]) identifier:self.fieldObjectID];
		NSString *display = [queryField display];
		NSString *detailtext = [[NSString alloc] initWithFormat:formatString, display];
		_tableViewCellAggregateInput.detailTextLabel.text = detailtext;
		
	}
	
	if (aggregateFunctionType != MTAggregateFunctionTypeNotSet) {
		self.aggregateFunctionType = aggregateFunctionType;
		NSString *functionName = [RptqDocumentElementAggregate newStringDisplayForType:aggregateFunctionType];
		self.tableViewCellAggrageFunction.detailTextLabel.text = [functionName stringByAppendingString:@"()"];
	}
	
	[self updateDisplay];
}

//- (BOOL)canPerformUnwindSegueAction:(SEL)action
//				 fromViewController:(UIViewController *)fromViewController
//							 sender:(nullable id)sender {
//	return self.delegate == nil;
//}
/*
- (UIViewController *)viewControllerForUnwindSegueAction:(SEL)action
									  fromViewController:(UIViewController *)fromViewController
											  sender:(nullable id)sender {
	__strong UIViewController *vc = self.unwindViewController;
	return vc ? vc :
	[super viewControllerForUnwindSegueAction: action
						   fromViewController: fromViewController
								   withSender: sender];
}
*/

- (void)updateDisplay {
	
	[self updateField];
	[self updateFunctionType];
	[self updateGroupType];
	
	id <MTViewControllerAggregateDelegate> aggregateDelegate;
	aggregateDelegate = _aggregateDelegate;
	if (aggregateDelegate) {

		[aggregateDelegate didUpdateggregateFunctionWithType: self.aggregateFunctionType
												   inputType: MTAggregateFunctionInputTypeField
												 inputObject: self.fieldObjectID
												   groupType: self.aggregateGroupByType
												 groupNumber: self.groupTypeSectionNumber];
	}
	self.navigationItem.rightBarButtonItem.enabled = self.fieldObjectID != 0;
}

- (void)updateField {
	if (self.fieldObjectID != 0) {
		RptqQueryField *fieldObject = (RptqQueryField *)[self.document.storeContext objectForEntity:NSStringFromClass([RptqQueryField class]) identifier:self.fieldObjectID];
		self.tableViewCellAggregateInput.detailTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Field: %@", @"Field: %@"), [fieldObject display]];
	}
}

- (void)updateFunctionType {
	self.tableViewCellAggrageFunction.detailTextLabel.text = [[RptqDocumentElementAggregate newStringDisplayForType:self.aggregateFunctionType] stringByAppendingString:@"(x)"];
}

- (void)updateGroupType {
	switch (self.aggregateGroupByType) {
		case MTAggregateGroupByTypeSection: {
			NSString *format = [RptqDocumentElementAggregate newStringDisplayForGroupByType: MTAggregateGroupByTypeSection];
			self.tableViewCellAggregateGroupBy.detailTextLabel.text = [NSString stringWithFormat:format, self.groupTypeSectionNumber];
			break;
			
		}
		case MTAggregateGroupByTypeReport: {
			self.tableViewCellAggregateGroupBy.detailTextLabel.text = [RptqDocumentElementAggregate newStringDisplayForGroupByType: MTAggregateGroupByTypeReport];
			break;
			
		}
		case MTAggregateGroupByTypePage: {
			self.tableViewCellAggregateGroupBy.detailTextLabel.text = [RptqDocumentElementAggregate newStringDisplayForGroupByType: MTAggregateGroupByTypePage];
			break;
			
		}
		default:
			self.tableViewCellAggregateGroupBy.detailTextLabel.text = @"";
			break;
	}
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	
	MADocument *document = _document;
	if ([segue.identifier isEqualToString:@"MTSegueNewDocumentObjectAggregateLabelSaveIdentifer"]) {

	} else if ([segue.identifier isEqualToString:@"MTSegueAggregateFunctionChooser"]) {
	
		MTAggregateFunctionsViewController *destinationViewController = segue.destinationViewController;
		destinationViewController.functionDelegate = self;
		destinationViewController.selectedFunctionType = self.aggregateFunctionType;

	} else if ([segue.identifier isEqualToString:@"MTSegueGroupByPush"]) {
	
		MADGroupByViewController *destinationViewController = segue.destinationViewController;
		destinationViewController.delegate = self;
		destinationViewController.document = document;
		[destinationViewController selectGroupType: _aggregateGroupByType withSectionNumber: _groupTypeSectionNumber];
		
	} else if ([segue.identifier isEqualToString:@"MADSegueAggregateFunctionField"]) {
	
		MADQueryChooseFieldController *destinationViewController = segue.destinationViewController;
		destinationViewController.document = document;
		destinationViewController.delegate = self;
	}

}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	if (self) {
		[self setEditmode:NO];
	}
	return self;
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}

- (void)setAggregateObjectToEdit:(RptqDocumentElementAggregate *)aggregateDocumentObject {
	self.aggregateFunctionType = aggregateDocumentObject.functionType;
	self.aggregateGroupByType = aggregateDocumentObject.groupType;
	self.groupTypeSectionNumber = aggregateDocumentObject.groupNumber;
	self.fieldObjectID = aggregateDocumentObject.aggregateField.identifier;
	self.editmode = YES;
}
- (IBAction)save:(id)sender {
	[self performSegueWithIdentifier:@"MTSegueNewDocumentObjectAggregateLabelSaveIdentifer" sender:sender];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
	[super viewDidLoad];
	self.navigationItem.leftItemsSupplementBackButton = YES;
	self.navigationItem.hidesBackButton = NO;
	
	MADLabelTitle *titleView = [[MADLabelTitle alloc] initWithFrame:CGRectZero];
	titleView.text = NSLocalizedString(@"Aggregate Function", @"Title of form to create a non changing text label document object.");
	self.navigationItem.titleView = titleView;

}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	if (self.editmode) {
		[self setEditmode:NO];
	}
	[self updateDisplay];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}

#pragma mark -
#pragma mark Table View Delegate Protocol

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
