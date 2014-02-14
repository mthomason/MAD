//
//  MTDocumentObjectNewAggregateViewController.h
//  Reports
//
//  Created by Michael Thomason on 3/25/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "MTAggregateFunctionsViewController.h"

extern NSString * const MTDocumentObjectNewAggregateViewControllerIdentifier;
extern NSString * const MTDocumentObjectNewAggregateNavigationControllerIdentifier;
extern NSString * const MTIdentifierSegueDocumentObjectEditAggregate;

@protocol MTViewControllerAggregateDelegate
- (void)didUpdateggregateFunctionWithType:(MTAggregateFunctionType)functionType
                                inputType:(MTAggregateFunctionInputType)inputType
                              inputObject:(NSManagedObject *)inputObject
                                groupType:(MTAggregateGroupByType)groupType
                              groupNumber:(NSNumber *)groupNumber;
@end

@interface MTDocumentObjectNewAggregateViewController : UITableViewController
    <UITableViewDelegate>

@property (nonatomic, assign) id <MTViewControllerAggregateDelegate> delegate;

@property (nonatomic, retain) IBOutlet UITableViewCell *tableViewCellAggrageFunction;
@property (nonatomic, retain) IBOutlet UITableViewCell *tableViewCellAggregateInput;
@property (nonatomic, retain) IBOutlet UITableViewCell *tableViewCellAggregateGroupBy;

@property (nonatomic, assign) MTAggregateFunctionType aggregateFunctionType;
@property (nonatomic, assign) MTAggregateGroupByType aggregateGroupByType;
@property (nonatomic, assign) NSInteger groupTypeSectionNumber;
@property (nonatomic, retain) NSManagedObjectID *fieldObjectId;
@property (nonatomic, retain) RptqQueryField *fieldObject;

@property (nonatomic, assign) BOOL editmode;

- (void)setAggregateObjectToEdit:(RptqDocumentObjectAggregate *)aggregateDocumentObject;

@end
