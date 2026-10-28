//
//  MADDesignerViewController_Private.h
//  Reports
//
//  Created by Michael Thomason on 1/4/12.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_MADDesignerViewController_Private_h
#define MAD_MADDesignerViewController_Private_h

#import "MADDesignerViewController.h"
#import "MADViewControllerBarcodeDelegate.h"
#import "MADTabBarController.h"
#import "MADRulerView.h"
#import "MADDesignerElementView.h"
#import "MADDesignerElementTextView.h"
#import "MADDesignerElementView+Constructor.h"
#import "MADDesignerSectionView.h"
#import "MADDesignerSectionLabel.h"
#import "MADDesignerElementPickerViewController.h"
#import "MADCellElement.h"
#import "UICollectionReusableView+Reuse.h"
#import "MTCollectionReuseableViewDefault.h"
#import "MADDesignerSectionLayoutLiquid.h"
#import "MADDesignerSectionLayoutController.h"
#import "MADDesignerSectionBackground.h"
#import "MADManagedObjectCollectionView.h"
#import "MTDocumentObjectNewAggregateViewController.h"
#import "MTDocumentObjectNewStaticLabelViewController.h"
#import "MADToolboxPresentationController.h"
#import "MADDesignerStatusLabel.h"
#import "MADDesignerScrollView.h"
#import "MADPromptManager.h"
#import "MADQueryChooseFieldProtocol.h"
#import "MADQueryChooseFieldController.h"
#import "MADToolboxViewController.h"
#import "MADToolboxTransitioner.h"
#import "MADLayoutConstraint.h"
#import "UITapGestureRecognizer+Designer.h"
#import "MADNavigationController.h"
#import "UIViewController+tabBarItem.h"
#import "MADManagedObjectViewProtocol.h"
#import "MADCellElementDelegate.h"
#import "MTViewControllerBarcode.h"
#import "MADElementPickerProtocol.h"
#import "MADDesignerLayoutDesignView.h"
#import "MADDesignerView.h"
#import "MADReportSectionDelegateProtocol.h"
#import "MADReportSectionsDataSource.h"
#import "MADThemeManager.h"
#import <MADFoundation/madlog.h>

#import <MADCocoaExtensions/MADResizeAspect.h>
#import <MADCocoaExtensions/MADMathAlgebra.h>
#import <MADCocoaExtensions/MADViewHelpers.h>

#import <MADFoundation/MADStringUtilities.h>

#import <MAD/MADReportSection.h>
#import <MAD/RptqStoreContext.h>
#import <MAD/MADocument.h>
#import <MAD/MADSectionLayoutManager.h>
#import <MAD/MADSectionLayoutAttributes.h>
#import <MAD/RptqDocument.h>
#import <MAD/RptqDocument+Extras.h>
#import <MAD/RptqDatabase.h>
#import <MAD/RptqDatabase+Extras.h>
#import <MAD/RptqDocumentElement.h>
#import <MAD/RptqDocumentElement+Extras.h>
#import <MAD/RptqDocumentElementBarcode+Extras.h>
#import <MAD/RptqTextStyle.h>
#import <MAD/RptqDocumentElementLabel.h>
#import <MAD/RptqDocumentElementLabelDataField.h>
#import <MAD/RptqDocumentElementAggregate+Extras.h>
#import <MAD/RptqQuery+Extras.h>
#import <MAD/RptqQueryField.h>
#import <MAD/RptqDocumentSection+Extras.h>
#import <MAD/RptqDocumentSectionRows.h>
#import <MAD/RptqDocumentSectionEnumerator.h>
#import <MAD/RptqDirectionalAsymmetry.h>
#import <MAD/RptqNumericFormat.h>
#import <MAD/RptqAlignment.h>
#import <MAD/RptqBorder.h>
#import <MAD/RptqRect.h>
#import <MAD/RptqSize.h>
#import <MAD/RptqObject.h>
#import <MAD/madmath.h>

#import <UIKit/NSLayoutAnchor.h>
#import <UIKit/UIStoryboard.h>
#import <UIKit/UIStoryboardSegue.h>
#import <UIKit/UICollectionViewFlowLayout.h>
#import <UIKit/UIAccessibility.h>
#import <UIKit/UIImagePickerController.h>
#import <UIKit/UIBarButtonItem.h>
#import <UIKit/UINibLoading.h>
#import <UIKit/UINavigationController.h>
#import <UIKit/UINavigationBar.h>
#import <UIKit/UIVisualEffectView.h>
#import <UIKit/NSAttributedString.h>
#import <UIKit/UIMenuController.h>
#import <UIKit/NSStringDrawing.h>
#import <UIKit/UIPopoverPresentationController.h>

#import <math.h>
#import <asl.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnullability-completeness"

// The portable store has no per-object change tracking yet; the change-notification
// handlers below are dormant until a later milestone wires them.  Treat every attribute
// as changed so they stay correct if they are ever delivered.
@interface RptqObject (MADDesignerViewControllerChangeShim)
- (NSDictionary<NSString *, id> *)changedValues;
@end

typedef NS_ENUM(NSUInteger, MTToolboxType) {
	MTToolboxTypeElement = 2,
	MTToolboxTypeSection = 3,
	MTToolboxTypeNone = 4,
};

static const CGFloat MADDefaultsPopooverWidth = 320.0;
static const CGFloat MADDefaultsPopooverHeight = 480.0;
static const CGFloat MADSizeWidthViewDetailDisplay = 32.0;
static const CGFloat MADSizeHeightViewDetailDisplay = 20.0;

static inline CGFloat ScrollViewCenterX(UIScrollView *scrollView) {
	return scrollView.contentSize.width * 0.5000f + MAX((scrollView.bounds.size.width - scrollView.contentSize.width) * 0.5, 0.0);
}

static inline CGFloat ScrollViewCenterY(UIScrollView *scrollView) {
	return scrollView.contentSize.height * 0.5000f + MAX((scrollView.bounds.size.height - scrollView.contentSize.height) * 0.5, 0.0);
}

static inline CGFloat DetailDisplayFrameOriginX(CGFloat width) { return width - MADSizeWidthViewDetailDisplay - MTReportDesignerBorderPaddingDetail; }
static inline CGFloat DetailDisplayFrameOriginY(CGFloat marginTop) { return CGPointZero.y + marginTop + MTReportDesignerBorderPaddingDetail; }
static const inline CGSize sizePopoverDefault(void) { return CGSizeMake(MADDefaultsPopooverWidth, 320.0); }
static const inline CGSize sizePopoverFonts(void) { return CGSizeMake(MADDefaultsPopooverWidth, MADDefaultsPopooverHeight); }

@interface MADDesignerViewController() <MADDesignerDesignViewDelegate, UIGestureRecognizerDelegate, UIScrollViewDelegate> {
	@package
	BOOL _editAggregate;
	BOOL _toolboxVisible;
	BOOL _sectionSettingsVisible;
	BOOL _insetsSetup;
	BOOL _shownAndHidden;
	BOOL _lastMenuItemSelectRequiresElementView;
	int64_t _identifierJustDisplayed;
	CGFloat _zoomScaleRestore;
	CGRect _boundsOnDisappear;
}

@property (null_resettable, nonatomic, strong) MADDesignerView *view;

@property (nonatomic, strong) MADDesignerStatusLabel *statusLabelZoomScale;

@property (nonatomic, strong) NSMutableSet <MADDesignerElementView *> *visibleElementViews;
@property (nonatomic, strong) NSMutableSet <NSNumber *> *selectedElementIDs;

@property (nonatomic, strong) NSMutableDictionary <NSNumber *, __kindof MADDesignerElementView *> *elementViewsDictionary;
@property (nonatomic, strong) NSMutableDictionary <NSNumber *, NSNumber *> *borderAppliedToView;

@property (nonatomic, weak) MADDesignerElementView *lastElementViewToShowMenu;

@property (nonatomic, strong) MADToolboxTransitioningDelegate *toolboxTransitioningDelegate;
@property (nonatomic, strong) MADToolboxTransitioningDelegate *settingsTransitioningDelegate;

@property (nonatomic, strong) NSNumberFormatter *numberFormatterPercentage;

@property (nonatomic, strong) MADPromptManager *promptManager;

@property (nonatomic, strong) NSLayoutConstraint *layoutConstraintContainerWidth;
@property (nonatomic, strong) NSLayoutConstraint *layoutConstraintContainerLeft;

@property (nonatomic, strong) MADToolboxViewController *viewControllerToolbox;
@property (nonatomic, strong) MADDesignerSectionLayoutController *viewControllerSectionLayoutSettings;

@property (nonatomic, strong) UINavigationController *navigationControllerToolbox;
@property (nonatomic, strong) UINavigationController *navigationControllerSectionLayoutSettings;

@property (nonatomic, assign) NSInteger lastSelectedSectionControlPanel;

@property (nonatomic, strong) UIPopoverPresentationController *popoverToolbox;
@property (nonatomic, strong) UIPopoverPresentationController *popoverObjectSelector;

@property (nonatomic, copy) NSNumber *objectIdEditDynamicLabel;
@property (nonatomic, copy) NSNumber *objectIdEditBarcode;
@property (nonatomic, copy) NSNumber *objectIdEditImage;
@property (nonatomic, copy) NSNumber *barcodeToEditObjectID;
@property (nonatomic, assign) int64_t aggregateToEditObjectID;

@property (nonatomic, weak) UIGestureRecognizer *strayTouchGesture;
@property (nonatomic, weak) UILabel *lastSelectedLabel;
@property (nonatomic, weak) UIBarButtonItem *undoButton;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *barButtonItemAdd;

@property (nonatomic, strong) MADReportSectionsDataSource *reportSectionDatasource;

- (void)setDisplayActive;
- (void)setDisplayInactive;
- (void)setScrollersEnabled:(BOOL)enabled;
- (BOOL)dismissAllPopovers;
- (void)displayPrompt;
- (CGRect)detailDisplayFrame;
- (void)scrollToDetailSectionView;

- (BOOL)elementViewIsSelected:(MADDesignerElementView *)elementView;
- (void)selectElementView:(__kindof MADDesignerElementView *)elementView;
- (void)deselectElementView:(MADDesignerElementView *)elementView animated:(BOOL)animated;
- (void)deselectAllElementsAnimated:(BOOL)animated;
- (NSSet <UIView *> *)selectedElementViews;
- (CGRect)rectForSelectedElements;

- (MADDesignerElementView *)elementViewForManagedObject:(__kindof RptqDocumentElement *)managedObject;
- (MADDesignerElementView *)elementViewAtIndexPath:(NSIndexPath *)indexPath inCollectionView:(UICollectionView *)collectionView;
- (MADDesignerElementView *)elementViewForCollectionViewCell:(UICollectionViewCell *)cell;
- (void)redrawAllElementViewsInCollectionView:(UICollectionView *)collectionView;
- (MADDesignerSectionView *)documentSectionViewWithIdentifier:(NSInteger)identifier;
- (MADDesignerSectionView *)getSectionViewForSectionID:(int64_t)sectionID;
- (MADDesignerSectionView *)getSectionViewForDocumentSection:(RptqDocumentSection *)section;
- (RptqDocumentSection *)sectionForLabelTag:(NSInteger)tag;
- (void)relayoutSectionView:(MADDesignerSectionView *)documentSectionView;

- (void)handlePanPiece:(UIPanGestureRecognizer *)gestureRecognizer;
- (void)handlePinchPiece:(UIPinchGestureRecognizer *)gestureRecognizer;
- (void)handleTapStray:(UITapGestureRecognizer *)sender;
- (void)handleTapLabel:(UITapGestureRecognizer *)sender;
- (void)handleToggleElementView:(UITapGestureRecognizer *)sender;

@end

#pragma clang diagnostic pop

#endif
