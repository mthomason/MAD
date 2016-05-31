//
//  MADOpenFileViewController
//  MAD Designer
//
//  Created by Michael Thomason on 1/2/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADOpenFileViewController.h"
#import "MADOpenFileViewControllerProtocol.h"

#import <QuickLook/QLPreviewController.h>
#import <StoreKit/SKPaymentQueue.h>

#import <MADCocoaExtensions/UIAlertController+Constructors.h>
#import <MADCocoaExtensions/UIColor+EverydayApps.h>
#import <MADCocoaExtensions/UIColor+EverydayApps.h>
#import <MADCocoaExtensions/UIBarButtonItem+Constructors.h>
#import <MADCocoaExtensions/NSError+Constructors.h>
#import <MADCocoaExtensions/MFMailComposeViewController+Constructors.h>
#import <MADCocoaExtensions/MTMath.h>

#import <MADFoundation/UIApplication+MADAppDelegate.h>
#import <MADFoundation/MADApplicationProtocol.h>
#import <MADFoundation/NSURL+Document.h>

#import <MADExplorer/MADFileLocationManager.h>
#import <MADExplorer/MADOpenDocumentManager.h>

#import <MADExplorer/MTCollectionViewCellDocument.h>
#import <MADExplorer/MADFileLocationManager.h>
#import <MADExplorer/MADOpenDocumentManager.h>
#import <MADExplorer/MADCollectionViewLayoutGroupedDelegate.h>

#import <MADFileManager/MADFilesController.h>
#import <MADFileManager/MADFileInfo.h>
#import <MADFileManager/MADMetaData.h>
#import <MADFileManager/MADAppLaunchContext.h>
#import <MADFileManager/MADFilesController.h>

#import <MADCocoaExtensions/UIView+Animations.h>
#import <MADCocoaExtensions/UIAlertController+Constructors.h>
#import <MADCocoaExtensions/NSNumberFormatter+Constructors.h>

#import <MAD/MADConstants.h>
#import <MAD/MADocument.h>
#import <MAD/MADDocumentProtocol.h>
#import <MAD/MADCredential.h>

#import "MADOpenFileSectionHeaderView.h"
#import "MADSearchBar.h"
#import "MADProgressView.h"

#import "Constants.h"

#import "MTStoreKitController+Features.h"
#import "MADDocumentInformationTableViewController+Designer.h"

#import "MUIViewControllerDelegate.h"
#import "MADQueryBuilderSplitViewController.h"
#import "MADViewerController.h"
#import "MADDesignerViewController.h"
#import "MADQueryViewController.h"
#import "MTDatabaseDriverSelectorViewController.h"
#import "MADStoreViewController.h"

#import "MADNavigationBarTitleView.h"
#import "MADWatermarkView.h"

#import "MADNavigationController.h"

#import "UIStoryboard+Query.h"
#import "UINavigationController+MADQuery.h"
#import "UINavigationController+Designer.h"

#import "UITabBarController+Shared.h"
#import "UITableViewController+Designer.h"

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

const NSUInteger MADIDInstallOperationSampleDatabaseChinook = 1;
const NSUInteger MADIDInstallOperationSampleDocumentMusic = 2;
const NSUInteger MADIDInstallOperationSampleDocumentLondon = 3;

static NSString * const MADIdentifierFileLondon                 = @"London";
static NSString * const MADIdentifierFileMusic                  = @"Music";

NSString * const MTSegueOpenInViewer                            = @"MTSegueOpenInViewer";
NSString * const MTSegueShowAddDocument                         = @"showAddDocument";
NSString * const MTSegueLicensing                               = @"MTSegueLicensing";
NSString * const MADUtiType                                     = @"com.everydayapps.productivity.mad";

static NSString * const MADImageToolbarCloudDownload = @"MADImageToolbarCloudDownload";

static NSString * const NotDownloaded                           = @"Not Downloaded";
static NSString * const Syncing                                 = @"Syncing";
static NSString * const Downloading                             = @"Downloading";

NSString * const MADUpgradeInstalledSamplesLondon   = @"MADUpgradeInstalledSamplesLondon";
NSString * const MADUpgradeInstalledSamplesMusic    = @"MADUpgradeInstalledSamplesMusic";
static NSString * const MADAppConfigurationUserDefaultsSamplesInstalled    = @"MADAppConfigurationUserDefaultsSamplesInstalled";

const char * MADQueueFileViewController = "com.everydayapps.mad.designer.file.view.controller";

NSString * const MADIdentifierOpenFileSectionHeader             = @"MADIdentifierOpenFileSectionHeader";

static NSString * const MADIDNotificationCloudActivityStarted = @"MADNotificationCloudActivityStarted";
static NSString * const MADIDNotificationCloudActivityCompleted = @"MADNotificationCloudActivityCompleted";

static const CGFloat Float_0 = 0.000000000f;
static const CGFloat Float_100 = 100.00000000f;

// FIXME: Get these from AppDelegate using a protocol/deletgate pattern... different for each version of file exploer.
//NSString * const MADUtiPublicData                               = @"public.data";


const CGFloat MADSectionHeaderHeight                            = 32.0000f;

@interface MADFileExplorerViewController()
    <NSFileManagerDelegate,
        UIGestureRecognizerDelegate,
        MFMailComposeViewControllerDelegate,
        UIDocumentInteractionControllerDelegate,
        UIDocumentPickerDelegate,
        UITextFieldDelegate,
        UISearchBarDelegate,
        UIPopoverControllerDelegate,
        MTDocumentCellProtocol,
        UIPopoverControllerDelegate,
        UIPopoverPresentationControllerDelegate,
        MADocumentDelegate,
        MTViewControllerProtocol,
        MADFileLocationManagerDelegate,
        MADOperationObserver>

    @property (nonatomic, strong) MADCollectionViewLayoutGroupedDelegate *collectionViewDelegate;

    @property (nonatomic, strong, readwrite) MADOpenDocumentManager *fileManager;
    @property (nonatomic, strong) MADFileLocationManager *filesCoordnator;

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

    @property (nonatomic, assign)   bool shouldShowAddDocumentPopover;
    @property (nonatomic, assign)   bool aboutViewControllerOnScreen;

    @property (nonatomic, strong)   MADSearchBar *searchBar;

    @property (nonatomic, strong) UIBarButtonItem *rightBarButtonItemHolderWhileActivity;

    @property (nonatomic, strong) MADOpenFileSectionHeaderView *headerCloud;

    @property (nonatomic, assign) BOOL cloudActivityRunning;
    @property (nonatomic, assign) BOOL cloudActivityRunningDisplay;

    @property (nonatomic, assign, getter=isRightBarButtonItemActivityIndicatorVisible) BOOL rightBarButtonItemActivityIndicatorVisible;
    @property (nonatomic, assign, getter=isUpdatingEnabled) BOOL updatingEnabled;

    @property (nonatomic, strong) UIProgressView *progressViewFileManager;

    @property (nonatomic, strong) NSMutableIndexSet *batchInserts;
    @property (nonatomic, strong) NSMutableIndexSet *batchRemoves;
    @property (nonatomic, strong) NSMutableIndexSet *batchUpdates;

    @property (nonatomic, assign) BOOL getUserCloudPrefsFirstCall;

@end

@implementation MADFileExplorerViewController

#pragma mark -
#pragma mark MADOperationObserver

- (void)operationDidStart:(MADOperation *)operation {
    
}

- (void)operation:(MADOperation *)operation didProduceOperation:(NSOperation *)newOperation {
    
}

- (void)operationDidFinish:(MADOperation *)operation
                    errors:(NSArray *)errors {

    switch (operation.tag) {

        case MADIDInstallOperationSampleDocumentMusic:
        case MADIDInstallOperationSampleDocumentLondon: {
            typeof(self) __weak weakself = self;
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [weakself.collectionView reloadData];
            }];
            break;
        }
            
        default:
            break;
    }
}

- (void)initalInstallOperations {
    MADOperationQueue *operationQueueBackground;
    operationQueueBackground = [[MADOperationQueue alloc] init];
    operationQueueBackground.maxConcurrentOperationCount = 1;
    
    NSOperation *getUserCloudPreferences;
    MADOperation *operation;
    NSOperation *resetReceipt;
    
    getUserCloudPreferences = [[NSInvocationOperation alloc] initWithTarget: self
                                                                   selector: @selector(getUserCloudPrefs)
                                                                     object: NULL];
    [operationQueueBackground addOperation:getUserCloudPreferences];

    
    operation = [[MADInstallOperationSampleDatabase alloc] init];
    [operationQueueBackground addOperation:operation];
    
    operation = [[MADInstallOperationSampleDocument alloc] initWithFilename: MADIdentifierFileLondon
                                                                        fileExtension: MADFileExtentionMobleApplicationDocument
                                                                      groupIdentifier: MADIdentifierGroup
                                                                          installFlag: MADUpgradeInstalledSamplesLondon];
    operation.tag = MADIDInstallOperationSampleDocumentLondon;
    [operation addObserver:self];
    [operationQueueBackground addOperation:operation];
    
    operation = [[MADInstallOperationSampleDocument alloc] initWithFilename: MADIdentifierFileMusic
                                                              fileExtension: MADFileExtentionMobleApplicationDocument
                                                            groupIdentifier: MADIdentifierGroup
                                                                installFlag: MADUpgradeInstalledSamplesMusic];
    operation.tag = MADIDInstallOperationSampleDocumentMusic;
    [operation addObserver:self];
    [operationQueueBackground addOperation:operation];

    resetReceipt = [[NSInvocationOperation alloc] initWithTarget: [MTVerificationController sharedInstance]
                                                        selector: @selector(resetReceipt)
                                                          object: NULL];
    
    [operationQueueBackground addOperation:resetReceipt];
}

#pragma mark -
#pragma mark NSObject

- (void)dealloc {
    _barButtonItemAction = nil;
    [_batchInserts removeAllIndexes];
    [_batchUpdates removeAllIndexes];
    [_batchRemoves removeAllIndexes];
    _subtitleNumberFormatter = nil;
    [self removeObservers];
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
        
        
        UITabBarItem *tabBarItemAppearance =                [UITabBarItem appearance];
        UIBarButtonItem *barButtonItem =                    [UIBarButtonItem appearance];
        UINavigationBar *navigationBarAppearance =          [UINavigationBar appearance];
        
        UINavigationBar *navigationBarQLPreviewAppearance = [UINavigationBar appearanceWhenContainedIn:[QLPreviewController class], nil];
        UINavigationBar *navigationBarViewController =      [UINavigationBar appearanceWhenContainedIn:[UIViewController class], nil];
        UINavigationBar *navigationBarNavigationBar =       [UINavigationBar appearanceWhenContainedIn:[UINavigationController class], nil];
        UIBarButtonItem *barButtonItemToolbar =             [UIBarButtonItem appearanceWhenContainedIn:[UIToolbar class], nil];
        UISegmentedControl *segmentedControl =              [UISegmentedControl appearanceWhenContainedIn:[UINavigationBar class], nil];
        
        
        navigationBarQLPreviewAppearance.barTintColor   = madColor4;
        
        UIColor *whiteColor = [MADColorEverydayApps newColorWhite];
        navigationBarViewController.tintColor           = whiteColor;
        navigationBarNavigationBar.tintColor            = whiteColor;
        barButtonItemToolbar.tintColor                  = whiteColor;
        barButtonItem.tintColor                         = whiteColor;
        segmentedControl.tintColor                      = whiteColor;
        
        id titleTextAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
                                  whiteColor, NSForegroundColorAttributeName, nil];
        [tabBarItemAppearance setTitleTextAttributes: titleTextAttributes
                                            forState: UIControlStateNormal];
        navigationBarAppearance.titleTextAttributes = titleTextAttributes;
        
        UIColor *redColor = [MADColorEverydayApps newColorRed];
        navigationBarQLPreviewAppearance.tintColor = redColor;
                UIColor *orangeColor = [MADColorEverydayApps newColorOrange];
        UILabel *labelInTableCell = [UILabel appearanceWhenContainedIn:[UITableViewCell class], nil];
        labelInTableCell.highlightedTextColor       = orangeColor;
        
        UILabel *labelInCollectionCell = [UILabel appearanceWhenContainedIn:[UICollectionViewCell class], nil];
        labelInCollectionCell.highlightedTextColor  = orangeColor;
        
        UIImageView *imageInCollectionViewCell = [UIImageView appearanceWhenContainedIn:[UICollectionViewCell class], nil];
        imageInCollectionViewCell.tintColor         = orangeColor;
        
    }
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
    
        self.shouldShowAddDocumentPopover = true;

        MADFileLocationManager *filesCoordnator = [[MADFileLocationManager alloc] init];
        filesCoordnator.delegate = self;
        filesCoordnator.filesController.delegate = self;
        self.filesCoordnator = filesCoordnator;

        self.getUserCloudPrefsFirstCall = YES;
        
        MADOpenDocumentManager *openFiles = [[MADOpenDocumentManager alloc] init];
        self.fileManager = openFiles;

        MADProgressView *progressView = [[MADProgressView alloc] initWithProgressViewStyle: UIProgressViewStyleBar];
        self.progressViewFileManager = progressView;
        
        NSMutableIndexSet *indexSet;
        indexSet = [[NSMutableIndexSet alloc] init];
        self.batchInserts = indexSet;
        
        indexSet = [[NSMutableIndexSet alloc] init];
        self.batchRemoves = indexSet;
        
        indexSet = [[NSMutableIndexSet alloc] init];
        self.batchUpdates = indexSet;

    }
    return self;
}

#pragma mark - 
#pragma mark MADFileLocationManagerDelegate

- (NSString *)groupIdentifier { return MADIdentifierGroup; }

- (NSString *)ubiquityIdentifier { return MADUbiquityIdentifier; }

- (NSString *)fileExtention { return MADFileExtentionMobleApplicationDocument; }

- (void)didConfigureFilesController:(MADFilesController *)filesController {
    filesController.delegate = self;
}

- (void)didDisconnectFromCloud:(id)sender {

    typeof(self) __weak weakself = self;
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        MADFileExplorerViewController *sself = weakself;
        if (sself) {
            id __weak weakself2 = sself;
            UIAlertController *alert;
            alert = [UIAlertController newAlertControlerNotifyCloudSignOut:^(UIAlertAction *action) {
                MADFileExplorerViewController *sself2 = weakself2;
                [sself2 getUserCloudPrefs];
            }];
            
            [sself presentViewController:alert animated:YES completion:nil];
        }
    }];
}

- (UIAlertController *)promotCloudSignOut:(void (^)(UIAlertAction *action))handler {
    UIAlertController *alert = [UIAlertController newAlertControlerNotifyCloudSignOut:handler];
    return alert;
}

- (void)startLongRunningActivity { }

- (void)completedLongRunningActivity { }

#pragma mark -
#pragma mark Static Functions

+ (NSString *)keySubviews {
    return NSStringFromSelector(@selector(subviews));
}
+ (NSString *)keyLeftView {
    return NSStringFromSelector(@selector(leftView));
}

+ (NSOperationQueue *)queue {
// ???: Does this run?
    static NSOperationQueue *queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = [[NSOperationQueue alloc] init];
    });
    
    return queue;
}

#pragma mark -
#pragma mark MADSaveFileProtocol

- (NSURL *)documentDirectory {
    return self.filesCoordnator.filesController.documentDirectory;
}

#pragma mark -
#pragma mark Public

- (void)getUserCloudPrefs {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    [self.filesCoordnator getUserCloudPrefs];
}

#pragma mark -
#pragma mark NSKeyValueObserving

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context {
    
    if ([keyPath isEqualToString:[MADFileExplorerViewController keySubviews]]) {
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

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // set delegates
    MADCollectionViewLayoutGroupedDelegate *layoutGroupedDelegate;
    layoutGroupedDelegate = [[MADCollectionViewLayoutGroupedDelegate alloc] init];
    layoutGroupedDelegate.delegate = self;
    
    self.collectionView.delegate = layoutGroupedDelegate;
    self.collectionView.dataSource = self;
    
    _collectionViewDelegate = layoutGroupedDelegate;
    
    // start observing
    
    [self addObservers];

    [self initalInstallOperations];
    
    // init
    _aboutViewControllerOnScreen = false;
    _updatingEnabled = YES;
    _cloudActivityRunning = NO;
    _cloudActivityRunningDisplay = NO;
    _rightBarButtonItemActivityIndicatorVisible = NO;
    
    [self.collectionView registerClass: [MADOpenFileSectionHeaderView class]
            forSupplementaryViewOfKind: UICollectionElementKindSectionHeader
                   withReuseIdentifier: MADIdentifierOpenFileSectionHeader];

    // setup ui - navigaion item
    MADNavigationBarTitleView *titleView;
    titleView = [[MADNavigationBarTitleView alloc] initWithFrame: CGRectZero];
    
    MADAppDelegate delegate = [MADApplication AppDelegate];
    NSString *name = [delegate name];
    titleView.text = name.copy;
    titleView.accessibilityHint = NSLocalizedString(@"MAD Designer is the mobile analytics document designer.",
                                                    @"MAD Designer is the mobile analytics document designer.");
    titleView.accessibilityTraits = UIAccessibilityTraitHeader;
    
    self.navigationItem.titleView = titleView;
    self.navigationItem.hidesBackButton = YES;
    
    // setup ui - background
    MADWatermarkView *watermarkView;
    watermarkView = [[MADWatermarkView alloc] initWithFrame: self.collectionView.bounds];
    self.collectionView.backgroundView = watermarkView;
    
    // setup ui - search bar
    
    MADSearchBar *searchBar = [[MADSearchBar alloc] initWithFrame:CGRectZero];
    _searchBar = searchBar;
    
    // setup ui - bar button items
    
    NSString *hint;
    
    UIBarButtonItem *barButtonItemDuplicate;
    SEL handleDuplicate = @selector(actionDuplicate:);
    barButtonItemDuplicate = [UIBarButtonItem newBarButtonItemDuplicate:self
                                                                 action:handleDuplicate];
    
    NSMutableArray *toolbarButtons = self.toolbarItems.mutableCopy;
    [toolbarButtons removeObject:_barButtonItemAction];
    [toolbarButtons removeObject:_barButtonItemCloudDown];
    [toolbarButtons insertObject:barButtonItemDuplicate atIndex:1];
    [self setToolbarItems:toolbarButtons animated:NO];
    _barButtonItemDuplicate = barButtonItemDuplicate;
    
    UIBarButtonItem *editButton = [UIBarButtonItem newBarButtonItemEdit:self
                                                                 action:@selector(edit:)];
    _barButtonItemEdit = editButton;
    
    hint = NSLocalizedString(@"Enables document list edit mode.",
                             @"Enables document list edit mode.");
    _barButtonItemEdit.accessibilityHint = hint;
    
    hint = NSLocalizedString(@"Adds a new document.", @"Adds a new document.");
    _barButtonItemAddNewDocument.accessibilityHint = hint;
    
    hint = NSLocalizedString(@"Displays the store.", @"Displays the store.");
    _barButtonItemLicensing.accessibilityHint = hint;
    
    hint = NSLocalizedString(@"Deletes the selected documents.",
                             @"Deletes the selected documents.");
    _barButtonItemTrash.accessibilityHint = hint;
    
    hint = NSLocalizedString(@"Preforms an action on the selected document.",
                             @"Preforms an action on the selected document.");
    _barButtonItemAction.accessibilityHint = hint;
    
    hint = NSLocalizedString(@"Duplicates the selected documents.",
                             @"Duplicates the selected documents.");
    _barButtonItemDuplicate.accessibilityHint = hint;
    
    hint = NSLocalizedString(@"Displays selected document details.",
                             @"Displays selected document details.");
    _barButtonItemInformationDocument.accessibilityHint = hint;
    
    hint = NSLocalizedString(@"Displays application information.",
                             @"Displays application information.");
    _barButtonItemInformation.accessibilityHint = hint;
    
    hint = NSLocalizedString(@"Displays application about screen.",
                             @"Displays application about screen.");
    _barButtonItemAbout.accessibilityHint = hint;
    
    [self.navigationItem setRightBarButtonItem:_barButtonItemEdit animated:NO];

    self.navigationController.toolbar.barTintColor = [MADColorEverydayApps newColorBlue];
    self.navigationController.toolbar.tintColor = [MADColorEverydayApps newColorWhite];
    self.collectionView.backgroundColor = [UIColor lightGrayColor];
    
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
        [_barButtonItemLicensing setEnabled:canMakePayments];
    }

    NSArray <NSIndexPath *> *selectedIndexs = self.collectionView.indexPathsForSelectedItems.copy;
    typeof (self.collectionView) __weak wCollectionView = self.collectionView;
    [selectedIndexs enumerateObjectsWithOptions: NSEnumerationConcurrent
                                     usingBlock: ^(NSIndexPath * _Nonnull indexPath,
                                                   NSUInteger idx, BOOL * _Nonnull stop) {
    
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            UICollectionView *collectionView = wCollectionView;
            if (collectionView) {
                id cell = [collectionView cellForItemAtIndexPath:indexPath];
                [cell performDeselectionAnimations];
            }
        }];
    }];

    if ([self.toolbarItems containsObject: self.barButtonItemAction] == NO) {
        NSMutableArray *toolbarButtons = self.toolbarItems.mutableCopy;
        [toolbarButtons insertObject: self.barButtonItemAction atIndex: 1];
        [self setToolbarItems:toolbarButtons animated:animated];
    }

    //[self.collectionView.backgroundView setNeedsDisplay];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.aboutViewControllerOnScreen = false;
    
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

#pragma mark - UIResponder

- (void)restoreUserActivityState:(NSUserActivity *)activity {
    // Obtain an app launch context from the provided activity and configure the view controller with it.
    MADAppLaunchContext *launchContext = [[MADAppLaunchContext alloc] initWithUserActivity:activity];
    
    // Configure the view controller with the launch context.
    [self configureViewControllerWithLaunchContext:launchContext];
}

#pragma mark - UIViewController

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
    
    //Only allow the thumbnails to proceed to after an error.
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
#pragma mark MADCollectionViewLayoutFilesDelegate

#pragma mark -
#pragma mark Touch Event Handlers

- (void)handleDidTapCollectionView:(UIGestureRecognizer *)sender {
    [self.searchBar resignFirstResponder];
    if (self.isEditing) {
        [self edit:self];
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
    
    if (_rightBarButtonItemActivityIndicatorVisible == rightBarButtonItemActivityIndicatorVisible) {
        return;
    }
    UIBarButtonItem *barButtonItem;
    
    if ((_rightBarButtonItemActivityIndicatorVisible = rightBarButtonItemActivityIndicatorVisible)) {
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
#pragma mark MADFilesControllerDelegate

- (void)filesControllerWillChangeContent:(MADFilesController *)filesController {
    NSLog(@"%s", __PRETTY_FUNCTION__);

    [self.batchInserts removeAllIndexes];
    [self.batchRemoves removeAllIndexes];
    [self.batchUpdates removeAllIndexes];
}

- (void)filesController:(MADFilesController *)filesController
      didInsertFileInfo:(MADFileInfo *)fileInfo atIndex:(NSUInteger)index {

    NSLog(@"%s", __PRETTY_FUNCTION__);
    [self.batchInserts addIndex:index];

}

- (void)filesController:(MADFilesController *)filesController
      didRemoveFileInfo:(MADFileInfo *)fileInfo atIndex:(NSUInteger)index {

    NSLog(@"%s", __PRETTY_FUNCTION__);
    [self.batchRemoves addIndex:index];

}

- (void)filesController:(MADFilesController *)filesController
      didUpdateFileInfo:(MADFileInfo *)fileInfo atIndex:(NSUInteger)index {

    NSLog(@"%s", __PRETTY_FUNCTION__);
    [self.batchUpdates addIndex:index];

}

- (void)filesControllerDidChangeContent:(MADFilesController *)filesController
                             completion:(void (^)(BOOL, NSError *))completion {

    NSLog(@"%s", __PRETTY_FUNCTION__);

    NSMutableArray *inserts = [[NSMutableArray alloc] initWithCapacity: _batchInserts.count],
                   *removes = [[NSMutableArray alloc] initWithCapacity: _batchRemoves.count],
                   *updates = [[NSMutableArray alloc] initWithCapacity: _batchUpdates.count];

    NSIndexPath *path;
    NSUInteger i;

    i = [_batchInserts firstIndex];
    while (i != NSNotFound) {
        path = [NSIndexPath indexPathForItem:(NSInteger)i inSection:0];
        [inserts addObject:path];
        i = [_batchInserts indexGreaterThanIndex: i];
    }
    
    i = [_batchRemoves firstIndex];
    while (i != NSNotFound) {
        path = [NSIndexPath indexPathForItem:(NSInteger)i inSection:0];
        [removes addObject:path];
        i = [_batchRemoves indexGreaterThanIndex: i];
    }

    i = [_batchUpdates firstIndex];
    while (i != NSNotFound) {
        path = [NSIndexPath indexPathForItem:(NSInteger)i inSection:0];
        [updates addObject:path];
        i = [_batchUpdates indexGreaterThanIndex: i];
    }

    [updates removeObjectsInArray:inserts];
    [updates removeObjectsInArray:removes];


    UICollectionView *__weak weakCollectionView = self.collectionView;
    [self.collectionView performBatchUpdates:^{
    
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
    } completion:^(BOOL finished) {
        
    }];

    completion(YES, nil);
}

- (void)filesController:(MADFilesController *)filesController
                didFailCreatingFileInfo:(MADFileInfo *)fileInfo withError:(NSError *)error {

    NSLog(@"%s", __PRETTY_FUNCTION__);

}

- (void)filesController:(MADFilesController *)filesController
                didFailRemovingFileInfo:(MADFileInfo *)fileInfo withError:(NSError *)error {
    
    NSLog(@"%s", __PRETTY_FUNCTION__);

}

- (void)filesController:(MADFilesController *)filesController
                didFailDuplicatingFileInfo:(MADFileInfo *)fileInfo withError:(NSError *)error {

    NSLog(@"%s", __PRETTY_FUNCTION__);

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
    MTCollectionViewCellDocument *cell;
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
    MADMetaData *metadata = [self.filesCoordnator.filesController
                                objectAtIndexedSubscript:(NSUInteger)indexPath.item];
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

- (void)addObservers {
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
}

- (void)removeObservers {
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

- (void)handleNotificationUbiquityIdentityDidChange:(NSNotification *)notification {
    NSLog(@"Ubiquity did indeed change..... %@", notification.userInfo);
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        
        NSLog(@"%s", __PRETTY_FUNCTION__);
        
        UINavigationController *navController;
        navController = (UINavigationController *)[UIApplication sharedApplication].windows.firstObject.rootViewController;
        [navController popToRootViewControllerAnimated:YES];
        
        typeof(self) __weak weakself = self;
        UIAlertController *signedOutController;
        signedOutController = [UIAlertController newAlertControlerNotifyCloudSignOut:^(UIAlertAction *action) {
            MADFileExplorerViewController *strongself = weakself;
            if (strongself) {
                [strongself getUserCloudPrefs];
            }
        }];
        
        [self presentViewController:signedOutController animated:YES completion:nil];
    }];
    
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
        _barButtonItemEditDone = [UIBarButtonItem buttonEditDone:self action:@selector(edit:)];
    }
    return _barButtonItemEditDone;
}

#pragma mark -
#pragma mark UIPopoverControllerDelegate

- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController {
    return [self.openDocumentPopoverController isEqual:popoverController] == NO;
}

#pragma mark - 
#pragma mark MADCollectionViewLayoutFilesDelegate

- (NSString *)titleForItemAtIndexPath:(NSIndexPath *)indexPath {
    MADMetaData *metadata = [self.filesCoordnator.filesController objectAtIndexedSubscript: (NSUInteger)indexPath.item];
    return metadata.URL.lastPathComponent.stringByDeletingPathExtension;
}

- (NSString *)subtitleForItemAtIndexPath:(NSIndexPath *)indexPath {
    MADMetaData *metadata = [self.filesCoordnator.filesController objectAtIndexedSubscript: (NSUInteger)indexPath.item];
    return [self copySubtitleForMetadata:metadata];
}

- (BOOL)isFileViewEditing { return self.editing; }

- (MADMetaData *)metadataForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [self.filesCoordnator.filesController objectAtIndexedSubscript: (NSUInteger)indexPath.item];
}

- (void)userSelectedItemAtIndexPath:(NSIndexPath *)indexPath {
    
    MADMetaData *metadata = [self.filesCoordnator.filesController objectAtIndexedSubscript:(NSUInteger)indexPath.item];
    MTCollectionViewCellDocument *cell = (MTCollectionViewCellDocument *)
                                            [self.collectionView cellForItemAtIndexPath:indexPath];
    [cell performSelectionAnimations];
    
    if (self.isEditing) {
        [self.collectionView selectItemAtIndexPath:indexPath animated:YES
                                    scrollPosition:UICollectionViewScrollPositionCenteredVertically];
        
        if (metadata.isUbiquitous) {
            if (metadata.isUbiquitousItemDownloadingStatusNotDownloaded) {
                NSURL *url = metadata.URL.copy;
                
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    NSError *error = nil;
                    [[NSFileManager defaultManager] startDownloadingUbiquitousItemAtURL:url
                                                                                  error:&error];
                }];
            }
        }
    } else {
        [cell stopWobble];
        [self.collectionView deselectItemAtIndexPath:indexPath animated:YES];
        [cell.activityIndicator startAnimating];
        
        id open = [[NSInvocationOperation alloc] initWithTarget:self
                                                       selector:@selector(openDocumentAtURL:)
                                                         object:metadata.URL.copy];
        [[NSOperationQueue mainQueue] addOperation:open];
        [cell normalizeTint];
    }
}

#pragma mark - 
#pragma mark UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView { return 1; }

- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section {
    return self.filesCoordnator.filesController ?
                            (NSInteger)self.filesCoordnator.filesController.count : 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellDocumentIdentifier  = @"MTCollectionViewCellDocumentIdentifier";
    MTCollectionViewCellDocument *cell;
    cell = [collectionView dequeueReusableCellWithReuseIdentifier: CellDocumentIdentifier
                                                     forIndexPath: indexPath];
    
    if (cell.delegate == nil) {
        ((MTCollectionViewCellDocument *)cell).delegate = self;
    }
    
    MADMetaData *metadata = [self metadataForItemAtIndexPath:indexPath];

    NSString *filename = metadata.name.copy;
    cell.labelTitle.text = filename;
    
    bool notDownloaded, downloading, uploading;
    
    notDownloaded = [metadata.ubiquitousItemDownloadingStatus isEqualToString:
                            NSMetadataUbiquitousItemDownloadingStatusNotDownloaded];
    
    downloading = metadata.ubiquitousItemIsDownloading,
    uploading   = metadata.ubiquitousItemIsUploading;

    if (downloading) {
        cell.labelTitleSub.text = NSLocalizedString(Downloading, Downloading);
    } else if (uploading) {
        cell.labelTitleSub.text = NSLocalizedString(Syncing, Syncing);
    } else {
        NSString *subtitle = [self copySubtitleForMetadata:metadata];
        cell.labelTitleSub.text = subtitle.copy;
    }
    
    [self updateProgressView:cell.progressViewUpload active:uploading
                     percent:metadata.ubiquitousItemPercentUploaded];
    
    [self updateProgressView:cell.progressViewDownload active:downloading
                     percent:metadata.ubiquitousItemPercentDownloaded];
    
    UIActivityIndicatorView *activityIndicator = cell.activityIndicator;
    if (metadata.ubiquitousItemIsDownloading || metadata.ubiquitousItemIsUploading)
        [activityIndicator startAnimating];
    else
        [activityIndicator stopAnimating];
    
    cell.imageCloudIndicator.image = notDownloaded && metadata.isUbiquitous ?
                                        [UIImage imageNamed:MADImageToolbarCloudDownload] : nil;
    
    [cell.labelTitle layoutIfNeeded];
    [cell.labelTitleSub layoutIfNeeded];


    @autoreleasepool {
        NSURL *thumbnailUrl = [MADocument newThumbnailUrlForMadUrl:metadata.URL];
        NSString *path = thumbnailUrl.path;
        if (!path) goto END_ReadThumbnail;
        {
            NSData *imageData = [[NSData alloc] initWithContentsOfFile:path];
            UIImage *image = [[UIImage alloc] initWithData:imageData scale:6.0];
        
            if (image != nil) {
                cell.imagePreview.image = image;
            } else {
                image = [MTCollectionViewCellDocument newDefaultThumbnail];
                cell.imagePreview.image = image;
            }
            image = nil;
            imageData = nil;
        }
        END_ReadThumbnail:;
    }
    
    /*[cell normalizeTint];
    
    if ([self isFileViewEditing]) {
        [cell startWobble];
    } else {
        [cell stopWobble];
    }*/
    
    return cell;
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
    [self.barButtonItemAddNewDocument setEnabled:YES];
    [super awakeFromNib];
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    
    BOOL shouldPerformSegueWithIdentifier = YES;
    if ([identifier isEqualToString:MTSegueShowAddDocument]) {
        if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
            shouldPerformSegueWithIdentifier = [self shouldShowAddDocumentPopover];
            self.shouldShowAddDocumentPopover = false;
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
    [segue.destinationViewController setDelegate: self];
    
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
    MADViewerController *viewControllerReportViewer = (MADViewerController *)[(UINavigationController *)segue.destinationViewController topViewController];
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
        MADQueryViewController *queryBuilderViewController = (MADQueryViewController *)[segue.destinationViewController topViewController];
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
            if ([popoverController isPopoverVisible]) {
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
    self.shouldShowAddDocumentPopover = true;
    [self.barButtonItemAddNewDocument setEnabled:YES];
}

#pragma mark - 
#pragma mark MTViewControllerProtocol

- (void)viewControllerDidFinish:(id)sender {
    self.shouldShowAddDocumentPopover = true;
    MADTabBarController *tabController = self.tabController;
    [tabController setViewControllers:nil animated:YES];
    [self dismissViewControllerAnimated:YES completion:^{ }];

    self.shouldShowAddDocumentPopover = true;
    self.barButtonItemAddNewDocument.enabled = YES;
    [self.openDocumentPopoverController dismissPopoverAnimated:YES];
    
    MADocument *openDocument = self.fileManager.openDocument;
    if (openDocument && openDocument.documentState != UIDocumentStateClosed) {
        MADOpenDocumentManager * __unsafe_unretained fileManager = self.fileManager;
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
    self.shouldShowAddDocumentPopover = true;
    [self.barButtonItemAddNewDocument setEnabled:YES];
}

#pragma mark -
#pragma mark MADOpenFileViewControllerDelegate

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
        
        self.fileManager.openDocument = document;
        
    }

    MADocument *allocatedDocument = self.fileManager.openDocument;
    [allocatedDocument openWithCompletionHandler:^(BOOL success) { }];

}

- (NSString *)mimeTypeForDocumentUTI:(NSString *)documentType {
    if ([documentType isEqualToString:MADUtiType]) {
        return MADMimeType;
    } else {
        NSAssert(false, @"Unknown type at %s", __PRETTY_FUNCTION__);
        return MADMimeType;
    }
}

- (NSArray *)supportedUTIs {
    NSArray *UTIs = @[MADUtiType];
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
#pragma mark MTDocumentCellProtocol

- (void)editFile:(id)sender {
    [self activateEditMode:sender];
}

- (void)emailFile:(id)sender {
    [self email:sender];
}

- (void)renameFile:(id)sender {
    [self rename:sender];
}

- (void)duplicateFile:(id)sender {
    [self actionDuplicate:sender];
}

#pragma mark - 
#pragma mark Actions

- (IBAction)addDocument:(id)sender {
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

- (IBAction)info:(id)sender {
    UINavigationController *infoViewController = [UINavigationController AppInformation];
    UIPopoverPresentationController *ppc = infoViewController.popoverPresentationController;
    ppc.passthroughViews = [ppc.passthroughViews arrayByAddingObjectsFromArray:[self defaultPassthroughViews]];
    ppc.backgroundColor = [UIColor clearColor];
    ppc.delegate = self;
    ppc.barButtonItem = sender;
    self.infoPopoverPresentationController = ppc;
    [self showViewController:infoViewController sender:self];
}

- (IBAction)about:(id)sender {
    if (self.aboutViewControllerOnScreen) {
        self.aboutViewControllerOnScreen = false;
        [self dismissViewControllerAnimated:YES completion:^{ }];
    } else {
        self.aboutViewControllerOnScreen = true;
        
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

- (IBAction)documentInformation:(id)sender {
    MADMetaData *metadata = nil;
    NSArray *selectedItems = [self.collectionView indexPathsForSelectedItems];
    NSIndexPath *indexPath;
    NSMutableArray *metadataItems = [[NSMutableArray alloc] initWithCapacity:selectedItems.count];
    for (indexPath in selectedItems) {
        metadata = [self.filesCoordnator.filesController objectAtIndexedSubscript:(NSUInteger)indexPath.item];
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
    [self done:sender];
}

- (IBAction)store:(id)sender {
    
    UINavigationController *licensing = [UINavigationController Licensing];
    licensing.modalPresentationStyle = UIModalPresentationFormSheet;
    licensing.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    ((MADStoreViewController *)licensing.viewControllers[0]).delegate = self;
    [self showViewController:licensing sender:self];
    
}

- (IBAction)cancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.barButtonItemAddNewDocument setEnabled:YES];
}

- (IBAction)search:(id)sender {
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

- (IBAction)edit:(id)sender {
    
    BOOL startEdit = !self.isEditing;
    [self setEditing:startEdit animated:YES];
    
    if (startEdit) {
        
        //self.barButtonItemLicensing.enabled = NO;
        self.barButtonItemAddNewDocument.enabled = NO;
        self.barButtonItemAbout.enabled = NO;
        self.barButtonItemInformation.enabled = NO;
        self.collectionView.allowsMultipleSelection = YES;
        
        for (MTCollectionViewCellDocument *cell in self.collectionView.visibleCells) {
            [cell startWobble];
        }
        [self.navigationItem setRightBarButtonItem: self.barButtonItemEditDone animated: YES];
        
    } else {
        [self done:sender];
    }
}

- (IBAction)done:(id)sender {
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
    for (MTCollectionViewCellDocument *cell in self.collectionView.visibleCells) {
        [cell stopWobble];
        [cell normalizeTint];
    }

}

- (IBAction)download:(id)sender {
    NSArray *documentTypes = [self supportedUTIs];
    UIDocumentPickerViewController *picker;
    picker = [[UIDocumentPickerViewController alloc] initWithDocumentTypes: documentTypes
                                                                    inMode: UIDocumentPickerModeImport];
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:^{}];
}

- (IBAction)cut:(id)sender {
    [super cut:sender];
}

- (IBAction)copy:(id)sender {
    [super copy:sender];
}

- (IBAction)paste:(id)sender {
    NSURL *url = [[UIPasteboard generalPasteboard] URL];
    NSData *data = [[NSData alloc] initWithContentsOfURL:url];
    NSFileWrapper *fileWrapper = [[NSFileWrapper alloc] initWithSerializedRepresentation:data];
    NSURL *destinationUrl = [url uniqueUrl];
    
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

- (IBAction)activity:(id)sender {
    
    NSMutableArray *wrappedUrls =
        [[NSMutableArray alloc] initWithCapacity: self.filesCoordnator.filesController ?
                                                    self.filesCoordnator.filesController.count : 0];

    NSArray<NSIndexPath *> *indexPaths = self.collectionView.indexPathsForSelectedItems;
    for (NSIndexPath *indexPath in indexPaths) {
        NSURL *fileUrl = [self copyMetaDataUrlForIndexPath:indexPath];
        [wrappedUrls addObject:fileUrl];
    }
    
    NSInteger numberOfItemsInSection = [self.collectionView numberOfItemsInSection:0];
    for (NSInteger i=0; i<numberOfItemsInSection; i++) {
        NSIndexPath *path = [NSIndexPath indexPathForItem:i inSection:0];
        MTCollectionViewCellDocument *documentCell;
        documentCell = (MTCollectionViewCellDocument *)[self.collectionView cellForItemAtIndexPath:path];
        if (documentCell != nil) {
            [documentCell normalizeTint];
        }
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
            MTCollectionViewCellDocument * __weak documentCell = (MTCollectionViewCellDocument *)cell;
            [documentCell normalizeTint];
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
            [self setPopoverControllerActivity:popoverController];
        }
    } else {
        [self presentViewController:activityViewController animated:YES completion:^{ }];
    }
}

- (IBAction)delete:(id)sender {

    NSArray *selectedItems = self.collectionView.indexPathsForSelectedItems;
    UIAlertController *alertController = [UIAlertController deleteItems:selectedItems.count
                                                                confirm:^(UIAlertAction *action) {
    
        MADMetaData *metaData;
        for (NSIndexPath *selectedItem in selectedItems) {
            metaData = [self.filesCoordnator.filesController objectAtIndexedSubscript:(NSUInteger)selectedItem.item];
            [self.filesCoordnator.filesController removeFileInfo:metaData];
        }
        
    } cancel:^(UIAlertAction *action) { }];
    
    if ([sender isKindOfClass:[UIBarButtonItem class]]) {
        alertController.popoverPresentationController.barButtonItem = sender;
    }
    [self presentViewController:alertController animated:YES completion:NULL];
}

- (IBAction)actionDuplicate:(id)sender {
    for (NSIndexPath *selectedItem in self.collectionView.indexPathsForSelectedItems) {
        MADMetaData *metaData = [self.filesCoordnator.filesController objectAtIndexedSubscript:(NSUInteger)selectedItem.item];
        [self.filesCoordnator.filesController duplicateFileInfo:metaData];
    }
}

- (IBAction)rename:(id)sender {
    
    MTCollectionViewCellDocument *cellDocument;
    if ([sender isKindOfClass:[MTCollectionViewCellDocument class]]) {
        cellDocument = sender;
    } else if ([sender isKindOfClass:[UITapGestureRecognizer class]]) {
        UIView *contentView = ((UITapGestureRecognizer *)sender).view.superview;
        cellDocument = (MTCollectionViewCellDocument *)contentView.superview;
    }
    
    NSAssert(cellDocument != nil, @"Null cell at %s.", __PRETTY_FUNCTION__);
    
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cellDocument];
    MADMetaData *metaData = [self.filesCoordnator.filesController objectAtIndexedSubscript:(NSUInteger)indexPath.item];
    
    NSString *textFieldText = cellDocument.labelTitle.text.copy;
    UIAlertController *alert = [UIAlertController renameDocument:^(UITextField *textField) {
        
        textField.text = textFieldText;
        textField.clearButtonMode = UITextFieldViewModeAlways;
        textField.delegate = self;
        
    } confirm:^(UIAlertAction *action, NSString *text) {
        
        NSString *name = [NSURL newStringFileNameFilter:text];
        if (name.length > 0) {
            NSURL *newUrl = [metaData.URL.URLByDeletingLastPathComponent
                                            URLByAppendingPathComponent:name isDirectory:NO];
            NSString *path = newUrl.path;
            if ([[NSFileManager defaultManager] fileExistsAtPath:path] == NO &&
                [[NSFileManager defaultManager] isUbiquitousItemAtURL:newUrl] == NO) {
                if (metaData.isUbiquitousItemDownloadingStatusNotDownloaded) {
                    
                    MADocument *doc = [MADocument newManagedDocumentForURL:metaData.URL];
                    [doc openWithCompletionHandler:^(BOOL success) {
                        if (success) {
                            [MADocument close: doc completion:^(BOOL successClose) {
                                if (successClose) {
                                    [self.filesCoordnator.filesController renameFileInfo:metaData toName:text];
                                }
                            }];
                        }
                    }];
                    
                } else {
                    [self.filesCoordnator.filesController renameFileInfo:metaData toName:text];
                }
            } else {
                UIAlertController *alertFileExist = [UIAlertController newAlertControllerErrorFileExist];
                [self showViewController:alertFileExist sender:self];
            }
        } else {
            UIAlertController *alertFilename = [UIAlertController newAlertControllerErrorValidationFilename];
            [self showViewController:alertFilename sender:self];
        }
        
    } cancel:nil];
    
    [self showViewController:alert sender:self];
    
}

- (IBAction)email:(MTCollectionViewCellDocument *)cell {
    
    NSIndexPath *indexPath;
    MADMetaData *metadata;
    MADocument *documentReport;
    
    if ([MFMailComposeViewController canSendMail] == NO) {
        UIAlertController *alert = [UIAlertController newAlertControllerNotConfiguredForEmail];
        [self showViewController:alert sender:self];
        return;
    }

    indexPath = [self.collectionView indexPathForCell:cell];
    metadata = [self.filesCoordnator.filesController objectAtIndexedSubscript:(NSUInteger)indexPath.item];
    documentReport = [MADocument newManagedDocumentForURL:metadata.URL];
    
    if (documentReport.documentState != UIDocumentStateClosed) {
        
        [MADocument close: documentReport completion:^(BOOL success) {
            if (success) {
                [self email:cell];
            }
        }];
        
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

- (void)activateEditMode:(UILongPressGestureRecognizer *)sender {

    if (sender.state == UIGestureRecognizerStateBegan) {
        NSIndexPath *indexPath = [self.collectionView indexPathForCell:((MTCollectionViewCellDocument *)sender.view)];
        if (self.isEditing == NO) [self edit:self];
        
        [self.collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
        [self selectionsUpdated];
    }
}

#pragma mark -
#pragma mark Helpers

- (NSString *)copySubtitleForMetadata:(MADMetaData *)metadata {
    NSString *result;
    NSString *downloadingStatus = metadata.ubiquitousItemDownloadingStatus.copy;
    if ([downloadingStatus isEqualToString: NSMetadataUbiquitousItemDownloadingStatusNotDownloaded]) {
        result = NSLocalizedString(NotDownloaded, NotDownloaded);;
    } else {
        NSNumber *systemFileSizeMB = [[NSNumber alloc] initWithDouble:madSystemFileSizeToMB(metadata.fileSystemFileSize)];
        NSString *systemFileSizeString = [self.subtitleNumberFormatter stringFromNumber:systemFileSizeMB];
        result = [[NSString alloc] initWithFormat:@"%@ MB", systemFileSizeString];
    }
    return result;
}


#pragma mark - 
#pragma mark UIAdaptivePresentationControllerDelegate

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller {
    UIModalPresentationStyle style = UIModalPresentationOverCurrentContext;
    if ([controller isEqual:self.aboutPopoverPresentationController] || [controller isEqual:self.infoPopoverPresentationController] ||
        [controller isEqual:self.documentInformationPopoverPresentationController]) {
        style = UIModalPresentationNone;
    }
    return style;
}

#pragma mark - 
#pragma mark UIPopoverPresentationControllerDelegate

- (void)prepareForPopoverPresentation:(UIPopoverPresentationController *)popoverPresentationController { }

- (BOOL)popoverPresentationControllerShouldDismissPopover:(UIPopoverPresentationController *)popoverPresentationController { return YES; }

- (void)popoverPresentationControllerDidDismissPopover:(UIPopoverPresentationController *)popoverPresentationController {
    self.aboutViewControllerOnScreen = false;
}

#pragma mark -
#pragma mark Update UI

- (void)updateProgressView:(UIProgressView *)progressView
                    active:(bool)active
                   percent:(double)percent {
    
    if (!active) {
        progressView.hidden = YES;
        [progressView setProgress:Float_0 animated:YES];
        return;
    }
    
    progressView.hidden = NO;
    if (progressView.progress < percent / Float_100) {
        [progressView setProgress: (float) (percent / Float_100)
                         animated: YES];
    }
}

- (void)reenable { }

- (void)selectionsUpdated {
    
    NSArray *indexPaths = self.collectionView.indexPathsForSelectedItems;
    
    switch (indexPaths.count) {
            
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

@end
