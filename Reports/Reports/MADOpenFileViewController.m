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
#import <MessageUI/MessageUI.h>

#import "AppDelegate.h"
#import "MTApplicationInstance.h"

#import "MADGroupedCollectionViewLayout.h"

#import "MADocument.h"
#import "MACloudManager.h"
#import "MADMetaData.h"
#import "MADSearchBar.h"

#import "MADOpenFileSectionHeaderView.h"
#import "MTCollectionViewCellDocument.h"
#import "MTTableViewCellDocument.h"

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
#import "MADFileLocationManager.h"
#import "MADUpgradeManager.h"
#import "MADBarButtonItem.h"

#import "UIColor+EverydayApps.h"
#import "UIView+Animations.h"
#import "UIDevice+Hack.h"
#import "NSFileManager+Common.h"
#import "NSError+UserInterface.h"
#import "NSURL+Document.h"
#import "UIAlertController+CommonAlerts.h"
#import "MTNavigationController.h"

NSString * const MTSegueOpenInViewer                            = @"MTSegueOpenInViewer";
NSString * const MTSegueShowAddDocument                         = @"showAddDocument";
NSString * const MTSegueShowOpenDocument                        = @"MADSegueOpenDocument";
NSString * const MTCollectionViewCellDocumentIdentifier         = @"MTCollectionViewCellDocumentIdentifier";
NSString * const MTDocumentExtentionPoratableNetworkGraphic     = @"png";
NSString * const MTSegueLicensing                               = @"MTSegueLicensing";
NSString * const MADIdentifierOpenFileSectionHeader             = @"MADIdentifierOpenFileSectionHeader";
NSString * const MADNotificationReloadSectionLocal              = @"MADNotificationReloadSectionLocal";

CGFloat const MADSectionHeaderHeight = 32.0000f;
CGFloat const MADConstCellDocumentLabelWidth = 124.0000f;
CGFloat const MADConstCellDocumentLabelMaxHeight = 300.0000f;

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
        MTDocumentCellProtocol>

@property (nonatomic, strong) IBOutlet UIBarButtonItem *barButtonItemAction;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *barButtonItemEdit;
@property (nonatomic, strong) UIBarButtonItem *barButtonItemLicensing;
@property (nonatomic, strong) UIBarButtonItem *barButtonItemEditDone;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *barButtonItemTrash;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *barButtonItemInformation;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *barButtonItemAbout;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *barButtonItemAddNewDocument;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *barButtonItemCloudDown;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *barButtonItemSearch;
@property (nonatomic, strong) UIBarButtonItem *barButtonItemDuplicate;

@property (nonatomic, weak) UIPopoverPresentationController *aboutPopoverPresentationController;
@property (nonatomic, strong) MTNavigationController *aboutNavigationController;

@property (nonatomic, strong) UIPopoverController *openDocumentPopoverController;
//@property (nonatomic, strong) UIPopoverController *aboutPopoverController;
@property (nonatomic, strong) UIPopoverController *licensingPopoverController;
@property (nonatomic, strong) UIPopoverController *popoverControllerActivity;

@property (nonatomic, assign) BOOL shouldShowAddDocumentPopover;
@property (nonatomic, assign) BOOL editModeEnabled;
@property (nonatomic, assign) BOOL bothContentControllersDisplayed;

@property (nonatomic, assign, getter = isSavingActivityIndicatorVisible, readwrite) BOOL savingActivityIndicatorVisible;
@property (nonatomic, assign, getter = isRightBarButtonItemActivityIndicatorVisible, readwrite) BOOL rightBarButtonItemActivityIndicatorVisible;

@property (nonatomic, strong) MADSearchBar *searchBar;
@property (nonatomic, strong) UILabel *labelMadDesigner;

@property (nonatomic, strong) UIBarButtonItem *rightBarButtonItemHolderWhileActivity;

@property (nonatomic, assign) BOOL firstViewWillAppear;

@property (nonatomic, strong) MADOpenFileSectionHeaderView *headerCloud;

@property (nonatomic, assign) BOOL cloudActivityRunning;
@property (nonatomic, assign) BOOL cloudActivityRunningDisplay;

@property (nonatomic, strong) NSStringDrawingContext *collectionViewSizeForItemAtIndexPath;
@property (nonatomic, strong) UILabel *testLabel;

// Local cache
@property (atomic, assign, getter=isUpdatingEnabled) BOOL updatingEnabled;
@property (nonatomic, strong) NSMutableArray *documentsLocal;
@property (nonatomic, strong) NSMutableArray *documentsCloud;

@end

@implementation MADOpenFileViewController

- (void)setRightBarButtonItemActivityIndicatorVisible:(BOOL)rightBarButtonItemActivityIndicatorVisible animated:(BOOL)animated {
    
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

- (IBAction)unwindToOpenDocumentViewController:(UIStoryboardSegue *)action {
    
    NSString *actionIdentifier = [action identifier];
    if ([actionIdentifier isEqualToString:@"MTSegueCloseDesigner"] ||
        [actionIdentifier isEqualToString:@"MAReportViewerCloseReportIdentifier"]) {
        MTApplicationInstance *app = [AppDelegate app];
        __weak MADOpenFileViewController *weakself = self;
        [[app openDocument] regenThumbnailWithTraits:self.traitCollection];
        [app closeReportWithCompletionHandler:^(BOOL success) {
            [weakself reenable];
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

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initialize];
    }
    return self;    
}

- (instancetype)initWithCollectionViewLayout:(UICollectionViewLayout *)layout {
    self = [super initWithCollectionViewLayout:layout];
    if (self) {
        [self initialize];
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self initialize];
    }
    return self;
}

- (void)initialize {

    NSMutableArray *documentsLocal = [[NSMutableArray alloc] init];
    self.documentsLocal = documentsLocal;
    
    NSMutableArray *documentsCloud = [[NSMutableArray alloc] init];
    self.documentsCloud = documentsCloud;
    
    self.updatingEnabled = YES;
    self.cloudActivityRunning = NO;
    self.cloudActivityRunningDisplay = NO;
    self.firstViewWillAppear = YES;
    self.rightBarButtonItemActivityIndicatorVisible = NO;
    
    NSStringDrawingContext *collectionViewSizeForItemAtIndexPath = [[NSStringDrawingContext alloc] init];
    self.collectionViewSizeForItemAtIndexPath = collectionViewSizeForItemAtIndexPath;

}

- (void)dealloc {

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
                                                    name: MADNotificationReloadSectionLocal
                                                  object: nil];
}

#pragma mark - NSNotificationCenter

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
    
}

- (void)displayActivityIndictor {
    if (self.cloudActivityRunning) {
        self.cloudActivityRunningDisplay = YES;
        [self.headerCloud startAnimating];
    }
}


- (void)handleCloudActivityCompleted:(NSNotification *)notification {
    self.cloudActivityRunning = NO;
    self.cloudActivityRunningDisplay = NO;
    [self.headerCloud stopAnimating];
}

+ (CGRect)cellLabelRect {
    return CGRectMake(CGPointZero.x,
                      CGPointZero.y,
                      MADConstCellDocumentLabelWidth,
                      MADConstCellDocumentLabelMaxHeight);
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)viewDidLoad {

    [self setNeedsStatusBarAppearanceUpdate];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(reloadSectionLocal)
                                                 name: MADNotificationReloadSectionLocal
                                               object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleContentSizeCategoryDidChangeNotification:)
                                                 name: UIContentSizeCategoryDidChangeNotification
                                               object: nil];

    UILabel *label = [[UILabel alloc] initWithFrame:[MADOpenFileViewController cellLabelRect]];
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
    
    self.collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(self.collectionView.contentInset.top + ([MACloudManager sharedManager].cloudAvailble ? MADSectionHeaderHeight : CGSizeZero.height),
                                                                 self.collectionView.contentInset.left,
                                                                 self.collectionView.contentInset.bottom,
                                                                 self.collectionView.contentInset.right);
    
    
    [self.collectionView registerClass: [MADOpenFileSectionHeaderView class]
            forSupplementaryViewOfKind: UICollectionElementKindSectionHeader
                   withReuseIdentifier: MADIdentifierOpenFileSectionHeader];
  
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleCloudActivityStarted:)
                                                 name: MADNotificationCloudActivityStarted
                                               object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleCloudActivityCompleted:)
                                                 name: MADNotificationCloudActivityCompleted
                                               object: nil];
    
    UIBarButtonItem *barButtonItemEditDone = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemDone
                                                                                           target: self
                                                                                           action: @selector(edit:)];
    [self setBarButtonItemEditDone:barButtonItemEditDone];

    [self setEditModeEnabled:NO];
    [self setEditing:NO animated:NO];

    UIColor *barTintColor = [UIColor tintColorBlue];
    UIColor *tintColor = [UIColor tintColorWhite];
    self.navigationController.toolbar.barTintColor = barTintColor;
    self.navigationController.toolbar.tintColor = tintColor;

    MADWatermarkView *watermarkView = [[MADWatermarkView alloc] initWithFrame: self.collectionView.bounds];
    UIImageView *testimage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"testimage.jpg"]];
    testimage.frame=self.collectionView.frame;
    //[watermarkView addSubview:testimage];
    self.collectionView.backgroundView = testimage;
    self.collectionView.backgroundColor = [UIColor purpleColor];

    UIColor *bgColor = [UIColor lightGrayColor];
    //self.collectionView.backgroundColor = bgColor;
    
    [self setSavingActivityIndicatorVisible:NO];
    UILabel *labelMadDesigner = [[UILabel alloc] initWithFrame:CGRectZero];
    labelMadDesigner.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    NSAttributedString *attributedString = nil;
    if ([MTApplicationInstance isMadDesigner]) {
        attributedString = [MTApplicationInstance localizedAttributedApplicationNameMadDesigner];
    } else if ([MTApplicationInstance isMadViewer]) {
        attributedString = [MTApplicationInstance localizedAttributedApplicationNameMadViewer];
    }
    NSAssert(attributedString != nil, @"Navigation title is not set.");
    [labelMadDesigner setAttributedText:attributedString];
    self.navigationItem.titleView = labelMadDesigner;
    self.labelMadDesigner = labelMadDesigner;
    [self.navigationItem.titleView sizeToFit];

    self.navigationItem.hidesBackButton = YES;
    self.editModeEnabled = NO;
    
    UITapGestureRecognizer *tapGestureRecognizer = [self tapGestureRecognizer];
    [self.collectionView addGestureRecognizer:tapGestureRecognizer];
    
    self.barButtonItemLicensing.enabled = [SKPaymentQueue canMakePayments];

    NSMutableArray *toolbarButtons = [NSMutableArray arrayWithArray: self.toolbarItems];
    [toolbarButtons removeObject:self.barButtonItemAction];
    
    // FIXME: Remove cloud down button until feature is added.
    [toolbarButtons removeObject:self.barButtonItemCloudDown];

    
    MADSearchBar *searchBar = [[MADSearchBar alloc] initWithFrame:CGRectZero];
    searchBar.delegate = self;
    searchBar.showsBookmarkButton = NO;
    searchBar.showsCancelButton = YES;
    searchBar.showsScopeBar = NO;
    searchBar.showsSearchResultsButton = NO;
    searchBar.hidden = YES;
    
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

- (UITapGestureRecognizer *)tapGestureRecognizer {
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget: self
                                                                                           action: @selector(endEditMode:)];
    tapGestureRecognizer.delegate = self;
    return tapGestureRecognizer;
}

#pragma mark - UISearchBarDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField { }

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar { }

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if ([keyPath isEqualToString:@"subviews"]) {
        if ([object isKindOfClass:[UITextField class]]) {
            
            
            for (UIView *view in ((UITextField *)object).subviews) {
                if ([view isKindOfClass:[UIButton class]]) {
                    
                    
                    UIImage *image = [((UIButton *)view).imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                    ((UIButton *)view).tintColor = [UIColor whiteColor];
                    [((UIButton *)view) setImage:image forState:UIControlStateNormal];
                }
            }
        }
    } else if ([keyPath isEqualToString:@"leftView"]) {
        
    }
}

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope { }

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [self animateUpdates];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar { }

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    if (self.searchBar.text.length > 0) {
        self.searchBar.text = @"";
        
        [self animateUpdates];
    }
    [searchBar resignFirstResponder];
    [self search: self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    __weak MADOpenFileViewController *weakself = self;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        MADUpgradeManager *upgradeManager = [[MADUpgradeManager alloc] init];
        [upgradeManager performUpgradeIfRequired:^(BOOL success, NSError *error, BOOL upgradePerfomrmed) {
            if (upgradePerfomrmed) {
                [weakself reloadData];
            }
        }];
    });
    
    [[MTStoreKitController sharedObject] licensedUser:^(BOOL isLicensedUser, NSDate *experationDate) {
        if (isLicensedUser) {
            [weakself addActionItemToToolbar:animated];
        }
    }];

    if (self.firstViewWillAppear == NO) {
        [self reenableDataWithSearch];
    }
    
    self.firstViewWillAppear = NO;
}

- (void)reenableDataWithSearch {
    if (self.searchBar) {
        [self searchBar: self.searchBar
          textDidChange: self.searchBar.text];
    } else {
        [self reloadData];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
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
    
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self.navigationItem.titleView sizeToFit];
    [self.collectionView.backgroundView setNeedsDisplay];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    __weak MADOpenFileViewController *weakself = self;
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [weakself.collectionView.backgroundView setNeedsDisplay];
    } completion:nil];

}

- (void)prepareForSegueAddDocument:(UIStoryboardSegue *)segue {
    if ([segue.destinationViewController isKindOfClass: [UINavigationController class]]) {
        UINavigationController *navControl = segue.destinationViewController;
        if ([navControl topViewController]) {
            if ([segue isKindOfClass:[UIStoryboardPopoverSegue class]]) {
                [self setOpenDocumentPopoverController: [(UIStoryboardPopoverSegue *)segue popoverController]];
                self.openDocumentPopoverController.delegate = self;
            }
            ((MTDatabaseDriverSelectorViewController *)[navControl topViewController]).delegate = self;
        }
    }
    if ([segue.destinationViewController isKindOfClass:[MTQueryBuilderContainerController class]]) {
        ((MTQueryBuilderContainerController *)segue.destinationViewController).viewControllerDelegate = self;
    } else {
        [segue.destinationViewController setDelegate: self];
    }
}

- (void)prepareForSegueDetails:(UIStoryboardPopoverSegue *)segue {
    UINavigationController *navigationController = segue.destinationViewController;
    navigationController.modalPresentationStyle = UIModalPresentationPopover;
    UIPopoverPresentationController *ppc = navigationController.popoverPresentationController;
    ppc.containerView.backgroundColor = [UIColor clearColor];
    ppc.delegate = self;
    self.aboutPopoverPresentationController = ppc;
    
    MADAboutTableViewController *aboutViewController = (MADAboutTableViewController *)navigationController.topViewController;
    aboutViewController.delegate = self;
    aboutViewController.preferredContentSize = CGSizeMake(320.0000f, 320.0000f);
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
    
    if ([segue.identifier isEqualToString:MTSegueShowAddDocument]) {
        [self prepareForSegueAddDocument:segue];
        
    } else if ([segue.identifier isEqualToString:@"MTSegueDetails"] || [segue.identifier isEqualToString:@"MTSegueAbout"]) {
        [self prepareForSegueDetails:(UIStoryboardPopoverSegue *)segue];
        
    } else if ([segue.identifier isEqualToString:MTSegueLicensing]) {
        [self prepareForSegueLicensing:segue];

    } else if ([segue.identifier isEqualToString:MTSegueOpenInViewer]) {
        MTApplicationInstance *app = [AppDelegate app];
        [[app openDocument] activeDocumentModel];
        [self prepareForSegueOpenInViewer:segue sender:sender];
        
    } else if ([segue.identifier isEqualToString:MTSegueShowOpenDocument]) {
        MTApplicationInstance *app = [AppDelegate app];
        [[app openDocument] activeDocumentModel];
        [self prepareForSegueShowOpenDocument:segue sender:sender];
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
    [self setShouldShowAddDocumentPopover:YES];
    [self.barButtonItemAddNewDocument setEnabled:YES];
}

#pragma mark - UIAdaptivePresentationControllerDelegate

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller {
    UIModalPresentationStyle style = UIModalPresentationOverCurrentContext;
    if ([controller isEqual:self.aboutPopoverPresentationController]) {
        style = UIModalPresentationNone;
    }
    return style;
}

//- (UIViewController *)presentationController:(UIPresentationController *)controller viewControllerForAdaptivePresentationStyle:(UIModalPresentationStyle)style {
    
//}

#pragma mark - UIPopoverPresentationControllerDelegate

- (void)prepareForPopoverPresentation:(UIPopoverPresentationController *)popoverPresentationController {
    
}

- (BOOL)popoverPresentationControllerShouldDismissPopover:(UIPopoverPresentationController *)popoverPresentationController {
    return YES;
}

- (void)popoverPresentationControllerDidDismissPopover:(UIPopoverPresentationController *)popoverPresentationController {
    
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

#pragma mark - UIDocumentInteractionControllerDelegatex

- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *) controller {
    return self.navigationController;
}


#pragma mark - Delegates

- (void)viewControllerDidFinish:(id)sender {
    [self setShouldShowAddDocumentPopover:YES];
    MTApplicationInstance *app = [AppDelegate app];
    __weak MADOpenFileViewController *weakself = self;
    [[app openDocument] regenThumbnailWithTraits:self.traitCollection];
    [app closeReportWithCompletionHandler:^(BOOL success) {
        [weakself reenable];
    }];
    
    if ([self.openDocumentPopoverController isPopoverVisible]) {
        [self.openDocumentPopoverController dismissPopoverAnimated:YES];
    } else {
        [self dismissViewControllerAnimated:YES completion:^{ }];
    }
    [self.barButtonItemAddNewDocument setEnabled:YES];
    if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        [self reloadData];
    }
}

- (void)viewControllerDidFinish:(id)sender animated:(BOOL)animated {
    [self dismissViewControllerAnimated:YES completion:^{ }];
    
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
    [self setShouldShowAddDocumentPopover:YES];
    [self.barButtonItemAddNewDocument setEnabled:YES];
    [self.openDocumentPopoverController dismissPopoverAnimated:YES];
    
}

- (void)viewControllerDidCancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.openDocumentPopoverController dismissPopoverAnimated:YES];
    [self setShouldShowAddDocumentPopover:YES];
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
    if ([[self toolbarItems] containsObject:[self barButtonItemAction]] == NO) {
        NSMutableArray *toolbarButtons = [[self toolbarItems] mutableCopy];
        [toolbarButtons insertObject:[self barButtonItemAction] atIndex:1];
        [self setToolbarItems:toolbarButtons animated:animated];
    }

}

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
    
    return [MACloudManager sharedManager].cloudAvailble ? CGSizeMake(collectionView.bounds.size.width, MADSectionHeaderHeight) : CGSizeZero;
    
}

- (NSURL *)urlForDocumentCell:(MTCollectionViewCellDocument *)cellDocument {
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cellDocument];

    return [self documentForIndexPath:indexPath];

}


- (void)reloadSectionLocal {
    if (self.isUpdatingEnabled) {
        [[MACloudManager sharedManager] reloadCacheLocal:self.searchBar.text];
        [self.documentsLocal setArray:[MACloudManager sharedManager].documentCacheLocalUrls];
        
        NSIndexSet *local = [NSIndexSet indexSetWithIndex:0];
        [self.collectionView reloadSections:local];
    }
}

- (void)reloadSectionCloud {
    if (self.isUpdatingEnabled) {
        [[MACloudManager sharedManager] reloadCacheCloud:self.searchBar.text];
        [self.documentsCloud setArray:[MACloudManager sharedManager].documentCacheCloudMetaDataItems];
        
        NSIndexSet *cloud = [NSIndexSet indexSetWithIndex:1];
        [self.collectionView reloadSections:cloud];
    }
}

- (void)reloadData {
    if (self.isUpdatingEnabled) {
        NSLog(@"Reload Data");
        
        [[MACloudManager sharedManager] reloadCacheLocal:self.searchBar.text];
        [[MACloudManager sharedManager] reloadCacheCloud:self.searchBar.text];
        
        [self.documentsLocal setArray:[MACloudManager sharedManager].documentCacheLocalUrls];
        [self.documentsCloud setArray:[MACloudManager sharedManager].documentCacheCloudMetaDataItems];
        
        [self.collectionView reloadData];
    }
}

- (NSURL *)documentForIndexPath:(NSIndexPath *)indexPath {
    MADMetaData *metadata = [[MACloudManager sharedManager] metadataForItemAtLocation: indexPath.item
                                                                            inSection: cloudManagerSectionForDisplaySection(indexPath.section)];
    
    return metadata.url;
}

- (void)removeCachedFileForDocumentUrl:(NSURL *)documentUrl {
    NSError *error = nil;
    NSFileManager *defaultManager = [NSFileManager defaultManager];
    NSURL *cachedDirectory = [defaultManager localCachedDirectoryForFileUrl:documentUrl];
    NSArray *contentsOfDirectoryAtUrlCachedDirectory = [defaultManager contentsOfDirectoryAtURL:cachedDirectory
                                                                     includingPropertiesForKeys:nil options:0 error:&error];
    for (NSURL *cachedFile in contentsOfDirectoryAtUrlCachedDirectory) {
        [defaultManager removeItemAtURL:cachedFile error:&error];
    }
    [defaultManager removeItemAtURL:cachedDirectory error:&error];
}

#pragma mark - MFMailComposeViewController delegate protocol

- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {

    [self dismissViewControllerAnimated: YES
                             completion: nil];
    [error presentErrorOnViewController: self];

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

- (void)collectionView:(UICollectionView *)collectionView willDisplaySupplementaryView:(UICollectionReusableView *)view forElementKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath {
    
    switch (indexPath.section) {
        case 0:
            ((MADOpenFileSectionHeaderView *)view).sectionType = MACloudManagerSectionLocal;
            break;
        case 1:
            
            if ([elementKind isEqualToString:UICollectionElementKindSectionHeader]) {
                self.headerCloud = (MADOpenFileSectionHeaderView *)view;
            }

            ((MADOpenFileSectionHeaderView *)view).sectionType = MACloudManagerSectionCloud;
            break;
            
        default:
            break;
    }
    
}

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
        image = [MTTableViewCellDocument defaultThumbnail];
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
        image = [MTTableViewCellDocument defaultThumbnail];
    }
    [cell normalizeTint];
    cell.imagePreview.image = image;

}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSURL *fileUrl = [self documentForIndexPath:indexPath];
    if ([self isEditing] == NO) {
        [collectionView deselectItemAtIndexPath:indexPath animated:YES];
        
        [self openFileWithUrl:fileUrl];

    } else {
        [collectionView selectItemAtIndexPath:indexPath animated:YES scrollPosition:UICollectionViewScrollPositionCenteredVertically];
    }
    [self selectionsUpdated];

    MTCollectionViewCellDocument *cell = (MTCollectionViewCellDocument *)[collectionView cellForItemAtIndexPath:indexPath];
    [cell performSelectionAnimations];
    [cell normalizeTint];
    
    NSURL *url = [MADocument thumbnailUrlForMadUrl:fileUrl];
    NSString *path = [url path];
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:path];
    if (image == nil) {
        image = [MTTableViewCellDocument defaultThumbnail];
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
        image = [MTTableViewCellDocument defaultThumbnail];
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

- (void)openFileWithUrl:(NSURL *)url {
    __weak MADOpenFileViewController *weakself = self;
    MTApplicationInstance *app = [AppDelegate app];
    
    MADocument *document = [[MADocument alloc] initWithFileURL:url];
    app.openFiles.openDocument = document;
    __weak MTApplicationInstance *weakapp = app;
    [self displaySavingReportActivityIndicator];
    
    [document openWithCompletionHandler:^(BOOL success) {
        
        if (success) {
            
            
            weakapp.reportState = MTReportStateOpen;
            
            if ([MTApplicationInstance isMadDesigner]) {

                [weakself performSegueWithIdentifier: MTSegueShowOpenDocument
                                              sender: weakself];
                
            } else if ([MTApplicationInstance isMadViewer]) {
                
                [weakself performSegueWithIdentifier: MTSegueOpenInViewer
                                              sender: weakself];
                
            }
        }
        
        [weakself reenable];

    }];
    
}

#pragma mark - UICollectionViewFlowLayoutDelegate

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    MADMetaData *metadata = [[MACloudManager sharedManager] metadataForItemAtLocation: indexPath.item
                                                                            inSection: cloudManagerSectionForDisplaySection(indexPath.section)];
    NSURL *url = metadata.url;
    NSString *filename = [MADocument fileNameForMadUrl:url];
    
    
    
    NSDictionary *attributes = [MTCollectionViewCellDocument attributes];

    
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString: filename
                                                                           attributes: attributes];
    self.testLabel.frame = [MADOpenFileViewController cellLabelRect];
    self.testLabel.attributedText = attributedString;
    self.testLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.testLabel.contentScaleFactor = self.collectionView.contentScaleFactor;
    [self.testLabel sizeToFit];
    
    return CGSizeMake(140.0000f, 128.0000f + ceil(self.testLabel.frame.size.height) + 20.0000f);
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return [MACloudManager sharedManager].cloudAvailble ? 2 : 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView
    numberOfItemsInSection:(NSInteger)section {
    
    switch (section) {
        
        case 0:
            return self.documentsLocal.count;
            break;

        case 1:
            return self.documentsCloud.count;
            break;
            
        default:
            return 0;
            break;
    }
}

- (NSUInteger)dataSourceCount {
    return self.documentsLocal.count + self.documentsCloud.count;
}

static MACloudManagerSection cloudManagerSectionForDisplaySection(NSUInteger displaySection);
static MACloudManagerSection cloudManagerSectionForDisplaySection(NSUInteger displaySection) {
    switch (displaySection) {
            
        case 0:
            return MACloudManagerSectionLocal;
            break;
            
        case 1:
            return MACloudManagerSectionCloud;
            break;
            
        default:
            return MACloudManagerSectionLocal;
            break;
    }
}

- (UICollectionViewCell *)collectionView: (UICollectionView *)collectionView
                  cellForItemAtIndexPath: (NSIndexPath *)indexPath {

    MTCollectionViewCellDocument *cell = [collectionView dequeueReusableCellWithReuseIdentifier: MTCollectionViewCellDocumentIdentifier
                                                                                   forIndexPath: indexPath];
    
    MADMetaData *metadata = [[MACloudManager sharedManager] metadataForItemAtLocation: indexPath.item
                                                                            inSection: cloudManagerSectionForDisplaySection(indexPath.section)];
    NSURL *url = metadata.url;
    
    if (cell.delegate == nil) {
        cell.delegate =  self;
                
    }
    
    NSString *filename = [MADocument fileNameForMadUrl:url];
    cell.text = filename;
    cell.labelTitle.text = filename;
    [cell.labelTitle layoutIfNeeded];
    //[cell sizeToFit];
    [cell loadPreviewImageForUrl:url];
    
    if (self.isEditing) {
        [cell startWobble];
    }
    
    if (self.isSavingActivityIndicatorVisible == NO) {

        [cell.activityIndicator stopAnimating];

    } else {
        
        MTApplicationInstance *app = [AppDelegate app];
        NSComparisonResult comparionResult = [app.openFiles.openUrl.lastPathComponent caseInsensitiveCompare: url.lastPathComponent];
        if (comparionResult == NSOrderedSame) {
            [cell.activityIndicator startAnimating];
        } else {
            [cell.activityIndicator stopAnimating];
        }
    
    }

    [cell normalizeTint];
    
    return cell;
}

#pragma mark - Misc

#pragma mark Edit Mode

- (void)activateEditMode:(UILongPressGestureRecognizer *)sender {

    if ([sender state] == UIGestureRecognizerStateBegan) {

        if ([self editModeEnabled] == NO) {
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

- (void)endEditMode:(UITapGestureRecognizer *)sender {

    [self.searchBar resignFirstResponder];
    if ([self editModeEnabled]) {
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
    for (NSIndexPath *path in self.collectionView.indexPathsForVisibleItems) {
        MTCollectionViewCellDocument *cell = (MTCollectionViewCellDocument *)[self.collectionView cellForItemAtIndexPath:path];
        [cell.activityIndicator stopAnimating];
    }
    [self reenableDataWithSearch];
}

- (void)displaySavingReportActivityIndicator {
    [self setSavingActivityIndicatorVisible:YES];
    for (NSIndexPath *path in self.collectionView.indexPathsForVisibleItems) {
        NSURL *visibleUrl = [self documentForIndexPath:path];
        MTApplicationInstance *app = [AppDelegate app];
        BOOL animate = [app.openFiles.openUrl.lastPathComponent caseInsensitiveCompare:visibleUrl.lastPathComponent] == NSOrderedSame;
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
                UIImage *defaultThumbnail = [MTTableViewCellDocument defaultThumbnail];
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
            self.barButtonItemTrash.enabled = NO;
            self.barButtonItemDuplicate.enabled = NO;
            self.barButtonItemAction.enabled = NO;
            break;
        case 1:
            self.barButtonItemTrash.enabled = YES;
            self.barButtonItemDuplicate.enabled = YES;
            self.barButtonItemAction.enabled = YES;
            break;
        default:
            self.barButtonItemTrash.enabled = YES;
            self.barButtonItemDuplicate.enabled = YES;
            self.barButtonItemAction.enabled = NO;
            break;
    }
}

#pragma mark - Actions

- (IBAction)download:(id)sender {
    NSArray *documentTypes = @[MADUtiType];
    UIDocumentPickerViewController *vc = [[UIDocumentPickerViewController alloc] initWithDocumentTypes: documentTypes
                                                                                                inMode: UIDocumentPickerModeImport];
    vc.delegate = self;
    [self presentViewController:vc animated:YES completion:^{}];
}

#pragma mark - UIDocumentPickerDelegate

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentAtURL:(NSURL *)url {
    
    [controller removeFromParentViewController];
}

- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller {
    [controller removeFromParentViewController];
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
            [self animateUpdates];
            //[self reloadData];
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

- (IBAction)done:(id)sender { }

- (IBAction)edit:(id)sender {
    
    BOOL startEdit = ![self isEditing];
    [self setEditing:startEdit animated:YES];
    
    if (startEdit) {
        self.editModeEnabled = YES;
        self.barButtonItemLicensing.enabled = NO;
        self.barButtonItemAddNewDocument.enabled = NO;
        self.barButtonItemAbout.enabled = NO;
        self.barButtonItemInformation.enabled = NO;
        self.collectionView.allowsMultipleSelection = YES;
        
        for (NSIndexPath *path in self.collectionView.indexPathsForVisibleItems) {
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

        self.editModeEnabled = NO;
        self.barButtonItemLicensing.enabled = YES;
        self.barButtonItemAddNewDocument.enabled = YES;
        self.barButtonItemAbout.enabled = YES;
        self.barButtonItemInformation.enabled = YES;
        
        self.barButtonItemTrash.enabled = NO;
        self.barButtonItemDuplicate.enabled = NO;
        self.barButtonItemAction.enabled = NO;
        
        self.collectionView.allowsMultipleSelection = NO;
        
        [self.navigationItem setRightBarButtonItem:self.barButtonItemSearch animated:YES];
        
        NSMutableArray *items = [self.toolbarItems mutableCopy];
        [items removeObject:self.barButtonItemEditDone];
        [items addObject:self.barButtonItemEdit];
        [self setToolbarItems:items animated:YES];

        for (NSIndexPath *path in self.collectionView.indexPathsForVisibleItems) {
            [self.collectionView deselectItemAtIndexPath:path animated:YES];
            MTCollectionViewCellDocument *cell = (MTCollectionViewCellDocument *)[self.collectionView cellForItemAtIndexPath:path];
            [cell stopWobble];
            [cell performDeselectionAnimations];
            
            NSURL *fileUrl = [self documentForIndexPath:path];
            NSURL *url = [MADocument thumbnailWithBorderUrlForMadUrl:fileUrl];
            NSString *path = [url path];
            UIImage *image = [[UIImage alloc] initWithContentsOfFile:path];
            if (image == nil) {
                image = [MTTableViewCellDocument defaultThumbnail];
            }
            [[cell imagePreview] setImage:image];
        }
    }
}

- (IBAction)info:(id)sender {

    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MADStoryboardInformationTable" bundle:[NSBundle mainBundle]];
    UINavigationController *infoViewController = [storyboard instantiateViewControllerWithIdentifier: @"MADIdentifierInformationNavigationController"];
    infoViewController.modalPresentationStyle = UIModalPresentationPopover;
    UIPopoverPresentationController *ppc = infoViewController.popoverPresentationController;
    
    ppc.backgroundColor = [UIColor clearColor];
    ppc.delegate = self;
    ppc.barButtonItem = sender;
    self.aboutPopoverPresentationController = ppc;
    
    [self presentViewController: infoViewController
                       animated: YES
                     completion: nil];

}

- (IBAction)about:(id)sender {
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MADStoryboardAboutTable" bundle:[NSBundle mainBundle]];
    UITableViewController *aboutViewController = [storyboard instantiateViewControllerWithIdentifier: @"MADIdentifierAboutViewController"];
    
    aboutViewController.modalPresentationStyle = UIModalPresentationPopover;
    UIPopoverPresentationController *ppc = aboutViewController.popoverPresentationController;

    ppc.backgroundColor = [UIColor clearColor];
    ppc.delegate = self;
    ppc.barButtonItem = sender;
    self.aboutPopoverPresentationController = ppc;

    [self presentViewController: aboutViewController
                       animated: YES
                     completion: nil];
}

- (void)cut:(id)sender {
    [super cut:sender];
}

- (void)copy:(id)sender {
    [super copy:sender];
}

- (IBAction)activity:(id)sender {
    NSMutableArray *wrappedUrls = [[NSMutableArray alloc] initWithCapacity:[self dataSourceCount]];
    for (NSIndexPath *selectedCellLocation in self.collectionView.indexPathsForSelectedItems) {
        NSURL *fileUrl = [self documentForIndexPath:selectedCellLocation];
        [wrappedUrls addObject:fileUrl];
    }
    for (NSIndexPath *visibleCellLocations in self.collectionView.indexPathsForVisibleItems) {
        MTCollectionViewCellDocument *documentCell = (MTCollectionViewCellDocument *)[self.collectionView cellForItemAtIndexPath:visibleCellLocations];
        if (documentCell != nil) {
            [documentCell normalizeTint];
        }
    }
    
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:wrappedUrls applicationActivities:@[]];
    [activityViewController setExcludedActivityTypes:@[UIActivityTypeAssignToContact, UIActivityTypePostToFacebook, UIActivityTypePostToFlickr, UIActivityTypePostToTwitter, UIActivityTypePostToVimeo]];
    
    
    MADOpenFileViewController *weakSelf = self;
    
    [activityViewController setCompletionWithItemsHandler: ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
        for (NSIndexPath *visibleCellLocations in weakSelf.collectionView.indexPathsForVisibleItems) {
            MTCollectionViewCellDocument *documentCell = (MTCollectionViewCellDocument *)[weakSelf.collectionView cellForItemAtIndexPath:visibleCellLocations];
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

- (IBAction)delete:(id)sender {
    
    self.updatingEnabled = NO;
    
    if (self.collectionView != nil) {
        NSArray *selectedItems = [self.collectionView indexPathsForSelectedItems];
        
        NSMutableArray *urlsToDelete = [[NSMutableArray alloc] init];
        NSMutableDictionary *urlsToDeleteByIndexPath = [[NSMutableDictionary alloc] init];
        
        for (NSIndexPath *selectedItem in selectedItems) {
            NSURL *documentUrl = [self documentForIndexPath:selectedItem];
            [urlsToDelete addObject:documentUrl];
            [urlsToDeleteByIndexPath setObject:documentUrl forKey:selectedItem];
        }
        
        __block NSMutableDictionary *deletedUrlsAndKeys = [[NSMutableDictionary alloc] init];
        
        [urlsToDeleteByIndexPath enumerateKeysAndObjectsUsingBlock:^(id indexPath, id url, BOOL *stop) {
            BOOL success = [[MACloudManager sharedManager] deleteDocument:url];
            if (success) {
                [deletedUrlsAndKeys setObject:url forKey:indexPath];
                
            }
        }];
        
        NSMutableIndexSet *indexSetCloud = [[NSMutableIndexSet alloc] init];
        NSMutableIndexSet *indexSetLocal = [[NSMutableIndexSet alloc] init];
        for (NSIndexPath *path in deletedUrlsAndKeys.allKeys) {
            switch (path.section) {

                case 0:
                    [indexSetLocal addIndex:path.item];
                    break;

                case 1:
                    [indexSetCloud addIndex:path.item];
                    break;
                    
                default:
                    break;
            }
        }
        
        
        __weak MADOpenFileViewController *weakself = self;
        [self.collectionView performBatchUpdates:^{
            __strong MADOpenFileViewController *strongself = weakself;
            [strongself.documentsLocal removeObjectsAtIndexes:indexSetLocal];
            [strongself.documentsCloud removeObjectsAtIndexes:indexSetCloud];
            [strongself.collectionView deleteItemsAtIndexPaths:deletedUrlsAndKeys.allKeys];
        } completion:^(BOOL finished) {
            __strong MADOpenFileViewController *strongself = weakself;
            [[MACloudManager sharedManager] reloadCacheLocal:strongself.searchBar.text];
            [[MACloudManager sharedManager] reloadCacheCloud:strongself.searchBar.text];
            strongself.updatingEnabled = YES;
        }];
        
        
        
        
    } else {
        self.updatingEnabled = YES;
    }
    [self selectionsUpdated];
    
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
    [self reloadData];
    [self selectionsUpdated];
}

NSString * const MADPredicateFormatDuplcate = @"url.lastPathComponent.stringByDeletingPathExtension MATCHES %@";

- (NSString *)uniquieCloudNameForHandle:(NSString *)handle {
    NSString *maybe = handle;
    NSPredicate *predicateMatchesName = [NSPredicate predicateWithFormat:MADPredicateFormatDuplcate, maybe];
    NSArray *filteredArray = [self.documentsCloud filteredArrayUsingPredicate:predicateMatchesName];
    
    NSUInteger ctr = 0;
    while (filteredArray.count > 0) {
        maybe = [maybe stringByAppendingFormat:@" %ld", (long)ctr];
        predicateMatchesName = [NSPredicate predicateWithFormat:MADPredicateFormatDuplcate, maybe];
        filteredArray = [self.documentsCloud filteredArrayUsingPredicate:predicateMatchesName];
        ctr++;
    }
    return maybe;
}

- (void)duplicate:(id)sender {
    self.updatingEnabled = NO;
    
    NSMutableArray *urls = [NSMutableArray new];
    NSArray *selectedItems = [self.collectionView indexPathsForSelectedItems];
    for (NSIndexPath *path in selectedItems) {
        NSURL *url = [self documentForIndexPath:path];
        [urls addObject:url];
        
        switch (path.section) {

            case 0:
                [[MACloudManager sharedManager] duplicateUrl: url];
                break;

            case 1: {
                
                //Unique Cloud name
                NSString *maybe = [self uniquieCloudNameForHandle: url.lastPathComponent.stringByDeletingPathExtension];
                NSURL *toDirectory = [url URLByDeletingLastPathComponent];
                NSURL *toUrl = [toDirectory URLByAppendingPathComponent:maybe];
                NSURL *toUrlWithExtention = [toUrl URLByAppendingPathExtension:@"mad"];
                [[MACloudManager sharedManager] copyUrl:url toUrl:toUrlWithExtention completion:^(BOOL success, NSURL *url , NSError *error) {
                    
                }];
                break;
            }
                
            default:
                break;
        }
    }
    
    if (urls.count > 0) {

        [self animateUpdates];
        
    } else {
    
        self.updatingEnabled = YES;

    }
    
    [self selectionsUpdated];
}

- (void)animateUpdates {
    
    self.updatingEnabled = NO;
    [[MACloudManager sharedManager] reloadCacheLocal:self.searchBar.text];
    [[MACloudManager sharedManager] reloadCacheCloud:self.searchBar.text];
    
    //NSMutableArray *insertedIndexPaths = [[NSMutableArray alloc] init];
    
    NSArray *updatedLocalUrlsOrdered = [MACloudManager sharedManager].documentCacheLocalUrls;
    NSArray *updatedCloudUrlsOrdered = [MACloudManager sharedManager].documentCacheCloudMetaDataItems;

    NSMutableArray *insertedIndexPathsLocal = [[NSMutableArray alloc] initWithCapacity:updatedLocalUrlsOrdered.count];
    NSMutableArray *insertedIndexPathsCloud = [[NSMutableArray alloc] initWithCapacity:updatedCloudUrlsOrdered.count];
    NSMutableArray *deletedIndexPathsLocal = [[NSMutableArray alloc] initWithCapacity:self.documentsLocal.count];
    NSMutableArray *deletedIndexPathsCloud = [[NSMutableArray alloc] initWithCapacity:self.documentsCloud.count];
    
    NSSet *updatedLocalUrls = [NSMutableSet setWithArray: updatedLocalUrlsOrdered];
    NSSet *updatedCloudUrls = [NSMutableSet setWithArray: updatedCloudUrlsOrdered];
    
    NSSet *localUrls = [NSSet setWithArray:self.documentsLocal];
    NSSet *cloudUrls = [NSSet setWithArray:self.documentsCloud];
    
    NSMutableSet *deletedLocalUrls = [NSMutableSet setWithSet:localUrls];
    [deletedLocalUrls minusSet:updatedLocalUrls];
    
    NSMutableSet *deletedCloudUrls = [NSMutableSet setWithSet:cloudUrls];
    [deletedCloudUrls minusSet:updatedCloudUrls];
    
    NSMutableSet *insertedLocalUrls = [NSMutableSet setWithSet:updatedLocalUrls];
    [insertedLocalUrls minusSet:localUrls];
    
    NSMutableSet *insertedCloudUrls = [NSMutableSet setWithSet:updatedCloudUrls];
    [insertedCloudUrls minusSet:cloudUrls];

    //Pre populate deleted indexes local
    for (NSUInteger item=0; item<self.documentsLocal.count;item++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:0];
        [deletedIndexPathsLocal addObject:indexPath];
    }

    //Remove indexes of items that still exist
    for (NSURL *updatedLocalUrl in updatedLocalUrlsOrdered) {
        NSUInteger index = NSNotFound;
        NSUInteger ctr = 0;
        for (NSURL *url in self.documentsLocal) {
            if ([[url.path.lastPathComponent stringByDeletingPathExtension] isEqualToString:[updatedLocalUrl.path.lastPathComponent stringByDeletingPathExtension]]) {
                index = ctr;
                break;
            }
            ctr++;
        }
        if (index != NSNotFound) {
            NSIndexPath *path = [NSIndexPath indexPathForItem:index inSection:0];
            [deletedIndexPathsLocal removeObjectIdenticalTo:path];
        }
    }

    //Pre populate deleted indexes cloud
    for (NSUInteger item=0; item<self.documentsCloud.count;item++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:1];
        [deletedIndexPathsCloud addObject:indexPath];
    }

    //Remove indexes of items that still exist
    for (MADMetaData *updatedData in updatedCloudUrlsOrdered) {
        
        NSUInteger index = NSNotFound;
        NSUInteger ctr = 0;
        for (MADMetaData *metad in self.documentsCloud) {
            NSString *path1 = [metad.url.path.lastPathComponent stringByDeletingPathExtension];
            NSString *path2 = [updatedData.url.path.lastPathComponent stringByDeletingPathExtension];
            if ([path1 isEqualToString:path2]) {
                index = ctr;
                break;
            }
            ctr++;
        }
        if (index != NSNotFound) {
            NSIndexPath *path = [NSIndexPath indexPathForItem:index inSection:1];
            [deletedIndexPathsCloud removeObjectIdenticalTo:path];
        }
    }

    //Pre populate inserted indexes local
    for (NSUInteger item=0; item<updatedLocalUrlsOrdered.count;item++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:0];
        [insertedIndexPathsLocal addObject:indexPath];
    }
    
    //Remove indexes of items that still exist
    for (NSURL *localUrl in self.documentsLocal) {
        NSUInteger index = NSNotFound;
        NSUInteger ctr = 0;
        for (NSURL *url in updatedLocalUrlsOrdered) {
            if ([[url.path.lastPathComponent stringByDeletingPathExtension] isEqualToString:[localUrl.path.lastPathComponent stringByDeletingPathExtension]]) {
                index = ctr;
                break;
            }
            ctr++;
        }
        if (index != NSNotFound) {
            NSIndexPath *path = [NSIndexPath indexPathForItem:index inSection:0];
            [insertedIndexPathsLocal removeObjectIdenticalTo:path];
        }
    }

    //Pre populate inserted indexes cloud
    for (NSUInteger item=0; item<updatedCloudUrlsOrdered.count;item++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:1];
        [insertedIndexPathsCloud addObject:indexPath];
    }
    
    //Remove indexes of items that still exist
    for (MADMetaData *data in self.documentsCloud) {
        
        NSUInteger index = NSNotFound;
        NSUInteger ctr = 0;
        for (MADMetaData *metad in updatedCloudUrlsOrdered) {
            NSString *path1 = [metad.url.path.lastPathComponent stringByDeletingPathExtension];
            NSString *path2 = [data.url.path.lastPathComponent stringByDeletingPathExtension];
            if ([path1 isEqualToString:path2]) {
                index = ctr;
                break;
            }
            ctr++;
        }

        if (index != NSNotFound) {
            NSIndexPath *path = [NSIndexPath indexPathForItem:index inSection:1];
            [insertedIndexPathsCloud removeObjectIdenticalTo:path];
        }
    }

    NSArray *insertedIndexPathsCumulative = [insertedIndexPathsCloud arrayByAddingObjectsFromArray:insertedIndexPathsLocal];
    NSArray *deletedIndexPathsCumulative = [deletedIndexPathsCloud arrayByAddingObjectsFromArray:deletedIndexPathsLocal];
    
    __weak MADOpenFileViewController *weakself = self;
    [self.collectionView performBatchUpdates:^{
        __strong MADOpenFileViewController *strongself = weakself;
        [strongself.documentsLocal setArray:updatedLocalUrlsOrdered];
        [strongself.documentsCloud setArray:updatedCloudUrlsOrdered];

        [strongself.collectionView insertItemsAtIndexPaths:insertedIndexPathsCumulative];
        [strongself.collectionView deleteItemsAtIndexPaths:deletedIndexPathsCumulative];
        
    } completion:^(BOOL finished) {
        __strong MADOpenFileViewController *strongself = weakself;
        strongself.updatingEnabled = YES;
    }];

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
    NSString *title = NSLocalizedString(@"Rename Document", @"Rename Document");
    NSString *cancel = NSLocalizedString(@"Cancel", @"Cancel");
    NSString *rename = NSLocalizedString(@"Rename", @"Rename");
    NSString *message = NSLocalizedString(@"Please enter a new name for the document.", @"Please enter a new name for the document.");
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle: title
                                                                   message: message
                                                            preferredStyle: UIAlertControllerStyleAlert];
    
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cellDocument];
    
    [self setRightBarButtonItemActivityIndicatorVisible:YES];

    __weak MADOpenFileViewController *weakself = self;
    UIAlertAction *actionDefault = [UIAlertAction actionWithTitle: rename
                                                            style: UIAlertActionStyleDefault
                                                          handler: ^(UIAlertAction *action) {
                                                              
                                                              __strong MADOpenFileViewController *strongself = weakself;
                                                              
                                                              UITextField *textField = alert.textFields.firstObject;
                                                              NSString *text = [weakself renameFilter:textField.text];
                                                              
                                                              if (text.length > 0) {
                                                                  
                                                                  NSURL *urlToRename = nil;
                                                                  if (indexPath.item < [weakself dataSourceCount]) {
                                                                      NSIndexPath *pathToMove = [NSIndexPath indexPathForItem: indexPath.item
                                                                                                                    inSection: indexPath.section];
                                                                      urlToRename = [weakself documentForIndexPath:pathToMove];
                                                                      NSString *maybe;
                                                                      if (indexPath.section == 0) {
                                                                          maybe = textField.text;
                                                                      } else {
                                                                          maybe = [strongself uniquieCloudNameForHandle: textField.text];
                                                                      }
                                                                      
                                                                      NSURL *newUrl = [[MACloudManager sharedManager] uniqueUrlForDocumentWithName: maybe
                                                                                                                                     withExtension: MTDocumentExtentionMobleApplicationDocument
                                                                                                                                       inContainer: indexPath.section == 0 ? MACloudManagerSectionLocal : MACloudManagerSectionCloud];
                                                                      __weak MADOpenFileViewController *weakself2 = strongself;
                                                                      [[MACloudManager sharedManager] moveDocument: urlToRename
                                                                                                        toLocation: newUrl
                                                                                                        completion: ^(BOOL success, NSError *error) {
                                                                                                            
                                                                                                            [weakself2 setRightBarButtonItemActivityIndicatorVisible: NO];
                                                                                                            
                                                                                                            switch (indexPath.section) {
                                                                                                                    
                                                                                                                case 0:
                                                                                                                    [[NSNotificationCenter defaultCenter] postNotificationName:MADNotificationReloadSectionLocal object:nil];
                                                                                                                    break;
                                                                                                                    
                                                                                                                case 1:
                                                                                                                    break;
                                                                                                                    
                                                                                                                default:
                                                                                                                    break;
                                                                                                                    
                                                                                                            }
                                                                                                            
                                                                                                        }];
                                                                      
                                                                      [weakself removeCachedFileForDocumentUrl:urlToRename];
                                                                  }
                                                                  
                                                              } else {
                                                                  [weakself setRightBarButtonItemActivityIndicatorVisible:NO];
                                                                  [weakself validationError];
                                                              }

                                                          }];
    
    UIAlertAction *actionCancel = [UIAlertAction actionWithTitle: cancel
                                                           style: UIAlertActionStyleCancel
                                                         handler: nil];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {

        textField.text = cellDocument.labelTitle.text;
        textField.clearButtonMode = UITextFieldViewModeAlways;
        textField.delegate = weakself;

    }];

    [alert addAction:actionDefault];
    [alert addAction:actionCancel];

    [self presentViewController:alert animated:YES completion:nil];
    
}

- (NSString *)renameFilter:(NSString *)text {

    NSMutableCharacterSet *characterSet = [[NSMutableCharacterSet alloc] init];
    [characterSet formUnionWithCharacterSet:[NSCharacterSet alphanumericCharacterSet]];
    [characterSet formUnionWithCharacterSet:[NSCharacterSet whitespaceCharacterSet]];
    NSCharacterSet *invertedSet = characterSet.invertedSet;
    NSArray *components = [text componentsSeparatedByCharactersInSet:invertedSet];
    return [components componentsJoinedByString:@""];
    
}

- (void)validationError {

    UIAlertController *alert = [UIAlertController alertControllerWithTitle: @"Validation Error"
                                                                   message: @"Filename not valid."
                                                            preferredStyle: UIAlertControllerStyleAlert];
    
    UIAlertAction *ok = [UIAlertAction actionWithTitle: @"Dismiss"
                                                 style: UIAlertActionStyleDefault
                                               handler: nil];
    [alert addAction:ok];

    [self presentViewController:alert animated:YES completion:nil];

}

- (void)email:(MTCollectionViewCellDocument *)cell {
    
    if ([MFMailComposeViewController canSendMail] == NO) {
        
        UIAlertController *alert = [UIAlertController alertNotConfiguredForEmail];
        [self presentViewController:alert animated:YES completion:nil];
        
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
            NSString *name = [NSString stringWithFormat:@"%@.%@", documentReport.fileName, MTDocumentExtentionMobleApplicationDocument];
            [mailComposer addAttachmentData:data mimeType:MADMimeType fileName:name];
            mailComposer.navigationController.navigationBar.barTintColor = [UIColor tintColorAnalogous4];
            
            if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
                mailComposer.modalPresentationStyle = UIModalPresentationFormSheet;
                mailComposer.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
                mailComposer.providesPresentationContextTransitionStyle = YES;
                mailComposer.modalInPopover = NO;
            }
            
            [weakself presentViewController:mailComposer animated:YES completion:nil];
            
        }
    }

}

@end
