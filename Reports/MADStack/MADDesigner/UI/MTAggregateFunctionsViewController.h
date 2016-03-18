//
//  MTAggregateFunctionsViewController.h
//  Reports
//
//  Created by Michael Thomason on 3/25/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTAggregateFunctionsViewController_h
#define Reports_MTAggregateFunctionsViewController_h

#import "MADViewController.h"
#import <MAD/RptqDocumentObjectAggregate+Extras.h>

extern NSString * const MTAggregateFunctionsViewControllerIdentifier;

@protocol MTAggregateFunctionsViewControllerDelegate

    - (void)didSelectFunction:(MTAggregateFunctionType)functionType;

@end

@interface MTAggregateFunctionsViewController : MADTableViewController

    @property (nonatomic, weak) id <MTAggregateFunctionsViewControllerDelegate> delegate;
    @property (nonatomic, readonly) MTAggregateFunctionType selectedFunctionType;

    - (void)setSelectedFunctionType:(MTAggregateFunctionType)selectedFunctionType;

@end

#endif
