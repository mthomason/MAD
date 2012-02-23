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
    <UITableViewControllerChooseFieldDelegate,
        UINavigationControllerDelegate,
        UIImagePickerControllerDelegate>

@property (assign, nonatomic) IBOutlet id <UIViewControllerObjectSelectorDelegate> delegate;

@property (retain) UIManagedDocumentQuery *managedDocumentQuery;

@property (retain, nonatomic) IBOutlet UISegmentedControl *segmentedControlSelectorType;
@property (retain, nonatomic) IBOutlet UIView *containerView;

- (IBAction)segmentedControlSelectorTypeValueChanged:(id)sender;
- (IBAction)done:(id)sender;

- (void)showObjectSelector;

@end