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

#import "MADFileExplorerViewController.h"
#import "MADFileExplorerViewControllerProtocol.h"

#import <MADExplorer/MADCollectionViewLayoutGroupedDelegateProtocol.h>
//#import <MADFileManager/MADFilesControllerDelegate.h>

#import <QuickLook/QLPreviewController.h>

#import "MADDocumentManager.h"

#import "MADFileExplorerView.h"

#import <MADCocoaExtensions/UIAlertController+Constructors.h>
#import <MADCocoaExtensions/UIColor+EverydayApps.h>
#import <MADCocoaExtensions/UIBarButtonItem+Constructors.h>
#import <MADCocoaExtensions/NSError+Constructors.h>
#import <MADCocoaExtensions/UIView+Animations.h>
#import <MADCocoaExtensions/NSNumberFormatter+Constructors.h>
#import <MADCocoaExtensions/MFMailComposeViewController+Constructors.h>
#import <MADCocoaExtensions/MTMath.h>

#import <MADFoundation/UIApplication+MADAppDelegate.h>
#import <MADFoundation/MADApplicationProtocol.h>
#import <MADFoundation/MADConstantsDocumentExtentions.h>
#import <MADFoundation/NSURL+Document.h>

#import <MADExplorer/MADDocumentState.h>
#import <MADExplorer/MADFileLocationManager.h>
#import <MADExplorer/MADActiveDocumentManager.h>
#import <MADExplorer/MTCollectionViewCellDocument.h>
#import <MADExplorer/MADCollectionViewLayoutGroupedDelegate.h>

#import <MADFileManager/MADFilesController.h>
#import <MADFileManager/MADFileInfo.h>
#import <MADFileManager/MADMetaData.h>
#import <MADFileManager/MADFilesController.h>

#import <MAD/MADConstants.h>
#import <MAD/MADAppLaunchContext.h>
#import <MAD/MADDocumentProtocol.h>
#import <MAD/MADocument.h>
#import <MAD/MADCredential.h>

#import "MADOpenFileSectionHeaderView.h"
#import "MADSearchBar.h"
#import "MADProgressView.h"

#import "MUIViewControllerDelegate.h"
#import "MADQueryBuilderSplitViewController.h"
#import "MADViewerController.h"
#import "MADDesignerViewController.h"
#import "MADQueryViewController.h"
#import "MTDatabaseDriverSelectorViewController.h"
#import "MADStoreViewController.h"

#import "MADNavigationBarTitleView.h"
#import "MADNavigationController.h"

#import "MADQueryBuilderSplitViewController.h"
#import "MADQueryVisualizationViewController.h"

#import "MADTabBarController.h"

#import "MADOperation.h"
#import "MADOperationQueue.h"
#import "MADOperationObserver.h"

#import "MADInstallOperationSampleDatabase.h"
#import "MADInstallOperationSampleDocument.h"
#import "MTVerificationController.h"

#import "NSUserDefaults+MADDesigner.h"
#import "UIStoryboard+Query.h"
#import "UINavigationController+MADQuery.h"
#import "UINavigationController+Designer.h"

#import "UITabBarController+Shared.h"
#import "UITableViewController+Designer.h"
#import "MTStoreKitController+Features.h"
#import "MADDocumentInformationTableViewController+Designer.h"

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

const char * MADQueueFileViewController                                     = "com.everydayapps.mad.designer.file.view.controller";

NSString * const MADIdentifierOpenFileSectionHeader                         = @"MADIdentifierOpenFileSectionHeader";

static NSString * const MADIDNotificationCloudActivityStarted               = @"MADNotificationCloudActivityStarted";
static NSString * const MADIDNotificationCloudActivityCompleted             = @"MADNotificationCloudActivityCompleted";

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

// FIXME: Get these from AppDelegate using a protocol/deletgate pattern... different for each version of file exploer.
//NSString * const MADUtiPublicData                               = @"public.data";


@interface MADFileExplorerViewController()
    <NSFileManagerDelegate,
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
        MTViewControllerProtocol,
        MADOperationObserver,
        MADSaveFileProtocol,
        MADFileExplorerViewDelegateProtocol>

    @property (nonatomic, readwrite, strong) MADFileExplorerViewDelegate *collectionViewDelegate;

    // ActiveDocumentManager holds strong reference to open documents.
    @property (nonatomic, readwrite, strong) MADActiveDocumentManager *activeDocumentManager;

    // Document Manager manages the file location for the documents.
    @property (nonatomic, readwrite, strong) MADDocumentManager *documentManager;

    // This is the collection view
    @property (weak, nonatomic) IBOutlet MADFileExplorerView *fileExplorerView;

    @property (nonatomic, strong) NSNumberFormatter *subtitleNumberFormatter;

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

    @property (nonatomic, weak)     MADQueryBuilderSplitViewController *splitViewController;
    @property (nonatomic, weak)     MADTabBarController *tabController;

    @property (nonatomic, strong)   UIPopoverController *openDocumentPopoverController;
    @property (nonatomic, strong)   UIPopoverController *licensingPopoverController;
    @property (nonatomic, strong)   UIPopoverController *popoverControllerActivity;

    @property (nonatomic, weak)     UIPopoverPresentationController *infoPopoverPresentationController;
    @property (nonatomic, weak)     UIPopoverPresentationController *aboutPopoverPresentationController;
    @property (nonatomic, weak)     UIPopoverPresentationController *documentInformationPopoverPresentationController;

    @property (nonatomic, strong)   MADSearchBar *searchBar;

    @property (nonatomic, strong) UIBarButtonItem *rightBarButtonItemHolderWhileActivity;

    @property (nonatomic, strong) MADOpenFileSectionHeaderView *headerCloud;

    @property (nonatomic, assign) BOOL cloudActivityRunning;
    @property (nonatomic, assign) BOOL cloudActivityRunningDisplay;

    @property (nonatomic, assign) BOOL shouldShowAddDocumentPopover;
    @property (nonatomic, assign) BOOL aboutViewControllerOnScreen;

    @property (nonatomic, assign, getter=isActivityIndicatorRightVisible)
                                                BOOL activityIndicatorRightVisible;
    @property (nonatomic, assign, getter=isUpdatingEnabled) BOOL updatingEnabled;
    @property (nonatomic, assign) BOOL getUserCloudPrefsFirstCall;

    @property (nonatomic, strong) UIProgressView *progressViewFileManager;

@end

@implementation MADFileExplorerViewController

#pragma mark -
#pragma mark NSObject

- (void)dealloc {
    _barButtonItemAction = nil;
    _subtitleNumberFormatter = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: NSUbiquityIdentityDidChangeNotification
                                                  object: nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: UIContentSizeCategoryDidChangeNotification
                                                  object: nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: MADIDNotificationCloudActivityStarted
                                                  object: nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: MADIDNotificationCloudActivityCompleted
                                                  object: nil];

}

+ (void)initialize {
    [super initialize];
    if (self == [MADFileExplorerViewController self]) {
    
        NSUserDefaults *defaults;
        NSDictionary *defaultsToRegister;
        
        defaults = [NSUserDefaults newUserDefaultsMADDesigner];
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
        
        UIBarButtonItem *barButtonItem;
        barButtonItem = [UIBarButtonItem appearance];
        barButtonItem.tintColor = whiteColor.copy;
        
        UINavigationBar *navigationBar;
        Class controlClass;
        controlClass = [QLPreviewController class];
        navigationBar = [UINavigationBar appearanceWhenContainedIn:controlClass, nil];
        navigationBar.barTintColor  = madColor4.copy;
        navigationBar.tintColor     = redColor.copy;

        controlClass = [UIViewController class];
        navigationBar = [UINavigationBar appearanceWhenContainedIn:controlClass, nil];
        navigationBar.tintColor     = whiteColor.copy;

        controlClass = [UINavigationController class];
        navigationBar = [UINavigationBar appearanceWhenContainedIn:controlClass, nil];
        navigationBar.tintColor     = whiteColor.copy;

        controlClass = [UIToolbar class];
        barButtonItem = [UIBarButtonItem appearanceWhenContainedIn:controlClass, nil];
        barButtonItem.tintColor = whiteColor.copy;
        
        id titleTextAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
                                  whiteColor, NSForegroundColorAttributeName, nil];
        [tabBarItemAppearance setTitleTextAttributes: titleTextAttributes
                                            forState: UIControlStateNormal];

        UINavigationBar *navigationBarAppearance = [UINavigationBar appearance];
        navigationBarAppearance.titleTextAttributes = titleTextAttributes;
        
        UIColor *orangeColor = [MADColorEverydayApps newColorOrange];

        UILabel *labelInTableCell;
        controlClass = [UITableViewCell class];
        labelInTableCell = [UILabel appearanceWhenContainedIn:controlClass, nil];
        labelInTableCell.highlightedTextColor = orangeColor.copy;
        
        UILabel *labelInCollectionCell;
        labelInCollectionCell = [UILabel appearanceWhenContainedIn:controlClass, nil];
        labelInCollectionCell.highlightedTextColor = orangeColor.copy;
        
        UIImageView *imageInCollectionViewCell;
        imageInCollectionViewCell = [UIImageView appearanceWhenContainedIn:controlClass, nil];
        imageInCollectionViewCell.tintColor = orangeColor.copy;
        
    }
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
    
        _shouldShowAddDocumentPopover = YES;
        _getUserCloudPrefsFirstCall = YES;

    }
    return self;
}

#pragma mark -
#pragma mark UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    MADDocumentManager *documentManager = [[MADDocumentManager alloc] init];
    documentManager.delegate = self;
    self.documentManager = documentManager;
    
    MADActiveDocumentManager *openFiles;
    openFiles = [[MADActiveDocumentManager alloc] init];
    self.activeDocumentManager = openFiles;
    
    MADProgressView *progressView;
    progressView= [[MADProgressView alloc] initWithProgressViewStyle: UIProgressViewStyleBar];
    self.progressViewFileManager = progressView;
        
    // set delegates
    MADFileExplorerViewDelegate *layoutGroupedDelegate;
    layoutGroupedDelegate = [[MADFileExplorerViewDelegate alloc] init];
    layoutGroupedDelegate.delegate = self;
    
    self.collectionView.delegate = layoutGroupedDelegate;
    self.collectionView.dataSource = self;
    self.collectionViewDelegate = layoutGroupedDelegate;
    
#pragma mark Start observing
    
    SEL resultHandler;
    
    resultHandler = @selector(handleNotificationUbiquityIdentityDidChange:);
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: resultHandler
                                                 name: NSUbiquityIdentityDidChangeNotification
                                               object: nil];
    
    resultHandler = @selector(handleContentSizeCategoryDidChangeNotification:);
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: resultHandler
                                                 name: UIContentSizeCategoryDidChangeNotification
                                               object: nil];
    
    resultHandler = @selector(handleCloudActivityStarted:);
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: resultHandler
                                                 name: MADIDNotificationCloudActivityStarted
                                               object: nil];
    
    resultHandler = @selector(handleCloudActivityCompleted:);
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: resultHandler
                                                 name: @"MADNotificationCloudActivityCompleted"
                                               object: nil];

#pragma mark Initalize install operations

    MADOperationQueue *operationQueueBackground;
    operationQueueBackground = [[MADOperationQueue alloc] init];
    operationQueueBackground.maxConcurrentOperationCount = 1;
    
    NSOperation *getUserCloudPreferences;
    MADOperation *operation;
    NSOperation *resetReceipt;
    
    operation = [[MADInstallOperationSampleDatabase alloc] init];
    [operationQueueBackground addOperation:operation];
    
    NSString *groupID = [self.documentManager groupIdentifier].copy;
    operation = [[MADInstallOperationSampleDocument alloc] initWithFilename: MADIdentifierFileLondon
                                                              fileExtension: MADFileExtentionMobleApplicationDocument
                                                            groupIdentifier: groupID
                                                                installFlag: MADUpgradeInstalledSamplesLondon];
    operation.tag = MADIDInstallOperationSampleDocumentLondon;
    [operation addObserver:self];
    [operationQueueBackground addOperation:operation];
    
    operation = [[MADInstallOperationSampleDocument alloc] initWithFilename: MADIdentifierFileMusic
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
    getUserCloudPreferences = [[NSInvocationOperation alloc] initWithTarget: _documentManager
                                                                   selector: cloudPrefs
                                                                     object: NULL];
    [operationQueueBackground addOperation:getUserCloudPreferences];
    
    
    // init
    _aboutViewControllerOnScreen = NO;
    _updatingEnabled = YES;
    _cloudActivityRunning = NO;
    _cloudActivityRunningDisplay = NO;
    _activityIndicatorRightVisible = NO;
    
    [self.collectionView registerClass: [MADOpenFileSectionHeaderView class]
            forSupplementaryViewOfKind: UICollectionElementKindSectionHeader
                   withReuseIdentifier: MADIdentifierOpenFileSectionHeader];

    // setup ui - navigaion item
    MADNavigationBarTitleView *titleView;
    titleView = [[MADNavigationBarTitleView alloc] initWithFrame: CGRectZero];
    
    MADAppDelegate delegate = [MADApplication AppDelegate];
    NSString *name = [delegate name];
    titleView.text = name.copy;
    titleView.accessibilityHint = NSLocalizedString(MADHintAppTitle, MADHintAppTitle);
    titleView.accessibilityTraits = UIAccessibilityTraitHeader;
    
    self.navigationItem.titleView = titleView;
    self.navigationItem.hidesBackButton = YES;
    
    // setup ui - search bar
    
    MADSearchBar *searchBar = [[MADSearchBar alloc] initWithFrame:CGRectZero];
    _searchBar = searchBar;
    
    // setup ui - bar button items
    
    NSString *hint;
    
    UIBarButtonItem *barButtonItemDuplicate;
    SEL handleDuplicate = @selector(actionDuplicate:);
    barButtonItemDuplicate = [UIBarButtonItem newBarButtonItemDuplicate: self
                                                                 action: handleDuplicate];
    
    NSMutableArray *toolbarButtons = self.toolbarItems.mutableCopy;
    [toolbarButtons removeObject:_barButtonItemAction];
    [toolbarButtons removeObject:_barButtonItemCloudDown];
    [toolbarButtons insertObject:barButtonItemDuplicate atIndex:1];
    [self setToolbarItems:toolbarButtons animated:NO];
    _barButtonItemDuplicate = barButtonItemDuplicate;
    
    UIBarButtonItem *editButton = [UIBarButtonItem newBarButtonItemEdit: self
                                                                 action: @selector(actionEdit:)];
    _barButtonItemEdit = editButton;
    
    hint = NSLocalizedString(MADHintBarButtonItemEdit, MADHintBarButtonItemEdit);
    _barButtonItemEdit.accessibilityHint = hint;
    
    hint = NSLocalizedString(MADHintBarButtonItemAddNewDocument,
                             MADHintBarButtonItemAddNewDocument);
    _barButtonItemAddNewDocument.accessibilityHint = hint;
    
    hint = NSLocalizedString(MADHintBarButtonItemStore, MADHintBarButtonItemStore);
    _barButtonItemLicensing.accessibilityHint = hint;
    
    hint = NSLocalizedString(MADHintBarButtonItemDelete, MADHintBarButtonItemDelete);
    _barButtonItemTrash.accessibilityHint = hint;
    
    hint = NSLocalizedString(MADHintBarButtonItemAction, MADHintBarButtonItemAction);
    _barButtonItemAction.accessibilityHint = hint;
    
    hint = NSLocalizedString(MADHintBarButtonItemDuplicate, MADHintBarButtonItemDuplicate);
    _barButtonItemDuplicate.accessibilityHint = hint;
    
    hint = NSLocalizedString(MADHintBarButtonItemDetails, MADHintBarButtonItemDetails);
    _barButtonItemInformationDocument.accessibilityHint = hint;
    
    hint = NSLocalizedString(MADHintBarButtonItemInformation, MADHintBarButtonItemInformation);
    _barButtonItemInformation.accessibilityHint = hint;
    
    hint = NSLocalizedString(MADHintBarButtonItemAbout, MADHintBarButtonItemAbout);
    _barButtonItemAbout.accessibilityHint = hint;
    
    [self.navigationItem setRightBarButtonItem:_barButtonItemEdit animated:NO];

    self.navigationController.toolbar.barTintColor = [MADColorEverydayApps newColorBlue];
    self.navigationController.toolbar.tintColor = [MADColorEverydayApps newColorWhite];
    
    // inital layout
    self.collectionView.scrollIndicatorInsets = self.collectionView.contentInset;
    
    // not editing
    [self setEditing: NO animated: NO];
    
    // add gestures
    
    UITapGestureRecognizer *tapGestureRecognizer;
    SEL didTapCollectionView = @selector(handleDidTapCollectionView:);
    tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget: self
                                                                   action: didTapCollectionView];
    tapGestureRecognizer.delegate = self;
    [self.collectionView addGestureRecognizer:tapGestureRecognizer];
    
    // update statusbar?
    [self setNeedsStatusBarAppearanceUpdate];

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    @autoreleasepool {
        BOOL canMakePayments;
        canMakePayments = [SKPaymentQueue canMakePayments];
        _barButtonItemLicensing.enabled = canMakePayments;
    }

    if ([self.toolbarItems containsObject: self.barButtonItemAction] == NO) {
        NSMutableArray *toolbarButtons = self.toolbarItems.mutableCopy;
        [toolbarButtons insertObject: self.barButtonItemAction atIndex: 1];
        [self setToolbarItems:toolbarButtons animated:animated];
    }

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
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self.searchBar sizeToFit];
}

- (void)setEditing:(BOOL)editing {
    [super setEditing:editing];
    _collectionViewDelegate.editing = editing;
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    _collectionViewDelegate.editing = editing;
}

#pragma mark - 
#pragma mark UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView { return 1; }

- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section {
    return (NSInteger)_documentManager.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *MADIDCellDocumentIdentifier  = @"MADCollectionViewCellDocumentIdentifier";
    MADCollectionViewCellDocument *cell;
    cell = [collectionView dequeueReusableCellWithReuseIdentifier: MADIDCellDocumentIdentifier
                                                     forIndexPath: indexPath];
    
    if (cell.delegate == nil) {
        ((MADCollectionViewCellDocument *)cell).delegate = self;
    }
    
    return cell;
}

#pragma mark -
#pragma mark MADDocumentManagerProtocol

- (void)handleDidDisconnectFromClound:(id)sender {
    typeof(self) __weak weakself = self;
    
    void (^actionConfirm)(UIAlertAction *action);
    actionConfirm = ^(UIAlertAction *action) {
        MADFileExplorerViewController *sself = weakself;
        [sself.documentManager updateCloudPreferences];
    };

    void (^block)(void) = ^ {

        MADFileExplorerViewController *sself = weakself;
        if (!sself) return;
        
        UIAlertController *alert;
        alert = [UIAlertController newAlertControlerNotifyCloudSignOut:actionConfirm];
        [sself presentViewController:alert animated:YES completion:nil];

    };
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:block];
}

- (void)handleDidStartLongRunningActivity {
    
}

- (void)handleDidCompletedLongRunningActivity {
    
}

#pragma mark -
#pragma mark MADDocumentManagerProtocol
- (void)documentManagerDidChangeContent:(NSArray *)inserts
                                removes:(NSArray *)removes
                                updates:(NSArray *)updates
                             completion:(void (^)(BOOL, NSError *))completion {
    UICollectionView *__weak weakCollectionView = self.collectionView;
    
    void (^ batchUpdates)(void);
    void (^ batchCompletion)(BOOL finished);

    batchUpdates = ^{
        
        NSLog(@"%s", __PRETTY_FUNCTION__);
        
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
    return _documentManager.documentsDirectory;
}

#pragma mark -
#pragma mark NSKeyValueObserving

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context {
    
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

- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    if (!CGSizeEqualToSize(size, self.view.bounds.size)) {
        UIView * __weak backgroundView = self.collectionView.backgroundView;
        [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
            
            [backgroundView setNeedsDisplay];
            
        } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) { }];
    }

}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    NSLog(@"%s", __PRETTY_FUNCTION__);

    if (self.traitCollection.horizontalSizeClass != previousTraitCollection.horizontalSizeClass) {
        [self.collectionView.collectionViewLayout invalidateLayout];
    }
}

- (void)willTransitionToTraitCollection: (UITraitCollection *)newCollection
              withTransitionCoordinator: (id<UIViewControllerTransitionCoordinator>)coordinator {
    NSLog(@"%s", __PRETTY_FUNCTION__);

    [super willTransitionToTraitCollection: newCollection
                 withTransitionCoordinator: coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self.collectionView.backgroundView setNeedsDisplay];
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) { }];

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

- (BOOL)canBecomeFirstResponder {
    return NO;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    return NO;
}

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
    self.cloudActivityRunning = YES;
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
    self.cloudActivityRunning = NO;
    self.cloudActivityRunningDisplay = NO;
    [self.headerCloud stopAnimating];
}

#pragma mark -
#pragma mark Convenience

- (NSArray *)defaultPassthroughViews {

    id view;

    NSMutableArray *defaultPassthroughViews;
    defaultPassthroughViews = [[NSMutableArray alloc] initWithCapacity: 2];
    
    view = self.navigationController.toolbar;
    if (view) [defaultPassthroughViews addObject: view];
    
    view = self.navigationController.navigationBar;
    if (view) [defaultPassthroughViews addObject: view];
    
    return defaultPassthroughViews;
}

- (NSURL *)copyMetaDataUrlForIndexPath:(NSIndexPath *)indexPath {
    MADMetaData *metadata = [_documentManager metadataAtIndex:(NSUInteger)indexPath.item];
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
    
    MADDocumentManager *documentManager = self.documentManager;
    void (^handleSignout)(UIAlertAction *action) = ^(UIAlertAction *action) {
        [documentManager updateCloudPreferences];
    };
    
    void (^ubiquityIdentityDidChange)(void) = ^ {
        
        UINavigationController *navController;
        navController = (UINavigationController *)[UIApplication sharedApplication].windows.firstObject.rootViewController;
        [navController popToRootViewControllerAnimated:YES];
        
        UIAlertController *signedOutController;
        
        signedOutController = [UIAlertController newAlertControlerNotifyCloudSignOut:handleSignout];
        
        [self presentViewController:signedOutController animated:YES completion:nil];
    };
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:ubiquityIdentityDidChange];
    
}

#pragma mark -
#pragma mark Add controls

- (void)addProgressViewToView {
    self.progressViewFileManager.progress = 0.0000f;
    [self.view addSubview:self.progressViewFileManager];
    [self.view bringSubviewToFront:self.progressViewFileManager];
}

- (void)removeProgressViewFromView {
    [self.progressViewFileManager removeFromSuperview];
}

#pragma mark - 
#pragma mark Property Overrides (Lazy loading)

- (NSNumberFormatter *)subtitleNumberFormatter {
    if (!_subtitleNumberFormatter) {
        _subtitleNumberFormatter = [NSNumberFormatter newNumberFormatterTwoDecimalPlaces];
    }
    return _subtitleNumberFormatter;
}

- (UIBarButtonItem *)barButtonItemEditDone {
    if (!_barButtonItemEditDone) {
        _barButtonItemEditDone = [UIBarButtonItem newBarButtonItemEditDone: self
                                                                    action: @selector(actionEdit:)];
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
    return [_documentManager metadataAtIndex: (NSUInteger)indexPath.item];
}

- (MADMetaData *)metaDataForItemAtIndexPath:(NSIndexPath *)indexPath {
    MADMetaData *metadata = [_documentManager metadataAtIndex:(NSUInteger)indexPath.item];
    return metadata;
}

#pragma mark -
#pragma mark UISearchBarDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField { }

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar { }

- (void)searchBar:(UISearchBar *)searchBar
    selectedScopeButtonIndexDidChange:(NSInteger)selectedScope { }

- (void)searchBar:(UISearchBar *)searchBar
    textDidChange:(NSString *)searchText { }

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar { }

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar { }

#pragma mark -
#pragma mark UINibLoading

- (void)awakeFromNib {
    [self.barButtonItemAddNewDocument setEnabled:YES];
    [super awakeFromNib];
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
        tabBarController.querySplitViewController.viewControllerDelegate = self;
        tabBarController.designerViewController.delegate = self;
        tabBarController.viewerViewController.viewControllerDelegate = self;
        self.tabController = tabBarController;
        
    } else if ([segue.destinationViewController isKindOfClass:[MADQueryBuilderSplitViewController class]]) {
        
    } else if ([segue.destinationViewController isKindOfClass:[MADQueryViewController class]]) {
        MADQueryViewController *queryBuilderViewController = (MADQueryViewController *)[(segue.destinationViewController) topViewController];
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
#pragma mark MTViewControllerProtocol

- (void)viewControllerDidFinish:(id)sender {
    _shouldShowAddDocumentPopover = YES;
    MADTabBarController *tabController = self.tabController;
    [tabController setViewControllers:nil animated:YES];
    [self dismissViewControllerAnimated:YES completion:^{ }];

    _shouldShowAddDocumentPopover = YES;
    self.barButtonItemAddNewDocument.enabled = YES;
    [self.openDocumentPopoverController dismissPopoverAnimated:YES];
    
    MADocument *openDocument = self.activeDocumentManager.openDocument;
    if (openDocument && openDocument.documentState != UIDocumentStateClosed) {
        MADActiveDocumentManager *fileManager = self.activeDocumentManager;
        [MADocument close:openDocument completion:^(BOOL success) {
            if (success) {
                [fileManager unload];
            }
        }];
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

        MADocument * __unsafe_unretained document = notification.object;
        switch (document.documentState) {

            case UIDocumentStateClosed:
                [self handleDocumentStateChangedNotificationClosed:notification];
                break;

            case UIDocumentStateEditingDisabled:
                NSLog(@"\n\n\tDocument state editing disabled.\n\n");
                break;

            case UIDocumentStateInConflict:
                NSLog(@"\n\n\tDocument state in conflict.\n\n");
                break;
                
            case UIDocumentStateNormal:
                [self handleDocumentStateChangedNotificationNormal:notification];
                break;

            case UIDocumentStateSavingError:
                NSLog(@"\n\n\tDocument state saving error.\n\n");
                break;

            default:
                break;
        }

    }
}

- (void)handleDocumentStateChangedNotificationClosed:(NSNotification *)notification {

    MADocument * __unsafe_unretained document = notification.object;
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: UIDocumentStateChangedNotification
                                                  object: document];
    id o = [[NSInvocationOperation alloc] initWithTarget:self
                                                selector:@selector(handleReloadAfterClose)
                                                  object:nil];
    [[NSOperationQueue mainQueue] addOperation:o];
    NSLog(@"\n\n\tDocument state closed.\n\n");
}

- (void)handleDocumentStateChangedNotificationNormal:(NSNotification *)notification {
    MADocument * __unsafe_unretained document = notification.object;
    SEL open = @selector(openViewerWithDocument:);
    id o = [[NSInvocationOperation alloc] initWithTarget: self
                                                selector: open
                                                  object: document];
    [[NSOperationQueue mainQueue] addOperation:o];
}

- (void)openViewerWithDocument:(MADocument *)document {

    MADTabBarController *tabBarController = [MADTabBarController newTabBarControllerMain];
    tabBarController.navigationItem.prompt = document.fileURL.lastPathComponent.copy;
    tabBarController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    tabBarController.modalPresentationStyle = UIModalPresentationOverFullScreen;
    tabBarController.viewControllerDelegate = self;
    
    NSAssert([tabBarController conformsToProtocol:@protocol(MADViewControllerDocumentProtocol)],
             @"Controller to conform to MADocumentProtocol.");
    
    ((id <MADViewControllerDocumentProtocol>)tabBarController).document = document;
    
    MADQueryBuilderSplitViewController *splitViewController =  [MADQueryBuilderSplitViewController newQueryBuilderSplitViewController];
    splitViewController.viewControllerDelegate = self;
    
    MADDesignerViewController *designerViewController = [MADDesignerViewController newDesignerViewController];
    designerViewController.delegate = self;
    
    MADViewerController *viewerViewController = [MADViewerController newViewerController];
    viewerViewController.viewControllerDelegate = self ;
    
    MADNavigationController *navControllerViewer = [[MADNavigationController alloc] initWithRootViewController:viewerViewController];
    navControllerViewer.document = document;
    [navControllerViewer setNavigationBarHidden:YES animated:NO];
    [navControllerViewer setToolbarHidden:NO animated:NO];
    
    NSArray <__kindof UIViewController *> *tabBarViewControllers =
                    [[NSArray alloc] initWithObjects:splitViewController, designerViewController,
                                                                    navControllerViewer, nil];
    
    [tabBarController setViewControllers:tabBarViewControllers animated:NO];
    self.tabController = tabBarController;
    
    MADNavigationController *navigationController = [[MADNavigationController alloc] initWithRootViewController:tabBarController];
    
    UIColor *color = [MADColorEverydayApps newColorBlue];
    navigationController.navigationBar.barTintColor = color;
    
    color = [MADColorEverydayApps newColorWhite];
    navigationController.navigationBar.tintColor = color;
    [self presentViewController:navigationController animated:YES completion:nil];
}

- (void)openDocumentAtURL:(NSURL *)url {

    @autoreleasepool {

        MADocument *document = [[MADocument alloc] initWithFileURL:url];
        document.limitResultsDesignMode = [MTStoreKitController sharedObject].isReportingLimited;
        document.documentDelegate = self;
        SEL documentStateChanged = @selector(handleDocumentStateChangedNotification:);
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: documentStateChanged
                                                     name: UIDocumentStateChangedNotification
                                                   object: document];
        
        self.activeDocumentManager.openDocument = document;
        
    }

    MADocument *allocatedDocument = self.activeDocumentManager.openDocument;
    [allocatedDocument openWithCompletionHandler:^(BOOL success) { }];

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
    UICollectionView *weakCollectionView __weak = self.collectionView;
    /*[UIView performWithoutAnimation:^{
     
     }];
     */
    @autoreleasepool {
        UICollectionView *collectionView = weakCollectionView;
        NSArray <NSIndexPath *> *paths = collectionView.indexPathsForVisibleItems.copy;
        [collectionView.backgroundView setNeedsDisplay];
        [collectionView reloadItemsAtIndexPaths:paths];
    }
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
    UINavigationController *navControl = [UINavigationController NewDocument];
    navControl.modalPresentationStyle = UIModalPresentationFormSheet;
    
    MTDatabaseDriverSelectorViewController *vc = (MTDatabaseDriverSelectorViewController *)navControl.topViewController;
    vc.delegate = self;
    vc.saveFileDelegate = self;
    self.definesPresentationContext = YES;
    self.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    
    UIPresentationController *pc = navControl.presentationController;
    pc.presentedView.backgroundColor = [UIColor whiteColor];
    [self showViewController:navControl sender:self];
}

- (IBAction)actionInformation:(id)sender {
    UINavigationController *infoViewController = [UINavigationController AppInformation];
    UIPopoverPresentationController *ppc = infoViewController.popoverPresentationController;
    ppc.passthroughViews = [ppc.passthroughViews arrayByAddingObjectsFromArray:[self defaultPassthroughViews]];
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
        
        UITableViewController *aboutViewController = [UITableViewController About];
        UIPopoverPresentationController *ppc = aboutViewController.popoverPresentationController;
        ppc.passthroughViews = [ppc.passthroughViews arrayByAddingObjectsFromArray:[self defaultPassthroughViews]];
        ppc.backgroundColor = [UIColor clearColor];
        ppc.delegate = self;
        ppc.barButtonItem = sender;
        self.aboutPopoverPresentationController = ppc;
        [self showViewController:aboutViewController sender:self];
    }
}

- (IBAction)actionDocumentInformation:(id)sender {
    MADMetaData *metadata = nil;
    NSArray *selectedItems = [self.collectionView indexPathsForSelectedItems];
    NSIndexPath *indexPath;
    NSMutableArray *metadataItems = [[NSMutableArray alloc] initWithCapacity:selectedItems.count];
    for (indexPath in selectedItems) {
        metadata = [_documentManager metadataAtIndex:(NSUInteger)indexPath.item];
        [metadataItems addObject:metadata];
    }
    
    MADDocumentInformationTableViewController *documentInformation = [MADDocumentInformationTableViewController DocumentInformation];
    documentInformation.modalPresentationStyle = UIModalPresentationPopover;
    UIPopoverPresentationController *ppc = documentInformation.popoverPresentationController;
    ppc.passthroughViews = [ppc.passthroughViews arrayByAddingObjectsFromArray:[self defaultPassthroughViews]];
    ppc.backgroundColor = [UIColor clearColor];
    ppc.delegate = self;
    ppc.barButtonItem = sender;
    self.documentInformationPopoverPresentationController = ppc;
    
    documentInformation.metadataItems = metadataItems;
    [self showViewController:documentInformation sender:self];
    [self actionDone:sender];
}

- (IBAction)actionStore:(id)sender {
    
    UINavigationController *licensing = [UINavigationController Licensing];
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
        
            UIView *titleView = (UIView * _Nonnull)self.navigationItem.titleView;
            [UIView transitionWithView: titleView
                              duration: 0.2000f
                               options: UIViewAnimationOptionCurveEaseOut animations:^{
                               
                                   self.searchBar.alpha = 1.0000f;
                                   self.navigationItem.titleView.alpha = 0.0000f;
                                   self.navigationItem.titleView = searchViewHolder;
                               } completion:^(BOOL finished) {
                                   if (self.searchBar.isFirstResponder == NO) {
                                       [self.searchBar becomeFirstResponder];
                                   }
                               }];
        }
        
    } else {
        if (self.searchBar.text.length > 0) {
            self.searchBar.text = @"";
        }
        self.searchBar.hidden = YES;
        self.searchBar.alpha = 0.1000f;
        self.navigationItem.titleView.alpha = 0.0000f;
        self.navigationItem.leftBarButtonItem.enabled = YES;
        UIView *titleView = self.navigationItem.titleView;
        [UIView transitionWithView: titleView
                          duration: 0.2000f
                           options: UIViewAnimationOptionCurveEaseOut animations:^{
                               self.searchBar.alpha = 0.0000f;
                               self.navigationItem.titleView.alpha = 1.0000f;
                               self.navigationItem.titleView = self.navigationItem.titleView;
                           } completion:nil];
        
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
        
        NSArray <NSIndexPath *> *visibleItems = self.collectionView.indexPathsForVisibleItems;
        if (visibleItems != nil)
            [self.collectionView reloadItemsAtIndexPaths:visibleItems];
        
        /*for (MADCollectionViewCellDocument *cell in self.collectionView.visibleCells) {
            [cell startWobble];
        }*/
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
    for (NSIndexPath *path in self.collectionView.indexPathsForSelectedItems) {
        [self.collectionView deselectItemAtIndexPath:path animated:YES];
    }

    for (MADCollectionViewCellDocument *cell in self.collectionView.visibleCells) {
        [cell stopWobble];
        cell.selected = NO;
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
    id destinationUrl = [url uniqueUrl];

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
        [[NSMutableArray alloc] initWithCapacity: self.documentManager.count];

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
    UIAlertController *alertController = [UIAlertController deleteItems:selectedItems.count
                                                                confirm:^(UIAlertAction *action) {
    
        for (NSIndexPath *selectedItem in selectedItems) {
            [self.documentManager removeItemAtIndex:(NSUInteger)selectedItem.item];
        }
        
    } cancel:^(UIAlertAction *action) { }];
    
    if ([sender isKindOfClass:[UIBarButtonItem class]]) {
        alertController.popoverPresentationController.barButtonItem = sender;
    }
    [self presentViewController:alertController animated:YES completion:NULL];
}

- (IBAction)actionDuplicate:(id)sender {
    for (NSIndexPath *selectedItem in self.collectionView.indexPathsForSelectedItems) {
        [_documentManager duplicateItemAtIndex:(NSUInteger)selectedItem.item];
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
    MADMetaData *metaData = [self.documentManager metadataAtIndex: (NSUInteger)indexPath.item];
    
    NSString *textFieldText = cellDocument.labelTitle.text.copy;
    
    void (^handleRename)(UITextField *);
    handleRename = ^(UITextField *textField) {
        
        textField.text = textFieldText.copy;
        textField.clearButtonMode = UITextFieldViewModeAlways;
        textField.delegate = self;
        
    };
    
    void (^handleConfermation)(UIAlertAction *action, NSString *text);
    handleConfermation = ^(UIAlertAction *action, NSString *text) {
        
        NSString *name = [NSURL newStringFileNameFilter:text];
        if (name.length > 0) {
            NSURL *newUrl = [metaData.URL.URLByDeletingLastPathComponent
                             URLByAppendingPathComponent:name isDirectory:NO];
            NSString *path = newUrl.path;
            if ([[NSFileManager defaultManager] fileExistsAtPath:path] == NO &&
                [[NSFileManager defaultManager] isUbiquitousItemAtURL:newUrl] == NO) {
                if (metaData.isUbiquitousItemDownloadingStatusNotDownloaded) {
                    
                    MADDocumentManager *documentManager = self.documentManager;
                    
                    void (^closeCompletion)(BOOL success);
                    void (^openCompletion)(BOOL success);
                    
                    closeCompletion = ^(BOOL successClose) {
                        if (successClose)
                            [documentManager rename:text
                                        itemAtIndex:(NSUInteger)indexPath.item];
                    };
                    
                    MADocument *doc = [MADocument newManagedDocumentForURL:metaData.URL];
                    
                    openCompletion = ^(BOOL success) {
                        if (success) [MADocument close: doc completion:closeCompletion];
                    };
                    
                    [doc openWithCompletionHandler:openCompletion];
                    
                } else {
                    [self.documentManager rename:text itemAtIndex:(NSUInteger)indexPath.item];
                }
            } else {
                UIAlertController *alertFileExist = [UIAlertController newAlertControllerErrorFileExist];
                [self showViewController:alertFileExist sender:self];
            }
        } else {
            UIAlertController *alertFilename = [UIAlertController newAlertControllerErrorValidationFilename];
            [self showViewController:alertFilename sender:self];
        }
        
    };

    UIAlertController *alert = [UIAlertController renameDocument: handleRename
                                                         confirm: handleConfermation
                                                          cancel: nil];
    
    [self showViewController:alert sender:self];
    
}

- (IBAction)actionEmail:(MADCollectionViewCellDocument *)cell {
    
    NSIndexPath *indexPath;
    MADMetaData *metadata;
    MADocument *documentReport;
    
    if ([MFMailComposeViewController canSendMail] == NO) {
        UIAlertController *alert = [UIAlertController newAlertControllerNotConfiguredForEmail];
        [self showViewController:alert sender:self];
        return;
    }

    indexPath = [self.collectionView indexPathForCell:cell];
    metadata = [_documentManager metadataAtIndex:(NSUInteger)indexPath.item];
    documentReport = [MADocument newManagedDocumentForURL:metadata.URL];
    
    if (documentReport.documentState != UIDocumentStateClosed) {
        
        void (^handleCloseDocumentCompletion)(BOOL success);
        handleCloseDocumentCompletion = ^(BOOL success) {
            if (success) { [self actionEmail:cell]; }
        };
        [MADocument close: documentReport completion:handleCloseDocumentCompletion];
        
    } else {
        
        NSString *mimeType = [self mimeTypeForDocumentUTI:documentReport.fileType];
        NSString *messageStringStart = NSLocalizedString(@"The attached document can be opened with MAD Viewer.",
                                                         @"The attached document can be opened with MAD Viewer.");
        NSMutableString *messageBody = [[NSMutableString alloc] initWithString:messageStringStart];
        [messageBody appendString:@"\n\nhttp://www.everydayapps.com/\n\n"];
        MFMailComposeViewController	*mailComposer;
        mailComposer = [MFMailComposeViewController newMailComposeViewControllerWithBody: messageBody
                                                                              attachment: metadata.URL
                                                                                mimeType: mimeType
                                                                      userInterfaceIdiom: self.traitCollection.userInterfaceIdiom];
        mailComposer.mailComposeDelegate = self;
        [self showViewController:mailComposer sender:self];
    }

    
}

- (IBAction)actionActivateEditMode:(UILongPressGestureRecognizer *)sender {

    if (sender.state == UIGestureRecognizerStateBegan) {

        [self actionEdit:nil];

        NSIndexPath *indexPath;

            UICollectionView *collectionView = self.collectionView;
            
            if ([self.collectionViewDelegate collectionView: collectionView
                                shouldSelectItemAtIndexPath: indexPath]) {

                [collectionView selectItemAtIndexPath: indexPath
                                             animated: YES
                                       scrollPosition: UICollectionViewScrollPositionNone];

                [self.collectionViewDelegate collectionView: collectionView
                                   didSelectItemAtIndexPath: indexPath];
                NSArray <NSIndexPath *> *selectedPath =
                                            [[NSArray alloc] initWithObjects:indexPath, nil];
                [collectionView reloadItemsAtIndexPaths:selectedPath];
            }
            

    }
}

#pragma mark - 
#pragma mark UIAdaptivePresentationControllerDelegate

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:
                        (UIPresentationController *)controller {
    UIModalPresentationStyle style = UIModalPresentationOverCurrentContext;
    if ([controller isEqual:self.aboutPopoverPresentationController] || [controller isEqual:self.infoPopoverPresentationController] ||
        [controller isEqual:self.documentInformationPopoverPresentationController]) {
        style = UIModalPresentationNone;
    }
    return style;
}

#pragma mark - 
#pragma mark UIPopoverPresentationControllerDelegate

- (void)prepareForPopoverPresentation:
                        (UIPopoverPresentationController *)popoverPresentationController { }

- (BOOL)popoverPresentationControllerShouldDismissPopover:
                        (UIPopoverPresentationController *)popoverPresentationController { return YES; }

- (void)popoverPresentationControllerDidDismissPopover:
                        (UIPopoverPresentationController *)popoverPresentationController {
    _aboutViewControllerOnScreen = NO;
}

#pragma mark -
#pragma mark Update UI

- (void)collectionView:(UICollectionView *)collectionView
                    didChangeNumberOfItemsSelected:(NSUInteger)numberOfItemsSelected {

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

@end
