//
//  UIViewControllerObjectSelector.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/15/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MUIViewController.h"
#import "UITableViewControllerChooseField.h"

typedef enum {
	MNSSegmentedControlOptionsData = 0,
	MNSSegmentedControlOptionsObjects = 1,
	MNSSegmentedControlOptionsMedia = 2,
} MNSSegmentedControlOptions;

@protocol UIViewControllerObjectSelectorDelegate <MUIViewControllerDelegate>
- (void)didSelectDataField:(RptqField *)field;
@end

@interface UIViewControllerObjectSelector : MUIViewController
    <UITableViewControllerChooseFieldDelegate,
        UINavigationControllerDelegate,
        UIImagePickerControllerDelegate>

@property (assign, nonatomic) IBOutlet id <UIViewControllerObjectSelectorDelegate> objectSelectorDelegate;
@property (retain, nonatomic) IBOutlet UISegmentedControl *segmentedControlSelectorType;
@property (retain, nonatomic) IBOutlet UIView *containerView;
@property (retain, nonatomic) IBOutlet UIToolbar *toolbarMain;
@property (retain, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (retain, nonatomic) IBOutlet UINavigationItem *navigationItemMain;

- (IBAction)segmentedControlSelectorTypeValueChanged:(id)sender;
- (IBAction)done:(id)sender;

- (void)showObjectSelector;

@end