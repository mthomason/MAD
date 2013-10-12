//
//  UITableViewControllerDataSourceSetupMySql.m
//  Reports
//
//  Created by Michael Thomason on 1/13/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "MTDatabaseDriverSelectorMySqlViewController.h"
#import "MTViewControllerActivitySpinner.h"

@interface MTDatabaseDriverSelectorMySqlViewController()

@property (nonatomic, assign) BOOL activitySpinnerVisable;
@property (nonatomic, retain) MTViewControllerActivitySpinner *activitySpinnerViewController;
@property (nonatomic, retain) UIBarButtonItem *holderButton;

@end

@implementation MTDatabaseDriverSelectorMySqlViewController

- (void)dealloc {
    [_holderButton release];
    [_activitySpinnerViewController release];
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
    [self setActivitySpinnerVisable:NO];
    if ([UIDevice isPad] == NO) {
        [[self navigationItem] setPrompt: NSLocalizedString(@"Set connection settings.", @"Set connection settings.")];
    }
    [self setTitle: NSLocalizedString(@"Connection Settings", @"Connection Settings")];
    [self setClearsSelectionOnViewWillAppear: YES];
    
    [[self navigationItem] setHidesBackButton:NO];
    [[self navigationItem] setLeftItemsSupplementBackButton: YES];
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

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    
    
    UIViewController *viewControllerFrom = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *viewControllerTo = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    //CGRect rectStart = [transitionContext initialFrameForViewController:viewControllerFrom];
    
    
    [[transitionContext containerView] setBackgroundColor:[UIColor clearColor]];
    [[transitionContext containerView] setOpaque:NO];
    
    [[viewControllerTo view] setBounds:[[viewControllerFrom view] bounds]];
    [[viewControllerTo view] setBackgroundColor:[UIColor clearColor]];
    
    //[[viewControllerFrom view] addSubview:[viewControllerTo view]];
    [[transitionContext containerView] addSubview:[viewControllerTo view]];
    [[viewControllerTo view] setBounds:[[transitionContext containerView] bounds]];
    [[viewControllerTo view] setCenter:[[transitionContext containerView] center]];
    [[viewControllerTo view] setAlpha:0.0000f];
    [UIView animateWithDuration:0.4000f animations:^{
        [[viewControllerTo view] setAlpha:1.0000f];
        [[transitionContext containerView] addSubview:[viewControllerTo view]];
    } completion:^(BOOL finished) {
        [transitionContext completeTransition:![transitionContext transitionWasCancelled]]; // :))
    }];
    
}

- (void)animationEnded:(BOOL)transitionCompleted {
    if (transitionCompleted) {
        
    }
}

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    return 0.4000f;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    return [self activitySpinnerViewController];
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
    return self;
}

- (id<UIViewControllerInteractiveTransitioning>)interactionControllerForDismissal:(id<UIViewControllerAnimatedTransitioning>)animator {
    return nil;
}

- (id<UIViewControllerInteractiveTransitioning>)interactionControllerForPresentation:(id<UIViewControllerAnimatedTransitioning>)animator {
    return nil;
}

- (IBAction)save:(id)sender {
    
    [sender setEnabled:NO];
    [[[self navigationItem] backBarButtonItem] setEnabled:NO];
    
    [self setHolderButton: [[self navigationItem] rightBarButtonItem]];
    
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [activityIndicator setColor:[UIColor blackColor]];
    [activityIndicator startAnimating];
    [activityIndicator setHidden:NO];
    [activityIndicator setHidesWhenStopped:NO];
    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithCustomView:activityIndicator];
    [[self navigationItem] setRightBarButtonItem:barButtonItem animated:YES];
    [barButtonItem release];
    [activityIndicator release];
    
    __block MTDatabaseDriverSelectorMySqlViewController *blockSelf = self;
    
    UITextField *textFieldServer    = [blockSelf textFieldHost];
    UITextField *textFieldDatabae   = [blockSelf textFieldDatabase];
    UITextField *textFieldPort      = [blockSelf textFieldPort];
    
    NSString *blockUsername = [[NSString alloc] initWithString:@"bogus"];
    NSString *blockPassword = [[NSString alloc] initWithString:@"bogus"];
    NSString *blockServer   = [[NSString alloc] initWithString:[textFieldServer text]];
    NSString *blockDatabase = [[NSString alloc] initWithString:[textFieldDatabae text]];
    
    NSString *textPortText  = [textFieldPort text];
    NSString *textPort      = [textPortText length] > 0 ? textPortText : @"0";   // FIXME: A very poor guess.
    NSInteger blockPort     = [textPort integerValue];
    
    NSString *databaseType = [[NSString alloc] initWithString:[blockSelf databaseType]];
    
    __block id blockSender = sender;
    
    NSURL *applicationFileUrlWithExtention = [NSURL uniqueUrlForDocumentWithName:[[self textFieldReportName] text]
                                                                   withExtension:MTDocumentExtentionMobleApplicationDocumentArchive];



    [MAReportDocument openManagedDocumentAtUrl:applicationFileUrlWithExtention withCompletionHandler:^(id managedDocument, BOOL success) {
        
        if (success) {
            
            __block MAReportDocument *documentReport = managedDocument;
            __block MTDatabaseDriverSelectorMySqlViewController *viewContoller = blockSelf;
            
            MTDatabaseConnection *databaseConnection = [[MTDatabaseConnection alloc] init];
            [databaseConnection setUsername:    blockUsername];
            [databaseConnection setPassword:    blockPassword];
            [databaseConnection setServer:      blockServer];
            [databaseConnection setDatabase:    blockDatabase];
            [databaseConnection setPort:        blockPort];

            id database = nil;
            if ([databaseType isEqualToString:MTSegueShowSetUpDatasourceMySqlIdentifier]) {

                database = [[MTDatabaseMySql alloc] initWithConnectionSettings:databaseConnection];
            
            } else if ([databaseType isEqualToString:MTSegueShowSetUpDatasourceSqlServerIdentifier]) {

                database = [[MTDatabaseSqlServer alloc] initWithConnectionSettings:databaseConnection];
            }
            
            if (database) {
                //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                dispatch_async(dispatch_get_main_queue(), ^{

                    [RptqDocument addDatabase:database toManagedObjectContext:[documentReport managedObjectContext] completion:^(BOOL successAddingDatasource, NSError *error) {

                        
                        
                        
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                            if (successAddingDatasource) {
                                [documentReport closeWithCompletionHandler:^(BOOL success) {
                                    if (success) {
                                        [documentReport setSuspended:YES];
                                        [[documentReport managedObjectContext] lock];
                                        [NSFileManager wrapFile:[documentReport fileURL] withExtention:MTDocumentExtentionMobleApplicationDocument overwrite:NO completion:^(BOOL success, NSURL *resultUrl) {
                                            
                                            [documentReport deleteFromDiskCompletion:^(BOOL success) {
                                                //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                                                dispatch_sync(dispatch_get_main_queue(), ^{
                                                    [blockSender setEnabled:YES];
                                                    [[viewContoller delegate] viewControllerDidFinish: viewContoller];
                                                    
                                                });
                                                
                                            }];
                                            
                                        }];
                                    }
                                }];
                                
                            } else {
                                [documentReport closeWithCompletionHandler:^(BOOL successClosingReport) {
                                    if (successClosingReport) {
                                        
                                        [documentReport deleteFromDiskCompletion:^(BOOL successDeletingFromDisk) { }];
                                        
                                        if (error) {
                                            
                                            [error presentErrorToUserWithCompletion:^(BOOL success) {
                                                [blockSender setEnabled:YES];
                                                [[[viewContoller navigationItem] backBarButtonItem] setEnabled:YES];
                                                [[viewContoller navigationItem] setRightBarButtonItem:[self holderButton] animated:YES];
                                                [[viewContoller delegate] viewControllerDidFinish: viewContoller];
                                            }];
                                            
                                        } else {
                                            
                                            NSString *connectionProblem = NSLocalizedString(@"Connection Problem", @"Connection Problem");
                                            NSString *connectionMessage = NSLocalizedString(@"Could not connect to database.", @"Could not connect to database.");
                                            NSString *connectionCancel = NSLocalizedString(@"Cancel", @"Cancel");
                                            
                                            MTAlertView *alertView = [[MTAlertView alloc] initWithTitle: connectionProblem message: connectionMessage cancelButtonTitle: connectionCancel otherButtonTitle:nil onDismiss:^(NSInteger buttonIndex) {
                                                
                                                [blockSender setEnabled:YES];
                                                [[[viewContoller navigationItem] backBarButtonItem] setEnabled:YES];
                                                [[viewContoller navigationItem] setRightBarButtonItem:[self holderButton] animated:YES];
                                                
                                            } onCancel:^{
                                                
                                                [blockSender setEnabled:YES];
                                                [[[viewContoller navigationItem] backBarButtonItem] setEnabled:YES];
                                                [[viewContoller navigationItem] setRightBarButtonItem:[self holderButton] animated:YES];
                                                
                                            }];
                                            [alertView show];
                                            [alertView autorelease];
                                            
                                        }
                                    }
                                }];
                                
                            }
                        });
                    }];
                    //});
                });
            }
            
            [databaseConnection release];
            [database release];
            
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
    
    [blockUsername release];
    [blockPassword release];
    [blockServer release];
    [blockDatabase release];
    [databaseType release];

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