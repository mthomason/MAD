//
//  UITableViewControllerDataSourceSetupMySql.m
//  Reports
//
//  Created by Michael Thomason on 1/13/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTConnectionViewController.h"
#import "MAReportDocument.h"
#import "UIDevice+Hack.h"
#import "MTDatabaseSqlServer.h"
#import "NSURL+Document.h"
#import "NSError+Constructors.h"
#import "NSError+UserInterface.h"
#import "MTActivityIndicator.h"
#import "MTQuery.h"

@interface MTConnectionViewController()

@property (nonatomic, assign) BOOL activitySpinnerVisable;
@property (nonatomic, strong) UIBarButtonItem *holderButton;
@property (nonatomic, strong) MTActivityIndicator *activityIndicator;

@end

@implementation MTConnectionViewController

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
    [[self tableView] setSeparatorStyle:UITableViewCellSeparatorStyleNone];
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
    return nil;
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
    
    [self.textFieldHost resignFirstResponder];
    [self.textFieldPort resignFirstResponder];
    [self.textFieldDatabase resignFirstResponder];
    [self.textFieldReportName resignFirstResponder];
    
    CGRect activityViewRect = CGRectMake(CGPointZero.x, CGPointZero.y, 230.0000f, 200.0000f);
    MTActivityIndicator *activityView = [[MTActivityIndicator alloc] initWithFrame:activityViewRect];
    activityView.center = CGPointMake(self.view.center.x, self.view.bounds.origin.y + (activityView.bounds.size.height / 2.0000f) +
                                                        (activityView.bounds.size.width - self.view.bounds.size.width) / 2.0000f + 64.0000f);
    [activityView.status setText:@"Importing schema. Please wait."];
    [[self view] addSubview:activityView];
    [self setActivityIndicator:activityView];
    
    [sender setEnabled:NO];
    [[[self navigationItem] backBarButtonItem] setEnabled:NO];
    
    [self setHolderButton: [[self navigationItem] rightBarButtonItem]];
    
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [activityIndicator startAnimating];
    [activityIndicator setHidden:NO];
    [activityIndicator setHidesWhenStopped:NO];
    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithCustomView:activityIndicator];
    [[self navigationItem] setRightBarButtonItem:barButtonItem animated:YES];
    
    __weak MTConnectionViewController *blockSelf = self;
    
    UITextField *textFieldServer    = [blockSelf textFieldHost];
    UITextField *textFieldDatabae   = [blockSelf textFieldDatabase];
    UITextField *textFieldPort      = [blockSelf textFieldPort];
    
    NSString *blockServer   = [[NSString alloc] initWithString:[textFieldServer text]];
    NSString *blockDatabase = [[NSString alloc] initWithString:[textFieldDatabae text]];
    
    NSString *textPortText  = [textFieldPort text];
    NSString *textPort      = [textPortText length] > 0 ? textPortText : @"0";   // FIXME: A very poor guess.
    NSInteger blockPort     = [textPort integerValue];
    
    __weak id blockSender = sender;
    
    NSURL *url = [NSURL uniqueUrlForDocumentWithName:[[self textFieldReportName] text]
                                                                   withExtension:MTDocumentExtentionMobleApplicationDocumentArchive];

    MTDatabaseConnection *dbDetails = [MTDatabaseConnection databaseConnectionFactoryEmpty:[self databaseType]];
    [dbDetails setServer:                  blockServer];
    [dbDetails setDatabase:                blockDatabase];
    [dbDetails setPort:                    blockPort];

    MTQuery *queryTest = [[MTQuery alloc] initWithQueryType: MTQueryTypeConnectionTest
                                                     object: dbDetails];
    __weak MTDatabaseConnection *weakDatabaseConnection = dbDetails;
    __weak MTActivityIndicator *weakActivityView = activityView;

    self.activityIndicator.status.text = @"Query Test";
    
    //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{

        [queryTest performQuery:^(BOOL success, NSError *error) {
            if (success) {
                self.activityIndicator.status.text = @"Query Test Succeded";
                MAReportDocument *report = [[MAReportDocument alloc] initWithFileURL:url];
                __weak MTActivityIndicator *weakActivityView2 = weakActivityView;
                [report open:^(id doc, BOOL success) {
                    if (success) {
                        __weak MTActivityIndicator *weakActivityView3 = weakActivityView2;
                        [doc addDatabaseConnection:weakDatabaseConnection
                                            status:^(NSString *readStatus) {
                                                //dispatch_sync(dispatch_get_main_queue(), ^{
                                                    NSString *status = [NSString stringWithString:readStatus];
                                                    weakActivityView3.status.text = status;
                                                    //[weakActivityView3.status performSelectorOnMainThread:@selector(setText:) withObject:status waitUntilDone:YES];
                                                //});
                                            }
                                        completion:^(BOOL success, NSError *error) {
                                            //dispatch_sync(dispatch_get_main_queue(), ^{
                                                if (success) {
                                                    [blockSender setEnabled:YES];
                                                    [[blockSelf delegate] viewControllerDidFinish: blockSelf];
                                                } else {
                                                    [blockSender setEnabled:YES];
                                                    [[[blockSelf navigationItem] backBarButtonItem] setEnabled:YES];
                                                    [[blockSelf navigationItem] setRightBarButtonItem:[blockSelf holderButton] animated:YES];
                                                }
                                                [activityView removeFromSuperview];
                                            //});
                                        }];
                    } else {
                        //dispatch_sync(dispatch_get_main_queue(), ^{
                            [blockSender setEnabled:YES];
                            [[[blockSelf navigationItem] backBarButtonItem] setEnabled:YES];
                            [[blockSelf navigationItem] setRightBarButtonItem:[blockSelf holderButton] animated:YES];
                            [activityView performSelectorOnMainThread:@selector(removeFromSuperview) withObject:nil waitUntilDone:YES];
                            NSString *title = NSLocalizedString(MNSInterfaceTitleProblem, MNSInterfaceTitleProblem);
                            NSString *message = NSLocalizedString(MNSInterfaceMessageErrorFailedToCreateReport, MNSInterfaceMessageErrorFailedToCreateReport);
                            NSError *error = [NSError errorWithDomain:@"MTReportDocument" code:36732 title:title andMessage:message];
                            [error performSelectorOnMainThread:@selector(presentErrorToUser) withObject:nil waitUntilDone:NO];
                        //});
                    }
                }];
            } else {
                //dispatch_sync(dispatch_get_main_queue(), ^{
                    [blockSender setEnabled:YES];
                    [[[blockSelf navigationItem] backBarButtonItem] setEnabled:YES];
                    [[blockSelf navigationItem] setRightBarButtonItem:[blockSelf holderButton] animated:YES];
                    [activityView performSelectorOnMainThread:@selector(removeFromSuperview) withObject:nil waitUntilDone:YES];
                    [error performSelectorOnMainThread:@selector(presentErrorToUser) withObject:nil waitUntilDone:NO];
                //});
            }
        }];
    //});

}

- (IBAction)documentNameDidEndOnExit:(id)sender { }

- (IBAction)schemaDidEndOnExit:(id)sender { }

- (IBAction)usernameDidEndOnExit:(id)sender { }

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
