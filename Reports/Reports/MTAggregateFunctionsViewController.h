//
//  MTAggregateFunctionsViewController.h
//  Reports
//
//  Created by Michael Thomason on 3/25/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RptqDocumentObject+Extras.h"

extern NSString * const MTAggregateFunctionsViewControllerIdentifier;

@protocol MTAggregateFunctionsViewControllerDelegate
- (void)didSelectFunction:(MTAggregateFunctionType)functionType;
@end

@interface MTAggregateFunctionsViewController : UITableViewController

@property (nonatomic, assign) id <MTAggregateFunctionsViewControllerDelegate> delegate;

- (void)setSelectedFunctionType:(MTAggregateFunctionType)selectedFunctionType;

@end
