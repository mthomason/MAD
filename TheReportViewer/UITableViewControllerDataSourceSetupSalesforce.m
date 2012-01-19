//
//  UITableViewControllerDataSourceSetupSalesforce.m
//  TheReportViewer
//
//  Created by Michael Thomason on 1/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "UITableViewControllerDataSourceSetupSalesforce.h"
#import "NSDatabaseSalesForce.h"
#import "Constants.h"

@interface UITableViewControllerDataSourceSetupSalesforce() {
@private
    NSMutableString *inputNickname;
    
    rsltBlk_loginComplete blockCompleteLogin;
    rsltBlk_tblNames blockCompleteTable;
    
    __block NSDatabaseSalesForce *db;

}

@property (retain) NSMutableString *inputNickname;
@property (retain) __block NSDatabaseSalesForce *db;

@end

@implementation UITableViewControllerDataSourceSetupSalesforce

@synthesize delegate;
@synthesize tableViewCellNickname;
@synthesize tableViewCellConnectionCreate;
@synthesize activityIndicatorTestConnection;
@synthesize textFieldNickname;
@synthesize db;

@synthesize inputNickname;


typedef void (^loginComplete)(NSDatabaseSalesForce *database, BOOL complete);
typedef void (^tablesComplete)(NSDatabaseSalesForce *database, NSArray *tables);

tablesComplete tablesCompleteBlock = ^(NSDatabaseSalesForce *database, NSArray *tables) {
    NSLog(@"results: %@", tables);
    //[[self db] logout];
    //[[self db] release];
    //db = nil;
    NSLog(@"Credentals released");
};

loginComplete loginCompleteBlock = ^(NSDatabaseSalesForce *database, BOOL complete) {
    if (complete) {
        NSLog(@"Login good");
        [database tablesInDataseAsyc:nil completion: tablesCompleteBlock];
    } else {
        NSLog(@"Block not complete");
    }
};

- (void)dealloc {

    if (db != nil) {
        [db logout];
        [db release];
        db = nil;
    }
    [db release];
    [inputNickname release];
    [activityIndicatorTestConnection release];
    [textFieldNickname release];
    [super dealloc];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Custom initialization
        __block NSDatabaseSalesForce *d = [[NSDatabaseSalesForce alloc] init];
        [self setDb:d];
        [d release];
        
        /*
        blockCompleteTable = ^(NSArray *tables) {
            NSLog(@"results: %@", tables);
            [db logout];
            [db release];
            db = nil;
            NSLog(@"Credentals released");
        };
        
        blockCompleteLogin = ^(BOOL complete) {
            if (complete) {
                [db tablesInDataseAsyc:nil completion:blockCompleteTable];
            } else {
                NSLog(@"Block not complete");
            }
        };
        */
        
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
        __block NSDatabaseSalesForce *d = [[NSDatabaseSalesForce alloc] init];
        [self setDb:d];
        [d release];
        
        /*
         blockCompleteTable = ^(NSArray *tables) {
         NSLog(@"results: %@", tables);
         [db logout];
         [db release];
         db = nil;
         NSLog(@"Credentals released");
         };
         
         blockCompleteLogin = ^(BOOL complete) {
         if (complete) {
         [db tablesInDataseAsyc:nil completion:blockCompleteTable];
         } else {
         NSLog(@"Block not complete");
         }
         };
         */
        

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

    // Uncomment the following line to preserve selection between presentations.
    self.clearsSelectionOnViewWillAppear = YES;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload {
    [self setTableViewCellNickname:nil];
    [self setTableViewCellConnectionCreate:nil];
    [self setActivityIndicatorTestConnection:nil];
    [self setTextFieldNickname:nil];
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

- (void)test:(id)sender {
    NSLog(@"Database released");
    //Create salesforce.com database.
    
    [[self db] login: loginCompleteBlock];

}

- (IBAction)save:(id)sender {
    //Create UIManaged Document that Stores the Database Schema
    
}

- (IBAction)done:(id)sender {
    [[self delegate] uITableViewControllerDataSourceSetupSalesforceDidFinish: self];
}

- (IBAction)nicknameDidEndOnExit:(id)sender {
    [sender resignFirstResponder];
}

#pragma mark - MNSDatabaseSalesForce Delegate

- (void)showWebView:(UIWebView *)view {
    [[self view] addSubview: view];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath: indexPath animated: YES];
    
    if ([[tableView cellForRowAtIndexPath: indexPath] isEqual: [self tableViewCellConnectionCreate]]) {
        NSLog(@"Test connection!!!");
        [self test:nil];
        NSLog(@"Did finish test connection");
    }
    
}

@end