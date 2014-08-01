//
//  MTDocumentObjectNewAggregateViewController.h
//  Reports
//
//  Created by Michael Thomason on 3/25/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTDocumentObjectNewAggregateViewController_h
#define Reports_MTDocumentObjectNewAggregateViewController_h

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "MTAggregateFunctionsViewController.h"
#import "Constants.h"

extern NSString * const MTDocumentObjectNewAggregateViewControllerIdentifier;
extern NSString * const MTDocumentObjectNewAggregateNavigationControllerIdentifier;
extern NSString * const MTIdentifierSegueDocumentObjectEditAggregate;

@class MAReportDocument, RptqQueryField, RptqDocumentObjectAggregate;

@protocol MTViewControllerAggregateDelegate
- (void)didUpdateggregateFunctionWithType:(MTAggregateFunctionType)functionType
                                inputType:(MTAggregateFunctionInputType)inputType
                              inputObject:(NSManagedObject *)inputObject
                                groupType:(MTAggregateGroupByType)groupType
                              groupNumber:(NSNumber *)groupNumber;
@end

@interface MTDocumentObjectNewAggregateViewController : UITableViewController
    <UITableViewDelegate>

@property (nonatomic, weak) id <MTViewControllerAggregateDelegate> delegate;
@property (nonatomic, weak) MAReportDocument *document;

@property (nonatomic, weak) IBOutlet UITableViewCell *tableViewCellAggrageFunction;
@property (nonatomic, weak) IBOutlet UITableViewCell *tableViewCellAggregateInput;
@property (nonatomic, weak) IBOutlet UITableViewCell *tableViewCellAggregateGroupBy;

@property (nonatomic, assign) MTAggregateFunctionType aggregateFunctionType;
@property (nonatomic, assign) MTAggregateGroupByType aggregateGroupByType;
@property (nonatomic, assign) NSInteger groupTypeSectionNumber;
@property (nonatomic, strong) NSManagedObjectID *fieldObjectId;
@property (nonatomic, strong) RptqQueryField *fieldObject;

@property (nonatomic, assign) BOOL editmode;

- (void)setAggregateObjectToEdit:(RptqDocumentObjectAggregate *)aggregateDocumentObject;

@end

#endif
