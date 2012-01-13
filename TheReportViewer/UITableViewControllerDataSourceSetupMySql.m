//
//  UITableViewControllerDataSourceSetupMySql.m
//  TheReportViewer
//
//  Created by Michael Thomason on 1/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "UITableViewControllerDataSourceSetupMySql.h"

@implementation UITableViewControllerDataSourceSetupMySql

@synthesize delegate;
@synthesize tableViewCellUsername;
@synthesize tableViewCellPassword;
@synthesize tableViewCellHost;
@synthesize tableViewCellPort;
@synthesize tableViewCellTestConnection;
@synthesize activityIndicatorTestConnection;
@synthesize textFieldUsername;
@synthesize textFieldPassword;
@synthesize textFieldHost;
@synthesize textFieldPort;

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

    // Uncomment the following line to preserve selection between presentations.
    self.clearsSelectionOnViewWillAppear = YES;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload {
    [self setTableViewCellUsername:nil];
    [self setTableViewCellPassword:nil];
    [self setTableViewCellHost:nil];
    [self setTableViewCellPort:nil];
    [self setTableViewCellTestConnection:nil];
    [self setActivityIndicatorTestConnection:nil];
    [self setTextFieldUsername:nil];
    [self setTextFieldPassword:nil];
    [self setTextFieldHost:nil];
    [self setTextFieldPort:nil];
    [super viewDidUnload];
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
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Actions

- (IBAction)done:(id)sender {
    [[self delegate] uITableViewControllerDataSourceSetupMySqlDidFinish: self];
}

- (IBAction)save:(id)sender {
    //Create UIManaged Document that Stores the Database Schema
    
}

- (IBAction)usernameDidEndOnExit:(id)sender {
    if ([[self textFieldPassword] canBecomeFirstResponder]) {
        [[self textFieldPassword] becomeFirstResponder];
    }
}

- (IBAction)passwordDidEndOnExit:(id)sender {
    if ([[self textFieldHost] canBecomeFirstResponder]) {
        [[self textFieldHost] becomeFirstResponder];
    }
}

- (IBAction)hostDidEndOnExit:(id)sender {
    if ([[self textFieldPort] canBecomeFirstResponder]) {
        [[self textFieldPort] becomeFirstResponder];
    }
}

- (IBAction)portDidEndOnExit:(id)sender {
    [[self textFieldPort] resignFirstResponder];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath: indexPath animated: YES];
    
    if ([[tableView cellForRowAtIndexPath: indexPath] isEqual: [self tableViewCellTestConnection]]) {
        NSLog(@"Test connection!!!");
    }
    
}

- (void)dealloc {
    [tableViewCellUsername release];
    [tableViewCellPassword release];
    [tableViewCellHost release];
    [tableViewCellPort release];
    [tableViewCellTestConnection release];
    [activityIndicatorTestConnection release];
    [textFieldUsername release];
    [textFieldPassword release];
    [textFieldHost release];
    [textFieldPort release];
    [super dealloc];
}
@end