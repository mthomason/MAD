//
//  UITableViewControllerFieldOrCustomValue.h
//  Reports
//
//  Created by Michael Thomason on 2/4/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_UITableViewControllerFieldOrCustomValue_h
#define Reports_UITableViewControllerFieldOrCustomValue_h

#import <UIKit/UIKit.h>
#import "MTQueryBuilderChooseFieldViewController.h"

@class UITableViewControllerFieldOrCustomValue;

@interface UITableViewControllerFieldOrCustomValue : MTQueryBuilderChooseFieldViewController
    <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, retain) IBOutlet UISegmentedControl *segmentedControlDisplayType;

- (IBAction)segmentedControlValueChanged:(id)sender;

@end

#endif
