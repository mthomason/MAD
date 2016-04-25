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

//#import "MADKeyChainGetCredentials.h"
//#import "MADKeyChainSaveCredentials.h"

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
#import "MADTabBarController.h"

#import <MADExplorer/MADFileLocationManager.h>
#import <MADExplorer/MADOpenDocumentManager.h>

#import "UIStoryboard+Query.h"
#import "UINavigationController+MADQuery.h"
#import "UINavigationController+Designer.h"
#import "UITabBarController+Shared.h"
#import "UITableViewController+Designer.h"

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

    @property (nonatomic, strong)   MADQueryBuilderSplitViewController *splitViewController;

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
    UIAlertController *alert = [UIAlertController promotStorageOptionLocal:handlerLocal cloud:handlerCloud];
    return alert;
}

- (UIAlertController *)promotCloudSignOut:(void (^)(UIAlertAction *action))handler {
    UIAlertController *alert = [UIAlertController promotCloudSignOut:handler];
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
    
    MADOpenFileViewController * __weak weakself = self;
    [self closeDocument:self.traitCollection completion:^(BOOL success) {
        MADOpenFileViewController * __strong strongself = weakself;
        [strongself performSelectorOnMainThread:@selector(finishCloseDocument:) withObject:strongself waitUntilDone:NO];
    }];

    [self.tabController setViewControllers:nil animated:YES];
    [self dismissViewControllerAnimated:YES completion:^{ }];
    
    self.shouldShowAddDocumentPopover = true;
    self.barButtonItemAddNewDocument.enabled = YES;
    [self.openDocumentPopoverController dismissPopoverAnimated:YES];
}

- (void)viewControllerDidCancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.openDocumentPopoverController dismissPopoverAnimated:YES];
    self.shouldShowAddDocumentPopover = true;
    [self.barButtonItemAddNewDocument setEnabled:YES];
}

- (void)finishCloseDocument:(MADOpenFileViewController *)sender {
    [sender reenable];
    //MADOpenFileViewController * __weak wsender = sender;
    //[UIView performWithoutAnimation:^{
    //    UICollectionViewController *ssender = wsender;
    //    [ssender.collectionView.backgroundView setNeedsDisplay];
    //    [ssender.collectionView reloadItemsAtIndexPaths:ssender.collectionView.indexPathsForVisibleItems];
    //}];

//    NSString *(^sqlWhere)(NSArray *);
//    sqlWhere = ^(NSArray *whereClause)
    
    void (^reloadCells)(void) = ^(){
        NSArray <NSIndexPath *> *paths = self.collectionView.indexPathsForVisibleItems.copy;
        [self.collectionView.backgroundView setNeedsDisplay];
        [self.collectionView reloadItemsAtIndexPaths:paths];
    };

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [UIView performWithoutAnimation:reloadCells];
        }];
    });
}

#pragma mark - MADOpenFileViewControllerDelegate

- (void)didOpenDocument:(MADocument *)documentByRef {
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
    
        MADocument *document = (MADocument *)self.openDocument;

        document.limitResultsDesignMode = [MTStoreKitController sharedObject].isReportingLimited;
   
        MADTabBarController *tabBarController = [MADTabBarController mainTabBarController];
        tabBarController.navigationItem.prompt = document.fileURL.lastPathComponent.copy;
        tabBarController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        tabBarController.modalPresentationStyle = UIModalPresentationOverFullScreen;
        tabBarController.viewControllerDelegate = self;
        NSAssert([tabBarController conformsToProtocol:@protocol(MADViewControllerDocumentProtocol)], @"Controller to conform to MADocumentProtocol.");
        ((id <MADViewControllerDocumentProtocol>)tabBarController).document = document;
        
        UIStoryboard *storyboardQuery = [UIStoryboard Query];
        MADQueryBuilderSplitViewController *splitViewController =  [storyboardQuery instantiateViewControllerWithIdentifier:@"MADIdentifierQueryBuilderSplitViewController"];
        splitViewController.viewControllerDelegate = self;
        
        UIStoryboard *storyboard = [MADStoryboard newStoryboardDesigner];
        
        MADDesignerViewController *designerViewController = [storyboard instantiateViewControllerWithIdentifier:@"MADIdentifierStoryboardDesignerViewController"];
        designerViewController.delegate = self;
        
        MADViewerController *viewerViewController = [storyboard instantiateViewControllerWithIdentifier:@"MADIdentifierStoryboardViewerViewController"];
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
        navigationController.navigationBar.barTintColor = [MADColorEverydayApps newColorBlue];
        navigationController.navigationBar.tintColor = [MADColorEverydayApps newColorWhite];
        
        [self presentViewController:navigationController animated:YES completion:nil];
        
    }];
    
}

- (UIManagedDocument *)documentForURL:(NSURL *)url {
    MADocument *document = [[MADocument alloc] initWithFileURL:url];
    return document;
}

- (void)openDocumentAtURL:(NSURL *)url completionHandler:(void(^)(BOOL success, UIManagedDocument *document))handler {
    MADocument *document = [[MADocument alloc] initWithFileURL:url];
    document.documentDelegate = self;
    
    self.fileManager.openDocument = document;
    
    __block bool openDocumentSuccess = false;
    
    dispatch_barrier_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{

        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        [self.fileManager.openDocument openWithCompletionHandler:^(BOOL success) {
            openDocumentSuccess = success ? true : false;
            dispatch_semaphore_signal(sema);
        }];
    
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if (openDocumentSuccess) [((MADocument *)self.fileManager.openDocument) activeDocumentModel];
            UIManagedDocument *openDocument = self.fileManager.openDocument;
            handler(openDocumentSuccess, openDocument);
            [self reenable];
        }];
    
    });
    
    
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
