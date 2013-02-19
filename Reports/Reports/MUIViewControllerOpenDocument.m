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

@interface MUIViewControllerOpenDocument()

@property (nonatomic, retain) NSURL *urlBeingOpended;
@property (nonatomic, retain) NSMutableArray *availableFilesCache;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *barButtonItemTitle;

@property (nonatomic, retain) MTQueryBuilderAdvancedViewController *advancedQueryBuilder;
@property (nonatomic, retain) MTViewControllerQueryBuilder *standardQueryBuilder;

@end

@implementation MUIViewControllerOpenDocument

- (void)dealloc {
    [_advancedQueryBuilder release];
    [_standardQueryBuilder release];
    [_urlBeingOpended release];
    [_availableFilesCache release];
    [_tableViewControllerDataSourceTypes release];
    [_tableViewQueries release];
    [_toolbar release];
    [_barButtonItemTitle release];
    [super dealloc];
}

- (void)awakeFromNib {
    self.contentSizeForViewInPopover = CGSizeMake(320.0, 480.0);
    [super awakeFromNib];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        //[[UIToolbar appearance] setTintColor:[UIColor clearColor]];
    }
    return self;    
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        //[[UIToolbar appearance] setTintColor:[UIColor clearColor]];
    }
    return self;
}


#pragma mark - UIViewController Overrides

- (void)viewDidLoad {
    [super viewDidLoad];
    //[[UIToolbar appearance] setTintColor:[UIColor clearColor]];

	// Do any additional setup after loading the view, typically from a nib.
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
    [self setTableViewControllerDataSourceTypes: nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    //NSLog(@"[segue identifier]                  %@", [segue identifier]);
    //NSLog(@"[segue destinationViewController]   %@", [segue destinationViewController]);
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
        if ([sender isKindOfClass:[UITableViewCellDocument class]]) {
            
            UITableViewCellDocument *senderCell = sender;
            row = [[[self tableViewQueries] indexPathForCell:senderCell] row];
            
            
            NSURL *url = [[[self availableFilesCache] objectAtIndex: row] retain];
            [self setUrlBeingOpended:url];
            
            //If Phone version, setup here, else Pad and setup on delegate callback.
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

#pragma mark - Delegates

- (void)viewControllerDidFinish:(id)sender {
    MNSDocumentReport *documentReport = [[AppDelegate activeDocument] retain];
    if (documentReport != nil) {
        [documentReport saveContext];
        [documentReport save:^(BOOL success) {
            if (success) {
                [AppDelegate setActiveDocument: nil];
                [[self tableViewQueries] reloadData];
            }
            [self dismissViewControllerAnimated:YES completion:nil];
        }];
    } else {
        NSMutableArray *a = [[NSMutableArray alloc] initWithArray:[NSFileManager schemaFiles]];
        [self setAvailableFilesCache: a];
        [a release];
        [[self tableViewQueries] reloadData];
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
    if (!result) {
        UINib *resultCellNib = [UINib nibWithNibName:@"UITableViewCellDocument" bundle:nil];
        [resultCellNib instantiateWithOwner:self options:nil];
        result = [self uITableViewCellDocument];
        [self setUITableViewCellDocument:nil];
    }
    if (row < [[self availableFilesCache] count]) {
        NSURL *url = [[self availableFilesCache] objectAtIndex:row];
        [[result imageThumbnail] setImage:[UITableViewCellDocument defaultThumbnail]];
        [[result labelH1] setText: [url lastPathComponent]];
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
    //UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
    //[self performSegueWithIdentifier:SEGUE_OPENDOCUMENT sender:selectedCell];
}

/*- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
 return 0.0000f;
 }*/

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [UITableViewCellDocument defaultHeight];
}

@end