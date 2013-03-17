//
//  UITableViewControllerDataSourceSetupMySql.m
//  Reports
//
//  Created by Michael Thomason on 1/13/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MTDatabaseDriverSelectorMySqlViewController.h"

@interface MTDatabaseDriverSelectorMySqlViewController()

@end

@implementation MTDatabaseDriverSelectorMySqlViewController

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

    if ([UIDevice isPad] == NO) {
        [[self navigationItem] setPrompt: NSLocalizedString(@"Set inital settings.", @"Set inital settings.")];
    }
    [self setTitle: NSLocalizedString(@"Inital Settings", @"Inital Settings")];
    [self setClearsSelectionOnViewWillAppear: YES];
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

    __block MTReportDocument *documentReport = [[MTReportDocument alloc] initNewFileWithName: [[self textFieldReportName] text] completion: ^(BOOL success) {
        
        if (success) {
            
            MTDatabaseConnection *databaseConnection = [[MTDatabaseConnection alloc] init];
            [databaseConnection setUsername:    [[self textFieldUsername] text]];
            [databaseConnection setPassword:    [[self textFieldPassword] text]];
            [databaseConnection setServer:      [[self textFieldHost] text]];
            [databaseConnection setDatabase:    [[self textFieldDatabase] text]];
            [databaseConnection setPort:        [[[self textFieldPort] text] integerValue]];
            
            MTDatabaseMySql *databaseMySql = [[MTDatabaseMySql alloc] initWithConnectionSettings:databaseConnection];

            [documentReport addDatasourceToReport: databaseMySql completion: ^(BOOL success, NSError *error) {

                if (success) {
                    [[vc view] removeFromSuperview];
                    [[self delegate] viewControllerDidFinish: self];
                } else {
                    
                    [documentReport deleteFromDiskCompletion:nil];
                    
                    if (error) {

                        [error presentErrorToUserWithCompletion:^(BOOL success) {
                            
                            [[vc view] removeFromSuperview];
                            
                        }];

                    } else {

                        MTAlertView *alertView = [[MTAlertView alloc] initWithTitle: NSLocalizedString(@"Connection Problem", @"Connection Problem")
                                                                            message: NSLocalizedString(@"Could not connect to database.", @"Could not connect to database.")
                                                                  cancelButtonTitle: NSLocalizedString(@"Cancel", @"Cancel") otherButtonTitle:nil onDismiss:^(NSInteger buttonIndex) {
                                                                  
                                                                      [[vc view] removeFromSuperview];

                                                                  } onCancel:^{
                                                                  
                                                                      [[vc view] removeFromSuperview];

                                                                  }];
                        [alertView show];
                        [alertView autorelease];
                        
                    }
                }

            }];
            
            [databaseMySql release];
            [databaseConnection release];
            
        } else {

            MTAlertView *alertView = [[MTAlertView alloc] initWithTitle: NSLocalizedString(MNSInterfaceTitleProblem, MNSInterfaceTitleProblem)
                                                                message: NSLocalizedString(MNSInterfaceMessageErrorFailedToCreateReport, MNSInterfaceMessageErrorFailedToCreateReport)
                                                      cancelButtonTitle: NSLocalizedString(MNSInterfaceButtonDismiss, MNSInterfaceButtonDismiss)
                                                       otherButtonTitle: nil onDismiss:^(NSInteger buttonIndex) {

                                                       } onCancel:^{

                                                       }];
            [alertView show];
            [alertView autorelease];


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

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath: indexPath animated: YES];
}

@end