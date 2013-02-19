//
//  UIViewControllerObjectSelector.h
//  Reports
//
//  Created by Michael Thomason on 1/15/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MTViewController.h"
#import "UITableViewControllerChooseField.h"
#import "AppDelegate.h"

typedef NS_ENUM(NSUInteger, MNSSegmentedControlOptions) {
	MNSSegmentedControlOptionsData = 0,
	MNSSegmentedControlOptionsObjects = 1,
	MNSSegmentedControlOptionsMedia = 2,
};

@protocol UIViewControllerObjectSelectorDelegate <MUIViewControllerDelegate>
- (void)didSelectDataField:(RptqField *)field;
- (void)viewControllerDidFinish:(id)sender;
@end

@interface MUIViewControllerObjectSelector : MTViewController
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