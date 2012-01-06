//
//  UITableViewControllerFontSelector.m
//  TheReportViewer
//
//  Created by Michael Thomason on 1/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "UITableViewControllerFontSelector.h"

@interface UITableViewControllerFontSelector()
- (void)shouldUpdateFont;
@end

@implementation UITableViewControllerFontSelector

@synthesize delegate;
@synthesize tableViewCellFontAmericanTypewriter;
@synthesize tableViewCellFontArial;
@synthesize tableViewCellFontCourierNew;
@synthesize tableViewCellFontCourier;
@synthesize tableViewCellFontGeorgia;
@synthesize tableViewCellFontHelvetica;
@synthesize tableViewCellFontHelveticaNeue;
@synthesize tableViewCellFontTimesNewRoman;
@synthesize tableViewCellFontTrebuchet;
@synthesize tableViewCellFontVerdana;
@synthesize tableViewCellFontZapfino;

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self shouldUpdateFont];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload {
    [self setTableViewCellFontAmericanTypewriter:nil];
    [self setTableViewCellFontArial:nil];
    [self setTableViewCellFontCourierNew:nil];
    [self setTableViewCellFontCourier:nil];
    [self setTableViewCellFontGeorgia:nil];
    [self setTableViewCellFontHelvetica:nil];
    [self setTableViewCellFontHelveticaNeue:nil];
    [self setTableViewCellFontTimesNewRoman:nil];
    [self setTableViewCellFontTrebuchet:nil];
    [self setTableViewCellFontVerdana:nil];
    [self setTableViewCellFontZapfino:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self shouldUpdateFont];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark -
#pragma Actions

- (void)shouldUpdateFont {
    for (NSInteger section = 0; section < [[self tableView] numberOfSections]; section++) {
        for (NSInteger row = 0; row < [[self tableView] numberOfRowsInSection:section]; row++) {
            UITableViewCell *cell = [[self tableView] cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:section]];
            if ([cell accessoryType] == UITableViewCellAccessoryCheckmark) {
                [[self delegate] uITableViewControllerDidUpdateFontToFontWithName:[[cell textLabel] text]];
                break;
            }
        }
    }
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    UITableViewCell *cell = [[[self tableView] cellForRowAtIndexPath:indexPath] retain];

    if ([cell accessoryType] != UITableViewCellAccessoryCheckmark) {
        [[self tableViewCellFontAmericanTypewriter] setAccessoryType:UITableViewCellAccessoryNone];
        [[self tableViewCellFontArial] setAccessoryType:UITableViewCellAccessoryNone];
        [[self tableViewCellFontCourierNew] setAccessoryType:UITableViewCellAccessoryNone];
        [[self tableViewCellFontCourier] setAccessoryType:UITableViewCellAccessoryNone];
        [[self tableViewCellFontGeorgia] setAccessoryType:UITableViewCellAccessoryNone];
        [[self tableViewCellFontHelvetica] setAccessoryType:UITableViewCellAccessoryNone];
        [[self tableViewCellFontHelveticaNeue] setAccessoryType:UITableViewCellAccessoryNone];
        [[self tableViewCellFontTimesNewRoman] setAccessoryType:UITableViewCellAccessoryNone];
        [[self tableViewCellFontTrebuchet] setAccessoryType:UITableViewCellAccessoryNone];
        [[self tableViewCellFontVerdana] setAccessoryType:UITableViewCellAccessoryNone];
        [[self tableViewCellFontZapfino] setAccessoryType:UITableViewCellAccessoryNone];
        
        //Check this box, or not (could test)
        [[[self tableView] cellForRowAtIndexPath:indexPath] setAccessoryType:UITableViewCellAccessoryCheckmark];
        [self shouldUpdateFont];
    }
    
    [[self tableView] deselectRowAtIndexPath:indexPath animated:YES];
    
    [cell release];
    
}

- (void)dealloc {
    [tableViewCellFontAmericanTypewriter release];
    [tableViewCellFontArial release];
    [tableViewCellFontCourierNew release];
    [tableViewCellFontCourier release];
    [tableViewCellFontGeorgia release];
    [tableViewCellFontHelvetica release];
    [tableViewCellFontHelveticaNeue release];
    [tableViewCellFontTimesNewRoman release];
    [tableViewCellFontTrebuchet release];
    [tableViewCellFontVerdana release];
    [tableViewCellFontZapfino release];
    [super dealloc];
}
@end
