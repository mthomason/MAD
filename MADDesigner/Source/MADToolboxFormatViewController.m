//
//  MADToolboxFormatViewController.m
//  Reports
//
//  Created by Michael Thomason on 3/16/13.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADToolboxFormatViewController.h"
#import "MADToolboxControllerProtocol.h"
#import <MADFoundation/madlog.h>

#import <MADAPI/MADDatabase.h>
#import <MADAPI/MADDatabaseField.h>
#import <MADFoundation/MADDataType.h>
#import <MAD/RptqAlignment.h>
#import <MAD/RptqStoreContext.h>
#import <MAD/RptqNumericFormat.h>
#import <MAD/MADocument.h>
#import <MAD/RptqDocumentElement.h>
#import <MAD/RptqDocumentElement+Extras.h>
#import <MAD/RptqDocumentElementLabelDataField.h>
#import <MAD/RptqDatabaseSchemaField.h>
#import <MAD/RptqQueryField.h>
#import <MAD/RptqNumericFormat.h>
#import <MADCocoaExtensions/MADViewHelpers.h>

#import <UIKit/UIStepper.h>
#import <UIKit/UINavigationController.h>
#import <UIKit/UIFont.h>
#import <UIKit/UILabel.h>
#import <UIKit/NSAttributedString.h>


@interface MADToolboxFormatViewController () <UITableViewDelegate, MADToolboxControllerProtocol>

@property (nonatomic, strong) NSSet <NSNumber *> *userSelectedObjectIDs;

@property (nonatomic, weak) IBOutlet UITableViewCell *tableViewCellDecimals;
@property (nonatomic, weak) IBOutlet UITableViewCell *tableViewCellCurrency;
@property (nonatomic, weak) IBOutlet UITableViewCell *tableViewCellCurrencyLocation;

@property (nonatomic, weak) IBOutlet UIStepper *stepperNumberOfDecimals;
@property (nonatomic, weak) IBOutlet UILabel *labelNumberOfDecimals;
@property (nonatomic, weak) IBOutlet UILabel *labelCurrency;
@property (nonatomic, weak) IBOutlet UILabel *labelCurrencyLocal;

@property (nonatomic, weak) IBOutletCollection(UIView) NSArray *viewsToDisableNumeric;
@property (nonatomic, weak) IBOutletCollection(UIControl) NSArray *controlsToDisableNumeric;

@property (nonatomic, assign) BOOL completedInitalLayout;

@end

@implementation MADToolboxFormatViewController

#pragma mark -
#pragma mark Table View Delegate Protocol


#pragma mark - View lifecycle

- (void)viewDidLoad {
	[super viewDidLoad];
	self.completedInitalLayout = NO;
	self.labelNumberOfDecimals.textColor = [UIColor labelColor];
	self.labelCurrency.textColor = [UIColor labelColor];
	self.labelCurrencyLocal.textColor = [UIColor labelColor];
}

- (void)viewWillLayoutSubviews {
	[super viewWillLayoutSubviews];
	UIEdgeInsets safeAreaInsets;
	MADViewSafeAreaInserts(self.view, &safeAreaInsets);
	self.tableView.contentInset = UIEdgeInsetsMake(safeAreaInsets.top, CGSizeZero.width, safeAreaInsets.bottom, CGSizeZero.width);
	self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(safeAreaInsets.top, CGSizeZero.width, safeAreaInsets.bottom, CGSizeZero.width);
	if (self.completedInitalLayout == NO) {
		[self.tableView setContentOffset:CGPointMake(CGPointZero.x, -safeAreaInsets.top) animated:NO];
		self.completedInitalLayout = YES;
	}
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self.navigationController setNavigationBarHidden: NO animated: animated];
	[self updateDisplay];
	if (self.clearsBackground) {
		self.tableView.backgroundView = nil;
	}
}

- (void)setSelectedDocumentObjects:(NSSet <NSNumber *> *)objectIDs {
	
	BOOL numericTypeInSet = NO;
	NSMutableSet <NSNumber *> *keepers = [[NSMutableSet alloc] init];
	for (NSNumber *objectID in objectIDs) {
		RptqDocumentElementLabelDataField *documentObject = [RptqDocumentElementLabelDataField newDocumentElementWithIdentifier: objectID.longLongValue
																											  fromObjectContext: _document.storeContext];
		MADDataType dataType = documentObject.referencesQueryField.databaseSchemaField.dataType;
		BOOL isNumeric = [MADDatabaseField isNumeric:dataType];
		if (isNumeric) {
			numericTypeInSet = YES;
			[keepers addObject:objectID];
			break;
		}
	}
	self.userSelectedObjectIDs = keepers;
	for (UIView *view in self.viewsToDisableNumeric) {
		view.userInteractionEnabled = numericTypeInSet;
		if ([view isKindOfClass:[UIControl class]]) {
			((UIControl *)view).enabled = numericTypeInSet;
		}
	}
	[self updateDisplay];
}

- (void)updateDisplay {
	
	if (self.userSelectedObjectIDs.count == 0) {
		
		self.tableViewCellCurrency.selectionStyle = UITableViewCellSelectionStyleNone;
		self.tableViewCellCurrency.accessoryType = UITableViewCellAccessoryNone;
		self.labelNumberOfDecimals.text = NSLocalizedString(@"Decimals", "Decimals");
		
	} else {
		
		(self.tableViewCellCurrency).selectionStyle = UITableViewCellSelectionStyleBlue;
		
		UITableViewCellAccessoryType accessoryType = UITableViewCellAccessoryNone;
		
		MADocument *document = _document;
		NSSet <NSNumber *> *userSelectedObjectIDs = self.userSelectedObjectIDs;
		for (NSNumber *identifier in userSelectedObjectIDs) {
			
			RptqDocumentElement *element = [RptqDocumentElement newDocumentElementWithIdentifier: identifier.longLongValue
																			   fromObjectContext: document.storeContext];
			if (element.numericFormat.enabled) {
				accessoryType = UITableViewCellAccessoryCheckmark;
			}
		}
		
		(self.tableViewCellCurrency).accessoryType = accessoryType;
		
		if ((self.userSelectedObjectIDs).count == 1) {
			RptqDocumentElement *element = [RptqDocumentElement newDocumentElementWithIdentifier: [userSelectedObjectIDs.anyObject longLongValue]
																			   fromObjectContext: document.storeContext];
			(self.labelNumberOfDecimals).attributedText = [self decimalsStringForNumberOfDecimals:element.numericFormat.decimalCount];
			(self.stepperNumberOfDecimals).value = (double)element.numericFormat.decimalCount;
			
		} else {

			BOOL allTheSame = self.userSelectedObjectIDs.count > 0;
			NSInteger lastInteger = 0;
			NSUInteger counter = 0;
			for (NSNumber *identifier in self.userSelectedObjectIDs) {
				RptqDocumentElement *element = [RptqDocumentElement newDocumentElementWithIdentifier: identifier.longLongValue
																				   fromObjectContext: document.storeContext];
				if (counter > 0 && lastInteger != element.numericFormat.decimalCount) {
					allTheSame = NO;
				}
				lastInteger = element.numericFormat.decimalCount;
				counter++;
			}
			if (allTheSame) {
				self.labelNumberOfDecimals.attributedText = [self decimalsStringForNumberOfDecimals:lastInteger];
			} else {
				NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:@""];
				self.labelNumberOfDecimals.attributedText = attributedString;
			}
			self.stepperNumberOfDecimals.value = (double)lastInteger;
		}

	}
}

#pragma mark -
#pragma mark Table View Delegate Protocol

- (void)emptySelector:(id)sender {}

- (IBAction)controlValueChanged:(id)sender {
	id valueThatChanged = nil;
	
	if ([sender isEqual:self.stepperNumberOfDecimals]) {
		valueThatChanged = [[NSNumber alloc] initWithDouble:(self.stepperNumberOfDecimals).value];
		(self.labelNumberOfDecimals).attributedText =
		[self decimalsStringForNumberOfDecimals:(NSInteger)[valueThatChanged floatValue]];
		
		RptqStoreContext *context = self.document.storeContext;
		for (NSNumber *identifier in self.userSelectedObjectIDs) {
			RptqDocumentElement *documentObject = [RptqDocumentElement newDocumentElementWithIdentifier: identifier.longLongValue
																					  fromObjectContext: context];
			documentObject.numericFormat.decimalCount = [valueThatChanged integerValue];
			NSError *error = NULL;
			BOOL saved = [documentObject.storeContext save:&error];
			if (!saved && error != nil) {
				os_log_error(GetDesignerLog(), "%s Error saving managed object context.", __PRETTY_FUNCTION__);
			}
		}
	}
}

- (NSAttributedString *)decimalsStringForNumberOfDecimals:(NSInteger)numberOfDecimals {
	NSMutableAttributedString *localizedAttributedMessage = [[NSMutableAttributedString alloc] initWithString: NSLocalizedString(@"Decimals", "Decimals") attributes: @{
		NSFontAttributeName : [UIFont boldSystemFontOfSize:self.labelNumberOfDecimals.font.pointSize]
	}];
	NSAttributedString *messageSuffix = [[NSAttributedString alloc] initWithString:(numberOfDecimals == -1) ? @"-" :  [@" " stringByAppendingFormat:@"%ld", (long)numberOfDecimals] attributes:@{
		NSFontAttributeName : [UIFont systemFontOfSize:self.labelNumberOfDecimals.font.pointSize]
	}];
	[localizedAttributedMessage appendAttributedString:messageSuffix];
	(self.labelNumberOfDecimals).attributedText = localizedAttributedMessage;
	return localizedAttributedMessage;
}

#pragma mark -
#pragma mark Table View Delegate Protocol

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
	cell.backgroundColor = [UIColor clearColor];
	cell.contentView.backgroundColor = [UIColor clearColor];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath { }

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	if (indexPath.row == 1 && indexPath.section == 0) {
		RptqStoreContext *context = self.document.storeContext;
		for (NSNumber *identifier in self.userSelectedObjectIDs) {
			RptqDocumentElement *documentObject = [RptqDocumentElement newDocumentElementWithIdentifier: identifier.longLongValue
																					  fromObjectContext: context];
			documentObject.numericFormat.enabled = !documentObject.numericFormat.enabled;
			(self.tableViewCellCurrency).accessoryType = documentObject.numericFormat.enabled ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
			NSError *error = NULL;
			BOOL saved = [documentObject.storeContext save:&error];
			if (!saved) {
				os_log_error(GetDesignerLog(), "%s Error saving managed object context.", __PRETTY_FUNCTION__);
				if (error != nil) {
					os_log_error(GetDesignerLog(), "%s Error saving managed object context: %@", __PRETTY_FUNCTION__, error);
				}
			}
		}
	}
}

@end
