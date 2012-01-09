//
//  UITableViewControllerSettings.m
//  TheReportViewer
//
//  Created by Michael Thomason on 1/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "UITableViewControllerSettings.h"


@implementation UITableViewControllerSettings

@synthesize delegate;
@synthesize tableCellPrint;
@synthesize tableCellExport;
@synthesize tableCellFind;
@synthesize tableCellSettings;
@synthesize tableCellHelp;
@synthesize tableCellStore;
@synthesize tableCellReportSetup;
@synthesize tableCellRuler;

- (void)dealloc {
    [tableCellPrint release];
    [tableCellExport release];
    [tableCellFind release];
    [tableCellReportSetup release];
    [tableCellRuler release];
    [tableCellFind release];
    [tableCellSettings release];
    [tableCellHelp release];
    [tableCellStore release];
    [super dealloc];
}

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

    self.clearsSelectionOnViewWillAppear = YES;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
}

- (void)viewDidUnload {
    [self setTableCellPrint:nil];
    [self setTableCellExport:nil];
    [self setTableCellFind:nil];
    [self setTableCellReportSetup:nil];
    [self setTableCellRuler:nil];
    [self setTableCellFind:nil];
    [self setTableCellSettings:nil];
    [self setTableCellHelp:nil];
    [self setTableCellStore:nil];
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
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Actions

- (IBAction)done:(id)sender {
    [self.delegate uIViewControllerSettingsDidFinish:self];
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    //[[self tableView] deselectRowAtIndexPath:indexPath animated:YES];

    //UITableViewCell *cell = [[[self tableView] cellForRowAtIndexPath:indexPath] retain];
    
    //[cell release];
    
}

@end