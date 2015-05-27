//
//  MTViewControllerOpenDocument
//  MAD Designer
//
//  Created by Michael Thomason on 1/2/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADOpenFileViewController.h"
#import "MADConstants.h"
#import <MessageUI/MessageUI.h>

#import "AppDelegate.h"
#import "MTApplicationInstance.h"

#import "MADGroupedCollectionViewLayout.h"

#import "MADocument.h"
#import "MADMetaData.h"
#import "MADSearchBar.h"

#import "MADOpenFileSectionHeaderView.h"
#import "MTCollectionViewCellDocument.h"

#import "MADViewerController.h"

#import "MTStoreKitController.h"
#import "MTStoreKitController+NonRenewableLicensing.h"

#import "MADDesignerViewController.h"
#import "MADWatermarkView.h"

#import "MTQueryBuilderContainerController.h"

#import "MADAboutTableViewController.h"

#import "MADQueryViewController.h"
#import "MTDatabaseDriverSelectorViewController.h"

#import "MADFileManager.h"
#import "MADMetadataQueryManager.h"
#import "MADUpgradeManager.h"
#import "MADBarButtonItem.h"

#import "UIColor+EverydayApps.h"
#import "UIView+Animations.h"
#import "UIDevice+Hack.h"
#import "NSFileManager+Common.h"
#import "NSError+Constructors.h"
#import "NSURL+Document.h"
#import "UIAlertController+Constructors.h"
#import "MTNavigationController.h"
#import "MADTransparentPresentationController.h"
#import "MADNavigationBarTitleView.h"
#import "MADDocumentInformationTableViewController.h"
#import "NSMetadataItem+Description.h"

#import "MADFilesController.h"
#import "MADAppLaunchContext.h"
#import "MADFileInfo.h"

#import "MTPair.h"

#import "MADProgressView.h"

NSString * const MTSegueOpenInViewer                            = @"MTSegueOpenInViewer";
NSString * const MTSegueShowAddDocument                         = @"showAddDocument";
NSString * const MTSegueShowOpenDocument                        = @"MADSegueOpenDocument";
NSString * const MTCollectionViewCellDocumentIdentifier         = @"MTCollectionViewCellDocumentIdentifier";
NSString * const MTSegueLicensing                               = @"MTSegueLicensing";
NSString * const MADIdentifierOpenFileSectionHeader             = @"MADIdentifierOpenFileSectionHeader";

CGFloat const MADSectionHeaderHeight                            = 32.0000f;
CGFloat const MADConstCellDocumentLabelWidth                    = 124.0000f;
CGFloat const MADConstCellDocumentLabelMaxHeight                = 300.0000f;

@interface MADOpenFileViewController()
    <NSFileManagerDelegate,
        UIPopoverControllerDelegate,
        UIPopoverPresentationControllerDelegate,
        UICollectionViewDelegateFlowLayout,
        UIGestureRecognizerDelegate,
        MFMailComposeViewControllerDelegate,
        UITextFieldDelegate,
        UIDocumentInteractionControllerDelegate,
        UIDocumentPickerDelegate,
        UISearchBarDelegate,
        UIStateRestoring,
        MTViewControllerProtocol,
        MTDocumentCellProtocol,
        MADFilesControllerDelegate>

@property (nonatomic, strong) MADAppLaunchContext *pendingLaunchContext;

@property (nonatomic, strong) IBOutlet  UIBarButtonItem *barButtonItemAction;
@property (nonatomic, strong) IBOutlet  UIBarButtonItem *barButtonItemEdit;
@property (nonatomic, weak)   IBOutlet  UIBarButtonItem *barButtonItemInformationDocument;
@property (nonatomic, strong)           UIBarButtonItem *barButtonItemLicensing;
@property (nonatomic, strong)           UIBarButtonItem *barButtonItemEditDone;
@property (nonatomic, weak)   IBOutlet  UIBarButtonItem *barButtonItemTrash;
@property (nonatomic, weak)   IBOutlet  UIBarButtonItem *barButtonItemInformation;
@property (nonatomic, weak)   IBOutlet  UIBarButtonItem *barButtonItemAbout;
@property (nonatomic, weak)   IBOutlet  UIBarButtonItem *barButtonItemAddNewDocument;
@property (nonatomic, weak)   IBOutlet  UIBarButtonItem *barButtonItemCloudDown;
@property (nonatomic, strong) IBOutlet  UIBarButtonItem *barButtonItemSearch;
@property (nonatomic, strong)           UIBarButtonItem *barButtonItemDuplicate;

@property (nonatomic, weak) UIPopoverPresentationController *aboutPopoverPresentationController;
@property (nonatomic, weak) UIPopoverPresentationController *infoPopoverPresentationController;
@property (nonatomic, weak) UIPopoverPresentationController *documentInformationPopoverPresentationController;

@property (nonatomic, strong) MTNavigationController *aboutNavigationController;

@property (nonatomic, strong) UIPopoverController *openDocumentPopoverController;
@property (nonatomic, strong) UIPopoverController *licensingPopoverController;
@property (nonatomic, strong) UIPopoverController *popoverControllerActivity;

@property (nonatomic, assign) BOOL shouldShowAddDocumentPopover;
@property (atomic, assign) BOOL aboutViewControllerOnScreen;

@property (nonatomic, assign, getter = isSavingActivityIndicatorVisible, readwrite) BOOL savingActivityIndicatorVisible;
@property (nonatomic, assign, getter = isRightBarButtonItemActivityIndicatorVisible, readwrite) BOOL rightBarButtonItemActivityIndicatorVisible;

@property (nonatomic, strong) MADSearchBar *searchBar;
@property (nonatomic, strong) UILabel *labelMadDesigner;

@property (nonatomic, strong) UIBarButtonItem *rightBarButtonItemHolderWhileActivity;

@property (nonatomic, assign) BOOL firstViewWillAppear;

@property (nonatomic, strong) MADOpenFileSectionHeaderView *headerCloud;

@property (nonatomic, assign) BOOL cloudActivityRunning;
@property (nonatomic, assign) BOOL cloudActivityRunningDisplay;

@property (nonatomic, strong) UILabel *testLabel;
@property (nonatomic, strong) UILabel *testLabelSub;

@property (nonatomic, strong) UIProgressView *progressViewFileManager;

@property (atomic, assign, getter=isUpdatingEnabled) BOOL updatingEnabled;

@property (nonatomic, strong) NSMutableArray *batchInserts;
@property (nonatomic, strong) NSMutableArray *batchRemoves;
@property (nonatomic, strong) NSMutableArray *batchUpdates;

@end

@implementation MADOpenFileViewController

#pragma mark - Static Functions

+ (NSString *)keySubviews {
    return NSStringFromSelector(@selector(subviews));
}
+ (NSString *)keyLeftView {
    return NSStringFromSelector(@selector(leftView));
}

static inline CGRect rectCellLabel();
static inline CGRect rectCellLabel() {
    return CGRectMake(CGPointZero.x, CGPointZero.y, MADConstCellDocumentLabelWidth, MADConstCellDocumentLabelMaxHeight);
}

#pragma mark - NSObject

- (void)dealloc {
    
    [self removeObservers];
    
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    
    if (self = [super initWithCoder:aDecoder]) {
        
        MADProgressView *progressView = [[MADProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
        self.progressViewFileManager = progressView;
        
        NSMutableArray *batchInserts = [[NSMutableArray alloc] init];
        self.batchInserts = batchInserts;
        
        NSMutableArray *batchRemoves = [[NSMutableArray alloc] init];
        self.batchRemoves = batchRemoves;
        
        NSMutableArray *batchUpdates = [[NSMutableArray alloc] init];
        self.batchUpdates = batchUpdates;

    }
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if ([keyPath isEqualToString:[MADOpenFileViewController keySubviews]]) {
        if ([object isKindOfClass:[UITextField class]]) {
            
            
            for (UIView *view in ((UITextField *)object).subviews) {
                if ([view isKindOfClass:[UIButton class]]) {
                    
                    
                    UIImage *image = [((UIButton *)view).imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
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
    
    [self addObservers];
    
    self.aboutViewControllerOnScreen = NO;
    
    self.updatingEnabled = YES;
    self.cloudActivityRunning = NO;
    self.cloudActivityRunningDisplay = NO;
    self.firstViewWillAppear = YES;
    self.rightBarButtonItemActivityIndicatorVisible = NO;
    
    [self setNeedsStatusBarAppearanceUpdate];
    
    UILabel *label = [[UILabel alloc] initWithFrame:rectCellLabel()];
    label.clipsToBounds = NO;
    label.numberOfLines = 0;
    
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem: label
                                                                  attribute: NSLayoutAttributeWidth
                                                                  relatedBy: NSLayoutRelationEqual
                                                                     toItem: nil
                                                                  attribute: NSLayoutAttributeNotAnAttribute
                                                                 multiplier: 1.0000f
                                                                   constant: MADConstCellDocumentLabelWidth];
    [label addConstraint:constraint];
    self.testLabel = label;
    
    UILabel *subLabel = [[UILabel alloc] initWithFrame:rectCellLabel()];
    subLabel.clipsToBounds = NO;
    subLabel.numberOfLines = 0;
    
    NSLayoutConstraint *constraintSub = [NSLayoutConstraint constraintWithItem: subLabel
                                                                  attribute: NSLayoutAttributeWidth
                                                                  relatedBy: NSLayoutRelationEqual
                                                                     toItem: nil
                                                                  attribute: NSLayoutAttributeNotAnAttribute
                                                                 multiplier: 1.0000f
                                                                   constant: MADConstCellDocumentLabelWidth];
    [subLabel addConstraint:constraintSub];
    self.testLabelSub = subLabel;
    
    self.collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(self.collectionView.contentInset.top + ([MACloudManager isCloudAvailable] ? MADSectionHeaderHeight : CGSizeZero.height),
                                                                 self.collectionView.contentInset.left,
                                                                 self.collectionView.contentInset.bottom,
                                                                 self.collectionView.contentInset.right);
    
    
    [self.collectionView registerClass: [MADOpenFileSectionHeaderView class]
            forSupplementaryViewOfKind: UICollectionElementKindSectionHeader
                   withReuseIdentifier: MADIdentifierOpenFileSectionHeader];
    
    UIBarButtonItem *barButtonItemEditDone = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemDone
                                                                                           target: self
                                                                                           action: @selector(edit:)];
    self.barButtonItemEditDone = barButtonItemEditDone;
    [self setEditing:NO animated:NO];
    
    UIColor *barTintColor = [UIColor tintColorBlue];
    UIColor *tintColor = [UIColor tintColorWhite];
    self.navigationController.toolbar.barTintColor = barTintColor;
    self.navigationController.toolbar.tintColor = tintColor;
    
    MADWatermarkView *watermarkView = [[MADWatermarkView alloc] initWithFrame: self.collectionView.bounds];
    //UIImageView *testimage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"testimage.jpg"]];
    //testimage.frame=self.collectionView.frame;
    //[watermarkView addSubview:testimage];
    
    self.collectionView.backgroundView = watermarkView;
    //self.collectionView.backgroundColor = [UIColor purpleColor];
    
    UIColor *bgColor = [UIColor lightGrayColor];
    self.collectionView.backgroundColor = bgColor;
    
    [self setSavingActivityIndicatorVisible:NO];
    
    MADNavigationBarTitleView *titleView = [[MADNavigationBarTitleView alloc] initWithFrame: CGRectZero];
    titleView.text = [MTApplicationInstance applicationName];
    
    
    self.navigationItem.titleView = titleView;
    self.labelMadDesigner = titleView;
    
    self.navigationItem.hidesBackButton = YES;
    
    UITapGestureRecognizer *tapGestureRecognizer = [self tapGestureRecognizer];
    [self.collectionView addGestureRecognizer:tapGestureRecognizer];
    
    self.barButtonItemLicensing.enabled = [SKPaymentQueue canMakePayments];
    
    NSMutableArray *toolbarButtons = [NSMutableArray arrayWithArray: self.toolbarItems];
    [toolbarButtons removeObject:self.barButtonItemAction];
    
    // FIXME: Remove cloud down button until feature is added.
    [toolbarButtons removeObject:self.barButtonItemCloudDown];
    
    MADSearchBar *searchBar = [[MADSearchBar alloc] initWithFrame:CGRectZero];
    [searchBar sizeToFit];
    
    self.searchBar = searchBar;
    
    if (self.barButtonItemEdit == nil) {
        UIBarButtonItem *edit = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemEdit
                                                                              target: self
                                                                              action: @selector(edit:)];
        self.barButtonItemEdit = edit;
    }
    
    [toolbarButtons addObject:self.barButtonItemEdit];
    
    UIImage *imageDuplcate = [UIImage imageNamed:@"MADImageToolbarDuplicate"];
    UIBarButtonItem *barButtonItemDuplicate = [[UIBarButtonItem alloc] initWithImage: imageDuplcate
                                                                               style: UIBarButtonItemStylePlain
                                                                              target: self
                                                                              action: @selector(duplicate:)];
    barButtonItemDuplicate.enabled = NO;
    [toolbarButtons insertObject:barButtonItemDuplicate atIndex:1];
    self.barButtonItemDuplicate = barButtonItemDuplicate;
    
    [self setToolbarItems:toolbarButtons animated:NO];
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (self.pendingLaunchContext) {
        [self configureViewControllerWithLaunchContext:self.pendingLaunchContext];
    }
    
    self.pendingLaunchContext = nil;
    
    for (NSIndexPath *indexPath in self.collectionView.indexPathsForSelectedItems) {
        
        MTCollectionViewCellDocument *cell = (MTCollectionViewCellDocument *)[self.collectionView cellForItemAtIndexPath:indexPath];
        [cell performDeselectionAnimations];
        
    }
    
    for (NSUInteger item = 0; item < [self.collectionView numberOfItemsInSection:0]; item++) {
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem: item
                                                     inSection: 0];
        
        [self.collectionView deselectItemAtIndexPath: indexPath
                                            animated: YES];
        
    }
    
    self.aboutViewControllerOnScreen = NO;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.collectionView.backgroundView setNeedsDisplay];
    
    [[MTStoreKitController sharedObject] licensedUser:^(BOOL isLicensedUser, NSDate *experationDate) {
        if (isLicensedUser) {
            [self addActionItemToToolbar:animated];
        }
    }];
    
    if (self.firstViewWillAppear == NO) {
        [self reenableDataWithSearch];
    }
    
    self.firstViewWillAppear = NO;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self.collectionView.backgroundView setNeedsDisplay];
}

#pragma mark - UIResponder

- (void)restoreUserActivityState:(NSUserActivity *)activity {
    // Obtain an app launch context from the provided activity and configure the view controller with it.
    MADAppLaunchContext *launchContext = [[MADAppLaunchContext alloc] initWithUserActivity:activity];
    
    // Configure the view controller with the launch context.
    [self configureViewControllerWithLaunchContext:launchContext];
}

#pragma mark - Property Overrides

- (void)setFilesController:(MADFilesController *)filesController {
    if (filesController != _filesController) {
        _filesController = filesController;
        _filesController.delegate = self;
    }
}

#pragma mark - add controls

- (void)addProgressViewToView {
    self.progressViewFileManager.progress = 0.0000f;
    [self.view addSubview:self.progressViewFileManager];
    [self.view bringSubviewToFront:self.progressViewFileManager];
}

- (void)removeProgressViewFromView {
    [self.progressViewFileManager removeFromSuperview];
}

#pragma mark - UIStateRestoring

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    [super encodeRestorableStateWithCoder:coder];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
    [super decodeRestorableStateWithCoder:coder];
}

- (void)applicationFinishedRestoringState {
    if ([MTApplicationInstance isMadDesigner]) {
        [self performSegueWithIdentifier: MTSegueShowOpenDocument
                                  sender: self];
    } else if ([MTApplicationInstance isMadViewer]) {
        [self performSegueWithIdentifier: MTSegueOpenInViewer
                                  sender: self];
    }
}

#pragma mark - Exit

- (void)closeAndSave {
    MTApplicationInstance *app = [AppDelegate app];
    __weak MADOpenFileViewController *weakself = self;
    [[app openDocument] regenThumbnailWithTraits:self.traitCollection];
    [app closeReportWithCompletionHandler:^(BOOL success) {
        [weakself reenable];
    }];
}

- (IBAction)unwindToOpenDocumentViewController:(UIStoryboardSegue *)action {
    
    NSString *actionIdentifier = [action identifier];
    if ([actionIdentifier isEqualToString:@"MTSegueCloseDesigner"] ||
        [actionIdentifier isEqualToString:@"MAReportViewerCloseReportIdentifier"]) {
        [self closeAndSave];
    }
    self.shouldShowAddDocumentPopover = YES;
    self.barButtonItemAddNewDocument.enabled = YES;
    
    if ([MTApplicationInstance isMadViewer] && self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad) {

    } else if ([MTApplicationInstance isMadViewer] && self.traitCollection.userInterfaceIdiom != UIUserInterfaceIdiomPad) {
    
    } else {
        [self.openDocumentPopoverController dismissPopoverAnimated:YES];
    }
}

- (BOOL)canPerformUnwindSegueAction:(SEL)action
                 fromViewController:(UIViewController *)fromViewController
                         withSender:(id)sender {
    return action == @selector(unwindToOpenDocumentViewController:);
}

- (UIViewController *)viewControllerForUnwindSegueAction:(SEL)action
                                      fromViewController:(UIViewController *)fromViewController
                                              withSender:(id)sender {
    
    return action == @selector(unwindToOpenDocumentViewController:) ?
            self :
            [super viewControllerForUnwindSegueAction: action
                                   fromViewController: fromViewController
                                           withSender: sender];
}

- (void)awakeFromNib {
    self.shouldShowAddDocumentPopover = YES;
    [self.barButtonItemAddNewDocument setEnabled:YES];
    [super awakeFromNib];
}

#pragma mark - NSNotificationCenter

- (void)addObservers {
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleContentSizeCategoryDidChangeNotification:)
                                                 name: UIContentSizeCategoryDidChangeNotification
                                               object: nil];
    
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleCloudActivityStarted:)
                                                 name: @"MADNotificationCloudActivityStarted"
                                               object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleCloudActivityCompleted:)
                                                 name: @"MADNotificationCloudActivityCompleted"
                                               object: nil];
}

- (void)removeObservers {
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: UIContentSizeCategoryDidChangeNotification
                                                  object: nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: @"MADNotificationCloudActivityStarted"
                                                  object: nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: @"MADNotificationCloudActivityCompleted"
                                                  object: nil];
}

- (void)handleContentSizeCategoryDidChangeNotification:(NSNotification *)notification {
    NSString *contentSize = notification.userInfo[UIContentSizeCategoryNewValueKey];
    [self updateInterfaceForPerferedContentSizeCategory:contentSize];
    [self.view setNeedsLayout];
}

- (void)updateInterfaceForPerferedContentSizeCategory:(NSString *)preferredContentSizeCategory {
    for (MTCollectionViewCellDocument *cell in self.collectionView.visibleCells) {
        [cell updateFont];
    }
}

- (void)handleCloudActivityStarted:(NSNotification *)notification {
    self.cloudActivityRunning = YES;
    NSTimer *timer = [NSTimer timerWithTimeInterval: 0.5000f
                                             target: self
                                           selector: @selector(displayActivityIndictor)
                                           userInfo: nil
                                            repeats: NO];
    [timer fire];
}

#pragma mark - UIViewController

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    if (self.traitCollection.horizontalSizeClass != previousTraitCollection.horizontalSizeClass) {
        [self.collectionView.collectionViewLayout invalidateLayout];
    }
}

- (void)willTransitionToTraitCollection: (UITraitCollection *)newCollection
              withTransitionCoordinator: (id<UIViewControllerTransitionCoordinator>)coordinator {
    
    [super willTransitionToTraitCollection: newCollection
                 withTransitionCoordinator: coordinator];
    
    __weak MADOpenFileViewController *weakself = self;
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [weakself.collectionView.backgroundView setNeedsDisplay];
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [weakself.navigationItem.titleView sizeToFit];
    }];

}

- (void)displayActivityIndictor {
    if (self.cloudActivityRunning) {
        self.cloudActivityRunningDisplay = YES;
        [self.headerCloud startAnimating];
    }
}

- (UIViewController *)childViewControllerForStatusBarHidden {
    return self.presentedViewController;
}

- (void)handleCloudActivityCompleted:(NSNotification *)notification {
    self.cloudActivityRunning = NO;
    self.cloudActivityRunningDisplay = NO;
    [self.headerCloud stopAnimating];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (UITapGestureRecognizer *)tapGestureRecognizer {
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget: self
                                                                                           action: @selector(handleDidTapCollectionView:)];
    tapGestureRecognizer.delegate = self;
    return tapGestureRecognizer;
}

#pragma mark - UISearchBarDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField { }

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar { }

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope { }

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    //[[MACloudManager sharedManager] reloadCacheLocal:self.searchBar.text];
    //[[MACloudManager sharedManager] reloadCacheCloud:self.searchBar.text];

    //[self animateUpdates];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar { }

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    //if (self.searchBar.text.length > 0) {
    //    self.searchBar.text = @"";
        //[[MACloudManager sharedManager] reloadCacheLocal:self.searchBar.text];
        //[[MACloudManager sharedManager] reloadCacheCloud:self.searchBar.text];

        //[self animateUpdates];
    //}
    //[searchBar resignFirstResponder];
    //[self search: self];
}

- (void)reenableDataWithSearch {
    //if (self.searchBar) {
    //    [self searchBar: self.searchBar
    //      textDidChange: self.searchBar.text];
    //} else {
    //[self.collectionView reloadData];
    //}
}

#pragma mark - Segues

- (void)prepareForSegueLicensing:(UIStoryboardSegue *)segue {
    if ([segue.destinationViewController isKindOfClass: [UINavigationController class]]) {
        UINavigationController *navControl = segue.destinationViewController;
        id tvc = [navControl topViewController];
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
    MTApplicationInstance *app = [AppDelegate app];
    viewControllerReportViewer.document = [app openDocument];
}

- (void)prepareForSegueShowOpenDocument:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.destinationViewController isKindOfClass: [UINavigationController class]] ||
        [segue.destinationViewController isKindOfClass: [UITabBarController class]]) {
        
        if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
            UITabBarController *tabBarController = (UITabBarController *)segue.destinationViewController;
            tabBarController.view.tintColor = [UIColor tintColorRed];
            
            UINavigationController *navController = (UINavigationController *)[tabBarController viewControllers][0];
            MTQueryBuilderContainerController *queryBuilderContainerController = (MTQueryBuilderContainerController *)[navController topViewController];
            queryBuilderContainerController.viewControllerDelegate = self;
            
            UINavigationController *navController2 = (UINavigationController *)[tabBarController viewControllers][1];
            MADDesignerViewController *reportDesignerViewController = (MADDesignerViewController *)[navController2 topViewController];
            reportDesignerViewController.delegate = self;
            
            UINavigationController *navController3 = (UINavigationController *)[tabBarController viewControllers][2];
            MADViewerController *reportViewerViewController = (MADViewerController *)[navController3 topViewController];
            reportViewerViewController.viewControllerDelegate = self ;
            
            MTApplicationInstance *app = [AppDelegate app];
            MADocument *document = [app openDocument];
            queryBuilderContainerController.document = document;
            reportDesignerViewController.document = document;
            reportViewerViewController.document = document;

        } else {
            
            UITabBarController *tabBarController = (UITabBarController *)segue.destinationViewController;
            [[tabBarController view] setTintColor:[UIColor greenColor]];
            [[UITabBar appearance] setTintColor:[UIColor redColor]];
            
            UINavigationController *navController = (UINavigationController *)[tabBarController viewControllers][0];

            MTQueryBuilderContainerController *queryBuilderContainerController = (MTQueryBuilderContainerController *)[navController topViewController];
            queryBuilderContainerController.viewControllerDelegate = self;
            
            MADQueryViewController *queryBuilderViewController = (MADQueryViewController *)[navController topViewController];
            
            UINavigationController *navController2 = (UINavigationController *)[tabBarController viewControllers][1];
            MADDesignerViewController *reportDesignerViewController = (MADDesignerViewController *)[navController2 topViewController];
            reportDesignerViewController.delegate = self;
            
            UINavigationController *navController3 = (UINavigationController *)[tabBarController viewControllers][2];
            MADViewerController *reportViewerViewController = (MADViewerController *)[navController3 topViewController];
            reportViewerViewController.viewControllerDelegate = self;
            MTApplicationInstance *app = [AppDelegate app];
            MADocument *document = [app openDocument];
            queryBuilderViewController.document = document;
            reportDesignerViewController.document = document;
            reportViewerViewController.document = document;

        }
        
    } else if ([segue.destinationViewController isKindOfClass:[MTQueryBuilderContainerController class]]) {
        
    } else if ([segue.destinationViewController isKindOfClass:[MADQueryViewController class]]) {
        MADQueryViewController *queryBuilderViewController = (MADQueryViewController *)[segue.destinationViewController topViewController];
        MTApplicationInstance *app = [AppDelegate app];
        MADocument *document = [app openDocument];
        queryBuilderViewController.document = document;
        [queryBuilderViewController reloadDocument:document animated:YES];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [super prepareForSegue:segue sender:sender];

    [self dismissAllPopovers];
    
    if ([segue.identifier isEqualToString:MTSegueLicensing]) {
        [self prepareForSegueLicensing:segue];

    }
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    
    // FIXME: Only do this when you are going to disable some feature for copy protection
    //          Right now it's just a pain in the ass.
    //static dispatch_once_t onceToken;
    //dispatch_once(&onceToken, ^{
        //[MTVerificationController sharedInstance];
    //});
    
    BOOL shouldPerformSegueWithIdentifier = YES;
    if ([identifier isEqualToString:MTSegueShowAddDocument]) {
        if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
            shouldPerformSegueWithIdentifier = [self shouldShowAddDocumentPopover];
            self.shouldShowAddDocumentPopover = NO;
            self.barButtonItemAddNewDocument.enabled = NO;
        }
    } else if ([identifier isEqualToString:MTSegueShowOpenDocument]) {
        shouldPerformSegueWithIdentifier = !self.isEditing;
    } else if ([identifier isEqualToString:MTSegueOpenInViewer]) {
        shouldPerformSegueWithIdentifier = !self.isEditing;
    }
    return shouldPerformSegueWithIdentifier;
}

#pragma mark - UIPopoverControllerDelegate

- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController {
    return [self.openDocumentPopoverController isEqual:popoverController] == NO;
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    self.shouldShowAddDocumentPopover = YES;
    [self.barButtonItemAddNewDocument setEnabled:YES];
}

#pragma mark - UIAdaptivePresentationControllerDelegate

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller {
    UIModalPresentationStyle style = UIModalPresentationOverCurrentContext;
    if ([controller isEqual:self.aboutPopoverPresentationController] || [controller isEqual:self.infoPopoverPresentationController] ||
        [controller isEqual:self.documentInformationPopoverPresentationController]) {
        style = UIModalPresentationNone;
    }
    return style;
}

#pragma mark - UIPopoverPresentationControllerDelegate

- (void)prepareForPopoverPresentation:(UIPopoverPresentationController *)popoverPresentationController {
    
}

- (BOOL)popoverPresentationControllerShouldDismissPopover:(UIPopoverPresentationController *)popoverPresentationController {
    return YES;
}

- (void)popoverPresentationControllerDidDismissPopover:(UIPopoverPresentationController *)popoverPresentationController {
    self.aboutViewControllerOnScreen = NO;
}

- (void)popoverPresentationController:(UIPopoverPresentationController *)popoverPresentationController
          willRepositionPopoverToRect:(inout CGRect *)rect
                               inView:(inout UIView **)view {
    
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    CGPoint touchPoint = [touch locationInView:self.collectionView];
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:touchPoint];
    BOOL shouldReceiveTouch = YES;
    if (indexPath && [gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]) {
        shouldReceiveTouch = NO;
    }
    return shouldReceiveTouch;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    return YES;
}

#pragma mark - UIDocumentInteractionControllerDelegate

- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *) controller {
    return self.navigationController;
}


#pragma mark - Delegates

- (void)viewControllerDidFinish:(id)sender {
    self.shouldShowAddDocumentPopover = YES;

    [self closeAndSave];
    [self dismissViewControllerAnimated:YES completion:^{
        [self.collectionView reloadData];
    }];
    
    [self.barButtonItemAddNewDocument setEnabled:YES];
}

- (void)viewControllerDidFinish:(id)sender animated:(BOOL)animated {
    [self dismissViewControllerAnimated:animated completion:^{ }];
    
    Class queryBuilderClass = [MADQueryViewController class];
    Class queryBuilderContainerClass = [MTQueryBuilderContainerController class];
    Class reportDesignerClass = [MADDesignerViewController class];
    Class reportViewerClass = [MADViewerController class];
    
    if ([sender isKindOfClass: queryBuilderClass] ||
        [sender isKindOfClass: queryBuilderContainerClass] ||
        [sender isKindOfClass: reportDesignerClass] ||
        [sender isKindOfClass: reportViewerClass]) {
        MTApplicationInstance *app = [AppDelegate app];
        __weak MADOpenFileViewController *weakself = self;
        [[app openDocument] regenThumbnailWithTraits:self.traitCollection];
        [app closeReportWithCompletionHandler:^(BOOL success) {
            [weakself reenable];
        }];
    }
    self.shouldShowAddDocumentPopover = YES;
    [self.barButtonItemAddNewDocument setEnabled:YES];
    [self.openDocumentPopoverController dismissPopoverAnimated:YES];
    
}

- (void)viewControllerDidCancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.openDocumentPopoverController dismissPopoverAnimated:YES];
    self.shouldShowAddDocumentPopover = YES;
    [self.barButtonItemAddNewDocument setEnabled:YES];
}

- (void)viewControllerDidRequestComposeEmail:(id)sender animated:(BOOL)animated {
    [self dismissViewControllerAnimated:animated completion:nil];

    if ([MFMailComposeViewController canSendMail]) {
        
        MFMailComposeViewController	*mFMailComposeViewController = [[MFMailComposeViewController alloc] init];
        mFMailComposeViewController.mailComposeDelegate = self;
        mFMailComposeViewController.toRecipients = @[@"admin@everydayapps.com"];
        mFMailComposeViewController.subject = @"MAD Designer";
        mFMailComposeViewController.navigationController.navigationBar.barTintColor = [UIColor tintColorAnalogous4];
        [self presentViewController: mFMailComposeViewController
                           animated: YES
                         completion: nil];
        
    } else {
        UIAlertController *alert = [UIAlertController alertNotConfiguredForEmail];
        [self presentViewController: alert
                           animated: YES
                         completion: nil];
    }
}

#pragma mark - Static functions

#pragma mark - Custom Initalization

- (void)addActionItemToToolbar:(BOOL)animated {
    if ([self.toolbarItems containsObject: self.barButtonItemAction] == NO) {
        NSMutableArray *toolbarButtons = self.toolbarItems.mutableCopy;
        [toolbarButtons insertObject: self.barButtonItemAction
                             atIndex: 1];
        [self setToolbarItems:toolbarButtons animated:animated];
    }
}

- (NSURL *)urlForDocumentCell:(MTCollectionViewCellDocument *)cellDocument {
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cellDocument];

    return [self documentForIndexPath:indexPath];

}

- (NSArray *)indexSetToIndexPaths:(NSIndexSet *)indexSet section:(NSUInteger)section {
    NSMutableArray *indexPaths = [[NSMutableArray alloc] initWithCapacity:indexSet.count];
    [indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        NSIndexPath *path = [NSIndexPath indexPathForItem:idx inSection:section];
        [indexPaths addObject:path];
    }];
    return indexPaths;
}

- (NSURL *)documentForIndexPath:(NSIndexPath *)indexPath {
    MADMetaData *metadata = [self.filesController objectAtIndexedSubscript:indexPath.item];
    return metadata.URL;
}

#pragma mark - UICollectionView Layout

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView
                        layout:(UICollectionViewLayout*)collectionViewLayout
        insetForSectionAtIndex:(NSInteger)section {
    
    return self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular ? UIEdgeInsetsMake(15.0000f, 15.0000f, 15.0000f, 15.0000f) :
                                                                                         UIEdgeInsetsMake(5.0000f, 5.0000f, 5.0000f, 5.0000f);
    
}

- (CGFloat)collectionView:(UICollectionView *)collectionView
                   layout:(UICollectionViewLayout*)collectionViewLayout
                    minimumLineSpacingForSectionAtIndex:(NSInteger)section {

    return self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular ? 30.0000f : 5.0000f;
    
}

- (CGFloat)collectionView:(UICollectionView *)collectionView
                   layout:(UICollectionViewLayout*)collectionViewLayout
                    minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    
    return self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular ? 30.0000f : 5.0000f;
    
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
                    referenceSizeForHeaderInSection:(NSInteger)section {
    
    return CGSizeZero;
    
}

#pragma mark - MFMailComposeViewController delegate protocol

- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {

    [NSError presentError: error
         onViewController: self
               completion:^(BOOL success) {
                   [self dismissViewControllerAnimated:YES completion:nil];
    }];

}

#pragma mark -  NSFileManager delegate protocol

- (BOOL)fileManager:(NSFileManager *)fileManager shouldMoveItemAtURL:(NSURL *)srcURL toURL:(NSURL *)dstURL {
    return YES;
}

- (BOOL)fileManager:(NSFileManager *)fileManager shouldProceedAfterError:(NSError *)error
    movingItemAtURL:(NSURL *)srcURL toURL:(NSURL *)dstURL {
    
    //Only allow the thumbnails to proceed to after an error.
    return [dstURL.pathExtension.lowercaseString isEqualToString:MTDocumentExtentionPoratableNetworkGraphic];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    return YES;
}

#pragma mark - UIMenuController required methods

- (BOOL)canBecomeFirstResponder {
    return NO;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    return NO;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {

    [((UICollectionView *)scrollView).collectionViewLayout invalidateLayout];

}

#pragma mark - UICollectionViewDelegate

- (BOOL)collectionView: (UICollectionView *)collectionView
      canPerformAction: (SEL)action
    forItemAtIndexPath: (NSIndexPath *)indexPath
            withSender: (id)sender {

    [super collectionView: collectionView
         canPerformAction: action
       forItemAtIndexPath: indexPath
               withSender: sender];
    
    return YES;

}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView
           viewForSupplementaryElementOfKind:(NSString *)kind
                                 atIndexPath:(NSIndexPath *)indexPath {
    
    MADOpenFileSectionHeaderView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind: kind
                                                        withReuseIdentifier: MADIdentifierOpenFileSectionHeader
                                                               forIndexPath: indexPath];
        
    switch (indexPath.section) {
            
        case 0:
            [headerView stopAnimating];
            headerView.sectionType = MACloudManagerSectionLocal;
            break;
            
        case 1:
            self.cloudActivityRunningDisplay ? [headerView startAnimating] : [headerView stopAnimating];
            headerView.sectionType = MACloudManagerSectionCloud;
            break;
            
        default:
            headerView.sectionType = MACloudManagerSectionLocal;
            break;
            
    }
    return headerView;
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath { }

- (void)collectionView:(UICollectionView *)collectionView willDisplaySupplementaryView:(UICollectionReusableView *)view forElementKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath { }

- (void)collectionView: (UICollectionView *)collectionView didEndDisplayingSupplementaryView:(UICollectionReusableView *)view
      forElementOfKind: (NSString *)elementKind
           atIndexPath: (NSIndexPath *)indexPath { }

- (void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    
    [self selectionsUpdated];
    MTCollectionViewCellDocument *cell = (MTCollectionViewCellDocument *)[collectionView cellForItemAtIndexPath:indexPath];
    [cell performSelectionAnimations];
    
    NSURL *fileUrl = [self documentForIndexPath:indexPath];
    NSURL *url = [MADocument thumbnailUrlForMadUrl:fileUrl];
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:url.path];
    if (image == nil) {
        image = [MTCollectionViewCellDocument defaultThumbnail];
    }
    cell.imagePreview.image = image;
}

- (void)collectionView:(UICollectionView *)collectionView didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    
    MTCollectionViewCellDocument *cell = (MTCollectionViewCellDocument *)[collectionView cellForItemAtIndexPath:indexPath];
    [cell performDeselectionAnimations];
    
    NSURL *fileUrl = [self documentForIndexPath:indexPath];
    NSURL *url = [MADocument thumbnailWithBorderUrlForMadUrl:fileUrl];
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:url.path];
    if (image == nil) {
        image = [MTCollectionViewCellDocument defaultThumbnail];
    }
    [cell normalizeTint];
    cell.imagePreview.image = image;

}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {

    MTCollectionViewCellDocument *cell = (MTCollectionViewCellDocument *)[collectionView cellForItemAtIndexPath:indexPath];
    [cell performSelectionAnimations];

    NSURL *fileUrl = [self documentForIndexPath:indexPath];
    if (self.isEditing == NO) {
        
        [collectionView deselectItemAtIndexPath:indexPath animated:YES];
        [cell.activityIndicator startAnimating];
        [self.collectionView setUserInteractionEnabled: NO];

        [self openFileWithUrl:fileUrl];

    } else {
        [collectionView selectItemAtIndexPath:indexPath
                                     animated:YES
                               scrollPosition:UICollectionViewScrollPositionCenteredVertically];
    }
    [self selectionsUpdated];

    
    NSURL *url = [MADocument thumbnailUrlForMadUrl:fileUrl];
    NSString *path = [url path];
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:path];
    if (image == nil) {
        image = [MTCollectionViewCellDocument defaultThumbnail];
    }
    cell.imagePreview.image = image;
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    [self selectionsUpdated];
    
    MTCollectionViewCellDocument *cell = (MTCollectionViewCellDocument *)[collectionView cellForItemAtIndexPath:indexPath];
    [cell performDeselectionAnimations];
    
    NSURL *fileUrl = [self documentForIndexPath:indexPath];
    NSURL *url = [MADocument thumbnailWithBorderUrlForMadUrl:fileUrl];
    NSString *path = [url path];
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:path];
    if (image == nil) {
        image = [MTCollectionViewCellDocument defaultThumbnail];
    }
    cell.imagePreview.image = image;
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender { }

- (BOOL)collectionView:(UICollectionView *)collectionView shouldDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

+ (NSOperationQueue *)queue {
    static NSOperationQueue *queue;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = [[NSOperationQueue alloc] init];
    });
    
    return queue;
}


- (void)openFileWithUrl:(NSURL *)url {
    MADocument *document = [[MADocument alloc] initWithFileURL:url];
    [AppDelegate app].fileManager.openDocument = document;
    
    [document openWithCompletionHandler:^(BOOL success) {
        
        if (success) {
            
            [AppDelegate app].reportState = MTReportStateOpen;
            
            if ([MTApplicationInstance isMadViewer]) {
                
                MTApplicationInstance *app = [AppDelegate app];
                [[app openDocument] activeDocumentModel];
                [self performSegueWithIdentifier: MTSegueOpenInViewer sender: self];
                
            } else if ([MTApplicationInstance isMadDesigner]) {
                
                [[AppDelegate app].openDocument activeDocumentModel];
                NSString *storyboardName = [MTApplicationInstance storyboardName];
                UIStoryboard *storyboard = [UIStoryboard storyboardWithName:storyboardName bundle:nil];
                UITabBarController *tabBarController = [storyboard instantiateViewControllerWithIdentifier:@"MADIdentifierStoryboardMainTabBarController"];
                
                tabBarController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
                tabBarController.modalPresentationStyle = UIModalPresentationOverFullScreen;
                
                UINavigationController *navController = (UINavigationController *)tabBarController.viewControllers[0];
                UINavigationController *navController2 = (UINavigationController *)tabBarController.viewControllers[1];
                UINavigationController *navController3 = (UINavigationController *)tabBarController.viewControllers[2];
                
                MTQueryBuilderContainerController * queryBuilderViewController = (MTQueryBuilderContainerController *)navController.topViewController;
                queryBuilderViewController.viewControllerDelegate = self;
                queryBuilderViewController.document = document;
                
                MADDesignerViewController *reportDesignerViewController = (MADDesignerViewController *)navController2.topViewController;
                reportDesignerViewController.delegate = self;
                
                MADViewerController *reportViewerViewController = (MADViewerController *)navController3.topViewController;
                reportViewerViewController.viewControllerDelegate = self ;
                
                reportDesignerViewController.document = [AppDelegate app].openDocument;
                reportViewerViewController.document = [AppDelegate app].openDocument;
                
                [self presentViewController:tabBarController animated:YES completion:nil];
                
            }
            
        }
        
        [self reenable];
        
    }];
}

#pragma mark - UICollectionViewFlowLayoutDelegate

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    MADMetaData *metadata;
    if (indexPath.section == 0) {
        metadata = [self.filesController objectAtIndexedSubscript: indexPath.item];
    } else {
        metadata = [self.filesController objectAtIndexedSubscript: indexPath.item];
    }
    NSString *filename = [MADocument fileNameForMadUrl:metadata.URL];
    NSString *size = [metadata fileSystemSizeMB];
    
    NSDictionary *attributesCaption = [MTCollectionViewCellDocument attributesCaption];
    NSDictionary *attributesCaption2 = [MTCollectionViewCellDocument attributesCaption];

    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString: filename
                                                                           attributes: attributesCaption];

    CGFloat sizeLabelHeight = [self heightForAttributedString: attributedString
                                           contentScaleFactor: self.collectionView.contentScaleFactor
                                                         font: [MTCollectionViewCellDocument CaptionFont]];
    
    NSAttributedString *attributedStringSub = [[NSAttributedString alloc] initWithString: size
                                                                              attributes: attributesCaption2];
    CGFloat sizeLabelSubHeight = [self heightForAttributedString: attributedStringSub
                                              contentScaleFactor: self.collectionView.contentScaleFactor
                                                            font: [MTCollectionViewCellDocument CaptionFont2]];
    return CGSizeMake(140.0000f, 128.0000f /*+ ceil(self.testLabel.frame.size.height)*/ + ceilf(sizeLabelHeight) + ceilf(sizeLabelSubHeight) + 20.0000f);
}

- (CGFloat)heightForAttributedString:(NSAttributedString *)attributedString
                  contentScaleFactor:(CGFloat)contentScaleFactor
                                font:(UIFont *)font {
    self.testLabel.frame = rectCellLabel();
    self.testLabel.font = font;
    self.testLabel.attributedText = attributedString;
    self.testLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.testLabel.contentScaleFactor = contentScaleFactor;
    [self.testLabel sizeToFit];
    return self.testLabel.frame.size.height;
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section {
    
    switch (section) {
        
        case 0:
            return self.filesController ? self.filesController.count : 0;
            break;
            
        default:
            return 0;
            break;
    }
    
}

- (NSUInteger)dataSourceCount {
    return self.filesController ? self.filesController.count : 0;
}

- (UICollectionViewCell *)collectionView: (UICollectionView *)collectionView
                  cellForItemAtIndexPath: (NSIndexPath *)indexPath {

    MTCollectionViewCellDocument *cell = [collectionView dequeueReusableCellWithReuseIdentifier: MTCollectionViewCellDocumentIdentifier
                                                                                   forIndexPath: indexPath];
    MADMetaData *metadata = [self.filesController objectAtIndexedSubscript:indexPath.item];
    
    NSURL *url = metadata.URL;
    
    if (cell.delegate == nil) {
        cell.delegate =  self;
    }
    
    NSString *filename = [MADocument fileNameForMadUrl:url];
    cell.text = filename;
    cell.labelTitle.text = filename;
    
    BOOL notDownloaded = [metadata.ubiquitousItemDownloadingStatus isEqualToString: NSMetadataUbiquitousItemDownloadingStatusNotDownloaded];
    cell.progressViewDownload.hidden = !metadata.ubiquitousItemIsDownloading;
    cell.progressViewUpload.hidden = YES;//!metadata.ubiquitousItemIsUploading;
    
    cell.labelTitleSub.text = (notDownloaded ? NSLocalizedString(@"Not Downloaded", @"Not Downloaded") : [metadata fileSystemSizeMB]);

    if (metadata.ubiquitousItemIsUploading) {
        [cell.progressViewUpload setProgress:metadata.ubiquitousItemPercentUploaded
                                    animated:YES];
    } else {
        [cell.progressViewUpload setProgress:0.0000f animated:YES];
    }
        
    if (metadata.ubiquitousItemIsDownloading) {
        [cell.progressViewDownload setProgress:metadata.ubiquitousItemPercentDownloaded
                                      animated:YES];
    } else {
        [cell.progressViewDownload setProgress:0.0000f animated:YES];
    }
    
    cell.imageCloudIndicator.image = notDownloaded && metadata.isUbiquitous ?
                                                [UIImage imageNamed:@"MADImageToolbarCloudDownload"] :
                                                nil;
    
    [cell.labelTitle layoutIfNeeded];
    [cell loadPreviewImageForUrl:url];
    
    if (self.isEditing) {
        [cell startWobble];
    }
    
    if (self.isSavingActivityIndicatorVisible == NO) {

        [cell.activityIndicator stopAnimating];

    } else {
        
        if ([[AppDelegate app].fileManager.openUrl.lastPathComponent caseInsensitiveCompare: url.lastPathComponent] == NSOrderedSame) {
            [cell.activityIndicator startAnimating];
        } else {
            [cell.activityIndicator stopAnimating];
        }
    
    }

    [cell normalizeTint];
    
    return cell;
}

#pragma mark - Misc

- (NSArray *)defaultPassthoughViews {
    return @[self.navigationController.navigationBar, self.navigationController.toolbar];
}

#pragma mark Edit Mode

- (void)activateEditMode:(UILongPressGestureRecognizer *)sender {

    if ([sender state] == UIGestureRecognizerStateBegan) {

        if (self.isEditing == NO) {
            [self edit:self];
        }
        
        NSIndexPath *indexPath = [self.collectionView indexPathForCell:((MTCollectionViewCellDocument *)sender.view)];
        [self.collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
        
        [self selectionsUpdated];
        
        MTCollectionViewCellDocument *cell = (MTCollectionViewCellDocument *)[self.collectionView cellForItemAtIndexPath:indexPath];
        [cell performSelectionAnimations];
        [cell normalizeTint];
    }

}

- (void)handleDidTapCollectionView:(UIGestureRecognizer *)sender {

    [self.searchBar resignFirstResponder];
    if (self.isEditing) {
        [self edit:self];
    }
}

#pragma mark UI Helpers

- (BOOL)dismissAllPopovers {

    BOOL result = NO;
    if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad) {

        NSMutableArray *allpopovers = [[NSMutableArray alloc] initWithCapacity:3];
        if (self.openDocumentPopoverController != nil)
            [allpopovers addObject:self.openDocumentPopoverController];
        if (self.licensingPopoverController != nil)
            [allpopovers addObject:self.licensingPopoverController];
        if (self.aboutPopoverController != nil)
            [allpopovers addObject:self.aboutPopoverController];
        
        for (UIPopoverController *popoverController in allpopovers) {
            if ([popoverController isPopoverVisible]) {
                [popoverController dismissPopoverAnimated:YES];
                result = YES;
            }
        }

    }
    return result;

}

- (void)reenable {
    self.collectionView.userInteractionEnabled = YES;
    self.savingActivityIndicatorVisible = NO;
    NSUInteger numberOfItemsInSection = [self.collectionView numberOfItemsInSection:0];
    for (NSInteger i=0; i<numberOfItemsInSection; i++) {
        NSIndexPath *path = [NSIndexPath indexPathForItem:i inSection:0];
        MTCollectionViewCellDocument *cell = (MTCollectionViewCellDocument *)[self.collectionView cellForItemAtIndexPath:path];
        [cell.activityIndicator stopAnimating];
    }
    [self reenableDataWithSearch];
}

- (void)displaySavingReportActivityIndicator {
    [self setSavingActivityIndicatorVisible:YES];
    
    NSUInteger numberOfItemsInSection = [self.collectionView numberOfItemsInSection:0];
    for (NSInteger i=0; i<numberOfItemsInSection; i++) {
        NSIndexPath *path = [NSIndexPath indexPathForItem:i inSection:0];
        NSURL *visibleUrl = [self documentForIndexPath:path];

        BOOL animate = [[AppDelegate app].fileManager.openUrl.lastPathComponent caseInsensitiveCompare:visibleUrl.lastPathComponent] == NSOrderedSame;
        if (animate) {
            MTCollectionViewCellDocument *cell = (MTCollectionViewCellDocument *)[self.collectionView cellForItemAtIndexPath:path];
            if (cell != nil) {
                [cell performDeselectionAnimations];
                [cell.activityIndicator startAnimating];
            }
        }
    }
    [self.collectionView setUserInteractionEnabled: NO];
}

- (void)loadCollectionViewPreviewImageForIndexPath:(NSIndexPath *)indexPath {
    NSURL *fileUrl = [self documentForIndexPath:indexPath];
    __weak UICollectionView *collectionView = self.collectionView;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        dispatch_sync(dispatch_get_main_queue(), ^(void) {
            
            MTCollectionViewCellDocument *visibleCell = (MTCollectionViewCellDocument *)[collectionView cellForItemAtIndexPath:indexPath];
            NSURL *url = [MADocument thumbnailWithBorderUrlForMadUrl:fileUrl];
            NSString *path = [url path];
            UIImage *image = [[UIImage alloc] initWithContentsOfFile:path];
            if (image) {
                visibleCell.imagePreview.image = image;
            } else {
                UIImage *defaultThumbnail = [MTCollectionViewCellDocument defaultThumbnail];
                visibleCell.imagePreview.image = defaultThumbnail;
            }
            [visibleCell setNeedsLayout];
            
        });
    });
}

- (NSUInteger)numberOfItemsSelected {
    NSArray *data = [self.collectionView indexPathsForSelectedItems];
    return data.count;
}

- (void)selectionsUpdated {
    NSUInteger selectedCellCounter = [self numberOfItemsSelected];
    switch (selectedCellCounter) {
        case 0:
            self.barButtonItemInformationDocument.enabled = NO;
            self.barButtonItemTrash.enabled = NO;
            self.barButtonItemDuplicate.enabled = NO;
            self.barButtonItemAction.enabled = NO;
            break;
        case 1:
            self.barButtonItemInformationDocument.enabled = YES;
            self.barButtonItemTrash.enabled = YES;
            self.barButtonItemDuplicate.enabled = YES;
            self.barButtonItemAction.enabled = YES;
            break;
        default:
            self.barButtonItemInformationDocument.enabled = YES;
            self.barButtonItemTrash.enabled = YES;
            self.barButtonItemDuplicate.enabled = YES;
            self.barButtonItemAction.enabled = NO;
            break;
    }
}

#pragma mark - UIDocumentPickerDelegate

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentAtURL:(NSURL *)url {
    
    [controller removeFromParentViewController];
}

- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller {
    [controller removeFromParentViewController];
}

#pragma mark - Actions

- (IBAction)addDocument:(id)sender {

    UIStoryboard *storyboard = [UIStoryboard storyboardWithName: @"MADStoryboardNewDocument"
                                                         bundle: [NSBundle mainBundle]];
    MTNavigationController *navControl = [storyboard instantiateViewControllerWithIdentifier:@"MADIdentifierOpenDocumentStart"];
    navControl.modalPresentationStyle = UIModalPresentationFormSheet;
    
    MTDatabaseDriverSelectorViewController *vc = (MTDatabaseDriverSelectorViewController *)navControl.topViewController;
    vc.delegate = self;
    self.definesPresentationContext = YES;
    self.modalTransitionStyle = UIModalTransitionStyleCoverVertical;

    UIPresentationController *pc = navControl.presentationController;
    pc.presentedView.backgroundColor = [UIColor whiteColor];
    [self showViewController:navControl sender:self];
}

- (IBAction)cancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.barButtonItemAddNewDocument setEnabled:YES];
}

- (IBAction)search:(id)sender {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    if (self.searchBar.isHidden) {
        //        self.searchBar.showsCancelButton = YES;
        
        //[self.searchBar sizeToFit];
        self.searchBar.hidden = NO;
        self.searchBar.showsCancelButton = NO;
        self.searchBar.alpha = 0.0000f;
        self.labelMadDesigner.alpha = 1.0000f;
        //[self.navigationItem setRightBarButtonItem:nil animated:YES];
        self.navigationItem.leftBarButtonItem.enabled = NO;
        __weak MADOpenFileViewController *weakself = self;
        
        self.searchBar.searchBarStyle = UISearchBarStyleMinimal;
        [self.searchBar sizeToFit];
        
        
        UIView *searchViewHolder = [[UIView alloc] initWithFrame:self.searchBar.bounds];
        self.searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        searchViewHolder.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [searchViewHolder addSubview:self.searchBar];
        [searchViewHolder sizeToFit];
        self.searchBar.translucent = NO;
        //self.searchBar.
        self.searchBar.backgroundColor = [UIColor clearColor];
        self.searchBar.barTintColor = [UIColor whiteColor];
        self.searchBar.tintColor = [UIColor whiteColor];
        
        
        /*
         for (UIView *subview in self.searchBar.subviews) {
         for (id subview2 in subview.subviews) {
         if ([subview2 isKindOfClass:[UITextField class]]) {
         ((UITextField *)subview2).textColor = [UIColor whiteColor];
         ((UITextField *)subview2).tintColor = [UIColor whiteColor];
         ((UIImageView *)((UITextField *)subview2).leftView).image = [((UIImageView *)((UITextField *)subview2).leftView).image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
         ((UIImageView *)((UITextField *)subview2).leftView).tintColor = [UIColor whiteColor];
         for (UIView *view in ((UITextField *)subview2).subviews) {
         if ([view isKindOfClass:[UIButton class]]) {
         
         
         UIImage *image = [((UIButton *)view).imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
         ((UIButton *)view).tintColor = [UIColor whiteColor];
         [((UIButton *)view) setImage:image forState:UIControlStateNormal];
         }
         }
         ((UIImageView *)((UITextField *)subview2).rightView).image = [((UIImageView *)((UITextField *)subview2).rightView).image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
         ((UIImageView *)((UITextField *)subview2).rightView).tintColor = [UIColor whiteColor];
         ((UITextField *)subview2).rightView.tintColor = [UIColor whiteColor];
         }
         }
         }*/
        
        
        //        self.navigationController.navigationBar.
        [UIView transitionWithView:self.navigationItem.titleView
                          duration:0.2000f
                           options:UIViewAnimationOptionCurveEaseOut animations:^{
                               weakself.searchBar.alpha = 1.0000f;
                               weakself.labelMadDesigner.alpha = 0.0000f;
                               weakself.navigationItem.titleView = searchViewHolder;
                           } completion:^(BOOL finished) {
                               if (weakself.searchBar.isFirstResponder == NO) {
                                   [weakself.searchBar becomeFirstResponder];
                               }
                           }];
        
    } else {
        if (self.searchBar.text.length > 0) {
            self.searchBar.text = @"";
            
            //[[MACloudManager sharedManager] reloadCacheLocal:self.searchBar.text];
            //[[MACloudManager sharedManager] reloadCacheCloud:self.searchBar.text];

            //[self animateUpdates];
            //[self.collectionView reloadData];
        }
        self.searchBar.hidden = YES;
        self.searchBar.alpha = 0.1000f;
        self.labelMadDesigner.alpha = 0.0000f;
        //[self.navigationItem setRightBarButtonItem:self.barButtonItemSearch animated:YES];
        self.navigationItem.leftBarButtonItem.enabled = YES;
        __weak MADOpenFileViewController *weakself = self;
        [UIView transitionWithView:self.navigationItem.titleView
                          duration:0.2000f
                           options:UIViewAnimationOptionCurveEaseOut animations:^{
                               weakself.searchBar.alpha = 0.0000f;
                               weakself.labelMadDesigner.alpha = 1.0000f;
                               weakself.navigationItem.titleView = weakself.labelMadDesigner;
                           } completion:nil];
        
    }
}

- (IBAction)edit:(id)sender {
    
    BOOL startEdit = !self.isEditing;
    [self setEditing:startEdit animated:YES];
    
    if (startEdit) {
        self.editing = YES;
        self.barButtonItemLicensing.enabled = NO;
        self.barButtonItemAddNewDocument.enabled = NO;
        self.barButtonItemAbout.enabled = NO;
        self.barButtonItemInformation.enabled = NO;
        self.collectionView.allowsMultipleSelection = YES;
        
        NSUInteger numberOfItemsInSection = [self.collectionView numberOfItemsInSection:0];
        for (NSInteger i=0; i<numberOfItemsInSection; i++) {
            NSIndexPath *path = [NSIndexPath indexPathForItem:i inSection:0];
            UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:path];
            [cell startWobble];
        }
        
        NSMutableArray *items = [self.toolbarItems mutableCopy];
        [items removeObject:self.barButtonItemEdit];
        [items addObject:self.barButtonItemEditDone];
        [self setToolbarItems:items animated:YES];
        [self.navigationItem setRightBarButtonItem: nil
                                          animated: YES];
        
    } else {
        [self done:sender];
    }
}

- (void)done:(id)sender {
    self.editing = NO;
    self.barButtonItemLicensing.enabled = YES;
    self.barButtonItemAddNewDocument.enabled = YES;
    self.barButtonItemAbout.enabled = YES;
    self.barButtonItemInformation.enabled = YES;
    
    self.barButtonItemTrash.enabled = NO;
    self.barButtonItemInformationDocument.enabled = NO;
    self.barButtonItemDuplicate.enabled = NO;
    self.barButtonItemAction.enabled = NO;
    
    self.collectionView.allowsMultipleSelection = NO;
    
    [self.navigationItem setRightBarButtonItem:self.barButtonItemSearch animated:YES];
    
    NSMutableArray *items = [self.toolbarItems mutableCopy];
    [items removeObject:self.barButtonItemEditDone];
    [items addObject:self.barButtonItemEdit];
    [self setToolbarItems:items animated:YES];
    
    for (NSInteger i=0; i<[self.collectionView numberOfItemsInSection:0]; i++) {
        NSIndexPath *path = [NSIndexPath indexPathForItem:i inSection:0];
        [self.collectionView deselectItemAtIndexPath:path animated:YES];
        MTCollectionViewCellDocument *cell = (MTCollectionViewCellDocument *)[self.collectionView cellForItemAtIndexPath:path];
        [cell stopWobble];
        [cell performDeselectionAnimations];
        
        NSURL *fileUrl = [self documentForIndexPath:path];
        NSURL *url = [MADocument thumbnailWithBorderUrlForMadUrl:fileUrl];
        UIImage *image = [[UIImage alloc] initWithContentsOfFile:url.path];
        if (image == nil) {
            image = [MTCollectionViewCellDocument defaultThumbnail];
        }
        cell.imagePreview.image = image;
    }
}

- (IBAction)download:(id)sender {
    NSArray *documentTypes = @[MADUtiType];
    UIDocumentPickerViewController *vc = [[UIDocumentPickerViewController alloc] initWithDocumentTypes: documentTypes
                                                                                                inMode: UIDocumentPickerModeImport];
    vc.delegate = self;
    [self presentViewController:vc animated:YES completion:^{}];
}

- (void)cut:(id)sender {
    [super cut:sender];
}

- (void)copy:(id)sender {
    [super copy:sender];
}

// FIXME: Not updated with file coordnation... but likely unused
- (void)paste:(id)sender {
    NSURL *url = [[UIPasteboard generalPasteboard] URL];
    NSData *data = [[NSData alloc] initWithContentsOfURL:url];
    NSFileWrapper *fileWrapper = [[NSFileWrapper alloc] initWithSerializedRepresentation:data];
    NSURL *destinationUrl = [url uniqueUrl];
    
    NSFileWrapperWritingOptions writingOptions = NSFileWrapperWritingAtomic | NSFileWrapperWritingWithNameUpdating;
    NSError* fileWrittingError = nil;
    [fileWrapper writeToURL:destinationUrl options:writingOptions originalContentsURL:url error:&fileWrittingError];
    if (fileWrittingError) {
        fileWrittingError = nil;
        [fileWrapper writeToURL:destinationUrl options:writingOptions originalContentsURL:url error:&fileWrittingError];
    }
    [self.collectionView reloadData];
    [self selectionsUpdated];
}

- (IBAction)info:(id)sender {

    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MADStoryboardInformationTable" bundle:[NSBundle mainBundle]];
    UINavigationController *infoViewController = [storyboard instantiateViewControllerWithIdentifier: @"MADIdentifierInformationNavigationController"];
    infoViewController.modalPresentationStyle = UIModalPresentationPageSheet;
    infoViewController.preferredContentSize = CGSizeMake(320.0000f, 480.0000f);
    UIPopoverPresentationController *ppc = infoViewController.popoverPresentationController;
    ppc.passthroughViews = [ppc.passthroughViews arrayByAddingObjectsFromArray:[self defaultPassthoughViews]];
    
    ppc.backgroundColor = [UIColor clearColor];
    ppc.delegate = self;
    ppc.barButtonItem = sender;
    self.infoPopoverPresentationController = ppc;
    
    [self showViewController:infoViewController sender:self];

}

- (IBAction)about:(id)sender {
    
    if (self.aboutViewControllerOnScreen) {
        self.aboutViewControllerOnScreen = NO;
        [self dismissViewControllerAnimated:YES completion:^{
            
        }];
    } else {
        self.aboutViewControllerOnScreen = YES;
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MADStoryboardAboutTable" bundle:[NSBundle mainBundle]];
        UITableViewController *aboutViewController = [storyboard instantiateViewControllerWithIdentifier: @"MADIdentifierAboutViewController"];
        
        aboutViewController.modalPresentationStyle = UIModalPresentationPopover;
        UIPopoverPresentationController *ppc = aboutViewController.popoverPresentationController;
        ppc.passthroughViews = [ppc.passthroughViews arrayByAddingObjectsFromArray:[self defaultPassthoughViews]];
        
        ppc.backgroundColor = [UIColor clearColor];
        ppc.delegate = self;
        ppc.barButtonItem = sender;
        self.aboutPopoverPresentationController = ppc;
        
        
        [self showViewController:aboutViewController sender:self];

    }
}

- (void)showViewController:(UIViewController *)vc sender:(id)sender {
    if (self.presentedViewController != nil) {
        __weak MADOpenFileViewController *weakself = self;
        [self dismissViewControllerAnimated: YES completion:^{
            [weakself presentViewController: vc
                                   animated: YES
                                 completion: nil];
        }];
    } else {
        [self presentViewController: vc
                           animated: YES
                         completion: nil];
    }
}

- (IBAction)activity:(id)sender {
    NSMutableArray *wrappedUrls = [[NSMutableArray alloc] initWithCapacity:[self dataSourceCount]];
    for (NSIndexPath *selectedCellLocation in self.collectionView.indexPathsForSelectedItems) {
        NSURL *fileUrl = [self documentForIndexPath:selectedCellLocation];
        [wrappedUrls addObject:fileUrl];
    }
    NSUInteger numberOfItemsInSection = [self.collectionView numberOfItemsInSection:0];
    for (NSInteger i=0; i<numberOfItemsInSection; i++) {
        NSIndexPath *path = [NSIndexPath indexPathForItem:i inSection:0];
        MTCollectionViewCellDocument *documentCell = (MTCollectionViewCellDocument *)[self.collectionView cellForItemAtIndexPath:path];
        if (documentCell != nil) {
            [documentCell normalizeTint];
        }
    }
    
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:wrappedUrls applicationActivities:@[]];
    [activityViewController setExcludedActivityTypes:@[UIActivityTypeAssignToContact, UIActivityTypePostToFacebook, UIActivityTypePostToFlickr, UIActivityTypePostToTwitter, UIActivityTypePostToVimeo]];
    
    
    MADOpenFileViewController *weakSelf = self;
    
    [activityViewController setCompletionWithItemsHandler: ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
        NSUInteger numberOfItemsInSection = [self.collectionView numberOfItemsInSection:0];
        for (NSInteger i=0; i<numberOfItemsInSection; i++) {
            NSIndexPath *path = [NSIndexPath indexPathForItem:i inSection:0];
            MTCollectionViewCellDocument *documentCell = (MTCollectionViewCellDocument *)[weakSelf.collectionView cellForItemAtIndexPath:path];
            if (documentCell != nil) {
                [documentCell normalizeTint];
            }
        }
    }];
    
    if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        if (self.popoverControllerActivity == nil || self.popoverControllerActivity.isPopoverVisible == NO) {
            UIPopoverController *popoverController = [[UIPopoverController alloc] initWithContentViewController:activityViewController];
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

- (IBAction)documentInformation:(id)sender {
    
    MADMetaData *metadata = nil;
    NSArray *selectedItems = [self.collectionView indexPathsForSelectedItems];
    NSIndexPath *indexPath;
    NSMutableArray *metadataItems = [[NSMutableArray alloc] initWithCapacity:selectedItems.count];
    for (indexPath in selectedItems) {
        metadata = [self.filesController objectAtIndexedSubscript:indexPath.item];
        [metadataItems addObject:metadata];
    }
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MADStoryboardDocumentInformation" bundle:[NSBundle mainBundle]];
    MADDocumentInformationTableViewController *aboutViewController = [storyboard instantiateViewControllerWithIdentifier: @"MADIdentifierDocumentInformationTableViewController"];
    
    aboutViewController.modalPresentationStyle = UIModalPresentationPopover;
    UIPopoverPresentationController *ppc = aboutViewController.popoverPresentationController;
    ppc.passthroughViews = [ppc.passthroughViews arrayByAddingObjectsFromArray:[self defaultPassthoughViews]];
    
    ppc.backgroundColor = [UIColor clearColor];
    ppc.delegate = self;
    ppc.barButtonItem = sender;
    self.documentInformationPopoverPresentationController = ppc;
    
    aboutViewController.metadataItems = metadataItems;
    [self showViewController:aboutViewController sender:self];
    
    [self done:sender];
}

- (IBAction)delete:(id)sender {
    NSArray *selectedItems = self.collectionView.indexPathsForSelectedItems;
    UIAlertController *alertController = [UIAlertController deleteItems:selectedItems.count
                                                                confirm:^(UIAlertAction *action) {
                                                                    for (NSIndexPath *selectedItem in selectedItems) {
                                                                        MADMetaData *metaData = [self.filesController objectAtIndexedSubscript:selectedItem.item];
                                                                        [self.filesController removeFileInfo:metaData];
                                                                    }
    } cancel:^(UIAlertAction *action) {
        
    }];
    
    [self presentViewController:alertController animated:YES completion:NULL];
    
}

- (void)duplicate:(id)sender {
    for (NSIndexPath *selectedItem in self.collectionView.indexPathsForSelectedItems) {
        MADMetaData *metaData = [self.filesController objectAtIndexedSubscript:selectedItem.item];
        [self.filesController duplicateFileInfo:metaData];
    }
}

- (void)rename:(id)sender {
    
    MTCollectionViewCellDocument *cellDocument;
    if ([sender isKindOfClass:[MTCollectionViewCellDocument class]]) {
        cellDocument = sender;
    } else if ([sender isKindOfClass:[UITapGestureRecognizer class]]) {
        UIView *contentView = ((UITapGestureRecognizer *)sender).view.superview;
        cellDocument = (MTCollectionViewCellDocument *)contentView.superview;
    }
    
    NSAssert(cellDocument != nil, @"Null cell at %s.", __PRETTY_FUNCTION__);

    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cellDocument];
    MADMetaData *metaData = [self.filesController objectAtIndexedSubscript:indexPath.item];
    
    UIAlertController *alert = [UIAlertController renameDocument:^(UITextField *textField) {
        
        textField.text = cellDocument.labelTitle.text;
        textField.clearButtonMode = UITextFieldViewModeAlways;
        textField.delegate = self;
        
    } confirm:^(UIAlertAction *action, NSString *text) {
        
        NSString *name = [self renameFilter:text];
        if (name.length > 0) {
            NSURL *newUrl = [metaData.URL.URLByDeletingLastPathComponent URLByAppendingPathComponent:name isDirectory:NO];
            if ([[NSFileManager defaultManager] fileExistsAtPath:newUrl.path] == NO && [[NSFileManager defaultManager] isUbiquitousItemAtURL:newUrl] == NO) {
                [self.filesController renameFileInfo:metaData toName:text];
            } else {
                UIAlertController *alert = [UIAlertController errorFileExist];
                [self showViewController:alert sender:self];
            }
        } else {
            UIAlertController *alert = [UIAlertController errorValidationFilename];
            [self showViewController:alert sender:self];
        }
        
    } cancel:nil];
    
    [self showViewController:alert sender:self];
    
}

- (void)setRightBarButtonItemActivityIndicatorVisible:(BOOL)rightBarButtonItemActivityIndicatorVisible
                                             animated:(BOOL)animated {
    
    if (self.rightBarButtonItemActivityIndicatorVisible != rightBarButtonItemActivityIndicatorVisible) {

        UIBarButtonItem *barButtonItem;
        if ((self.rightBarButtonItemActivityIndicatorVisible = rightBarButtonItemActivityIndicatorVisible)) {
            
            self.rightBarButtonItemHolderWhileActivity = self.navigationItem.rightBarButtonItem;
            barButtonItem = [[MADBarButtonItem alloc] initWithBarButtonSystemItem: MADBarButtonSystemItemActivity
                                                                           target: nil
                                                                           action: nil];
            
        } else {
            
            barButtonItem = (UIBarButtonItem *)self.rightBarButtonItemHolderWhileActivity;
            
        }
        [self.navigationItem setRightBarButtonItem:barButtonItem animated:animated];
    }
}

- (NSString *)renameFilter:(NSString *)text {

    NSMutableCharacterSet *characterSet = [[NSMutableCharacterSet alloc] init];
    [characterSet formUnionWithCharacterSet:[NSCharacterSet alphanumericCharacterSet]];
    [characterSet formUnionWithCharacterSet:[NSCharacterSet whitespaceCharacterSet]];
    NSCharacterSet *invertedSet = characterSet.invertedSet;
    NSArray *components = [text componentsSeparatedByCharactersInSet:invertedSet];
    return [components componentsJoinedByString:@""];
    
}

- (void)fileExistError {
    UIAlertController *alert = [UIAlertController errorFileExist];
    [self showViewController:alert sender:self];
}

- (void)email:(MTCollectionViewCellDocument *)cell {
    
    if ([MFMailComposeViewController canSendMail] == NO) {
        
        UIAlertController *alert = [UIAlertController alertNotConfiguredForEmail];
        [self showViewController:alert sender:self];
        
    } else {
        
        NSURL *fileToAttach = [self urlForDocumentCell:cell];
        
        MADocument *documentReport = [[MADocument alloc] initWithFileURL:fileToAttach];
        
        if ([documentReport documentState] != UIDocumentStateClosed) {
            __weak MADOpenFileViewController *weakself = self;
            [documentReport closeWithCompletionHandler:^(BOOL success) {
                if (success) {
                    [weakself email:cell];
                }
            }];
            
        } else {
            
            __weak MADOpenFileViewController *weakself = self;
            NSURL *fileUrl = [self urlForDocumentCell:cell];
            NSData *data = [NSData dataWithContentsOfURL:fileUrl];
            
            NSString *messageStringStart = NSLocalizedString(@"The attached document can be opened with MAD Viewer.",
                                                             @"The attached document can be opened with MAD Viewer.");
            NSMutableString *messageBody = [[NSMutableString alloc] initWithString:messageStringStart];
            
            [messageBody appendString:@"\n\nhttp://www.everydayapps.com/\n\n"];
            
            MFMailComposeViewController	*mailComposer = [[MFMailComposeViewController alloc] init];
            mailComposer.mailComposeDelegate = self;
            NSString *formatString = NSLocalizedString(@"MAD Document %@.", @"MAD Document %@.");
            mailComposer.subject = [NSString stringWithFormat:formatString, documentReport.fileName];
            [mailComposer setMessageBody:messageBody isHTML:NO];
            NSString *name = [NSString stringWithFormat:@"%@.%@", documentReport.fileName, MADFileExtentionMobleApplicationDocument];
            [mailComposer addAttachmentData:data mimeType:MADMimeType fileName:name];
            mailComposer.navigationController.navigationBar.barTintColor = [UIColor tintColorAnalogous4];
            
            if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
                mailComposer.modalPresentationStyle = UIModalPresentationFormSheet;
                mailComposer.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
                mailComposer.providesPresentationContextTransitionStyle = YES;
                mailComposer.modalInPopover = NO;
            }
            [weakself showViewController:mailComposer sender:weakself];
            
        }
    }

}

#pragma mark - MADFilesControllerDelegate

- (void)filesControllerWillChangeContent:(MADFilesController *)filesController {
    [self.batchInserts removeAllObjects];
    [self.batchRemoves removeAllObjects];
    [self.batchUpdates removeAllObjects];
}

- (void)filesController:(MADFilesController *)filesController didInsertListInfo:(MADFileInfo *)listInfo atIndex:(NSInteger)index {
    NSNumber *i = @(index);
    MTPair *pair = [[MTPair alloc] initWithLeft:listInfo andRight:i];
    [self.batchInserts addObject:pair];
}

- (void)filesController:(MADFilesController *)filesController didRemoveListInfo:(MADFileInfo *)listInfo atIndex:(NSInteger)index {
    NSNumber *i = @(index);
    MTPair *pair = [[MTPair alloc] initWithLeft:listInfo andRight:i];
    [self.batchRemoves addObject:pair];
}

- (void)filesController:(MADFilesController *)filesController didUpdateListInfo:(MADFileInfo *)listInfo atIndex:(NSInteger)index {
    NSNumber *i = @(index);
    MTPair *pair = [[MTPair alloc] initWithLeft:listInfo andRight:i];
    [self.batchUpdates addObject:pair];
}

- (void)filesControllerDidChangeContent:(MADFilesController *)filesController completion:(void (^)(BOOL, NSError *))completion {
    
    NSIndexPath *path;
    MTPair *pair;
    NSMutableArray *inserts = [[NSMutableArray alloc] initWithCapacity:self.batchInserts.count];
    for (pair in self.batchInserts) {
        path = [NSIndexPath indexPathForItem:((NSNumber *)pair.right).integerValue
                                   inSection:0];
        [inserts addObject:path];
    }

    NSMutableArray *removes = [[NSMutableArray alloc] initWithCapacity:self.batchRemoves.count];
    for (pair in self.batchRemoves) {
        path = [NSIndexPath indexPathForItem:((NSNumber *)pair.right).integerValue
                                   inSection:0];
        [removes addObject:path];
    }

    NSMutableArray *updates = [[NSMutableArray alloc] initWithCapacity:self.batchUpdates.count];
    for (pair in self.batchUpdates) {
        path = [NSIndexPath indexPathForItem:((NSNumber *)pair.right).integerValue
                                   inSection:0];
        [updates addObject:path];
    }

    [self.collectionView performBatchUpdates:^{
        
        if (inserts.count > 0) {
            [self.collectionView insertItemsAtIndexPaths: inserts];
        }
        if (removes.count > 0) {
            [self.collectionView deleteItemsAtIndexPaths: removes];
        }
        if (updates.count > 0) {
            [self.collectionView reloadItemsAtIndexPaths: updates];
        }
    
    } completion:^(BOOL finished) {
        if (finished) {
            completion(YES, nil);
        }
    }];
}

- (void)filesController:(MADFilesController *)filesController didFailCreatingListInfo:(MADFileInfo *)listInfo withError:(NSError *)error {
    
}

- (void)filesController:(MADFilesController *)filesController didFailRemovingListInfo:(MADFileInfo *)listInfo withError:(NSError *)error {
    
}

- (void)filesController:(MADFilesController *)filesController didFailDuplicatingListInfo:(MADFileInfo *)listInfo withError:(NSError *)error {
    
}

#pragma mark - Convenience

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
    
    MADFileInfo *activityListInfo = [[MADFileInfo alloc] initWithURL:launchContext.fileURL];
    //activityListInfo.color = launchContext.listColor;
    
    //[self performSegueWithIdentifier:AAPLAppDelegateMainStoryboardListDocumentsViewControllerContinueUserActivity sender:activityListInfo];
}

@end
