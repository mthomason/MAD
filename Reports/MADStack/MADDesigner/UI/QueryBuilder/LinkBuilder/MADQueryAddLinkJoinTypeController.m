//
//  UIViewControllerSchemaAddLink.m
//  Reports
//
//  Created by Michael Thomason on 1/24/12.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADQueryAddLinkJoinTypeController.h"

#import <UIKit/UILabel.h>

#import "MADQueryBuilderAddLinkJoinTypeDelegate.h"

#import <MADAPI/MADDatabaseConnection.h>

#import <MAD/MADocument.h>
#import <MAD/RptqDatabaseCredentals+Extras.h>

#import <MAD/MADSQLJoinType.h>

#import <MAD/MADDatabaseConnection+Constructor.h>

@interface MADQueryAddLinkJoinTypeController ()

	@property (nonatomic, weak) IBOutlet UITableViewCell *tableViewCellEquiJoin;
	@property (nonatomic, weak) IBOutlet UITableViewCell *tableViewCellFullOuterJoin;
	@property (nonatomic, weak) IBOutlet UITableViewCell *tableViewCellNaturalJoin;

	@property (nonatomic, weak) IBOutlet UITableViewCell *tableViewCellCrossJoin;
	@property (nonatomic, weak) IBOutlet UITableViewCell *tableViewCellInnerJoin;
	@property (nonatomic, weak) IBOutlet UITableViewCell *tableViewCellLeftOuterJoin;
	@property (nonatomic, weak) IBOutlet UITableViewCell *tableViewCellRightOuterJoin;

@end

@implementation MADQueryAddLinkJoinTypeController

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
	[super viewDidLoad];
	
	NSArray <RptqDatabaseCredentals *> *connections;
	connections = [RptqDatabaseCredentals newDatabaseCredentals:self.document.managedObjectContext];
	RptqDatabaseCredentals *userCredentals = connections[0];
	NSString *databaseDriverType = userCredentals.driverID;

	UITableViewCell *tableViewCell;
	if ([databaseDriverType isEqualToString:[MADDatabaseConnection Identifier:MADDatabaseTypeMySQL]]) {

		tableViewCell = _tableViewCellEquiJoin;
		tableViewCell.userInteractionEnabled = YES;
		tableViewCell.selectionStyle = UITableViewCellSelectionStyleGray;
		tableViewCell.textLabel.enabled = YES;
		
		tableViewCell = _tableViewCellNaturalJoin;
		tableViewCell.userInteractionEnabled = YES;
		tableViewCell.selectionStyle = UITableViewCellSelectionStyleGray;
		tableViewCell.textLabel.enabled = YES;

		tableViewCell = _tableViewCellFullOuterJoin;
		tableViewCell.userInteractionEnabled = NO;
		tableViewCell.selectionStyle = UITableViewCellSelectionStyleNone;
		tableViewCell.textLabel.enabled = NO;


		
	} else if ([databaseDriverType isEqualToString:[MADDatabaseConnection Identifier:MADDatabaseTypeTDS]]) {

		tableViewCell = _tableViewCellEquiJoin;
		[tableViewCell setUserInteractionEnabled:YES];
		tableViewCell.selectionStyle = UITableViewCellSelectionStyleGray;
		[tableViewCell.textLabel setEnabled:YES];

		tableViewCell = _tableViewCellNaturalJoin;
		tableViewCell.userInteractionEnabled = NO;
		tableViewCell.selectionStyle = UITableViewCellSelectionStyleGray;
		tableViewCell.textLabel.enabled = NO;
		
	}

}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self checkLinkType:[self.delegate initalLinktype]];
}

- (void)checkLinkType:(MADLinkType)type {

	switch (type) {
		case MADLinkTypeCrossJoin:
			
			self.tableViewCellCrossJoin.accessoryType =        UITableViewCellAccessoryCheckmark;
			self.tableViewCellEquiJoin.accessoryType =         UITableViewCellAccessoryNone;
			self.tableViewCellFullOuterJoin.accessoryType =    UITableViewCellAccessoryNone;
			self.tableViewCellInnerJoin.accessoryType =        UITableViewCellAccessoryNone;
			self.tableViewCellLeftOuterJoin.accessoryType =    UITableViewCellAccessoryNone;
			self.tableViewCellNaturalJoin.accessoryType =      UITableViewCellAccessoryNone;
			self.tableViewCellRightOuterJoin.accessoryType =   UITableViewCellAccessoryNone;
			
			break;
		case MADLinkTypeEquiJoin:
			
			self.tableViewCellCrossJoin.accessoryType =        UITableViewCellAccessoryNone;
			self.tableViewCellEquiJoin.accessoryType =         UITableViewCellAccessoryCheckmark;
			self.tableViewCellFullOuterJoin.accessoryType =    UITableViewCellAccessoryNone;
			self.tableViewCellInnerJoin.accessoryType =        UITableViewCellAccessoryNone;
			self.tableViewCellLeftOuterJoin.accessoryType =    UITableViewCellAccessoryNone;
			self.tableViewCellNaturalJoin.accessoryType =      UITableViewCellAccessoryNone;
			self.tableViewCellRightOuterJoin.accessoryType =   UITableViewCellAccessoryNone;
			
			break;
		case MADLinkTypeFullOuterJoin:
			
			self.tableViewCellCrossJoin.accessoryType =        UITableViewCellAccessoryNone;
			self.tableViewCellEquiJoin.accessoryType =         UITableViewCellAccessoryNone;
			self.tableViewCellFullOuterJoin.accessoryType =    UITableViewCellAccessoryCheckmark;
			self.tableViewCellInnerJoin.accessoryType =        UITableViewCellAccessoryNone;
			self.tableViewCellLeftOuterJoin.accessoryType =    UITableViewCellAccessoryNone;
			self.tableViewCellNaturalJoin.accessoryType =      UITableViewCellAccessoryNone;
			self.tableViewCellRightOuterJoin.accessoryType =   UITableViewCellAccessoryNone;

			break;
		case MADLinkTypeInnerJoin:

			self.tableViewCellCrossJoin.accessoryType =        UITableViewCellAccessoryNone;
			self.tableViewCellEquiJoin.accessoryType =         UITableViewCellAccessoryNone;
			self.tableViewCellFullOuterJoin.accessoryType =    UITableViewCellAccessoryNone;
			self.tableViewCellInnerJoin.accessoryType =        UITableViewCellAccessoryCheckmark;
			self.tableViewCellLeftOuterJoin.accessoryType =    UITableViewCellAccessoryNone;
			self.tableViewCellNaturalJoin.accessoryType =      UITableViewCellAccessoryNone;
			self.tableViewCellRightOuterJoin.accessoryType =   UITableViewCellAccessoryNone;

			break;
		case MADLinkTypeLeftOuterJoin:
			
			self.tableViewCellCrossJoin.accessoryType =        UITableViewCellAccessoryNone;
			self.tableViewCellEquiJoin.accessoryType =         UITableViewCellAccessoryNone;
			self.tableViewCellFullOuterJoin.accessoryType =    UITableViewCellAccessoryNone;
			self.tableViewCellInnerJoin.accessoryType =        UITableViewCellAccessoryNone;
			self.tableViewCellLeftOuterJoin.accessoryType =    UITableViewCellAccessoryCheckmark;
			self.tableViewCellNaturalJoin.accessoryType =      UITableViewCellAccessoryNone;
			self.tableViewCellRightOuterJoin.accessoryType =   UITableViewCellAccessoryNone;

			break;
		case MADLinkTypeNaturalJoin:
			
			self.tableViewCellCrossJoin.accessoryType =        UITableViewCellAccessoryNone;
			self.tableViewCellEquiJoin.accessoryType =         UITableViewCellAccessoryNone;
			self.tableViewCellFullOuterJoin.accessoryType =    UITableViewCellAccessoryNone;
			self.tableViewCellInnerJoin.accessoryType =        UITableViewCellAccessoryNone;
			self.tableViewCellLeftOuterJoin.accessoryType =    UITableViewCellAccessoryNone;
			self.tableViewCellNaturalJoin.accessoryType =      UITableViewCellAccessoryCheckmark;
			self.tableViewCellRightOuterJoin.accessoryType =   UITableViewCellAccessoryNone;

			break;
		case MADLinkTypeRightOuterJoin:
			
			self.tableViewCellCrossJoin.accessoryType =        UITableViewCellAccessoryNone;
			self.tableViewCellEquiJoin.accessoryType =         UITableViewCellAccessoryNone;
			self.tableViewCellFullOuterJoin.accessoryType =    UITableViewCellAccessoryNone;
			self.tableViewCellInnerJoin.accessoryType =        UITableViewCellAccessoryNone;
			self.tableViewCellLeftOuterJoin.accessoryType =    UITableViewCellAccessoryNone;
			self.tableViewCellNaturalJoin.accessoryType =      UITableViewCellAccessoryNone;
			self.tableViewCellRightOuterJoin.accessoryType =   UITableViewCellAccessoryCheckmark;

			break;
		default:
			
			self.tableViewCellCrossJoin.accessoryType =        UITableViewCellAccessoryNone;
			self.tableViewCellEquiJoin.accessoryType =         UITableViewCellAccessoryNone;
			self.tableViewCellFullOuterJoin.accessoryType =    UITableViewCellAccessoryNone;
			self.tableViewCellInnerJoin.accessoryType =        UITableViewCellAccessoryNone;
			self.tableViewCellLeftOuterJoin.accessoryType =    UITableViewCellAccessoryNone;
			self.tableViewCellNaturalJoin.accessoryType =      UITableViewCellAccessoryNone;
			self.tableViewCellRightOuterJoin.accessoryType =   UITableViewCellAccessoryNone;
			
			break;
	}
}

#pragma mark -
#pragma mark Table View Delegate Protocol

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	MADLinkType linktype = MADLinkTypeUnknown;
	
	UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
	if ([cell.reuseIdentifier isEqualToString:MNSJoinTypeInnerJoin]) {
		linktype = MADLinkTypeInnerJoin;
		
	} else if ([cell.reuseIdentifier isEqualToString:MNSJoinTypeEquiJoin]) {
		linktype = MADLinkTypeEquiJoin;

	} else if ([cell.reuseIdentifier isEqualToString:MNSJoinTypeNaturalJoin]) {
		linktype = MADLinkTypeNaturalJoin;
	
	} else if ([cell.reuseIdentifier isEqualToString:MNSJoinTypeCrossJoin]) {
		linktype = MADLinkTypeCrossJoin;
	
	} else if ([cell.reuseIdentifier isEqualToString:MNSJoinTypeLeftOuterJoin]) {
		linktype = MADLinkTypeLeftOuterJoin;

	} else if ([cell.reuseIdentifier isEqualToString:MNSJoinTypeRightOuterJoin]) {
		linktype = MADLinkTypeRightOuterJoin;
	
	} else if ([cell.reuseIdentifier isEqualToString:MNSJoinTypeFullOuterJoin]) {
		linktype = MADLinkTypeFullOuterJoin;
	}
	
	if ((NSInteger)linktype != MADLinkTypeUnknown) {
		[self checkLinkType:linktype];
		[self.delegate viewController:self addLinkJoinType: linktype];
	}

}

@end
