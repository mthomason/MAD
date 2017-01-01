//
//  MTDocumentObjectNewAggregateViewController.h
//  Reports
//
//  Created by Michael Thomason on 3/25/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTDocumentObjectNewAggregateViewController_h
#define Reports_MTDocumentObjectNewAggregateViewController_h

#import <UIKit/UITableViewController.h>
#import "MTUnwindProtocol.h"
#import <UIKit/UITableView.h>

#import <MAD/MADAggregateFunctionType.h>
#import <MAD/MADAggregateFunctionInputType.h>
#import <MAD/MADAggregateFunctionGroupByType.h>

@class NSManagedObject;
@class NSManagedObjectID;

@class MADocument;

@class RptqQueryField;
@class RptqDocumentObjectAggregate;

@protocol MTViewControllerAggregateDelegate

    - (void)didUpdateggregateFunctionWithType:(MTAggregateFunctionType)functionType
                                    inputType:(MTAggregateFunctionInputType)inputType
                                  inputObject:(NSManagedObject *)inputObject
                                    groupType:(MTAggregateGroupByType)groupType
                                  groupNumber:(NSNumber *)groupNumber;

@end

@interface MTDocumentObjectNewAggregateViewController : UITableViewController
    <MTUnwindProtocol, UITableViewDelegate>

    @property (nonatomic, weak) id <MTViewControllerAggregateDelegate> aggregateDelegate;
    @property (nonatomic, weak) MADocument *document;

    @property (nonatomic, weak) IBOutlet UITableViewCell *tableViewCellAggrageFunction;
    @property (nonatomic, weak) IBOutlet UITableViewCell *tableViewCellAggregateInput;
    @property (nonatomic, weak) IBOutlet UITableViewCell *tableViewCellAggregateGroupBy;

    @property (nonatomic, assign) MTAggregateFunctionType aggregateFunctionType;
    @property (nonatomic, assign) MTAggregateGroupByType aggregateGroupByType;
    @property (nonatomic, assign) NSInteger groupTypeSectionNumber;
    @property (nonatomic, copy) NSManagedObjectID *fieldObjectId;
    @property (nonatomic, strong) RptqQueryField *fieldObject;

    @property (nonatomic, assign) BOOL editmode;

    - (void)setAggregateObjectToEdit:(RptqDocumentObjectAggregate *)aggregateDocumentObject;

@end

#endif
