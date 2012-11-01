//
//  UITableViewControllerDataSourceSetupSalesforce.m
//  TheReportViewer
//
//  Created by Michael Thomason on 1/13/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "UITableViewControllerDataSourceSetupSalesforce.h"

@interface UITableViewControllerDataSourceSetupSalesforce() {
@private
    NSMutableString *inputNickname;
    
    //rsltBlk_loginComplete blockCompleteLogin;
    rsltBlk_tblNames blockCompleteTable;
    
    NSDatabaseSalesForce *db;

}

@property (retain) NSMutableString *inputNickname;
@property (retain) NSDatabaseSalesForce *db;

@end

@implementation UITableViewControllerDataSourceSetupSalesforce

@synthesize delegate;
@synthesize tableViewCellNickname;
@synthesize tableViewCellConnectionCreate;
@synthesize saveButton;
@synthesize activityIndicatorTestConnection;
@synthesize textFieldNickname;
@synthesize db;

@synthesize inputNickname;


typedef void (^loginComplete)(NSDatabaseSalesForce *database, BOOL complete);
typedef void (^tablesComplete)(NSDatabaseSalesForce *database, NSArray *tables);

/*
tablesComplete tablesCompleteBlock = ^(NSDatabaseSalesForce *database, NSArray *tables) {
    NSLog(@"results: %@", tables);
    [database logout];
    [database release];
    database = nil;
    NSLog(@"Credentals released");
};

loginComplete loginCompleteBlock = ^(NSDatabaseSalesForce *database, BOOL complete) {
    if (complete) {
        NSLog(@"Login good");
        [database tablesInDataseAsyc:nil completion: tablesCompleteBlock];
    }
};

loginComplete loginCompleteBlock = ^(NSDatabaseSalesForce *database, BOOL complete) {
    if (complete) {
        NSLog(@"Login good");
        [database tablesInDataseAsyc:nil completion: tablesCompleteBlock];
    }
};

loginComplete loginCompleteBlock = ^(NSDatabaseSalesForce *database, BOOL complete) {
    if (complete) {
        NSLog(@"Login good");
        [database tablesInDataseAsyc:nil completion: tablesCompleteBlock];
    }
};
*/

- (void)dealloc {

    if (db != nil) {
        [db logout];
        [db release];
        db = nil;
    }
    
    [inputNickname release];
    [activityIndicatorTestConnection release];
    [textFieldNickname release];
    [saveButton release];
    [super dealloc];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Custom initialization
        NSMutableString *blank = [[NSMutableString alloc] initWithString:@""];
        [self setInputNickname: blank];
        [blank release];
    }
    return self;
}

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        NSMutableString *blank = [[NSMutableString alloc] initWithString:@""];
        [self setInputNickname: blank];
        [blank release];
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

    [[self navigationItem] setPrompt: NSLocalizedString(@"Set inital settings.", @"Set inital settings.")];
    [self setTitle: NSLocalizedString(@"New Report", @"New Report")];

    [[self textFieldNickname] selectAll: self];

    // Uncomment the following line to preserve selection between presentations.
    self.clearsSelectionOnViewWillAppear = YES;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[self textFieldNickname] becomeFirstResponder];
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

- (const char *)cStringFromString:(NSString *)theString {       
    NSMutableData *theData;
    NSLog(@"theString, %@", theString);
    if (! theString) {
        return (const char *)NULL;
    }
    
    theData = [NSMutableData dataWithData:[theString dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
    [theData increaseLengthBy:1];
    return (const char *)[theData bytes];
}

//Create new file using core data with
// the table names and fields inside it.
// This will be used as the program
// schema.
- (void)test:(id)sender {
        if ([[[self textFieldNickname] text] length] > 0) {
            NSDatabaseSalesForce *d = [[NSDatabaseSalesForce alloc] initNewFileWithName: [[self textFieldNickname] text] completion: ^(BOOL success) {

            }];
            [d setDelegate: self];
            [self setDb:d];
            [d release];

        }
}

- (IBAction)save:(id)sender {
    //Create UIManaged Document that Stores the Database Schema
    if ([[[self textFieldNickname] text] length] > 0) {
        [[self saveButton] setEnabled: NO];
        NSDatabaseSalesForce *d = [[NSDatabaseSalesForce alloc] initNewFileWithName: [[self textFieldNickname] text] completion: ^(BOOL success) {
            if (success) {
                [[[self navigationController] presentingViewController] dismissModalViewControllerAnimated: YES];
            } else {
                [[self saveButton] setEnabled: YES];
            }
        }];
        [d setDelegate: self];
        [self setDb:d];
        [d release];
        
    } else {
        [UIView animateWithDuration:ANIMATION_DURATION_FAST animations:^{
            [[[self tableViewCellNickname] contentView] setBackgroundColor:[UIColor edaOrange]];
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:ANIMATION_DURATION_FAST animations:^{
                [[[self tableViewCellNickname] contentView] setBackgroundColor:[UIColor clearColor]];
            } completion:^(BOOL finished) {

            }];
        }];
    }
}

- (IBAction)done:(id)sender {
    [[self delegate] uITableViewControllerDataSourceSetupSalesforceDidFinish: self];
}

- (IBAction)nicknameDidEndOnExit:(id)sender {
    [sender resignFirstResponder];
    [self save: sender];
}

#pragma mark - MNSDatabaseSalesForce Delegate

- (void)showWebView:(UIWebView *)view {
    [[self view] addSubview: view];
}

#pragma mark - Table View Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath: indexPath animated: YES];
    
    if ([[tableView cellForRowAtIndexPath: indexPath] isEqual: [self tableViewCellConnectionCreate]]) {
        NSLog(@"Test connection!!!");
        [self test:nil];
        NSLog(@"Did finish test connection");
    }
    
}

@end