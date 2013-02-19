//
//  UITableViewControllerDataSourceSetupMySql.m
//  Reports
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

#pragma mark - Actions

- (IBAction)save:(id)sender {
    
    UIStoryboard *sb = [UIStoryboard storyboardWithName:[AppDelegate storyboardName] bundle:nil];
    UIViewController *vc = [sb instantiateViewControllerWithIdentifier: MUIViewControllerActivitySpinner];
    [[vc view] setBounds:[[self view] bounds]];
    [[vc view] setCenter:[[self view] center]];
    [[self view] addSubview: [vc view]];

    __block MNSDocumentReport *documentReport = [[MNSDocumentReport alloc] initNewFileWithName: [[self textFieldReportName] text] completion: ^(BOOL success) {
        
        if (success) {
            
            MNSDatabaseConnection *databaseConnection = [[MNSDatabaseConnection alloc] init];
            [databaseConnection setUsername:    [[self textFieldUsername] text]];
            [databaseConnection setPassword:    [[self textFieldPassword] text]];
            [databaseConnection setServer:      [[self textFieldHost] text]];
            [databaseConnection setDatabase:    [[self textFieldDatabase] text]];
            [databaseConnection setPort:        [[[self textFieldPort] text] integerValue]];
            
            MNSDatabaseMySql *databaseMySql = [[MNSDatabaseMySql alloc] initWithConnectionSettings:databaseConnection];
            [documentReport addDatasourceToReport: databaseMySql completion: ^(BOOL success) {
                if (success) {
                    NSLog(@"Delegate %@", self.delegate);
                    [[vc view] removeFromSuperview];
                    [[self delegate] viewControllerDidFinish: self];
                }
            }];
            
            [databaseMySql release];
            [databaseConnection release];
            
        } else {

            [UIAlertView showAlertViewWithTitle: NSLocalizedString(MNSInterfaceTitleProblem, MNSInterfaceTitleProblem)
                                        message: NSLocalizedString(MNSInterfaceMessageErrorFailedToCreateReport, MNSInterfaceMessageErrorFailedToCreateReport)
                              cancelButtonTitle: NSLocalizedString(MNSInterfaceButtonDismiss, MNSInterfaceButtonDismiss)
                               otherButtonTitle: nil
                                      onDismiss: ^(int buttonIndex) { }
                                       onCancel: ^{ }];

        }
        
    }];
    
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
}

@end