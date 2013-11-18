//
//  FlipsideViewController.m
//  Reports
//
//  Created by Michael Thomason on 1/2/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MTViewControllerOpenDocument.h"
#import "MADWatermarkView.h"
#import "MTBarcode.h"
#import "MTBarcodeView.h"

NSString * const MTSegueShowAddDocument = @"showAddDocument";
NSString * const MTSegueShowOpenDocument = @"openDocument";
NSString * const MTCollectionViewCellDocumentIdentifier = @"MTCollectionViewCellDocumentIdentifier";

@interface MTViewControllerOpenDocument() <UIAlertViewDelegate, NSFileManagerDelegate>

@property (nonatomic, retain) IBOutlet UICollectionViewFlowLayout *collectionViewFlowLayout;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *barButtonItemTitle;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *barButtonItemEdit;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *barButtonItemEditDone;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *barButtonItemTrash;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *barButtonItemAction;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *barButtonItemInformation;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *barButtonItemAbout;

@property (nonatomic, retain) UIAlertView *renameAlertView;

@property (nonatomic, retain) IBOutlet UIBarButtonItem *barButtonItemAddNewDocument;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *barButtonItemLicensing;

@property (nonatomic, retain) IBOutlet MTTitleView *titleView;

@property (nonatomic, retain) UIPopoverController *openDocumentPopoverController;
@property (nonatomic, retain) UIPopoverController *aboutPopoverController;
@property (nonatomic, retain) UIPopoverController *licensingPopoverController;

@property (nonatomic, retain) NSURL *urlBeingOpended;
@property (nonatomic, retain) NSMutableArray *availableFilesCache;
@property (nonatomic, retain) NSMutableDictionary *previewLoadingOperations;

@property (nonatomic, retain) MTReportViewerController *reportViewer;

@property (nonatomic, retain) UILongPressGestureRecognizer *longPressGestureRecognizer;
@property (nonatomic, retain) UITapGestureRecognizer *tapGestureRecognizer;

@property (nonatomic, assign) BOOL shouldShowAddDocumentPopover;
@property (nonatomic, assign) BOOL editModeEnabled;
@property (nonatomic, assign) BOOL bothContentControllersDisplayed;

@property (nonatomic, assign) BOOL needsEmailMenu;

@property (nonatomic, assign) BOOL cellsHidden;

@end

@implementation MTViewControllerOpenDocument

- (void)dealloc {
    [_reportViewer release];
    [_renameAlertView release];
    [_barButtonItemEditDone release];
    [_previewLoadingOperations release];
    [_tapGestureRecognizer release];
    [_longPressGestureRecognizer release];
    [_urlBeingOpended release];
    [_availableFilesCache release];
    [_titleView release];
    [_licensingPopoverController release];
    [_openDocumentPopoverController release];
    [_aboutPopoverController release];
    [_barButtonItemAddNewDocument release];
    [_barButtonItemLicensing release];
    [_collectionViewFlowLayout release];
    [_barButtonItemTitle release];
    [_barButtonItemEdit release];
    [_barButtonItemTrash release];
    [_barButtonItemAction release];
    [_barButtonItemInformation release];
    [_barButtonItemAbout release];
    [super dealloc];
}

- (void)closeReport {
    
    __block MTViewControllerOpenDocument *blockSelf = self;

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
            [activityView release];
        }
    }
    [[self collectionView] setUserInteractionEnabled: NO];
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        
        MAReportDocument *activeDocument = [[MTActiveDocument sharedDocument] activeDocument];
        [activeDocument regenThumbnail];
        
        [activeDocument closeWithCompletionHandler:^(BOOL success) {
            if (success) {
                MAReportDocument *activeDocument = [[MTActiveDocument sharedDocument] activeDocument];
                [activeDocument setSuspended:YES];
                
                [NSFileManager wrapFile:[activeDocument fileURL] withExtention:MTDocumentExtentionMobleApplicationDocument overwrite:YES completion:^(BOOL success, NSURL *resultUrl) {
                    
                    [MADocument deleteFromDiskQuick:activeDocument completion:^(BOOL success) {
                        [[MTActiveDocument sharedDocument] setActiveDocument:nil];
                        dispatch_sync(dispatch_get_main_queue(), ^{
                            [[blockSelf collectionView] setUserInteractionEnabled: YES];
                            [blockSelf setCellsHidden:NO];
                            [[blockSelf collectionView] reloadData];
                        });
                    }];
                    
                }];
            };
        }];
        
    });
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
    
    if ([AppDelegate isMadViewer] && [UIDevice isPad]) {

    } else if ([AppDelegate isMadViewer] && ![UIDevice isPad]) {
    
    } else {
        [[self openDocumentPopoverController] dismissPopoverAnimated:YES];
    }
    if ([AppDelegate isMadViewer]) {
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

    NSMutableDictionary *d = [[NSMutableDictionary alloc] init];
    [self setPreviewLoadingOperations:d];
    [d release];
    
    UIBarButtonItem *barButtonItemEditDone = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(edit:)];
    [self setBarButtonItemEditDone:barButtonItemEditDone];
    [barButtonItemEditDone release];
    
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

        /*
        [self setEditModeEnabled:NO];
        [self setEditing:NO animated:YES];
        [[self navigationItem] setRightBarButtonItem:[self barButtonItemEdit] animated:YES];

        CGPoint locationInView = [sender locationInView:[self collectionView]];
        NSIndexPath *indexPath = [[self collectionView] indexPathForItemAtPoint:locationInView];
        if (!indexPath) {
            [[[self collectionView] collectionViewLayout] invalidateLayout];
        }
        
        for (NSUInteger item = 0; item < [[self collectionView] numberOfItemsInSection:0]; item++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:0];
            MTCollectionViewCellDocument *cell = (MTCollectionViewCellDocument *)[[[self collectionView] cellForItemAtIndexPath:indexPath] retain];
            [cell stopWobble];
            [cell performDeselectionAnimations];
            
            NSURL *fileUrl = [self availableFilesCache][[indexPath row]];
            NSURL *url = [MAReportDocument thumbnailWithBorderUrlForMadUrl:fileUrl];
            NSString *path = [url path];
            UIImage *image = [[UIImage alloc] initWithContentsOfFile:path];
            if (image == nil) {
                image = [[MTTableViewCellDocument defaultThumbnail] retain];
            }
            [[cell imagePreview] setImage:image];
            [image release];
            
            [cell release];
        }*/
        
    }
}

#pragma mark - UIViewController Overrides

- (void)setLetterpressBackground {
    UICollectionView *v = (UICollectionView *)[self collectionView];

    CGRect bounds = [v bounds];
    MADWatermarkView *watermarkView = [[MADWatermarkView alloc] initWithFrame:bounds];
    [v setBackgroundView:watermarkView];
    [watermarkView release];
    /*
    UILabel *bg = [[UILabel alloc] initWithFrame:[v bounds]];
    [bg setNumberOfLines:1];
    [bg setBaselineAdjustment:UIBaselineAdjustmentAlignCenters];
    [bg setLineBreakMode:NSLineBreakByClipping];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineBreakMode:NSLineBreakByClipping];
    [paragraphStyle setBaseWritingDirection:NSWritingDirectionLeftToRight];
    [paragraphStyle setAlignment:NSTextAlignmentCenter];
    
    NSMutableAttributedString *attributedStringMadDesigner = [[NSMutableAttributedString alloc] initWithString:@"MAD"];
    NSInteger length = [[attributedStringMadDesigner string] length];
    CGFloat fontSize = [UIDevice isPad] ? 400.0000f : 160.0000f;
    UIFont *fontb = [UIFont fontWithName:@"HelveticaNeue-CondensedBlack" size:fontSize];
    NSRange range = NSMakeRange(0, length);
    [attributedStringMadDesigner addAttribute:NSForegroundColorAttributeName value:[UIColor lightTextColor] range:range];
    [attributedStringMadDesigner addAttribute:NSFontAttributeName value:fontb range:range];
    [attributedStringMadDesigner addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:range];
    [attributedStringMadDesigner addAttribute:NSTextEffectAttributeName value:NSTextEffectLetterpressStyle range:range];
    [attributedStringMadDesigner addAttribute:NSKernAttributeName value:[NSNull null] range:range];
    [bg setAttributedText:attributedStringMadDesigner];
    [v setBackgroundView:bg];
    [paragraphStyle release];
     [attributedStringMadDesigner release];
    */
}

- (void)viewDidLoad {
    [super viewDidLoad];
    

    UIColor *barTintColor = [UIColor tintColor];
    UIColor *tintColor = [UIColor tintColor2];
    UIToolbar *toolbar = [[self navigationController] toolbar];
    [toolbar setBarTintColor:barTintColor];
    [toolbar setTintColor:tintColor];

    
    [self setLetterpressBackground];
    
    
    //MTBarcodeView *bview = [[MTBarcodeView alloc] initWithFrame:CGRectMake(500.0000f, 100.0000f, 200.0000f, 200.0000f) type:MTBarcodeUpca borderStyle:MTBarcodeBorderStyleNone stringToEncode:@"72527270270" whitespaceWidth:10.0000f];
    //[[[self collectionView] backgroundView] addSubview:bview];
    //[bview release];
    
    
    UIColor *bgColor = [UIColor lightGrayColor];
    [[self collectionView] setBackgroundColor:bgColor];
    
    [self setCellsHidden:NO];
    UILabel *labelMadDesigner = [[UILabel alloc] initWithFrame:CGRectZero];
    [labelMadDesigner setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];

    NSAttributedString *attributedString = nil;
    if ([AppDelegate isMadDesigner]) {
        attributedString = [AppDelegate attributedStringMadDesigner];
    } else if ([AppDelegate isMadViewer]) {
        attributedString = [AppDelegate attributedStringMadViewer];
    }
    NSAssert(attributedString != nil, @"Navigation title is not set.");
    [labelMadDesigner setAttributedText:attributedString];
    [[self navigationItem] setTitleView:labelMadDesigner];
    [[[self navigationItem] titleView] sizeToFit];
    [labelMadDesigner release];

    [[self navigationItem] setHidesBackButton:YES];
    [self setEditModeEnabled:NO];
    
    UILongPressGestureRecognizer *longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(activateEditMode:)];
    [longPressGestureRecognizer setDelegate: self];
    [[self collectionView] addGestureRecognizer:longPressGestureRecognizer];
    [self setLongPressGestureRecognizer:longPressGestureRecognizer];
    [longPressGestureRecognizer release];
    
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(endEditMode:)];
    [tapGestureRecognizer setDelegate: self];
    [[self collectionView] addGestureRecognizer:tapGestureRecognizer];
    [self setTapGestureRecognizer:tapGestureRecognizer];
    [tapGestureRecognizer release];
    
    [[[self titleView] label] setText:NSLocalizedString(@"Reports", @"Reports")];

    NSMutableArray *fileUrlCache = [[NSMutableArray alloc] init];
    [self setAvailableFilesCache: fileUrlCache];
    [fileUrlCache release];
    
    [[self barButtonItemLicensing] setEnabled:[SKPaymentQueue canMakePayments]];
    
    [self setNeedsEmailMenu:YES];

    NSMutableArray *toolbarButtons = [[NSMutableArray alloc] initWithArray: [self toolbarItems]];
    [toolbarButtons removeObject:[self barButtonItemAction]];
    [self setToolbarItems:toolbarButtons animated:NO];
    [toolbarButtons release];
    
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
        [menuItem release];
        [menuItems release];
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
                [menuItem release];
                [menuItems release];
            });

            if ([[self toolbarItems] containsObject:[self barButtonItemAction]] == NO) {
                NSMutableArray *toolbarButtons = [[self toolbarItems] mutableCopy];
                [toolbarButtons insertObject:[self barButtonItemAction] atIndex:1];
                [self setToolbarItems:toolbarButtons animated:animated];
                [toolbarButtons release];
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
        MTCollectionViewCellDocument *cell = (MTCollectionViewCellDocument *)[[[self collectionView] cellForItemAtIndexPath:indexPath] retain];
        [cell performDeselectionAnimations];
        [cell release];
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
    return NO;
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
        [allpopovers release];
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
                [(MTViewController *)[navControl topViewController] setDelegate:self];
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
                if ([AppDelegate isMadViewer]) {
                    [[self aboutPopoverController]  setPopoverContentSize: CGSizeMake(420.0000f, 376.0000f)];
                } else {
                    [[self aboutPopoverController]  setPopoverContentSize: CGSizeMake(420.0000f, 480.0000f)];
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
            NSURL *url = [[self urlForDocumentCell:sender] retain];
            [self setUrlBeingOpended:url];
            [url release];
            foundUrl = YES;
        } else if ([sender isKindOfClass:[NSURL class]]) {
            NSURL *url = [sender retain];
            [self setUrlBeingOpended:url];
            [url release];
            foundUrl = YES;
        }

        if (foundUrl) {
            MTReportViewerController *viewControllerReportViewer = [(MTReportViewerController *)[(UINavigationController *)[segue destinationViewController] topViewController] retain];
            [viewControllerReportViewer setViewControllerDelegate:self];
            [self setReportViewer:viewControllerReportViewer];
            [MAReportDocument openManagedDocumentAtUrl:[self urlBeingOpended] withCompletionHandler:^(id managedDocument, BOOL success) {
                if (success) {
                    [managedDocument retain];
                    [[MTActiveDocument sharedDocument] setActiveDocument: managedDocument];
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
                        dispatch_sync(dispatch_get_main_queue(), ^{
                            [[self reportViewer] reload];
                        });
                    });
                    [managedDocument release];
                }
            }];
            [viewControllerReportViewer release];
            
        } else {
            NSAssert(foundUrl == NO, @"No URL to open.");
        }
        
    } else if ([[segue identifier] isEqualToString:MTSegueShowOpenDocument]) {
        BOOL foundUrl = NO;
        if ([sender isKindOfClass:[MTCollectionViewCellDocument class]]) {

            NSURL *url = [[self urlForDocumentCell:sender] retain];
            if (url != nil) {
                foundUrl = YES;
            }
            [self setUrlBeingOpended:url];
            [url release];
            
        } else if ([sender isKindOfClass:[NSURL class]])  {
            NSURL *url = [sender retain];
            if (url != nil) {
                [self setUrlBeingOpended:url];
                foundUrl = YES;
            }
            [url release];
        }
        if (foundUrl) {
            if ([[segue destinationViewController] isKindOfClass: [UINavigationController class]] || [[segue destinationViewController] isKindOfClass: [UITabBarController class]]) {

                if ([UIDevice isPad]) {
                    UITabBarController *tabBarController = (UITabBarController *)[segue destinationViewController];
                    UINavigationController *navController = (UINavigationController *)[[tabBarController viewControllers] objectAtIndex:0];
                    __block MTQueryBuilderContainerController *queryBuilderViewController = (MTQueryBuilderContainerController *)[navController topViewController];
                    [queryBuilderViewController setDelegate:self];

                    UINavigationController *navController2 = (UINavigationController *)[[tabBarController viewControllers] objectAtIndex:1];
                    MTReportDesignerViewController *reportDesignerViewController = (MTReportDesignerViewController *)[navController2 topViewController];
                    [reportDesignerViewController setDelegate:self];

                    UINavigationController *navController3 = (UINavigationController *)[[tabBarController viewControllers] objectAtIndex:2];
                    MTReportViewerController *reportViewerViewController = (MTReportViewerController *)[navController3 topViewController];
                    [reportViewerViewController setViewControllerDelegate:self];
                    
                    [MAReportDocument openManagedDocumentAtUrl:[self urlBeingOpended] withCompletionHandler:^(id managedDocument, BOOL success) {
                        if (success) {
                            [managedDocument retain];
                            [[MTActiveDocument sharedDocument] setActiveDocument: managedDocument];
                            [[queryBuilderViewController queryBuilderController] reloadDocument:managedDocument];
                            [[queryBuilderViewController queryBuilderControllerAdvanced] reloadDocument:managedDocument animated:YES];
                            [managedDocument release];
                        }
                    }];
                    
                    
                } else {
                    
                    UITabBarController *tabBarController = (UITabBarController *)[segue destinationViewController];
                    UINavigationController *navController = (UINavigationController *)[[tabBarController viewControllers] objectAtIndex:0];
                    __block MTQueryBuilderViewController *queryBuilderViewController = (MTQueryBuilderViewController *)[navController topViewController];
                    //[queryBuilderViewController setDelegate:self];
                    
                    UINavigationController *navController2 = (UINavigationController *)[[tabBarController viewControllers] objectAtIndex:1];
                    MTReportDesignerViewController *reportDesignerViewController = (MTReportDesignerViewController *)[navController2 topViewController];
                    [reportDesignerViewController setDelegate:self];
                    
                    UINavigationController *navController3 = (UINavigationController *)[[tabBarController viewControllers] objectAtIndex:2];
                    MTReportViewerController *reportViewerViewController = (MTReportViewerController *)[navController3 topViewController];
                    [reportViewerViewController setViewControllerDelegate:self];
                    
                    [MAReportDocument openManagedDocumentAtUrl:[self urlBeingOpended] withCompletionHandler:^(id managedDocument, BOOL success) {
                        if (success) {
                            [managedDocument retain];
                            [[MTActiveDocument sharedDocument] setActiveDocument: managedDocument];
                            [queryBuilderViewController reloadDocument:managedDocument];
                            [managedDocument release];
                        }
                    }];
                }
                
            } else if ([[segue destinationViewController] isKindOfClass:[MTQueryBuilderContainerController class]]) {
                //MTQueryBuilderContainerController *queryBuilderViewController = (MTQueryBuilderContainerController *)[segue destinationViewController];
                //[queryBuilderViewController setDelegate:self];
            } else if ([[segue destinationViewController] isKindOfClass:[MTQueryBuilderViewController class]]) {
                
                __block MTQueryBuilderViewController *queryBuilderViewController = (MTQueryBuilderViewController *)[[segue destinationViewController] topViewController];
                [MAReportDocument openManagedDocumentAtUrl:[self urlBeingOpended] withCompletionHandler:^(id managedDocument, BOOL success) {
                    if (success) {
                        [managedDocument retain];
                        [[MTActiveDocument sharedDocument] setActiveDocument: managedDocument];
                        [queryBuilderViewController reloadDocument:managedDocument];
                        [managedDocument release];
                    }
                }];
            }
        }
    }
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [[MTVerificationController sharedInstance] iOS7VerifyReceipt];
    });
    
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
    __block MTQueryBuilderAdvancedViewController *advanced = nil;
    __block MTQueryBuilderViewController *standard = nil;

    if ([AppDelegate isMadDesigner]) {
        UIViewController *childController = [contentController retain];
        if ([contentController isKindOfClass:[UINavigationController class]]) {
            UINavigationController *childNavigationController = (UINavigationController *)contentController;
            if ([[childNavigationController topViewController] isKindOfClass:[MTQueryBuilderViewController class]]) {
                standard = (MTQueryBuilderViewController *)[(UINavigationController *)childNavigationController topViewController];
                [self setBothContentControllersDisplayed:NO];
            }
        } else if ([contentController isKindOfClass:[MTQueryBuilderAdvancedViewController class]]) {
            advanced = (MTQueryBuilderAdvancedViewController *)contentController;
            [self setBothContentControllersDisplayed:NO];
        } else if ([contentController isKindOfClass:[MTQueryBuilderViewController class]]) {
            standard = (MTQueryBuilderViewController *)contentController;
            [self setBothContentControllersDisplayed:YES];
        }
        
        
        
        if ([self bothContentControllersDisplayed] && standard != nil && standard != nil) {
            
            //[[self standardQueryBuilder] setDelegate: self];
            [MAReportDocument openManagedDocumentAtUrl:[self urlBeingOpended] withCompletionHandler:^(id managedDocument, BOOL success) {
                
                if (success) {
                    [managedDocument retain];
                    [[MTActiveDocument sharedDocument] setActiveDocument: managedDocument];
                    if ([contentController isKindOfClass:[MTQueryBuilderAdvancedViewController class]]) {
                    }
                    [standard reloadDocument:managedDocument];
                    [advanced reloadDocument:managedDocument animated:YES];
                    [managedDocument release];
                }
            }];
            
            
        }
        [childController release];
    } else if ([AppDelegate isMadViewer]) {
        __block __weak MTReportViewerController *viewController = (MTReportViewerController *)contentController;
        
        [MAReportDocument openManagedDocumentAtUrl:[self urlBeingOpended] withCompletionHandler:^(id managedDocument, BOOL success) {
            
                                   if (success) {
                                       [managedDocument retain];
                                       [[MTActiveDocument sharedDocument] setActiveDocument: managedDocument];
                                       [viewController reload:viewController];
                                       [managedDocument release];
                                   }
                                   
                               }];
    }
}

- (void)deleteDocumentRepresentedByCell:(MTCollectionViewCellDocument *)cell {
    NSIndexPath *cellPath = [[self collectionView] indexPathForCell:cell];
    [self deleteDocumentAtIndexPath:cellPath];
}

- (void)viewControllerDidFinish:(id)sender {
    [self setShouldShowAddDocumentPopover:YES];
    
    if ([[MTActiveDocument sharedDocument] activeDocument] != nil) {
        [self closeReport];
    }
    
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
        [mFMailComposeViewController release];
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
        [uIAlertView release];
    }
}

- (void)setupQueryDesignerController:(MTQueryBuilderViewController *)tvc usingFileAtUrl:(NSURL*)url {
    //[tvc setDelegate: self];
    [MAReportDocument openManagedDocumentAtUrl:url withCompletionHandler:^(id managedDocument, BOOL success) {

        if (success) {
            [managedDocument retain];

            [[MTActiveDocument sharedDocument] setActiveDocument: managedDocument];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [tvc reloadDocument:managedDocument];
                });
            });
            [managedDocument release];
        }
        
    }];
}

#pragma mark - Actions

- (NSURL *)urlForDocumentCell:(MTCollectionViewCellDocument *)cellDocument {
    NSInteger row = [[[self collectionView] indexPathForCell:cellDocument] row];
    return [[[[self availableFilesCache] objectAtIndex: row] retain] autorelease];
    
}

- (IBAction)updateFileList:(id)sender {
    
    NSArray *madFiles = [NSFileManager madFiles];
    NSMutableArray *a = [[NSMutableArray alloc] initWithArray:madFiles];
    [self setAvailableFilesCache: a];
    [a release];
    
    [[self collectionView] reloadData];
    
}

- (IBAction)add:(id)sender { }

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
                UICollectionViewCell *cell = [[[self collectionView] cellForItemAtIndexPath:indexPath] retain];
                [cell startWobble];
                [cell release];
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
            MTCollectionViewCellDocument *cell = (MTCollectionViewCellDocument *)[[[self collectionView] cellForItemAtIndexPath:indexPath] retain];
            [cell stopWobble];
            [cell performDeselectionAnimations];
            
            NSURL *fileUrl = [self availableFilesCache][[indexPath row]];
            NSURL *url = [MAReportDocument thumbnailWithBorderUrlForMadUrl:fileUrl];
            NSString *path = [url path];
            UIImage *image = [[UIImage alloc] initWithContentsOfFile:path];
            if (image == nil) {
                image = [[MTTableViewCellDocument defaultThumbnail] retain];
            }
            [[cell imagePreview] setImage:image];
            [image release];

            [cell release];
        }
    }
    
}

- (IBAction)about:(id)sender {
    NSString *applicationName = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleNameKey];
    NSString *title = [NSString stringWithFormat:NSLocalizedString(@"About %@", @"About Mad Designer"),  applicationName];
    NSString *message = NSLocalizedString(@"© Everyday Apps LLC 2012-2013.  Software created by Michael Thomason for Everyday Apps LLC.",
                                          @"© Everyday Apps LLC 2012-2013.  Software created by Michael Thomason for Everyday Apps LLC.");
    NSString *buttonTitle = NSLocalizedString(@"Continue", @"Continue");

    MTAlertView *alertView = [[MTAlertView alloc] initWithTitle: title
                                                        message: message
                                              cancelButtonTitle: buttonTitle
                                               otherButtonTitle: nil onDismiss:nil onCancel:nil];
    [alertView show];
    [alertView autorelease];
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
            MTCollectionViewCellDocument *documentCell = [(MTCollectionViewCellDocument *)[[self collectionView] cellForItemAtIndexPath:selectedCellLocation] retain];
            if (documentCell != nil) {
                if ([documentCell isSelected]) {
                    NSURL *fileUrl = [self availableFilesCache][item];
                    [wrappedUrls addObject:fileUrl];
                    [documentCell dimTint];
                }
            }
            [documentCell release];
        }
    }
    
    UIActivityViewControllerCompletionHandler activityViewControllerCompletionHandler = ^(NSString *activityType, BOOL completed) {
    
        NSUInteger numberOfSections = [[self collectionView] numberOfSections];
        for (NSUInteger section = 0; section < numberOfSections; section++) {
            NSUInteger numberOfItemsInSection = [[self collectionView] numberOfItemsInSection:section];
            for (NSUInteger item = 0; item < numberOfItemsInSection; item++) {
                NSIndexPath *selectedCellLocation = [NSIndexPath indexPathForItem:item inSection:section];
                MTCollectionViewCellDocument *documentCell = [(MTCollectionViewCellDocument *)[[self collectionView] cellForItemAtIndexPath:selectedCellLocation] retain];
                if (documentCell != nil) {
                    if ([documentCell isSelected]) {
                        [documentCell normalizeTint];
                    }
                }
                [documentCell release];
            }
        }
    
    };
    
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:wrappedUrls applicationActivities:@[]];
    [activityViewController setExcludedActivityTypes:@[UIActivityTypeAssignToContact, UIActivityTypePostToFacebook, UIActivityTypePostToFlickr, UIActivityTypePostToTwitter, UIActivityTypePostToVimeo]];
    [activityViewController setCompletionHandler:activityViewControllerCompletionHandler];
    [self presentViewController:activityViewController animated:YES completion:^{}];
    [activityViewController release];
    
    [wrappedUrls release];
}

- (IBAction)delete:(id)sender {
    if ([self collectionView] != nil) {
        NSMutableArray *itemsToDelete = [[NSMutableArray alloc] init];
        NSUInteger numberOfSections = [[self collectionView] numberOfSections];
        for (NSUInteger section = 0; section < numberOfSections; section++) {
            NSUInteger numberOfItemsInSection = [[self collectionView] numberOfItemsInSection:section];
            for (NSUInteger item = 0; item < numberOfItemsInSection; item++) {
                NSIndexPath *selectedCellLocation = [NSIndexPath indexPathForItem:item inSection:section];
                MTCollectionViewCellDocument *documentCell = [(MTCollectionViewCellDocument *)[[self collectionView] cellForItemAtIndexPath:selectedCellLocation] retain];
                if (documentCell != nil) {
                    if ([documentCell isSelected]) {
                        [itemsToDelete addObject:selectedCellLocation];
                    }
                }
                [documentCell release];
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
//        updateFileList
        [indexSet release];
        [itemsToDelete release];
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
    MTCollectionViewCellDocument *cellDocument = [sender retain];
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
    [alertView release];
    [cellDocument release];
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
        [alertView release];
        
    } else {
        
        NSURL *fileToAttach = [self urlForDocumentCell:cell];
        
        MAReportDocument *documentReport = [[MAReportDocument alloc] initWithFileURL:fileToAttach];
        
        if ([documentReport documentState] != UIDocumentStateClosed) {
            [documentReport closeWithCompletionHandler:^(BOOL success) {
                if (success) {
                    [self email:[[cell retain] autorelease]];
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
                        
                        [messageBody release];
                        
                    });
                }
            }];
        }
        
        [documentReport release];
        
    }
    
}

#pragma mark -
#pragma mark - MFMailComposeViewController delegate protocol

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
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
        
        UITextField *textField = [[alertView textFieldAtIndex:0] retain];
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
            [validFileName release];
        } else {
            NSURL *urlToRename = nil;
            if ([alertView tag] < [[self availableFilesCache] count]) {
                urlToRename = [self availableFilesCache][[alertView tag]];
                NSString *fileName = [textField text];
                NSString *filenameWithExtention = [fileName stringByAppendingPathExtension:MTDocumentExtentionMobleApplicationDocument];
                NSURL *newUrl = [[[urlToRename URLByDeletingLastPathComponent] URLByAppendingPathComponent:filenameWithExtention isDirectory:NO] retain];
                NSError *error = nil;
                [[NSFileManager defaultManager] moveItemAtURL:urlToRename toURL:newUrl error:&error];
                if (error != nil) {
                    [error presentErrorToUser];
                    
                } else {
                    
                    NSFileManager *fileManager = [[NSFileManager alloc] init];
                    [fileManager setDelegate:self];
                    
                    NSURL *thumbnailUrlOld = [[MAReportDocument thumbnailUrlForMadUrl:urlToRename] retain];
                    NSURL *thumbnailUrlNew = [[MAReportDocument thumbnailUrlForMadUrl:newUrl] retain];
                    [fileManager moveItemAtURL:thumbnailUrlOld toURL:thumbnailUrlNew error:&error];
                    [thumbnailUrlNew release]; [thumbnailUrlOld release];
                    
                    thumbnailUrlOld = [[MAReportDocument thumbnailWithBorderUrlForMadUrl:urlToRename] retain];
                    thumbnailUrlNew = [[MAReportDocument thumbnailWithBorderUrlForMadUrl:newUrl] retain];
                    [fileManager moveItemAtURL:thumbnailUrlOld toURL:thumbnailUrlNew error:&error];

                    [self updateFileList:self];
                    
                    [fileManager release];
                    [thumbnailUrlOld release];
                    [thumbnailUrlNew release];
                }
                [newUrl release];
            }
        }
        [characterSet release];
        [textField release];
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
    NSURL *destinationUrl = [[NSURL uniqueUrlForDocumentWithName:name
                                                   withExtension:MTDocumentExtentionMobleApplicationDocumentArchive] retain];
    
    NSFileWrapperWritingOptions writingOptions = NSFileWrapperWritingAtomic | NSFileWrapperWritingWithNameUpdating;
    NSError* fileWrittingError = nil;
    [fileWrapper writeToURL:destinationUrl options:writingOptions originalContentsURL:url error:&fileWrittingError];
    if (fileWrittingError) {
        fileWrittingError = nil;
        [fileWrapper writeToURL:destinationUrl options:writingOptions originalContentsURL:url error:&fileWrittingError];
    }
    [self updateFileList:self];
    [destinationUrl release];
    [fileWrapper release];
    [data release];
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
            UICollectionViewCell *cell = [[[self collectionView] cellForItemAtIndexPath:indexPath] retain];
            if ([self isEditing]) {
                [cell startWobble];
            }
            [cell release];
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
        image = [[MTTableViewCellDocument defaultThumbnail] retain];
    }
    [[cell imagePreview] setImage:image];
    [image release];
    //[cell setNeedsDisplay];


}

- (void)collectionView:(UICollectionView *)collectionView didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    MTCollectionViewCellDocument *cell = (MTCollectionViewCellDocument *)[collectionView cellForItemAtIndexPath:indexPath];
    [cell performDeselectionAnimations];
    
    NSURL *fileUrl = [self availableFilesCache][[indexPath row]];
    NSURL *url = [MAReportDocument thumbnailWithBorderUrlForMadUrl:fileUrl];
    NSString *path = [url path];
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:path];
    if (image == nil) {
        image = [[MTTableViewCellDocument defaultThumbnail] retain];
    }
    [[cell imagePreview] setImage:image];
    [image release];
    //[cell setNeedsDisplay];

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
        image = [[MTTableViewCellDocument defaultThumbnail] retain];
    }
    [[cell imagePreview] setImage:image];
    [image release];
    //[cell setNeedsDisplay];

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
        image = [[MTTableViewCellDocument defaultThumbnail] retain];
    }
    [[cell imagePreview] setImage:image];
    [image release];
    //[cell setNeedsDisplay];

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
        __block UIView *blockView = [result contentView];
        __block UIActivityIndicatorView *activityIndicatorView;
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
            [image release];
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
