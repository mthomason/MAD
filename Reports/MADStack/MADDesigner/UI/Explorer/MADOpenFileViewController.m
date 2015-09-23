//
//  MADOpenFileViewController
//  MAD Designer
//
//  Created by Michael Thomason on 1/2/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADOpenFileViewController.h"
#import "MADOpenFileSectionHeaderView.h"
#import "MADSearchBar.h"
#import "MADBarButtonItem.h"

#import "MADProgressView.h"

NSString * const MADIdentifierOpenFileSectionHeader             = @"MADIdentifierOpenFileSectionHeader";

// FIXME: Get these from AppDelegate using a protocol/deletgate pattern... different for each version of file exploer.
//NSString * const MADUtiPublicData                               = @"public.data";


CGFloat const MADSectionHeaderHeight                            = 32.0000f;

@interface MADOpenFileViewController()
    <NSFileManagerDelegate,
        UIGestureRecognizerDelegate,
        MFMailComposeViewControllerDelegate,
        UIDocumentInteractionControllerDelegate,
        UIDocumentPickerDelegate,
        UITextFieldDelegate,
        UIPopoverControllerDelegate,
        MADFileExplorerDelegate,
        MTDocumentCellProtocol>

@property (nonatomic, assign, getter = isRightBarButtonItemActivityIndicatorVisible) BOOL rightBarButtonItemActivityIndicatorVisible;

@property (nonatomic, strong) MADAppLaunchContext *pendingLaunchContext;

@property (nonatomic, strong) IBOutlet  UIBarButtonItem *barButtonItemAction;
@property (nonatomic, strong) IBOutlet  UIBarButtonItem *barButtonItemEdit;
@property (nonatomic, weak)   IBOutlet  UIBarButtonItem *barButtonItemInformationDocument;
@property (nonatomic, strong)           UIBarButtonItem *barButtonItemEditDone;
@property (nonatomic, weak)   IBOutlet  UIBarButtonItem *barButtonItemTrash;
@property (nonatomic, weak)   IBOutlet  UIBarButtonItem *barButtonItemInformation;
@property (nonatomic, weak)   IBOutlet  UIBarButtonItem *barButtonItemAbout;
@property (nonatomic, weak)   IBOutlet  UIBarButtonItem *barButtonItemAddNewDocument;
@property (nonatomic, weak)   IBOutlet  UIBarButtonItem *barButtonItemCloudDown;
@property (nonatomic, strong)           UIBarButtonItem *barButtonItemDuplicate;

@property (nonatomic, strong) UIPopoverController *popoverControllerActivity;

@property (nonatomic, strong) MADSearchBar *searchBar;
@property (readonly) UILabel *titleView;

@property (nonatomic, strong) UIBarButtonItem *rightBarButtonItemHolderWhileActivity;

@property (nonatomic, strong) MADOpenFileSectionHeaderView *headerCloud;

@property (nonatomic, assign) BOOL cloudActivityRunning;
@property (nonatomic, assign) BOOL cloudActivityRunningDisplay;

@property (nonatomic, strong) UIProgressView *progressViewFileManager;

@property (atomic, assign, getter=isUpdatingEnabled) BOOL updatingEnabled;

@property (nonatomic, strong) NSMutableArray *batchInserts;
@property (nonatomic, strong) NSMutableArray *batchRemoves;
@property (nonatomic, strong) NSMutableArray *batchUpdates;

@property (nonatomic, strong) dispatch_queue_t queueSerialOperations;

@property (nonatomic, assign) BOOL getUserCloudPrefsFirstCall;

@end

@implementation MADOpenFileViewController

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField { return YES; }

#pragma mark - Helper functions

- (void)closeDocument:(UITraitCollection *)traitCollectionForThumbnail completion:(void (^)(BOOL))completion {
    if (self.openDocument && self.openDocument.documentState != UIDocumentStateClosed) {
        self.reportState = MTReportStateClosed;
        [self.fileManager removeDocumentWithUrl:self.fileManager.openUrl];
        [self.openDocument closeWithCompletionHandler:^(BOOL success) {
            completion(success);
        }];
    }
}

#pragma mark - Static Functions

+ (NSString *)keySubviews {
    return NSStringFromSelector(@selector(subviews));
}
+ (NSString *)keyLeftView {
    return NSStringFromSelector(@selector(leftView));
}

+ (NSOperationQueue *)queue {
    static NSOperationQueue *queue;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = [[NSOperationQueue alloc] init];
    });
    
    return queue;
}

#pragma mark - Public

- (void)getUserCloudPrefs {
    [self.filesCoordnator getUserCloudPrefs];
}

#pragma mark - NSObject

- (void)dealloc {
    [self removeObservers];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {

        self.getUserCloudPrefsFirstCall = YES;
        
        dispatch_queue_t queueSerialOperations = dispatch_queue_create("MADFileManager", DISPATCH_QUEUE_SERIAL);
        self.queueSerialOperations = queueSerialOperations;
        
        MADOpenDocumentManager *openFiles = [[MADOpenDocumentManager alloc] init];
        self.fileManager = openFiles;

        MADProgressView *progressView = [[MADProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
        self.progressViewFileManager = progressView;
        
        NSMutableArray *batchInserts = [[NSMutableArray alloc] init];
        self.batchInserts = batchInserts;
        
        NSMutableArray *batchRemoves = [[NSMutableArray alloc] init];
        self.batchRemoves = batchRemoves;
        
        NSMutableArray *batchUpdates = [[NSMutableArray alloc] init];
        self.batchUpdates = batchUpdates;

    }
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:[MADOpenFileViewController keySubviews]]) {
        if ([object isKindOfClass:[UITextField class]]) {
            for (UIView *view in ((UITextField *)object).subviews) {
                if ([view isKindOfClass:[UIButton class]]) {
                    UIImage *image = [((UIButton *)view).imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                    ((UIButton *)view).tintColor = [UIColor whiteColor];
                    [((UIButton *)view) setImage:image forState:UIControlStateNormal];
                }
            }
        }
    }
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.fileExplorerDelegate = self;
    
    [self addObservers];
    
    self.updatingEnabled = YES;
    self.cloudActivityRunning = NO;
    self.cloudActivityRunningDisplay = NO;
    self.rightBarButtonItemActivityIndicatorVisible = NO;
    
    [self setNeedsStatusBarAppearanceUpdate];
    
    self.collectionView.scrollIndicatorInsets = self.collectionView.contentInset;
    [self.collectionView registerClass: [MADOpenFileSectionHeaderView class]
            forSupplementaryViewOfKind: UICollectionElementKindSectionHeader
                   withReuseIdentifier: MADIdentifierOpenFileSectionHeader];
    
    [self setEditing:NO animated:NO];
    
    self.navigationController.toolbar.barTintColor = [UIColor tintColorBlue];
    self.navigationController.toolbar.tintColor = [UIColor tintColorWhite];
    
    self.collectionView.backgroundColor = [UIColor lightGrayColor];
        
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget: self
                                                                                           action: @selector(handleDidTapCollectionView:)];
    tapGestureRecognizer.delegate = self;
    [self.collectionView addGestureRecognizer:tapGestureRecognizer];
    
    
    MADSearchBar *searchBar = [[MADSearchBar alloc] initWithFrame:CGRectZero];
    [searchBar sizeToFit];
    self.searchBar = searchBar;

    
    NSMutableArray *toolbarButtons = self.toolbarItems.mutableCopy;
    [toolbarButtons removeObject:self.barButtonItemAction];
    [toolbarButtons removeObject:self.barButtonItemCloudDown];
    [toolbarButtons insertObject:self.barButtonItemDuplicate atIndex:1];
    
    [self setToolbarItems:toolbarButtons animated:NO];
    
    UIBarButtonItem *editButton = [UIBarButtonItem buttonEdit:self action:@selector(edit:)];
    self.barButtonItemEdit = editButton;
    [self.navigationItem setRightBarButtonItem:self.barButtonItemEdit animated:NO];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.collectionView.backgroundView setNeedsDisplay];
    [self.collectionView reloadItemsAtIndexPaths:self.collectionView.indexPathsForVisibleItems];
    
    [self addActionItemToToolbar:animated];
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (self.pendingLaunchContext) {
        [self configureViewControllerWithLaunchContext:self.pendingLaunchContext];
    }
    
    self.pendingLaunchContext = nil;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self.collectionView.backgroundView setNeedsDisplay];
}

#pragma mark - UIResponder

- (void)restoreUserActivityState:(NSUserActivity *)activity {
    // Obtain an app launch context from the provided activity and configure the view controller with it.
    MADAppLaunchContext *launchContext = [[MADAppLaunchContext alloc] initWithUserActivity:activity];
    
    // Configure the view controller with the launch context.
    [self configureViewControllerWithLaunchContext:launchContext];
}

#pragma mark - NSNotificationCenter

- (void)updateInterfaceForPerferedContentSizeCategory:(NSString *)preferredContentSizeCategory {
    for (MTCollectionViewCellDocument *cell in self.collectionView.visibleCells) {
        [cell updateFont];
    }
}

#pragma mark - UIViewController

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    if (self.traitCollection.horizontalSizeClass != previousTraitCollection.horizontalSizeClass) {
        [self.collectionView.collectionViewLayout invalidateLayout];
    }
}

- (void)willTransitionToTraitCollection: (UITraitCollection *)newCollection withTransitionCoordinator: (id<UIViewControllerTransitionCoordinator>)coordinator {
    
    [super willTransitionToTraitCollection: newCollection
                 withTransitionCoordinator: coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self.collectionView.backgroundView setNeedsLayout];
        [self.collectionView.backgroundView setNeedsDisplay];
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) { }];

}

- (void)displayActivityIndictor {
    if (self.cloudActivityRunning) {
        self.cloudActivityRunningDisplay = YES;
        [self.headerCloud startAnimating];
    }
}

- (UIViewController *)childViewControllerForStatusBarHidden {
    return self.presentedViewController;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
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

#pragma mark - UIDocumentInteractionControllerDelegate

- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *) controller {
    return self.navigationController;
}

#pragma mark - Static functions

#pragma mark - Custom Initalization

- (void)addActionItemToToolbar:(BOOL)animated {
    if ([self.toolbarItems containsObject: self.barButtonItemAction] == NO) {
        NSMutableArray *toolbarButtons = self.toolbarItems.mutableCopy;
        [toolbarButtons insertObject: self.barButtonItemAction atIndex: 1];
        [self setToolbarItems:toolbarButtons animated:animated];
    }
}

#pragma mark - MFMailComposeViewController delegate protocol

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [NSError presentError: error onViewController: self completion:^(BOOL success) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
}

#pragma mark -  NSFileManager delegate protocol

- (BOOL)fileManager:(NSFileManager *)fileManager shouldMoveItemAtURL:(NSURL *)srcURL toURL:(NSURL *)dstURL {
    return YES;
}

- (BOOL)fileManager:(NSFileManager *)fileManager shouldProceedAfterError:(NSError *)error movingItemAtURL:(NSURL *)srcURL toURL:(NSURL *)dstURL {
    
    //Only allow the thumbnails to proceed to after an error.
    return [dstURL.pathExtension.lowercaseString isEqualToString:MTDocumentExtentionPoratableNetworkGraphic];
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

- (void)openFileWithUrl:(NSURL *)url {
    [self.openFileDelegate openDocumentAtURL:url completionHandler:^(BOOL success, UIManagedDocument *document) {
        if (success) {
            self.fileManager.openDocument = document;
            [self performSelectorOnMainThread:@selector(handleFileOpenCompletion:) withObject:self waitUntilDone:NO];
        }
        [self reenable];
    }];
}

- (void)handleFileOpenCompletion:(id)sender {
    self.reportState = MTReportStateOpen;
    [self.openFileDelegate didOpenDocument:self.openDocument];
}

#pragma mark - MADCollectionViewLayoutFilesDelegate

- (void)userSelectedItemAtIndexPath:(NSIndexPath *)indexPath {
    
    MADMetaData *metadata = [self.filesCoordnator.filesController objectAtIndexedSubscript:indexPath.item];
    MTCollectionViewCellDocument *cell = (MTCollectionViewCellDocument *)[self.collectionView cellForItemAtIndexPath:indexPath];
    [cell performSelectionAnimations];
    
    if (self.isEditing) {
        [self.collectionView selectItemAtIndexPath:indexPath animated:YES scrollPosition:UICollectionViewScrollPositionCenteredVertically];
        if (metadata.isUbiquitous) {
            if (metadata.isUbiquitousItemDownloadingStatusNotDownloaded) {
                NSError *error = nil;
                [[NSFileManager defaultManager] startDownloadingUbiquitousItemAtURL:metadata.URL error:&error];
            }
        }
    } else {
        [cell stopWobble];
        [self.collectionView deselectItemAtIndexPath:indexPath animated:YES];
        [cell.activityIndicator startAnimating];
        [self.collectionView setUserInteractionEnabled: NO];
        [self openFileWithUrl:metadata.URL];
        [cell normalizeTint];
    }
}

#pragma mark - Touch Event Handlers

- (void)handleDidTapCollectionView:(UIGestureRecognizer *)sender {
    [self.searchBar resignFirstResponder];
    if (self.isEditing) {
        [self edit:self];
    }
}

#pragma mark UI Helpers

- (UILabel *)titleView {
    return (UILabel *)self.navigationItem.titleView;
}

- (void)reenable {
    self.collectionView.userInteractionEnabled = YES;
    for (MTCollectionViewCellDocument *cell in self.collectionView.visibleCells) {
        [cell.activityIndicator stopAnimating];
    }
}

- (void)loadCollectionViewPreviewImageForIndexPath:(NSIndexPath *)indexPath {
   NSURL *fileUrl = [self documentForIndexPath:indexPath];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        dispatch_sync(dispatch_get_main_queue(), ^(void) {
            
            MTCollectionViewCellDocument *visibleCell = (MTCollectionViewCellDocument *)[self.collectionView cellForItemAtIndexPath:indexPath];
            NSURL *url = [UIDocument thumbnailWithBorderUrlForMadUrl:fileUrl];
            NSString *path = [url path];
            UIImage *image = [[UIImage alloc] initWithContentsOfFile:path];
            if (image) {
                visibleCell.imagePreview.image = image;
            } else {
                UIImage *defaultThumbnail = [MTCollectionViewCellDocument defaultThumbnail];
                visibleCell.imagePreview.image = defaultThumbnail;
            }
            [visibleCell setNeedsLayout];
            
        });
    });
}

- (void)selectionsUpdated {
    switch (self.collectionView.indexPathsForSelectedItems.count) {
        case 0:
            self.barButtonItemInformationDocument.enabled = NO;
            self.barButtonItemTrash.enabled = NO;
            self.barButtonItemDuplicate.enabled = NO;
            self.barButtonItemAction.enabled = NO;
            break;
        case 1:
            self.barButtonItemInformationDocument.enabled = YES;
            self.barButtonItemTrash.enabled = YES;
            self.barButtonItemDuplicate.enabled = YES;
            self.barButtonItemAction.enabled = YES;
            break;
        default:
            self.barButtonItemInformationDocument.enabled = YES;
            self.barButtonItemTrash.enabled = YES;
            self.barButtonItemDuplicate.enabled = YES;
            self.barButtonItemAction.enabled = NO;
            break;
    }
}

#pragma mark - UIDocumentPickerDelegate

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentAtURL:(NSURL *)url {
    [controller removeFromParentViewController];
}

- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller {
    [controller removeFromParentViewController];
}

- (void)showViewController:(UIViewController *)vc sender:(id)sender {
    if (self.presentedViewController != nil) {
        [self dismissViewControllerAnimated: YES completion:^{
            [self presentViewController: vc animated: YES completion: nil];
        }];
    } else {
        [self presentViewController: vc animated: YES completion: nil];
    }
}

- (void)setRightBarButtonItemActivityIndicatorVisible:(BOOL)rightBarButtonItemActivityIndicatorVisible
                                             animated:(BOOL)animated {
    
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

#pragma mark - MADFilesControllerDelegate

- (void)filesControllerWillChangeContent:(MADFilesController *)filesController {
    [self.batchInserts removeAllObjects];
    [self.batchRemoves removeAllObjects];
    [self.batchUpdates removeAllObjects];
}

- (void)filesController:(MADFilesController *)filesController didInsertListInfo:(MADFileInfo *)listInfo atIndex:(NSInteger)index {
    NSNumber *i = @(index);
    MTPair *pair = [[MTPair alloc] initWithLeft:listInfo andRight:i];
    [self.batchInserts addObject:pair];
}

- (void)filesController:(MADFilesController *)filesController didRemoveListInfo:(MADFileInfo *)listInfo atIndex:(NSInteger)index {
    NSNumber *i = @(index);
    MTPair *pair = [[MTPair alloc] initWithLeft:listInfo andRight:i];
    [self.batchRemoves addObject:pair];
}

- (void)filesController:(MADFilesController *)filesController didUpdateListInfo:(MADFileInfo *)listInfo atIndex:(NSInteger)index {
    NSNumber *i = @(index);
    MTPair *pair = [[MTPair alloc] initWithLeft:listInfo andRight:i];
    [self.batchUpdates addObject:pair];
}

- (void)filesControllerDidChangeContent:(MADFilesController *)filesController completion:(void (^)(BOOL, NSError *))completion {
    NSIndexPath *path;
    MTPair *pair;
    NSMutableArray *inserts = [[NSMutableArray alloc] initWithCapacity:self.batchInserts.count];
    for (pair in self.batchInserts) {
        path = [NSIndexPath indexPathForItem:((NSNumber *)pair.right).integerValue
                                   inSection:0];
        [inserts addObject:path];
    }

    NSMutableArray *removes = [[NSMutableArray alloc] initWithCapacity:self.batchRemoves.count];
    for (pair in self.batchRemoves) {
        path = [NSIndexPath indexPathForItem:((NSNumber *)pair.right).integerValue
                                   inSection:0];
        [removes addObject:path];
    }

    NSMutableArray *updates = [[NSMutableArray alloc] initWithCapacity:self.batchUpdates.count];
    for (pair in self.batchUpdates) {
        path = [NSIndexPath indexPathForItem:((NSNumber *)pair.right).integerValue inSection:0];
        [updates addObject:path];
    }

    [updates removeObjectsInArray:inserts];
    [updates removeObjectsInArray:removes];
    
    [self.collectionView performBatchUpdates:^{
        if (inserts.count > 0) {
            [self.collectionView insertItemsAtIndexPaths: inserts];
        }
        if (removes.count > 0) {
            [self.collectionView deleteItemsAtIndexPaths: removes];
        }
        if (updates.count > 0) {
            [self.collectionView reloadItemsAtIndexPaths: updates];
        }
    } completion:^(BOOL finished) {
        if (finished) {
            [self.collectionView reloadItemsAtIndexPaths:self.collectionView.indexPathsForVisibleItems];
            completion(YES, nil);
        }
    }];
}

- (void)filesController:(MADFilesController *)filesController didFailCreatingListInfo:(MADFileInfo *)listInfo withError:(NSError *)error { }

- (void)filesController:(MADFilesController *)filesController didFailRemovingListInfo:(MADFileInfo *)listInfo withError:(NSError *)error { }

- (void)filesController:(MADFilesController *)filesController didFailDuplicatingListInfo:(MADFileInfo *)listInfo withError:(NSError *)error { }

- (void)editFile:(id)sender {
    [self activateEditMode:sender];
}

- (void)emailFile:(id)sender {
    [self email:sender];
}

- (void)renameFile:(id)sender {
    [self rename:sender];
}

- (void)duplicateFile:(id)sender {
    [self actionDuplicate:sender];
}

#pragma mark - Actions

- (IBAction)cancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.barButtonItemAddNewDocument setEnabled:YES];
}

- (IBAction)search:(id)sender {
    if (self.searchBar.isHidden) {
        self.searchBar.hidden = NO;
        self.searchBar.showsCancelButton = NO;
        self.searchBar.alpha = 0.0000f;
        self.titleView.alpha = 1.0000f;
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
        self.searchBar.backgroundColor = [UIColor clearColor];
        self.searchBar.barTintColor = [UIColor whiteColor];
        self.searchBar.tintColor = [UIColor whiteColor];
        
        
        [UIView transitionWithView:self.navigationItem.titleView
                          duration:0.2000f
                           options:UIViewAnimationOptionCurveEaseOut animations:^{
                               weakself.searchBar.alpha = 1.0000f;
                               weakself.titleView.alpha = 0.0000f;
                               weakself.navigationItem.titleView = searchViewHolder;
                           } completion:^(BOOL finished) {
                               if (weakself.searchBar.isFirstResponder == NO) {
                                   [weakself.searchBar becomeFirstResponder];
                               }
                           }];
        
    } else {
        if (self.searchBar.text.length > 0) {
            self.searchBar.text = @"";
        }
        self.searchBar.hidden = YES;
        self.searchBar.alpha = 0.1000f;
        self.titleView.alpha = 0.0000f;
        self.navigationItem.leftBarButtonItem.enabled = YES;
        __weak MADOpenFileViewController *weakself = self;
        [UIView transitionWithView:self.navigationItem.titleView
                          duration:0.2000f
                           options:UIViewAnimationOptionCurveEaseOut animations:^{
                               weakself.searchBar.alpha = 0.0000f;
                               weakself.titleView.alpha = 1.0000f;
                               weakself.navigationItem.titleView = weakself.titleView;
                           } completion:nil];
        
    }
}

- (IBAction)edit:(id)sender {
    
    BOOL startEdit = !self.isEditing;
    [self setEditing:startEdit animated:YES];
    
    if (startEdit) {
        
        //self.barButtonItemLicensing.enabled = NO;
        self.barButtonItemAddNewDocument.enabled = NO;
        self.barButtonItemAbout.enabled = NO;
        self.barButtonItemInformation.enabled = NO;
        self.collectionView.allowsMultipleSelection = YES;
        
        for (MTCollectionViewCellDocument *cell in self.collectionView.visibleCells) {
            [cell startWobble];
        }
        [self.navigationItem setRightBarButtonItem: self.barButtonItemEditDone animated: YES];
        
    } else {
        [self done:sender];
    }
}

- (void)done:(id)sender {
    self.editing = NO;
    //self.barButtonItemLicensing.enabled = [SKPaymentQueue canMakePayments];
    self.barButtonItemAddNewDocument.enabled = YES;
    self.barButtonItemAbout.enabled = YES;
    self.barButtonItemInformation.enabled = YES;
    
    self.barButtonItemTrash.enabled = NO;
    self.barButtonItemInformationDocument.enabled = NO;
    self.barButtonItemDuplicate.enabled = NO;
    self.barButtonItemAction.enabled = NO;
    
    self.collectionView.allowsMultipleSelection = NO;
    
    [self.navigationItem setRightBarButtonItem:self.barButtonItemEdit animated:YES];
    for (NSIndexPath *path in self.collectionView.indexPathsForSelectedItems) {
        [self.collectionView deselectItemAtIndexPath:path animated:YES];
    }
    for (MTCollectionViewCellDocument *cell in self.collectionView.visibleCells) {
        [cell stopWobble];
        [cell normalizeTint];
    }

}

- (IBAction)download:(id)sender {
    NSArray *documentTypes = [self.openFileDelegate supportedUTIs];
    UIDocumentPickerViewController *vc = [[UIDocumentPickerViewController alloc] initWithDocumentTypes: documentTypes
                                                                                                inMode: UIDocumentPickerModeImport];
    vc.delegate = self;
    [self presentViewController:vc animated:YES completion:^{}];
}

- (void)cut:(id)sender {
    [super cut:sender];
}

- (void)copy:(id)sender {
    [super copy:sender];
}

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
    [self.collectionView reloadData];
}

- (IBAction)activity:(id)sender {
    
    NSMutableArray *wrappedUrls = [[NSMutableArray alloc] initWithCapacity: self.filesCoordnator.filesController ? self.filesCoordnator.filesController.count : 0];
    for (NSIndexPath *selectedCellLocation in self.collectionView.indexPathsForSelectedItems) {
        NSURL *fileUrl = [self documentForIndexPath:selectedCellLocation];
        [wrappedUrls addObject:fileUrl];
    }
    NSUInteger numberOfItemsInSection = [self.collectionView numberOfItemsInSection:0];
    for (NSInteger i=0; i<numberOfItemsInSection; i++) {
        NSIndexPath *path = [NSIndexPath indexPathForItem:i inSection:0];
        MTCollectionViewCellDocument *documentCell = (MTCollectionViewCellDocument *)[self.collectionView cellForItemAtIndexPath:path];
        if (documentCell != nil) {
            [documentCell normalizeTint];
        }
    }
    
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:wrappedUrls applicationActivities:@[]];
    [activityViewController setExcludedActivityTypes:@[UIActivityTypeAssignToContact, UIActivityTypePostToFacebook, UIActivityTypePostToFlickr, UIActivityTypePostToTwitter, UIActivityTypePostToVimeo]];
    [activityViewController setCompletionWithItemsHandler: ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
        
        NSUInteger numberOfItemsInSection = [self.collectionView numberOfItemsInSection:0];
        for (NSInteger i=0; i<numberOfItemsInSection; i++) {
            NSIndexPath *path = [NSIndexPath indexPathForItem:i inSection:0];
            MTCollectionViewCellDocument *documentCell = (MTCollectionViewCellDocument *)[self.collectionView cellForItemAtIndexPath:path];
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
    NSArray *selectedItems = self.collectionView.indexPathsForSelectedItems;
    UIAlertController *alertController = [UIAlertController deleteItems:selectedItems.count
                                                                confirm:^(UIAlertAction *action) {
                                                                    for (NSIndexPath *selectedItem in selectedItems) {
                                                                        MADMetaData *metaData = [self.filesCoordnator.filesController objectAtIndexedSubscript:selectedItem.item];
                                                                        [self.filesCoordnator.filesController removeFileInfo:metaData];
                                                                    }
                                                                } cancel:^(UIAlertAction *action) {
                                                                    
                                                                }];
    if ([sender isKindOfClass:[UIBarButtonItem class]]) {
        alertController.popoverPresentationController.barButtonItem = sender;
    }
    [self presentViewController:alertController animated:YES completion:NULL];
}

- (void)actionDuplicate:(id)sender {
    for (NSIndexPath *selectedItem in self.collectionView.indexPathsForSelectedItems) {
        MADMetaData *metaData = [self.filesCoordnator.filesController objectAtIndexedSubscript:selectedItem.item];
        [self.filesCoordnator.filesController duplicateFileInfo:metaData];
    }
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
    
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cellDocument];
    MADMetaData *metaData = [self.filesCoordnator.filesController objectAtIndexedSubscript:indexPath.item];
    
    UIAlertController *alert = [UIAlertController renameDocument:^(UITextField *textField) {
        
        textField.text = cellDocument.labelTitle.text;
        textField.clearButtonMode = UITextFieldViewModeAlways;
        textField.delegate = self;
        
    } confirm:^(UIAlertAction *action, NSString *text) {
        
        NSString *name = [NSURL fileNameFilter:text];
        if (name.length > 0) {
            NSURL *newUrl = [metaData.URL.URLByDeletingLastPathComponent URLByAppendingPathComponent:name isDirectory:NO];
            if ([[NSFileManager defaultManager] fileExistsAtPath:newUrl.path] == NO && [[NSFileManager defaultManager] isUbiquitousItemAtURL:newUrl] == NO) {
                if (metaData.isUbiquitousItemDownloadingStatusNotDownloaded) {
                    
                    UIDocument *doc = [self.openFileDelegate documentForURL:metaData.URL];
                    [doc openWithCompletionHandler:^(BOOL success) {
                        if (success) {
                            [doc closeWithCompletionHandler:^(BOOL success) {
                                if (success) {
                                    [self.filesCoordnator.filesController renameFileInfo:metaData toName:text];
                                }
                            }];
                        }
                    }];
                    
                } else {
                    [self.filesCoordnator.filesController renameFileInfo:metaData toName:text];
                }
            } else {
                UIAlertController *alert = [UIAlertController errorFileExist];
                [self showViewController:alert sender:self];
            }
        } else {
            UIAlertController *alert = [UIAlertController errorValidationFilename];
            [self showViewController:alert sender:self];
        }
        
    } cancel:nil];
    
    [self showViewController:alert sender:self];
    
}

- (void)email:(MTCollectionViewCellDocument *)cell {
    
    if ([MFMailComposeViewController canSendMail] == NO) {
        
        UIAlertController *alert = [UIAlertController alertNotConfiguredForEmail];
        [self showViewController:alert sender:self];
        
    } else {
        
        NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
        MADMetaData *metadata = [self.filesCoordnator.filesController objectAtIndexedSubscript:indexPath.item];
        UIManagedDocument *documentReport = [self.openFileDelegate documentForURL:metadata.URL];
        if (documentReport.documentState != UIDocumentStateClosed) {
            [documentReport closeWithCompletionHandler:^(BOOL success) {
                if (success) {
                    [self email:cell];
                }
            }];
        } else {
            
            NSString *mimeType = [self.openFileDelegate mimeTypeForDocumentUTI:documentReport.fileType];
            NSString *messageStringStart = NSLocalizedString(@"The attached document can be opened with MAD Viewer.",
                                                             @"The attached document can be opened with MAD Viewer.");
            NSMutableString *messageBody = [[NSMutableString alloc] initWithString:messageStringStart];
            [messageBody appendString:@"\n\nhttp://www.everydayapps.com/\n\n"];
            MFMailComposeViewController	*mailComposer = [MFMailComposeViewController body: messageBody
                                                                               attachment: metadata.URL
                                                                                 mimeType: mimeType
                                                                       userInterfaceIdiom: self.traitCollection.userInterfaceIdiom];
            mailComposer.mailComposeDelegate = self;
            [self showViewController:mailComposer sender:self];
        }
    }
}

- (void)activateEditMode:(UILongPressGestureRecognizer *)sender {

    if (sender.state == UIGestureRecognizerStateBegan) {
        NSIndexPath *indexPath = [self.collectionView indexPathForCell:((MTCollectionViewCellDocument *)sender.view)];
        if (self.isEditing == NO) [self edit:self];
        
        [self.collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
        [self selectionsUpdated];
    }
}

#pragma mark - Notification Handlers

- (void)handleCloudActivityStarted:(NSNotification *)notification {
    self.cloudActivityRunning = YES;
    NSTimer *timer = [NSTimer timerWithTimeInterval: 0.5000f
                                             target: self
                                           selector: @selector(displayActivityIndictor)
                                           userInfo: nil
                                            repeats: NO];
    [timer fire];
}

- (void)handleContentSizeCategoryDidChangeNotification:(NSNotification *)notification {
    NSString *contentSize = notification.userInfo[UIContentSizeCategoryNewValueKey];
    [self updateInterfaceForPerferedContentSizeCategory:contentSize];
    [self.view setNeedsLayout];
}

- (void)handleCloudActivityCompleted:(NSNotification *)notification {
    self.cloudActivityRunning = NO;
    self.cloudActivityRunningDisplay = NO;
    [self.headerCloud stopAnimating];
}

#pragma mark - Convenience

- (NSArray *)defaultPassthoughViews {
    return @[self.navigationController.navigationBar, self.navigationController.toolbar];
}

- (NSURL *)documentForIndexPath:(NSIndexPath *)indexPath {
    MADMetaData *metadata = [self.filesCoordnator.filesController objectAtIndexedSubscript:indexPath.item];
    return metadata.URL;
}

- (void)configureViewControllerWithLaunchContext:(MADAppLaunchContext *)launchContext {
    /**
     If there is a list currently displayed; pop to the root view controller (this controller) and
     continue configuration from there. Otherwise, configure the view controller directly.
     */
    if ([self.navigationController.topViewController isKindOfClass:[UINavigationController class]]) {
        [self.navigationController popToRootViewControllerAnimated:NO];
        self.pendingLaunchContext = launchContext;
        return;
    }
}

- (void)addObservers {
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleContentSizeCategoryDidChangeNotification:)
                                                 name: UIContentSizeCategoryDidChangeNotification
                                               object: nil];
    
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleCloudActivityStarted:)
                                                 name: @"MADNotificationCloudActivityStarted"
                                               object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleCloudActivityCompleted:)
                                                 name: @"MADNotificationCloudActivityCompleted"
                                               object: nil];
}

- (void)removeObservers {
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: UIContentSizeCategoryDidChangeNotification
                                                  object: nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: @"MADNotificationCloudActivityStarted"
                                                  object: nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: @"MADNotificationCloudActivityCompleted"
                                                  object: nil];
}

#pragma mark Add controls

- (void)addProgressViewToView {
    self.progressViewFileManager.progress = 0.0000f;
    [self.view addSubview:self.progressViewFileManager];
    [self.view bringSubviewToFront:self.progressViewFileManager];
}

- (void)removeProgressViewFromView {
    [self.progressViewFileManager removeFromSuperview];
}

#pragma mark - Lazy Load

- (UIBarButtonItem *)barButtonItemEditDone {
    if (!_barButtonItemEditDone) {
        _barButtonItemEditDone = [UIBarButtonItem buttonEditDone:self action:@selector(edit:)];
    }
    return _barButtonItemEditDone;
}

- (UIBarButtonItem *)barButtonItemDuplicate {
    if (!_barButtonItemDuplicate) {
        _barButtonItemDuplicate = [UIBarButtonItem buttonDuplicate:self action:@selector(actionDuplicate:)];
    }
    return _barButtonItemDuplicate;
}

#pragma mark - UIPopoverControllerDelegate

- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController {
    return YES;
}

@end
