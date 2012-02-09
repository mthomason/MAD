//
//  UITableViewControllerFieldOrCustomValue.h
//  TheReportViewer
//
//  Created by Michael Thomason on 2/4/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RptqField.h"
#import "UITableViewControllerChooseField.h"

@class UITableViewControllerFieldOrCustomValue;

@protocol UITableViewControllerFieldOrCustomValueDelegate
- (void)uITableViewControllerFieldOrCustomValueDidFinish:(UITableViewControllerFieldOrCustomValue *)controller;
- (void)uITableViewControllerFieldOrCustomValueDidAddField:(RptqField *)field;
- (void)uITableViewControllerFieldOrCustomValueDidAddValue:(id)value;
@end

@interface UITableViewControllerFieldOrCustomValue : UITableViewControllerChooseField
    <UITableViewDataSource, UITableViewDelegate>

@property (assign, nonatomic) IBOutlet id <UITableViewControllerFieldOrCustomValueDelegate> delegate;

@property (retain, nonatomic) IBOutlet UISegmentedControl *segmentedControlDisplayType;

- (IBAction)segmentedControlValueChanged:(id)sender;

@end