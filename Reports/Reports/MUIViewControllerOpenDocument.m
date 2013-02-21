//
//  FlipsideViewController.m
//  Reports
//
//  Created by Michael Thomason on 1/2/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MUIViewControllerOpenDocument.h"
#import "MNSDocumentReport.h"
#import "AppDelegate.h"
#import "MTSplitViewController.h"
#import "MTQueryBuilderAdvancedViewController.h"
#import "RptqDocument+ActiveDocument.h"

NSString * const SEGUE_SHOWADDDOCUMENT = @"showAddDocument";
NSString * const SEGUE_OPENDOCUMENT = @"openDocument";

NSString * const MTCollectionViewCellDocumentIdentifier = @"MTCollectionViewCellDocumentIdentifier";

@interface MUIViewControllerOpenDocument()

@property (nonatomic, retain) NSURL *urlBeingOpended;
@property (nonatomic, retain) NSMutableArray *availableFilesCache;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *barButtonItemTitle;

@property (nonatomic, retain) MTQueryBuilderAdvancedViewController *advancedQueryBuilder;
@property (nonatomic, retain) MTViewControllerQueryBuilder *standardQueryBuilder;

@property (nonatomic, retain) UILongPressGestureRecognizer *longPressGestureRecognizer;
@property (nonatomic, retain) UITapGestureRecognizer *tapGestureRecognizer;

@property (nonatomic, assign) BOOL editModeEnabled;

@end

@implementation MUIViewControllerOpenDocument

- (void)dealloc {
    [_advancedQueryBuilder release];
    [_standardQueryBuilder release];
    [_tapGestureRecognizer release];
    [_longPressGestureRecognizer release];
    [_urlBeingOpended release];
    [_availableFilesCache release];
    [_tableViewQueries release];
    [_toolbar release];
    [_barButtonItemTitle release];
    [_collectionViewQueries release];
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
        [[self collectionViewQueries] registerClass: [MTCollectionViewCellDocument class]
                         forCellWithReuseIdentifier: MTCollectionViewCellDocumentIdentifier];
        
        [self setEditModeEnabled:NO];

    }
    return self;    
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {

        [[self collectionViewQueries] registerClass: [MTCollectionViewCellDocument class]
                         forCellWithReuseIdentifier: MTCollectionViewCellDocumentIdentifier];
        
        [self setEditModeEnabled:NO];

    }
    return self;
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
    return YES;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    return action == @selector(cut:) ||
        action == @selector(copy:) ||
        action == @selector(paste:) ||
        action == @selector(delete:) ||
        [super canPerformAction:action withSender:sender];
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

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {

}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [super prepareForSegue:segue sender:sender];

    if ([[segue identifier] isEqualToString:SEGUE_SHOWADDDOCUMENT]) {
        if ([[segue destinationViewController] isKindOfClass: [UINavigationController class]]) {
            UINavigationController *navControl = [[segue destinationViewController] retain];
            if ([navControl topViewController]) {
                if ([[navControl topViewController] isKindOfClass:[MUIViewControllerTemplateSelector class]]) {
                    MUIViewControllerTemplateSelector *tvc = (MUIViewControllerTemplateSelector *)[[navControl topViewController] retain];
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
        
    } else if ([[segue identifier] isEqualToString:SEGUE_OPENDOCUMENT]) {
        
        NSUInteger row = 0;
        NSURL *url = nil;
        if ([sender isKindOfClass:[UITableViewCellDocument class]]) {
            
            UITableViewCellDocument *senderCell = sender;
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
                    
                    if ([[navControl topViewController] isKindOfClass:[MTViewControllerQueryBuilder class]]) {
                        MTViewControllerQueryBuilder *tvc = [(MTViewControllerQueryBuilder *)[navControl topViewController] retain];
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
        } else if ([[segue destinationViewController] isKindOfClass:[MTSplitViewController class]]) {
            
            MTSplitViewController *splitViewController = (MTSplitViewController* )[[segue destinationViewController] retain];
            [splitViewController setDelegate: self];
            [splitViewController release];
            
        }
        
        
        [url release];
        
    }
}

- (void)displayContentController:(UIViewController *)contentController {
    UIViewController *childController = [contentController retain];

    if ([contentController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *childNavigationController = (UINavigationController *)[contentController retain];
        if ([[childNavigationController topViewController] isKindOfClass:[MTViewControllerQueryBuilder class]]) {
            MTViewControllerQueryBuilder *queryBuilderViewController = (MTViewControllerQueryBuilder *)[[childNavigationController topViewController] retain];
            [self setStandardQueryBuilder:queryBuilderViewController];
            [queryBuilderViewController release];
            
        }
        [childNavigationController release];
    } else if ([contentController isKindOfClass:[MTQueryBuilderAdvancedViewController class]]) {
        MTQueryBuilderAdvancedViewController *advancedControl = (MTQueryBuilderAdvancedViewController *)contentController;
        [self setAdvancedQueryBuilder:advancedControl];
    }
    
    if ([self advancedQueryBuilder] != nil && [self standardQueryBuilder] != nil) {

        [[self standardQueryBuilder] setDelegate: self];
        MNSDocumentReport *documentReport = [[MNSDocumentReport alloc] initExistingExistingFileWithUrl:[self urlBeingOpended] completion:^(BOOL success, id document) {
            if (success) {
                [AppDelegate setActiveDocument: document];
                [[self standardQueryBuilder] reloadDocument:document];
                [[self advancedQueryBuilder] reloadDocument:document];
            }
        }];
        [documentReport release];
    }
    [childController release];
}

- (void)setupQueryDesignerController:(MTViewControllerQueryBuilder *)tvc usingFileAtUrl:(NSURL*)url {
    [tvc setDelegate: self];
    MNSDocumentReport *documentReport = [[MNSDocumentReport alloc] initExistingExistingFileWithUrl:url completion:^(BOOL success, id document) {
        if (success) {
            [AppDelegate setActiveDocument: document];
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
    NSString *title = NSLocalizedString(@"About Reports", @"About Reports");
    NSString *message = NSLocalizedString(@"© Everyday Apps LLC 2013.  Software created by Michael Thomason for Everyday Apps LLC.", @"© Everyday Apps LLC 2013.  Software created by Michael Thomason for Everyday Apps LLC.");
    NSString *buttonTitle = NSLocalizedString(@"Continue", @"Continue");
    [UIAlertView showAlertViewWithTitle: title
                                message: message
                      cancelButtonTitle: buttonTitle
                       otherButtonTitle: nil onDismiss: nil onCancel: nil];
}

- (IBAction)delete:(id)sender {
    if ([self collectionViewQueries] != nil) {
        for (NSUInteger section = 0; section < [[self collectionViewQueries] numberOfSections]; section++) {
            for (NSUInteger item = 0; item < [[self collectionViewQueries] numberOfItemsInSection:section]; item++) {
                NSIndexPath *selectedCellLocation = [[NSIndexPath indexPathForItem:item inSection:section] retain];
                MTCollectionViewCellDocument *documentCell = [(MTCollectionViewCellDocument *)[[self collectionViewQueries] cellForItemAtIndexPath:selectedCellLocation] retain];
                if (documentCell != nil) {
                    if ([documentCell isSelected]) {
                        
                        NSError *error = nil;
                        [[NSFileManager defaultManager] removeItemAtURL:[[self availableFilesCache] objectAtIndex:item] error:&error];
                        if (!error) {
                            if (item < [[self availableFilesCache] count]) {
                                [[self availableFilesCache] removeObjectAtIndex:item];
                                [[self collectionViewQueries] deleteItemsAtIndexPaths:@[selectedCellLocation]];
                            }
                        } else {
                            [error presentErrorToUser];
                        }
                        
                        
                    }
                }
                [selectedCellLocation release];
                [documentCell release];
            }
        }
    }
}

#pragma mark - Delegates

- (void)viewControllerDidFinish:(id)sender {
    MNSDocumentReport *documentReport = [[AppDelegate activeDocument] retain];
    if (documentReport != nil) {
        [documentReport saveContext];
        [documentReport save:^(BOOL success) {
            if (success) {
                [AppDelegate setActiveDocument: nil];
                [[self tableViewQueries] reloadData];
                [[self collectionViewQueries] reloadData];
            }
            [self dismissViewControllerAnimated:YES completion:nil];
        }];
    } else {
        NSMutableArray *a = [[NSMutableArray alloc] initWithArray:[NSFileManager schemaFiles]];
        [self setAvailableFilesCache: a];
        [a release];
        [[self tableViewQueries] reloadData];
        [[self collectionViewQueries] reloadData];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    [documentReport release];
}

- (void)viewControllerDidCancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
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
    UITableViewCellDocument *result = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
    if (row < [[self availableFilesCache] count]) {
        NSURL *url = [[self availableFilesCache] objectAtIndex:row];
        [[result imageThumbnail] setImage:[UITableViewCellDocument defaultThumbnail]];
        [[result labelH1] setText: [[url lastPathComponent] stringByDeletingPathExtension]];
        [[result labelH2] setText:NSLocalizedString(@"Fixme Default Text.", @"A subheading.")];
    } else {
        [[result imageThumbnail] setImage:[UITableViewCellDocument defaultThumbnail]];
        [[result labelH1] setText: @""];    
        [[result labelH2] setText: @""];
    }
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
    return [UITableViewCellDocument defaultHeight];
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

#pragma mark -
#pragma mark Collection View Data Protocol

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    MTCollectionViewCellDocument *result = [[collectionView dequeueReusableCellWithReuseIdentifier:MTCollectionViewCellDocumentIdentifier
                                                                                      forIndexPath:indexPath] retain];
    if ([indexPath row] < [[self availableFilesCache] count]) {
        NSURL *url = [[self availableFilesCache] objectAtIndex:[indexPath row]];
        [[result imagePreview] setImage:[UITableViewCellDocument defaultThumbnail]];
        [[result labelTitle] setText: [[url lastPathComponent] stringByDeletingPathExtension]];
    } else {
        [[result imagePreview] setImage:[UITableViewCellDocument defaultThumbnail]];
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
