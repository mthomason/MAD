//
//  FlipsideViewController.m
//  TheReportViewer
//
//  Created by Michael Thomason on 1/2/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "UIViewControllerDatabases.h"
#import "UITableViewCellDocument.h"
#import "NSFileManager+Reports.h"

@interface UIViewControllerDatabases()

@property (retain) NSMutableArray *availableFilesCache;
@property (assign) NSUInteger selectedDocument;             //The document inside the array to to open.

@end

@implementation UIViewControllerDatabases

@synthesize delegate = _delegate;
@synthesize tableViewControllerDataSourceTypes = _tableViewControllerDataSourceTypes;
@synthesize uITableViewCellDocument;
@synthesize tableViewQueries = _tableViewQueries;
@synthesize availableFilesCache = _availableFilesCache;
@synthesize selectedDocument = _selectedDocument;

- (void)dealloc {
    [_availableFilesCache release];
    [_tableViewControllerDataSourceTypes release];
    [_tableViewQueries release];
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

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidUnload {
    [self setTableViewQueries:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    NSMutableArray *a = [[NSMutableArray alloc] initWithArray:[NSFileManager schemaFiles]];
    [self setAvailableFilesCache: a];
    [a release];
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
    // Return YES for supported orientations
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    [self setTableViewControllerDataSourceTypes: nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showDatabasesDrivers"]) {
        //Set UITableViewControllerDataSourceTypes delegate
        if ([[segue destinationViewController] isKindOfClass: [UINavigationController class]]) {
            UINavigationController *navControl = [[segue destinationViewController] retain];
            if ([navControl topViewController]) {
                if ([[navControl topViewController] isKindOfClass:[UITableViewControllerDataSourceTypes class]]) {
                    UITableViewControllerDataSourceTypes *tvc = (UITableViewControllerDataSourceTypes *)[[navControl topViewController] retain];
                    if (tvc) [tvc setDelegate:self];
                    [tvc release];
                }
            }
            
            [navControl release];
        }
        [[segue destinationViewController] setDelegate:self];
        
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            UIPopoverController *popoverController = [(UIStoryboardPopoverSegue *)segue popoverController];
            [self setTableViewControllerDataSourceTypes: popoverController];
            [popoverController setDelegate: self];
        }
    } else if ([[segue identifier] isEqualToString:@"showQueryDetails"]) {
        [[segue destinationViewController] setDelegate:self];
        
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            UIPopoverController *popoverController = [(UIStoryboardPopoverSegue *)segue popoverController];
            [self setTableViewControllerDataSourceTypes: popoverController];
            [popoverController setDelegate: self];
        }
    } else if ([[segue identifier] isEqualToString:@"showQueryBuilder"]) {
        
        [[segue destinationViewController] setDelegate:self];
        
        if ([self selectedDocument] < [[self availableFilesCache] count]) {
            
            NSURL *url = [[[self availableFilesCache] objectAtIndex: [self selectedDocument]] retain];
            UIManagedDocumentQuery *mdq = [[UIManagedDocumentQuery alloc] initWithFileURL:url];
            
            if ([[NSFileManager defaultManager] fileExistsAtPath:[url path]]) {
                [mdq openWithCompletionHandler:^(BOOL success) {
                    //if (success) {
                        [[segue destinationViewController] setManagedDocumentQuery: mdq];
                    //} else {
                    //    NSLog(@"Could not open document %@.", url);
                    //}
                }];
            }
            [mdq release];
            [url release];
        }
        
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            UIPopoverController *popoverController = [(UIStoryboardPopoverSegue *)segue popoverController];
            [self setTableViewControllerDataSourceTypes: popoverController];
            [popoverController setDelegate: self];
        }
    }
}

#pragma mark - Actions

- (IBAction)done:(id)sender {
    [[self delegate] flipsideViewControllerDidFinish: self];
}

#pragma mark - Delegates

- (void)uITableViewControllerDataSourceTypesDidFinish:(UITableViewControllerDataSourceTypes *)controller {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        [self dismissModalViewControllerAnimated: YES];
    } else {
        [[self tableViewControllerDataSourceTypes] dismissPopoverAnimated:YES];
        [self setTableViewControllerDataSourceTypes: nil];
    }
}

- (void)uIViewControllerSchemaTablesDelegateDidFinish:(UIViewControllerSchemaTables *)controller {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        [self dismissModalViewControllerAnimated: YES];
    } else {
        [[self tableViewControllerDataSourceTypes] dismissPopoverAnimated:YES];
        [self setTableViewControllerDataSourceTypes: nil];
    }
}

#pragma mark -
#pragma mark Table View Data Source Protocol

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

/*
 - (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
 
 }
 */

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
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

/*
 - (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
 
 }
 */

/*
 - (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
 
 }
 */

/*
 - (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
 NSString *result;
 switch (section) {
 case 0:
 result = @"";
 break;
 case 1:
 result = @"";
 break;
 default:
 result = @"";
 break;
 }
 return result;
 }
 */

//- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
//    return nil;
//}


#pragma mark -
#pragma mark Table View Delegate Protocol

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
	
}

- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath {
	
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self setSelectedDocument: [indexPath row]];
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

/*- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
 return 0.0000f;
 }*/

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [UITableViewCellDocument defaultHeight];
}

/*
 - (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath { }
 */

/*
 - (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section { }
 */

/*
 
 - (NSInteger)tableView:(UITableView *)tableView indentationLevelForRowAtIndexPath:(NSIndexPath *)indexPath {
 
 }
 */

/*
 - (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
 
 }
 */

/*
 - (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath {
 
 }
 */

/*
 - (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
 
 }
 */

/*
 - (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
 
 }
 */


/*
 - (void)tableView:(UITableView *)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath {
 
 }
 */

/*
 - (NSIndexPath *)tableView:(UITableView *)tableView willDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
 
 }
 */

/*
 - (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
 
 }
 */

/*
 - (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
 
 }
 */

@end