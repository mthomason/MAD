//
//  MUIViewControllerReportDesigner.h
//  Reports
//
//  Created by Michael Thomason on 1/4/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTReportDesignerViewController_h
#define Reports_MTReportDesignerViewController_h

#import <UIKit/UIKit.h>
#import "MTSettingsViewController.h"
#import "MTReportDesignerObjectSelectorViewController.h"
#import "MTReportViewerController.h"
#import "MTCollectionViewCellElement.h"
#import "UICollectionReusableView+Reuse.h"
#import "MTCollectionReuseableViewDefault.h"
#import "MTElementView.h"
#import "MTReportDesignerSectionViewLayoutLiquid.h"
#import "MTReportDesignerToolBoxViewController.h"
#import "MTRulerView.h"
#import "MTDocumentSectionView.h"
#import "UIDevice+Hack.h"
#import "MTReportDesignerSectionLayoutSettingsViewController.h"
#import "MTReportDesignerSectionBackgroundView.h"
#import "NSManagedObject+Extras.h"

@interface MTReportDesignerViewController : MTViewController
    <UIPopoverControllerDelegate,
        UIPopoverControllerDelegate,
        UICollectionViewDataSource,
        UICollectionViewDelegate,
        UICollectionViewDelegateFlowLayout,
        UIGestureRecognizerDelegate,
        UINavigationControllerDelegate,
        UIScrollViewDelegate,
        UIImagePickerControllerDelegate,
        UITabBarControllerDelegate,
        UITextFieldDelegate,
        MTReportDesignerToolBoxDelegate,
        MTElementViewDelegate,
        MTCollectionViewCellElementDelegate,
        MTReportDesignerSectionViewLayoutLiquidDelegate,
        MTReportDesignerObjectSelectorDelegate,
        MTViewControllerProtocol,
        MTDocumentSectionViewDelegate,
        MTReportDesignerSectionLayoutSettingsDelegate,
        MTQueryBuilderChooseFieldDelegate>

- (IBAction)doneReports:(id)sender;
- (IBAction)done:(id)sender;
- (IBAction)info:(id)sender;
- (IBAction)showObjects:(id)sender;

@end

#endif
