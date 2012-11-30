//
//  UITableViewControllerDataSourceSetupMySql.m
//  TheReportViewer
//
//  Created by Michael Thomason on 1/13/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MUITableViewControllerDatabaseMySqlSetup.h"

@interface MUITableViewControllerDatabaseMySqlSetup()

@end

@implementation MUITableViewControllerDatabaseMySqlSetup

- (void)dealloc {
    [_tableViewCellUsername release];
    [_tableViewCellPassword release];
    [_tableViewCellHost release];
    [_tableViewCellPort release];
    [_tableViewCellTestConnection release];
    [_activityIndicatorTestConnection release];
    [_textFieldUsername release];
    [_textFieldPassword release];
    [_textFieldHost release];
    [_textFieldPort release];
    [_tableViewCellDatabase release];
    [_textFieldDatabase release];
    [_textFieldReportName release];
    [super dealloc];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Custom initialization
    }
    return self;
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

    [[self navigationItem] setPrompt: NSLocalizedString(@"Set inital settings.", @"Set inital settings.")];
    [self setTitle: NSLocalizedString(@"New Report", @"New Report")];
    
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
#warning Commenting this shit out
    
    
    MNSDocumentReport *documentReport = [[MNSDocumentReport alloc] initFileWithName: [[self textFieldReportName] text] completion: ^(BOOL success) {
        if (success) {
            NSLog(@"That's a bingo!");
            MNSDatabaseConnection *databaseConnection = [[MNSDatabaseConnection alloc] init];
            [databaseConnection setUsername:    [[self textFieldUsername] text]];
            [databaseConnection setPassword:    [[self textFieldPassword] text]];
            [databaseConnection setServer:      [[self textFieldHost] text]];
            [databaseConnection setDatabase:    [[self textFieldDatabase] text]];
            [databaseConnection setPort:        [[[self textFieldPort] text] integerValue]];
            
            MNSDatabaseMySql *databaseMySql = [[MNSDatabaseMySql alloc] initWithConnectionSettings:databaseConnection completion:^(BOOL success) {
                if (success) {
                    [documentReport addDatasourceToReport: databaseMySql completion: ^(BOOL success) {
                        
                    }];
                }
            }];
            
            [databaseConnection release];

        }
    }];

}

- (IBAction)save:(id)sender {
    /*
    //Create UIManaged Document that Stores the Database Schema
#warning What is this trash!?!
    //Create UIManaged Document that Stores the Database Schema
    if ([[[self textFieldNickname] text] length] > 0) {
        [[self saveButton] setEnabled: NO];
        NSDatabaseMySql *d = [[NSDatabaseSalesForce alloc] initNewFileWithName: [[self textFieldNickname] text] completion: ^(BOOL success) {
            success ?
            [[[self navigationController] presentingViewController] dismissModalViewControllerAnimated: YES] :
            [[self saveButton] setEnabled: YES];
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
    }    [[[self navigationController] presentingViewController] dismissModalViewControllerAnimated: YES];
     */
}

- (IBAction)done:(id)sender {
    [[self delegate] viewControllerDidFinish: self];
}

- (IBAction)usernameDidEndOnExit:(id)sender {
/*    if ([sender isKindOfClass: [UITextField class]]) {
        [self setInputUsername:[(UITextField *)sender text]];
    }
    if ([[self textFieldPassword] canBecomeFirstResponder]) {
        [[self textFieldPassword] becomeFirstResponder];
    }*/
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
        [self test:nil];
        NSLog(@"Did finish test connection");
    }
}

- (void)viewDidUnload {
    [self setTableViewCellDatabase:nil];
    [self setTextFieldDatabase:nil];
    [self setTextFieldReportName:nil];
    [super viewDidUnload];
}
@end