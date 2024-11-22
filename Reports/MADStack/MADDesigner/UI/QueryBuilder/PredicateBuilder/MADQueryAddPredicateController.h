//
//  UITableViewControllerSchemaAddPredicate.h
//  Reports
//
//  Created by Michael Thomason on 2/4/12.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_MADQueryAddPredicateController_h
#define Reports_MADQueryAddPredicateController_h

#import <UIKit/UITableViewController.h>
#import <MAD/MADPredicateOperator.h>

#import <MADAPI/MADViewControllerStandardProtocol.h>
#import "MADQueryValueFromFieldControllerDelegate.h"

#import "MADTableViewControllerOpperatorsDelegate.h"

#import "MADQueryChooseFieldProtocol.h"

typedef NS_ENUM(NSUInteger, MNSPredicatePart) {
	MNSPredicateLeft = 0,
	MNSPredicateCenter,
	MNSPredicateRight,
	MNSPredicateNone
};

@protocol MADQueryAddPredicateProtocol;

@class MADocument;

@interface MADQueryAddPredicateController : UITableViewController
	<UITableViewDelegate,
		MADTableViewControllerOpperatorsDelegate,
		MADQueryChooseFieldProtocol,
		MADQueryValueFromFieldControllerDelegate>


	@property (nonatomic, weak)     IBOutlet id <MADQueryAddPredicateProtocol,
													MADViewControllerStandardProtocol> queryPredicateDelegate;
	@property (nonatomic, weak)     MADocument *document;

	@property (nonatomic, assign)   MNSPredicatePart currentlyEditingPart;
	@property (nonatomic, assign)   MADPredicateOperator predicateOperator;

	@property (nonatomic, weak)     IBOutlet UITableViewCell *tableViewCellLeftSide;
	@property (nonatomic, weak)     IBOutlet UITableViewCell *tableViewCellRightSide;
	@property (nonatomic, weak)     IBOutlet UITableViewCell *tableViewCellOperator;

	@property (nonatomic, copy)     NSString *leftValue;
	@property (nonatomic, copy)     NSString *rightValue;
	@property (nonatomic, strong)   NSManagedObjectID /* RptqQueryField */ *fieldLeftID;
	@property (nonatomic, strong)   NSManagedObjectID /* RptqQueryField */ *fieldRightID;

	- (IBAction)save:(id)sender;
	- (IBAction)cancel:(id)sender;

@end

#endif
