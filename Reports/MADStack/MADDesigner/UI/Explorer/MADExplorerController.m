//
//  MADFileExplorerViewController
//  MAD Designer
//
//  Created by Michael Thomason on 1/2/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADExplorerController.h"

#import <QuickLook/QLPreviewController.h>

#import <MessageUI/MFMailComposeViewController.h>

#import <MADFileManager/MADFileUtilities.h>

#import <MADCocoaExtensions/MADAlertController.h>
#import <MADCocoaExtensions/UIColor+EverydayApps.h>
#import <MADCocoaExtensions/MADBarButtonItem.h>
#import <MADCocoaExtensions/NSError+Constructors.h>
#import <MADCocoaExtensions/UIView+Animations.h>
#import <MADCocoaExtensions/MADNumberFormatter.h>
#import <MADCocoaExtensions/MADMailComposeViewController.h>
#import <MADCocoaExtensions/MTMath.h>

#import <MADFoundation/MADApplication.h>
#import <MADFoundation/MADApplicationProtocol.h>
#import <MADFoundation/MADConstantsDocumentExtentions.h>
#import <MADFoundation/MADURL.h>

#import <MADExplorer/MADFileExplorerViewDelegateProtocol.h>
#import <MADExplorer/MADDocumentState.h>
#import <MADExplorer/MADOpenDocumentManager.h>
#import <MADExplorer/MTCollectionViewCellDocument.h>
#import <MADExplorer/MADFileExplorerViewDelegate.h>
#import <MADExplorer/MADLabelFileExplorerDocumentCellTitle.h>

#import <MADFileManager/MADFileInfo.h>
#import <MADFileManager/MADMetaData.h>

#import <MAD/MADConstants.h>
#import <MAD/MADAppLaunchContext.h>
#import <MAD/MADDocumentProtocol.h>
#import <MAD/MADocument.h>
#import <MAD/MADCredential.h>

#import "MADFileExplorerViewControllerProtocol.h"

#import "MADAboutTableViewController.h"
#import "MADDocumentInformationTableViewController.h"
#import "MADFileExplorerDataSource.h"
#import "MADExplorerView.h"

#import "MADOpenFileSectionHeaderView.h"
#import "MADSearchBar.h"
#import "MADProgressView.h"

#import "MADViewControllerStandardProtocol.h"
#import "MADViewerController.h"
#import "MADDesignerViewController.h"
#import "MADQueryViewController.h"
#import "MTDatabaseDriverSelectorViewController.h"
#import "MADStoreViewController.h"

#import "MADNavigationBarTitleView.h"
#import "MADNavigationController.h"

#import "MADQueryVisualizationViewController.h"

#import "MADTabBarController.h"

#import "MADOperation.h"
#import "MADOperationQueue.h"
#import "MADOperationObserver.h"

#import "MADOperationInstallSampleDatabase.h"
#import "MADOperationInstallSampleDocument.h"
#import "MTVerificationController.h"

#import "NSUserDefaults+MADDesigner.h"

#import "MTStoreKitController+Features.h"

#import "MADDocumentManagerProtocol.h"

#import "MADLabelTitle.h"

#import "MADSearchBar.h"

#import "AppDelegate.h"


const NSUInteger MADIDInstallOperationSampleDatabaseChinook     = 1;
const NSUInteger MADIDInstallOperationSampleDocumentMusic       = 2;
const NSUInteger MADIDInstallOperationSampleDocumentLondon      = 3;

static NSString * const MADIdentifierFileLondon                 = @"London";
static NSString * const MADIdentifierFileMusic                  = @"Music";

NSString * const MTSegueOpenInViewer                            = @"MTSegueOpenInViewer";
NSString * const MTSegueShowAddDocument                         = @"showAddDocument";
NSString * const MTSegueLicensing                               = @"MTSegueLicensing";
NSString * const MADUtiType                                     = @"com.everydayapps.productivity.mad";
NSString * const MADUpgradeInstalledSamplesLondon               = @"MADUpgradeInstalledSamplesLondon";
NSString * const MADUpgradeInstalledSamplesMusic                = @"MADUpgradeInstalledSamplesMusic";

static NSString * const MADAppConfigurationUserDefaultsSamplesInstalled     = @"MADAppConfigurationUserDefaultsSamplesInstalled";

static NSString * const MADNotificationCloudActivityStarted               = @"MADNotificationCloudActivityStarted";
static NSString * const MADNotificationCloudActivityCompleted             = @"MADNotificationCloudActivityCompleted";

static NSString * const MADHintAppTitle = @"MAD Designer is the mobile analytics document designer.";
static NSString * const MADHintBarButtonItemEdit = @"Enables document list edit mode.";
static NSString * const MADHintBarButtonItemAddNewDocument = @"Adds a new document.";
static NSString * const MADHintBarButtonItemStore = @"Displays the store.";
static NSString * const MADHintBarButtonItemDelete = @"Deletes the selected documents.";
static NSString * const MADHintBarButtonItemAction = @"Preforms an action on the selected document.";
static NSString * const MADHintBarButtonItemDuplicate = @"Duplicates the selected documents.";
static NSString * const MADHintBarButtonItemDetails = @"Displays selected document details.";
static NSString * const MADHintBarButtonItemInformation = @"Displays selected document details.";
static NSString * const MADHintBarButtonItemAbout = @"Displays selected document details.";
static NSString * const MADTextOpenWithViewer = @"The attached document can be opened with MAD Viewer.";

// FIXME: Get these from AppDelegate using a protocol/deletgate pattern... different for each version of file exploer.
//NSString * const MADUtiPublicData                               = @"public.data";

@interface MADFileExplorerViewController()
    <NSFileManagerDelegate,
        UIViewControllerAnimatedTransitioning,
        UIGestureRecognizerDelegate,
        MFMailComposeViewControllerDelegate,
        UIDocumentInteractionControllerDelegate,
        UIDocumentPickerDelegate,
        UITextFieldDelegate,
        UISearchBarDelegate,
        UIPopoverControllerDelegate,
        UIPopoverControllerDelegate,
        UIPopoverPresentationControllerDelegate,
        MADDocumentManagerProtocol,
        MADocumentDelegate,
        MADViewControllerStandardProtocol,
        MADOperationObserver,
        MADSaveFileProtocol,
        MADFileExplorerViewDelegateProtocol>

    @property (nonatomic, readwrite, strong) MADFileExplorerDataSource *fileExplorerDataSource;
    @property (nonatomic, readwrite, strong) MADFileExplorerViewDelegate *fileExplorerViewDelegate;

    @property (nonatomic, readwrite, strong) MADOpenDocumentManager *activeDocumentManager;

    // This is the collection view
    @property (nonatomic, weak)     IBOutlet MADExplorerView *fileExplorerView;

    @property (nonatomic, strong)   NSNumberFormatter *subtitleNumberFormatter;

    @property (nonatomic, strong)   MADAppLaunchContext *pendingLaunchContext;

    @property (nonatomic, strong)   IBOutlet    UIBarButtonItem *barButtonItemAction;
    @property (nonatomic, strong)               UIBarButtonItem *barButtonItemEdit;
    @property (nonatomic, strong)               UIBarButtonItem *barButtonItemEditDone;
    @property (nonatomic, strong)               UIBarButtonItem *barButtonItemDuplicate;
    @property (nonatomic, weak)     IBOutlet    UIBarButtonItem *barButtonItemInformationDocument;
    @property (nonatomic, weak)     IBOutlet    UIBarButtonItem *barButtonItemTrash;
    @property (nonatomic, weak)     IBOutlet    UIBarButtonItem *barButtonItemInformation;
    @property (nonatomic, weak)     IBOutlet    UIBarButtonItem *barButtonItemAbout;
    @property (nonatomic, weak)     IBOutlet    UIBarButtonItem *barButtonItemAddNewDocument;
    @property (nonatomic, weak)     IBOutlet    UIBarButtonItem *barButtonItemCloudDown;
    @property (nonatomic, weak)     IBOutlet    UIBarButtonItem *barButtonItemLicensing;

    @property (nonatomic, strong)   MADTabBarController *tabController;

    @property (nonatomic, strong)   UIPopoverController *openDocumentPopoverController;
    @property (nonatomic, strong)   UIPopoverController *licensingPopoverController;
    @property (nonatomic, strong)   UIPopoverController *popoverControllerActivity;

    @property (nonatomic, weak)     UIPopoverPresentationController *infoPopoverPresentationController;
    @property (nonatomic, weak)     UIPopoverPresentationController *aboutPopoverPresentationController;
    @property (nonatomic, weak)     UIPopoverPresentationController *documentInformationPopoverPresentationController;

    @property (nonatomic, strong)   MADSearchBar *searchBar;

    @property (nonatomic, strong) UIBarButtonItem *rightBarButtonItemHolderWhileActivity;

    @property (nonatomic, strong) MADOpenFileSectionHeaderView *headerCloud;

    @property (nonatomic, strong) MADProgressView *progressViewFileManager;

    @property (nonatomic, strong) NSArray *defaultPassthroughViews;

@end

@implementation MADFileExplorerViewController {
    
    BOOL _cloudActivityRunning;
    BOOL _cloudActivityRunningDisplay;
    
    BOOL _shouldShowAddDocumentPopover;
    BOOL _aboutViewControllerOnScreen;
    
    BOOL _isActivityIndicatorRightVisible;
    BOOL _activityIndicatorRightVisible;
    BOOL _updatingEnabled;
    BOOL _getUserCloudPrefsFirstCall;
}

#pragma mark -
#pragma mark NSObject

+ (void)initialize {
    [super initialize];
    
    if (self == [MADFileExplorerViewController self]) {
        
        @autoreleasepool {
            
            NSUserDefaults *defaults;
            NSDictionary *defaultsToRegister;
            
            defaults = [MADUserDefaults newUserDefaults];
            defaultsToRegister = [[NSDictionary alloc] initWithObjectsAndKeys:
                                  @NO, MADUpgradeInstalledChinook,
                                  @NO, MADUpgradeInstalledSamples,
                                  @NO, MADAppConfigurationUserDefaultsSamplesInstalled, nil];
            
            [defaults registerDefaults:defaultsToRegister];
            
            UIColor *madColor4 = [MADColorEverydayApps newColorAnalogous4];
            UIColor *redColor = [MADColorEverydayApps newColorRed];
            UIColor *whiteColor = [MADColorEverydayApps newColorWhite];
            
            UITabBarItem *tabBarItemAppearance;
            tabBarItemAppearance = [UITabBarItem appearance];
            id titleTextAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
                                      whiteColor, NSForegroundColorAttributeName, nil];
            [tabBarItemAppearance setTitleTextAttributes: titleTextAttributes
                                                forState: UIControlStateNormal];
            
            UIBarButtonItem *barButtonItem;
            barButtonItem = [UIBarButtonItem appearance];
            barButtonItem.tintColor = whiteColor.copy;
            
            NSArray <Class <UIAppearanceContainer>> *classes;
            UINavigationBar *navigationBar;

            classes = [[NSArray alloc] initWithObjects:[QLPreviewController class], nil];
            navigationBar = [UINavigationBar appearanceWhenContainedInInstancesOfClasses: classes];
            navigationBar.barTintColor  = madColor4.copy;
            navigationBar.tintColor     = redColor.copy;
            
            classes = [[NSArray alloc] initWithObjects: [UINavigationController class], [UIViewController class], nil];
            navigationBar = [UINavigationBar appearanceWhenContainedInInstancesOfClasses: classes];
            navigationBar.tintColor     = whiteColor.copy;
            
            classes = [[NSArray alloc] initWithObjects:[UIToolbar class], nil];
            barButtonItem = [UIBarButtonItem appearanceWhenContainedInInstancesOfClasses: classes];
            barButtonItem.tintColor = whiteColor.copy;
            
            
            UINavigationBar *navigationBarAppearance = [UINavigationBar appearance];
            navigationBarAppearance.titleTextAttributes = titleTextAttributes;
            
            UIColor *orangeColor = [MADColorEverydayApps newColorOrange];
            
            UILabel *labelInTableCell;
            classes = [[NSArray alloc] initWithObjects:[UITableViewCell class], [UICollectionViewCell class], nil];
            labelInTableCell = [UILabel appearanceWhenContainedInInstancesOfClasses: classes];
            labelInTableCell.highlightedTextColor = orangeColor.copy;
            
            
            UIImageView *imageView;
            imageView = [UIImageView appearanceWhenContainedInInstancesOfClasses: classes];
            imageView.tintColor = orangeColor.copy;
            
        }
    }
}

+ (instancetype)newFileExplorerViewController {
    id controller;
    NSString *explorerStoryboardIdentifier, *explorerViewControllerIdentifier;
    explorerStoryboardIdentifier = @"MADDesignerExplorer";
    explorerViewControllerIdentifier = @"MADIdentifierFileExplorerViewController";
    id bundle = [NSBundle mainBundle];
    UIStoryboard *storyboard;
    storyboard = [UIStoryboard storyboardWithName:explorerStoryboardIdentifier bundle:bundle];
    controller = [storyboard instantiateViewControllerWithIdentifier:explorerViewControllerIdentifier];
    return controller;
}

- (void)dealloc {
    
    _barButtonItemAction = nil;
    _subtitleNumberFormatter = nil;
    
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    
    [center removeObserver: self
                      name: NSUbiquityIdentityDidChangeNotification
                    object: nil];
    
    [center removeObserver: self
                      name: UIContentSizeCategoryDidChangeNotification
                    object: nil];
    
    [center removeObserver: self
                      name: MADNotificationCloudActivityStarted
                    object: nil];
    
    [center removeObserver: self
                      name: MADNotificationCloudActivityCompleted
                    object: nil];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    
    if (self = [super initWithCoder:aDecoder]) {
        
        const char *MADQueueFileViewController;
        MADQueueFileViewController = "com.everydayapps.mad.designer.file.explorer.controller";
        
        _shouldShowAddDocumentPopover = YES;
        _getUserCloudPrefsFirstCall = YES;
        _aboutViewControllerOnScreen = NO;
        _updatingEnabled = YES;
        _cloudActivityRunning = NO;
        _cloudActivityRunningDisplay = NO;
        _activityIndicatorRightVisible = NO;

        void (^handleCellLayout)(MADCollectionViewCellDocument *cell);
        handleCellLayout = ^(MADCollectionViewCellDocument *cell) {
            if (cell.delegate == nil) ((MADCollectionViewCellDocument *)cell).delegate = self;
        };

        MADOpenDocumentManager *openFileManager;
        openFileManager = [[MADOpenDocumentManager alloc] init];
        self.activeDocumentManager = openFileManager;

        UIBarButtonItem *barButtonItemDuplicate;
        SEL selector = @selector(actionDuplicate:);
        barButtonItemDuplicate = [MADBarButtonItem newBarButtonItemDuplicate: self
                                                                      action: selector];
        
        self.barButtonItemDuplicate = barButtonItemDuplicate;
        
        selector = @selector(actionEdit:);
        UIBarButtonItem *editButton = [MADBarButtonItem newBarButtonItemEdit: self
                                                                      action: selector];
        self.barButtonItemEdit = editButton;

    }
    return self;
    
}

- (MADFileExplorerDataSource *)fileExplorerDataSource {
    if (!_fileExplorerDataSource) {
        MADFileExplorerDataSource *datasource;
        datasource = [[MADFileExplorerDataSource alloc] initWithCellConfiguration:^(MADCollectionViewCellDocument *cell) {
            if (cell.delegate == nil) ((MADCollectionViewCellDocument *)cell).delegate = self;
        }];
        _fileExplorerDataSource = datasource;
    }
    return _fileExplorerDataSource;
}

- (MADSearchBar *)searchBar {
    if (!_searchBar) {
        MADSearchBar *searchBar = [[MADSearchBar alloc] initWithFrame:CGRectZero];
        _searchBar = searchBar;
    }
    return _searchBar;
}

- (MADProgressView *)progressViewFileManager {
    if (!_progressViewFileManager) {
        MADProgressView *progressView;
        progressView = [MADProgressView newProgressView:MADProgressViewTypeFileExplorer];
        _progressViewFileManager = progressView;
    }
    return _progressViewFileManager;
}

#pragma mark -
#pragma mark UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];

#pragma mark Initialize install operations
    
    //[[NSOperationQueue mainQueue] addOperationWithBlock:^{

        MADOperationQueue *operationQueueBackground;
        NSOperation *getUserCloudPreferences;
        MADOperation *operation;
        NSOperation *resetReceipt;
        
        MADAppDelegate delegate = [MADApplication AppDelegate];
        NSString *groupID = [delegate groupIdentifier].copy;
        
        operationQueueBackground = [[MADOperationQueue alloc] init];
        operationQueueBackground.maxConcurrentOperationCount = 1;
        
        operation = [[MADOperationInstallSampleDatabase alloc] init];
        [operationQueueBackground addOperation:operation];
        
        operation = [[MADOperationInstallSampleDocument alloc] initWithFilename: MADIdentifierFileLondon
                                                                  fileExtension: MADFileExtentionMobleApplicationDocument
                                                                groupIdentifier: groupID
                                                                    installFlag: MADUpgradeInstalledSamplesLondon];
        operation.tag = MADIDInstallOperationSampleDocumentLondon;
        [operation addObserver:self];
        [operationQueueBackground addOperation:operation];
        
        operation = [[MADOperationInstallSampleDocument alloc] initWithFilename: MADIdentifierFileMusic
                                                                  fileExtension: MADFileExtentionMobleApplicationDocument
                                                                groupIdentifier: groupID
                                                                    installFlag: MADUpgradeInstalledSamplesMusic];
        operation.tag = MADIDInstallOperationSampleDocumentMusic;
        [operation addObserver:self];
        [operationQueueBackground addOperation:operation];
        
        SEL storeReceipt = @selector(resetReceipt);
        id target = [MTVerificationController sharedInstance];
        resetReceipt = [[NSInvocationOperation alloc] initWithTarget: target
                                                            selector: storeReceipt
                                                              object: NULL];
        
        [operationQueueBackground addOperation:resetReceipt];
        
        SEL cloudPrefs = @selector(updateCloudPreferences);
        
        MADFileExplorerDataSource *fileExplorerDataSource = self.fileExplorerDataSource;
        getUserCloudPreferences = [[NSInvocationOperation alloc] initWithTarget: fileExplorerDataSource
                                                                       selector: cloudPrefs
                                                                         object: NULL];
        [operationQueueBackground addOperation:getUserCloudPreferences];
        
    //}];
    
    NSString *hint;
    hint = NSLocalizedString(MADHintBarButtonItemEdit, MADHintBarButtonItemEdit);
    self.barButtonItemEdit.accessibilityHint = hint;
    
    hint = NSLocalizedString(MADHintBarButtonItemAddNewDocument,
                             MADHintBarButtonItemAddNewDocument);
    self.barButtonItemAddNewDocument.accessibilityHint = hint;
    
    hint = NSLocalizedString(MADHintBarButtonItemStore, MADHintBarButtonItemStore);
    self.barButtonItemLicensing.accessibilityHint = hint;
    
    hint = NSLocalizedString(MADHintBarButtonItemDelete, MADHintBarButtonItemDelete);
    self.barButtonItemTrash.accessibilityHint = hint;
    
    hint = NSLocalizedString(MADHintBarButtonItemAction, MADHintBarButtonItemAction);
    self.barButtonItemAction.accessibilityHint = hint;
    
    hint = NSLocalizedString(MADHintBarButtonItemDuplicate, MADHintBarButtonItemDuplicate);
    self.barButtonItemDuplicate.accessibilityHint = hint;
    
    hint = NSLocalizedString(MADHintBarButtonItemDetails, MADHintBarButtonItemDetails);
    self.barButtonItemInformationDocument.accessibilityHint = hint;
    
    hint = NSLocalizedString(MADHintBarButtonItemInformation, MADHintBarButtonItemInformation);
    self.barButtonItemInformation.accessibilityHint = hint;
    
    hint = NSLocalizedString(MADHintBarButtonItemAbout, MADHintBarButtonItemAbout);
    self.barButtonItemAbout.accessibilityHint = hint;
    
    [self.collectionView registerClass: [MADOpenFileSectionHeaderView class]
            forSupplementaryViewOfKind: UICollectionElementKindSectionHeader
                   withReuseIdentifier: MADIdentifierOpenFileSectionHeader];
    
    

    NSMutableArray *toolbarButtons = self.toolbarItems.mutableCopy;
    [toolbarButtons removeObject:_barButtonItemAction];
    [toolbarButtons removeObject:_barButtonItemCloudDown];
    [toolbarButtons insertObject:_barButtonItemDuplicate atIndex:1];
    [self setToolbarItems:toolbarButtons animated:NO];
    
    // not editing
    [self setEditing: NO animated: NO];
    
    // add gestures
    
    UITapGestureRecognizer *tapGestureRecognizer;
    SEL didTapCollectionView = @selector(handleDidTapCollectionView:);
    tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget: self
                                                                   action: didTapCollectionView];
    tapGestureRecognizer.delegate = self;
    [self.collectionView addGestureRecognizer:tapGestureRecognizer];
    
    self.fileExplorerDataSource.delegate = self;
    self.collectionView.dataSource = self.fileExplorerDataSource;
    
    // update statusbar?
    [self setNeedsStatusBarAppearanceUpdate];
    
    SEL selector;
    NSNotificationCenter *center;
    center = [NSNotificationCenter defaultCenter];
    selector = @selector(handleNotificationUbiquityIdentityDidChange:);
    [center addObserver: self
               selector: selector
                   name: NSUbiquityIdentityDidChangeNotification
                 object: nil];
    
    selector = @selector(handleContentSizeCategoryDidChangeNotification:);
    [center addObserver: self
               selector: selector
                   name: UIContentSizeCategoryDidChangeNotification
                 object: nil];
    
    selector = @selector(handleCloudActivityStarted:);
    [center addObserver: self
               selector: selector
                   name: MADNotificationCloudActivityStarted
                 object: nil];
    
    selector = @selector(handleCloudActivityCompleted:);
    [center addObserver: self
               selector: selector
                   name: MADNotificationCloudActivityCompleted
                 object: nil];

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
#pragma mark Start observing

    [self.navigationItem setRightBarButtonItem: _barButtonItemEdit
                                      animated: animated];

    @autoreleasepool {

        _barButtonItemLicensing.enabled = [SKPaymentQueue canMakePayments];

    }
    
    // setup ui - navigaion item
    MADLabelTitle *titleView;
    titleView = [[MADLabelTitle alloc] initWithFrame: CGRectZero];
    
    MADAppDelegate delegate = [MADApplication AppDelegate];
    titleView.text = [delegate name].copy;
    titleView.accessibilityHint = NSLocalizedString(MADHintAppTitle, MADHintAppTitle);
    titleView.accessibilityTraits = UIAccessibilityTraitHeader;
    //self.navigationController.providesPresentationContextTransitionStyle;
    //self.navigationItem.titleView = titleView;
    self.navigationItem.hidesBackButton = YES;

    if ([self.toolbarItems containsObject: self.barButtonItemAction] == NO) {
        NSMutableArray *toolbarButtons = self.toolbarItems.mutableCopy;
        [toolbarButtons insertObject: self.barButtonItemAction atIndex: 1];
        [self setToolbarItems:toolbarButtons animated:NO];
    }

    // set delegates
    MADFileExplorerViewDelegate *layoutGroupedDelegate;
    layoutGroupedDelegate = [[MADFileExplorerViewDelegate alloc] init];
    layoutGroupedDelegate.delegate = self;

    self.collectionView.delegate = layoutGroupedDelegate;
    self.fileExplorerViewDelegate = layoutGroupedDelegate;
    
    //[self.collectionView.backgroundView setNeedsDisplay];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    _aboutViewControllerOnScreen = NO;
    
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
#pragma mark MADDocumentManagerProtocol

- (void)handleDidDisconnectFromClound:(id)sender {
    typeof(self) __weak weakself = self;
    
    void (^actionConfirm)(UIAlertAction *action);
    actionConfirm = ^(UIAlertAction *action) {
        MADFileExplorerViewController *sself = weakself;
        [sself.fileExplorerDataSource updateCloudPreferences];
    };
    
    void (^block)(void) = ^ {
        
        MADFileExplorerViewController *sself = weakself;
        if (!sself) return;
        
        UIAlertController *alert;
        alert = [MADAlertController newAlertControllerNotifyCloudSignOut:actionConfirm];
        [sself presentViewController:alert animated:YES completion:nil];
        
    };
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:block];
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

    //NSLog(@"%s", __PRETTY_FUNCTION__);

    UICollectionView *__weak weakCollectionView = self.collectionView;
    
    void (^ batchUpdates)(void);
    void (^ batchCompletion)(BOOL finished);
    
    batchUpdates = ^{
        
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
    
    batchCompletion = ^(BOOL finished) {
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
    // Obtain an app launch context from the provided activity and configure the view controller with it.
    MADAppLaunchContext *launchContext = [[MADAppLaunchContext alloc] initWithUserActivity:activity];
    
    // Configure the view controller with the launch context.
    [self configureViewControllerWithLaunchContext:launchContext];
}

#pragma mark -
#pragma mark UIViewController

//- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator

- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    if (!CGSizeEqualToSize(size, self.view.bounds.size)) {
        [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
            [self.collectionView setNeedsDisplay];
        } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        }];
    }

}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
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
    return YES;
}

#pragma mark -
#pragma mark UIDocumentInteractionControllerDelegate

- (UIViewController *)documentInteractionControllerViewControllerForPreview:
                                            (UIDocumentInteractionController *) controller {
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

- (BOOL)fileManager:(NSFileManager *)fileManager shouldProceedAfterError:(NSError *)error
    movingItemAtURL:(NSURL *)srcURL toURL:(NSURL *)dstURL {
    return [dstURL.pathExtension.lowercaseString isEqualToString:MTDocumentExtentionPoratableNetworkGraphic];
}

#pragma mark -
#pragma mark UIMenuController required methods
/*
- (BOOL)canBecomeFirstResponder {
    //NSLog(@"%s", __PRETTY_FUNCTION__);
    return YES;
}

- (BOOL)canResignFirstResponder {
    return YES;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    //NSLog(@"%s\n\t%@", __PRETTY_FUNCTION__, NSStringFromSelector(action));
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
#pragma mark MADFileExplorerViewDelegateProtocol

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

- (void)documentPicker:(UIDocumentPickerViewController *)controller
  didPickDocumentAtURL:(NSURL *)url {
    [controller removeFromParentViewController];
}

- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller {
    [controller removeFromParentViewController];
}

- (void)showViewController:(UIViewController *)vc sender:(id)sender {
    if (self.presentedViewController != nil) {
        [self dismissViewControllerAnimated: YES completion:^{
            [self presentViewController: vc animated: YES completion: nil];
        }];
    } else {
        [self presentViewController: vc animated: YES completion: nil];
    }
}

- (void)setRightBarButtonItemActivityIndicatorVisible:(BOOL)rightBarButtonItemActivityIndicatorVisible
                                             animated:(BOOL)animated {
    
    if (_activityIndicatorRightVisible == rightBarButtonItemActivityIndicatorVisible) {
        return;
    }
    UIBarButtonItem *barButtonItem;
    
    if ((_activityIndicatorRightVisible = rightBarButtonItemActivityIndicatorVisible)) {
        self.rightBarButtonItemHolderWhileActivity = self.navigationItem.rightBarButtonItem;
        
        UIActivityIndicatorView *activityIndicator;
        activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
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
    NSArray<__kindof UICollectionViewCell *> *visibleCells;
    visibleCells = self.collectionView.visibleCells;
    MADCollectionViewCellDocument *cell;
    for (cell in visibleCells) {
        [cell updateFont];
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

        NSMutableArray *defaultPassthroughViews;
        UINavigationController *controller;
        id view;
        
        defaultPassthroughViews = [[NSMutableArray alloc] initWithCapacity: 2];

        controller = self.navigationController;
        view = controller.toolbar;
        if (view) [defaultPassthroughViews addObject: view];
        
        view = controller.navigationBar;
        if (view) [defaultPassthroughViews addObject: view];
        
        _defaultPassthroughViews = [[NSArray alloc] initWithArray: defaultPassthroughViews];
        
    }
    
    return _defaultPassthroughViews;
}

- (NSURL *)copyMetaDataUrlForIndexPath:(NSIndexPath *)indexPath {
    MADMetaData *metadata = [_fileExplorerDataSource metadataAtIndex:(NSUInteger)indexPath.item];
    return metadata.URL.copy;
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
        
        UINavigationController *navController;
        navController = (UINavigationController *)[UIApplication sharedApplication].windows.firstObject.rootViewController;
        [navController popToRootViewControllerAnimated:YES];
        
        UIAlertController *signedOutController;
        
        signedOutController = [MADAlertController newAlertControllerNotifyCloudSignOut:^(UIAlertAction *action) {
            [self.fileExplorerDataSource updateCloudPreferences];
        }];
        
        [self presentViewController:signedOutController animated:YES completion:nil];
    }];
    
}

#pragma mark -
#pragma mark Add controls

- (void)addProgressViewToView {
    UIProgressView *progressView = self.progressViewFileManager;
    progressView.progress = 0.0000f;
    [self.view addSubview: progressView];
    [self.view bringSubviewToFront: progressView];
}

- (void)removeProgressViewFromView {
    [self.progressViewFileManager removeFromSuperview];
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
        SEL actionEdit = @selector(actionEdit:);
        _barButtonItemEditDone = [MADBarButtonItem newBarButtonItemEditDone: self
                                                                     action: actionEdit];
    }
    return _barButtonItemEditDone;
}

#pragma mark -
#pragma mark UIPopoverControllerDelegate

- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController {
    return [self.openDocumentPopoverController isEqual:popoverController] == NO;
}

#pragma mark - 
#pragma mark MADFileExplorerViewDelegateProtocol

- (BOOL)isFileViewEditing { return self.editing; }

- (MADMetaData *)metadataForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [_fileExplorerDataSource metadataAtIndex: (NSUInteger)indexPath.item];
}

#pragma mark -
#pragma mark UISearchBarDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField { }

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar { }

- (void)searchBar:(UISearchBar *)searchBar
    selectedScopeButtonIndexDidChange:(NSInteger)selectedScope { }

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText { }

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar { }

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar { }

#pragma mark -
#pragma mark UINibLoading

- (void)awakeFromNib {
    [super awakeFromNib];
    [self.barButtonItemAddNewDocument setEnabled:YES];
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    
    BOOL shouldPerformSegueWithIdentifier = YES;
    if ([identifier isEqualToString:MTSegueShowAddDocument]) {
        if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
            shouldPerformSegueWithIdentifier = _shouldShowAddDocumentPopover;
            _shouldShowAddDocumentPopover = NO;
            self.barButtonItemAddNewDocument.enabled = NO;
        }
    } else if ([identifier isEqualToString:MTSegueOpenInViewer]) {
        shouldPerformSegueWithIdentifier = !self.isEditing;
    }
    return shouldPerformSegueWithIdentifier;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [super prepareForSegue:segue sender:sender];

    [self dismissAllPopovers];
    
    if ([segue.identifier isEqualToString:MTSegueLicensing]) {
        [self prepareForSegueLicensing:segue];
    }
}

- (void)prepareForSegueLicensing:(UIStoryboardSegue *)segue {
    if ([segue.destinationViewController isKindOfClass: [UINavigationController class]]) {
        UINavigationController *navControl = segue.destinationViewController;
        id tvc = navControl.topViewController;
        [tvc setDelegate: self];
    }
    [(segue.destinationViewController) setDelegate: self];
    
    if ([segue.destinationViewController isKindOfClass: [UINavigationController class]]) {
        UINavigationController *navControl = segue.destinationViewController;
        if (navControl.topViewController) {
            if ([segue isKindOfClass:[UIStoryboardPopoverSegue class]]) {
                self.licensingPopoverController = ((UIStoryboardPopoverSegue *)segue).popoverController;
            }
        }
    }
}


- (void)prepareForSegueOpenInViewer:(UIStoryboardSegue *)segue sender:(id)sender {
    MADViewerController *viewControllerReportViewer;
    viewControllerReportViewer = (MADViewerController *)((UINavigationController *)segue.destinationViewController).topViewController;
    viewControllerReportViewer.viewControllerDelegate = self;
}

- (void)prepareForSegueShowOpenDocument:(UIStoryboardSegue *)segue sender:(id)sender {

    if ([segue.destinationViewController isKindOfClass: [UINavigationController class]] ||
        [segue.destinationViewController isKindOfClass: [UITabBarController class]]) {
        
        MADTabBarController *tabBarController = (MADTabBarController *)segue.destinationViewController;
        tabBarController.view.tintColor = [MADColorEverydayApps newColorRed];
        self.tabController = tabBarController;
        
    } else if ([segue.destinationViewController isKindOfClass:[MADQueryViewController class]]) {
        MADQueryViewController *queryBuilderViewController;
        queryBuilderViewController = (MADQueryViewController *)[(segue.destinationViewController) topViewController];
        [queryBuilderViewController reloadMainDocumentAnimated:YES];
    }
}

- (BOOL)dismissAllPopovers {
    
    BOOL result = NO;
    if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        
        NSMutableArray *allpopovers = [[NSMutableArray alloc] initWithCapacity:3];
        if (self.openDocumentPopoverController != nil)
            [allpopovers addObject:self.openDocumentPopoverController];
        if (self.licensingPopoverController != nil)
            [allpopovers addObject:self.licensingPopoverController];
        
        for (UIPopoverController *popoverController in allpopovers) {
            if (popoverController.popoverVisible) {
                [popoverController dismissPopoverAnimated:YES];
                result = YES;
            }
        }
        
    }
    return result;
    
}

#pragma mark -
#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField { return YES; }

#pragma mark - UIPopoverControllerDelegate

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    _shouldShowAddDocumentPopover = YES;
    [self.barButtonItemAddNewDocument setEnabled:YES];
}

#pragma mark - 
#pragma mark MADViewControllerStandardProtocol

// This is where we are unloading the view controller, in a sane, and stable way.

- (void)done:(id)sender {
    _shouldShowAddDocumentPopover = YES;

    self.barButtonItemAddNewDocument.enabled = YES;
    [self.openDocumentPopoverController dismissPopoverAnimated:YES];
    
    MADocument *openDocument = self.activeDocumentManager.openDocument;
    if (openDocument && openDocument.documentState != UIDocumentStateClosed) {
        
        void (^handleCloseCompletion)(BOOL, NSURL *, NSURL *);
        handleCloseCompletion = ^(BOOL success, NSURL *fileURL, NSURL *cleanupURL) {
            
            if (success) {
                
                NSURL *documentURL = fileURL.copy;
                NSURL *dataURL = cleanupURL.copy;
                MADOpenDocumentManager *fileManager = self.activeDocumentManager;
                [fileManager removeDocumentWithUrl:documentURL];
                [MADFileUtilities removeFileAndArchiveAtURL:dataURL];
                
            }
            
            self.tabController = nil;
            //NSArray *viewControllers = [[NSArray alloc] init];
            //[tabController setViewControllers:viewControllers animated:YES];
            [self.navigationController popViewControllerAnimated:YES];
            
                id handlerClose;
                handlerClose = [[NSInvocationOperation alloc] initWithTarget:self
                                                                    selector:@selector(handleReloadAfterClose)
                                                                      object:nil];
                [[NSOperationQueue mainQueue] addOperation:handlerClose];
                
            //}];
        };
        
        [MADocument close:openDocument completion:handleCloseCompletion];
    }
}

- (void)viewControllerDidCancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.openDocumentPopoverController dismissPopoverAnimated:YES];
    _shouldShowAddDocumentPopover = YES;
    [self.barButtonItemAddNewDocument setEnabled:YES];
}

#pragma mark -
#pragma mark MADFileExplorerViewControllerDelegate

- (void)handleDocumentStateChangedNotification:(NSNotification *)notification {

    if ([notification.name isEqualToString:UIDocumentStateChangedNotification]) {
        
        NSNotification *changeNotification = notification.copy;
        MADocument *document = changeNotification.object;
        UIDocumentState documentState = document.documentState;
        
        switch (documentState) {

            case UIDocumentStateClosed:
                [self handleDocumentStateChangedNotificationClosed:changeNotification];
                break;

            case UIDocumentStateEditingDisabled:
                //NSLog(@"\n\n\tDocument state editing disabled.\n\n");
                break;

            case UIDocumentStateInConflict:
                //NSLog(@"\n\n\tDocument state in conflict.\n\n");
                break;
                
            case UIDocumentStateNormal:
                [self handleDocumentStateChangedNotificationNormal:changeNotification];
                break;

            case UIDocumentStateSavingError:
                //NSLog(@"\n\n\tDocument state saving error.\n\n");
                break;

            default:
                break;
        }

    }
}

- (void)handleDocumentStateChangedNotificationClosed:(NSNotification *)notification {

    MADocument *document = notification.object;
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: UIDocumentStateChangedNotification
                                                  object: document];

}

- (void)handleDocumentStateChangedNotificationNormal:(NSNotification *)notification {

/*    NSNotification *changeNotification;
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


- (void)openViewer {
    MADocument *document = self.activeDocumentManager.openDocument;
    NSURL *fileURL = document.fileURL.copy;
    NSString *title = fileURL.lastPathComponent.copy;
    
    MADTabBarController *tabBarController;
    tabBarController = [MADTabBarController newTabBarController:document prompt:title];
    
    tabBarController.document = document;
    tabBarController.viewControllerDelegate = self;
    self.tabController = tabBarController;
    
    [self.navigationController pushViewController:tabBarController animated:YES];

}

- (void)openDocumentAtURL:(NSURL *)url {


        MADocument *document = [[MADocument alloc] initWithFileURL:url];
        document.limitResultsDesignMode = [MTStoreKitController sharedObject].isReportingLimited;
        document.documentDelegate = self;
        SEL documentStateChanged = @selector(handleDocumentStateChangedNotification:);
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: documentStateChanged
                                                     name: UIDocumentStateChangedNotification
                                                   object: document];
        
        self.activeDocumentManager.openDocument = document;
        

    [document openWithCompletionHandler:^(BOOL success) {
        if (!success) {
            //NSLog(@"Failed to open file");
        } else {
            SEL selector = @selector(openViewer);
            
            id operation = [[NSInvocationOperation alloc] initWithTarget: self
                                                                selector: selector
                                                                  object: nil];
            
            [[NSOperationQueue mainQueue] addOperation:operation];
        }
    }];

}

- (NSString *)mimeTypeForDocumentUTI:(NSString *)documentType {
    if ([documentType isEqualToString:MADUtiType]) {
        return MADMimeType;
    } else {
        NSAssert(NO, @"Unknown type at %s", __PRETTY_FUNCTION__);
        return MADMimeType;
    }
}

- (NSArray *)supportedUTIs {
    NSArray *UTIs = [[NSArray alloc] initWithObjects: MADUtiType, nil];
    return UTIs;
}

#pragma mark -
#pragma mark Private events handlers

- (void)handleReloadAfterClose {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        @autoreleasepool {
            NSArray <NSIndexPath *> *paths = self.collectionView.indexPathsForVisibleItems.copy;
            [self.collectionView.backgroundView setNeedsDisplay];
            [self.collectionView reloadItemsAtIndexPaths:paths];
        }
    }];
}

#pragma mark - MADDocumentDelegate

- (MADCredential *)getCredentialsForKey:(NSString *)key {
    /*
    NSOperationQueue *credentialQueue = [[NSOperationQueue alloc] init];
    credentialQueue.maxConcurrentOperationCount = 1;
    
    MADKeyChainGetCredentials *cg = [[MADKeyChainGetCredentials alloc] initWithKey:key viewController:self];
    MADKeyChainSaveCredentials *cs = [[MADKeyChainSaveCredentials alloc] initWithKey:key viewController:self];

    [cs addDependency:cg];
    [credentialQueue addOperation:cg];
    [credentialQueue addOperation:cs];
    [credentialQueue waitUntilAllOperationsAreFinished];
    MADCredential *credentials = cg.credential.copy;
    */
    MADCredential *credentials = nil;
    return credentials;
    
}

#pragma mark - 
#pragma mark Actions

- (IBAction)actionAddDocument:(id)sender {
    
    UINavigationController *navigationControl;
    navigationControl = [MADNavigationController newNavigationController: MADNavigationControllerTypeNewDocument];
    navigationControl.modalPresentationStyle = UIModalPresentationFormSheet;
    
    MTDatabaseDriverSelectorViewController *databaseDriverSelector;
    databaseDriverSelector = (MTDatabaseDriverSelectorViewController *)navigationControl.topViewController;
    databaseDriverSelector.delegate = self;
    databaseDriverSelector.saveFileDelegate = self;
    
    self.definesPresentationContext = YES;
    self.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    
    UIPresentationController *pc = navigationControl.presentationController;
    pc.presentedView.backgroundColor = [UIColor whiteColor];
    [self showViewController:navigationControl sender:self];
}

- (IBAction)actionInformation:(id)sender {
    
    UINavigationController *infoViewController;
    infoViewController = [MADNavigationController newNavigationController:MADNavigationControllerTypeInformation];
    infoViewController.modalPresentationStyle = UIModalPresentationPopover;
    infoViewController.preferredContentSize = CGSizeMake(420.0000f, 480.0000f);
    
    NSArray *passthoughViews = [self defaultPassthroughViews];
    UIPopoverPresentationController *ppc = infoViewController.popoverPresentationController;
    ppc.passthroughViews = [ppc.passthroughViews arrayByAddingObjectsFromArray: passthoughViews];
    ppc.backgroundColor = [UIColor clearColor];
    ppc.delegate = self;
    ppc.barButtonItem = sender;
    
    self.infoPopoverPresentationController = ppc;
    
    [self showViewController:infoViewController sender:self];
}

- (IBAction)actionAbout:(id)sender {
    
    if (_aboutViewControllerOnScreen) {
        _aboutViewControllerOnScreen = NO;
        [self dismissViewControllerAnimated:YES completion:^{ }];
        
    } else {
        
        _aboutViewControllerOnScreen = YES;
        
        UITableViewController *aboutViewController;
        UIPopoverPresentationController *ppc;
        NSArray *passthoughViews;
        
        passthoughViews = [self defaultPassthroughViews];

        aboutViewController = [MADAboutTableViewController newAboutTableViewController];
        aboutViewController.modalPresentationStyle = UIModalPresentationPopover;
        
        ppc = aboutViewController.popoverPresentationController;
        ppc.passthroughViews = [ppc.passthroughViews arrayByAddingObjectsFromArray: passthoughViews];
        ppc.backgroundColor = [UIColor clearColor];
        ppc.delegate = self;
        ppc.barButtonItem = sender;
        
        self.aboutPopoverPresentationController = ppc;
        
        [self showViewController:aboutViewController sender:self];
    }
}

- (IBAction)actionDocumentInformation:(id)sender {
    
    MADMetaData *metadata = nil;
    NSArray *selectedItems, *passthoughViews;
    NSIndexPath *indexPath;
    NSMutableArray *metadataItems;
    UIPopoverPresentationController *ppc;
    MADFileExplorerDataSource *fileExplorerDataSource;
    MADDocumentInformationTableViewController *documentInformation;
    
    selectedItems = [self.fileExplorerViewDelegate indexPathsForSelectedItems];
    metadataItems = [[NSMutableArray alloc] initWithCapacity:selectedItems.count];
    
    for (indexPath in selectedItems) {
        metadata = [self.fileExplorerDataSource metadataAtIndex: (NSUInteger)indexPath.item];
        [metadataItems addObject:metadata];
    }
    
    documentInformation = [MADDocumentInformationTableViewController newDocumentInformationTableViewController];
    documentInformation.modalPresentationStyle = UIModalPresentationPopover;
    
    passthoughViews = [self defaultPassthroughViews];
    
    ppc = documentInformation.popoverPresentationController;
    ppc.passthroughViews = [ppc.passthroughViews arrayByAddingObjectsFromArray:passthoughViews];
    ppc.backgroundColor = [UIColor clearColor];
    ppc.delegate = self;
    ppc.barButtonItem = sender;
    
    self.documentInformationPopoverPresentationController = ppc;
    
    documentInformation.metadataItems = metadataItems;
    
    [self showViewController:documentInformation sender:self];
    
    [self actionDone:sender];
    
}

- (IBAction)actionStore:(id)sender {
    
    MADNavigationController *licensing;
    licensing = [MADNavigationController newNavigationController: MADNavigationControllerTypeLicensing];
    licensing.modalPresentationStyle = UIModalPresentationFormSheet;
    licensing.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    ((MADStoreViewController *)licensing.viewControllers[0]).delegate = self;
    [self showViewController:licensing sender:self];
    
}

- (IBAction)actionCancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.barButtonItemAddNewDocument setEnabled:YES];
}

- (IBAction)actionSearch:(id)sender {
    
    if (self.searchBar.isHidden) {
        
        self.searchBar.hidden = NO;
        self.searchBar.showsCancelButton = NO;
        self.searchBar.alpha = 0.0000f;
        self.navigationItem.titleView.alpha = 1.0000f;
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
                              duration: 0.2000f
                               options: UIViewAnimationOptionCurveEaseOut
                            animations: ^{
                                typeof(self) strongSelf = weakSelf;
                                if (strongSelf) {
                                    strongSelf.searchBar.alpha = 1.0000f;
                                    strongSelf.navigationItem.titleView.alpha = 0.0000f;
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
        self.searchBar.alpha = 1.0000f;
        
        self.navigationItem.titleView.alpha = 0.0000f;
        self.navigationItem.leftBarButtonItem.enabled = YES;
        
        typeof(self) __weak weakSelf = self;
        UIView *titleView = self.navigationItem.titleView;
        [UIView transitionWithView: titleView
                          duration: 0.2000f
                           options: UIViewAnimationOptionCurveEaseOut animations:^{
                               typeof(self) strongSelf = weakSelf;
                               if (strongSelf) {
                                   strongSelf.searchBar.alpha = 0.0000f;
                                   strongSelf.navigationItem.titleView.alpha = 1.0000f;
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
        self.collectionView.allowsMultipleSelection = YES;
        
        //NSArray <NSIndexPath *> *visibleItems = self.collectionView.indexPathsForVisibleItems;
        //if (visibleItems != nil)
        //    [self.collectionView reloadItemsAtIndexPaths:visibleItems];
        
        for (MADCollectionViewCellDocument *cell in self.collectionView.visibleCells) {
            [cell setEditing:YES];
        }
        [self.navigationItem setRightBarButtonItem: self.barButtonItemEditDone animated: YES];
        
    } else {
        [self actionDone:nil];
    }
}

- (IBAction)actionDone:(id)sender {

    self.editing = NO;
    //self.barButtonItemLicensing.enabled = [SKPaymentQueue canMakePayments];
    self.barButtonItemAddNewDocument.enabled = YES;
    self.barButtonItemAbout.enabled = YES;
    self.barButtonItemInformation.enabled = YES;
    
    self.barButtonItemTrash.enabled = NO;
    self.barButtonItemInformationDocument.enabled = NO;
    self.barButtonItemDuplicate.enabled = NO;
    self.barButtonItemAction.enabled = NO;
    
    self.collectionView.allowsMultipleSelection = NO;
    
    [self.navigationItem setRightBarButtonItem:self.barButtonItemEdit animated:YES];
    UICollectionView *collectionView = self.collectionView;
    for (NSIndexPath *path in collectionView.indexPathsForSelectedItems) {
        [collectionView deselectItemAtIndexPath:path animated:YES];
    }
    
    NSArray<__kindof UICollectionViewCell *> *visibleCells;
    visibleCells = self.collectionView.visibleCells;
    MADCollectionViewCellDocument *cell;
    for (cell in visibleCells) {
        cell.editing = NO;
    }

}

- (IBAction)actionDownload:(id)sender {
    NSArray *documentTypes = [self supportedUTIs];
    UIDocumentPickerViewController *picker;
    picker = [[UIDocumentPickerViewController alloc] initWithDocumentTypes: documentTypes
                                                                    inMode: UIDocumentPickerModeImport];
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:^{}];
}

- (IBAction)actionCut:(id)sender {
    [super cut:sender];
}

- (IBAction)actionCopy:(id)sender {
    [super copy:sender];
}

- (IBAction)actionPaste:(id)sender {
    id url = [UIPasteboard generalPasteboard].URL;
    id data = [[NSData alloc] initWithContentsOfURL:url];
    id destinationUrl = [MADURL newURLWithUniqueFilenameForURL: url];

    NSFileWrapper *fileWrapper = [[NSFileWrapper alloc] initWithSerializedRepresentation:data];
    
    NSFileWrapperWritingOptions writingOptions = NSFileWrapperWritingAtomic |
                                                 NSFileWrapperWritingWithNameUpdating;
    NSError* fileWrittingError = nil;
    [fileWrapper writeToURL:destinationUrl options:writingOptions originalContentsURL:url
                      error:&fileWrittingError];
    
    if (fileWrittingError) {
        fileWrittingError = nil;
        [fileWrapper writeToURL:destinationUrl options:writingOptions originalContentsURL:url
                          error:&fileWrittingError];
    }
    [self.collectionView reloadData];
}

- (IBAction)actionActivity:(id)sender {
    
    NSMutableArray *wrappedUrls =
        [[NSMutableArray alloc] initWithCapacity: self.fileExplorerDataSource.count];

    NSArray<NSIndexPath *> *indexPaths = self.collectionView.indexPathsForSelectedItems;
    for (NSIndexPath *indexPath in indexPaths) {
        NSURL *fileUrl = [self copyMetaDataUrlForIndexPath:indexPath];
        [wrappedUrls addObject:fileUrl];
    }
    
    NSInteger numberOfItemsInSection = [self.collectionView numberOfItemsInSection:0];
    for (NSInteger i=0; i<numberOfItemsInSection; i++) {
        NSIndexPath *path = [NSIndexPath indexPathForItem:i inSection:0];
        MADCollectionViewCellDocument *documentCell;
        documentCell = (MADCollectionViewCellDocument *)[self.collectionView cellForItemAtIndexPath:path];
        documentCell.selected = NO;
    }
    
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
    
    MADFileExplorerViewController * __weak weakself = self;
    activityViewController.completionWithItemsHandler = ^(NSString *activityType, BOOL completed,
                                                          NSArray *returnedItems, NSError *activityError) {
    
        for (UITableViewCell *cell in weakself.collectionView.visibleCells) {
            MADCollectionViewCellDocument * __weak documentCell = (MADCollectionViewCellDocument *)cell;
            documentCell.selected = NO;
        }
        
    };
    
    if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        if (self.popoverControllerActivity == nil || self.popoverControllerActivity.isPopoverVisible == NO) {

            UIPopoverController *popoverController;
            popoverController = [[UIPopoverController alloc] initWithContentViewController:activityViewController];
            popoverController.delegate = self;
            [popoverController presentPopoverFromBarButtonItem: self.barButtonItemAction
                                      permittedArrowDirections: UIPopoverArrowDirectionAny
                                                      animated: YES];
            self.popoverControllerActivity = popoverController;
            
        }
    } else {
        [self presentViewController:activityViewController animated:YES completion:^{ }];
    }
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
    
    NSString *textFieldText = cellDocument.titleLabelText.copy;
    
    void (^handleRename)(UITextField *);
    handleRename = ^(UITextField *textField) {
        
        textField.text = textFieldText.copy;
        textField.clearButtonMode = UITextFieldViewModeAlways;
        textField.delegate = self;
        
    };
    
    void (^handleConfermation)(UIAlertAction *action, NSString *text);
    handleConfermation = ^(UIAlertAction *action, NSString *text) {
        
        NSString *name = [self.class safeFilenameWithDesiredFilename:text];
        BOOL shortcircut = NO;
        
        //Test for input
        UIAlertController *alert;
        if (name.length <= 0) {
            alert = [MADAlertController newAlertControllerErrorValidationFilename];
            [self showViewController:alert sender:self];
            shortcircut = YES;
        }
        
        //Check if file exist
        NSURL *url = metaData.URL.copy;
        if (!shortcircut && [self.class isUniqueFilename:name inDirectory:url]) {
            alert = [MADAlertController newAlertControllerErrorFileExist];
            [self showViewController:alert sender:self];
            shortcircut = YES;
        }
        
        if (!shortcircut && metaData.isUbiquitousItemDownloadingStatusNotDownloaded) {
            
            MADFileExplorerDataSource *fileExplorerDataSource = self.fileExplorerDataSource;
            
            void (^closeCompletion)(BOOL, NSURL *, NSURL *);
            void (^openCompletion)(BOOL);
            
            closeCompletion = ^(BOOL successClose, NSURL *fileURL, NSURL *cleanupURL) {
                if (successClose)
                    [fileExplorerDataSource rename:text
                                itemAtIndex:(NSUInteger)indexPath.item];
            };
            
            MADocument *doc = [MADocument newManagedDocumentForURL:metaData.URL];
            
            openCompletion = ^(BOOL success) {
                if (success) [MADocument close: doc completion:closeCompletion];
            };
            
            [doc openWithCompletionHandler:openCompletion];
            
        } else {
            [self.fileExplorerDataSource rename:text itemAtIndex:(NSUInteger)indexPath.item];
        }
    };

    UIAlertController *alert = [MADAlertController newAlertControllerRenameDocument: handleRename
                                                         confirm: handleConfermation
                                                          cancel: nil];
    
    [self showViewController:alert sender:self];
    
}

- (IBAction)actionEmail:(MADCollectionViewCellDocument *)cell {
    
    NSIndexPath *indexPath;
    MADMetaData *metadata;
    MADocument *documentReport;
    
    if ([MFMailComposeViewController canSendMail] == NO) {
        id alert;
        alert = [MADAlertController newAlertControllerNotConfiguredForEmail];
        [self showViewController:alert sender:self];
        return;
    }

    indexPath = [self.collectionView indexPathForCell:cell];
    metadata = [_fileExplorerDataSource metadataAtIndex:(NSUInteger)indexPath.item];
    documentReport = [MADocument newManagedDocumentForURL:metadata.URL];
    
    if (documentReport.documentState != UIDocumentStateClosed) {
        
        void (^handleCloseDocumentCompletion)(BOOL, NSURL *, NSURL *);
        handleCloseDocumentCompletion = ^(BOOL success, NSURL *fileURL, NSURL *cleanupURL) {
            if (success) { [self actionEmail:cell]; }
        };
        [MADocument close: documentReport completion:handleCloseDocumentCompletion];
        
    } else {
        
        NSString *mimeType = [self mimeTypeForDocumentUTI:documentReport.fileType];
        NSString *messageStringStart = NSLocalizedString(MADTextOpenWithViewer, MADTextOpenWithViewer);
        NSMutableString *messageBody = [[NSMutableString alloc] initWithString:messageStringStart];
        [messageBody appendString:@"\n\nhttp://www.everydayapps.com/\n\n"];
        
        MFMailComposeViewController	*mailComposer;
        mailComposer = [MADMailComposeViewController newMailComposeViewControllerWithBody: messageBody
                                                                               attachment: metadata.URL
                                                                                 mimeType: mimeType
                                                                       userInterfaceIdiom: self.traitCollection.userInterfaceIdiom];
        mailComposer.mailComposeDelegate = self;
        [self showViewController:mailComposer sender:self];
    }

    
}

- (IBAction)actionActivateEditMode:(UILongPressGestureRecognizer *)sender {

    if (sender.state != UIGestureRecognizerStateBegan) return;

    [self actionEdit:nil];

    UICollectionView *collectionView = self.collectionView;
    NSIndexPath *indexPath;
    if (sender.view) {
        if ([sender.view isKindOfClass:[UICollectionViewCell class]]) {
            indexPath = [collectionView indexPathForCell:(UICollectionViewCell *)sender.view];
        }
    }
    
    if (indexPath) {
        if ([self.fileExplorerViewDelegate collectionView: collectionView
                            shouldSelectItemAtIndexPath: indexPath]) {
            
            [collectionView selectItemAtIndexPath: indexPath
                                         animated: YES
                                   scrollPosition: UICollectionViewScrollPositionNone];
            
            [self.fileExplorerViewDelegate collectionView: collectionView
                               didSelectItemAtIndexPath: indexPath];
        }
    }
    NSArray <NSIndexPath *> *selectedPath =
    [[NSArray alloc] initWithObjects:indexPath, nil];
    [collectionView reloadItemsAtIndexPaths:selectedPath];
}

#pragma mark -
#pragma mark UIAdaptivePresentationControllerDelegate

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:
                        (UIPresentationController *)controller {

    UIModalPresentationStyle style = UIModalPresentationOverCurrentContext;
    if ([controller isEqual:self.aboutPopoverPresentationController] ||
        [controller isEqual:self.infoPopoverPresentationController] ||
        [controller isEqual:self.documentInformationPopoverPresentationController]) {
        style = UIModalPresentationNone;
        
    }
    
    return style;
}

#pragma mark - 
#pragma mark UIPopoverPresentationControllerDelegate

- (void)prepareForPopoverPresentation: (UIPopoverPresentationController *)controller { }

- (BOOL)popoverPresentationControllerShouldDismissPopover: (UIPopoverPresentationController *)controller {
    return YES;
}

- (void)popoverPresentationControllerDidDismissPopover: (UIPopoverPresentationController *)controller {
    
    controller.passthroughViews = nil;
    controller.barButtonItem = nil;
    controller.delegate = nil;
    
    _aboutViewControllerOnScreen = NO;
}

#pragma mark -
#pragma mark Update UI

- (void)fileExplorerDidChangeNumberOfItemsSelected:(NSUInteger)numberOfItemsSelected {

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
                    errors:(NSArray *)errors {

    switch (operation.tag) {

        case MADIDInstallOperationSampleDocumentMusic:
        case MADIDInstallOperationSampleDocumentLondon: {
// FIXME: Trigger reload after install... without crashing.
            break;
        }
            
        default:
            break;
    }
}

#pragma mark -
#pragma mark Helpers

+ (BOOL)isUniqueFilename:(NSString *)name inDirectory:(NSURL *)directory {
    NSURL *renamedURL = [directory.URLByDeletingLastPathComponent
                     URLByAppendingPathComponent:name isDirectory:NO];
    NSString *path = renamedURL.path;
    BOOL result = [[NSFileManager defaultManager] fileExistsAtPath:path] ||
                  [[NSFileManager defaultManager] isUbiquitousItemAtURL:renamedURL];
    return result;
}

+ (NSString *)safeFilenameWithDesiredFilename:(NSString *)desiredName {
    
    NSMutableCharacterSet *characterSet = [[NSMutableCharacterSet alloc] init];
    
    NSCharacterSet *unionSet = [NSCharacterSet alphanumericCharacterSet];
    [characterSet formUnionWithCharacterSet:unionSet];
    
    unionSet = [NSCharacterSet whitespaceCharacterSet];
    [characterSet formUnionWithCharacterSet:unionSet];
    
    unionSet = characterSet.invertedSet;
    NSArray *components = [desiredName componentsSeparatedByCharactersInSet:unionSet];
    NSString *result = [components componentsJoinedByString:@""];
    return result.copy;
    
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
