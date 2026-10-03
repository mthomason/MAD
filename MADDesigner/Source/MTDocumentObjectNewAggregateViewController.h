//
//  MTDocumentObjectNewAggregateViewController.h
//  Reports
//
//  Created by Michael Thomason on 3/25/13.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_MTDocumentObjectNewAggregateViewController_h
#define Reports_MTDocumentObjectNewAggregateViewController_h

#import <UIKit/UITableViewController.h>
#import <UIKit/UITableView.h>

#import <MAD/MADAggregateFunctionType.h>
#import <MAD/MADAggregateFunctionInputType.h>
#import <MAD/MADAggregateFunctionGroupByType.h>

#import "MADUnwindProtocol.h"

@class NSManagedObject, NSManagedObjectID, MADocument, RptqQueryField, RptqDocumentElementAggregate;

@protocol MTViewControllerAggregateDelegate

	- (void)didUpdateggregateFunctionWithType:(MTAggregateFunctionType)functionType
									inputType:(MTAggregateFunctionInputType)inputType
								  inputObject:(int64_t)objectID
									groupType:(MTAggregateGroupByType)groupType
								  groupNumber:(int32_t)groupNumber;

@end

@interface MTDocumentObjectNewAggregateViewController : UITableViewController <MADUnwindProtocol, UITableViewDelegate>

	@property (nonatomic, weak) id <MTViewControllerAggregateDelegate> aggregateDelegate;
	@property (nonatomic, weak) MADocument *document;

	@property (nonatomic, weak) IBOutlet UITableViewCell *tableViewCellAggrageFunction;
	@property (nonatomic, weak) IBOutlet UITableViewCell *tableViewCellAggregateInput;
	@property (nonatomic, weak) IBOutlet UITableViewCell *tableViewCellAggregateGroupBy;

	@property (nonatomic, assign) MTAggregateFunctionType aggregateFunctionType;
	@property (nonatomic, assign) MTAggregateGroupByType aggregateGroupByType;
	@property (nonatomic, assign) int32_t groupTypeSectionNumber;
	@property (nonatomic, assign) int64_t fieldObjectID;

	@property (nonatomic, assign) BOOL editmode;

	- (void)setAggregateObjectToEdit:(RptqDocumentElementAggregate *)aggregateDocumentObject;

@end

#endif
