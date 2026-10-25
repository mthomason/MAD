//
//  MTAggregateFunctionsViewController.h
//  Reports
//
//  Created by Michael Thomason on 3/25/13.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_MTAggregateFunctionsViewController_h
#define Reports_MTAggregateFunctionsViewController_h

#import <UIKit/UITableViewController.h>
#import <MAD/MADAggregateFunctionType.h>

extern NSString * const MTAggregateFunctionsViewControllerIdentifier;

@protocol MADAggregateFunctionsViewControllerDelegate;

@interface MTAggregateFunctionsViewController : UITableViewController

	@property (nonatomic, weak) NSObject <MADAggregateFunctionsViewControllerDelegate> *functionDelegate;
	@property (nonatomic, readonly) MTAggregateFunctionType selectedFunctionType;

	- (void)setSelectedFunctionType:(MTAggregateFunctionType)selectedFunctionType;

@end

#endif
