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
#import "AppDelegate.h"
#import "MTSettingsViewController.h"
#import "MTReportDesignerFontSelectorViewController.h"
#import "MTReportDesignerFontSettingsViewController.h"
#import "MTReportDesignerObjectSelectorViewController.h"
#import "MTReportViewerViewController.h"
#import "MTCollectionViewCellElement.h"
#import "UICollectionView+Extras.h"
#import "UIView+NSObjectIdTag.h"
#import "RptqDocumentObjectLabelDataField+Extras.h"
#import "UICollectionReusableView+Reuse.h"
#import "MTCollectionReuseableViewDefault.h"
#import "MTCollectionReusableViewFloatingLabel.h"
#import "MTElementView.h"
#import "MTFont.h"
#import "MTReportDesignerSectionViewLayoutLiquid.h"
#import "MTReportDesignerToolBoxViewController.h"
#import "MTRulerView.h"
#import "MTDocumentSectionView.h"
#import "UIGestureRecognizer+AnchorPoint.h"
#import "UIDevice+Hack.h"
#import "MTReportViewerPrintPageRenderer.h"
#import "MTReportDesignerSectionLayoutSettingsViewController.h"
#import "MTReportDesignerSectionBackgroundView.h"
#import "NSManagedObject+Extras.h"

@interface MTReportDesignerViewController : MTViewController
    <UITableViewDataSource,
        UIPopoverControllerDelegate,
        UITableViewDelegate,
        UIPopoverControllerDelegate,
        UICollectionViewDataSource,
        UICollectionViewDelegate,
        UICollectionViewDelegateFlowLayout,
        UIGestureRecognizerDelegate,
        UINavigationBarDelegate,
        UIScrollViewDelegate,
        MTReportDesignerToolBoxDelegate,
        MTElementViewDelegate,
        MTCollectionViewCellElementDelegate,
        MTReportDesignerSectionViewLayoutLiquidDelegate,
        MTReportDesignerObjectSelectorDelegate,
        MUIViewControllerProtocol,
        MTDocumentSectionViewDelegate,
        MTReportDesignerSectionLayoutSettingsDelegate>

- (IBAction)doneReports:(id)sender;
- (void)openReport:(NSURL *)url;
- (void)openTemplate:(NSURL *)url;
- (IBAction)done:(id)sender;
- (IBAction)info:(id)sender;
- (IBAction)showObjects:(id)sender;
- (IBAction)showSettings:(id)sender;

@end

#endif
