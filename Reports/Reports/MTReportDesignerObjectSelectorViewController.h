//
//  MTReportDesignerObjectSelectorViewController.h
//  Reports
//
//  Created by Michael Thomason on 1/15/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTReportDesignerObjectSelectorViewController_h
#define Reports_MTReportDesignerObjectSelectorViewController_h

#import <UIKit/UIKit.h>
#import "MTViewController.h"
#import "MTQueryBuilderChooseFieldViewController.h"
#import "AppDelegate.h"

typedef NS_ENUM(NSUInteger, MNSSegmentedControlOptions) {
	MNSSegmentedControlOptionsData = 0,
	MNSSegmentedControlOptionsObjects = 1,
	MNSSegmentedControlOptionsMedia = 2,
};

@protocol MTReportDesignerObjectSelectorDelegate <MUIViewControllerProtocol>
- (void)insertDocumentObjectDataField:(RptqField *)field;
- (void)insertDocumentObjectNewLabel;
- (void)insertDocumentObjectNewFormula;
- (void)insertDocumentObjectNewChart;
- (void)insertDocumentObjectNewHyperlink;
- (void)viewControllerDidFinish:(id)sender;
@end

@interface MTReportDesignerObjectSelectorViewController : MTViewController
    <MTQueryBuilderChooseFieldDelegate,
        UINavigationControllerDelegate,
        UIImagePickerControllerDelegate,
        UICollectionViewDataSource,
        UICollectionViewDelegateFlowLayout>

@property (assign, nonatomic) IBOutlet id <MTReportDesignerObjectSelectorDelegate> objectSelectorDelegate;
@property (retain, nonatomic) IBOutlet UISegmentedControl *segmentedControlSelectorType;
@property (retain, nonatomic) IBOutlet UIView *containerView;
@property (retain, nonatomic) IBOutlet UIToolbar *toolbarMain;
@property (retain, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (retain, nonatomic) IBOutlet UINavigationItem *navigationItemMain;

- (IBAction)segmentedControlSelectorTypeValueChanged:(id)sender;
- (IBAction)done:(id)sender;

- (void)showObjectSelector;

@end

#endif
