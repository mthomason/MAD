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

@property (nonatomic, retain) UIPopoverController *openDocumentPopoverController;
@property (nonatomic, assign) BOOL shouldShowAddDocumentPopover;
@property (nonatomic, retain) NSURL *urlBeingOpended;
@property (nonatomic, retain) NSMutableArray *availableFilesCache;
@property (nonatomic, retain) NSMutableArray *availableFilesCacheMetaData;

@property (nonatomic, retain) IBOutlet UIBarButtonItem *barButtonItemTitle;

@property (nonatomic, retain) MTQueryBuilderAdvancedViewController *advancedQueryBuilder;
@property (nonatomic, retain) MTQueryBuilderViewController *standardQueryBuilder;

@property (nonatomic, retain) UILongPressGestureRecognizer *longPressGestureRecognizer;
@property (nonatomic, retain) UITapGestureRecognizer *tapGestureRecognizer;

@property (nonatomic, assign) BOOL editModeEnabled;
@property (nonatomic, retain) IBOutlet MTTitleView *titleView;

@property (nonatomic, assign) BOOL bothContentControllersDisplayed;

@property (nonatomic, retain) NSMutableDictionary *previewLoadingOperations;

@property (retain, nonatomic) IBOutlet UIBarButtonItem *buttonAddNewDocument;
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
    [_tableViewQueries release];
    [_toolbar release];
    [_barButtonItemTitle release];
    [_collectionViewQueries release];
    [_titleView release];
    [_openDocumentPopoverController release];
    [_buttonAddNewDocument release];
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
    [[self collectionViewQueries] registerClass: [MTCollectionViewCellDocument class]
                     forCellWithReuseIdentifier: MTCollectionViewCellDocumentIdentifier];
    
    [self setEditModeEnabled:NO];
    
    NSMutableDictionary *d = [[NSMutableDictionary alloc] init];
    [self setPreviewLoadingOperations:d];
    [d release];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    CGPoint touchPoint = [touch locationInView:[self collectionViewQueries]];
    NSIndexPath *indexPath = [[self collectionViewQueries] indexPathForItemAtPoint:touchPoint];
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
        CGPoint locationInView = [sender locationInView:[self collectionViewQueries]];
        NSIndexPath *indexPath = [[self collectionViewQueries] indexPathForItemAtPoint:locationInView];
        if (indexPath) {
            UICollectionViewCell *cell = [[[self collectionViewQueries] cellForItemAtIndexPath:indexPath] retain];
            [cell startWobble];
            [cell release];
            [self setEditModeEnabled:YES];
            [[[self collectionViewQueries] collectionViewLayout] invalidateLayout];
        }
    }
}

- (void)endEditMode:(UITapGestureRecognizer *)sender {
    if ([self editModeEnabled]) {
        CGPoint locationInView = [sender locationInView:[self collectionViewQueries]];
        NSIndexPath *indexPath = [[self collectionViewQueries] indexPathForItemAtPoint:locationInView];
        if (!indexPath) {
            [self setEditModeEnabled:NO];
            [[[self collectionViewQueries] collectionViewLayout] invalidateLayout];
        }
        
        for (NSUInteger item = 0; item < [[self collectionViewQueries] numberOfItemsInSection:0]; item++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:0];
            UICollectionViewCell *cell = [[[self collectionViewQueries] cellForItemAtIndexPath:indexPath] retain];
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
    [[self collectionViewQueries] addGestureRecognizer:tapGestureRecognizer];
    [self setTapGestureRecognizer:tapGestureRecognizer];
    [tapGestureRecognizer release];
    
    [[[self titleView] label] setText:NSLocalizedString(@"Reports", @"Reports")];
    [self updateFileList];

    NSMutableArray *fileUrlCache = [[NSMutableArray alloc] init];
    [self setAvailableFilesCache: fileUrlCache];
    [fileUrlCache release];
    
    NSMutableArray *fileMetaCache = [[NSMutableArray alloc] init];
    [self setAvailableFilesCacheMetaData: fileMetaCache];
    [fileMetaCache release];
    
    [self updateFileList];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[self tableViewQueries] reloadData];
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
            UINavigationController *navControl = [[segue destinationViewController] retain];
            if ([navControl topViewController]) {
                if ([[navControl topViewController] isKindOfClass:[MTTemplateSelectorViewController class]]) {
                    if ([segue isKindOfClass:[UIStoryboardPopoverSegue class]]) {
                        [self setOpenDocumentPopoverController: [(UIStoryboardPopoverSegue *)segue popoverController]];
                        [[self openDocumentPopoverController] setDelegate:self];
                    }
                    MTTemplateSelectorViewController *tvc = (MTTemplateSelectorViewController *)[[navControl topViewController] retain];
                    if (tvc) {
                        [tvc setDelegate:self];
                        [tvc setTemplateSelectorDelegate:self];
                    }
                    [tvc release];
                }
            }
            
            [navControl release];
        }
        [[segue destinationViewController] setDelegate:self];
        
    } else if ([[segue identifier] isEqualToString:MTSegueShowOpenDocument]) {
        
        NSUInteger row = 0;
        NSURL *url = nil;
        if ([sender isKindOfClass:[MTDocumentTableViewCell class]]) {
            
            MTDocumentTableViewCell *senderCell = sender;
            row = [[[self tableViewQueries] indexPathForCell:senderCell] row];
            url = [[[self availableFilesCache] objectAtIndex: row] retain];
            [self setUrlBeingOpended:url];
            
        } else if ([sender isKindOfClass:[MTCollectionViewCellDocument class]]) {
            
            MTCollectionViewCellDocument *senderCell = sender;
            row = [[[self collectionViewQueries] indexPathForCell:senderCell] row];
            url = [[[self availableFilesCache] objectAtIndex: row] retain];
            [self setUrlBeingOpended:url];
        }
        if ([[segue destinationViewController] isKindOfClass: [UINavigationController class]]) {
            
            UINavigationController *navControl = [[segue destinationViewController] retain];
            if ([navControl topViewController]) {
                if (row < [[self availableFilesCache] count]) {
                    
                    if ([[navControl topViewController] isKindOfClass:[MTQueryBuilderViewController class]]) {
                        MTQueryBuilderViewController *tvc = [(MTQueryBuilderViewController *)[navControl topViewController] retain];
                        if (tvc) {
                            [self setupQueryDesignerController:tvc usingFileAtUrl:url];
                        } else {
                            @throw [NSException exceptionWithName: NSInternalInconsistencyException
                                                           reason: [NSString stringWithFormat:@"Could not find MTViewControllerQueryBuilder in %@.", NSStringFromSelector(_cmd)]
                                                         userInfo: nil];
                        }
                        [tvc release];
                    }
                }
            }
            [navControl release];
            
        } else if ([[segue destinationViewController] isKindOfClass:[MTQueryBuilderContainerController class]]) {
            
            MTQueryBuilderContainerController *splitViewController = (MTQueryBuilderContainerController* )[[segue destinationViewController] retain];
            [splitViewController setDelegateContentController: self];
            [splitViewController setDelegate:self];
            [splitViewController setDocumentToOpen:url];
            [splitViewController release];
            
        }
        
        
        [url release];
        
    }
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    BOOL shouldPerformSegueWithIdentifier = YES;
    if ([identifier isEqualToString:MTSegueShowAddDocument]) {
        if ([UIDevice isPad] == YES) {
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
    
    if ([[CloudManager sharedManager] isCloudEnabled]) {
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
        NSURL *documentsDirectoryURL = [[[CloudManager sharedManager] documentsDirectoryURL] retain];
        NSError *error = nil;
        NSArray *localDocuments = [[[NSFileManager defaultManager] contentsOfDirectoryAtURL:documentsDirectoryURL
                                                                includingPropertiesForKeys:nil options:0 error:&error] retain];

        NSURL *dataDirectoryURL = [[[CloudManager sharedManager] dataDirectoryURL] retain];
        
        for (NSURL *document in localDocuments) {
            if ([[document pathExtension] isEqualToString:MTDocumentExtentionMobleApplicationDocument]) {
                NSString *fileName = [[document lastPathComponent] stringByDeletingPathExtension];
                FileRepresentation* fileRepresentation = [[FileRepresentation fileRepresentationWithName:fileName
                                                                                                 andUrl:document] retain];
                NSURL *thumbnailPath = [document URLByAppendingPathComponent:@"AdditionalContent" isDirectory:YES];
                thumbnailPath = [thumbnailPath URLByAppendingPathComponent:MTDocumentInfoKeyThumbnail isDirectory:NO];
                NSString* previewFilePath = [thumbnailPath path];
                if ([[NSFileManager defaultManager] fileExistsAtPath:previewFilePath]) {
                    NSLog(@"Got a local thumbnail.");
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
}

#pragma mark - Delegates

- (void)deleteDocumentRepresentedByCell:(MTCollectionViewCellDocument *)cell {
    NSIndexPath *cellPath = [[self collectionViewQueries] indexPathForCell:cell];
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

        NSIndexPath *cellPath = [[self collectionViewQueries] indexPathForCell:cell];
        NSURL *fileToAttach = [[self availableFilesCache] objectAtIndex:cellPath.item];
        
        MTReportDocument *documentReport = [[MTReportDocument alloc] initWithFileURL:fileToAttach];
        
        if ([documentReport documentState] != UIDocumentStateClosed) {

            //Close the document
            [documentReport closeWithCompletionHandler:^(BOOL success) {
                if (success) {

                    [self emailDocumentRepresentedByCell:[[cell retain] autorelease]];
                }

            }];
            
        } else {
            
                NSError *error = nil;
                NSFileCoordinator *cordinator = [[NSFileCoordinator alloc] initWithFilePresenter:documentReport];
                
                [cordinator coordinateReadingItemAtURL:[fileToAttach filePathURL] options:0 error:&error byAccessor:^(NSURL* writingURL) {
                    
                    NSError *error = nil;
                    NSDictionary *fileAsDictionary = [documentReport contentsForType:MTDocumentTypeUtiMad error:&error];
                    
                    NSMutableData *data = [[NSMutableData alloc] init];
                    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
                    [archiver encodeObject:fileAsDictionary];
                    [archiver finishEncoding];
                    [archiver release];
                    
                    NSMutableString *messageBody = [[NSMutableString alloc] initWithString:NSLocalizedString(@"The attached document can be opened with the Mad Viewer available on iOS.",
                                                                                                             @"The attached document can be opened with the Mad Viewer available on iOS.")];
                    
                    NSString *subject = [NSString stringWithFormat:NSLocalizedString(@"MAD Document %@.", @"MAD Document %@."), [documentReport name]];
                    [messageBody appendString:@"\n\nhttp://www.everydayapps.com/\n\n"];
                    
                    MFMailComposeViewController	*mailComposer = [[MFMailComposeViewController alloc] init];
                    [mailComposer setMailComposeDelegate: self];
                    [mailComposer setMessageBody:messageBody isHTML:NO];
                    [mailComposer setSubject:subject];
                    
                    [mailComposer addAttachmentData:data mimeType:@"application/vnd.everydayapps.mad" fileName:@"get.mad"];
                    [self presentViewController:mailComposer animated:YES completion:nil];
                    
                    [data release];
                    [mailComposer release];
                    [messageBody release];
                    
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

}

- (void)viewControllerDidFinish:(id)sender animated:(BOOL)animated {
    MTReportDocument *documentReport = [[[MTActiveDocument sharedDocument] activeDocument] retain];
    if (documentReport != nil) {
        [documentReport saveToURL:[documentReport fileURL] forSaveOperation:UIDocumentSaveForOverwriting completionHandler:^(BOOL success) {
            if (success) {
                [documentReport closeWithCompletionHandler:^(BOOL success) {
                    
                }];
                [[MTActiveDocument sharedDocument] setActiveDocument: nil];
                [[self tableViewQueries] reloadData];
                [[self collectionViewQueries] reloadData];
            }
            [self dismissViewControllerAnimated:animated completion:nil];
        }];
    } else {
        [self updateFileList];
        [[self tableViewQueries] reloadData];
        [[self collectionViewQueries] reloadData];
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

- (void)displayContentController:(UIViewController *)contentController {
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
                                        withWrapper:[MTReportDocument class]
                               andCompletionHandler:^(id managedDocument, BOOL success) {
            
            if (success) {
                [[MTActiveDocument sharedDocument] setActiveDocument: managedDocument];
                [[self standardQueryBuilder] reloadDocument:managedDocument];
                [[self advancedQueryBuilder] reloadDocument:managedDocument];
            }
            
        }];
        
    }
    [childController release];
}

- (void)setupQueryDesignerController:(MTQueryBuilderViewController *)tvc usingFileAtUrl:(NSURL*)url {
    [tvc setDelegate: self];
    [UIManagedDocument openManagedDocumentAtUrl:url
                                    withWrapper:[MTReportDocument class]
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

- (IBAction)edit:(id)sender {
    BOOL editing = ![[self tableViewQueries] isEditing];
    UIBarButtonSystemItem buttonType = editing ? UIBarButtonSystemItemDone: UIBarButtonSystemItemEdit;
    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: buttonType
                                                                                   target: self
                                                                                   action: @selector(edit:)];
    NSMutableArray *tbItems = [[NSMutableArray alloc] initWithArray:[[self toolbar] items]];
    [tbItems replaceObjectAtIndex:([tbItems count] - 1) withObject: barButtonItem];
    [[self toolbar] setItems: tbItems];
    [tbItems release];
    [[self tableViewQueries] setEditing: editing];
    [barButtonItem release];
}

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
    if ([self collectionViewQueries] != nil) {
        for (NSUInteger section = 0; section < [[self collectionViewQueries] numberOfSections]; section++) {
            for (NSUInteger item = 0; item < [[self collectionViewQueries] numberOfItemsInSection:section]; item++) {
                NSIndexPath *selectedCellLocation = [NSIndexPath indexPathForItem:item inSection:section];
                MTCollectionViewCellDocument *documentCell = [(MTCollectionViewCellDocument *)[[self collectionViewQueries] cellForItemAtIndexPath:selectedCellLocation] retain];
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
            [[self collectionViewQueries] deleteItemsAtIndexPaths:@[index]];
        }
    } else {
        [error presentErrorToUser];
    }
    
}


#pragma mark -
#pragma mark Table View Data Source Protocol

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *MyIdentifier = @"UITableViewCellDocument";
    MTDocumentTableViewCell *result = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];

    if ([indexPath row] < [[self availableFilesCache] count]) {
        FileRepresentation *fr = [[self availableFilesCacheMetaData] objectAtIndex:[indexPath row]];
        [[result imageThumbnail] setImage:nil];
        [[result labelH1] setText: [fr fileName]];
        [self loadTableViewPreviewImageForIndexPath:indexPath];
    } else {
        [[result imageThumbnail] setImage:[MTDocumentTableViewCell defaultThumbnail]];
        [[result labelH1] setText: @""];    
    }
    [result setDelegate:self];
    return result;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
	switch (editingStyle) {
        case UITableViewCellEditingStyleDelete: {
            NSInteger row = [indexPath row];
            [tableView beginUpdates];
            NSError *error = nil;
            [[NSFileManager defaultManager] removeItemAtURL:[[self availableFilesCache] objectAtIndex:[indexPath row]] error:&error];
            if (!error) {
                if (row < [[self availableFilesCache] count]) {
                    [[self availableFilesCache] removeObjectAtIndex:row];
                    [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                }
            }
            [tableView endUpdates];
            break;
        }
        case UITableViewCellEditingStyleInsert: {
            break;
        }
        case UITableViewCellEditingStyleNone: {
            break;
        }
        default:
            break;
    }

	
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
	
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NSInteger numberOfRows;
    switch (section) {
        case 0: {
            numberOfRows = [[self availableFilesCache] count];
            break;
        }            
        default:
            numberOfRows = 0;
            break;
    }
	return numberOfRows;
}

#pragma mark -
#pragma mark Table View Delegate Protocol

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
	
}

- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath {
	
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [MTDocumentTableViewCell defaultHeight];
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

-(void)tableView:(UITableView*)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath*)indexPath withSender:(id)sender {
    NSLog(@"Get busy!!!");
}
-(BOOL)tableView:(UITableView*)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath*)indexPath withSender:(id)sender {
    return YES;
}
-(BOOL)tableView:(UITableView*)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath*)indexPath {
    return YES;
}

#pragma mark -
#pragma mark Collection View Data Protocol

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    MTCollectionViewCellDocument *result = [[collectionView dequeueReusableCellWithReuseIdentifier:MTCollectionViewCellDocumentIdentifier
                                                                                      forIndexPath:indexPath] retain];
    [result setDelegate:self];
    if ([indexPath row] < [[self availableFilesCache] count]) {
        FileRepresentation *fr = [[self availableFilesCacheMetaData] objectAtIndex:[indexPath row]];
        [[result imagePreview] setImage:nil];
        [[result labelTitle] setText: [fr fileName]];
        [self loadCollectionViewPreviewImageForIndexPath:indexPath];
    } else {
        [[result imagePreview] setImage:[MTDocumentTableViewCell defaultThumbnail]];
        [[result labelTitle] setText: @""];
    }
    return [result autorelease];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    [self updateFileList];
    return [[self availableFilesCache] count];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (void)loadCollectionViewPreviewImageForIndexPath:(NSIndexPath *)indexPath {

    FileRepresentation *fileRepresentation = [[self availableFilesCacheMetaData] objectAtIndex:[indexPath row]];
    NSBlockOperation *previewLoadingOperation = [NSBlockOperation blockOperationWithBlock:^(void) {
        MTCollectionViewCellDocument *visibleCell = (MTCollectionViewCellDocument *)[[self collectionViewQueries] cellForItemAtIndexPath:indexPath];
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

- (void)loadTableViewPreviewImageForIndexPath:(NSIndexPath *)indexPath {
    
    FileRepresentation *fileRepresentation = [[self availableFilesCacheMetaData] objectAtIndex:[indexPath row]];
    NSBlockOperation *previewLoadingOperation = [NSBlockOperation blockOperationWithBlock:^(void) {
        MTDocumentTableViewCell *visibleCell = (MTDocumentTableViewCell *)[[self tableViewQueries] cellForRowAtIndexPath:indexPath];
        NSString *path = [fileRepresentation.previewURL path];
        UIImage *image = [UIImage imageWithContentsOfFile:path];
        [[visibleCell imageThumbnail] setImage: image];
        [visibleCell setNeedsLayout];
        [_previewLoadingOperations removeObjectForKey:indexPath];
    }];
    _previewLoadingOperations[indexPath] = previewLoadingOperation;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        NSFileCoordinator* fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
        [fileCoordinator coordinateReadingItemAtURL:[fileRepresentation previewURL]
                                            options:0
                                              error:nil
                                         byAccessor:^(NSURL* previewURL) {
            [[NSOperationQueue mainQueue] addOperation:previewLoadingOperation];
        }];
    });
}


#pragma mark -
#pragma mark Collection View Flow Layout Delegate

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(25.0000f, 25.0000f, 25.0000f, 25.0000f);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 50.0000f;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 50.0000f;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(150.0000f, 100.0000f);
}

- (void)viewDidUnload {
    [self setButtonAddNewDocument:nil];
    [super viewDidUnload];
}
@end
