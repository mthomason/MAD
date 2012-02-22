//
//  UIViewControllerObjectSelector.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/15/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UITableViewControllerChooseField.h"

typedef enum {
	MNSSegmentedControlOptionsData = 0,
	MNSSegmentedControlOptionsObjects = 1,
	MNSSegmentedControlOptionsMedia = 2,
} MNSSegmentedControlOptions;

@class UIViewControllerObjectSelector;

@protocol UIViewControllerObjectSelectorDelegate
- (void)uIViewControllerObjectSelectorFinish:(UIViewControllerObjectSelector *)controller;
@end

@interface UIViewControllerObjectSelector : UIViewController

@property (assign, nonatomic) IBOutlet id <UIViewControllerObjectSelectorDelegate> delegate;
@property (retain, nonatomic) IBOutlet UISegmentedControl *segmentedControlSelectorType;

@property (retain) UITableViewControllerChooseField *viewControllerChooseField;
@property (retain) UIViewController *viewControllerObjects;
@property (retain) UITableViewControllerChooseField *viewControllerMedia;

- (IBAction)segmentedControlSelectorTypeValueChanged:(id)sender;
- (IBAction)done:(id)sender;

- (void)showObjectSelector;

@end