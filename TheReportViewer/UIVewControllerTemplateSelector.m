//
//  UIVIewControllerTemplateSelector.m
//  TheReportViewer
//
//  Created by Michael Thomason on 1/7/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "UIViewControllerTemplateSelector.h"
#import "NSFileManager+Common.h"
#import "UITableViewCellDocument.h"
#import "UITableViewControllerDataSourceTypes.h"
#import "Constants.h"

@interface UIViewControllerTemplateSelector()

@property (retain) NSMutableArray *availableFilesCache;

@end

@implementation UIViewControllerTemplateSelector

@synthesize delegate;
@synthesize tableViewTemplates;
@synthesize uITableViewCellDocument;
@synthesize availableFilesCache = _availableFilesCache;

- (void)dealloc {
    [_availableFilesCache release];
    [tableViewTemplates release];
    [super dealloc];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [[UINavigationBar appearance] setTintColor:[UIColor clearColor]];
        self.title = NSLocalizedString(@"Templates", @"Templates");
    }
    return self;    
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [[UINavigationBar appearance] setTintColor:[UIColor clearColor]];
        self.title = NSLocalizedString(@"Templates", @"Templates");
    }
    return self;
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UINavigationBar appearance] setTintColor:[UIColor clearColor]];

    [self setAvailableFilesCache: [NSFileManager contentsOfTemplateDirectoryWithPathExtension:TEMPLATE_PATH_EXTENSION]];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[self navigationItem] setPrompt: NSLocalizedString(@"Choose A Template", @"Choose A Template")];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}


- (void)viewDidUnload {
    [self setAvailableFilesCache:nil];
    [self setTableViewTemplates:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Actions

- (IBAction)done:(id)sender {
    [[self delegate] uIViewControllerTemplateSelectorDidFinish: self];
}

- (IBAction)cancel:(id)sender {
    [[self delegate] uIViewControllerTemplateSelectorDidCancel: self];
}

#pragma mark - Table View Controller Data Source Delegate

- (void)uITableViewControllerDataSourceTypesDidFinish:(UITableViewControllerDataSourceTypes *)controller {
    [[self delegate] uIViewControllerTemplateSelectorDidCancel: self];
}

#pragma mark - Table View Data Source Protocol

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
    static NSString *MyIdentifier = @"UITableViewCellDocument";
    UITableViewCellDocument *result = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
    if (!result) {
        UINib *resultCellNib = [UINib nibWithNibName:@"UITableViewCellDocument" bundle:nil];
        [resultCellNib instantiateWithOwner:self options:nil];
        result = [self uITableViewCellDocument];
        [self setUITableViewCellDocument:nil];
    }
    
    [[result labelH1] setText:NSLocalizedString(@"Blank", @"The name of a blank template document.")];    
    [[result labelH2] setText:NSLocalizedString(@"A blank report template.", @"A subheading.")];

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
            numberOfRows = 1;
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
            result = NSLocalizedString(@"Choose a Template", @"Choose a Template");
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

/*
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return nil;
}
*/

#pragma mark -
#pragma mark Table View Delegate Protocol

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    NSUInteger row = [indexPath row];
    if (row < [[self availableFilesCache] count]) {
        [delegate uIViewControllerTemplateSelectorRequestOpenOfTemplateAtUrl: [[self availableFilesCache] objectAtIndex: row]];
    }
    
}

/*- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
	
}

- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath {
	
}*/

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