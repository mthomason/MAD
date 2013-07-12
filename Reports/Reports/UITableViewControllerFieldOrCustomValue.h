//
//  UITableViewControllerFieldOrCustomValue.h
//  Reports
//
//  Created by Michael Thomason on 2/4/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RptqDatabaseSchemaField.h"
#import "MTQueryBuilderChooseFieldViewController.h"

@class UITableViewControllerFieldOrCustomValue;

@interface UITableViewControllerFieldOrCustomValue : MTQueryBuilderChooseFieldViewController
    <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, retain) IBOutlet UISegmentedControl *segmentedControlDisplayType;

- (IBAction)segmentedControlValueChanged:(id)sender;

@end