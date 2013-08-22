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
    [_databaseType release];
    [_tableViewCellDocumentName release];
    [_tableViewCells release];
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
        [[self navigationItem] setPrompt: NSLocalizedString(@"Set connection settings.", @"Set connection settings.")];
    }
    [self setTitle: NSLocalizedString(@"Connection Settings", @"Connection Settings")];
    [self setClearsSelectionOnViewWillAppear: YES];
    
    UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
    [[self navigationItem] setLeftBarButtonItem:cancel];
    [[self navigationItem] setHidesBackButton:NO];
    [[self navigationItem] setBackBarButtonItem:cancel];
    [[self navigationItem] setLeftItemsSupplementBackButton: YES];
    
    [cancel release];

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

- (void)cancel:(id)sender {
    //if ([UIDevice isPad]) {
        [[self delegate] viewControllerDidCancel:self];
    //}
}

- (IBAction)save:(id)sender {
    
    [sender setEnabled:NO];
    [[[self navigationItem] backBarButtonItem] setEnabled:NO];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:[AppDelegate storyboardName] bundle:nil];
    UIViewController *activitySpinnerViewController = [storyboard instantiateViewControllerWithIdentifier: MUIViewControllerActivitySpinner];
    [[activitySpinnerViewController view] setFrame:[[self tableView] frame]];
    [[activitySpinnerViewController view] setCenter:[[self tableView] center]];
    [[self view] addSubview: [activitySpinnerViewController view]];
    
    NSURL *applicationFileUrlWithExtention = [NSURL uniqueUrlForDocumentWithName:[[self textFieldReportName] text]
                                                                   withExtension:MTDocumentExtentionMobleApplicationDocumentArchive];
    
    //dispatch_queue_t queuePriorityBackground = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    
    //dispatch_async(queuePriorityBackground, ^{

    [UIManagedDocument openManagedDocumentAtUrl:applicationFileUrlWithExtention
                                    withWrapper:[MAReportDocument class]
                           andCompletionHandler:^(id managedDocument, BOOL success) {
        if (success) {
            __block MAReportDocument *documentReport = managedDocument;
            
            MTDatabaseConnection *databaseConnection = [[MTDatabaseConnection alloc] init];
            [databaseConnection setUsername:    [[self textFieldUsername] text]];
            [databaseConnection setPassword:    [[self textFieldPassword] text]];
            [databaseConnection setServer:      [[self textFieldHost] text]];
            [databaseConnection setDatabase:    [[self textFieldDatabase] text]];
            [databaseConnection setPort:        [[[self textFieldPort] text] integerValue]];
            
            id database = nil;
            if ([[self databaseType] isEqualToString:MTSegueShowSetUpDatasourceMySqlIdentifier]) {
                database = [[MTDatabaseMySql alloc] initWithConnectionSettings:databaseConnection];
            } else if ([[self databaseType] isEqualToString:MTSegueShowSetUpDatasourceSqlServerIdentifier]) {
                database = [[MTDatabaseSqlServer alloc] initWithConnectionSettings:databaseConnection];
            }
            
            if (database) {
                dispatch_async(dispatch_get_main_queue(), ^{

                [documentReport addDatasourceToReport: database completion: ^(BOOL success2, NSError *error) {
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        if (success2) {
                            [[activitySpinnerViewController view] removeFromSuperview];
                            [sender setEnabled:YES];
                            [[[self navigationItem] backBarButtonItem] setEnabled:YES];
                            [[self delegate] viewControllerDidFinish: self];
                        } else {
                            
                            [documentReport deleteFromDiskCompletion:nil];
                            
                            if (error) {
                                
                                [error presentErrorToUserWithCompletion:^(BOOL success) {
                                    
                                    [[activitySpinnerViewController view] removeFromSuperview];
                                    [sender setEnabled:YES];
                                    [[[self navigationItem] backBarButtonItem] setEnabled:YES];
                                    
                                }];
                                
                            } else {
                                
                                MTAlertView *alertView = [[MTAlertView alloc] initWithTitle: NSLocalizedString(@"Connection Problem", @"Connection Problem")
                                                                                    message: NSLocalizedString(@"Could not connect to database.", @"Could not connect to database.")
                                                                          cancelButtonTitle: NSLocalizedString(@"Cancel", @"Cancel") otherButtonTitle:nil onDismiss:^(NSInteger buttonIndex) {
                                                                              
                                                                              [[activitySpinnerViewController view] removeFromSuperview];
                                                                              [sender setEnabled:YES];
                                                                              [[[self navigationItem] backBarButtonItem] setEnabled:YES];
                                                                              
                                                                          } onCancel:^{
                                                                              
                                                                              [[activitySpinnerViewController view] removeFromSuperview];
                                                                              [sender setEnabled:YES];
                                                                              [[[self navigationItem] backBarButtonItem] setEnabled:YES];
                                                                              
                                                                          }];
                                [alertView show];
                                [alertView autorelease];
                                
                            }
                            
                        }
                    });
                    
                }];
                });
            }
            
            [database release];
            [databaseConnection release];

        } else {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                MTAlertView *alertView = [[MTAlertView alloc] initWithTitle: NSLocalizedString(MNSInterfaceTitleProblem, MNSInterfaceTitleProblem)
                                                                    message: NSLocalizedString(MNSInterfaceMessageErrorFailedToCreateReport, MNSInterfaceMessageErrorFailedToCreateReport)
                                                          cancelButtonTitle: NSLocalizedString(MNSInterfaceButtonDismiss, MNSInterfaceButtonDismiss)
                                                           otherButtonTitle: nil onDismiss:^(NSInteger buttonIndex) {
                                                               
                                                           } onCancel:^{
                                                               
                                                           }];
                [alertView show];
                [alertView autorelease];
            });
        }
    }];
    //});

    
    
    
    /*
    
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
                    [sender setEnabled:YES];
                    [[[self navigationItem] backBarButtonItem] setEnabled:YES];
                    [[self delegate] viewControllerDidFinish: self];
                } else {
                    
                    [documentReport deleteFromDiskCompletion:nil];
                    
                    if (error) {

                        [error presentErrorToUserWithCompletion:^(BOOL success) {
                            
                            [[vc view] removeFromSuperview];
                            [sender setEnabled:YES];
                            [[[self navigationItem] backBarButtonItem] setEnabled:YES];
                            
                        }];

                    } else {

                        MTAlertView *alertView = [[MTAlertView alloc] initWithTitle: NSLocalizedString(@"Connection Problem", @"Connection Problem")
                                                                            message: NSLocalizedString(@"Could not connect to database.", @"Could not connect to database.")
                                                                  cancelButtonTitle: NSLocalizedString(@"Cancel", @"Cancel") otherButtonTitle:nil onDismiss:^(NSInteger buttonIndex) {
                                                                  
                                                                      [[vc view] removeFromSuperview];
                                                                      [sender setEnabled:YES];
                                                                      [[[self navigationItem] backBarButtonItem] setEnabled:YES];

                                                                  } onCancel:^{
                                                                  
                                                                      [[vc view] removeFromSuperview];
                                                                      [sender setEnabled:YES];
                                                                      [[[self navigationItem] backBarButtonItem] setEnabled:YES];

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
    */
}

- (IBAction)done:(id)sender {
    [[self delegate] viewControllerDidFinish: self];
}
- (IBAction)documentNameDidEndOnExit:(id)sender { }
- (IBAction)schemaDidEndOnExit:(id)sender { }
- (IBAction)usernameDidEndOnExit:(id)sender { }
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

- (void)viewDidUnload {
    [self setTableViewCellDocumentName:nil];
    [self setTableViewCells:nil];
    [super viewDidUnload];
}
@end