//
//  MADExplorerController.m
//  MAD Designer
//
//  Created by Michael Thomason on 1/2/12.
//  Copyright © 2020 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADExplorerController.h"
#import "AppDelegate.h"
#import "MADExplorerViewLayout.h"
#import "MADExplorerControllerProtocol.h"
#import "MADAboutTableViewController.h"
#import "MADDocumentInformationTableViewController.h"
#import "MADExplorerSectionHeaderView.h"
#import "MADSearchBar.h"
#import "MADViewerController.h"
#import "MADDesignerViewController.h"
#import "MADQueryViewController.h"
#import "MADDriverSelectorController.h"
#import "MADStoreViewController.h"
#import "MADNavigationController.h"
#import "MADQueryVisualizationViewController.h"
#import "MADTabBarController.h"
#import "MADOperationInstallSampleDatabase.h"
#import "MADOperationInstallSampleDocument.h"
#import "MTVerificationController.h"
#import "MTStoreKitController+Features.h"
#import "MADSearchBar.h"
#import "MADKeyChainSaveCredentials.h"
#import "MADKeyChainGetCredentials.h"
#import "MADColorTransformer.h"
#import "MADLocaleTransformer.h"
#import "MADThemeManager.h"
#import "madlog.h"

#import <MADAPI/MADViewControllerStandardProtocol.h>
#import <MADFileManager/MADFileUtilities.h>
#import <MADFileManager/MADFileInfo.h>
#import <MADFileManager/MADMetaData.h>

#import <MADCocoaExtensions/MADAlertController.h>
#import <MADCocoaExtensions/UIColor+EverydayApps.h>
#import <MADCocoaExtensions/MADBarButtonItem.h>
#import <MADCocoaExtensions/NSError+Constructors.h>
#import <MADCocoaExtensions/MADViewHelpers.h>
#import <MADCocoaExtensions/MADNumberFormatter.h>
#import <MADCocoaExtensions/MADMailComposeViewController.h>
#import <MADCocoaExtensions/MTMath.h>
#import <MADCocoaExtensions/MADLabelTitle.h>
#import <MADCocoaExtensions/MADProgressView.h>
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

static NSString * const MADIdentifierFileLondon                 = @"London";
static NSString * const MADIdentifierFileMusic                  = @"Music";

NSString * const MADUtiType                                     = @"com.everydayapps.productivity.mad";
NSString * const MADUpgradeInstalledSamplesLondon               = @"MADUpgradeInstalledSamplesLondon";
NSString * const MADUpgradeInstalledSamplesMusic                = @"MADUpgradeInstalledSamplesMusic";

static NSString * const MADAppConfigurationUserDefaultsSamplesInstalled     = @"MADAppConfigurationUserDefaultsSamplesInstalled";

static NSString * const MADNotificationCloudActivityStarted                 = @"MADNotificationCloudActivityStarted";
static NSString * const MADNotificationCloudActivityCompleted               = @"MADNotificationCloudActivityCompleted";

// FIXME: Get these from AppDelegate using a protocol/deletgate pattern... different for each version of file exploer.
// NSString * const MADUtiPublicData                               = @"public.data";

@interface MADExplorerController()
	<NSFileManagerDelegate, UIGestureRecognizerDelegate, MFMailComposeViewControllerDelegate, UIDocumentInteractionControllerDelegate, UIDocumentPickerDelegate, UITextFieldDelegate, UISearchBarDelegate, UIPopoverControllerDelegate, UIPopoverPresentationControllerDelegate, UIAdaptivePresentationControllerDelegate, MADExplorerProtocol, MADDocumentManagerProtocol, MADocumentDelegate, MADViewControllerStandardProtocol, MADOperationObserver, MADSaveFileProtocol>

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
@property (nonatomic, strong) MADProgressView *progressViewFileManager;
@property (nonatomic, strong) NSArray *defaultPassthroughViews;

@end

@implementation MADExplorerController {
	
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

#pragma mark -
#pragma mark Helpers

+ (BOOL)isUniqueFilename:(NSString *)name inDirectory:(NSURL *)directory {
	NSURL *renamedURL = [directory.URLByDeletingLastPathComponent URLByAppendingPathComponent:name isDirectory:NO];
	NSString *path = renamedURL.path;
	return [[NSFileManager defaultManager] fileExistsAtPath:path] || [[NSFileManager defaultManager] isUbiquitousItemAtURL:renamedURL];
}

+ (NSString *)safeFilenameWithDesiredFilename:(NSString *)desiredName {
	NSMutableCharacterSet *characterSet = [[NSMutableCharacterSet alloc] init];
	[characterSet formUnionWithCharacterSet:[NSCharacterSet alphanumericCharacterSet]];
	[characterSet formUnionWithCharacterSet:[NSCharacterSet whitespaceCharacterSet]];
	NSArray *components = [desiredName componentsSeparatedByCharactersInSet:characterSet.invertedSet];
	return [components componentsJoinedByString:@""];
}

+ (instancetype)newExplorerController {
	return [[UIStoryboard storyboardWithName:@"MADExplorer"
									  bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"MADIdentifierFileExplorerViewController"];
}

+ (void)initialize {
	[super initialize];
	
	if (self == [MADExplorerController self]) {
		@autoreleasepool {
		
			[NSValueTransformer setValueTransformer:[[MADLocaleTransformer alloc] init] forName:NSStringFromClass([MADLocaleTransformer class])];
			[NSValueTransformer setValueTransformer:[[MADColorTransformer alloc] init] forName:NSStringFromClass([MADColorTransformer class])];

			NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.everydayapps.mad.primary"];
			[defaults registerDefaults:@{
				MADUpgradeInstalledSamples: @NO,
				MADAppConfigurationUserDefaultsSamplesInstalled: @NO,
				MADUpgradeInstalledChinook: @NO
			}];

		}
	}
}

#pragma mark -
#pragma mark NSObject

- (void)dealloc {
	self.fileExplorerViewDelegate = nil;
	_barButtonItemAction = nil;
	_subtitleNumberFormatter = nil;
	
	[[NSNotificationCenter defaultCenter] removeObserver: self
													name: NSUbiquityIdentityDidChangeNotification
												  object: nil];
	
	[[NSNotificationCenter defaultCenter] removeObserver: self
													name: UIContentSizeCategoryDidChangeNotification
												  object: nil];
	
	[[NSNotificationCenter defaultCenter] removeObserver: self
													name: MADNotificationCloudActivityStarted
												  object: nil];
	
	[[NSNotificationCenter defaultCenter] removeObserver: self
													name: MADNotificationCloudActivityCompleted
												  object: nil];

}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
	
	if (self = [super initWithCoder:aDecoder]) {
		_shouldShowAddDocumentPopover = YES;
		_getUserCloudPrefsFirstCall = YES;
		_infoControllerOnScreen = NO;
		_aboutViewControllerOnScreen = NO;
		_updatingEnabled = YES;
		_cloudActivityRunning = NO;
		_cloudActivityRunningDisplay = NO;
		_activityIndicatorRightVisible = NO;

		_activeDocumentManager = [[MADOpenDocumentManager alloc] init];
		_barButtonItemDuplicate = [[UIBarButtonItem alloc] initWithImage: [UIImage imageNamed: @"MADImageToolbarDuplicate"]
																   style: UIBarButtonItemStylePlain
																  target: self
																  action: @selector(actionDuplicate:)];
		[_barButtonItemDuplicate setEnabled: NO];
		
		_barButtonItemEdit = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemEdit
																		   target: self
																		   action: @selector(actionEdit:)];
		_fileExplorerViewDelegate = [[MADExplorerViewDelegate alloc] init];
		_fileExplorerViewDelegate.delegate = self;

	}
	return self;
	
}

#pragma mark -
#pragma mark UIViewController
#pragma mark Initialize install operations

- (void)viewDidLoad {
	[super viewDidLoad];

	MADOperationQueue *operationQueueBackground = [[MADOperationQueue alloc] init];
	operationQueueBackground.maxConcurrentOperationCount = 1;
	
	MADOperationInstallSampleDatabase *opInstallDb = [[MADOperationInstallSampleDatabase alloc] init];
	[operationQueueBackground addOperation:opInstallDb];
	
	MADOperationInstallSampleDocument *opInstallDocA = [[MADOperationInstallSampleDocument alloc] initWithFilename: MADIdentifierFileLondon
																									 fileExtension: MADFileExtentionMobleApplicationDocument
																								   groupIdentifier: [AppDelegate groupIdentifier]
																									   installFlag: MADUpgradeInstalledSamplesLondon];
	opInstallDocA.identifier = 3;
	[opInstallDocA addObserver:self];
	[operationQueueBackground addOperation:opInstallDocA];

	
	MADOperationInstallSampleDocument *opInstallDocB = [[MADOperationInstallSampleDocument alloc] initWithFilename: MADIdentifierFileMusic
																									 fileExtension: MADFileExtentionMobleApplicationDocument
																								   groupIdentifier: [AppDelegate groupIdentifier]
																									   installFlag: MADUpgradeInstalledSamplesMusic];
	opInstallDocB.identifier = 2;
	[opInstallDocB addObserver:self];
	[operationQueueBackground addOperation:opInstallDocB];
	
	NSOperation *resetReceipt = [[NSInvocationOperation alloc] initWithTarget: [MTVerificationController sharedInstance]
																	 selector: @selector(resetReceipt)
																	   object: NULL];
	[operationQueueBackground addOperation:resetReceipt];
	
	NSOperation *getUserCloudPreferences = [[NSInvocationOperation alloc] initWithTarget: self.fileExplorerDataSource
																				selector: @selector(updateCloudPreferences)
																				  object: NULL];
	[operationQueueBackground addOperation:getUserCloudPreferences];

	self.barButtonItemEdit.accessibilityHint = NSLocalizedString(@"Enables document list edit mode.", @"Enables document list edit mode.");
	self.barButtonItemAddNewDocument.accessibilityHint = NSLocalizedString(@"Adds a new document.", @"Adds a new document.");;
	self.barButtonItemLicensing.accessibilityHint = NSLocalizedString(@"Displays the store.", @"Displays the store.");
	self.barButtonItemTrash.accessibilityHint = NSLocalizedString(@"Deletes the selected documents.", @"Deletes the selected documents.");
	[MADThemeManager applyAppearanceToBarButtonItem:self.barButtonItemTrash traitCollection:self.traitCollection];
	self.barButtonItemAction.accessibilityHint = NSLocalizedString(@"Preforms an action on the selected document.", @"Preforms an action on the selected document.");
	[MADThemeManager applyAppearanceToBarButtonItem:self.barButtonItemAction traitCollection:self.traitCollection];
	self.barButtonItemDuplicate.accessibilityHint = NSLocalizedString(@"Duplicates the selected documents.", @"Duplicates the selected documents.");
	[MADThemeManager applyAppearanceToBarButtonItem:self.barButtonItemDuplicate traitCollection:self.traitCollection];
	self.barButtonItemInformationDocument.accessibilityHint = NSLocalizedString(@"Displays selected document details.", @"Displays selected document details.");
	[MADThemeManager applyAppearanceToBarButtonItem:self.barButtonItemInformationDocument traitCollection:self.traitCollection];
	self.barButtonItemInformation.accessibilityHint = NSLocalizedString(@"Displays selected document details.", @"Displays selected document details.");
	[MADThemeManager applyAppearanceToBarButtonItem:self.barButtonItemInformation traitCollection:self.traitCollection];
	self.barButtonItemAbout.accessibilityHint = NSLocalizedString(@"Displays selected document details.", @"Displays selected document details.");
	
	[self.collectionView registerClass: [MADExplorerSectionHeaderView class]
			forSupplementaryViewOfKind: UICollectionElementKindSectionHeader
				   withReuseIdentifier: MADIdentifierOpenFileSectionHeader];

	NSMutableArray *toolbarButtons = self.toolbarItems.mutableCopy;
	[toolbarButtons removeObject:_barButtonItemAction];
	[toolbarButtons removeObject:_barButtonItemCloudDown];
	[toolbarButtons insertObject:_barButtonItemDuplicate atIndex:1];
	[self setToolbarItems:toolbarButtons animated:NO];
	[self setEditing: NO animated: NO];
	
	UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget: self
																						   action: @selector(handleDidTapCollectionView:)];
	tapGestureRecognizer.delegate = self;
	[self.collectionView addGestureRecognizer:tapGestureRecognizer];
	self.fileExplorerDataSource.delegate = self;
	self.collectionView.dataSource = self.fileExplorerDataSource;
	
	[self setNeedsStatusBarAppearanceUpdate];
	
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(handleNotificationUbiquityIdentityDidChange:)
												 name: NSUbiquityIdentityDidChangeNotification
											   object: nil];
	
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(handleContentSizeCategoryDidChangeNotification:)
												 name: UIContentSizeCategoryDidChangeNotification
											   object: nil];
	
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(handleCloudActivityStarted:)
												 name: MADNotificationCloudActivityStarted
											   object: nil];
	
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(handleCloudActivityCompleted:)
												 name: MADNotificationCloudActivityCompleted
											   object: nil];
	
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	[self.navigationItem setRightBarButtonItem: _barButtonItemEdit
									  animated: animated];
	_barButtonItemLicensing.enabled = [SKPaymentQueue canMakePayments];

	if ([self.toolbarItems containsObject: self.barButtonItemAction] == NO) {
		NSMutableArray *toolbarButtons = self.toolbarItems.mutableCopy;
		[toolbarButtons insertObject: self.barButtonItemAction atIndex: 1];
		[self setToolbarItems:toolbarButtons animated:NO];
	}
	self.collectionView.delegate = self.fileExplorerViewDelegate;
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	[self.navigationController setNavigationBarHidden:NO animated:animated];
	_aboutViewControllerOnScreen = NO;
	_infoControllerOnScreen = NO;
	if (self.pendingLaunchContext) {
		[self configureViewControllerWithLaunchContext:self.pendingLaunchContext];
	}
	
	self.pendingLaunchContext = nil;
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
	self.defaultPassthroughViews = nil;
}

- (void)viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];
	if (self.searchBar.superview != nil) {
		[self.searchBar sizeToFit];
	}
}

- (void)setEditing:(BOOL)editing {
	[super setEditing:editing];
	_fileExplorerViewDelegate.editing = editing;
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
	[super setEditing:editing animated:animated];
	_fileExplorerViewDelegate.editing = editing;
}


#pragma mark -
#pragma mark Lazy Load

- (MADExplorerDataSource *)fileExplorerDataSource {

	if (!_fileExplorerDataSource) {
		
		MADExplorerDataSource *datasource = [[MADExplorerDataSource alloc] initWithFileExtension: MADFileExtentionMobleApplicationDocument
																						 groupID: [AppDelegate groupIdentifier]
																					  ubiquityID: [AppDelegate ubiquityIdentifier]
																			   cellConfiguration: ^(MADCollectionViewCellDocument *cell, NSIndexPath *indexPath) {
			((MADCollectionViewCellDocument *)cell).wobbling = self.isEditing;
			MADMetaData *metadata = [self metadataForItemAtIndexPath:indexPath];
			[cell updateDisplayForMetaData:metadata editing:self.isEditing];
			[cell invalidateIntrinsicContentSize];
			//[self.collectionView.collectionViewLayout invalidateLayout];
		}];
		_fileExplorerDataSource = datasource;
		
	}
	
	return _fileExplorerDataSource;
}

- (MADSearchBar *)searchBar {
	if (!_searchBar) {
		_searchBar = [[MADSearchBar alloc] initWithFrame:CGRectZero];
	}
	return _searchBar;
}

- (MADProgressView *)progressViewFileManager {
	if (!_progressViewFileManager) {
		_progressViewFileManager = [MADProgressView newProgressView:MADProgressViewTypeFileExplorer];
	}
	return _progressViewFileManager;
}

#pragma mark -
#pragma mark MADDocumentManagerProtocol

- (void)handleDidDisconnectFromClound:(id)sender {
	typeof(self) __weak weakself = self;
	
	void (^actionConfirm)(UIAlertAction *action) = ^(UIAlertAction *action) {
		MADExplorerController *sself = weakself;
		[sself.fileExplorerDataSource updateCloudPreferences];
	};
		
	[[NSOperationQueue mainQueue] addOperationWithBlock:^{
		
		MADExplorerController *sself = weakself;
		if (!sself) return;
		
		UIAlertController *alert;
		alert = [MADExplorerController alertNotifyCloudSignOut:actionConfirm];
		[sself presentViewController:alert animated:YES completion:nil];
		
	}];
}

- (void)handleDidStartLongRunningActivity {
	// FIXME: Show activity indicator.
}

- (void)handleDidCompletedLongRunningActivity {
	// FIXME: Hide activity indicator.
}

#pragma mark -
#pragma mark MADDocumentManagerProtocol

- (void)documentManagerDidChangeContent:(NSArray *)inserts
								removes:(NSArray *)removes
								updates:(NSArray *)updates
							 completion:(void (^)(BOOL, NSError *))completion {

	UICollectionView *__weak weakCollectionView = self.collectionView;
	void (^batchUpdates)(void) = ^{
		
		UICollectionView *collectionView = weakCollectionView;
		if (inserts.count > 0) {
			[collectionView insertItemsAtIndexPaths: inserts];
		}
		if (removes.count > 0) {
			[collectionView deleteItemsAtIndexPaths: removes];
		}
		if (updates.count > 0) {
			[collectionView reloadItemsAtIndexPaths: updates];
		}
		collectionView = nil;
	};
	
	void (^batchCompletion)(BOOL finished) = ^(BOOL finished) {
		completion(YES, nil);
	};
	
	[self.collectionView performBatchUpdates:batchUpdates
								  completion:batchCompletion];
}

#pragma mark -
#pragma mark MADSaveFileProtocol

- (NSURL *)documentDirectory {
	return _fileExplorerDataSource.documentsDirectory;
}

#pragma mark -
#pragma mark NSKeyValueObserving

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
						change:(NSDictionary <NSKeyValueChangeKey, id> *)change
					   context:(void *)context {
	
	if ([keyPath isEqualToString: NSStringFromSelector(@selector(subviews))]) {
		if ([object isKindOfClass:[UITextField class]]) {
			UIImage *image;
			UIView *view;
			NSArray<__kindof UIView *> *subviews = ((UITextField *)object).subviews;
			for (view in subviews) {
				if ([view isKindOfClass:[UIButton class]]) {
					image = [((UIButton *)view).imageView.image
							 imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
					((UIButton *)view).tintColor = [UIColor whiteColor];
					[((UIButton *)view) setImage:image forState:UIControlStateNormal];
				}
			}
		}
	}
}

#pragma mark -
#pragma mark UIResponder

- (void)restoreUserActivityState:(NSUserActivity *)activity {
	MADAppLaunchContext *launchContext = [[MADAppLaunchContext alloc] initWithUserActivity:activity];
	[self configureViewControllerWithLaunchContext:launchContext];
}

#pragma mark -
#pragma mark UIViewController

- (void)viewWillTransitionToSize:(CGSize)size
	   withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
	[super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
	
	[coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
		[self.collectionView setNeedsDisplay];
		[self.navigationItem.titleView sizeToFit];
	} completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
		[self.collectionView.collectionViewLayout invalidateLayout];
	}];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
	[super traitCollectionDidChange:previousTraitCollection];
	if (self.traitCollection.horizontalSizeClass != previousTraitCollection.horizontalSizeClass) {
		[self.collectionView.collectionViewLayout invalidateLayout];
	}
}

- (void)willTransitionToTraitCollection: (UITraitCollection *)newCollection
			  withTransitionCoordinator: (id<UIViewControllerTransitionCoordinator>)coordinator {
	[super willTransitionToTraitCollection: newCollection
				 withTransitionCoordinator: coordinator];
	[coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
		[self.collectionView.backgroundView setNeedsDisplay];
	} completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
		[self.collectionView.collectionViewLayout invalidateLayout];
	}];

}

- (UIViewController *)childViewControllerForStatusBarHidden {
	return self.presentedViewController;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
	return UIStatusBarStyleLightContent;
}

#pragma mark -
#pragma mark UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
	   shouldReceiveTouch:(UITouch *)touch {
	CGPoint touchPoint = [touch locationInView:self.collectionView];
	NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:touchPoint];
	BOOL shouldReceiveTouch = YES;
	BOOL tapGestureRecognizer = [gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]];
	if (indexPath != nil && tapGestureRecognizer) {
		shouldReceiveTouch = NO;
	}
	return shouldReceiveTouch;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
//    BOOL result = YES;
//    if (self.isEditing &&
//        [gestureRecognizer.view isKindOfClass:[MADLabelFileExplorerDocumentCellTitle class]]) {
//        result = NO;
//    }
	return YES;
}

#pragma mark -
#pragma mark UIDocumentInteractionControllerDelegate

- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *) controller {
	id interactionController = self.navigationController;
	return interactionController;
}

#pragma mark - MFMailComposeViewController delegate protocol

- (void)mailComposeController:(MFMailComposeViewController *)controller
		  didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
	
	[NSError presentError: error onViewController: self completion:^(BOOL success) {
		[self dismissViewControllerAnimated:YES completion:nil];
	}];
}

#pragma mark -
#pragma mark NSFileManager delegate protocol

- (BOOL)fileManager:(NSFileManager *)fileManager shouldMoveItemAtURL:(NSURL *)srcURL
			  toURL:(NSURL *)dstURL {
	return YES;
}

- (BOOL)fileManager:(NSFileManager *)fileManager shouldProceedAfterError:(NSError *)error movingItemAtURL:(NSURL *)srcURL toURL:(NSURL *)dstURL {
	return [dstURL.pathExtension.lowercaseString isEqualToString:@"png"];
}

#pragma mark -
#pragma mark UIMenuController required methods
/*
- (BOOL)canBecomeFirstResponder {
	return YES;
}

- (BOOL)canResignFirstResponder {
	return YES;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
	BOOL result = NO;
	if (@selector(handleDidTapCollectionView:) == action) {
		result = YES;
	}
	return result;
}*/

#pragma mark -
#pragma mark UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	[((UICollectionView *)scrollView).collectionViewLayout invalidateLayout];
}

#pragma mark -
#pragma mark Touch Event Handlers

- (void)handleDidTapCollectionView:(UIGestureRecognizer *)sender {
	[self.searchBar resignFirstResponder];
	if (self.isEditing) {
		[self actionEdit:self];
	}
}

#pragma mark -
#pragma mark UIDocumentPickerDelegate

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
	[controller removeFromParentViewController];
}

- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller {
	[controller removeFromParentViewController];
}

- (void)showViewController:(UIViewController *)vc animated:(BOOL)animated {
	if (self.presentedViewController != nil) {
		[self dismissViewControllerAnimated: animated completion:^{
			[self presentViewController: vc animated: animated completion: nil];
		}];
	} else {
		[self presentViewController: vc animated: animated completion: nil];
	}
}

- (void)setRightBarButtonItemActivityIndicatorVisible:(BOOL)visible
											 animated:(BOOL)animated {
	
	if (_activityIndicatorRightVisible == visible) {
		return;
	}
	UIBarButtonItem *barButtonItem;
	
	if ((_activityIndicatorRightVisible = visible)) {

		self.rightBarButtonItemHolderWhileActivity = self.navigationItem.rightBarButtonItem;
		UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
		[activityIndicator startAnimating];
		activityIndicator.hidden = NO;
		activityIndicator.hidesWhenStopped = NO;
		barButtonItem = [[UIBarButtonItem alloc] initWithCustomView:activityIndicator];
		barButtonItem.isAccessibilityElement = NO;
		
	} else {
		barButtonItem = (UIBarButtonItem *)self.rightBarButtonItemHolderWhileActivity;
	}
	[self.navigationItem setRightBarButtonItem:barButtonItem animated:animated];
}

#pragma mark -
#pragma mark Notification Handlers

- (void)handleCloudActivityStarted:(NSNotification *)notification {
	_cloudActivityRunning = YES;
	NSTimer *timer = [NSTimer timerWithTimeInterval: 0.5000f
											 target: self
										   selector: @selector(displayActivityIndictor)
										   userInfo: nil
											repeats: NO];
	[timer fire];
}

- (void)handleContentSizeCategoryDidChangeNotification:(NSNotification *)notification {
	NSArray<__kindof UICollectionViewCell *> *visibleCells = self.collectionView.visibleCells;
	for (MADCollectionViewCellDocument *cell in visibleCells) {
		[cell handleContentSizeCategoryDidChangeNotification];
	}
	[self.view setNeedsLayout];
}

- (void)handleCloudActivityCompleted:(NSNotification *)notification {
	_cloudActivityRunning = NO;
	_cloudActivityRunningDisplay = NO;
	[self.headerCloud stopAnimating];
}

#pragma mark -
#pragma mark Convenience

- (NSArray *)defaultPassthroughViews {
	
	if (_defaultPassthroughViews == nil) {
		
		NSMutableArray *defaultPassthroughViews = [[NSMutableArray alloc] initWithCapacity: 2];

		UINavigationController *controller = self.navigationController;
		UIToolbar *view = controller.toolbar;
		if (view) [defaultPassthroughViews addObject: view];
		
		UINavigationBar *navBar = controller.navigationBar;
		if (navBar) [defaultPassthroughViews addObject: navBar];
		
		_defaultPassthroughViews = [[NSArray alloc] initWithArray: defaultPassthroughViews];
		
	}
	
	return _defaultPassthroughViews;
}

- (NSURL *)copyMetaDataUrlForIndexPath:(NSIndexPath *)indexPath {
	MADMetaData *metadata = [_fileExplorerDataSource metadataAtIndex:(NSUInteger)indexPath.item];
	return [metadata.URL copy];
}

- (void)configureViewControllerWithLaunchContext:(MADAppLaunchContext *)launchContext {
	/**
	 If there is a list currently displayed; pop to the root view controller (this controller) and
	 continue configuration from there. Otherwise, configure the view controller directly.
	 */
	if ([self.navigationController.topViewController isKindOfClass:[UINavigationController class]]) {
		[self.navigationController popToRootViewControllerAnimated:NO];
		self.pendingLaunchContext = launchContext;
		return;
	}
}

- (void)handleNotificationUbiquityIdentityDidChange:(NSNotification *)notification {
	[[NSOperationQueue mainQueue] addOperationWithBlock:^ {
		
		UINavigationController *navController = (UINavigationController *)[UIApplication sharedApplication].safeKeyWindow.rootViewController;
		[navController popToRootViewControllerAnimated:YES];
		
		UIAlertController *signedOutController = [MADExplorerController alertNotifyCloudSignOut:^(UIAlertAction *action) {
			[self.fileExplorerDataSource updateCloudPreferences];
		}];
		
		[self presentViewController:signedOutController animated:YES completion:nil];
	}];
}

#pragma mark -
#pragma mark Property Overrides (Lazy loading)

- (NSNumberFormatter *)subtitleNumberFormatter {
	if (!_subtitleNumberFormatter) {
		_subtitleNumberFormatter = [MADNumberFormatter newNumberFormatterTwoDecimalPlaces];
	}
	return _subtitleNumberFormatter;
}

- (UIBarButtonItem *)barButtonItemEditDone {
	if (!_barButtonItemEditDone) {
		_barButtonItemEditDone = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemDone
																			   target: self
																			   action: @selector(actionEdit:)];
	}
	return _barButtonItemEditDone;
}

#pragma mark -
#pragma mark MADExplorerProtocol

- (BOOL)isFileViewEditing { return self.editing; }

- (MADMetaData *)metadataForItemAtIndexPath:(NSIndexPath *)indexPath {
	return [_fileExplorerDataSource metadataAtIndex: (NSUInteger)indexPath.item];
}

- (void)explorerDidChangeNumberOfItemsSelected:(NSUInteger)numberOfItemsSelected {

	switch (numberOfItemsSelected) {
			
		case 0:
			[self disableBarButtonItems];
			break;
			
		case 1:
			[self enableBarButtonItems];
			break;
			
		default:
			[self defaultBarButtonItemState];
			break;
	}
}

#pragma mark -
#pragma mark MADExplorerControllerProtocol

- (NSString *)mimeTypeForDocumentUTI:(NSString *)documentType {
	if ([documentType isEqualToString:MADUtiType]) {
		return MADMimeType;
	} else {
		NSAssert(NO, @"Unknown type at %s", __PRETTY_FUNCTION__);
		return MADMimeType;
	}
}

- (NSArray <NSString *> *)supportedUTIs {
	return [[NSArray alloc] initWithObjects: MADUtiType, nil];
}

- (void)openDocumentAtURL:(NSURL *)url {

	MADocument *document = [[MADocument alloc] initWithFileURL:url];
	document.limitResultsDesignMode = [MTStoreKitController sharedObject].isReportingLimited;
	document.documentDelegate = self;
	
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(handleDocumentStateChangedNotification:)
												 name: UIDocumentStateChangedNotification
											   object: document];
	
	self.activeDocumentManager.openDocument = document;
	
	[document openWithCompletionHandler:^(BOOL success) {

		if (success) {
			document.documentDelegate = self;
			SEL selector = @selector(openViewer);
			id operation = [[NSInvocationOperation alloc] initWithTarget: self
																selector: selector
																  object: nil];
			[[NSOperationQueue mainQueue] addOperation:operation];
		}
	}];
}

#pragma mark Helpers

- (void)openViewer {
	MADocument *document = self.activeDocumentManager.openDocument;
	NSURL *fileURL = [document.fileURL copy];
	NSString *title = [fileURL.lastPathComponent copy];
	
	MADTabBarController *tabBarController = [MADTabBarController newTabBarController:document prompt:title];
	tabBarController.document = document;
	tabBarController.viewControllerDelegate = self;
	//tabBarController.navigationItem.prompt = title;
	
	[self.navigationController pushViewController:tabBarController animated:YES];
}

#pragma mark -
#pragma mark UISearchBarDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField { }

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar { }

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope { }

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText { }

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar { }

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar { }

#pragma mark -
#pragma mark UINibLoading

- (void)awakeFromNib {
	[super awakeFromNib];
	[self.barButtonItemAddNewDocument setEnabled:YES];
}

#pragma mark -
#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField { return YES; }

#pragma mark -
#pragma mark MADViewControllerStandardProtocol

// This is where we are unloading the view controller, in a sane, and stable way.

- (void)done:(id)sender {
	_shouldShowAddDocumentPopover = YES;

	self.barButtonItemAddNewDocument.enabled = YES;
	
	MADocument *openDocument = self.activeDocumentManager.openDocument;
	if (openDocument && !(openDocument.documentState & UIDocumentStateClosed)) {
		[MADocument close: openDocument completion: ^(BOOL success, NSURL *fileURL, NSURL *cleanupURL) {
			if (success) {
				NSURL *documentURL = [fileURL copy];
				NSURL *dataURL = [cleanupURL copy];
				MADOpenDocumentManager *fileManager = self.activeDocumentManager;
				[fileManager removeDocumentWithUrl:documentURL];
				[MADFileUtilities removeFileAndArchiveAtURL:dataURL];
			}
			[self.navigationController popViewControllerAnimated:YES];
			NSInvocationOperation *opReload = [[NSInvocationOperation alloc] initWithTarget: self
																				   selector: @selector(handleReloadAfterClose)
																					 object: nil];
			[[NSOperationQueue mainQueue] addOperation:opReload];
		}];
		
		[self actionDone:sender];
	}
}

- (void)viewControllerDidFinish:(id)sender {
	[self dismissViewControllerAnimated:YES completion:nil];
	_shouldShowAddDocumentPopover = YES;
	[self.barButtonItemAddNewDocument setEnabled:YES];
	self.fileExplorerViewDelegate.showingPopover = NO;
}

- (void)viewControllerDidCancel:(id)sender {
	[self viewControllerDidFinish:sender];
}

#pragma mark -
#pragma mark MADExplorerControllerProtocol

- (void)handleDocumentStateChangedNotification:(NSNotification *)notification {
	if ([notification.name isEqualToString:UIDocumentStateChangedNotification]) {
		
		switch (((MADocument *)notification.object).documentState) {

			case UIDocumentStateClosed:
				[self handleDocumentStateChangedNotificationClosed:notification];
				break;

			case UIDocumentStateEditingDisabled:
				[self handleDocumentStateChangedNotificationDisabled:notification];
				break;

			case UIDocumentStateInConflict:
				[self handleDocumentStateChangedNotificationConflict:notification];
				break;
				
			case UIDocumentStateNormal:
				[self handleDocumentStateChangedNotificationNormal:notification];
				break;

			case UIDocumentStateSavingError: {
				[self handleDocumentStateChangedNotificationError:notification];
				break;
			}

			default:
				break;
		}

	}
}

- (void)handleDocumentStateChangedNotificationClosed:(NSNotification *)notification {
	[[NSNotificationCenter defaultCenter] removeObserver: self
													name: UIDocumentStateChangedNotification
												  object: /* `MADocument *` */ notification.object];

}

- (void)handleDocumentStateChangedNotificationDisabled:(NSNotification *)notification { }

- (void)handleDocumentStateChangedNotificationConflict:(NSNotification *)notification { }

- (void)handleDocumentStateChangedNotificationNormal:(NSNotification *)notification {
/*
	NSNotification *changeNotification;
	MADocument *document;
	SEL selector;
	changeNotification = notification.copy;
	document = changeNotification.object;
	selector = @selector(openViewer);
	id operation = [[NSInvocationOperation alloc] initWithTarget: self
													 selector: selector
													   object: nil];
	
	[[NSOperationQueue mainQueue] addOperation:operation];*/
}

- (void)handleDocumentStateChangedNotificationError:(NSNotification *)notification {
	[self.fileExplorerViewDelegate collectionView:self.collectionView allowSelection:YES];
	UIAlertController *alert = [UIAlertController alertControllerWithTitle: @"Open Failure"
																   message: [NSString stringWithFormat: @"Failed to open with message:\n\t%@", notification.userInfo]
															preferredStyle: UIAlertControllerStyleAlert];
	[self presentViewController:alert animated:YES completion:nil];
}

#pragma mark -
#pragma mark Private events handlers

- (void)handleReloadAfterClose {
	//NSArray <NSIndexPath *> *visibleItems = self.collectionView.indexPathsForVisibleItems;
	self.collectionView.allowsSelection = YES;
	//[self.collectionView reloadItemsAtIndexPaths:visibleItems];
}

#pragma mark - MADDocumentDelegate

- (MADCredential *)getCredentialsForKey:(NSString *)key {
	NSOperationQueue *credentialQueue = [[NSOperationQueue alloc] init];
	credentialQueue.maxConcurrentOperationCount = 1;
	
	MADKeyChainGetCredentials *cg = [[MADKeyChainGetCredentials alloc] initWithKey:key viewController:self];
	MADKeyChainSaveCredentials *cs = [[MADKeyChainSaveCredentials alloc] initWithKey:key viewController:self];

	[cs addDependency:cg];
	[credentialQueue addOperation:cg];
	[credentialQueue addOperation:cs];
	[credentialQueue waitUntilAllOperationsAreFinished];
	MADCredential *credentials = [cg.credential copy];
	return credentials;
}

- (void)getCredentialsForKey:(NSString *)key
				  completion:(void (^)(MADCredential * _Nullable credential, NSError * _Nullable error))completion {
	MADLogDebug("%@ <%p> getCredentialsForKey:\"%@\" (ASYNC with completion)",
				NSStringFromClass([self class]), self, key);
	
	if (!key || key.length == 0) {
		MADLogError("%@ <%p> getCredentialsForKey: Received nil or empty key.",
					NSStringFromClass([self class]), self);
		if (completion) {
			NSError *keyError = [NSError errorWithDomain:@"FileExplorerDomain"
													code:1001
												userInfo:@{NSLocalizedDescriptionKey:@"Keychain key was missing or empty."}];
			completion(nil, keyError);
		}
		return;
	}
	
	// MADKeyChainGetCredentials is an NSOperation that handles its own asynchronicity (for UI).
	MADKeyChainGetCredentials *getCredsOp = [[MADKeyChainGetCredentials alloc] initWithKey:key
																			viewController:self]; // 'self' is the File Explorer VC
	getCredsOp.name = [NSString stringWithFormat:@"Delegate.AsyncGetKeyChainCredsOp_for_%@", key];
	
	// Use a MADBlockObserver to get the result and call the completion handler
	MADBlockObserver *observer = [[MADBlockObserver alloc] initWithFinishHandler:^(MADOperation * _Nonnull finishedOperation, NSArray<NSError *> * _Nullable opErrors) {
		MADCredential *finalCredential = nil;
		NSError *finalError = opErrors.firstObject; // Use the first error from the operation, if any
		
		if ([finishedOperation isKindOfClass:[MADKeyChainGetCredentials class]]) {
			MADKeyChainGetCredentials *op = (MADKeyChainGetCredentials *)finishedOperation;
			if (op.credential && !finalError) { // Success if credential present and no primary error
				finalCredential = [op.credential copy]; // Copy as per original intent
				MADLogInfo("%@ <%p> getCredentialsForKey: Op <%@> finished. Credential retrieved. Source: %d",
						   NSStringFromClass([self class]), self, finishedOperation.name, (int)op.source);
			} else {
				if (!finalError) { // If op.credential is nil but no error reported by op, create one
					finalError = [NSError errorWithDomain:@"FileExplorerDomain"
													 code:1002
												 userInfo:@{NSLocalizedDescriptionKey:@"Credential operation completed without a credential and no specific error."}];
				}
				MADLogError("%@ <%p> getCredentialsForKey: Op <%@> finished. Credential retrieval failed or op had errors. Error: %@",
							NSStringFromClass([self class]), self, finishedOperation.name, finalError);
			}
		} else {
			MADLogInfo("%@ <%p> getCredentialsForKey: Finished operation was not MADKeyChainGetCredentials? Op: %@. Aggregated errors: %@",
					   NSStringFromClass([self class]), self, finishedOperation, opErrors);
			if (!finalError) {
				finalError = [NSError errorWithDomain:@"FileExplorerDomain" code:1003 userInfo:@{NSLocalizedDescriptionKey:@"Unexpected operation type finished."}];
			}
		}
		
		// Call the original completion handler.
		// This will be on the thread the observer's finishHandler is called on (likely a background thread).
		// If the caller of `getCredentialsForKey:completion:` (i.e., MADDatabase) needs this callback
		// on a specific thread (e.g., its own operation's thread or main), it should handle that dispatch.
		if (completion) {
			completion(finalCredential, finalError);
		}
	}];
	[getCredsOp addObserver:observer];
	
	// Add the operation to a shared background operation queue to execute.
	// Replace with your actual shared queue. For example:
	// [[AppSharedOperationQueues backgroundUtilityQueue] addOperation:getCredsOp];
	// Creating a new one each time is also possible but less efficient if called frequently.
	NSOperationQueue *backgroundQueue = [[NSOperationQueue alloc] init];
	backgroundQueue.name = @"FileExplorer_CredentialFetchingQueue";
	MADLogDebug("%@ <%p> getCredentialsForKey: Adding op <%@> to background queue <%@>.",
				NSStringFromClass([self class]), self, getCredsOp.name, backgroundQueue.name);
	[backgroundQueue addOperation:getCredsOp];
	
	// The method returns immediately; the result is delivered via the completion block.
}

#pragma mark -
#pragma mark Actions

- (IBAction)actionAddDocument:(id)sender {
	
	UINavigationController *navControl = [UINavigationController navigationControllerWithType: MADNavigationControllerTypeNewDocument];
	[MADThemeManager applyAppearanceToNavigationController:navControl traitCollection:self.traitCollection];

	navControl.modalPresentationStyle = UIModalPresentationFormSheet;
	navControl.presentationController.delegate = self;
	
	MADDriverSelectorController *databaseDriverSelector = (MADDriverSelectorController *)navControl.topViewController;
	databaseDriverSelector.delegate = self;
	databaseDriverSelector.saveFileDelegate = self;
	
	self.definesPresentationContext = YES;
	self.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
	
	UIPresentationController *pc = navControl.presentationController;
	pc.presentedView.backgroundColor = [UIColor whiteColor];
	[self showViewController:navControl animated:YES];
}

- (IBAction)actionInformation:(id)sender {
	
	if (_aboutViewControllerOnScreen) {
		_aboutViewControllerOnScreen = NO;
		[self dismissViewControllerAnimated:YES completion:^{ }];
	}
	if (_infoControllerOnScreen) {
		_infoControllerOnScreen = NO;
		[self dismissViewControllerAnimated:YES completion:^{ }];
	} else {
		UINavigationController *infoViewController = [UINavigationController navigationControllerWithType:MADNavigationControllerTypeInformation];
		[MADThemeManager applyAppearanceToNavigationController:infoViewController traitCollection:self.traitCollection];

		infoViewController.modalPresentationStyle = UIModalPresentationPopover;
		infoViewController.preferredContentSize = CGSizeMake(420.0, 480.0);
		
		NSArray *passthoughViews = [self defaultPassthroughViews];
		
		UIPopoverPresentationController *ppc = infoViewController.popoverPresentationController;
		ppc.passthroughViews = [ppc.passthroughViews arrayByAddingObjectsFromArray: passthoughViews];
		ppc.backgroundColor = [UIColor clearColor];
		ppc.delegate = self;
		ppc.barButtonItem = sender;
		
		self.infoPopoverPresentationController = ppc;
		
		[self presentViewController:infoViewController animated:YES completion:nil];
	}
}

- (IBAction)actionAbout:(id)sender {
	
	if (_infoControllerOnScreen) {
		_infoControllerOnScreen = NO;
		[self dismissViewControllerAnimated:YES completion:^{ }];
	}
	
	if (_aboutViewControllerOnScreen) {
		_aboutViewControllerOnScreen = NO;
		[self dismissViewControllerAnimated:YES completion:^{ }];
		
	} else {
		
		_aboutViewControllerOnScreen = YES;
		NSArray *passthoughViews = [self defaultPassthroughViews];
		UITableViewController *aboutViewController = [MADAboutTableViewController newAboutTableViewController];
		aboutViewController.modalPresentationStyle = UIModalPresentationPopover;
		
		UIPopoverPresentationController *ppc = aboutViewController.popoverPresentationController;
		ppc.passthroughViews = [ppc.passthroughViews arrayByAddingObjectsFromArray: passthoughViews];
		ppc.backgroundColor = [UIColor clearColor];
		ppc.delegate = self;
		ppc.barButtonItem = sender;
		
		self.aboutPopoverPresentationController = ppc;
		[self showViewController:aboutViewController animated: YES];
	}
}

- (IBAction)actionDocumentInformation:(id)sender {
	NSArray <NSIndexPath *> *selectedItems = [self.fileExplorerViewDelegate indexPathsForSelectedItems];
	NSMutableArray <MADMetaData *> *metadataItems = [[NSMutableArray alloc] initWithCapacity:selectedItems.count];
	
	for (NSIndexPath *indexPath in selectedItems) {
		MADMetaData *metadata = [self.fileExplorerDataSource metadataAtIndex: (NSUInteger)indexPath.item];
		[metadataItems addObject:metadata];
	}
	
	MADDocumentInformationTableViewController *documentInformation = [MADDocumentInformationTableViewController newDocumentInformationTableViewController];
	documentInformation.modalPresentationStyle = UIModalPresentationPopover;
	
	NSArray *passthoughViews = [self defaultPassthroughViews];
	UIPopoverPresentationController *ppc = documentInformation.popoverPresentationController;
	ppc.passthroughViews = [ppc.passthroughViews arrayByAddingObjectsFromArray:passthoughViews];
	ppc.backgroundColor = [UIColor clearColor];
	ppc.delegate = self;
	ppc.barButtonItem = sender;
	
	self.documentInformationPopoverPresentationController = ppc;
	
	documentInformation.metadataItems = metadataItems;
	
	[self showViewController:documentInformation animated: YES];
}

- (IBAction)actionStore:(id)sender {
	
	UINavigationController *licensing = [UINavigationController navigationControllerWithType: MADNavigationControllerTypeLicensing];
	[MADThemeManager applyAppearanceToNavigationController:licensing traitCollection:self.traitCollection];
	
	licensing.providesPresentationContextTransitionStyle = YES;
	licensing.definesPresentationContext = YES;
	licensing.modalPresentationStyle = UIModalPresentationFormSheet;
	licensing.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
	licensing.presentationController.delegate = self;
	((MADStoreViewController *)licensing.viewControllers[0]).delegate = self;
	self.fileExplorerViewDelegate.showingPopover = YES;
	
	self.navigationController.modalPresentationStyle = UIModalPresentationCurrentContext;
	[self showViewController:licensing animated: YES];
}

- (IBAction)actionCancel:(id)sender {
	[self dismissViewControllerAnimated:YES completion:nil];
	[self.barButtonItemAddNewDocument setEnabled:YES];
}

- (IBAction)actionSearch:(id)sender {
	
	if (self.searchBar.isHidden) {
		
		self.searchBar.hidden = NO;
		self.searchBar.showsCancelButton = NO;
		self.searchBar.alpha = 0.0;
		self.navigationItem.titleView.alpha = 1.0;
		self.navigationItem.leftBarButtonItem.enabled = NO;
		
		self.searchBar.searchBarStyle = UISearchBarStyleMinimal;
		[self.searchBar sizeToFit];
		
		UIView *searchViewHolder = [[UIView alloc] initWithFrame:self.searchBar.bounds];
		self.searchBar.autoresizingMask = MADViewAutoresizingFlexable();
		searchViewHolder.autoresizingMask = MADViewAutoresizingFlexable();
		[searchViewHolder addSubview:self.searchBar];
		[searchViewHolder sizeToFit];
		self.searchBar.translucent = NO;
		self.searchBar.backgroundColor = [UIColor clearColor];
		self.searchBar.barTintColor = [UIColor whiteColor];
		self.searchBar.tintColor = [UIColor whiteColor];
		
		if (self.navigationItem.titleView != nil) {
		
			typeof(self) __weak weakSelf = self;
			UIView *titleView = (UIView * _Nonnull)self.navigationItem.titleView;
			[UIView transitionWithView: titleView
							  duration: 0.2
							   options: UIViewAnimationOptionCurveEaseOut
							animations: ^{
								typeof(self) strongSelf = weakSelf;
								if (strongSelf) {
									strongSelf.searchBar.alpha = 1.0;
									strongSelf.navigationItem.titleView.alpha = 0.0;
									strongSelf.navigationItem.titleView = searchViewHolder;
								}
							} completion:^(BOOL finished) {
								typeof(self) strongSelf = weakSelf;
								if (strongSelf) {
									if (strongSelf.searchBar.isFirstResponder == NO) {
										[strongSelf.searchBar becomeFirstResponder];
										strongSelf.searchBar.hidden = NO;
									}
								}
							}];
		}
		
	} else {
		
		if (self.searchBar.text.length > 0) {
			self.searchBar.text = @"";
		}
		self.searchBar.hidden = YES;
		self.searchBar.alpha = 1.0;
		
		self.navigationItem.titleView.alpha = 0.0;
		self.navigationItem.leftBarButtonItem.enabled = YES;
		
		typeof(self) __weak weakSelf = self;
		UIView *titleView = self.navigationItem.titleView;
		
		[UIView transitionWithView: titleView duration: 0.2 options: UIViewAnimationOptionCurveEaseOut animations:^{
			typeof(self) strongSelf = weakSelf;

			if (strongSelf) {
				strongSelf.searchBar.alpha = 0.0;
				strongSelf.navigationItem.titleView.alpha = 1.0;
				strongSelf.navigationItem.titleView = titleView;
			}
		} completion:^(BOOL finished) {
			if (finished) {
				typeof(self) strongSelf = weakSelf;
				if (strongSelf) {
					strongSelf.searchBar.hidden = YES;
				}
			}
		}];

	}
}

- (IBAction)actionEdit:(id)sender {
	BOOL startEdit = !self.isEditing;
	[self setEditing:startEdit animated:YES];
	if (startEdit) {
		self.barButtonItemAddNewDocument.enabled = NO;
		self.barButtonItemAbout.enabled = NO;
		self.barButtonItemInformation.enabled = NO;
		self.barButtonItemLicensing.enabled = NO;
		self.collectionView.allowsSelection = YES;
		self.collectionView.allowsMultipleSelection = YES;
		for (MADCollectionViewCellDocument *cell in self.collectionView.visibleCells) {
			cell.wobbling = YES;
		}
		[self.navigationItem setRightBarButtonItem: self.barButtonItemEditDone animated: YES];
		
	} else {
		[self actionDone:nil];
	}
}

- (IBAction)actionDone:(id)sender {

	self.editing = NO;
	self.barButtonItemAddNewDocument.enabled = YES;
	self.barButtonItemAbout.enabled = YES;
	self.barButtonItemLicensing.enabled = YES;
	self.barButtonItemInformation.enabled = YES;
	self.barButtonItemTrash.enabled = NO;
	self.barButtonItemInformationDocument.enabled = NO;
	self.barButtonItemDuplicate.enabled = NO;
	self.barButtonItemAction.enabled = NO;

	self.collectionView.allowsMultipleSelection = NO;
	
	[self.navigationItem setRightBarButtonItem:self.barButtonItemEdit animated:YES];
	for (NSIndexPath *path in self.collectionView.indexPathsForSelectedItems) {
		[self.collectionView deselectItemAtIndexPath:path animated:YES];
	}
	
	MADCollectionViewCellDocument *cell;
	for (cell in self.collectionView.visibleCells) {
		cell.wobbling = NO;
	}

}

- (IBAction)actionDownload:(id)sender {
	UIDocumentPickerViewController *picker = [[UIDocumentPickerViewController alloc] initWithDocumentTypes: [self supportedUTIs]
																									inMode: UIDocumentPickerModeImport];
	picker.delegate = self;
	[self presentViewController:picker animated:YES completion:nil];
}

- (IBAction)actionCut:(id)sender {
	[super cut:sender];
}

- (IBAction)actionCopy:(id)sender {
	[super copy:sender];
}

- (IBAction)actionPaste:(id)sender {
	NSURL *url = [[UIPasteboard generalPasteboard].URL copy];
	NSData *data = [[NSData alloc] initWithContentsOfURL:url];
	NSURL *destinationUrl = [MADURLFactory newURLWithUniqueFilenameForURL: url];

	NSFileWrapper *fileWrapper = [[NSFileWrapper alloc] initWithSerializedRepresentation:data];
	NSError *fileWrittingError = nil;
	[fileWrapper writeToURL: destinationUrl
					options: NSFileWrapperWritingAtomic | NSFileWrapperWritingWithNameUpdating
		originalContentsURL: url
					  error: &fileWrittingError];
	if (fileWrittingError != nil) {
		os_log_error(GetDesignerLog(), "Error: %@", fileWrittingError);
		NSError *error = nil;
		[fileWrapper writeToURL: destinationUrl	// Try to write twice
						options: NSFileWrapperWritingAtomic | NSFileWrapperWritingWithNameUpdating
			originalContentsURL: url
						  error: &error];
		if (error != nil) {
			os_log_error(GetDesignerLog(), "Error: %@", error);
		}
	}
	
	[self.collectionView reloadData];
}

- (IBAction)actionActivity:(id)sender {
	
	NSMutableArray *wrappedUrls =
		[[NSMutableArray alloc] initWithCapacity: self.fileExplorerDataSource.count];

	NSArray<NSIndexPath *> *indexPaths = self.collectionView.indexPathsForSelectedItems;
	MADMetaData *metadata;
	NSURL *fileURL;
	NSIndexPath *indexPath;
	for (indexPath in indexPaths) {
		metadata = [_fileExplorerDataSource metadataAtIndex:(NSUInteger)indexPath.item];
		fileURL = [metadata.URL copy];
		[wrappedUrls addObject:fileURL];
	}
	
	//NSInteger numberOfItemsInSection = [self.collectionView numberOfItemsInSection:0];
	//UICollectionViewCell *documentCell;
	//for (NSInteger i=0; i<numberOfItemsInSection; i++) {
	//    indexPath = [NSIndexPath indexPathForItem:i inSection:0];
	//    documentCell = [self.collectionView cellForItemAtIndexPath:indexPath];
	//    documentCell.selected = NO;
	//}
	
	NSArray *applicationActivities, *excludedActivityTypes;
	applicationActivities = [[NSArray alloc] init];
	excludedActivityTypes = [[NSArray alloc] initWithObjects: UIActivityTypeAssignToContact,
															  UIActivityTypePostToFacebook,
															  UIActivityTypePostToFlickr,
															  UIActivityTypePostToTwitter,
															  UIActivityTypePostToVimeo, nil];
	UIActivityViewController *activityViewController;
	activityViewController = [[UIActivityViewController alloc] initWithActivityItems: wrappedUrls
															   applicationActivities: applicationActivities];
	activityViewController.excludedActivityTypes = excludedActivityTypes;
	activityViewController.modalPresentationStyle = UIModalPresentationPopover;
	activityViewController.popoverPresentationController.barButtonItem = sender;
	activityViewController.popoverPresentationController.delegate = self;
	
	MADExplorerController * __weak weakself = self;
	activityViewController.completionWithItemsHandler = ^(NSString *activityType, BOOL completed,
														  NSArray *returnedItems, NSError *activityError) {
	
		for (UITableViewCell *cell in weakself.collectionView.visibleCells) {
			cell.selected = NO;
		}
		
	};
	
	[self presentViewController:activityViewController animated:YES completion:^{ }];
}

- (IBAction)actionDelete:(id)sender {

	NSArray *selectedItems = self.collectionView.indexPathsForSelectedItems;
	UIAlertController *alertController;
	alertController = [MADAlertController newAlertControllerDeleteItems:selectedItems.count
																confirm:^(UIAlertAction *action) {
																	
		for (NSIndexPath *selectedItem in selectedItems) {
			[self.fileExplorerDataSource removeItemAtIndex:(NSUInteger)selectedItem.item];
		}
		
	} cancel:^(UIAlertAction *action) { }];
	
	if ([sender isKindOfClass:[UIBarButtonItem class]]) {
		alertController.popoverPresentationController.barButtonItem = sender;
	}
	[self presentViewController:alertController animated:YES completion:NULL];
}

- (IBAction)actionDuplicate:(id)sender {
	for (NSIndexPath *selectedItem in self.collectionView.indexPathsForSelectedItems) {
		[_fileExplorerDataSource duplicateItemAtIndex:(NSUInteger)selectedItem.item];
	}
}

- (IBAction)actionRename:(id)sender {
	
	if (self.isEditing)
		return;
		
	MADCollectionViewCellDocument *cellDocument;
	
	if ([sender isKindOfClass:[MADCollectionViewCellDocument class]]) {
		cellDocument = sender;
		
	} else if ([sender isKindOfClass:[UITapGestureRecognizer class]]) {
		UIView *contentView = ((UITapGestureRecognizer *)sender).view.superview;
		cellDocument = (MADCollectionViewCellDocument *)contentView.superview;
	}
	
	NSAssert(cellDocument != nil, @"Null cell at %s.", __PRETTY_FUNCTION__);
	
	NSIndexPath *indexPath = [self.collectionView indexPathForCell:cellDocument];
	MADMetaData *metaData = [self.fileExplorerDataSource metadataAtIndex: (NSUInteger)indexPath.item];
	
	NSString *textFieldText = [cellDocument.labelTitle.text copy];
	
	void (^handleRename)(UITextField *) = ^(UITextField *textField) {
		textField.text = [textFieldText copy];
		textField.clearButtonMode = UITextFieldViewModeAlways;
		textField.delegate = self;
	};
	
	void (^handleConfermation)(UIAlertAction *action, NSString *text) = ^(UIAlertAction *action, NSString *text) {
		NSString *name = [self.class safeFilenameWithDesiredFilename:text];
		BOOL shortcircut = NO;
		
		//Test for input
		if (name.length <= 0) {
			UIAlertController *alertError = [UIAlertController alertControllerWithTitle: NSLocalizedString(@"Validation Error", @"Validation Error")
																				message: NSLocalizedString(@"Filename not valid.", @"Filename not valid.")
																		 preferredStyle: UIAlertControllerStyleAlert];
			UIAlertAction *ok = [UIAlertAction actionWithTitle: NSLocalizedString(@"Dismiss", @"Dismiss")
														 style: UIAlertActionStyleDefault
													   handler: nil];
			[alertError addAction:ok];
			
			[self showViewController:alertError animated: YES];
			shortcircut = YES;
		}
		
		//Check if file exist
		NSURL *url = [metaData.URL copy];
		if (!shortcircut && [self.class isUniqueFilename:name inDirectory:url]) {
			UIAlertController *alertError = [UIAlertController alertControllerWithTitle: NSLocalizedString(@"File Exist", @"File Exist")
																		   message: NSLocalizedString(@"File already exist. Please choose a new name.", @"File already exist. Please choose a new name.")
																	preferredStyle: UIAlertControllerStyleAlert];
			UIAlertAction *ok = [UIAlertAction actionWithTitle: NSLocalizedString(@"Dismiss", @"Dismiss")
														 style: UIAlertActionStyleDefault
													   handler: nil];
			[alertError addAction:ok];
			[self showViewController:alertError animated: YES];
			shortcircut = YES;
		}
		
		if (!shortcircut && metaData.isUbiquitousItemDownloadingStatusNotDownloaded) {
			
			MADExplorerDataSource *fileExplorerDataSource = self.fileExplorerDataSource;
			
			void (^closeCompletion)(BOOL, NSURL *, NSURL *) = ^(BOOL successClose, NSURL *fileURL, NSURL *cleanupURL) {
				if (successClose)
					[fileExplorerDataSource rename:text
								itemAtIndex:(NSUInteger)indexPath.item];
			};
			
			MADocument *doc = [MADocument newManagedDocumentForURL:metaData.URL];
			
			void (^openCompletion)(BOOL) = ^(BOOL success) {
				if (success) [MADocument close: doc completion:closeCompletion];
			};
			
			[doc openWithCompletionHandler:openCompletion];
			
		} else {
			[self.fileExplorerDataSource rename:text itemAtIndex:(NSUInteger)indexPath.item];
		}
	};
	
	UIAlertController *alert = [MADExplorerController alertRenameDocument: handleRename
																  confirm: handleConfermation
																   cancel: nil];
	[self showViewController:alert animated: YES];
	
}

- (IBAction)actionEmail:(MADCollectionViewCellDocument *)cell {
	if ([MFMailComposeViewController canSendMail] == NO) {
		id alert = [MADExplorerController alertNotConfiguredForEmail];
		[self showViewController:alert animated: YES];
		return;
	}

	NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
	MADMetaData *metadata = [_fileExplorerDataSource metadataAtIndex:(NSUInteger)indexPath.item];
	MADocument *documentReport = [MADocument newManagedDocumentForURL:metadata.URL];
	
	if (documentReport.documentState != UIDocumentStateClosed) {
		
		void (^handleCloseDocumentCompletion)(BOOL, NSURL *, NSURL *) = ^(BOOL success, NSURL *fileURL, NSURL *cleanupURL) {
			if (success) { [self actionEmail:cell]; }
		};
		[MADocument close: documentReport completion:handleCloseDocumentCompletion];
		
	} else {
		
		NSString *mimeType = [self mimeTypeForDocumentUTI:documentReport.fileType];
		NSMutableString *messageBody = [[NSMutableString alloc] initWithString:NSLocalizedString(@"The attached document can be opened with MAD Viewer.",
																								 @"The attached document can be opened with MAD Viewer.")];
		[messageBody appendString:@"\n\nhttp://www.everydayapps.com/\n\n"];
		
		MFMailComposeViewController	*mailComposer = [MADMailComposeViewController newMailComposeViewControllerWithBody: messageBody
																											attachment: metadata.URL
																											  mimeType: mimeType
																									userInterfaceIdiom: self.traitCollection.userInterfaceIdiom];
		mailComposer.mailComposeDelegate = self;
		[self showViewController:mailComposer animated: YES];
	}

	
}

- (void)actionActivateEditMode:(UICollectionViewCell *)sender {
	[self actionEdit:nil];
	[self selectCell:sender];
}

- (void)selectCell:(UICollectionViewCell *)cell {
	UICollectionView *collectionView = self.collectionView;
	if (collectionView) {
		NSIndexPath *indexPath;
		indexPath = [collectionView indexPathForCell:(UICollectionViewCell *)cell];
		if (indexPath) {
			if ([self.fileExplorerViewDelegate collectionView: collectionView
								  shouldSelectItemAtIndexPath: indexPath]) {
				
				[self.collectionView selectItemAtIndexPath: indexPath
												  animated: YES
											scrollPosition: UICollectionViewScrollPositionNone];
				
				[self.fileExplorerViewDelegate collectionView: collectionView
									 didSelectItemAtIndexPath: indexPath];
			}
		}
	}
}

+ (UIAlertController *)alertRenameDocument:(void (^)(UITextField *textField))textFieldConfig
								   confirm:(void (^)(UIAlertAction *action, NSString *text))handlerConfirm
									cancel:(void (^)(UIAlertAction *action))handlerCancel {
	UIAlertController *alert = [UIAlertController alertControllerWithTitle: NSLocalizedString(@"Rename Document", @"Rename Document")
																   message: NSLocalizedString(@"Please enter a new name for the document.", @"Please enter a new name for the document.")
															preferredStyle: UIAlertControllerStyleAlert];
	[alert addTextFieldWithConfigurationHandler:textFieldConfig];

	UITextField *textField = ((UIAlertController *)alert).textFields.firstObject;
	NSString *text = [textField.text copy];
	UIAlertAction *actionDefault = [UIAlertAction actionWithTitle: NSLocalizedString(@"Rename", @"Rename")
															style: UIAlertActionStyleDefault
														  handler: ^(UIAlertAction *action) {
		handlerConfirm(action, text);
	}];
	[alert addAction:actionDefault];

	UIAlertAction *actionCancel = [UIAlertAction actionWithTitle: NSLocalizedString(@"Cancel", @"Cancel")
											style: UIAlertActionStyleCancel
										  handler: handlerCancel];
	[alert addAction:actionCancel];
	return alert;
}

#pragma mark -
#pragma mark UIAdaptivePresentationControllerDelegate

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:
						(UIPresentationController *)controller {

	UIModalPresentationStyle style = UIModalPresentationOverCurrentContext;
	
		if ([controller isEqual:self.documentInformationPopoverPresentationController]) {
			
			if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
				style = UIModalPresentationNone;
			} else {
				style = UIModalPresentationFullScreen;
			}
		} else if ([controller isEqual:self.infoPopoverPresentationController]) {
			if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
				style = UIModalPresentationNone;
			} else {
				style = UIModalPresentationOverFullScreen;
			}
		} else if ([controller isEqual:self.aboutPopoverPresentationController]) {

			style = UIModalPresentationNone;
		}
	
	return style;
}

#pragma mark -
#pragma mark UIPopoverPresentationControllerDelegate

- (void)prepareForPopoverPresentation:(UIPopoverPresentationController *)controller {
	self.fileExplorerViewDelegate.showingPopover = YES;
	//[self.collectionView reloadData];
}

- (BOOL)presentationControllerShouldDismiss:(UIPresentationController *)presentationController {
	return YES;
}

- (void)presentationControllerDidDismiss:(UIPresentationController *)presentationController {
	self.fileExplorerViewDelegate.showingPopover = NO;
	if ([UIPresentationController isKindOfClass:[UIPopoverPresentationController class]]) {
		UIPopoverPresentationController *popoverPresentationController = (UIPopoverPresentationController *)presentationController;
		popoverPresentationController.passthroughViews = nil;
		popoverPresentationController.barButtonItem = nil;
		popoverPresentationController.delegate = nil;
	}
	_aboutViewControllerOnScreen = NO;
}

#pragma mark -
#pragma mark Update UI

- (void)defaultBarButtonItemState {
	_barButtonItemInformationDocument.enabled = YES;
	_barButtonItemTrash.enabled = YES;
	_barButtonItemDuplicate.enabled = YES;
	_barButtonItemAction.enabled = NO;
}

- (void)enableBarButtonItems {
	_barButtonItemInformationDocument.enabled = YES;
	_barButtonItemTrash.enabled = YES;
	_barButtonItemDuplicate.enabled = YES;
	_barButtonItemAction.enabled = YES;
}

- (void)disableBarButtonItems {
	_barButtonItemInformationDocument.enabled = NO;
	_barButtonItemTrash.enabled = NO;
	_barButtonItemDuplicate.enabled = NO;
	_barButtonItemAction.enabled = NO;
}

- (void)displayActivityIndictor {
	if (_cloudActivityRunning) {
		_cloudActivityRunningDisplay = YES;
		[_headerCloud startAnimating];
	}
}

#pragma mark -
#pragma mark MADOperationObserver

- (void)operationDidStart:(MADOperation *)operation { }

- (void)operation:(MADOperation *)operation didProduceOperation:(NSOperation *)newOperation { }

- (void)operationDidFinish:(MADOperation *)operation
					errors:(NSArray<NSError *> *)errors {
	
}

#pragma mark -
#pragma mark Alert Controllers

+ (UIAlertController *)alertNotConfiguredForEmail {
	id alert = [UIAlertController alertControllerWithTitle: NSLocalizedString(@"Alert", @"Alert")
												   message: NSLocalizedString(@"Device is not configured for email.", @"Device is not configured for email.")
											preferredStyle: UIAlertControllerStyleAlert];
	
	UIAlertAction *ok = [UIAlertAction actionWithTitle: NSLocalizedString(@"Continue", @"Continue")
												 style: UIAlertActionStyleDefault
											   handler: nil];
	[alert addAction:ok];
	return alert;
}

+ (UIAlertController *)alertNotifyCloudSignOut:(void (^)(UIAlertAction *action))handler {
	NSString *MADMessageCloudSignout = @"You have signed out of the iCloud account previously used to store documents. Sign back in to access those documents.";
	UIAlertController *alertController = [UIAlertController alertControllerWithTitle: NSLocalizedString(@"iCloud Sign Out", @"iCloud Sign Out")
																			 message: NSLocalizedString(MADMessageCloudSignout, MADMessageCloudSignout)
																	  preferredStyle: UIAlertControllerStyleAlert];
	UIAlertAction *actionConfirm = [UIAlertAction actionWithTitle: NSLocalizedString(@"Dismiss", @"Dismiss")
															style: UIAlertActionStyleDefault
														  handler: handler];
	[alertController addAction:actionConfirm];
	return alertController;
}

#pragma mark -
#pragma mark Debug Quick Look Object

- (id)debugQuickLookObject {
	NSMutableString *debug = [[NSMutableString alloc] init];
	NSString *classname = NSStringFromClass([self class]);
	id uppercaseClassname = [classname uppercaseString];
	[debug appendFormat:@"--%@--\n", uppercaseClassname];
	[debug appendFormat:@"Collection view delegate:          %@\n", self.fileExplorerViewDelegate];
	[debug appendFormat:@"Active document manager:           %@\n", self.activeDocumentManager];
	[debug appendFormat:@"Document manager:                  %@\n", self.fileExplorerDataSource];
	[debug appendFormat:@"Cloud activity running:            %@\n", _cloudActivityRunning ? @"Yes" : @"No"];
	[debug appendFormat:@"Cloud activity running display:    %@\n", _cloudActivityRunningDisplay ? @"Yes" : @"No"];
	[debug appendFormat:@"Shoulld show add document popover: %@\n", _shouldShowAddDocumentPopover ? @"Yes" : @"No"];
	[debug appendFormat:@"About view controller on screen:   %@\n", _aboutViewControllerOnScreen ? @"Yes" : @"No"];
	[debug appendFormat:@"Activity indicator right visible:  %@\n", _activityIndicatorRightVisible ? @"Yes" : @"No"];
	[debug appendFormat:@"Updating enabled:                  %@\n", _updatingEnabled ? @"Yes" : @"No"];
	[debug appendFormat:@"Get user cloud prefs first call:   %@\n", _getUserCloudPrefsFirstCall ? @"Yes" : @"No"];
	return debug;
}

@end
