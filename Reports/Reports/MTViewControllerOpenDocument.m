//
//  FlipsideViewController.m
//  Reports
//
//  Created by Michael Thomason on 1/2/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MTViewControllerOpenDocument.h"

NSString * const MTSegueShowAddDocument = @"showAddDocument";
NSString * const MTSegueShowOpenDocument = @"openDocument";

NSString * const MTCollectionViewCellDocumentIdentifier = @"MTCollectionViewCellDocumentIdentifier";

@interface FileRepresentation : NSObject

@property (nonatomic, retain) NSString* fileName;
@property (nonatomic, retain) NSURL* url;
@property (nonatomic, retain) NSURL* previewURL;

- (id)initWithFileName:(NSString*)fileName url:(NSURL*)url;

@end

@implementation FileRepresentation

- (void)dealloc {
    [_fileName release];
    [_url release];
    [_previewURL release];
    [super dealloc];
}

- (id)initWithFileName:(NSString *)fileName url:(NSURL *)url {
    self = [super init];
    if (self) {
        NSString *f = [[NSString alloc] initWithString:fileName];
        [self setFileName: f];
        [f release];
        
        NSURL *u = [url retain];
        [self setUrl:u];
        [u release];
                
    }
    
    return self;
}

+ (id)fileRepresentationWithName:(NSString *)fileName andUrl:(NSURL *)url {
    return [[[FileRepresentation alloc] initWithFileName:fileName url:url] autorelease];
}

- (BOOL)isEqual:(FileRepresentation*)object {
    return [object isKindOfClass:[FileRepresentation class]] && [_fileName isEqual:object.fileName];
}

@end

@interface MTViewControllerOpenDocument()

@property (nonatomic, retain) IBOutlet UICollectionViewFlowLayout *collectionViewFlowLayout;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *barButtonItemTitle;
@property (nonatomic, retain) IBOutlet MTTitleView *titleView;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *buttonAddNewDocument;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *buttonLicensing;

@property (nonatomic, retain) UIPopoverController *openDocumentPopoverController;
@property (nonatomic, retain) NSURL *urlBeingOpended;
@property (nonatomic, retain) NSMutableArray *availableFilesCache;
@property (nonatomic, retain) NSMutableArray *availableFilesCacheMetaData;
@property (nonatomic, retain) NSMutableDictionary *previewLoadingOperations;

@property (nonatomic, retain) MTQueryBuilderAdvancedViewController *advancedQueryBuilder;
@property (nonatomic, retain) MTQueryBuilderViewController *standardQueryBuilder;

@property (nonatomic, retain) UILongPressGestureRecognizer *longPressGestureRecognizer;
@property (nonatomic, retain) UITapGestureRecognizer *tapGestureRecognizer;

@property (nonatomic, assign) BOOL shouldShowAddDocumentPopover;
@property (nonatomic, assign) BOOL editModeEnabled;
@property (nonatomic, assign) BOOL bothContentControllersDisplayed;

@property (nonatomic, assign) BOOL needsEmailMenu;

@end

@implementation MTViewControllerOpenDocument

- (void)dealloc {
    [_advancedQueryBuilder release]; _advancedQueryBuilder = nil;
    [_standardQueryBuilder release]; _standardQueryBuilder = nil;
    [_previewLoadingOperations release];
    [_tapGestureRecognizer release];
    [_longPressGestureRecognizer release];
    [_urlBeingOpended release];
    [_availableFilesCacheMetaData release];
    [_availableFilesCache release];
    [_barButtonItemTitle release];
    [_titleView release];
    [_openDocumentPopoverController release];
    [_buttonAddNewDocument release];
    [_buttonLicensing release];
    [_collectionViewFlowLayout release];
    [super dealloc];
}

- (void)awakeFromNib {
    [self setContentSizeForViewInPopover: CGSizeMake(320.0, 480.0)];
    [self setShouldShowAddDocumentPopover:YES];
    [[self buttonAddNewDocument] setEnabled:YES];
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
    if ([sender state] == UIGestureRecognizerStateBegan) {
        CGPoint locationInView = [sender locationInView:[self collectionView]];
        NSIndexPath *indexPath = [[self collectionView] indexPathForItemAtPoint:locationInView];
        if (indexPath) {
            UICollectionViewCell *cell = [[[self collectionView] cellForItemAtIndexPath:indexPath] retain];
            [cell startWobble];
            [cell release];
            [self setEditModeEnabled:YES];
            [[[self collectionView] collectionViewLayout] invalidateLayout];
        }
    }
}

- (void)endEditMode:(UITapGestureRecognizer *)sender {
    if ([self editModeEnabled]) {
        CGPoint locationInView = [sender locationInView:[self collectionView]];
        NSIndexPath *indexPath = [[self collectionView] indexPathForItemAtPoint:locationInView];
        if (!indexPath) {
            [self setEditModeEnabled:NO];
            [[[self collectionView] collectionViewLayout] invalidateLayout];
        }
        
        for (NSUInteger item = 0; item < [[self collectionView] numberOfItemsInSection:0]; item++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:0];
            UICollectionViewCell *cell = [[[self collectionView] cellForItemAtIndexPath:indexPath] retain];
            [cell stopWobble];
            [cell release];
        }
    }
}

#pragma mark - UIMenuController required methods

- (BOOL)canBecomeFirstResponder {
    return NO;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    return NO;
}

#pragma mark - UIViewController Overrides

- (void)viewDidLoad {
    [super viewDidLoad];

    UILongPressGestureRecognizer *longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(activateEditMode:)];
    [longPressGestureRecognizer setDelegate: self];
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
    
    NSMutableArray *fileMetaCache = [[NSMutableArray alloc] init];
    [self setAvailableFilesCacheMetaData: fileMetaCache];
    [fileMetaCache release];

    [[self buttonLicensing] setEnabled:[SKPaymentQueue canMakePayments]];
    
    [self setNeedsEmailMenu:YES];

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [[MTStoreKitController sharedObject] licensedUser:^(BOOL isLicensedUser, NSDate *experationDate) {
        if (isLicensedUser) {
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                UIMenuItem *menuItem = [[UIMenuItem alloc] initWithTitle: NSLocalizedString(@"Email", @"Email")
                                                                  action: @selector(email:)];
                UIMenuController *menu = [UIMenuController sharedMenuController];
                [menu setMenuItems:@[menuItem]];
                [menuItem release];
            });
        }
    }];
    
    [self updateFileList];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
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
    return YES;
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    [self setShouldShowAddDocumentPopover:YES];
    [[self buttonAddNewDocument] setEnabled:YES];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [super prepareForSegue:segue sender:sender];

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
        
    } else if ([[segue identifier] isEqualToString:MTSegueLicensing]) {

        if ([[segue destinationViewController] isKindOfClass: [UINavigationController class]]) {
            UINavigationController *navControl = [segue destinationViewController];
            id tvc = [navControl topViewController];
            [tvc setDelegate:self];
        }
        [[segue destinationViewController] setDelegate:self];
        
    } else if ([[segue identifier] isEqualToString:MTSegueOpenInViewer]) {

        BOOL foundUrl = NO;
        if ([sender isKindOfClass:[MTCollectionViewCellDocument class]]) {
            NSUInteger row = 0;
            NSURL *url = nil;
            MTCollectionViewCellDocument *senderCell = sender;
            row = [[[self collectionView] indexPathForCell:senderCell] row];
            url = [[self availableFilesCache] objectAtIndex: row];
            [self setUrlBeingOpended:url];
            foundUrl = YES;
        } else if ([sender isKindOfClass:[NSURL class]]) {
            [self setUrlBeingOpended:(NSURL *)sender];
            foundUrl = YES;
        }

        //UINavigationController *navigationController = (UINavigationController *)[segue destinationViewController];
        if (foundUrl) {
            MTReportViewerController *viewControllerReportViewer = (MTReportViewerController *)[(UINavigationController *)[segue destinationViewController] topViewController];
            [viewControllerReportViewer setAsyncDelegate:self];
            [viewControllerReportViewer setViewControllerDelegate:self];
/*
            [[MTActiveDocument sharedDocument] setActiveDocument: managedDocument];
            UINavigationController *navigationController = (UINavigationController *)[segue destinationViewController];
            MTReportViewerController *viewControllerReportViewer = (MTReportViewerController *)[navigationController topViewController];
            [viewControllerReportViewer loadReport:managedDocument];*/
/*            [UIManagedDocument openManagedDocumentAtUrl:[self urlBeingOpended]
                                            withWrapper:[MAReportDocument class]
                                   andCompletionHandler:^(id managedDocument, BOOL success) {
                                       
                                       if (success) {
                                           [[MTActiveDocument sharedDocument] setActiveDocument: managedDocument];
                                           UINavigationController *navigationController = (UINavigationController *)[segue destinationViewController];
                                           MTReportViewerController *viewControllerReportViewer = (MTReportViewerController *)[navigationController topViewController];
                                           [viewControllerReportViewer setViewControllerDelegate:self];
                                           [viewControllerReportViewer loadReport:managedDocument];
                                       }
                                       
                                   }];*/

        } else {
            NSAssert(foundUrl == NO, @"No URL to open.");
        }
        
    } else if ([[segue identifier] isEqualToString:MTSegueShowOpenDocument]) {
        BOOL foundUrl = NO;
        if ([sender isKindOfClass:[MTCollectionViewCellDocument class]]) {

            NSUInteger row = 0;
            NSURL *url = nil;
            MTCollectionViewCellDocument *senderCell = sender;
            row = [[[self collectionView] indexPathForCell:senderCell] row];
            url = [[[self availableFilesCache] objectAtIndex: row] retain];
            if (url != nil) {
                foundUrl = YES;
            }
            [self setUrlBeingOpended:url];
            [url release];
            
        } else if ([sender isKindOfClass:[NSURL class]])  {
            NSURL *url = (NSURL *)sender;
            if (url != nil) {
                [self setUrlBeingOpended:url];
                foundUrl = YES;
            }
        }
        if (foundUrl) {
            if ([[segue destinationViewController] isKindOfClass: [UINavigationController class]]) {
                if ([UIDevice isPad]) {
                    MTQueryBuilderContainerController *queryBuilderViewController = (MTQueryBuilderContainerController *)[[segue destinationViewController] topViewController];
                    [queryBuilderViewController setDelegateContentController: self];
                    [queryBuilderViewController setDelegate:self];
                    [queryBuilderViewController setDocumentToOpen:[self urlBeingOpended]];
                } else {
                    MTQueryBuilderViewController *queryBuilderViewController = (MTQueryBuilderViewController *)[[segue destinationViewController] topViewController];
                    [self setupQueryDesignerController:queryBuilderViewController usingFileAtUrl:[self urlBeingOpended]];
                }
                
            } else if ([[segue destinationViewController] isKindOfClass:[MTQueryBuilderContainerController class]]) {
                MTQueryBuilderContainerController *queryBuilderViewController = (MTQueryBuilderContainerController *)[segue destinationViewController];
                [queryBuilderViewController setDelegateContentController: self];
                [queryBuilderViewController setDelegate:self];
                [queryBuilderViewController setDocumentToOpen:[self urlBeingOpended]];
            } else if ([[segue destinationViewController] isKindOfClass:[MTQueryBuilderViewController class]]) {
                MTQueryBuilderViewController *queryBuilderViewController = (MTQueryBuilderViewController *)[segue destinationViewController];
                [self setupQueryDesignerController:queryBuilderViewController usingFileAtUrl:[self urlBeingOpended]];
            }
        } else {
            NSAssert(foundUrl == NO, @"No URL to open.");
        }
        
    }
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    BOOL shouldPerformSegueWithIdentifier = YES;
    if ([identifier isEqualToString:MTSegueShowAddDocument]) {
        if ([UIDevice isPad]) {
            shouldPerformSegueWithIdentifier = [self shouldShowAddDocumentPopover];
            [self setShouldShowAddDocumentPopover:NO];
            [[self buttonAddNewDocument] setEnabled:NO];
        }
    }
    return shouldPerformSegueWithIdentifier;
}

#pragma mark - 

- (void)updateFileList {
    // Create and start a metadata query for cloud items if enabled.
    // If using local storage, build the file list with NSFileManager APIs.
    
//    [_fileList removeAllObjects];
//    [_query stopQuery];
    NSMutableArray *a = [[NSMutableArray alloc] initWithArray:[NSFileManager schemaFiles]];
    [self setAvailableFilesCache: a];
    [a release];
    [[self availableFilesCacheMetaData] removeAllObjects];
    
    if ([[MACloudManager sharedManager] isCloudEnabled]) {
        /*
        if (_query) {
            [_query startQuery];
        }
        else {
            _query = [[NSMetadataQuery alloc] init];
            [_query setSearchScopes:[NSArray arrayWithObjects:NSMetadataQueryUbiquitousDocumentsScope, NSMetadataQueryUbiquitousDataScope, nil]];
            [_query setPredicate:[NSPredicate predicateWithFormat:@"%K LIKE '*.note*'", NSMetadataItemFSNameKey]];
            NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];
            [notificationCenter addObserver:self selector:@selector(fileListReceived) name:NSMetadataQueryDidFinishGatheringNotification object:_query];
            [notificationCenter addObserver:self selector:@selector(fileListReceived) name:NSMetadataQueryDidUpdateNotification object:_query];
            [_query startQuery];
        }
         */
    } else {
        NSURL *documentsDirectoryURL = [[[MACloudManager sharedManager] documentsDirectoryURL] retain];
        NSError *error = nil;
        NSArray *localDocuments = [[[NSFileManager defaultManager] contentsOfDirectoryAtURL:documentsDirectoryURL
                                                                includingPropertiesForKeys:nil options:0 error:&error] retain];

        NSURL *dataDirectoryURL = [[[MACloudManager sharedManager] dataDirectoryURL] retain];
        
        for (NSURL *document in localDocuments) {
            if ([[document pathExtension] isEqualToString:MTDocumentExtentionMobleApplicationDocument]) {
                NSString *fileName = [[document lastPathComponent] stringByDeletingPathExtension];
                FileRepresentation* fileRepresentation = [[FileRepresentation fileRepresentationWithName:fileName
                                                                                                 andUrl:document] retain];
                NSURL *thumbnailPath = [document URLByAppendingPathComponent:@"AdditionalContent" isDirectory:YES];
                thumbnailPath = [thumbnailPath URLByAppendingPathComponent:MTDocumentInfoKeyThumbnail isDirectory:NO];
                NSString* previewFilePath = [thumbnailPath path];
                if ([[NSFileManager defaultManager] fileExistsAtPath:previewFilePath]) {
                    NSURL *previewUrl = [thumbnailPath retain];
                    fileRepresentation.previewURL = previewUrl;
                    [previewUrl release];
                }
                [[self availableFilesCacheMetaData] addObject:fileRepresentation];

                [fileRepresentation release];
            }
        }
        
        [localDocuments release];
        [dataDirectoryURL release];
        [documentsDirectoryURL release];
    }
    [[self collectionView] reloadData];

}

#pragma mark - Delegates

- (void)displayContentController:(UIViewController *)contentController {
    //If designer application, then load designer query builder.
    //  If viewer, load, well, the viewer.
    if ([AppDelegate isMadDesigner]) {
        UIViewController *childController = [contentController retain];
        if ([contentController isKindOfClass:[UINavigationController class]]) {
            UINavigationController *childNavigationController = (UINavigationController *)contentController;
            if ([[childNavigationController topViewController] isKindOfClass:[MTQueryBuilderViewController class]]) {
                MTQueryBuilderViewController *queryBuilderViewController = (MTQueryBuilderViewController *)[[childNavigationController topViewController] retain];
                [self setStandardQueryBuilder:queryBuilderViewController];
                [queryBuilderViewController release];
                [self setBothContentControllersDisplayed:NO];
            }
        } else if ([contentController isKindOfClass:[MTQueryBuilderAdvancedViewController class]]) {
            MTQueryBuilderAdvancedViewController *advancedControl = (MTQueryBuilderAdvancedViewController *)contentController;
            [self setAdvancedQueryBuilder:advancedControl];
            [self setBothContentControllersDisplayed:NO];
        } else if ([contentController isKindOfClass:[MTQueryBuilderViewController class]]) {
            MTQueryBuilderViewController *queryBuilder = (MTQueryBuilderViewController *)contentController;
            [self setStandardQueryBuilder:queryBuilder];
            [queryBuilder setDelegate:self];
            [self setBothContentControllersDisplayed:YES];
        }
        
        if ([self bothContentControllersDisplayed] && [self advancedQueryBuilder] != nil && [self standardQueryBuilder] != nil) {
            
            [[self standardQueryBuilder] setDelegate: self];
            
            
            [UIManagedDocument openManagedDocumentAtUrl:[self urlBeingOpended]
                                            withWrapper:[MAReportDocument class]
                                   andCompletionHandler:^(id managedDocument, BOOL success) {
                                       
                                       if (success) {
                                           [[MTActiveDocument sharedDocument] setActiveDocument: managedDocument];
                                           [[self standardQueryBuilder] reloadDocument:managedDocument];
                                           [[self advancedQueryBuilder] reloadDocument:managedDocument];
                                       }
                                       
                                   }];
            
        }
        [childController release];
    } else if ([AppDelegate isMadViewer]) {
        MTReportViewerController *viewController = (MTReportViewerController *)contentController;
        
        [UIManagedDocument openManagedDocumentAtUrl:[self urlBeingOpended]
                                        withWrapper:[MAReportDocument class]
                               andCompletionHandler:^(id managedDocument, BOOL success) {
                                
                                   if (success) {
                                       [[MTActiveDocument sharedDocument] setActiveDocument: managedDocument];
                                       [viewController loadReport:[[MTActiveDocument sharedDocument] activeDocument]];
                                       //[viewController reloadReportView];
                                   }
                                   
                               }];
    }
}

- (void)deleteDocumentRepresentedByCell:(MTCollectionViewCellDocument *)cell {
    NSIndexPath *cellPath = [[self collectionView] indexPathForCell:cell];
    [self deleteDocumentAtIndexPath:cellPath];
}

- (void)emailDocumentRepresentedByCell:(MTCollectionViewCellDocument *)cell {
    if ([MFMailComposeViewController canSendMail] == NO) {

        //Display an alert...
        UIAlertView *uIAlertView = [[UIAlertView alloc] initWithTitle: NSLocalizedString(@"Warning", @"Heading of a warning alert message.")
                                                              message: NSLocalizedString(@"Device is not configured for email.", @"Warning that email is not setup.")
                                                             delegate: nil
                                                    cancelButtonTitle: NSLocalizedString(@"OK", @"OK button on an alert message.")
                                                    otherButtonTitles: nil];
        [uIAlertView show];
        [uIAlertView release];
        
    } else {


        NSIndexPath *cellPath = [[self collectionView] indexPathForCell:cell];
        NSURL *fileToAttach = [[self availableFilesCache] objectAtIndex:cellPath.item];
        
        MAReportDocument *documentReport = [[MAReportDocument alloc] initWithFileURL:fileToAttach];
        
        if ([documentReport documentState] != UIDocumentStateClosed) {
            [documentReport closeWithCompletionHandler:^(BOOL success) {
                if (success) {
                    [self emailDocumentRepresentedByCell:[[cell retain] autorelease]];
                }
            }];
            
        } else {
            
            [documentReport performAsynchronousFileAccessUsingBlock:^{
                NSError *fileWrapperError = nil;
                NSFileWrapper *fileWrapper = [[NSFileWrapper alloc] initWithURL:[documentReport fileURL] options:NSFileWrapperReadingImmediate | NSFileWrapperReadingWithoutMapping error:&fileWrapperError];
                
                if (fileWrapperError == nil) {
                    NSData *data = [[fileWrapper serializedRepresentation] retain];
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

                } else {
                    [fileWrapperError presentErrorToUser];
                }
                
                [fileWrapper release];
            }];
        }
        
        [documentReport release];
        
    }

}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    [self dismissViewControllerAnimated:YES completion:nil];
    [error presentErrorToUser];
}

- (void)viewControllerDidFinish:(id)sender {
    [self viewControllerDidFinish:sender animated:YES];
    [[self openDocumentPopoverController] dismissPopoverAnimated:YES];
    [self setShouldShowAddDocumentPopover:YES];
    [[self buttonAddNewDocument] setEnabled:YES];
    [self updateFileList];
}

- (void)viewControllerDidFinish:(id)sender animated:(BOOL)animated {
    MAReportDocument *documentReport = [[[MTActiveDocument sharedDocument] activeDocument] retain];
    if (documentReport != nil) {
        [documentReport saveToURL:[documentReport fileURL] forSaveOperation:UIDocumentSaveForOverwriting completionHandler:^(BOOL success) {
            if (success) {
                [documentReport closeWithCompletionHandler:^(BOOL success) {
                    
                }];
                [[MTActiveDocument sharedDocument] setActiveDocument: nil];
            }
            [self dismissViewControllerAnimated:animated completion:nil];
        }];
    } else {
        [self dismissViewControllerAnimated:animated completion:nil];
    }
    [documentReport release];
}


- (void)viewControllerDidCancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
    [[self openDocumentPopoverController] dismissPopoverAnimated:YES];
    [self setShouldShowAddDocumentPopover:YES];
    [[self buttonAddNewDocument] setEnabled:YES];
}

- (void)setupQueryDesignerController:(MTQueryBuilderViewController *)tvc usingFileAtUrl:(NSURL*)url {
    [tvc setDelegate: self];
    [UIManagedDocument openManagedDocumentAtUrl:url
                                    withWrapper:[MAReportDocument class]
                           andCompletionHandler:^(id managedDocument, BOOL success) {
                               
                               if (success) {
                                   [[MTActiveDocument sharedDocument] setActiveDocument: managedDocument];
                                   [tvc reloadDocument:managedDocument];
                               }
                               
                           }];
}

#pragma mark - Actions

- (IBAction)add:(id)sender { }

- (IBAction)done:(id)sender { }

- (IBAction)edit:(id)sender { }

- (IBAction)about:(id)sender {
    NSString *applicationName = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleNameKey];
    NSString *title = [NSString stringWithFormat:NSLocalizedString(@"About %@", @"About Mad Designer"),  applicationName];
    NSString *message = NSLocalizedString(@"© Everyday Apps LLC 2013.  Software created by Michael Thomason for Everyday Apps LLC.",
                                          @"© Everyday Apps LLC 2013.  Software created by Michael Thomason for Everyday Apps LLC.");
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

- (void)paste:(id)sender {
    [super paste:sender];
}

- (IBAction)delete:(id)sender {
    if ([self collectionView] != nil) {
        for (NSUInteger section = 0; section < [[self collectionView] numberOfSections]; section++) {
            for (NSUInteger item = 0; item < [[self collectionView] numberOfItemsInSection:section]; item++) {
                NSIndexPath *selectedCellLocation = [NSIndexPath indexPathForItem:item inSection:section];
                MTCollectionViewCellDocument *documentCell = [(MTCollectionViewCellDocument *)[[self collectionView] cellForItemAtIndexPath:selectedCellLocation] retain];
                if (documentCell != nil) {
                    if ([documentCell isSelected]) {
                        [self deleteDocumentAtIndexPath:selectedCellLocation];
                    }
                }
                [documentCell release];
            }
        }
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

#pragma mark -
#pragma mark Collection View Delegate Protocol

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingSupplementaryView:(UICollectionReusableView *)view forElementOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath {
    
}

- (void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
}

- (void)collectionView:(UICollectionView *)collectionView didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    
}

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
    return YES;
}

-(void)tableView:(UITableView*)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath*)indexPath withSender:(id)sender { }

-(BOOL)tableView:(UITableView*)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath*)indexPath withSender:(id)sender {
    return YES;
}

-(BOOL)tableView:(UITableView*)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath*)indexPath {
    return YES;
}

#pragma mark -
#pragma mark Collection View Data Protocol

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    MTCollectionViewCellDocument *result = [[self collectionView] dequeueReusableCellWithReuseIdentifier:MTCollectionViewCellDocumentIdentifier
                                                                                      forIndexPath:indexPath];
    [result setDelegate:self];
    if ([indexPath row] < [[self availableFilesCache] count]) {
        FileRepresentation *fr = [[self availableFilesCacheMetaData] objectAtIndex:[indexPath row]];
        [[result imagePreview] setImage:[MTTableViewCellDocument defaultThumbnail]];
        [[result labelTitle] setText: [fr fileName]];
        [self loadCollectionViewPreviewImageForIndexPath:indexPath];
    } else {
        [[result labelTitle] setText: @"Default Text"];
        [[result imagePreview] setImage:[MTTableViewCellDocument defaultThumbnail]];
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

    FileRepresentation *fileRepresentation = [[self availableFilesCacheMetaData] objectAtIndex:[indexPath row]];
    NSBlockOperation *previewLoadingOperation = [NSBlockOperation blockOperationWithBlock:^(void) {
        MTCollectionViewCellDocument *visibleCell = (MTCollectionViewCellDocument *)[[self collectionView] cellForItemAtIndexPath:indexPath];
        NSString *path = [fileRepresentation.previewURL path];
        UIImage *image = [UIImage imageWithContentsOfFile:path];
        [[visibleCell imagePreview] setImage: image];
        [visibleCell setNeedsLayout];
        [_previewLoadingOperations removeObjectForKey:indexPath];
    }];
    _previewLoadingOperations[indexPath] = previewLoadingOperation;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        NSFileCoordinator* fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
        [fileCoordinator coordinateReadingItemAtURL:[fileRepresentation previewURL] options:0 error:nil byAccessor:^(NSURL* previewURL) {
            [[NSOperationQueue mainQueue] addOperation:previewLoadingOperation];
        }];
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
