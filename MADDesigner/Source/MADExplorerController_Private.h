//
//  MADExplorerController_Private.h
//  MAD Designer
//
//  Created by Michael Thomason on 1/2/12.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_MADExplorerController_Private_h
#define MAD_MADExplorerController_Private_h

#import "MADExplorerController.h"
#import "AppDelegate.h"
#import "MADExplorerViewLayout.h"
#import "MADAboutTableViewController.h"
#import "MADDocumentInformationTableViewController.h"
#import "MADExplorerSectionHeaderView.h"
#import "MADSearchBar.h"
#import "MADDesignerViewController.h"
#import "MADDriverSelectorController.h"
#import "MADStoreViewController.h"
#import "MADNavigationController.h"
#import "MADTabBarController.h"
#import "MADOperationInstallSampleDatabase.h"
#import "MADOperationInstallSampleDocument.h"
#import "MADKeyChainSaveCredentials.h"
#import "MADKeyChainGetCredentials.h"
#import "MADColorTransformer.h"
#import "MADLocaleTransformer.h"
#import "MADThemeManager.h"
#import <MADFoundation/madlog.h>

#import <MAD/MADNotificationFileUpdate.h>

#import <MADAPI/MADViewControllerStandardProtocol.h>
#import <MADFileManager/MADFileUtilities.h>
#import <MADFileManager/MADFileInfo.h>
#import <MADFileManager/MADMetaData.h>
#import <MADFileManager/MADFilesController.h>

#import <MADCocoaExtensions/MADAlertController.h>
#import <MADCocoaExtensions/UIColor+EverydayApps.h>
#import <MADCocoaExtensions/NSError+Constructors.h>
#import <MADCocoaExtensions/MADViewHelpers.h>
#import <MADCocoaExtensions/NSNumberFormatter+MADExtensions.h>
#import <MADCocoaExtensions/MFMailComposeViewController+MADExtensions.h>
#import <MADCocoaExtensions/MTMath.h>
#import <MADCocoaExtensions/MADLabelTitle.h>
#import <MADCocoaExtensions/UIApplication+Helpers.h>

#import <MADFoundation/MADBlockObserver.h>
#import <MADFoundation/MADApplication.h>
#import <MADFoundation/MADApplicationProtocol.h>
#import <MADFoundation/MADURLFactory.h>
#import <MADFoundation/MADOperation.h>
#import <MADFoundation/MADOperationQueue.h>
#import <MADFoundation/MADOperationObserver.h>
#import <MADFoundation/MADCredential.h>

#import <MADExplorer/MADExplorerProtocol.h>
#import <MADExplorer/MADDocumentManagerProtocol.h>
#import <MADExplorer/MADExplorerView.h>
#import <MADExplorer/MADFileLocationManager.h>
#import <MADExplorer/MADOpenDocumentManager.h>
#import <MADExplorer/MADCollectionViewCellDocument.h>
#import <MADExplorer/MADExplorerViewDelegate.h>
#import <MADExplorer/MADLabelFileExplorerDocumentCellTitle.h>
#import <MADExplorer/MADExplorerDataSource.h>

#import <MAD/MADConstants.h>
#import <MAD/MADAppLaunchContext.h>
#import <MAD/MADDocumentProtocol.h>
#import <MAD/MADocument.h>

#import <QuickLook/QLPreviewController.h>
#import <MessageUI/MFMailComposeViewController.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

extern NSString * const MADUtiType;
extern NSString * const MADUpgradeInstalledSamplesLondon;
extern NSString * const MADUpgradeInstalledSamplesMusic;

@interface MADExplorerController()
	<NSFileManagerDelegate, UIGestureRecognizerDelegate, UIDocumentPickerDelegate, MADExplorerProtocol, MADDocumentManagerProtocol, MADocumentDelegate, MADOperationObserver, MADSaveFileProtocol> {
	@package
	BOOL _cloudActivityRunning;
	BOOL _cloudActivityRunningDisplay;
	
	BOOL _shouldShowAddDocumentPopover;
	BOOL _aboutViewControllerOnScreen;
	BOOL _infoControllerOnScreen;
	
	BOOL _isActivityIndicatorRightVisible;
	BOOL _activityIndicatorRightVisible;
	BOOL _updatingEnabled;
	BOOL _getUserCloudPrefsFirstCall;
}

@property (readwrite, nonatomic, strong) MADExplorerDataSource *fileExplorerDataSource;
@property (readwrite, nonatomic, strong) MADExplorerViewDelegate *fileExplorerViewDelegate;
@property (readwrite, nonatomic, strong) MADOpenDocumentManager *activeDocumentManager;

@property (nonatomic, weak) IBOutlet MADExplorerView *fileExplorerView;
@property (nonatomic, strong) NSNumberFormatter *subtitleNumberFormatter;
@property (nonatomic, strong) MADAppLaunchContext *pendingLaunchContext;

@property (nonatomic, strong) IBOutlet UIBarButtonItem *barButtonItemAction;
@property (nonatomic, strong) UIBarButtonItem *barButtonItemEdit;
@property (nonatomic, strong) UIBarButtonItem *barButtonItemEditDone;
@property (nonatomic, strong) UIBarButtonItem *barButtonItemDuplicate;
@property (nonatomic, strong) MADTabBarController *tabController;

@property (nonatomic, weak) IBOutlet UIBarButtonItem *barButtonItemInformationDocument;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *barButtonItemTrash;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *barButtonItemInformation;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *barButtonItemAbout;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *barButtonItemAddNewDocument;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *barButtonItemCloudDown;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *barButtonItemLicensing;

@property (nonatomic, weak) UIPopoverPresentationController *infoPopoverPresentationController;
@property (nonatomic, weak) UIPopoverPresentationController *aboutPopoverPresentationController;
@property (nonatomic, weak) UIPopoverPresentationController *documentInformationPopoverPresentationController;

@property (nonatomic, strong) MADSearchBar *searchBar;
@property (nonatomic, strong) UIBarButtonItem *rightBarButtonItemHolderWhileActivity;
@property (nonatomic, strong) MADExplorerSectionHeaderView *headerCloud;
@property (nonatomic, strong) UIProgressView *progressViewFileManager;
@property (nonatomic, strong) NSArray *defaultPassthroughViews;

+ (BOOL)isUniqueFilename:(NSString *)name inDirectory:(NSURL *)directory;
+ (NSString *)safeFilenameWithDesiredFilename:(NSString *)desiredName;

- (void)showViewController:(UIViewController *)vc animated:(BOOL)animated;
- (void)selectCell:(UICollectionViewCell *)cell;
- (void)defaultBarButtonItemState;
- (void)enableBarButtonItems;
- (void)disableBarButtonItems;

@end

#endif
