//
//  UITableViewControllerLinkBuilder.m
//  Reports
//
//  Created by Michael Thomason on 1/26/12.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADQueryLinkBuilderController.h"


#import <UIKit/UIStoryboardSegue.h>
#import <UIKit/UINavigationController.h>
#import <UIKit/UINavigationBar.h>
#import <UIKit/UILabel.h>

#import <MAD/MADocument.h>
#import <MAD/RptqStoreContext.h>

#import <MAD/RptqDocument.h>
#import <MAD/RptqDocument+Extras.h>

#import <MAD/RptqQueryTable.h>

#import <MAD/RptqQueryField.h>
#import <MAD/RptqQueryField+Extras.h>

#import <MAD/RptqQueryLinks.h>
#import <MAD/RptqQueryLinks+Extras.h>

#import "MADQueryChooseFieldController.h"
#import "MADQueryAddLinkJoinTypeController.h"

@interface MADQueryLinkBuilderController ()

	@property (nonatomic, assign) int64_t /* RptqQueryTable */firstTableID;
	@property (nonatomic, assign) int64_t /* RptqQueryTable */secondTableID;

	@property (nonatomic, assign) int64_t /* RptqQueryField */firstFieldID;
	@property (nonatomic, assign) int64_t /* RptqQueryField */secondFieldID;

	@property (nonatomic, strong) IBOutlet UILabel *labelRightField;

@end

@implementation MADQueryLinkBuilderController

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	return self;
}

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
	[super viewDidLoad];
	[self setJoinType:MADLinkTypeLeftOuterJoin];
	self.currentlyEditingPart = MADLinkNone;
	[self updateRightLabelState];
	[self updateSaveButtonState];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

	if ([segue.identifier isEqualToString:@"showSelectJoinType"]) {

		if ([segue.destinationViewController isKindOfClass:
										[MADQueryAddLinkJoinTypeController class]]) {
			[self setupJoinController:segue.destinationViewController];
		}
		
	} else {
		
		if ([segue.identifier isEqualToString:@"showSelectLinkTableFieldOne"]) {
			
			self.currentlyEditingPart = MADLinkLeft;
			[self setupFieldController2:segue.destinationViewController];

		} else if ([segue.identifier isEqualToString:@"showSelectLinkTableFieldTwo"]) {
			
			self.currentlyEditingPart = MADLinkRight;
			[self setupFieldController1:segue.destinationViewController];
			
		}
	}
}

#pragma mark -
#pragma mark Actions

- (IBAction)save:(id)sender {
	if (self.firstFieldID && self.secondFieldID) {
		
		id <MADQueryBuilderLinkBuilderDelegate, MADViewControllerStandardProtocol> queryLinkDelegate;
		queryLinkDelegate = self.queryLinkDelegate;
		
		MADocument *document = self.document;
		RptqStoreContext *managedObjectContext = document.storeContext;
		
		
		
		RptqQueryLinks *link;
		RptqQueryField *firstField = (RptqQueryField *)[managedObjectContext objectForEntity:NSStringFromClass([RptqQueryField class]) identifier:self.firstFieldID];
		RptqQueryField *secondField = (RptqQueryField *)[managedObjectContext objectForEntity:NSStringFromClass([RptqQueryField class]) identifier:self.secondFieldID];
		link = [RptqQueryLinks newQueryLinksWithLeftField: firstField
											   rightField: secondField
												 joinType: self.linkType
									 managedObjectContext: managedObjectContext];
		[document.activeDocumentModel addQueryLink: link];
		[document saveContext];

		[queryLinkDelegate viewController: self addedQueryLink: link.identifier];
	} else {
		[self cancel: sender];
	}
}

- (IBAction)cancel:(id)sender {
	[self.queryLinkDelegate viewControllerDidCancel:self];
}

#pragma mark -
#pragma mark Delegate callbacks

- (MADLinkType)initalLinktype {
	return self.linkType;
}

- (void)tableViewControllerChooseFieldDidFinish: (MADQueryChooseFieldController *)controller
									withFieldID: (int64_t)fieldID {
	
	RptqStoreContext *context = self.document.storeContext;
	RptqQueryField *queryField = (RptqQueryField *)[context objectForEntity:NSStringFromClass([RptqQueryField class]) identifier:fieldID];
	
	[self.navigationController popToViewController: self animated: YES];
	
	RptqQueryTable *queryTable = queryField.inQueryTable;
	NSString *tableFieldName = [queryField toString];
	switch (self.currentlyEditingPart) {
		case MADLinkLeft: {

			self.tableViewCellTableFieldOne.detailTextLabel.text = tableFieldName.localizedLowercaseString;
			self.firstTableID = queryTable.identifier;
			self.firstFieldID = queryField.identifier;
			
			[self updateRightLabelState];

			NSString *required = NSLocalizedString(@"Required",
												   @"Shows that this field is required.");
			required = required.lowercaseString;
			self.tableViewCellTableFieldTwo.detailTextLabel.text = required;
			self.tableViewCellTableFieldTwo.accessoryType =
													UITableViewCellAccessoryDisclosureIndicator;
			break;
		}
		case MADLinkRight: {
			self.tableViewCellTableFieldTwo.detailTextLabel.text = tableFieldName.localizedLowercaseString;
			self.secondTableID = queryTable.identifier;
			self.secondFieldID = queryField.identifier;
			break;
		}
		default:
			break;
	}
	[self updateSaveButtonState];
}

- (void)viewController:(UIViewController *)viewController addLinkJoinType:(MADLinkType)result {
	[self setJoinType:result];
	[self.navigationController popToViewController: self animated: YES];
}

#pragma mark -
#pragma mark Helpers

- (void)setupJoinController:(MADQueryAddLinkJoinTypeController *)controller {
	controller.delegate = self;
	controller.document = self.document;
}

- (void)setupFieldController1:(MADQueryChooseFieldController *)controller {
	[self setupFieldController:controller excludeTable:self.firstTableID];
}

- (void)setupFieldController2:(MADQueryChooseFieldController *)controller {
	[self setupFieldController:controller excludeTable:self.secondTableID];
}

- (void)setupFieldController:(MADQueryChooseFieldController *)controller
				excludeTable:(int64_t)excludeTableID {
	if (controller == nil) return;
	
	MADocument *document = self.document;
	controller.delegate = self;
	controller.document = document;

	if (excludeTableID != 0) {
		RptqStoreContext *moc = document.storeContext;
		RptqQueryTable *excludeTable = (RptqQueryTable *)[moc objectForEntity:NSStringFromClass([RptqQueryTable class]) identifier:excludeTableID];
		NSString *alias = [excludeTable.alias copy];
		NSArray <NSString *> *excludeTables = alias != nil ?
										[[NSArray alloc] initWithObjects:alias, nil] :
										[[NSArray alloc] init];
		controller.excludeTables = excludeTables;
	} else {
		NSArray *excludeTables = [[NSArray alloc] init];
		controller.excludeTables = excludeTables;
	}
	
}

#pragma mark -
#pragma mark Helper functions

- (void)setJoinType:(MADLinkType)type {
	NSString *linkName = [RptqQueryLinks newLocalizedNameForLinkType:type];
	self.tableViewCellJoinType.detailTextLabel.text = linkName.lowercaseString;
	self.linkType = type;
}

- (BOOL)firstFieldSet {
	return self.firstFieldID != 0;
}

- (BOOL)secondFieldSet {
	return self.secondFieldID != 0 && self.firstFieldID != self.secondFieldID;
}

- (void)updateRightLabelState {
	BOOL enabled = [self firstFieldSet];
	self.tableViewCellTableFieldTwo.userInteractionEnabled = enabled;
	self.tableViewCellTableFieldTwo.textLabel.enabled = enabled;
	self.tableViewCellTableFieldTwo.detailTextLabel.enabled = enabled;
	self.labelRightField.enabled = enabled;
	self.labelRightField.textColor = enabled ? [UIColor blackColor] : [UIColor darkTextColor];
}

- (void)updateSaveButtonState {
	BOOL enabled = [self firstFieldSet] && self.secondFieldID;
	self.navigationItem.rightBarButtonItem.enabled = enabled;
}

@end
