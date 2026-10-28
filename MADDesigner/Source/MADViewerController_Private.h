//
//  MADViewerController_Private.h
//  Reports
//
//  Created by Michael Thomason on 3/1/12.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_MADViewerController_Private_h
#define MAD_MADViewerController_Private_h

#import "MADViewerController.h"
#import "MADOperationRefreshReload.h"
#import "MADPrintingProtocol.h"
#import "MADTabBarController.h"
#import "MADActivityReportPrintPreview.h"
#import "MADDocumentPageController.h"
#import "MADPageSlider.h"
#import "MADSliderPageVertical.h"
#import "MADLabelStatus.h"
#import "MADPageViewAttributes.h"
#import "MADDocumentScroller.h"
#import "MADRefreshOperationReload.h"
#import "MTStoreKitController+Features.h"
#import "UIViewController+tabBarItem.h"
#import "NSDate+Extras.h"
#import "MADThemeManager.h"
#import <MADFoundation/madlog.h>

#import <MADAPI/MADViewControllerStandardProtocol.h>
#import <MADFoundation/MADDataTable.h>
#import <MADFoundation/MADOperationQueue.h>
#import <MADFoundation/MADOperationObserver.h>
#import <MADAPI/MADNotificationDidReadRows.h>
#import <MADAPI/MADDatabase.h>
#import <MADAPI/MADDatabaseConnection.h>
#import <MADCocoaExtensions/MADLabelTitle.h>
#import <MADCocoaExtensions/CGGeometry+Extras.h>
#import <MADCocoaExtensions/MADViewHelpers.h>
#import <MADCocoaExtensions/UIApplication+Helpers.h>
#import <MADCocoaExtensions/UIColor+EverydayApps.h>
#import <MADDataStructures/MTPair.h>
#import <MAD/MADActivityItemProviderDelegate.h>
#import <MAD/MADPrintPageRenderer.h>
#import <MAD/MADReportFormatter.h>
#import <MAD/MADocument.h>
#import <MAD/MTPaper.h>
#import <MAD/MADActivityItemProviderPdf.h>
#import <MAD/MADNotificationDidFormatPage.h>
#import <MADBarcodes/MADBarcodeCache.h>

#import <UIKit/UIAccessibility.h>
#import <UIKit/UIAccessibilityConstants.h>
#import <UIKit/UIActivityIndicatorView.h>
#import <UIKit/UIBarButtonItem.h>
#import <UIKit/UIDocumentInteractionController.h>
#import <UIKit/UILocalNotification.h>
#import <UIKit/UINavigationBar.h>
#import <UIKit/UINavigationController.h>
#import <UIKit/UIPopoverPresentationController.h>
#import <UIKit/UIPrintInteractionController.h>
#import <UIKit/UIStoryboard.h>
#import <UIKit/UITabBarItem.h>
#import <UIKit/UIToolbar.h>
#import <UIKit/UIViewController.h>
#import <UIKit/UIViewControllerTransitioning.h>

@interface MADOperationLoadDocument : NSOperation
- (instancetype)initWithDocument:(MADocument *)document;
@property (readonly, nonatomic, weak) MADocument *document;
@end

@interface MADOperationLoadPrintPageRender : NSOperation
- (instancetype)initWithDocument:(MADocument *)document;
@property (readonly, nonatomic, weak) MADocument *document;
@property (readonly, nonatomic, weak) MADPrintPageRenderer *printPageRenderer;
@end

@interface MADViewerController () <UIPopoverPresentationControllerDelegate, UIStateRestoring, UIPageViewControllerDelegate, UIPageViewControllerDataSource, UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning, MADOperationObserver, MADPageSliderProtocol> {
	@package
	NSDate *_lastCacheDate;
	MADReportPosition _currentLocation;
	BOOL _isFirstAppearance;
	BOOL _firstTimeViewWillLayoutSubviews;
	BOOL _refreshing;
	BOOL _didRefreshBeforeReaload;
	BOOL _activityExporting;
	BOOL _startedRefresh;
	BOOL _pageIsAnimating;
	BOOL _updatingOfTimerIsPaused;
}

@property (nonatomic, strong) MADDateFromTimeFormatter *dateTimeFormatter;
@property (nonatomic, strong) NSTimer *timerLabelTimeSinceRefreh;
@property (nonatomic, strong) MADPageSlider *pageSlider;
@property (nonatomic, weak) MADLabelStatus *labelStatus;
@property (nonatomic, readonly) MADTabBarController *tabBarController;

@property (nonatomic, weak) IBOutlet UIBarButtonItem *barButtonItemActivity;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *barButtonItemRefresh;

@property (nonatomic, strong) MADPrintPageRenderer *printPageRendererReport;
@property (nonatomic, strong) MADActivityItemProviderPdf *activityItemProviderPdf;

@property (nonatomic, strong) MADOperationQueue *refreshQueue;

+ (void)setNavigationBarAppearanceTinted;
+ (void)setNavigationBarAppearanceHighlighted;
- (void)setDisplayActive;
- (void)setDisplayInactive;

@end

#endif
