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

#import "MADCollectionViewLayoutGroupedDelegate.h"

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
#import "MADUpgradeManager.h"
#import "MADBarButtonItem.h"

#import "UIColor+EverydayApps.h"
#import "NSFileManager+Common.h"
#import "NSURL+Document.h"
#import "MTNavigationController.h"
#import "MADNavigationBarTitleView.h"
#import "MADDocumentInformationTableViewController.h"
#import "MADFilesController.h"
#import "MADAppLaunchContext.h"
#import "MADFileInfo.h"

#import "MTPair.h"

#import "MADProgressView.h"

#import "UIAlertController+Constructors.h"
#import "MFMailComposeViewController+Constructors.h"
#import "UIBarButtonItem+Constructors.h"
#import "UILabel+Constructors.h"
#import "NSError+Constructors.h"
#import "UIView+Animations.h"

#import "MTMath.h"

#import "NSNumberFormatter+Constructors.h"
#import "MFMailComposeViewController+FileManager.h"

#import "UITabBarController+Shared.h"
#import "UINavigationController+Designer.h"
#import "MADDocumentInformationTableViewController+Designer.h"
#import "UITableViewController+Designer.h"

NSString * const MTSegueOpenInViewer                            = @"MTSegueOpenInViewer";
NSString * const MTSegueShowAddDocument                         = @"showAddDocument";
NSString * const MTSegueShowOpenDocument                        = @"MADSegueOpenDocument";
NSString * const MTCollectionViewCellDocumentIdentifier         = @"MTCollectionViewCellDocumentIdentifier";
NSString * const MTSegueLicensing                               = @"MTSegueLicensing";
NSString * const MADIdentifierOpenFileSectionHeader             = @"MADIdentifierOpenFileSectionHeader";

static NSString * const sNotDownloaded                          = @"Not Downloaded";
NSString * const MADUtiType                                     = @"com.everydayapps.productivity.mad";
NSString * const MADUtiPublicData                               = @"public.data";


CGFloat const MADSectionHeaderHeight                            = 32.0000f;

@interface MADOpenFileViewController()
    <NSFileManagerDelegate,
        UIPopoverControllerDelegate,
        UIPopoverPresentationControllerDelegate,
        UIGestureRecognizerDelegate,
        MFMailComposeViewControllerDelegate,
        UITextFieldDelegate,
        UIDocumentInteractionControllerDelegate,
        UIDocumentPickerDelegate,
        UISearchBarDelegate,
        UIStateRestoring,
        MTViewControllerProtocol,
        MTDocumentCellProtocol,
        MADFilesControllerDelegate,
        MADCollectionViewLayoutFilesDelegate>

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

@property (nonatomic, assign, getter = isRightBarButtonItemActivityIndicatorVisible, readwrite) BOOL rightBarButtonItemActivityIndicatorVisible;

@property (nonatomic, strong) MADSearchBar *searchBar;
@property (nonatomic, strong) UILabel *labelMadDesigner;

@property (nonatomic, strong) UIBarButtonItem *rightBarButtonItemHolderWhileActivity;

@property (nonatomic, strong) MADOpenFileSectionHeaderView *headerCloud;

@property (nonatomic, assign) BOOL cloudActivityRunning;
@property (nonatomic, assign) BOOL cloudActivityRunningDisplay;

@property (nonatomic, strong) UIProgressView *progressViewFileManager;

@property (atomic, assign, getter=isUpdatingEnabled) BOOL updatingEnabled;

@property (nonatomic, strong) NSMutableArray *batchInserts;
@property (nonatomic, strong) NSMutableArray *batchRemoves;
@property (nonatomic, strong) NSMutableArray *batchUpdates;

@property (nonatomic, strong) MADCollectionViewLayoutGroupedDelegate *collectionViewDelegate;

@property (nonatomic, strong) NSNumberFormatter *subtitleNumberFormatter;

@end

@implementation MADOpenFileViewController

#pragma mark - Static Functions

+ (NSString *)keySubviews {
    return NSStringFromSelector(@selector(subviews));
}
+ (NSString *)keyLeftView {
    return NSStringFromSelector(@selector(leftView));
}

+ (NSOperationQueue *)queue {
    static NSOperationQueue *queue;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = [[NSOperationQueue alloc] init];
    });
    
    return queue;
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

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
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

- (void)awakeFromNib {
    self.shouldShowAddDocumentPopover = YES;
    [self.barButtonItemAddNewDocument setEnabled:YES];
    [super awakeFromNib];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    MADCollectionViewLayoutGroupedDelegate *delegate = [[MADCollectionViewLayoutGroupedDelegate alloc] init];
    delegate.delegate = self;
    self.collectionViewDelegate = delegate;
    self.collectionView.delegate = self.collectionViewDelegate;
    
    [self addObservers];
    
    self.aboutViewControllerOnScreen = NO;
    self.updatingEnabled = YES;
    self.cloudActivityRunning = NO;
    self.cloudActivityRunningDisplay = NO;
    self.rightBarButtonItemActivityIndicatorVisible = NO;
    
    [self setNeedsStatusBarAppearanceUpdate];
    
    self.collectionView.scrollIndicatorInsets = self.collectionView.contentInset;
    [self.collectionView registerClass: [MADOpenFileSectionHeaderView class]
            forSupplementaryViewOfKind: UICollectionElementKindSectionHeader
                   withReuseIdentifier: MADIdentifierOpenFileSectionHeader];
    self.collectionView.dataSource = self;
    
    [self setEditing:NO animated:NO];
    
    self.navigationController.toolbar.barTintColor = [UIColor tintColorBlue];
    self.navigationController.toolbar.tintColor = [UIColor tintColorWhite];
    
    MADWatermarkView *watermarkView = [[MADWatermarkView alloc] initWithFrame: self.collectionView.bounds];
    self.collectionView.backgroundView = watermarkView;
    self.collectionView.backgroundColor = [UIColor lightGrayColor];
    
    MADNavigationBarTitleView *titleView = [[MADNavigationBarTitleView alloc] initWithFrame: CGRectZero];
    titleView.text = [MTApplicationInstance applicationName];
    self.navigationItem.titleView = titleView;
    self.labelMadDesigner = titleView;
    
    self.navigationItem.hidesBackButton = YES;
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget: self
                                                                                           action: @selector(handleDidTapCollectionView:)];
    tapGestureRecognizer.delegate = self;
    [self.collectionView addGestureRecognizer:tapGestureRecognizer];
    
    self.barButtonItemLicensing.enabled = [SKPaymentQueue canMakePayments];
    
    MADSearchBar *searchBar = [[MADSearchBar alloc] initWithFrame:CGRectZero];
    [searchBar sizeToFit];
    self.searchBar = searchBar;

    NSString *store = NSLocalizedString(@"Store", @"Store");
    UIBarButtonItem *barButtonItemLicensing = [[UIBarButtonItem alloc] initWithTitle:store style:UIBarButtonItemStylePlain target:self action:@selector(handleBarButtonItemStore:)];
    
    NSMutableArray *toolbarButtons = self.toolbarItems.mutableCopy;
    [toolbarButtons removeObject:self.barButtonItemAction];
    [toolbarButtons removeObject:self.barButtonItemCloudDown];
    [toolbarButtons addObject:self.barButtonItemEdit];
    [toolbarButtons insertObject:self.barButtonItemDuplicate atIndex:1];
    [toolbarButtons addObject:barButtonItemLicensing];
    [self setToolbarItems:toolbarButtons animated:NO];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.collectionView.backgroundView setNeedsDisplay];
    
    [[MTStoreKitController sharedObject] licensedUser:^(BOOL isLicensedUser, NSDate *experationDate) {
        if (isLicensedUser) {
            [self addActionItemToToolbar:animated];
        }
    }];
    
    if (self.firstTimeViewWillAppear == NO) {
        [self reenableDataWithSearch];
    }
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
    
    for (NSIndexPath *path in self.collectionView.indexPathsForVisibleItems) {
        [self.collectionView deselectItemAtIndexPath: path animated: animated];
    }
    
    self.aboutViewControllerOnScreen = NO;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
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

#pragma mark - UIStateRestoring

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    [super encodeRestorableStateWithCoder:coder];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
    [super decodeRestorableStateWithCoder:coder];
}

- (void)applicationFinishedRestoringState {
    if ([MTApplicationInstance isMadDesigner]) {
        [self performSegueWithIdentifier: MTSegueShowOpenDocument sender: self];
    } else if ([MTApplicationInstance isMadViewer]) {
        [self performSegueWithIdentifier: MTSegueOpenInViewer sender: self];
    }
}

#pragma mark - Exit

- (IBAction)unwindToOpenDocumentViewController:(UIStoryboardSegue *)action {
    
    NSString *actionIdentifier = [action identifier];
    if ([actionIdentifier isEqualToString:@"MTSegueCloseDesigner"] ||
        [actionIdentifier isEqualToString:@"MAReportViewerCloseReportIdentifier"]) {
        [[AppDelegate app] closeReport:self.traitCollection completion:^(BOOL success) {
            [self reenable];
        }];
    }
    self.shouldShowAddDocumentPopover = YES;
    self.barButtonItemAddNewDocument.enabled = YES;
    
    if ([MTApplicationInstance isMadViewer] && self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad) {

    } else if ([MTApplicationInstance isMadViewer] && self.traitCollection.userInterfaceIdiom != UIUserInterfaceIdiomPad) {
    
    } else {
        [self.openDocumentPopoverController dismissPopoverAnimated:YES];
    }
}

- (BOOL)canPerformUnwindSegueAction:(SEL)action fromViewController:(UIViewController *)fromViewController withSender:(id)sender {
    return action == @selector(unwindToOpenDocumentViewController:);
}

- (UIViewController *)viewControllerForUnwindSegueAction:(SEL)action fromViewController:(UIViewController *)fromViewController withSender:(id)sender {
    
    return action == @selector(unwindToOpenDocumentViewController:) ?
            self :
            [super viewControllerForUnwindSegueAction: action
                                   fromViewController: fromViewController
                                           withSender: sender];
}

#pragma mark - NSNotificationCenter

- (void)updateInterfaceForPerferedContentSizeCategory:(NSString *)preferredContentSizeCategory {
    for (MTCollectionViewCellDocument *cell in self.collectionView.visibleCells) {
        [cell updateFont];
    }
}

#pragma mark - UIViewController

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    if (self.traitCollection.horizontalSizeClass != previousTraitCollection.horizontalSizeClass) {
        [self.collectionView.collectionViewLayout invalidateLayout];
    }
}

- (void)willTransitionToTraitCollection: (UITraitCollection *)newCollection withTransitionCoordinator: (id<UIViewControllerTransitionCoordinator>)coordinator {
    
    [super willTransitionToTraitCollection: newCollection
                 withTransitionCoordinator: coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self.collectionView.backgroundView setNeedsDisplay];
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self.navigationItem.titleView sizeToFit];
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

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
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

- (void)popoverPresentationController:(UIPopoverPresentationController *)popoverPresentationController willRepositionPopoverToRect:(inout CGRect *)rect inView:(inout UIView **)view {
    
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

    [[AppDelegate app] closeReport:self.traitCollection completion:^(BOOL success) {
        [self reenable];
    }];
    [self dismissViewControllerAnimated:YES completion:^{
        [self.collectionView reloadData];
    }];
    
    [self.barButtonItemAddNewDocument setEnabled:YES];
}



- (void)viewControllerDidFinish:(id)sender animated:(BOOL)animated {
    [self dismissViewControllerAnimated:animated completion:^{
        [self.collectionView.indexPathsForSelectedItems enumerateObjectsUsingBlock:^(NSIndexPath *indexPath, NSUInteger idx, BOOL *stop) {
            [self.collectionView deselectItemAtIndexPath:indexPath animated:animated];
        }];
        [self.collectionView.indexPathsForVisibleItems enumerateObjectsUsingBlock:^(NSIndexPath *indexPath, NSUInteger idx, BOOL *stop) {
            MTCollectionViewCellDocument *cell = (MTCollectionViewCellDocument *)[self.collectionView cellForItemAtIndexPath:indexPath];
            [cell normalizeTint];
        }];
    }];
    
    Class queryBuilderClass = [MADQueryViewController class];
    Class queryBuilderContainerClass = [MTQueryBuilderContainerController class];
    Class reportDesignerClass = [MADDesignerViewController class];
    Class reportViewerClass = [MADViewerController class];
    
    if ([sender isKindOfClass: queryBuilderClass] ||
        [sender isKindOfClass: queryBuilderContainerClass] ||
        [sender isKindOfClass: reportDesignerClass] ||
        [sender isKindOfClass: reportViewerClass]) {
        [[AppDelegate app] closeReport:self.traitCollection completion:^(BOOL success) {
            [self reenable];
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
        MFMailComposeViewController	*controller = [MFMailComposeViewController contactUs:self];
        [self presentViewController: controller animated: YES completion: nil];
    } else {
        UIAlertController *alert = [UIAlertController alertNotConfiguredForEmail];
        [self presentViewController: alert animated: YES completion: nil];
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

#pragma mark - MFMailComposeViewController delegate protocol

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {

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

- (BOOL)fileManager:(NSFileManager *)fileManager shouldProceedAfterError:(NSError *)error movingItemAtURL:(NSURL *)srcURL toURL:(NSURL *)dstURL {
    
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

- (void)openFileWithUrl:(NSURL *)url { //completion:(void (^)(BOOL success))completion {
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
                UITabBarController *tabBarController = [UITabBarController mainTabBarController];
                
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

#pragma mark - MADCollectionViewLayoutFilesDelegate

- (NSString *)titleForItemAtIndexPath:(NSIndexPath *)indexPath {
    MADMetaData *metadata = [self.filesController objectAtIndexedSubscript: indexPath.item];
    return [MADocument fileNameForMadUrl:metadata.URL];
}

- (NSString *)subtitleForItemAtIndexPath:(NSIndexPath *)indexPath {
    MADMetaData *metadata = [self.filesController objectAtIndexedSubscript: indexPath.item];
    return [self subtitleForMetadata:metadata];
}

- (NSString *)subtitleForMetadata:(MADMetaData *)metadata {
    NSString *result;
    if ([metadata.ubiquitousItemDownloadingStatus isEqualToString: NSMetadataUbiquitousItemDownloadingStatusNotDownloaded]) {
        result = NSLocalizedString(sNotDownloaded, sNotDownloaded);;
    } else {
        NSNumber *systemFileSizeMB =  [MTMath systemFileSizeToMB: metadata.fileSystemFileSize];
        NSString *systemFileSizeString = [self.subtitleNumberFormatter stringFromNumber:systemFileSizeMB];
        result = [NSString stringWithFormat:@"%@ MB", systemFileSizeString];
    }
    return result;
}

- (MADMetaData *)metadataForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [self.filesController objectAtIndexedSubscript: indexPath.item];
}

- (void)userSelectedItemAtIndexPath:(NSIndexPath *)indexPath {
    
    MADMetaData *metadata = [self.filesController objectAtIndexedSubscript:indexPath.item];
    MTCollectionViewCellDocument *cell = (MTCollectionViewCellDocument *)[self.collectionView cellForItemAtIndexPath:indexPath];
    [cell performSelectionAnimations];
    
    if (self.isEditing) {
        [self.collectionView selectItemAtIndexPath:indexPath animated:YES scrollPosition:UICollectionViewScrollPositionCenteredVertically];
        if (metadata.isUbiquitous) {
            if (metadata.isUbiquitousItemDownloadingStatusNotDownloaded) {
                NSError *error = nil;
                [[NSFileManager defaultManager] startDownloadingUbiquitousItemAtURL:metadata.URL error:&error];
            }
        }
    } else {
        [self.collectionView deselectItemAtIndexPath:indexPath animated:YES];
        [cell.activityIndicator startAnimating];
        [self.collectionView setUserInteractionEnabled: NO];
        [self openFileWithUrl:metadata.URL];
    }
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.filesController ? self.filesController.count : 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    MTCollectionViewCellDocument *cell = [collectionView dequeueReusableCellWithReuseIdentifier: MTCollectionViewCellDocumentIdentifier forIndexPath: indexPath];
    if (cell.delegate == nil) {
        cell.delegate = self;
    }
    MADMetaData *metadata = [self metadataForItemAtIndexPath:indexPath];
    NSString *filename = metadata.name;
    cell.labelTitle.text = filename;
    
    BOOL notDownloaded = [metadata.ubiquitousItemDownloadingStatus isEqualToString: NSMetadataUbiquitousItemDownloadingStatusNotDownloaded];

    BOOL downloading = metadata.ubiquitousItemIsDownloading;
    BOOL uploading = metadata.ubiquitousItemIsUploading;
    
    if (downloading) {
        cell.labelTitleSub.text = NSLocalizedString(@"Downloading", @"Downloading");
    } else if (uploading) {
        cell.labelTitleSub.text = NSLocalizedString(@"Syncing", @"Syncing");
    } else {
        cell.labelTitleSub.text = [self subtitleForMetadata:metadata];
    }
    
    if (uploading) {
        cell.progressViewUpload.hidden = NO;
        if (cell.progressViewUpload.progress < metadata.ubiquitousItemPercentUploaded / 100.0000f) {
            [cell.progressViewUpload setProgress:metadata.ubiquitousItemPercentUploaded / 100.0000f animated:YES];
        }
    } else {
        cell.progressViewUpload.hidden = YES;
        [cell.progressViewUpload setProgress:0.0000f animated:YES];
    }
    
    if (downloading) {
        cell.progressViewDownload.hidden = NO;
        if (cell.progressViewUpload.progress < metadata.ubiquitousItemPercentDownloaded / 100.0000f) {
            [cell.progressViewDownload setProgress:metadata.ubiquitousItemPercentDownloaded / 100.0000f animated:YES];
        }
    } else {
        cell.progressViewDownload.hidden = YES;
        [cell.progressViewDownload setProgress:0.0000f animated:YES];
    }
    
    if (metadata.ubiquitousItemIsDownloading || metadata.ubiquitousItemIsUploading) {
        [cell.activityIndicator startAnimating];
    } else {
        [cell.activityIndicator stopAnimating];
    }
    
    cell.imageCloudIndicator.image = notDownloaded && metadata.isUbiquitous ? [UIImage imageNamed:MADImageToolbarCloudDownload] : nil;
    
    [cell.labelTitle layoutIfNeeded];
    [cell.labelTitleSub layoutIfNeeded];
    [cell loadPreviewImageForUrl:metadata.URL];
    
    if ([self isFileViewEditing]) {
        [cell startWobble];
    } else {
        [cell stopWobble];
    }
    [cell normalizeTint];
    return cell;
}

#pragma mark - MTDocumentCellProtocol

- (void)activateEditMode:(UILongPressGestureRecognizer *)sender {
    if ([sender state] == UIGestureRecognizerStateBegan) {
        
        NSIndexPath *indexPath = [self.collectionView indexPathForCell:((MTCollectionViewCellDocument *)sender.view)];
        if (self.isEditing == NO) {
            [self edit:self];
        }
        [self.collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
        [self selectionsUpdated];
    }
}

#pragma mark - Touch Event Handlers

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
    for (MTCollectionViewCellDocument *cell in self.collectionView.visibleCells) {
        [cell.activityIndicator stopAnimating];
    }
    [self reenableDataWithSearch];
}

- (void)loadCollectionViewPreviewImageForIndexPath:(NSIndexPath *)indexPath {
   NSURL *fileUrl = [self documentForIndexPath:indexPath];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        dispatch_sync(dispatch_get_main_queue(), ^(void) {
            
            MTCollectionViewCellDocument *visibleCell = (MTCollectionViewCellDocument *)[self.collectionView cellForItemAtIndexPath:indexPath];
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

- (void)selectionsUpdated {
    switch (self.collectionView.indexPathsForSelectedItems.count) {
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
        path = [NSIndexPath indexPathForItem:((NSNumber *)pair.right).integerValue inSection:0];
        [updates addObject:path];
    }

    [updates removeObjectsInArray:inserts];
    [updates removeObjectsInArray:removes];
    
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

#pragma mark - Actions

- (IBAction)addDocument:(id)sender {
    
    UINavigationController *navControl = [UINavigationController NewDocument];
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
        //self.editing = YES;
        self.barButtonItemLicensing.enabled = NO;
        self.barButtonItemAddNewDocument.enabled = NO;
        self.barButtonItemAbout.enabled = NO;
        self.barButtonItemInformation.enabled = NO;
        self.collectionView.allowsMultipleSelection = YES;
        /*
        NSUInteger numberOfItemsInSection = [self.collectionView numberOfItemsInSection:0];
        for (NSInteger i=0; i<numberOfItemsInSection; i++) {
            NSIndexPath *path = [NSIndexPath indexPathForItem:i inSection:0];
            UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:path];
            //[cell startWobble];
        }*/
        //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //    dispatch_sync(dispatch_get_main_queue(), ^{
                [self.collectionView reloadItemsAtIndexPaths:self.collectionView.indexPathsForVisibleItems];
        //    });
        //});

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

- (BOOL)isFileViewEditing {
    return self.editing;
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
    
    [self.collectionView reloadItemsAtIndexPaths:self.collectionView.indexPathsForVisibleItems];
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
}

- (IBAction)info:(id)sender {
    
    UINavigationController *infoViewController = [UINavigationController AppInformation];
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

        UITableViewController *aboutViewController = [UITableViewController About];
        UIPopoverPresentationController *ppc = aboutViewController.popoverPresentationController;
        ppc.passthroughViews = [ppc.passthroughViews arrayByAddingObjectsFromArray:[self defaultPassthoughViews]];
        
        ppc.backgroundColor = [UIColor clearColor];
        ppc.delegate = self;
        ppc.barButtonItem = sender;
        self.aboutPopoverPresentationController = ppc;
        
        
        [self showViewController:aboutViewController sender:self];
        
    }
}
- (void)handleBarButtonItemStore:(id)sender {
    
    UINavigationController *licensing = [UINavigationController Licensing];
    licensing.modalPresentationStyle = UIModalPresentationFullScreen;
    licensing.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self showViewController:licensing sender:self];    
    
}

- (IBAction)activity:(id)sender {
    
    NSMutableArray *wrappedUrls = [[NSMutableArray alloc] initWithCapacity: self.filesController ? self.filesController.count : 0];
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
    
    MADDocumentInformationTableViewController *documentInformation = [MADDocumentInformationTableViewController DocumentInformation];
    
    documentInformation.modalPresentationStyle = UIModalPresentationPopover;
    UIPopoverPresentationController *ppc = documentInformation.popoverPresentationController;
    ppc.passthroughViews = [ppc.passthroughViews arrayByAddingObjectsFromArray:[self defaultPassthoughViews]];
    
    ppc.backgroundColor = [UIColor clearColor];
    ppc.delegate = self;
    ppc.barButtonItem = sender;
    self.documentInformationPopoverPresentationController = ppc;
    
    documentInformation.metadataItems = metadataItems;
    [self showViewController:documentInformation sender:self];
    
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
    if ([sender isKindOfClass:[UIBarButtonItem class]]) {
        alertController.popoverPresentationController.barButtonItem = sender;
    }
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
        
        NSString *name = [NSURL fileNameFilter:text];
        if (name.length > 0) {
            NSURL *newUrl = [metaData.URL.URLByDeletingLastPathComponent URLByAppendingPathComponent:name isDirectory:NO];
            if ([[NSFileManager defaultManager] fileExistsAtPath:newUrl.path] == NO && [[NSFileManager defaultManager] isUbiquitousItemAtURL:newUrl] == NO) {
                if (metaData.isUbiquitousItemDownloadingStatusNotDownloaded) {
                    UIDocument *doc = [[MADocument alloc] initWithFileURL:metaData.URL];
                    [doc openWithCompletionHandler:^(BOOL success) {
                        if (success) {
                            [doc closeWithCompletionHandler:^(BOOL success) {
                                if (success) {
                                    [self.filesController renameFileInfo:metaData toName:text];
                                }
                            }];
                        }
                    }];
                } else {
                    [self.filesController renameFileInfo:metaData toName:text];
                }
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

- (void)email:(MTCollectionViewCellDocument *)cell {
    
    if ([MFMailComposeViewController canSendMail] == NO) {
        
        UIAlertController *alert = [UIAlertController alertNotConfiguredForEmail];
        [self showViewController:alert sender:self];
        
    } else {
        
        NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
        MADMetaData *metadata = [self.filesController objectAtIndexedSubscript:indexPath.item];

        MADocument *documentReport = [[MADocument alloc] initWithFileURL:metadata.URL];
        
        if (documentReport.documentState != UIDocumentStateClosed) {
            [documentReport closeWithCompletionHandler:^(BOOL success) {
                if (success) {
                    [self email:cell];
                }
            }];
        } else {
            
            NSString *messageStringStart = NSLocalizedString(@"The attached document can be opened with MAD Viewer.",
                                                             @"The attached document can be opened with MAD Viewer.");
            NSMutableString *messageBody = [[NSMutableString alloc] initWithString:messageStringStart];
            [messageBody appendString:@"\n\nhttp://www.everydayapps.com/\n\n"];
            
            NSString *formatString = NSLocalizedString(@"MAD Document %@.", @"MAD Document %@.");
            NSString *subject = [NSString stringWithFormat:formatString, metadata.name];
            MFMailComposeViewController	*mailComposer = [MFMailComposeViewController mailDocument: metadata.URL
                                                                                         mimeType: MADMimeType
                                                                                            title: subject
                                                                                             body: messageBody
                                                                               userInterfaceIdiom: self.traitCollection.userInterfaceIdiom];
            mailComposer.mailComposeDelegate = self;
            [self showViewController:mailComposer sender:self];
            
        }
    }
    
}

#pragma mark - Notification Handlers

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
    NSString *contentSize = notification.userInfo[UIContentSizeCategoryNewValueKey];
    [self updateInterfaceForPerferedContentSizeCategory:contentSize];
    [self.view setNeedsLayout];
}

- (void)handleCloudActivityCompleted:(NSNotification *)notification {
    self.cloudActivityRunning = NO;
    self.cloudActivityRunningDisplay = NO;
    [self.headerCloud stopAnimating];
}

#pragma mark - Convenience

- (NSArray *)defaultPassthoughViews {
    return @[self.navigationController.navigationBar, self.navigationController.toolbar];
}

- (NSURL *)urlForDocumentCell:(MTCollectionViewCellDocument *)cellDocument {
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cellDocument];
    return [self documentForIndexPath:indexPath];
}

- (NSURL *)documentForIndexPath:(NSIndexPath *)indexPath {
    MADMetaData *metadata = [self.filesController objectAtIndexedSubscript:indexPath.item];
    return metadata.URL;
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
    
    //MADFileInfo *activityListInfo = [[MADFileInfo alloc] initWithURL:launchContext.fileURL];
    //activityListInfo.color = launchContext.listColor;
    
    //[self performSegueWithIdentifier:AAPLAppDelegateMainStoryboardListDocumentsViewControllerContinueUserActivity sender:activityListInfo];
}

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

#pragma mark Add controls

- (void)addProgressViewToView {
    self.progressViewFileManager.progress = 0.0000f;
    [self.view addSubview:self.progressViewFileManager];
    [self.view bringSubviewToFront:self.progressViewFileManager];
}

- (void)removeProgressViewFromView {
    [self.progressViewFileManager removeFromSuperview];
}

#pragma mark - Property Overrides

- (NSNumberFormatter *)subtitleNumberFormatter {
    if (!_subtitleNumberFormatter) {
        _subtitleNumberFormatter = [NSNumberFormatter twoDecimalPlaces];
    }
    return _subtitleNumberFormatter;
}

- (void)setFilesController:(MADFilesController *)filesController {
    if (filesController != _filesController) {
        _filesController = filesController;
        _filesController.delegate = self;
    }
}

- (UIBarButtonItem *)barButtonItemEditDone {
    if (!_barButtonItemEditDone) {
        _barButtonItemEditDone = [UIBarButtonItem buttonEditDone:self action:@selector(edit:)];
    }
    return _barButtonItemEditDone;
}

- (UIBarButtonItem *)barButtonItemDuplicate {
    if (!_barButtonItemDuplicate) {
        _barButtonItemDuplicate = [UIBarButtonItem buttonDuplicate:self action:@selector(duplicate:)];
    }
    return _barButtonItemDuplicate;
}

- (UIBarButtonItem *)barButtonItemEdit {
    if (!_barButtonItemEdit) {
        _barButtonItemEdit = [UIBarButtonItem buttonEdit:self action:@selector(edit:)];
    }
    return _barButtonItemEdit;
}

@end
