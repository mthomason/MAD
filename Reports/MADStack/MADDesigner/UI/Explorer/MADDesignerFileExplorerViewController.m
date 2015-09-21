//
//  MADDesignerFileExplorerViewController.m
//  MAD Designer
//
//  Created by Michael Thomason on 9/21/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADDesignerFileExplorerViewController.h"
#import "MUIViewControllerDelegate.h"
#import "MADQueryBuilderSplitViewController.h"
#import "MADViewerController.h"
#import "MADDesignerViewController.h"
#import "MADQueryViewController.h"
#import "MTDatabaseDriverSelectorViewController.h"
#import "MADStoreViewController.h"

#import "MADDocumentInformationTableViewController.h"
#import "MADDocumentInformationTableViewController+Designer.h"

#import "UINavigationController+Designer.h"
#import "UITabBarController+Shared.h"
#import "UITableViewController+Designer.h"

NSString * const MTSegueOpenInViewer                            = @"MTSegueOpenInViewer";
NSString * const MTSegueShowAddDocument                         = @"showAddDocument";
NSString * const MTSegueLicensing                               = @"MTSegueLicensing";

@interface MADDesignerFileExplorerViewController ()
    <UIPopoverControllerDelegate,
        UIPopoverPresentationControllerDelegate,
        MTViewControllerProtocol>

@property (nonatomic, strong) UIPopoverController *licensingPopoverController;
@property (nonatomic, weak)   IBOutlet UIBarButtonItem *barButtonItemAddNewDocument;
@property (nonatomic, weak)   IBOutlet UIBarButtonItem *barButtonItemLicensing;
@property (nonatomic, strong) UIPopoverController *openDocumentPopoverController;

@property (nonatomic, weak) UIPopoverPresentationController *infoPopoverPresentationController;
@property (nonatomic, weak) UIPopoverPresentationController *aboutPopoverPresentationController;
@property (nonatomic, weak) UIPopoverPresentationController *documentInformationPopoverPresentationController;

@property (nonatomic, assign) BOOL shouldShowAddDocumentPopover;
@property (atomic, assign) BOOL aboutViewControllerOnScreen;

@end

@implementation MADDesignerFileExplorerViewController

- (void)awakeFromNib {
    [self.barButtonItemAddNewDocument setEnabled:YES];
    [super awakeFromNib];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        self.shouldShowAddDocumentPopover = YES;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.openFileDelegate = self;
    self.aboutViewControllerOnScreen = NO;
    
    self.barButtonItemLicensing.enabled = [SKPaymentQueue canMakePayments];

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.aboutViewControllerOnScreen = NO;
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    
    BOOL shouldPerformSegueWithIdentifier = YES;
    if ([identifier isEqualToString:MTSegueShowAddDocument]) {
        if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
            shouldPerformSegueWithIdentifier = [self shouldShowAddDocumentPopover];
            self.shouldShowAddDocumentPopover = NO;
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
        
        if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
            UITabBarController *tabBarController = (UITabBarController *)segue.destinationViewController;
            tabBarController.view.tintColor = [UIColor tintColorRed];
            
            UINavigationController *navController = (UINavigationController *)[tabBarController viewControllers][0];
            MADQueryBuilderSplitViewController *queryBuilderContainerController = (MADQueryBuilderSplitViewController *)[navController topViewController];
            queryBuilderContainerController.viewControllerDelegate = self;
            
            UINavigationController *navController2 = (UINavigationController *)[tabBarController viewControllers][1];
            MADDesignerViewController *reportDesignerViewController = (MADDesignerViewController *)[navController2 topViewController];
            reportDesignerViewController.delegate = self;
            
            UINavigationController *navController3 = (UINavigationController *)[tabBarController viewControllers][2];
            MADViewerController *reportViewerViewController = (MADViewerController *)[navController3 topViewController];
            reportViewerViewController.viewControllerDelegate = self ;
            
        } else {
            
            UITabBarController *tabBarController = (UITabBarController *)segue.destinationViewController;
            tabBarController.view.tintColor = [UIColor greenColor];
            [UITabBar appearance].tintColor = [UIColor redColor];
            
            UINavigationController *navController = (UINavigationController *)[tabBarController viewControllers][0];
            
            MADQueryBuilderSplitViewController *queryBuilderContainerController = (MADQueryBuilderSplitViewController *)navController.topViewController;
            queryBuilderContainerController.viewControllerDelegate = self;
            
            UINavigationController *navController2 = (UINavigationController *)[tabBarController viewControllers][1];
            MADDesignerViewController *reportDesignerViewController = (MADDesignerViewController *)navController2.topViewController;
            reportDesignerViewController.delegate = self;
            
            UINavigationController *navController3 = (UINavigationController *)[tabBarController viewControllers][2];
            MADViewerController *reportViewerViewController = (MADViewerController *)navController3.topViewController;
            reportViewerViewController.viewControllerDelegate = self;
            
        }
        
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
    self.shouldShowAddDocumentPopover = YES;
    [self.barButtonItemAddNewDocument setEnabled:YES];
}

#pragma mark - MTViewControllerProtocol

- (void)viewControllerDidFinish:(id)sender {
    self.shouldShowAddDocumentPopover = YES;
    
    __weak MADOpenFileViewController *weakself = self;
    [self closeDocument:self.traitCollection completion:^(BOOL success) {
        [weakself performSelectorOnMainThread:@selector(finishCloseDocument:) withObject:weakself waitUntilDone:NO];
    }];
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
    self.shouldShowAddDocumentPopover = YES;
    self.barButtonItemAddNewDocument.enabled = YES;
    [self.openDocumentPopoverController dismissPopoverAnimated:YES];
}

- (void)viewControllerDidCancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.openDocumentPopoverController dismissPopoverAnimated:YES];
    self.shouldShowAddDocumentPopover = YES;
    [self.barButtonItemAddNewDocument setEnabled:YES];
}

- (void)finishCloseDocument:(MADOpenFileViewController *)sender {
    [sender reenable];
    [UIView performWithoutAnimation:^{
        [sender.collectionView.backgroundView setNeedsDisplay];
        [sender.collectionView reloadItemsAtIndexPaths:sender.collectionView.indexPathsForVisibleItems];
    }];
}

- (void)didOpenDocument:(MADocument *)document {
    UITabBarController *tabBarController = [UITabBarController mainTabBarController];
    NSAssert([tabBarController conformsToProtocol:@protocol(MADocumentProtocol)], @"Controller to conform to MADocumentProtocol.");
    ((id <MADocumentProtocol>)tabBarController).document = self.openDocument;
    
    tabBarController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    tabBarController.modalPresentationStyle = UIModalPresentationOverFullScreen;
    
    UINavigationController *navController = (UINavigationController *)tabBarController.viewControllers[0];
    UINavigationController *navController2 = (UINavigationController *)tabBarController.viewControllers[1];
    UINavigationController *navController3 = (UINavigationController *)tabBarController.viewControllers[2];
    
    __weak MADQueryBuilderSplitViewController * queryBuilderViewController = (MADQueryBuilderSplitViewController *)navController.topViewController;
    queryBuilderViewController.viewControllerDelegate = self;
    
    __weak MADDesignerViewController *reportDesignerViewController = (MADDesignerViewController *)navController2.topViewController;
    reportDesignerViewController.delegate = self;
    
    __weak MADViewerController *reportViewerViewController = (MADViewerController *)navController3.topViewController;
    reportViewerViewController.viewControllerDelegate = self ;
    
    [self presentViewController:tabBarController animated:YES completion:nil];
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

- (IBAction)documentInformation:(id)sender {
    MADMetaData *metadata = nil;
    NSArray *selectedItems = [self.collectionView indexPathsForSelectedItems];
    NSIndexPath *indexPath;
    NSMutableArray *metadataItems = [[NSMutableArray alloc] initWithCapacity:selectedItems.count];
    for (indexPath in selectedItems) {
        metadata = [self.filesCoordnator.filesController objectAtIndexedSubscript:indexPath.item];
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
    self.aboutViewControllerOnScreen = NO;
}

- (void)popoverPresentationController:(UIPopoverPresentationController *)popoverPresentationController willRepositionPopoverToRect:(inout CGRect *)rect inView:(inout UIView **)view { }

#pragma mark - Convenience

- (NSArray *)defaultPassthoughViews {
    return @[self.navigationController.navigationBar, self.navigationController.toolbar];
}

@end
