//
//  UITableViewControllerFieldOrCustomValue.h
//  Reports
//
//  Created by Michael Thomason on 2/4/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RptqField.h"
#import "MTQueryBuilderChooseField.h"

@class UITableViewControllerFieldOrCustomValue;

@interface UITableViewControllerFieldOrCustomValue : MTQueryBuilderChooseField
    <UITableViewDataSource, UITableViewDelegate>

@property (retain, nonatomic) IBOutlet UISegmentedControl *segmentedControlDisplayType;

- (IBAction)segmentedControlValueChanged:(id)sender;

@end