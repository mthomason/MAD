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

#import "MADocument.h"
#import "MACloudManager.h"
#import "MADMetaData.h"

#import "MTCollectionViewCellDocument.h"
#import "MADOpenFileSectionHeaderView.h"

#import "MADViewerController.h"

#import "MTStoreKitController.h"
#import "MTStoreKitController+NonRenewableLicensing.h"

#import "MADDesignerViewController.h"
#import "MADWatermarkView.h"

#import "MTQueryBuilderContainerController.h"

#import "MTViewControllerAbout.h"
#import "MTTableViewCellDocument.h"
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

NSString * const MTSegueOpenInViewer                            = @"MTSegueOpenInViewer";
NSString * const MTSegueShowAddDocument                         = @"showAddDocument";
NSString * const MTSegueShowOpenDocument                        = @"MADSegueOpenDocument";
NSString * const MTCollectionViewCellDocumentIdentifier         = @"MTCollectionViewCellDocumentIdentifier";
NSString * const MTDocumentExtentionPoratableNetworkGraphic     = @"png";
NSString * const MTSegueLicensing                               = @"MTSegueLicensing";
NSString * const MADIdentifierOpenFileSectionHeader             = @"MADIdentifierOpenFileSectionHeader";

@interface MADOpenFileViewController()
    <NSFileManagerDelegate,
        UIPopoverControllerDelegate,
        UICollectionViewDelegate,
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

@property (nonatomic, weak) IBOutlet UICollectionViewFlowLayout *collectionViewFlowLayout;

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

@property (nonatomic, strong) UIPopoverController *openDocumentPopoverController;
@property (nonatomic, strong) UIPopoverController *aboutPopoverController;
@property (nonatomic, strong) UIPopoverController *licensingPopoverController;
@property (nonatomic, strong) UIPopoverController *popoverControllerActivity;

@property (nonatomic, assign) BOOL shouldShowAddDocumentPopover;
@property (nonatomic, assign) BOOL editModeEnabled;
@property (nonatomic, assign) BOOL bothContentControllersDisplayed;

@property (nonatomic, assign, getter = isSavingActivityIndicatorVisible, readwrite) BOOL savingActivityIndicatorVisible;
@property (nonatomic, assign, getter = isRightBarButtonItemActivityIndicatorVisible, readwrite) BOOL rightBarButtonItemActivityIndicatorVisible;

//@property (nonatomic, strong) NSArray *urls;
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) UILabel *labelMadDesigner;

@property (nonatomic, strong) UIBarButtonItem *rightBarButtonItemHolderWhileActivity;

@property (nonatomic, assign) BOOL firstViewWillAppear;

@property (nonatomic, assign) NSUInteger numberOfDocumentsLocal;
@property (nonatomic, assign) NSUInteger numberOfDocumentsCloud;

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
        [[app openDocument] regenThumbnail];
        [app closeReportWithCompletionHandler:^(BOOL success) {
            [weakself reenable];
        }];
    }
    self.shouldShowAddDocumentPopover = YES;
    self.barButtonItemAddNewDocument.enabled = YES;
    
    if ([MTApplicationInstance isMadViewer] && [UIDevice isPad]) {

    } else if ([MTApplicationInstance isMadViewer] && ![UIDevice isPad]) {
    
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
    [self setShouldShowAddDocumentPopover:YES];
    [[self barButtonItemAddNewDocument] setEnabled:YES];
    [super awakeFromNib];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
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

    self.firstViewWillAppear = YES;
    self.rightBarButtonItemActivityIndicatorVisible = NO;

}

#pragma mark - UIViewController

- (void)viewDidLoad {
    
    [self.collectionView registerClass: [MADOpenFileSectionHeaderView class]
            forSupplementaryViewOfKind: UICollectionElementKindSectionHeader
                   withReuseIdentifier: MADIdentifierOpenFileSectionHeader];
    

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

    [self initalizeBackground];

    UIColor *bgColor = [UIColor lightGrayColor];
    self.collectionView.backgroundColor = bgColor;
    
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

    UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectZero];
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
    
    self.collectionView.delegate = self;
    [self initalizeDataSource];

}

- (UILongPressGestureRecognizer *)longPressGestureRecognizer {
    UILongPressGestureRecognizer *longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget: self
                                                                                                             action: @selector(activateEditMode:)];
    longPressGestureRecognizer.delegate = self;
    return longPressGestureRecognizer;
}

- (UITapGestureRecognizer *)tapGestureRecognizer {
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget: self
                                                                                           action: @selector(endEditMode:)];
    tapGestureRecognizer.delegate = self;
    return tapGestureRecognizer;
}

#pragma mark - UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope { }

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [[MACloudManager sharedManager] reloadDocumentCacheWithSearchString:searchText];
    /*
    if (searchText.length > 0) {
        NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
            
            NSRange range = NSMakeRange(0, MIN(searchText.length, ((NSURL *)evaluatedObject).path.lastPathComponent.length));
            return [((NSURL *)evaluatedObject).path.lastPathComponent compare:searchText
                                                                      options: NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch
                                                                        range:range] == NSOrderedSame;
        }];
    //    self.urls = [[[MACloudManager sharedManager] hasMadDocuments] filteredArrayUsingPredicate:predicate];
        NSIndexSet *set = [NSIndexSet indexSetWithIndex:0];
        
        __weak UICollectionView *weakCollectionView = self.collectionView;
        [self.collectionView performBatchUpdates:^{
            [weakCollectionView reloadSections:set];
        } completion:nil];
    } else {
        [self reloadData];
    }
     */
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar { }

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    if (self.searchBar.text.length > 0) {
        self.searchBar.text = @"";
        [self reloadData];
    }
    [searchBar resignFirstResponder];
    [self search:self];     //Hides the search bar
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [[MACloudManager sharedManager] startQuery];
    
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
    
    [MADOpenFileViewController initalizeMenuController];
    
    [[MTStoreKitController sharedObject] licensedUser:^(BOOL isLicensedUser, NSDate *experationDate) {
        if (isLicensedUser) {
            [MADOpenFileViewController initalizeMenuControllerEmail];
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
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:0];
        [self.collectionView deselectItemAtIndexPath:indexPath animated:YES];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[MACloudManager sharedManager] stopQuery];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self.navigationItem.titleView sizeToFit];
    [self.collectionView.backgroundView setNeedsDisplay];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    __weak UICollectionViewController *weakSelf = self;
    [UIView animateWithDuration:duration delay:0.0000f options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        [weakSelf.collectionView.backgroundView setNeedsDisplay];
    } completion:NULL];
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
    [segue.destinationViewController setDelegate: self];
}

- (void)prepareForSegueDetails:(UIStoryboardSegue *)segue {
    UINavigationController *navigationController = segue.destinationViewController;
    MTViewControllerAbout *aboutViewController = (MTViewControllerAbout *)[navigationController topViewController];
    aboutViewController.delegate = self;
    
    if ([segue.destinationViewController isKindOfClass: [UINavigationController class]]) {
        UINavigationController *navControl = segue.destinationViewController;
        if ([navControl topViewController]) {
            if ([segue isKindOfClass:[UIStoryboardPopoverSegue class]]) {
                [self setAboutPopoverController:[(UIStoryboardPopoverSegue *)segue popoverController]];
            }
        }
    }
    
    if ([UIDevice isPad]) {
        if ([segue.identifier isEqualToString:@"MTSegueDetails"]) {
            if ([MTApplicationInstance isMadViewer]) {
                self.aboutPopoverController.popoverContentSize = CGSizeMake(420.0000f, 376.0000f);
            } else {
                self.aboutPopoverController.popoverContentSize = CGSizeMake(540.0000f, 556.0000f);
            }
        } else {
            self.aboutPopoverController.popoverContentSize = CGSizeMake(320.0000f, 320.0000f);
        }
    }
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
    if ([segue.destinationViewController isKindOfClass: [UINavigationController class]] || [segue.destinationViewController isKindOfClass: [UITabBarController class]]) {
        
        if ([UIDevice isPad]) {
            UITabBarController *tabBarController = (UITabBarController *)segue.destinationViewController;
            tabBarController.view.tintColor = [UIColor tintColorRed];
            
            UINavigationController *navController = (UINavigationController *)[tabBarController viewControllers][0];
            MTQueryBuilderContainerController *queryBuilderContainerController = (MTQueryBuilderContainerController *)[navController topViewController];
            queryBuilderContainerController.delegate = self;
            
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
        [self prepareForSegueDetails:segue];
        
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
        if ([UIDevice isPad]) {
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
    [[self barButtonItemAddNewDocument] setEnabled:YES];
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

- (void)deleteDocumentRepresentedByCell:(MTCollectionViewCellDocument *)cell {
    NSIndexPath *index = [self.collectionView indexPathForCell:cell];
    NSError *error = nil;
    [self deleteDocumentAtIndexPath:index error:&error];
    [self.collectionView deleteItemsAtIndexPaths:@[index]];
}

- (void)viewControllerDidFinish:(id)sender {
    [self setShouldShowAddDocumentPopover:YES];
    MTApplicationInstance *app = [AppDelegate app];
    __weak MADOpenFileViewController *weakself = self;
    [[app openDocument] regenThumbnail];
    [app closeReportWithCompletionHandler:^(BOOL success) {
        [weakself reenable];
    }];
    
    if ([self.openDocumentPopoverController isPopoverVisible]) {
        [self.openDocumentPopoverController dismissPopoverAnimated:YES];
    } else {
        [self dismissViewControllerAnimated:YES completion:^{ }];
    }
    [[self barButtonItemAddNewDocument] setEnabled:YES];
    if ([UIDevice isPad]) {
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
        [[app openDocument] regenThumbnail];
        [app closeReportWithCompletionHandler:^(BOOL success) {
            [weakself reenable];
        }];
    }
    [self setShouldShowAddDocumentPopover:YES];
    [[self barButtonItemAddNewDocument] setEnabled:YES];
    [self.openDocumentPopoverController dismissPopoverAnimated:YES];
    
}

- (void)viewControllerDidCancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.openDocumentPopoverController dismissPopoverAnimated:YES];
    [self setShouldShowAddDocumentPopover:YES];
    [[self barButtonItemAddNewDocument] setEnabled:YES];
}

- (void)viewControllerDidRequestComposeEmail:(id)sender animated:(BOOL)animated {
    if ([UIDevice isPad]) {
        [[self aboutPopoverController] dismissPopoverAnimated:animated];
    }
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController	*mFMailComposeViewController = [[MFMailComposeViewController alloc] init];
        [mFMailComposeViewController setMailComposeDelegate:self];
        [mFMailComposeViewController setToRecipients:@[@"admin@everydayapps.com"]];
        [mFMailComposeViewController setSubject:@"MAD Designer"];
        [[[mFMailComposeViewController navigationController] navigationBar] setBarTintColor:[UIColor tintColorAnalogous4]];
        [self presentViewController:mFMailComposeViewController animated:YES completion:nil];
    } else {
        UIAlertController *alert = [UIAlertController alertNotConfiguredForEmail];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

#pragma mark - Static functions

+ (UIMenuItem *)menuItemRename {
    UIMenuItem *menuItem = [[UIMenuItem alloc] initWithTitle: NSLocalizedString(@"Rename", @"Rename")
                                                      action: @selector(rename:)];
    return menuItem;
}

+ (UIMenuItem *)menuItemEmail {
    UIMenuItem *menuItem = [[UIMenuItem alloc] initWithTitle: NSLocalizedString(@"Email", @"Email")
                                                      action: @selector(email:)];
    return menuItem;
}

+ (UIMenuItem *)menuItemDuplicate {
    UIMenuItem *menuItem = [[UIMenuItem alloc] initWithTitle: NSLocalizedString(@"Duplicate", @"Duplicate")
                                                      action: @selector(duplicate:)];
    return menuItem;
}

#pragma mark - Custom Initalization

- (void)addActionItemToToolbar:(BOOL)animated {
    if ([[self toolbarItems] containsObject:[self barButtonItemAction]] == NO) {
        NSMutableArray *toolbarButtons = [[self toolbarItems] mutableCopy];
        [toolbarButtons insertObject:[self barButtonItemAction] atIndex:1];
        [self setToolbarItems:toolbarButtons animated:animated];
    }
    
}

+ (void)initalizeMenuController {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UIMenuController *menu = [UIMenuController sharedMenuController];
        NSMutableArray *menuItems = [[menu menuItems] mutableCopy];
        if (menuItems == nil) {
            menuItems = [NSMutableArray new];
        }
        [menuItems addObject:[MADOpenFileViewController menuItemRename]];
        [menuItems addObject:[MADOpenFileViewController menuItemDuplicate]];
        [menu setMenuItems:menuItems];
    });
}

+ (void)initalizeMenuControllerEmail {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UIMenuController *menu = [UIMenuController sharedMenuController];
        NSMutableArray *menuItems = [[menu menuItems] mutableCopy];
        if (menuItems == nil) {
            menuItems = [NSMutableArray new];
        }
        UIMenuItem *menuItem = [MADOpenFileViewController menuItemEmail];
        [menuItems addObject:menuItem];
        [menu setMenuItems:menuItems];
    });
}

- (void)initalizeBackground {
    UICollectionView *v = (UICollectionView *)self.collectionView;
    MADWatermarkView *watermarkView = [[MADWatermarkView alloc] initWithFrame:[v bounds]];
    [v setBackgroundView:watermarkView];
}

- (void)initalizeDataSource {
    self.collectionView.dataSource = self;
}

- (NSURL *)urlForDocumentCell:(MTCollectionViewCellDocument *)cellDocument {
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cellDocument];
    return [self documentForIndexPath:indexPath];
}

- (void)reloadData {
    NSLog(@"Reload Data");
    
    self.numberOfDocumentsLocal = [[MACloudManager sharedManager] numberOfDocuments:MACloudManagerSectionLocal];
    self.numberOfDocumentsCloud = [[MACloudManager sharedManager] numberOfDocuments:MACloudManagerSectionCloud];
    
//    self.urls = [[MACloudManager sharedManager] hasMadDocuments];
    [self.collectionView reloadData];
}

- (NSURL *)documentForIndexPath:(NSIndexPath *)indexPath {
    MADMetaData *metadata = [[MACloudManager sharedManager] metadataForItemAtLocation: indexPath.item
                                                                            inSection: cloudManagerSectionForDisplaySection(indexPath.section)];
    
    return metadata.url;
}

- (void)deleteDocumentAtIndexPath:(NSIndexPath *)index error:(NSError **)error {
    NSURL *documentUrl = [self documentForIndexPath:index];
    [self removeCachedFileForDocumentUrl:documentUrl];
    [[NSFileManager defaultManager] removeItemAtURL:documentUrl error:error];
    if (*error != nil) {
        [*error presentErrorOnViewController:self];
    }
}

- (void)removeCachedFileForDocumentUrl:(NSURL *)documentUrl {
    NSError *error = nil;
    NSFileManager *defaultManager = [NSFileManager defaultManager];
    NSURL *cachedDirectory = [defaultManager localCachedDirectoryForFileUrl:documentUrl];
    NSArray *contentsOfDirectoryAtUrlCachedDirectory = [defaultManager contentsOfDirectoryAtURL:cachedDirectory includingPropertiesForKeys:nil options:0 error:&error];
    for (NSURL *cachedFile in contentsOfDirectoryAtUrlCachedDirectory) {
        [defaultManager removeItemAtURL:cachedFile error:&error];
    }
    [defaultManager removeItemAtURL:cachedDirectory error:&error];
}

#pragma mark - MFMailComposeViewController delegate protocol

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [self dismissViewControllerAnimated:YES completion:nil];
    [error presentErrorOnViewController:self];
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

- (void)scrollViewDidScroll:(UIScrollView *)scrollView { }

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
            headerView.sectionType = MACloudManagerSectionLocal;
            break;

        case 1:
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
            ((MADOpenFileSectionHeaderView *)view).sectionType = MACloudManagerSectionCloud;
            break;
            
        default:
            break;
    }
    
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingSupplementaryView:(UICollectionReusableView *)view forElementOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath { }

- (void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    
    [self selectionsUpdated];
    MTCollectionViewCellDocument *cell = (MTCollectionViewCellDocument *)[collectionView cellForItemAtIndexPath:indexPath];
    [cell performSelectionAnimations];
    
    NSURL *fileUrl = [self documentForIndexPath:indexPath];
    NSURL *url = [MADocument thumbnailUrlForMadUrl:fileUrl];
    NSString *path = [url path];
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:path];
    if (image == nil) {
        image = [MTTableViewCellDocument defaultThumbnail];
    }
    [[cell imagePreview] setImage:image];
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
    
    [[MACloudManager sharedManager] stopQuery];

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
            
        } else {
            
            [[MACloudManager sharedManager] startQuery];

        }
        
        [weakself reenable];

    }];
    
}

#pragma mark - UICollectionViewFlowLayoutDelegate

//- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView
                        layout:(UICollectionViewLayout*)collectionViewLayout
        insetForSectionAtIndex:(NSInteger)section {

    return [UIDevice isPad] ? UIEdgeInsetsMake(25.0000f, 25.0000f, 25.0000f, 25.0000f) :
                                UIEdgeInsetsMake(5.0000f, 5.0000f, 5.0000f, 5.0000f);

}

- (CGFloat)collectionView:(UICollectionView *)collectionView
                   layout:(UICollectionViewLayout*)collectionViewLayout
minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    
    return [UIDevice isPad] ? 50.0000f : 5.0000f;
    
}

- (CGFloat)collectionView:(UICollectionView *)collectionView
                   layout:(UICollectionViewLayout*)collectionViewLayout
                    minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {

    return [UIDevice isPad] ? 50.0000f : 5.0000f;

}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
referenceSizeForHeaderInSection:(NSInteger)section {
    
    return CGSizeMake(collectionView.bounds.size.width, 24.0000f);
    
}

//- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section;


#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 2;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView
    numberOfItemsInSection:(NSInteger)section {
    
    switch (section) {
        
        case 0:
            return self.numberOfDocumentsLocal;
            break;

        case 1:
            return self.numberOfDocumentsCloud;
            break;
            
        default:
            return 0;
            break;
    }
}

- (NSUInteger)dataSourceCount {
    return self.numberOfDocumentsLocal + self.numberOfDocumentsCloud;
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

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {

    MTCollectionViewCellDocument *cell = [collectionView dequeueReusableCellWithReuseIdentifier:MTCollectionViewCellDocumentIdentifier
                                                                                   forIndexPath:indexPath];
    
    MADMetaData *metadata = [[MACloudManager sharedManager] metadataForItemAtLocation: indexPath.item
                                                                            inSection: cloudManagerSectionForDisplaySection(indexPath.section)];
    NSURL *url = metadata.url;
    
    if (cell.delegate == nil) {
        cell.delegate =  self;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget: self
                                                                              action: @selector(rename:)];
        tap.numberOfTapsRequired = 1;
        tap.numberOfTouchesRequired = 1;
        [cell.labelTitle addGestureRecognizer:tap];
        cell.labelTitle.userInteractionEnabled = YES;
        
        UILongPressGestureRecognizer *longPressGestureRecognizer = [self longPressGestureRecognizer];
        [cell addGestureRecognizer:longPressGestureRecognizer];
        
    }
    
    [cell configureCellForUrl:url];
    if (self.isEditing) {
        [cell startWobble];
    }
    
    if (self.isSavingActivityIndicatorVisible == NO) {

        [cell.activityIndicator stopAnimating];

    } else {
        
        MTApplicationInstance *app = [AppDelegate app];
        NSComparisonResult comparionResult = [app.openFiles.openUrl.lastPathComponent caseInsensitiveCompare:url.lastPathComponent];
        if (comparionResult == NSOrderedSame) {
            [cell.activityIndicator startAnimating];
        } else {
            [cell.activityIndicator stopAnimating];
        }
    
    }
    
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
    if ([UIDevice isPad]) {

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
        self.searchBar.showsCancelButton = YES;
        
        [self.searchBar sizeToFit];
        self.searchBar.hidden = NO;
        self.searchBar.alpha = 0.0000f;
        self.labelMadDesigner.alpha = 1.0000f;
        [self.navigationItem setRightBarButtonItem:nil animated:YES];
        self.navigationItem.leftBarButtonItem.enabled = NO;
        __weak MADOpenFileViewController *weakself = self;
        [UIView transitionWithView:self.navigationItem.titleView
                          duration:0.2000f
                           options:UIViewAnimationOptionCurveEaseOut animations:^{
            [weakself.searchBar sizeToFit];
            weakself.searchBar.alpha = 1.0000f;
            weakself.labelMadDesigner.alpha = 0.0000f;
            weakself.navigationItem.titleView = weakself.searchBar;
        } completion:^(BOOL finished) {
            if (weakself.searchBar.isFirstResponder == NO) {
                [weakself.searchBar becomeFirstResponder];
            }
        }];
        
    } else {
        if (self.searchBar.text.length > 0) {
            self.searchBar.text = @"";
            [self reloadData];
        }
        self.searchBar.hidden = YES;
        self.searchBar.alpha = 0.1000f;
        self.labelMadDesigner.alpha = 0.0000f;
        [self.navigationItem setRightBarButtonItem:self.barButtonItemSearch animated:YES];
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

- (IBAction)about:(id)sender {
    NSString *applicationName = [[NSBundle mainBundle] infoDictionary][(NSString *)kCFBundleNameKey];
    NSString *title = [NSString stringWithFormat:NSLocalizedString(@"About %@", @"About Mad Designer"),  applicationName];
    NSString *message = NSLocalizedString(@"© Everyday Apps LLC 2014.  Software created by Michael Thomason for Everyday Apps LLC.",
                                          @"© Everyday Apps LLC 2014.  Software created by Michael Thomason for Everyday Apps LLC.");
    NSString *buttonTitle = NSLocalizedString(@"Continue", @"Continue");
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle: title
                                                                             message: message
                                                                      preferredStyle: UIAlertControllerStyleAlert];
    UIAlertAction *actionKk = [UIAlertAction actionWithTitle: buttonTitle
                                                       style: UIAlertActionStyleDefault
                                                     handler: ^(UIAlertAction *action) {}];
    [alertController addAction:actionKk];
    [self presentViewController: alertController
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
        [[UINavigationBar appearance] setBarTintColor:[UIColor tintColorBlue]];
        
        for (NSIndexPath *visibleCellLocations in weakSelf.collectionView.indexPathsForVisibleItems) {
            MTCollectionViewCellDocument *documentCell = (MTCollectionViewCellDocument *)[weakSelf.collectionView cellForItemAtIndexPath:visibleCellLocations];
            if (documentCell != nil) {
                [documentCell normalizeTint];
            }
        }
    }];
    
    if ([UIDevice isPad]) {
        if (self.popoverControllerActivity == nil || self.popoverControllerActivity.isPopoverVisible == NO) {
            UIPopoverController *popoverController = [[UIPopoverController alloc] initWithContentViewController:activityViewController];
            popoverController.delegate = self;
            [popoverController presentPopoverFromBarButtonItem: self.barButtonItemAction
                                      permittedArrowDirections: UIPopoverArrowDirectionAny
                                                      animated: YES];
            [self setPopoverControllerActivity:popoverController];
        }
    } else {
        [self presentViewController:activityViewController animated:YES completion:^{
            [[UINavigationBar appearance] setBarTintColor:[UIColor tintColorAnalogous4]];
        }];
    }
}

- (IBAction)delete:(id)sender {
    if (self.collectionView != nil) {
        NSMutableArray *itemsToDelete = [[NSMutableArray alloc] init];
        NSMutableArray *urlsToDelete = [[NSMutableArray alloc] init];
        for (NSIndexPath *selectedItem in [self.collectionView indexPathsForSelectedItems]) {
            [itemsToDelete addObject:selectedItem];
            NSURL *url = [self documentForIndexPath:selectedItem];
            [urlsToDelete addObject:url];
        }

        NSFileManager *fileManager = [NSFileManager defaultManager];
        for (NSURL *url in urlsToDelete) {
            NSError *error = nil;
            [self removeCachedFileForDocumentUrl:url];
            [fileManager removeItemAtURL:url error:&error];
        }
        [self reloadData];
    }
    [self selectionsUpdated];
}

- (void)paste:(id)sender {
    NSURL *url = [[UIPasteboard generalPasteboard] URL];
    NSData *data = [[NSData alloc] initWithContentsOfURL:url];
    NSFileWrapper *fileWrapper = [[NSFileWrapper alloc] initWithSerializedRepresentation:data];
    NSString *name = [[url lastPathComponent] stringByDeletingPathExtension];
    NSURL *destinationUrl = [[MACloudManager sharedManager] uniqueUrlForDocumentWithName: name
                                                                           withExtension: MTDocumentExtentionMobleApplicationDocument];
    
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

- (void)duplicate:(id)sender {
    NSMutableArray *urls = [NSMutableArray new];
    MTCollectionViewCellDocument *cellDocument;
    if ([sender isKindOfClass:[MTCollectionViewCellDocument class]]) {
        cellDocument = sender;
        NSAssert(cellDocument != nil, @"Null cell at %s.", __PRETTY_FUNCTION__);
        NSIndexPath *indexPath = [self.collectionView indexPathForCell:cellDocument];
        NSURL *url = [self documentForIndexPath:indexPath];
        [urls addObject:url];
    } else if ([sender isKindOfClass:[UIBarButtonItem class]]) {
        for (NSIndexPath *path in [self.collectionView indexPathsForSelectedItems]) {
            NSURL *url = [self documentForIndexPath:path];
            [urls addObject:url];
        }
    }
    if (urls.count > 0) {
        for (NSURL *url in urls) {
            [[MACloudManager sharedManager] duplicateUrl:url];
        }
        [self reloadData];
    }
    [self selectionsUpdated];
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
    NSInteger itemIndex = indexPath.item;
    __weak MADOpenFileViewController *weakself = self;
    UIAlertAction *actionDefault = [UIAlertAction actionWithTitle: rename
                                                            style: UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction *action) {
                                                              
                                                              UITextField *textField = alert.textFields.firstObject;
                                                              NSString *text = [weakself renameFilter:textField.text];
                                                              
                                                              if (text.length > 0) {
                                                                  
                                                                  NSURL *urlToRename = nil;
                                                                  if (itemIndex < [weakself dataSourceCount]) {
                                                                      NSIndexPath *pathToMove = [NSIndexPath indexPathForItem:itemIndex inSection:0];
                                                                      urlToRename = [weakself documentForIndexPath:pathToMove];
                                                                      NSURL *newUrl = [[MACloudManager sharedManager] uniqueUrlForDocumentWithName: textField.text
                                                                                                                                     withExtension: MTDocumentExtentionMobleApplicationDocument];
                                                                      [[MACloudManager sharedManager] moveDocument:urlToRename
                                                                                                        toLocation:newUrl];
                                                                      
                                                                      [weakself removeCachedFileForDocumentUrl:urlToRename];
                                                                  }
                                                                  
                                                              } else {
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
    
    return [[text componentsSeparatedByCharactersInSet:[characterSet invertedSet]] componentsJoinedByString:@""];

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
            
            if ([UIDevice isPad]) {
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
