//
//  MADExplorerController.m
//  MAD Designer
//
//  Created by Michael Thomason on 1/2/12.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADExplorerController_Private.h"
#import "MADExplorerController+DocumentActions.h"

NSString * const MADUtiType                                     = @"com.everydayapps.productivity.mad";
NSString * const MADUpgradeInstalledSamplesLondon               = @"MADUpgradeInstalledSamplesLondon";
NSString * const MADUpgradeInstalledSamplesMusic                = @"MADUpgradeInstalledSamplesMusic";

static NSString * const MADAppConfigurationUserDefaultsSamplesInstalled     = @"MADAppConfigurationUserDefaultsSamplesInstalled";

static NSString * const MADNotificationCloudActivityStarted                 = @"MADNotificationCloudActivityStarted";
static NSString * const MADNotificationCloudActivityCompleted               = @"MADNotificationCloudActivityCompleted";

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wprotocol"
@implementation MADExplorerController

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
													name: NSUbiquitousKeyValueStoreDidChangeExternallyNotification
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
	[[NSNotificationCenter defaultCenter] removeObserver: self
													name: MADNotificationIdentifierFileUpdate
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
	
	MADOperationInstallSampleDocument *opInstallDocA = [[MADOperationInstallSampleDocument alloc] initWithFilename: @"London"
																									 fileExtension: MADFileExtentionMobleApplicationDocument
																								   groupIdentifier: [AppDelegate groupIdentifier]
																									   installFlag: MADUpgradeInstalledSamplesLondon];
	opInstallDocA.identifier = 3;
	[opInstallDocA addObserver:self];
	[operationQueueBackground addOperation:opInstallDocA];

	
	MADOperationInstallSampleDocument *opInstallDocB = [[MADOperationInstallSampleDocument alloc] initWithFilename: @"Music"
																									 fileExtension: MADFileExtentionMobleApplicationDocument
																								   groupIdentifier: [AppDelegate groupIdentifier]
																									   installFlag: MADUpgradeInstalledSamplesMusic];
	opInstallDocB.identifier = 2;
	[opInstallDocB addObserver:self];
	[operationQueueBackground addOperation:opInstallDocB];
	
	NSOperation *getUserCloudPreferences = [[NSInvocationOperation alloc] initWithTarget: self.fileExplorerDataSource
																				selector: @selector(updateCloudPreferences)
																				  object: NULL];
	[operationQueueBackground addOperation:getUserCloudPreferences];

	self.barButtonItemEdit.accessibilityHint = NSLocalizedString(@"Enables document list edit mode.", @"Enables document list edit mode.");
	self.barButtonItemAddNewDocument.accessibilityHint = NSLocalizedString(@"Adds a new document.", @"Adds a new document.");
#if MAD_VIEWER
	self.barButtonItemAddNewDocument.enabled = NO;
	self.navigationItem.leftBarButtonItem = nil;
#else
	if ([MADApplication isMADViewer]) {
		self.barButtonItemAddNewDocument.enabled = NO;
		self.navigationItem.leftBarButtonItem = nil;
	}
#endif
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
				   withReuseIdentifier: @"MADIdentifierOpenFileSectionHeader"];

	NSMutableArray *toolbarButtons = self.toolbarItems.mutableCopy;
	[toolbarButtons removeObject:_barButtonItemLicensing];
	[toolbarButtons removeObject:_barButtonItemAction];
	[toolbarButtons removeObject:_barButtonItemCloudDown];
	[toolbarButtons removeObject:_barButtonItemInformation];
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

	if ([MADFilesController isCloudReadilyAvailable]) {
		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(handleNotificationUbiquityIdentityDidChange:)
													 name: NSUbiquityIdentityDidChangeNotification
												   object: nil];
		
		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(handleNotificationUbiquityIdentityDidChange:)
													 name: NSUbiquitousKeyValueStoreDidChangeExternallyNotification
												   object: nil];
	}

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
	
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(handleFileUpdateNotification:)
												 name: MADNotificationIdentifierFileUpdate
											   object: nil];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	[self.navigationItem setRightBarButtonItem: _barButtonItemEdit
									  animated: animated];

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

- (UIProgressView *)progressViewFileManager {
	if (!_progressViewFileManager) {
		UIProgressView *progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
		progressView.trackTintColor = [MADColorEverydayApps newColorRed];
		progressView.tintColor = [MADColorEverydayApps newColorBlue];
		progressView.progress = 0.0;
		_progressViewFileManager = progressView;
	}
	return _progressViewFileManager;
}

#pragma mark -
#pragma mark handleFileUpdateNotification

- (void)handleFileUpdateNotification:(NSNotification *)notification {
	if (![notification.object isKindOfClass:[NSURL class]]) {
		return;
	}
	NSURL *updatedFileURL = (NSURL *)notification.object;
	
	__weak MADExplorerController *weakSelf = self;
	[[NSOperationQueue mainQueue] addOperationWithBlock:^{
		__strong MADExplorerController *strongSelf = weakSelf;
		if (!strongSelf) return;
		
		NSIndexPath *indexPathToReload = nil;
		NSUInteger count = [strongSelf.fileExplorerDataSource count];
		for (NSUInteger i = 0; i < count; i++) {
			MADMetaData *metadata = [strongSelf.fileExplorerDataSource metadataAtIndex:i];
			if ([metadata.URL isEqual:updatedFileURL]) {
				indexPathToReload = [NSIndexPath indexPathForItem:(NSInteger)i inSection:0];
				break;
			}
		}
		
		if (indexPathToReload) {
			[[strongSelf collectionView] reloadData];
		}
	}];
}

#pragma mark -
#pragma mark MADDocumentManagerProtocol

- (void)handleDidDisconnectFromClound:(id __unused)sender {
	if (![MADFilesController isCloudDesired]) {
		return;
	}

	__weak MADExplorerController *weakself = self;
	void (^actionConfirm)(UIAlertAction *action) = ^(UIAlertAction *__unused action) {
		__strong MADExplorerController *sself = weakself;
		[sself.fileExplorerDataSource updateCloudPreferences];
	};
		
	[[NSOperationQueue mainQueue] addOperationWithBlock:^{
		
		__strong MADExplorerController *sself = weakself;
		if (!sself) return;
		
		UIAlertController *alert = [MADExplorerController alertNotifyCloudSignOut:actionConfirm];
		[sself presentViewController:alert animated:YES completion:nil];
		
	}];
}

- (void)handleDidStartLongRunningActivity {
	// FIXME: Show activity indicator.
}

- (void)handleDidCompletedLongRunningActivity {
	// FIXME: Hide activity indicator.
}

- (void)documentManagerDidChangeContent:(NSArray <NSIndexPath *> *)inserts
								removes:(NSArray <NSIndexPath *> *)removes
								updates:(NSArray <NSIndexPath *> *)updates
							 completion:(void (^)(BOOL, NSError *))completion {
	if (self.collectionView.window == nil) {
		[self.collectionView reloadData];
		if (completion) {
			completion(YES, nil);
		}
		return;
	}

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
	
	void (^batchCompletion)(BOOL finished) = ^(BOOL __unused finished) {
		if (self.isEditing) {
			for (MADCollectionViewCellDocument *cell in self.collectionView.visibleCells) {
				cell.wobbling = YES;
			}
		}
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
						change:(NSDictionary <NSKeyValueChangeKey, id> * __unused)change
					   context:(void * __unused)context {
	
	if ([keyPath isEqualToString: NSStringFromSelector(@selector(subviews))]) {
		if ([object isKindOfClass:[UITextField class]]) {
			UIImage *image;
			UIView *view;
			NSArray<__kindof UIView *> *subviews = ((UITextField *)object).subviews;
			for (view in subviews) {
				if ([view isKindOfClass:[UIButton class]]) {
					image = [((UIButton *)view).imageView.image
							 imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
					((UIButton *)view).tintColor = [UIColor secondaryLabelColor];
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
	
	[coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull __unused context) {
		[self.collectionView setNeedsDisplay];
		[self.navigationItem.titleView sizeToFit];
	} completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull __unused context) {
		[self.collectionView.collectionViewLayout invalidateLayout];
		if (self.isEditing) {
			for (MADCollectionViewCellDocument *cell in self.collectionView.visibleCells) {
				cell.wobbling = YES;
			}
		}
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
	[coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> __unused context) {
		[self.collectionView.backgroundView setNeedsDisplay];
	} completion:^(id<UIViewControllerTransitionCoordinatorContext> __unused context) {
		[self.collectionView.collectionViewLayout invalidateLayout];
	}];
}

- (UIViewController *)childViewControllerForStatusBarHidden {
	return self.presentedViewController;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
	return UIStatusBarStyleDefault;
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

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer * __unused)gestureRecognizer {
	return YES;
}

#pragma mark -
#pragma mark NSFileManager delegate protocol

- (BOOL)fileManager:(NSFileManager * __unused)fileManager shouldMoveItemAtURL:(NSURL * __unused)srcURL
			  toURL:(NSURL * __unused)dstURL {
	return YES;
}

- (BOOL)fileManager:(NSFileManager * __unused)fileManager shouldProceedAfterError:(NSError * __unused)error movingItemAtURL:(NSURL * __unused)srcURL toURL:(NSURL *)dstURL {
	return [dstURL.pathExtension.lowercaseString isEqualToString:@"png"];
}

#pragma mark -
#pragma mark UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	[((UICollectionView *)scrollView).collectionViewLayout invalidateLayout];
}

#pragma mark -
#pragma mark Touch Event Handlers

- (void)handleDidTapCollectionView:(UIGestureRecognizer * __unused)sender {
	[self.searchBar resignFirstResponder];
	if (self.isEditing) {
		[self actionEdit:self];
	}
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

- (void)handleCloudActivityStarted:(NSNotification * __unused)notification {
	_cloudActivityRunning = YES;
	NSTimer *timer = [NSTimer timerWithTimeInterval: 0.5000f
											 target: self
										   selector: @selector(displayActivityIndictor)
										   userInfo: nil
											repeats: NO];
	[timer fire];
}

- (void)handleContentSizeCategoryDidChangeNotification:(NSNotification * __unused)notification {
	NSArray<__kindof UICollectionViewCell *> *visibleCells = self.collectionView.visibleCells;
	for (MADCollectionViewCellDocument *cell in visibleCells) {
		[cell handleContentSizeCategoryDidChangeNotification];
	}
	[self.view setNeedsLayout];
}

- (void)handleCloudActivityCompleted:(NSNotification * __unused)notification {
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
	if ([self.navigationController.topViewController isKindOfClass:[UINavigationController class]]) {
		[self.navigationController popToRootViewControllerAnimated:NO];
		self.pendingLaunchContext = launchContext;
		return;
	}
}

- (void)handleNotificationUbiquityIdentityDidChange:(NSNotification * __unused)notification {
	if (![MADFilesController isCloudDesired]) {
		return;
	}
	[[NSOperationQueue mainQueue] addOperationWithBlock:^ {
		
		UINavigationController *navController = (UINavigationController *)[UIApplication sharedApplication].safeKeyWindow.rootViewController;
		[navController popToRootViewControllerAnimated:YES];
		
		UIAlertController *signedOutController = [MADExplorerController alertNotifyCloudSignOut:^(UIAlertAction *__unused action) {
			[self.fileExplorerDataSource updateCloudPreferences];
		}];
		
		[self presentViewController:signedOutController animated:YES completion:nil];
	}];
}

#pragma mark -
#pragma mark Property Overrides (Lazy loading)

- (NSNumberFormatter *)subtitleNumberFormatter {
	if (!_subtitleNumberFormatter) {
		_subtitleNumberFormatter = [NSNumberFormatter ma_twoDecimalPlacesFormatter];
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

- (void)openDocumentAtURL:(NSURL *)url completion:(void (^)(void))completion {

	MADocument *document = [[MADocument alloc] initWithFileURL:url];
	document.limitResultsDesignMode = NO;
	document.documentDelegate = self;
	
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(handleDocumentStateChangedNotification:)
												 name: UIDocumentStateChangedNotification
											   object: document];
	
	self.activeDocumentManager.openDocument = document;
	
	[document openWithCompletionHandler:^(BOOL success) {

		if (success) {
			document.documentDelegate = self;
			id operation = [[NSInvocationOperation alloc] initWithTarget: self
																selector: @selector(openViewer)
																  object: nil];
			[[NSOperationQueue mainQueue] addOperation:operation];
		}
		if (completion) {
			completion();
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
	
	[self.navigationController pushViewController:tabBarController animated:YES];
}

#pragma mark -
#pragma mark UISearchBarDelegate

- (void)textFieldDidBeginEditing:(UITextField * __unused)textField { }

- (void)searchBarTextDidBeginEditing:(UISearchBar * __unused)searchBar { }

- (void)searchBar:(UISearchBar * __unused)searchBar selectedScopeButtonIndexDidChange:(NSInteger __unused)selectedScope { }

- (void)searchBar:(UISearchBar * __unused)searchBar textDidChange:(NSString * __unused)searchText { }

- (void)searchBarTextDidEndEditing:(UISearchBar * __unused)searchBar { }

- (void)searchBarCancelButtonClicked:(UISearchBar * __unused)searchBar { }

#pragma mark -
#pragma mark UINibLoading

- (void)awakeFromNib {
	[super awakeFromNib];
#if MAD_VIEWER
	[self.barButtonItemAddNewDocument setEnabled:NO];
	self.navigationItem.leftBarButtonItem = nil;
#else
	if ([MADApplication isMADViewer]) {
		[self.barButtonItemAddNewDocument setEnabled:NO];
		self.navigationItem.leftBarButtonItem = nil;
	} else {
		[self.barButtonItemAddNewDocument setEnabled:YES];
	}
#endif
}

#pragma mark -
#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField * __unused)textField { return YES; }

#pragma mark -
#pragma mark MADViewControllerStandardProtocol

- (void)done:(id)sender {
	_shouldShowAddDocumentPopover = YES;

#if MAD_VIEWER
	self.barButtonItemAddNewDocument.enabled = NO;
#else
	self.barButtonItemAddNewDocument.enabled = ![MADApplication isMADViewer];
#endif
	
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

- (void)viewControllerDidFinish:(id __unused)sender {
	[self dismissViewControllerAnimated:YES completion:nil];
	_shouldShowAddDocumentPopover = YES;
#if MAD_VIEWER
	[self.barButtonItemAddNewDocument setEnabled:NO];
#else
	[self.barButtonItemAddNewDocument setEnabled:![MADApplication isMADViewer]];
#endif
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
												  object: notification.object];
}

- (void)handleDocumentStateChangedNotificationDisabled:(NSNotification * __unused)notification { }

- (void)handleDocumentStateChangedNotificationConflict:(NSNotification * __unused)notification { }

- (void)handleDocumentStateChangedNotificationNormal:(NSNotification * __unused)notification { }

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
	self.collectionView.allowsSelection = YES;
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
	
	MADKeyChainGetCredentials *getCredsOp = [[MADKeyChainGetCredentials alloc] initWithKey:key
																			viewController:self];
	getCredsOp.name = [NSString stringWithFormat:@"Delegate.AsyncGetKeyChainCredsOp_for_%@", key];
	
	MADBlockObserver *observer = [[MADBlockObserver alloc] initWithFinishHandler:^(MADOperation * _Nonnull finishedOperation, NSArray<NSError *> * _Nullable opErrors) {
		MADCredential *finalCredential = nil;
		NSError *finalError = opErrors.firstObject;
		
		if ([finishedOperation isKindOfClass:[MADKeyChainGetCredentials class]]) {
			MADKeyChainGetCredentials *op = (MADKeyChainGetCredentials *)finishedOperation;
			if (op.credential && !finalError) {
				finalCredential = [op.credential copy];
				MADLogInfo("%@ <%p> getCredentialsForKey: Op <%@> finished. Credential retrieved. Source: %d",
						   NSStringFromClass([self class]), self, finishedOperation.name, (int)op.source);
			} else {
				if (!finalError) {
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
		
		if (completion) {
			completion(finalCredential, finalError);
		}
	}];
	[getCredsOp addObserver:observer];
	
	NSOperationQueue *backgroundQueue = [[NSOperationQueue alloc] init];
	backgroundQueue.name = @"FileExplorer_CredentialFetchingQueue";
	MADLogDebug("%@ <%p> getCredentialsForKey: Adding op <%@> to background queue <%@>.",
				NSStringFromClass([self class]), self, getCredsOp.name, backgroundQueue.name);
	[backgroundQueue addOperation:getCredsOp];
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

- (void)prepareForPopoverPresentation:(UIPopoverPresentationController * __unused)controller {
	self.fileExplorerViewDelegate.showingPopover = YES;
}

- (BOOL)presentationControllerShouldDismiss:(UIPresentationController * __unused)presentationController {
	return YES;
}

- (void)presentationControllerDidDismiss:(UIPresentationController *)presentationController {
	self.fileExplorerViewDelegate.showingPopover = NO;
	if ([presentationController isKindOfClass:[UIPopoverPresentationController class]]) {
		UIPopoverPresentationController *popoverPresentationController = (UIPopoverPresentationController *)presentationController;
		popoverPresentationController.passthroughViews = nil;
		popoverPresentationController.barButtonItem = nil;
		popoverPresentationController.delegate = nil;
	}
	_aboutViewControllerOnScreen = NO;
	_infoControllerOnScreen = NO;
}

#pragma mark -
#pragma mark Update UI

- (void)defaultBarButtonItemState {
	_barButtonItemInformationDocument.enabled = YES;
	_barButtonItemTrash.enabled = YES;
	_barButtonItemDuplicate.enabled = YES;
	_barButtonItemAction.enabled = YES;
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

- (void)operationDidStart:(MADOperation * __unused)operation { }

- (void)operation:(MADOperation * __unused)operation didProduceOperation:(NSOperation * __unused)newOperation { }

- (void)operationDidFinish:(MADOperation *)operation
					errors:(NSArray<NSError *> * __unused)errors {
	if ([operation isKindOfClass:[MADOperationInstallSampleDocument class]] && ((MADOperationInstallSampleDocument *)operation).sampleDocumentInstalled) {
		[[NSOperationQueue mainQueue] addOperationWithBlock:^{
			[self.fileExplorerDataSource refresh];
		}];
	}
}

#pragma mark -
#pragma mark Debug Quick Look Object

- (id)debugQuickLookObject {
	NSMutableString *debug = [[NSMutableString alloc] init];
	NSString *uppercaseClassname = [NSStringFromClass([self class]) uppercaseString];
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
#pragma clang diagnostic pop
