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

#import "MTViewControllerOpenDocument.h"
#import <MessageUI/MessageUI.h>
#import "MTApplicationInstance.h"
#import "UAAppReviewManager.h"
#import "MTReportViewerController.h"
#import "MTStoreKitController+NonRenewableLicensing.h"
#import "MTReportDesignerViewController.h"
#import "MADWatermarkView.h"
#import "NSURL+Document.h"
#import "MTUser.h"
#import "MTQueryBuilderContainerController.h"
#import "MTCollectionViewCellDocument.h"
#import "UIView+Animations.h"
#import "MTViewControllerAbout.h"
#import "MTTableViewCellDocument.h"
#import "MTQueryBuilderViewController.h"
#import "MTQueryBuilderVisualizationViewController.h"
#import "UIColor+EverydayApps.h"
#import "UIDevice+Hack.h"
#import "MTDatabaseDriverSelectorViewController.h"
#import "MTAlertView.h"

NSString * const MTSegueShowAddDocument = @"showAddDocument";
NSString * const MTSegueShowOpenDocument = @"openDocument";
NSString * const MTCollectionViewCellDocumentIdentifier = @"MTCollectionViewCellDocumentIdentifier";

@interface MTViewControllerOpenDocument()
    <UIAlertViewDelegate, NSFileManagerDelegate, UIPopoverControllerDelegate,
        UICollectionViewDataSource,
        UICollectionViewDelegate,
        UICollectionViewDelegateFlowLayout,
        UIGestureRecognizerDelegate,
        MFMailComposeViewControllerDelegate,
        UITextFieldDelegate,
        MTViewControllerProtocol,
        MTDocumentCellProtocol,
        MTViewControllerAsyncProtocol>

@property (nonatomic, weak) IBOutlet UICollectionViewFlowLayout *collectionViewFlowLayout;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *barButtonItemAction;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *barButtonItemEdit;
@property (nonatomic, strong)  UIBarButtonItem *barButtonItemEditDone;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *barButtonItemTrash;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *barButtonItemInformation;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *barButtonItemAbout;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *barButtonItemAddNewDocument;
@property (nonatomic, strong) UIBarButtonItem *barButtonItemLicensing;

@property (nonatomic, strong) UIAlertView *renameAlertView;

@property (nonatomic, strong) UIPopoverController *openDocumentPopoverController;
@property (nonatomic, strong) UIPopoverController *aboutPopoverController;
@property (nonatomic, strong) UIPopoverController *licensingPopoverController;
@property (nonatomic, strong) UIPopoverController *popoverControllerActivity;

@property (nonatomic, strong) NSURL *urlBeingOpended;
@property (nonatomic, strong) NSMutableArray *availableFilesCache;

@property (nonatomic, strong) MTReportViewerController *reportViewer;

@property (nonatomic, strong) UILongPressGestureRecognizer *longPressGestureRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;

@property (nonatomic, assign) BOOL shouldShowAddDocumentPopover;
@property (nonatomic, assign) BOOL editModeEnabled;
@property (nonatomic, assign) BOOL bothContentControllersDisplayed;

@property (nonatomic, assign) BOOL cellsHidden;

@end

@implementation MTViewControllerOpenDocument

- (void)closeReport {
    
    [self displaySavingReportActivityIndicator];
    
    __weak MTViewControllerOpenDocument *blockSelf = self;
    [[AppDelegate app] closeReportWithCompletionHandler:^(BOOL success) {
        [[blockSelf collectionView] setUserInteractionEnabled: YES];
        [blockSelf setCellsHidden:NO];
        [[blockSelf collectionView] reloadData];
    }];
    
}

- (void)displaySavingReportActivityIndicator {
    NSInteger numberOfCells = [[self collectionView] numberOfItemsInSection:0];
    [self setCellsHidden:YES];
    for (NSInteger i=0; i<numberOfCells; i++) {
        MTCollectionViewCellDocument *cell = (MTCollectionViewCellDocument *)[[self collectionView] cellForItemAtIndexPath:[NSIndexPath indexPathForItem:i inSection:0]];
        if (cell != nil) {
            [cell performDeselectionAnimations];
            [[cell contentView] setAlpha:0.9500f];
            UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            [activityView startAnimating];
            [activityView setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin];
            [activityView setCenter:[[cell contentView] center]];
            [[cell contentView] addSubview:activityView];
        }
    }
    [[self collectionView] setUserInteractionEnabled: NO];
}

- (IBAction)unwindToOpenDocumentViewController:(UIStoryboardSegue *)action {
    
    NSString *actionIdentifier = [action identifier];
    if ([actionIdentifier isEqualToString:@"MTSegueCloseDesigner"] ||
        [actionIdentifier isEqualToString:@"MAReportViewerCloseReportIdentifier"]) {
        [self closeReport];
    }
    [self setShouldShowAddDocumentPopover:YES];
    [[self barButtonItemAddNewDocument] setEnabled:YES];
    [self updateFileList:self];
    
    if ([MTApplicationInstance isMadViewer] && [UIDevice isPad]) {

    } else if ([MTApplicationInstance isMadViewer] && ![UIDevice isPad]) {
    
    } else {
        [[self openDocumentPopoverController] dismissPopoverAnimated:YES];
    }
    if ([MTApplicationInstance isMadViewer]) {
        [self setReportViewer:nil];
    }

}

- (void)awakeFromNib {
    [self setShouldShowAddDocumentPopover:YES];
    [[self barButtonItemAddNewDocument] setEnabled:YES];
    [super awakeFromNib];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initalize];
    }
    return self;    
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self initalize];
    }
    return self;
}

- (void)initalize {


    [self setEditModeEnabled:NO];
    
    UIBarButtonItem *barButtonItemEditDone = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(edit:)];
    [self setBarButtonItemEditDone:barButtonItemEditDone];
    
    [self setEditing:NO animated:NO];
    
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [[[self navigationItem] titleView] sizeToFit];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [UIView animateWithDuration:duration delay:0.0000f options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        [[[self collectionView] backgroundView] setNeedsDisplay];
    } completion:NULL];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    CGPoint touchPoint = [touch locationInView:[self collectionView]];
    NSIndexPath *indexPath = [[self collectionView] indexPathForItemAtPoint:touchPoint];
    if (indexPath && [gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]) {
        return NO;
    }
    return YES;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    return YES;
}

- (void)activateEditMode:(UILongPressGestureRecognizer *)sender {
    if ([sender state] == UIGestureRecognizerStateEnded) {
        if ([self editModeEnabled] == NO) {
            [self edit:self];
        }
    }
}

- (void)endEditMode:(UITapGestureRecognizer *)sender {
    if ([self editModeEnabled]) {
        [self edit:self];
    }
}

#pragma mark - UIViewController Overrides

- (void)setLetterpressBackground {
    UICollectionView *v = (UICollectionView *)[self collectionView];

    CGRect bounds = [v bounds];
    MADWatermarkView *watermarkView = [[MADWatermarkView alloc] initWithFrame:bounds];
    [v setBackgroundView:watermarkView];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    

    //MTApplicationInstance *appInstance = [[AppDelegate app] retain];
    //[self setApplicationInstance: appInstance];
    //[appInstance release];
    
    UIColor *barTintColor = [UIColor tintColorBlue];
    UIColor *tintColor = [UIColor tintColorWhite];
    UIToolbar *toolbar = [[self navigationController] toolbar];
    [toolbar setBarTintColor:barTintColor];
    [toolbar setTintColor:tintColor];

    [self setLetterpressBackground];

    UIColor *bgColor = [UIColor lightGrayColor];
    [[self collectionView] setBackgroundColor:bgColor];
    
    [self setCellsHidden:NO];
    UILabel *labelMadDesigner = [[UILabel alloc] initWithFrame:CGRectZero];
    [labelMadDesigner setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];

    NSAttributedString *attributedString = nil;
    if ([MTApplicationInstance isMadDesigner]) {
        attributedString = [MTApplicationInstance localizedAttributedApplicationNameMadDesigner];
    } else if ([MTApplicationInstance isMadViewer]) {
        attributedString = [MTApplicationInstance localizedAttributedApplicationNameMadViewer];
    }
    NSAssert(attributedString != nil, @"Navigation title is not set.");
    [labelMadDesigner setAttributedText:attributedString];
    [[self navigationItem] setTitleView:labelMadDesigner];
    [[[self navigationItem] titleView] sizeToFit];

    [[self navigationItem] setHidesBackButton:YES];
    [self setEditModeEnabled:NO];
    
    UILongPressGestureRecognizer *longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(activateEditMode:)];
    [longPressGestureRecognizer setDelegate: self];
    [[self collectionView] addGestureRecognizer:longPressGestureRecognizer];
    [self setLongPressGestureRecognizer:longPressGestureRecognizer];
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(endEditMode:)];
    [tapGestureRecognizer setDelegate: self];
    [[self collectionView] addGestureRecognizer:tapGestureRecognizer];
    [self setTapGestureRecognizer:tapGestureRecognizer];

    NSMutableArray *fileUrlCache = [[NSMutableArray alloc] init];
    [self setAvailableFilesCache: fileUrlCache];
    
    [[self barButtonItemLicensing] setEnabled:[SKPaymentQueue canMakePayments]];

    NSMutableArray *toolbarButtons = [[NSMutableArray alloc] initWithArray: [self toolbarItems]];
    [toolbarButtons removeObject:[self barButtonItemAction]];
    [self setToolbarItems:toolbarButtons animated:NO];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UIMenuController *menu = [UIMenuController sharedMenuController];
        NSMutableArray *menuItems = [[menu menuItems] mutableCopy];
        if (menuItems == nil) {
            menuItems = [[NSMutableArray alloc] init];
        }
        UIMenuItem *menuItem = [[UIMenuItem alloc] initWithTitle: NSLocalizedString(@"Rename", @"Rename")
                                                          action: @selector(rename:)];
        [menuItems addObject:menuItem];
        [menu setMenuItems:menuItems];
    });

    [[MTStoreKitController sharedObject] licensedUser:^(BOOL isLicensedUser, NSDate *experationDate) {
        if (isLicensedUser) {
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                UIMenuController *menu = [UIMenuController sharedMenuController];
                NSMutableArray *menuItems = [[menu menuItems] mutableCopy];
                if (menuItems == nil) {
                    menuItems = [[NSMutableArray alloc] init];
                }
                UIMenuItem *menuItem = [[UIMenuItem alloc] initWithTitle: NSLocalizedString(@"Email", @"Email")
                                                                  action: @selector(email:)];
                [menuItems addObject:menuItem];
                [menu setMenuItems:menuItems];
            });

            if ([[self toolbarItems] containsObject:[self barButtonItemAction]] == NO) {
                NSMutableArray *toolbarButtons = [[self toolbarItems] mutableCopy];
                [toolbarButtons insertObject:[self barButtonItemAction] atIndex:1];
                [self setToolbarItems:toolbarButtons animated:animated];
            }
            
        } else {

        }
    }];
    
    [self updateFileList:self];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    for (NSUInteger item = 0; item < [[self collectionView] numberOfItemsInSection:0]; item++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:0];
        [[self collectionView] deselectItemAtIndexPath:indexPath animated:YES];
        MTCollectionViewCellDocument *cell = (MTCollectionViewCellDocument *)[[self collectionView] cellForItemAtIndexPath:indexPath];
        [cell performDeselectionAnimations];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController {
    BOOL dismiss = [[self openDocumentPopoverController] isEqual:popoverController] == NO;
    return dismiss;
}

- (BOOL)dismissAllPopovers {
    BOOL result = NO;
    if ([UIDevice isPad]) {
        NSMutableArray *allpopovers = [[NSMutableArray alloc] initWithCapacity:3];
        if ([self openDocumentPopoverController] != nil) [allpopovers addObject:[self openDocumentPopoverController]];
        if ([self licensingPopoverController] != nil) [allpopovers addObject:[self licensingPopoverController]];
        if ([self aboutPopoverController] != nil) [allpopovers addObject:[self aboutPopoverController]];
        
        for (UIPopoverController *popoverController in allpopovers) {
            if ([popoverController isPopoverVisible]) {
                [popoverController dismissPopoverAnimated:YES];
                result = YES;
            }
        }
    }
    return result;
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    [self setShouldShowAddDocumentPopover:YES];
    [[self barButtonItemAddNewDocument] setEnabled:YES];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [super prepareForSegue:segue sender:sender];

    [self dismissAllPopovers];
    if ([[segue identifier] isEqualToString:MTSegueShowAddDocument]) {
        
        if ([[segue destinationViewController] isKindOfClass: [UINavigationController class]]) {
            UINavigationController *navControl = [segue destinationViewController];
            if ([navControl topViewController]) {
                if ([segue isKindOfClass:[UIStoryboardPopoverSegue class]]) {
                    [self setOpenDocumentPopoverController: [(UIStoryboardPopoverSegue *)segue popoverController]];
                    [[self openDocumentPopoverController] setDelegate:self];
                }
                [(MTDatabaseDriverSelectorViewController *)[navControl topViewController] setDelegate:self];
            }
        }

        [[segue destinationViewController] setDelegate:self];
        
    } else if ([[segue identifier] isEqualToString:@"MTSegueDetails"] || [[segue identifier] isEqualToString:@"MTSegueAbout"]) {
        UINavigationController *navigationController = [segue destinationViewController];
        MTViewControllerAbout *aboutViewController = (MTViewControllerAbout *)[navigationController topViewController];
        [aboutViewController setDelegate:self];

        if ([[segue destinationViewController] isKindOfClass: [UINavigationController class]]) {
            UINavigationController *navControl = [segue destinationViewController];
            if ([navControl topViewController]) {
                if ([segue isKindOfClass:[UIStoryboardPopoverSegue class]]) {
                    [self setAboutPopoverController:[(UIStoryboardPopoverSegue *)segue popoverController]];
                }
            }
        }
        
        if ([UIDevice isPad]) {
            if ([[segue identifier] isEqualToString:@"MTSegueDetails"]) {
                if ([MTApplicationInstance isMadViewer]) {
                    [[self aboutPopoverController]  setPopoverContentSize: CGSizeMake(420.0000f, 376.0000f)];
                } else {
                    [[self aboutPopoverController]  setPopoverContentSize: CGSizeMake(540.0000f, 556.0000f)];
                }
            } else {
                [[self aboutPopoverController]  setPopoverContentSize: CGSizeMake(320.0000f, 320.0000f)];
            }
        }
        
    } else if ([[segue identifier] isEqualToString:MTSegueLicensing]) {

        if ([[segue destinationViewController] isKindOfClass: [UINavigationController class]]) {
            UINavigationController *navControl = [segue destinationViewController];
            id tvc = [navControl topViewController];
            [tvc setDelegate:self];
        }
        [[segue destinationViewController] setDelegate:self];
        
        if ([[segue destinationViewController] isKindOfClass: [UINavigationController class]]) {
            UINavigationController *navControl = [segue destinationViewController];
            if ([navControl topViewController]) {
                if ([segue isKindOfClass:[UIStoryboardPopoverSegue class]]) {
                    [self setLicensingPopoverController:[(UIStoryboardPopoverSegue *)segue popoverController]];
                }
            }
        }
        
    } else if ([[segue identifier] isEqualToString:MTSegueOpenInViewer]) {

        BOOL foundUrl = NO;
        if ([sender isKindOfClass:[MTCollectionViewCellDocument class]]) {
            NSURL *url = [self urlForDocumentCell:sender];
            [self setUrlBeingOpended:url];
            foundUrl = YES;
        } else if ([sender isKindOfClass:[NSURL class]]) {
            NSURL *url = sender;
            [self setUrlBeingOpended:url];
            foundUrl = YES;
        }

        if (foundUrl) {
            MTReportViewerController *viewControllerReportViewer = (MTReportViewerController *)[(UINavigationController *)[segue destinationViewController] topViewController];
            [viewControllerReportViewer setViewControllerDelegate:self];
            [self setReportViewer:viewControllerReportViewer];
            
            MTApplicationInstance *appInstance = [AppDelegate app];
            [appInstance openReport:[self urlBeingOpended] withCompletionHandler:^(BOOL success) {
                if (success) {
                    [[self reportViewer] reload];
                }
            }];
            
        } else {
            NSAssert(foundUrl == NO, @"No URL to open.");
        }
        
    } else if ([[segue identifier] isEqualToString:MTSegueShowOpenDocument]) {
        BOOL foundUrl = NO;
        if ([sender isKindOfClass:[MTCollectionViewCellDocument class]]) {

            NSURL *url = [self urlForDocumentCell:sender];
            if (url != nil) {
                foundUrl = YES;
            }
            [self setUrlBeingOpended:url];
            
        } else if ([sender isKindOfClass:[NSURL class]])  {
            NSURL *url = sender;
            if (url != nil) {
                [self setUrlBeingOpended:url];
                foundUrl = YES;
            }
        }
        if (foundUrl) {
            if ([[segue destinationViewController] isKindOfClass: [UINavigationController class]] || [[segue destinationViewController] isKindOfClass: [UITabBarController class]]) {

                if ([UIDevice isPad]) {
                    UITabBarController *tabBarController = (UITabBarController *)[segue destinationViewController];
                    [[tabBarController view] setTintColor:[UIColor tintColorRed]];

                    UINavigationController *navController = (UINavigationController *)[[tabBarController viewControllers] objectAtIndex:0];
                    __weak MTQueryBuilderContainerController *queryBuilderViewController = (MTQueryBuilderContainerController *)[navController topViewController];
                    [queryBuilderViewController setDelegate:self];

                    UINavigationController *navController2 = (UINavigationController *)[[tabBarController viewControllers] objectAtIndex:1];
                    MTReportDesignerViewController *reportDesignerViewController = (MTReportDesignerViewController *)[navController2 topViewController];
                    [reportDesignerViewController setDelegate:self];

                    UINavigationController *navController3 = (UINavigationController *)[[tabBarController viewControllers] objectAtIndex:2];
                    MTReportViewerController *reportViewerViewController = (MTReportViewerController *)[navController3 topViewController];
                    [reportViewerViewController setViewControllerDelegate:self];
                    
                    MTApplicationInstance *appInstance = [AppDelegate app];
                    [appInstance openReport:[self urlBeingOpended] withCompletionHandler:^(BOOL success) {
                        if (success) {
                            [[queryBuilderViewController queryBuilderController] reloadActiveDocumentAnimated:YES];
                            [[queryBuilderViewController queryBuilderControllerAdvanced] reloadActiveDocumentAnimatedAnimated:YES];
                        }
                    }];

                    
                } else {
                    
                    UITabBarController *tabBarController = (UITabBarController *)[segue destinationViewController];
                    [[tabBarController view] setTintColor:[UIColor greenColor]];
                    [[UITabBar appearance] setSelectedImageTintColor:[UIColor redColor]];

                    //[[tabBarController view] setBackgroundColor:[UIColor greenColor]];
                    
                    UINavigationController *navController = (UINavigationController *)[[tabBarController viewControllers] objectAtIndex:0];
                    __weak MTQueryBuilderViewController *queryBuilderViewController = (MTQueryBuilderViewController *)[navController topViewController];
                    
                    UINavigationController *navController2 = (UINavigationController *)[[tabBarController viewControllers] objectAtIndex:1];
                    MTReportDesignerViewController *reportDesignerViewController = (MTReportDesignerViewController *)[navController2 topViewController];
                    [reportDesignerViewController setDelegate:self];
                    
                    UINavigationController *navController3 = (UINavigationController *)[[tabBarController viewControllers] objectAtIndex:2];
                    MTReportViewerController *reportViewerViewController = (MTReportViewerController *)[navController3 topViewController];
                    [reportViewerViewController setViewControllerDelegate:self];

                    [[AppDelegate app] openReport:[self urlBeingOpended] withCompletionHandler:^(BOOL success) {
                        if (success) {
                            [queryBuilderViewController reloadActiveDocumentAnimated:YES];
                        }
                    }];
                }
                
            } else if ([[segue destinationViewController] isKindOfClass:[MTQueryBuilderContainerController class]]) {
                //MTQueryBuilderContainerController *queryBuilderViewController = (MTQueryBuilderContainerController *)[segue destinationViewController];
                //[queryBuilderViewController setDelegate:self];
            } else if ([[segue destinationViewController] isKindOfClass:[MTQueryBuilderViewController class]]) {
                
                __weak MTQueryBuilderViewController *queryBuilderViewController = (MTQueryBuilderViewController *)[[segue destinationViewController] topViewController];
                
                [[AppDelegate app] openReport:[self urlBeingOpended] withCompletionHandler:^(BOOL success) {
                    if (success) {
                        [queryBuilderViewController reloadActiveDocumentAnimated:YES];
                    }
                }];
            }
        }
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
            [self setShouldShowAddDocumentPopover:NO];
            [[self barButtonItemAddNewDocument] setEnabled:NO];
        }
    } else if ([identifier isEqualToString:MTSegueShowOpenDocument]) {
        shouldPerformSegueWithIdentifier = ![self isEditing];
    } else if ([identifier isEqualToString:MTSegueOpenInViewer]) {
        shouldPerformSegueWithIdentifier = ![self isEditing];
    }
    return shouldPerformSegueWithIdentifier;
}

#pragma mark - Delegates

- (void)displayContentController:(UIViewController *)contentController {
    //If designer application, then load designer query builder.
    //  If viewer, load, well, the viewer.
    __weak MTQueryBuilderVisualizationViewController *advanced = nil;
    __weak MTQueryBuilderViewController *standard = nil;

    if ([MTApplicationInstance isMadDesigner]) {
        if ([contentController isKindOfClass:[UINavigationController class]]) {
            UINavigationController *childNavigationController = (UINavigationController *)contentController;
            if ([[childNavigationController topViewController] isKindOfClass:[MTQueryBuilderViewController class]]) {
                standard = (MTQueryBuilderViewController *)[(UINavigationController *)childNavigationController topViewController];
                [self setBothContentControllersDisplayed:NO];
            }
        } else if ([contentController isKindOfClass:[MTQueryBuilderVisualizationViewController class]]) {
            advanced = (MTQueryBuilderVisualizationViewController *)contentController;
            [self setBothContentControllersDisplayed:NO];
        } else if ([contentController isKindOfClass:[MTQueryBuilderViewController class]]) {
            standard = (MTQueryBuilderViewController *)contentController;
            [self setBothContentControllersDisplayed:YES];
        }
        
        
        
        if ([self bothContentControllersDisplayed] && standard != nil && standard != nil) {
            
            
            [[AppDelegate app] openReport:[self urlBeingOpended] withCompletionHandler:^(BOOL success) {
                if (success) {
                    [standard reloadActiveDocumentAnimated:YES];
                    [advanced reloadActiveDocumentAnimatedAnimated:YES];
                }
            }];
            
        }
    } else if ([MTApplicationInstance isMadViewer]) {
        __weak MTReportViewerController *viewController = (MTReportViewerController *)contentController;

        [[AppDelegate app] openReport:[self urlBeingOpended] withCompletionHandler:^(BOOL success) {
            if (success) [viewController reload:viewController];
        }];

    }
}



- (void)deleteDocumentRepresentedByCell:(MTCollectionViewCellDocument *)cell {
    NSIndexPath *cellPath = [[self collectionView] indexPathForCell:cell];
    [self deleteDocumentAtIndexPath:cellPath];
}

- (void)viewControllerDidFinish:(id)sender {
    [self setShouldShowAddDocumentPopover:YES];
    [self closeReport];
    
    if ([[self openDocumentPopoverController] isPopoverVisible]) {
        [[self openDocumentPopoverController] dismissPopoverAnimated:YES];
    } else {
        [self dismissViewControllerAnimated:YES completion:^{ }];
    }
    [[self barButtonItemAddNewDocument] setEnabled:YES];
    if ([UIDevice isPad]) {
        [self updateFileList:self];
    }
}

- (void)viewControllerDidFinish:(id)sender animated:(BOOL)animated {
    [self dismissViewControllerAnimated:YES completion:^{ }];
    
    Class queryBuilderClass = [MTQueryBuilderViewController class];
    Class queryBuilderContainerClass = [MTQueryBuilderContainerController class];
    Class reportDesignerClass = [MTReportDesignerViewController class];
    Class reportViewerClass = [MTReportViewerController class];
    
    if ([sender isKindOfClass: queryBuilderClass] ||
        [sender isKindOfClass: queryBuilderContainerClass] ||
        [sender isKindOfClass: reportDesignerClass] ||
        [sender isKindOfClass: reportViewerClass]) {
        [self closeReport];
    }
    [self setShouldShowAddDocumentPopover:YES];
    [[self barButtonItemAddNewDocument] setEnabled:YES];
    [[self openDocumentPopoverController] dismissPopoverAnimated:YES];
    
}


- (void)viewControllerDidCancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
    [[self openDocumentPopoverController] dismissPopoverAnimated:YES];
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
        [self presentViewController:mFMailComposeViewController animated:YES completion:nil];
    } else {
        NSString *title = NSLocalizedString(@"Alert", @"Alert title");
        NSString *message = NSLocalizedString(@"Device is not configured for email.", @"Device is not configured for email.");
        NSString *dismiss = NSLocalizedString(@"Continue", @"Continue");
        UIAlertView *uIAlertView = [[UIAlertView alloc] initWithTitle:title
                                                              message:message
                                                             delegate:self
                                                    cancelButtonTitle:dismiss
                                                    otherButtonTitles:nil];
        [uIAlertView show];
    }
}

- (void)setupQueryDesignerController:(MTQueryBuilderViewController *)tvc usingFileAtUrl:(NSURL*)url {
    __weak MTQueryBuilderViewController *weakTvc = tvc;
    [[AppDelegate app] openReport:[self urlBeingOpended] withCompletionHandler:^(BOOL success) {
        if (success) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [weakTvc reloadActiveDocumentAnimated:YES];
                });
            });
        }
    }];
}

#pragma mark - Actions

- (NSURL *)urlForDocumentCell:(MTCollectionViewCellDocument *)cellDocument {
    NSInteger row = [[[self collectionView] indexPathForCell:cellDocument] row];
    return [[self availableFilesCache] objectAtIndex: row];
    
}

- (IBAction)updateFileList:(id)sender {
    MTApplicationInstance *app = [AppDelegate app];
    NSMutableArray *madFiles = [[[app user] hasMadDocuments] mutableCopy];
    [self setAvailableFilesCache: madFiles];
    [[self collectionView] reloadData];
    
}

- (IBAction)done:(id)sender { }

- (IBAction)edit:(id)sender {
    
    BOOL startEdit = ![self isEditing];
    [self setEditing:startEdit animated:YES];
    
    if (startEdit) {
        [self setEditModeEnabled:YES];
        [[self barButtonItemLicensing] setEnabled:NO];
        [[self barButtonItemAddNewDocument] setEnabled:NO];
        [[self barButtonItemAbout] setEnabled:NO];
        [[self barButtonItemInformation] setEnabled:NO];
        
        [[self collectionView] setAllowsMultipleSelection:YES];
        [[self navigationItem] setRightBarButtonItem:[self barButtonItemEditDone] animated:YES];

        
        NSUInteger numberOfSections = [[self collectionView] numberOfSections];
        for (NSUInteger section = 0; section < numberOfSections; section++) {
            NSUInteger numberOfItemsInSection = [[self collectionView] numberOfItemsInSection:section];
            for (NSUInteger item = 0; item < numberOfItemsInSection; item++) {
                NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:0];
                UICollectionViewCell *cell = [[self collectionView] cellForItemAtIndexPath:indexPath];
                [cell startWobble];
            }
        }
    } else {
        [self setEditModeEnabled:NO];
        [[self barButtonItemLicensing] setEnabled:YES];
        [[self barButtonItemAddNewDocument] setEnabled:YES];
        [[self barButtonItemAbout] setEnabled:YES];
        [[self barButtonItemInformation] setEnabled:YES];

        [[self barButtonItemTrash] setEnabled:NO];
        [[self barButtonItemAction] setEnabled:NO];

        [[self collectionView] setAllowsMultipleSelection:NO];
        [[self navigationItem] setRightBarButtonItem:[self barButtonItemEdit] animated:YES];

        for (NSUInteger item = 0; item < [[self collectionView] numberOfItemsInSection:0]; item++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:0];
            [[self collectionView] deselectItemAtIndexPath:indexPath animated:YES];
            MTCollectionViewCellDocument *cell = (MTCollectionViewCellDocument *)[[self collectionView] cellForItemAtIndexPath:indexPath];
            [cell stopWobble];
            [cell performDeselectionAnimations];
            
            NSURL *fileUrl = [self availableFilesCache][[indexPath row]];
            NSURL *url = [MAReportDocument thumbnailWithBorderUrlForMadUrl:fileUrl];
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
    NSString *applicationName = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleNameKey];
    NSString *title = [NSString stringWithFormat:NSLocalizedString(@"About %@", @"About Mad Designer"),  applicationName];
    NSString *message = NSLocalizedString(@"© Everyday Apps LLC 2014.  Software created by Michael Thomason for Everyday Apps LLC.",
                                          @"© Everyday Apps LLC 2014.  Software created by Michael Thomason for Everyday Apps LLC.");
    NSString *buttonTitle = NSLocalizedString(@"Continue", @"Continue");

    MTAlertView *alertView = [[MTAlertView alloc] initWithTitle: title
                                                        message: message
                                              cancelButtonTitle: buttonTitle
                                               otherButtonTitle: nil onDismiss:nil onCancel:nil];
    [alertView show];
}

- (void)cut:(id)sender {
    [super cut:sender];
}

- (void)copy:(id)sender {
    [super copy:sender];
}

- (IBAction)activity:(id)sender {
    NSMutableArray *wrappedUrls = [[NSMutableArray alloc] initWithCapacity:[[self availableFilesCache] count]];
    NSUInteger numberOfSections = [[self collectionView] numberOfSections];
    for (NSUInteger section = 0; section < numberOfSections; section++) {
        NSUInteger numberOfItemsInSection = [[self collectionView] numberOfItemsInSection:section];
        for (NSUInteger item = 0; item < numberOfItemsInSection; item++) {
            NSIndexPath *selectedCellLocation = [NSIndexPath indexPathForItem:item inSection:section];
            MTCollectionViewCellDocument *documentCell = (MTCollectionViewCellDocument *)[[self collectionView] cellForItemAtIndexPath:selectedCellLocation];
            if (documentCell != nil) {
                if ([documentCell isSelected]) {
                    NSURL *fileUrl = [self availableFilesCache][item];
                    [wrappedUrls addObject:fileUrl];
                    [documentCell dimTint];
                }
            }
        }
    }
    
    UIActivityViewControllerCompletionHandler activityViewControllerCompletionHandler = ^(NSString *activityType, BOOL completed) {
        
        if (completed) {
            [UAAppReviewManager userDidSignificantEvent:YES];
        }
    
        NSUInteger numberOfSections = [[self collectionView] numberOfSections];
        for (NSUInteger section = 0; section < numberOfSections; section++) {
            NSUInteger numberOfItemsInSection = [[self collectionView] numberOfItemsInSection:section];
            for (NSUInteger item = 0; item < numberOfItemsInSection; item++) {
                NSIndexPath *selectedCellLocation = [NSIndexPath indexPathForItem:item inSection:section];
                MTCollectionViewCellDocument *documentCell = (MTCollectionViewCellDocument *)[[self collectionView] cellForItemAtIndexPath:selectedCellLocation];
                if (documentCell != nil) {
                    if ([documentCell isSelected]) {
                        [documentCell normalizeTint];
                    }
                }
            }
        }
    
    };
    
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:wrappedUrls applicationActivities:@[]];
    [activityViewController setExcludedActivityTypes:@[UIActivityTypeAssignToContact, UIActivityTypePostToFacebook, UIActivityTypePostToFlickr, UIActivityTypePostToTwitter, UIActivityTypePostToVimeo]];
    [activityViewController setCompletionHandler:activityViewControllerCompletionHandler];
    if ([UIDevice isPad]) {
        if ([self popoverControllerActivity] == nil || [[self popoverControllerActivity] isPopoverVisible] == NO) {
            UIPopoverController *popoverController = [[UIPopoverController alloc] initWithContentViewController:activityViewController];
            [popoverController setDelegate:self];
            [popoverController presentPopoverFromBarButtonItem:[self barButtonItemAction] permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
            [self setPopoverControllerActivity:popoverController];
        }
    } else {
        [self presentViewController:activityViewController animated:YES completion:^{ }];
    }
}

- (IBAction)delete:(id)sender {
    if ([self collectionView] != nil) {
        NSMutableArray *itemsToDelete = [[NSMutableArray alloc] init];
        NSUInteger numberOfSections = [[self collectionView] numberOfSections];
        for (NSUInteger section = 0; section < numberOfSections; section++) {
            NSUInteger numberOfItemsInSection = [[self collectionView] numberOfItemsInSection:section];
            for (NSUInteger item = 0; item < numberOfItemsInSection; item++) {
                NSIndexPath *selectedCellLocation = [NSIndexPath indexPathForItem:item inSection:section];
                MTCollectionViewCellDocument *documentCell = (MTCollectionViewCellDocument *)[[self collectionView] cellForItemAtIndexPath:selectedCellLocation];
                if (documentCell != nil) {
                    if ([documentCell isSelected]) {
                        [itemsToDelete addObject:selectedCellLocation];
                    }
                }
            }
        }
        NSFileManager *defaultManager = [NSFileManager defaultManager];
        NSMutableIndexSet *indexSet = [[NSMutableIndexSet alloc] init];
        for (NSIndexPath *indexPath in itemsToDelete) {
            NSUInteger index = [indexPath item];
            NSURL *urlToDelete = [[self availableFilesCache] objectAtIndex:index];
            NSError *error = nil;
            [defaultManager removeItemAtURL:urlToDelete error:&error];
            [indexSet addIndex:index];
        }
        [[self availableFilesCache] removeObjectsAtIndexes:indexSet];
        [[self collectionView] deleteItemsAtIndexPaths:itemsToDelete];
    }
}

- (void)deleteDocumentAtIndexPath:(NSIndexPath *)index {
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtURL:[[self availableFilesCache]
                                                     objectAtIndex:index.item] error:&error];
    if (!error) {
        if (index.item < [[self availableFilesCache] count]) {
            [[self availableFilesCache] removeObjectAtIndex:index.item];
            [[self collectionView] deleteItemsAtIndexPaths:@[index]];
        }
    } else {
        [error presentErrorToUser];
    }
}

- (void)selectionsUpdated {
    NSUInteger selectedCellCounter = 0;
    NSUInteger numberOfSections = [[self collectionView] numberOfSections];
    for (NSUInteger section = 0; section < numberOfSections; section++) {
        NSUInteger numberOfItemsInSection = [[self collectionView] numberOfItemsInSection:section];
        for (NSUInteger item = 0; item < numberOfItemsInSection; item++) {
            NSIndexPath *selectedCellLocation = [NSIndexPath indexPathForItem:item inSection:section];
            UICollectionViewCell *cell = [[self collectionView] cellForItemAtIndexPath:selectedCellLocation];
            if ([cell isSelected]) {
                selectedCellCounter++;
            }
        }
    }
    switch (selectedCellCounter) {
        case 0:
            [[self barButtonItemTrash] setEnabled:NO];
            [[self barButtonItemAction] setEnabled:NO];
            break;
        case 1:
            [[self barButtonItemTrash] setEnabled:YES];
            [[self barButtonItemAction] setEnabled:YES];
            break;
        default:
            [[self barButtonItemTrash] setEnabled:YES];
            [[self barButtonItemAction] setEnabled:NO];
            break;
    }
}

- (void)rename:(id)sender {
    MTCollectionViewCellDocument *cellDocument = sender;
    NSAssert(cellDocument != nil, @"Null cell.");
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle: NSLocalizedString(@"Rename Document", @"Rename Document")
                                                        message: NSLocalizedString(@"Please enter a new name for the document.", @"Please enter a new name for the document.")
                                                       delegate: self
                                              cancelButtonTitle: NSLocalizedString(@"Cancel", @"Cancel")
                                              otherButtonTitles: NSLocalizedString(@"Rename", @"Rename"), nil
                              ];
    [alertView setAlertViewStyle: UIAlertViewStylePlainTextInput];
    [alertView setDelegate:self];
    NSIndexPath *indexPath = [[self collectionView] indexPathForCell:cellDocument];
    [alertView setTag:[indexPath item]];
    UITextField *textField = [alertView textFieldAtIndex:0];
    [textField setText:[[cellDocument labelTitle] text]];
    [textField setClearButtonMode:UITextFieldViewModeAlways];
    [textField setDelegate:self];
    [self setRenameAlertView:alertView];
    [[self renameAlertView] show];
}

- (void)email:(MTCollectionViewCellDocument *)cell {
    if ([MFMailComposeViewController canSendMail] == NO) {
        
        //Display an alert...
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle: NSLocalizedString(@"Warning", @"Heading of a warning alert message.")
                                                            message: NSLocalizedString(@"Device is not configured for email.", @"Warning that email is not setup.")
                                                           delegate: nil
                                                  cancelButtonTitle: NSLocalizedString(@"OK", @"OK button on an alert message.")
                                                  otherButtonTitles: nil];
        [alertView show];
        
    } else {
        
        NSURL *fileToAttach = [self urlForDocumentCell:cell];
        
        MAReportDocument *documentReport = [[MAReportDocument alloc] initWithFileURL:fileToAttach];
        
        if ([documentReport documentState] != UIDocumentStateClosed) {
            [documentReport closeWithCompletionHandler:^(BOOL success) {
                if (success) {
                    [self email:cell];
                }
            }];
            
        } else {
            
            [documentReport performAsynchronousFileAccessUsingBlock:^{
                NSData *data = [NSData dataWithContentsOfURL:[documentReport fileURL]];
                if (data) {
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        
                        NSMutableString *messageBody = [[NSMutableString alloc] initWithString:NSLocalizedString(@"The attached document can be opened with the Mad Viewer available on iOS.",
                                                                                                                 @"The attached document can be opened with the Mad Viewer available on iOS.")];
                        
                        NSString *subject = [NSString stringWithFormat:NSLocalizedString(@"MAD Document %@.", @"MAD Document %@."), [documentReport name]];
                        [messageBody appendString:@"\n\nhttp://www.everydayapps.com/\n\n"];
                        
                        MFMailComposeViewController	*mailComposer = [[MFMailComposeViewController alloc] init];
                        [mailComposer setMailComposeDelegate: self];
                        [mailComposer setMessageBody:messageBody isHTML:NO];
                        [mailComposer setSubject:subject];
                        
                        NSString *name = [NSString stringWithFormat:@"%@.%@", [documentReport name], MTDocumentExtentionMobleApplicationDocument];
                        [mailComposer addAttachmentData:data mimeType:@"application/vnd.everydayapps.mad" fileName:name];
                        
                        if ([UIDevice isPad]) {
                            [mailComposer setModalPresentationStyle:UIModalPresentationFormSheet];
                            [mailComposer setModalTransitionStyle:UIModalTransitionStyleFlipHorizontal];
                            [mailComposer setProvidesPresentationContextTransitionStyle:YES];
                            [mailComposer setModalInPopover:NO];
                        }
                        [self presentViewController:mailComposer animated:YES completion:nil];
                        
                    });
                }
            }];
        }
    }
}

#pragma mark -
#pragma mark - MFMailComposeViewController delegate protocol

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    if (result == MFMailComposeResultSent) {
        [UAAppReviewManager userDidSignificantEvent:YES];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
    [error presentErrorToUser];
}

#pragma mark -
#pragma mark - NSFileManager delegate protocol

- (BOOL)fileManager:(NSFileManager *)fileManager shouldMoveItemAtURL:(NSURL *)srcURL toURL:(NSURL *)dstURL {
    return YES;
}

- (BOOL)fileManager:(NSFileManager *)fileManager shouldProceedAfterError:(NSError *)error movingItemAtURL:(NSURL *)srcURL toURL:(NSURL *)dstURL {
    
    //Only allow the thumbnails to proceed to after an error.
    return [[[dstURL pathExtension] lowercaseString] isEqualToString:MTDocumentExtentionPoratableNetworkGraphic];
}

#pragma mark -
#pragma mark - UIAlertView delegate protocol

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([alertView cancelButtonIndex] != buttonIndex) {
        
        UITextField *textField = [alertView textFieldAtIndex:0];
        NSMutableCharacterSet *characterSet = [[NSMutableCharacterSet alloc] init];
        [characterSet formUnionWithCharacterSet:[NSCharacterSet alphanumericCharacterSet]];
        [characterSet formUnionWithCharacterSet:[NSCharacterSet whitespaceCharacterSet]];
        
        NSString *text = [[[textField text] componentsSeparatedByCharactersInSet:[characterSet invertedSet]] componentsJoinedByString:@""];
        if ([text length] == 0) {
            UIAlertView *validFileName = [[UIAlertView alloc] initWithTitle:@"Validation Error"
                                                                    message:@"Filename not valid."
                                                                   delegate:nil
                                                          cancelButtonTitle:@"Dismiss"
                                                          otherButtonTitles: nil];
            [validFileName show];
        } else {
            NSURL *urlToRename = nil;
            if ([alertView tag] < [[self availableFilesCache] count]) {
                urlToRename = [self availableFilesCache][[alertView tag]];
                NSString *fileName = [textField text];
                NSString *filenameWithExtention = [fileName stringByAppendingPathExtension:MTDocumentExtentionMobleApplicationDocument];
                NSURL *newUrl = [[urlToRename URLByDeletingLastPathComponent] URLByAppendingPathComponent:filenameWithExtention isDirectory:NO];
                NSError *error = nil;
                [[NSFileManager defaultManager] moveItemAtURL:urlToRename toURL:newUrl error:&error];
                if (error != nil) {
                    [error presentErrorToUser];
                    
                } else {
                    
                    NSFileManager *fileManager = [[NSFileManager alloc] init];
                    [fileManager setDelegate:self];
                    
                    NSURL *thumbnailUrlOld = [MAReportDocument thumbnailUrlForMadUrl:urlToRename];
                    NSURL *thumbnailUrlNew = [MAReportDocument thumbnailUrlForMadUrl:newUrl];
                    [fileManager moveItemAtURL:thumbnailUrlOld toURL:thumbnailUrlNew error:&error];
                    
                    thumbnailUrlOld = [MAReportDocument thumbnailWithBorderUrlForMadUrl:urlToRename];
                    thumbnailUrlNew = [MAReportDocument thumbnailWithBorderUrlForMadUrl:newUrl];
                    [fileManager moveItemAtURL:thumbnailUrlOld toURL:thumbnailUrlNew error:&error];
                    [self updateFileList:self];
                }
            }
        }
    }
}

#pragma mark -
#pragma mark Text Field Delegate Protocol

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self alertView:[self renameAlertView] clickedButtonAtIndex:1];
    [[self renameAlertView] dismissWithClickedButtonIndex:1 animated:YES];
    return YES;
}

#pragma mark -
#pragma mark - UIMenuController required methods

- (BOOL)canBecomeFirstResponder {
    return NO;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    BOOL result = NO;
    /*
     if (action == @selector(paste:)) {
     NSURL *urlToDrop = [[UIPasteboard generalPasteboard] URL];
     if (urlToDrop != nil) {
     result = [[urlToDrop pathExtension]  isEqualToString:MTDocumentExtentionMobleApplicationDocument];
     }
     }*/
    return result;
}

- (void)paste:(id)sender {
    NSURL *url = [[UIPasteboard generalPasteboard] URL];
    NSData *data = [[NSData alloc] initWithContentsOfURL:url];
    NSFileWrapper *fileWrapper = [[NSFileWrapper alloc] initWithSerializedRepresentation:data];
    NSString *name = [[url lastPathComponent] stringByDeletingPathExtension];
    NSURL *destinationUrl = [NSURL uniqueUrlForDocumentWithName:name
                                                  withExtension:MTDocumentExtentionMobleApplicationDocumentArchive];
    
    NSFileWrapperWritingOptions writingOptions = NSFileWrapperWritingAtomic | NSFileWrapperWritingWithNameUpdating;
    NSError* fileWrittingError = nil;
    [fileWrapper writeToURL:destinationUrl options:writingOptions originalContentsURL:url error:&fileWrittingError];
    if (fileWrittingError) {
        fileWrittingError = nil;
        [fileWrapper writeToURL:destinationUrl options:writingOptions originalContentsURL:url error:&fileWrittingError];
    }
    [self updateFileList:self];
}

#pragma mark -
#pragma mark Collection View Delegate Protocol

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    return YES;
}


- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger numberOfSections = [[self collectionView] numberOfSections];
    for (NSUInteger section = 0; section < numberOfSections; section++) {
        NSUInteger numberOfItemsInSection = [[self collectionView] numberOfItemsInSection:section];
        for (NSUInteger item = 0; item < numberOfItemsInSection; item++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:0];
            UICollectionViewCell *cell = [[self collectionView] cellForItemAtIndexPath:indexPath];
            if ([self isEditing]) {
                [cell startWobble];
            }
        }
    }
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingSupplementaryView:(UICollectionReusableView *)view forElementOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath { }

- (void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    [self selectionsUpdated];
    MTCollectionViewCellDocument *cell = (MTCollectionViewCellDocument *)[collectionView cellForItemAtIndexPath:indexPath];
    [cell performSelectionAnimations];
    
    NSURL *fileUrl = [self availableFilesCache][[indexPath row]];
    NSURL *url = [MAReportDocument thumbnailUrlForMadUrl:fileUrl];
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
    
    NSURL *fileUrl = [self availableFilesCache][[indexPath row]];
    NSURL *url = [MAReportDocument thumbnailWithBorderUrlForMadUrl:fileUrl];
    NSString *path = [url path];
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:path];
    if (image == nil) {
        image = [MTTableViewCellDocument defaultThumbnail];
    }
    [[cell imagePreview] setImage:image];

}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([self isEditing] == NO) {
        [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    } else {
        [collectionView selectItemAtIndexPath:indexPath animated:YES scrollPosition:UICollectionViewScrollPositionCenteredVertically];
    }
    [self selectionsUpdated];

    MTCollectionViewCellDocument *cell = (MTCollectionViewCellDocument *)[collectionView cellForItemAtIndexPath:indexPath];
    [cell performSelectionAnimations];
    
    NSURL *fileUrl = [self availableFilesCache][[indexPath row]];
    NSURL *url = [MAReportDocument thumbnailUrlForMadUrl:fileUrl];
    NSString *path = [url path];
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:path];
    if (image == nil) {
        image = [MTTableViewCellDocument defaultThumbnail];
    }
    [[cell imagePreview] setImage:image];
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    [self selectionsUpdated];
    
    MTCollectionViewCellDocument *cell = (MTCollectionViewCellDocument *)[collectionView cellForItemAtIndexPath:indexPath];
    [cell performDeselectionAnimations];
    
    NSURL *fileUrl = [self availableFilesCache][[indexPath row]];
    NSURL *url = [MAReportDocument thumbnailWithBorderUrlForMadUrl:fileUrl];
    NSString *path = [url path];
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:path];
    if (image == nil) {
        image = [MTTableViewCellDocument defaultThumbnail];
    }
    [[cell imagePreview] setImage:image];
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
    MTCollectionViewCellDocument *cell = (MTCollectionViewCellDocument *)[collectionView cellForItemAtIndexPath:indexPath];
    [cell performSelectionAnimations];
    return YES;
}

#pragma mark -
#pragma mark Collection View Data Protocol

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    MTCollectionViewCellDocument *result = [[self collectionView] dequeueReusableCellWithReuseIdentifier:MTCollectionViewCellDocumentIdentifier
                                                                                      forIndexPath:indexPath];
    [result setDelegate:self];
    if ([indexPath row] < [[self availableFilesCache] count]) {
        NSURL *fileUrl = [self availableFilesCache][[indexPath row]];
        //[[result imagePreview] setImage:[MTTableViewCellDocument defaultThumbnail]];
        [result setText: [MADocument fileNameForMadUrl:fileUrl]];
        [self loadCollectionViewPreviewImageForIndexPath:indexPath];
    } else {
        [result setText: @""];
        [[result imagePreview] setImage:[MTTableViewCellDocument defaultThumbnail]];
    }
    if ([self isEditing]) {
        [result startWobble];
    }
    if ([[result contentView] alpha] < 0.99999f && [self cellsHidden] == NO) {
        __block __weak UIView *blockView = [result contentView];
        __block __weak UIActivityIndicatorView *activityIndicatorView;
        for (UIView *subview in [[result contentView] subviews]) {
            if ([subview isKindOfClass:[UIActivityIndicatorView class]]) {
                activityIndicatorView = (UIActivityIndicatorView *)subview;
                break;
            }
        }
        [UIView animateWithDuration:1.0000f animations:^{
            [blockView setAlpha:1.0000f];
            [activityIndicatorView setAlpha:0.0000f];
        } completion:^(BOOL finished) {
            [activityIndicatorView removeFromSuperview];
        }];
    }
    return result;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [[self availableFilesCache] count];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (void)loadCollectionViewPreviewImageForIndexPath:(NSIndexPath *)indexPath {
    
    
    __block __weak NSURL *fileUrl = [self availableFilesCache][[indexPath row]];
    __block __weak MTViewControllerOpenDocument *openDocument = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        dispatch_sync(dispatch_get_main_queue(), ^(void) {

            MTCollectionViewCellDocument *visibleCell = (MTCollectionViewCellDocument *)[[openDocument collectionView] cellForItemAtIndexPath:indexPath];
            NSURL *url = [MAReportDocument thumbnailWithBorderUrlForMadUrl:fileUrl];
            NSString *path = [url path];
            UIImage *image = [[UIImage alloc] initWithContentsOfFile:path];
            if (image) {
                [[visibleCell imagePreview] setImage: image];
            } else {
                UIImage *defaultThumbnail = [MTTableViewCellDocument defaultThumbnail];
                [[visibleCell imagePreview] setImage: defaultThumbnail];
            }
            [visibleCell setNeedsLayout];

        });
    });
}

#pragma mark -
#pragma mark Collection View Flow Layout Delegate

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return [UIDevice isPad] ? UIEdgeInsetsMake(25.0000f, 25.0000f, 25.0000f, 25.0000f) :
                                UIEdgeInsetsMake(5.0000f, 5.0000f, 5.0000f, 5.0000f);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return [UIDevice isPad] ? 50.0000f : 5.0000f;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return [UIDevice isPad] ? 50.0000f : 5.0000f;
}

@end
