//
//  MADDesignerFileExplorerViewController.m
//  MAD Designer
//
//  Created by Michael Thomason on 9/21/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADDesignerFileExplorerViewController.h"
#import <MAD/MADCredential.h>
#import <MADFoundation/MADApplicationProtocol.h>
#import <MADFoundation/UIApplication+MADAppDelegate.h>

#import "MADStoryboard.h"

#import <MAD/MADConstants.h>
#import "Constants.h"

#import "MTStoreKitController.h"
#import "MTStoreKitController+Features.h"
#import "MUIViewControllerDelegate.h"
#import "MADQueryBuilderSplitViewController.h"
#import "MADViewerController.h"
#import "MADDesignerViewController.h"
#import "MADQueryViewController.h"
#import "MTDatabaseDriverSelectorViewController.h"
#import "MADStoreViewController.h"

#import "MADDocumentInformationTableViewController.h"
#import "MADDocumentInformationTableViewController+Designer.h"

#import "MADNavigationBarTitleView.h"
#import "MADWatermarkView.h"

#import "MADNavigationController.h"

#import <MADExplorer/MADFileLocationManager.h>
#import <MADExplorer/MADOpenDocumentManager.h>

#import "UIStoryboard+Query.h"
#import "UINavigationController+MADQuery.h"
#import "UINavigationController+Designer.h"
#import "UITabBarController+Shared.h"
#import "UITableViewController+Designer.h"
#import "MADQueryBuilderSplitViewController.h"
#import "MADQueryVisualizationViewController.h"
#import "MADTabBarController.h"

NSString * const MTSegueOpenInViewer                            = @"MTSegueOpenInViewer";
NSString * const MTSegueShowAddDocument                         = @"showAddDocument";
NSString * const MTSegueLicensing                               = @"MTSegueLicensing";

NSString * const MADUtiType                                     = @"com.everydayapps.productivity.mad";

@interface MADDesignerFileExplorerViewController ()
    <UIPopoverControllerDelegate,
        UIPopoverPresentationControllerDelegate,
        MADocumentDelegate,
        MTViewControllerProtocol,
        MADFileLocationManagerDelegate>

    @property (nonatomic, weak)   MADQueryBuilderSplitViewController *splitViewController;

    @property (nonatomic, weak)     IBOutlet UIBarButtonItem *barButtonItemAddNewDocument;
    @property (nonatomic, weak)     IBOutlet UIBarButtonItem *barButtonItemLicensing;

    @property (nonatomic, strong)   UIPopoverController *openDocumentPopoverController;
    @property (nonatomic, strong)   UIPopoverController *licensingPopoverController;

    @property (nonatomic, weak)     UIPopoverPresentationController *infoPopoverPresentationController;
    @property (nonatomic, weak)     UIPopoverPresentationController *aboutPopoverPresentationController;
    @property (nonatomic, weak)     UIPopoverPresentationController *documentInformationPopoverPresentationController;

    @property (nonatomic, assign)   bool shouldShowAddDocumentPopover;
    @property (nonatomic, assign)   bool aboutViewControllerOnScreen;

    @property (nonatomic, weak)   MADTabBarController *tabController;

@end

@implementation MADDesignerFileExplorerViewController

#pragma mark - MADFileLocationManagerDelegate

- (NSString *)groupIdentifier { return MADIdentifierGroup; }

- (NSString *)ubiquityIdentifier { return MADUbiquityIdentifier; }

- (NSString *)fileExtention { return MADFileExtentionMobleApplicationDocument; }

- (void)didConfigureFilesController:(MADFilesController *)filesController { filesController.delegate = self; }

- (UIAlertController *)promotStorageOptionLocal:(void (^)())handlerLocal
                                          cloud:(void (^)())handlerCloud {
    UIAlertController *alert = [UIAlertController newAlertControllerPromptStorageOptionLocal:handlerLocal
                                                                                       cloud:handlerCloud];
    return alert;
}

- (void)didDisconnectFromCloud:(id)sender {
    typeof(self) __weak weakself = self;

    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        MADDesignerFileExplorerViewController *sself = weakself;
        if (sself) {
            id __weak weakself2 = sself;
            UIAlertController *alert = [UIAlertController newAlertControlerNotifyCloudSignOut:^(UIAlertAction *action) {
                MADDesignerFileExplorerViewController *sself2 = weakself2;
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

- (void)awakeFromNib {
    [self.barButtonItemAddNewDocument setEnabled:YES];
    [super awakeFromNib];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        self.filesCoordnator.delegate = self;
        self.shouldShowAddDocumentPopover = true;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    MADNavigationBarTitleView *titleView = [[MADNavigationBarTitleView alloc] initWithFrame: CGRectZero];
    MADAppDelegate delegate = [MADApplication AppDelegate];
    NSString *name = [delegate name];
    titleView.text = name.copy;
    titleView.accessibilityHint = NSLocalizedString(@"MAD Designer is the mobile analytics document designer.", @"MAD Designer is the mobile analytics document designer.");
    titleView.accessibilityTraits = UIAccessibilityTraitHeader;
    
    self.navigationItem.titleView = titleView;
    self.navigationItem.hidesBackButton = YES;
    
    MADWatermarkView *watermarkView = [[MADWatermarkView alloc] initWithFrame: self.collectionView.bounds];
    self.collectionView.backgroundView = watermarkView;

    self.openFileDelegate = self;
    self.aboutViewControllerOnScreen = false;

    self.barButtonItemAddNewDocument.accessibilityHint = NSLocalizedString(@"Adds a new document.", @"Adds a new document.");
    self.barButtonItemLicensing.accessibilityHint = NSLocalizedString(@"Displays the store.", @"Displays the store.");
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    BOOL canMakePayments = [SKPaymentQueue canMakePayments];
    self.barButtonItemLicensing.enabled = canMakePayments;
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.aboutViewControllerOnScreen = false;
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

#pragma mark - UIPopoverControllerDelegate

- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController {
    return [self.openDocumentPopoverController isEqual:popoverController] == NO;
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    self.shouldShowAddDocumentPopover = true;
    [self.barButtonItemAddNewDocument setEnabled:YES];
}

#pragma mark - MTViewControllerProtocol

- (void)viewControllerDidFinish:(id)sender {
    self.shouldShowAddDocumentPopover = true;
    MADTabBarController *tabController = self.tabController;
    [tabController setViewControllers:nil animated:YES];
    [self dismissViewControllerAnimated:YES completion:^{ }];

    self.shouldShowAddDocumentPopover = true;
    self.barButtonItemAddNewDocument.enabled = YES;
    [self.openDocumentPopoverController dismissPopoverAnimated:YES];
    
    UIManagedDocument *openDocument = self.openDocument;
    if (openDocument && openDocument.documentState != UIDocumentStateClosed) {
        self.reportState = MTReportStateClosed;
        [self.fileManager unload];
        [openDocument closeWithCompletionHandler:^(BOOL successClose) {
        
        }];
    }

}

- (void)viewControllerDidCancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.openDocumentPopoverController dismissPopoverAnimated:YES];
    self.shouldShowAddDocumentPopover = true;
    [self.barButtonItemAddNewDocument setEnabled:YES];
}

#pragma mark - MADOpenFileViewControllerDelegate

- (void)documentStateChanged:(NSNotification *)notification {
    if ([notification.name isEqualToString:UIDocumentStateChangedNotification]) {

        MADocument *document = notification.object;
        switch (document.documentState) {

            case UIDocumentStateClosed: {
                if (self.reportState == MTReportStateClosed) {
                    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                                    name: UIDocumentStateChangedNotification
                                                                  object: document];
                }
                id o = [[NSInvocationOperation alloc] initWithTarget:self
                                                            selector:@selector(reloadAfterClose)
                                                              object:nil];
                [[NSOperationQueue mainQueue] addOperation:o];
                NSLog(@"\n\n\tDocument state closed.\n\n");
                break;
            }

            case UIDocumentStateEditingDisabled:
                NSLog(@"\n\n\tDocument state editing disabled.\n\n");
                break;

            case UIDocumentStateInConflict:
                NSLog(@"\n\n\tDocument state in conflict.\n\n");
                break;
                
            case UIDocumentStateNormal:
                if (self.reportState !=  MTReportStateOpen) {
                    SEL open = @selector(openViewerWithDocument:);
                    id o = [[NSInvocationOperation alloc] initWithTarget: self
                                                                selector: open
                                                                  object: document];
                    [[NSOperationQueue mainQueue] addOperation:o];
                    self.reportState = MTReportStateOpen;
                }
                NSLog(@"\n\n\tDocument state normal.\n\n");
                break;

            case UIDocumentStateSavingError:
                NSLog(@"\n\n\tDocument state saving error.\n\n");
                break;

            default:
                break;
        }

    }
}

- (void)reloadAfterClose {
    UICollectionView *weakCollectionView __unsafe_unretained = self.collectionView;
    NSArray <NSIndexPath *> *paths = weakCollectionView.indexPathsForVisibleItems.copy;
    [UIView performWithoutAnimation:^{
        UICollectionView *collectionView = weakCollectionView;
        [collectionView.backgroundView setNeedsDisplay];
        [collectionView reloadItemsAtIndexPaths:paths];
    }];
}

- (void)openViewerWithDocument:(MADocument *)document {
    MADTabBarController *tabBarController = [MADTabBarController mainTabBarController];
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
    MADocument *document = [[MADocument alloc] initWithFileURL:url];
    document.limitResultsDesignMode = [MTStoreKitController sharedObject].isReportingLimited;
    document.documentDelegate = self;
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(documentStateChanged:)
                                                 name: UIDocumentStateChangedNotification
                                               object: document];
    
    self.reportState = MTReportStateClosed;
    self.fileManager.openDocument = document;
    
    id __weak wself = self;
    [document openWithCompletionHandler:^(BOOL success) {
        if (success) {
            MADDesignerFileExplorerViewController *sself = wself;
            @synchronized (sself) {
                sself.reportState = MTReportStateOpen;
            }
        }
    }];

    
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

#pragma mark - Actions

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

- (void)prepareForPopoverPresentation:(UIPopoverPresentationController *)popoverPresentationController { }

- (BOOL)popoverPresentationControllerShouldDismissPopover:(UIPopoverPresentationController *)popoverPresentationController { return YES; }

- (void)popoverPresentationControllerDidDismissPopover:(UIPopoverPresentationController *)popoverPresentationController {
    self.aboutViewControllerOnScreen = false;
}

- (void)popoverPresentationController:(UIPopoverPresentationController *)popoverPresentationController willRepositionPopoverToRect:(inout CGRect *)rect inView:(inout UIView **)view { }

#pragma mark - Convenience

- (NSArray *)defaultPassthroughViews {
    return @[self.navigationController.navigationBar, self.navigationController.toolbar];
}

@end
