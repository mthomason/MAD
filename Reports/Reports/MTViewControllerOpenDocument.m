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

@interface MTViewControllerOpenDocument()

@property (nonatomic, retain) UIPopoverController *openDocumentPopoverController;

@property (nonatomic, retain) NSURL *urlBeingOpended;
@property (nonatomic, retain) NSMutableArray *availableFilesCache;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *barButtonItemTitle;

@property (nonatomic, retain) MTQueryBuilderAdvancedViewController *advancedQueryBuilder;
@property (nonatomic, retain) MTQueryBuilderViewController *standardQueryBuilder;

@property (nonatomic, retain) UILongPressGestureRecognizer *longPressGestureRecognizer;
@property (nonatomic, retain) UITapGestureRecognizer *tapGestureRecognizer;

@property (nonatomic, assign) BOOL editModeEnabled;
@property (nonatomic, retain) IBOutlet MTTitleView *titleView;

@property (nonatomic, assign) BOOL bothContentControllersDisplayed;

@end

@implementation MTViewControllerOpenDocument

- (void)dealloc {
    [_advancedQueryBuilder release]; _advancedQueryBuilder = nil;
    [_standardQueryBuilder release]; _standardQueryBuilder = nil;
    [_tapGestureRecognizer release];
    [_longPressGestureRecognizer release];
    [_urlBeingOpended release];
    [_availableFilesCache release];
    [_tableViewQueries release];
    [_toolbar release];
    [_barButtonItemTitle release];
    [_collectionViewQueries release];
    [_titleView release];
    [_openDocumentPopoverController release];
    [super dealloc];
}

- (void)awakeFromNib {
    [self setContentSizeForViewInPopover: CGSizeMake(320.0, 480.0)];
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

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    NSMutableArray *a = [[NSMutableArray alloc] initWithArray:[NSFileManager schemaFiles]];
    [self setAvailableFilesCache: a];
    [a release];

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
    if ([identifier isEqualToString:@""]) {

    }
    return shouldPerformSegueWithIdentifier;
}

#pragma mark - Delegates

- (void)deleteDocumentRepresentedByCell:(MTCollectionViewCellDocument *)cell {
    NSIndexPath *cellPath = [[self collectionViewQueries] indexPathForCell:cell];
    [self deleteDocumentAtIndexPath:cellPath];
}

- (void)emailDocumentRepresentedByCell:(MTCollectionViewCellDocument *)cell {
    if ([MFMailComposeViewController canSendMail]) {
        NSIndexPath *cellPath = [[self collectionViewQueries] indexPathForCell:cell];
        NSURL *fileToAttach = [[self availableFilesCache] objectAtIndex:cellPath.item];
        
        UIManagedDocument *documentReport = [[UIManagedDocument alloc] initWithFileURL:fileToAttach];
        
        if ([documentReport documentState] != UIDocumentStateClosed) {

            [documentReport closeWithCompletionHandler:^(BOOL success) {
                if (success) {

                    [self emailDocumentRepresentedByCell:[[cell retain] autorelease]];
                }

            }];
        }
                
        if (documentReport) {
            
                NSMutableString *messageBody = [[NSMutableString alloc] initWithString:NSLocalizedString(@"The attached document can be opened with the Mad Viewer available on iOS.",
                                                                                                         @"The attached document can be opened with the Mad Viewer available on iOS.")];
                [messageBody appendString:@"\n\nhttp://www.everydayapps.com/\n\n"];
                
                MFMailComposeViewController	*mailComposer = [[MFMailComposeViewController alloc] init];
                [mailComposer setMailComposeDelegate: self];
                [mailComposer setMessageBody:messageBody isHTML:NO];
                [mailComposer setSubject:NSLocalizedString(@"Emailed from Shopped?", @"This is the subject of an email export.")];
                NSError *error = nil;
                //NSData *data = [NSData dataWithContentsOfURL:[fileToAttach filePathURL]];
                NSData *data = [NSData dataWithContentsOfURL:[documentReport fileURL] options:0 error:&error];
                //NSData *data = [NSData dataWithContentsOfURL:[documentReport fileURL] options:0 error:&error];
                if (error != nil) {
                    [error presentErrorToUserWithTryAgain:^(BOOL success) {
                        if (success) {
                            [self emailDocumentRepresentedByCell:[[cell retain] autorelease]];
                        }
                    }];
                } else {

                    [mailComposer addAttachmentData:data mimeType:@"application/vnd.everydayapps.mad" fileName:@"image.jpg"];
                    [self presentViewController:mailComposer animated:YES completion:^{ }];
                }
                [mailComposer release];
                [messageBody release];
            } else {
                //Display an alert...
                UIAlertView *uIAlertView = [[UIAlertView alloc] initWithTitle: NSLocalizedString(@"Warning", @"Heading of a warning alert message.")
                                                                      message: NSLocalizedString(@"Device is not configured for email.", @"Warning that email is not setup.")
                                                                     delegate: nil
                                                            cancelButtonTitle: NSLocalizedString(@"OK", @"OK button on an alert message.")
                                                            otherButtonTitles: nil];
                [uIAlertView show];
                [uIAlertView release];
            }

                
                
                
                
                
        [documentReport release];

    }

}

- (void)viewControllerDidFinish:(id)sender {
    [self viewControllerDidFinish:sender animated:YES];
    [[self openDocumentPopoverController] dismissPopoverAnimated:YES];
}

- (void)viewControllerDidFinish:(id)sender animated:(BOOL)animated {
    MTReportDocument *documentReport = [[[MTActiveDocument sharedDocument] activeDocument] retain];
    if (documentReport != nil) {
        [documentReport saveContext];
        [documentReport save:^(BOOL success) {
            if (success) {
                [[documentReport document] closeWithCompletionHandler:^(BOOL success) {

                }];
                [[MTActiveDocument sharedDocument] setActiveDocument: nil];
                [[self tableViewQueries] reloadData];
                [[self collectionViewQueries] reloadData];
            }
            [self dismissViewControllerAnimated:animated completion:nil];
        }];
    } else {
        NSMutableArray *a = [[NSMutableArray alloc] initWithArray:[NSFileManager schemaFiles]];
        [self setAvailableFilesCache: a];
        [a release];
        [[self tableViewQueries] reloadData];
        [[self collectionViewQueries] reloadData];
        [self dismissViewControllerAnimated:animated completion:nil];
    }
    [documentReport release];
}


- (void)viewControllerDidCancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
    [[self openDocumentPopoverController] dismissPopoverAnimated:YES];
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
        MTReportDocument *documentReport = [[MTReportDocument alloc] initExistingExistingFileWithUrl:[self urlBeingOpended] completion:^(BOOL success, id document) {
            if (success) {
                [[MTActiveDocument sharedDocument] setActiveDocument: document];
                [[self standardQueryBuilder] reloadDocument:document];
                [[self advancedQueryBuilder] reloadDocument:document];
            }
        }];
        [documentReport release];
    }
    [childController release];
}

- (void)setupQueryDesignerController:(MTQueryBuilderViewController *)tvc usingFileAtUrl:(NSURL*)url {
    [tvc setDelegate: self];
    MTReportDocument *documentReport = [[MTReportDocument alloc] initExistingExistingFileWithUrl:url completion:^(BOOL success, id document) {
        if (success) {
            
            [[MTActiveDocument sharedDocument] setActiveDocument: document];
            [tvc reloadDocument:document];

        }
    }];
    [documentReport release];
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
    NSUInteger row = [indexPath row];
    static NSString *MyIdentifier = @"UITableViewCellDocument";
    MTDocumentTableViewCell *result = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
    if (row < [[self availableFilesCache] count]) {
        NSURL *url = [[self availableFilesCache] objectAtIndex:row];
        [[result imageThumbnail] setImage:[MTDocumentTableViewCell defaultThumbnail]];
        [[result labelH1] setText: [[url lastPathComponent] stringByDeletingPathExtension]];
        [[result labelH2] setText:NSLocalizedString(@"Fixme Default Text.", @"A subheading.")];
    } else {
        [[result imageThumbnail] setImage:[MTDocumentTableViewCell defaultThumbnail]];
        [[result labelH1] setText: @""];    
        [[result labelH2] setText: @""];
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
        NSURL *url = [[self availableFilesCache] objectAtIndex:[indexPath row]];
        [[result imagePreview] setImage:[MTDocumentTableViewCell defaultThumbnail]];
        [[result labelTitle] setText: [[url lastPathComponent] stringByDeletingPathExtension]];
    } else {
        [[result imagePreview] setImage:[MTDocumentTableViewCell defaultThumbnail]];
        [[result labelTitle] setText: @""];
    }
    return [result autorelease];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSMutableArray *a = [[NSMutableArray alloc] initWithArray:[NSFileManager schemaFiles]];
    [self setAvailableFilesCache: a];
    [a release];
    return [[self availableFilesCache] count];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
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

@end
