//
//  MUIViewControllerReportDesigner.h
//  TheReportViewer
//
//  Created by Michael Thomason on 1/4/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "UITableViewControllerSettings.h"
#import "UITableViewControllerFontSelector.h"
#import "UITableViewControllerFontSettings.h"
#import "MUIViewControllerObjectSelector.h"
#import "MTViewControllerReportViewer.h"
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
#import "MTCollectionViewLineLayout.h"
#import "UIViewControllerToolBox.h"
#import "MTViewRuler.h"
#import "MTDocumentSectionView.h"

@interface MUIViewControllerReportDesigner : MTViewController
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
        UIViewControllerToolBoxDelegate,
        MTElementViewDelegate,
        MTCollectionViewLineLayoutDelegate,
        UIViewControllerObjectSelectorDelegate,
        MUIViewControllerDelegate,
        FontSettingsTableViewControllerDelegate,
        UITableViewControllerFontSelectorDelegate,
        MTDocumentSectionViewDelegate>

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