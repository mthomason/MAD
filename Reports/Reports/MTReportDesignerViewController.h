//
//  MUIViewControllerReportDesigner.h
//  Reports
//
//  Created by Michael Thomason on 1/4/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "MTSettingsViewController.h"
#import "MTReportDesignerFontSelectorViewController.h"
#import "MTReportDesignerFontSettingsViewController.h"
#import "MTReportDesignerObjectSelectorViewController.h"
#import "MTReportViewerViewController.h"
#import "MTCollectionViewFlowLayoutDesignerSection.h"
#import "MTCollectionViewCellElement.h"
#import "UICollectionView+Extras.h"
#import "UIView+NSObjectIdTag.h"
#import "RptqDocumentObjectLabelDataField+Extras.h"
#import "UICollectionReusableView+Reuse.h"
#import "MTCollectionReuseableViewDefault.h"
#import "MTCollectionReusableViewFloatingLabel.h"
#import "MTElementView.h"
#import "MTFont.h"
#import "MTReportDesignerSectionViewLayout.h"
#import "MTReportDesignerToolBoxViewController.h"
#import "MTRulerView.h"
#import "MTDocumentSectionView.h"
#import "UIGestureRecognizer+AnchorPoint.h"

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
        MTReportDesignerSectionViewLayoutDelegate,
        MTReportDesignerObjectSelectorDelegate,
        MUIViewControllerProtocol,
        MTReportDesignerFontSettingsDelegate,
        MTReportDesignerFontSelectorDelegate,
        MTDocumentSectionViewDelegate>

- (IBAction)doneReports:(id)sender;
- (void)openReport:(NSURL *)url;
- (void)openTemplate:(NSURL *)url;
- (IBAction)done:(id)sender;
- (IBAction)info:(id)sender;
- (IBAction)showObjects:(id)sender;
- (IBAction)showSettings:(id)sender;

- (void)cut:(id)sender;
- (void)copy:(id)sender;
- (void)select:(id)sender;
- (void)selectAll:(id)sender;
- (void)paste:(id)sender;
- (void)delete:(id)sender;

@end
