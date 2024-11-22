//
//  MADQueryLinkBuilderController.h
//  Reports
//
//  Created by Michael Thomason on 1/26/12.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_MTQueryBuilderLinkBuilderViewController_h
#define Reports_MTQueryBuilderLinkBuilderViewController_h

#import <UIKit/UITableViewController.h>
#import "MADQueryBuilderAddLinkJoinTypeDelegate.h"
#import "MADQueryChooseFieldProtocol.h"
#import <MADAPI/MADViewControllerStandardProtocol.h>

#import "MADLinkPart.h"

@class MADQueryLinkBuilderController, RptqQueryLinks;

@protocol MADQueryBuilderLinkBuilderDelegate
	- (void)viewController:(MADQueryLinkBuilderController *)controller
			addedQueryLink:(NSManagedObjectID *)linkID;
@end

@interface MADQueryLinkBuilderController : UITableViewController
	<UITableViewDataSource,
		UITableViewDelegate,
		MADQueryBuilderAddLinkJoinTypeDelegate,
		MADQueryChooseFieldProtocol>

	@property (nonatomic, weak) id <MADQueryBuilderLinkBuilderDelegate, MADViewControllerStandardProtocol> queryLinkDelegate;
	@property (nonatomic, weak) MADocument *document;

	@property (nonatomic, weak) IBOutlet UITableViewCell *tableViewCellTableFieldOne;
	@property (nonatomic, weak) IBOutlet UITableViewCell *tableViewCellJoinType;
	@property (nonatomic, weak) IBOutlet UITableViewCell *tableViewCellTableFieldTwo;

	@property (nonatomic, assign) MADLinkPart currentlyEditingPart;
	@property (nonatomic, assign) MADLinkType linkType;

	- (IBAction)save:(id)sender;
	- (IBAction)cancel:(id)sender;

@end

#endif
