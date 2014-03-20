//
//  UITableViewControllerDataSourceSetupMySql.m
//  Reports
//
//  Created by Michael Thomason on 1/13/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTConnectionViewController.h"
#import "MTViewControllerActivitySpinner.h"
#import "UIDevice+Hack.h"
#import "MTTableViewController.h"
#import "MTDatabaseSqlServer.h"
#import "NSURL+Document.h"

@interface MTConnectionViewController()

@property (nonatomic, assign) BOOL activitySpinnerVisable;
@property (nonatomic, retain) MTViewControllerActivitySpinner *activitySpinnerViewController;
@property (nonatomic, retain) UIBarButtonItem *holderButton;

@end

@implementation MTConnectionViewController

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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
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

#pragma mark - Actions

- (void)cancel:(id)sender {
    //if ([UIDevice isPad]) {
        [[self delegate] viewControllerDidCancel:self];
    //}
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    
    
    UIViewController *viewControllerFrom = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *viewControllerTo = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    [[transitionContext containerView] setBackgroundColor:[UIColor clearColor]];
    [[transitionContext containerView] setOpaque:NO];
    [[viewControllerTo view] setBounds:[[viewControllerFrom view] bounds]];
    [[viewControllerTo view] setBackgroundColor:[UIColor clearColor]];
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
    
    __block MTConnectionViewController *blockSelf = self;
    
    UITextField *textFieldServer    = [blockSelf textFieldHost];
    UITextField *textFieldDatabae   = [blockSelf textFieldDatabase];
    UITextField *textFieldPort      = [blockSelf textFieldPort];
    
    NSString *blockServer   = [[NSString alloc] initWithString:[textFieldServer text]];
    NSString *blockDatabase = [[NSString alloc] initWithString:[textFieldDatabae text]];
    
    NSString *textPortText  = [textFieldPort text];
    NSString *textPort      = [textPortText length] > 0 ? textPortText : @"0";   // FIXME: A very poor guess.
    NSInteger blockPort     = [textPort integerValue];
    
    __block id blockSender = sender;
    
    NSURL *applicationFileUrlWithExtention = [NSURL uniqueUrlForDocumentWithName:[[self textFieldReportName] text]
                                                                   withExtension:MTDocumentExtentionMobleApplicationDocumentArchive];

    MTDatabaseConnection *dbDetails = [[MTDatabaseConnection alloc] init];
    [dbDetails setUsername:                nil];
    [dbDetails setPassword:                nil];
    [dbDetails setServer:                  blockServer];
    [dbDetails setDatabase:                blockDatabase];
    [dbDetails setPort:                    blockPort];
    [dbDetails setDatabaseTypeIdentifier:  [self databaseType]];
    
    [MAReportDocument initalSaveUsingUrl:applicationFileUrlWithExtention andConnection:dbDetails completion:^(BOOL success) {
        if (success) {
            [blockSender setEnabled:YES];
            [[blockSelf delegate] viewControllerDidFinish: blockSelf];
        } else {
            [blockSender setEnabled:YES];
            [[[blockSelf navigationItem] backBarButtonItem] setEnabled:YES];
            [[blockSelf navigationItem] setRightBarButtonItem:[self holderButton] animated:YES];
        }
    }];
    
    
    [blockServer release];
    [blockDatabase release];

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