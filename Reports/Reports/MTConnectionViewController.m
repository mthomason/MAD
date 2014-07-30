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
#import "UIColor+EverydayApps.h"

@interface MTConnectionViewController()

@property (nonatomic, assign) BOOL activitySpinnerVisable;
@property (nonatomic, strong) UIBarButtonItem *holderButton;
@property (nonatomic, strong) MAReportDocument *docToSave;

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
    
    CGRect activtyViewRect = CGRectMake(CGPointZero.x, CGPointZero.y, 230.0000f, 200.0000f);
    UIProgressView *progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    [progressView setFrame:CGRectMake(progressView.frame.origin.x, progressView.frame.origin.y, self.tableView.frame.size.width, progressView.frame.size.height)];
    [progressView setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    UIColor *tintColor = [UIColor tintColorAnalogous4];
    [progressView setTintColor:tintColor];
    [[self tableView] addSubview:progressView];
    
    MTActivityIndicator *activtyView = [[MTActivityIndicator alloc] initWithFrame:activtyViewRect];
    activtyView.center = CGPointMake(self.view.center.x, self.view.bounds.origin.y + (activtyView.bounds.size.height / 2.0000f) +
                                                        (activtyView.bounds.size.width - self.view.bounds.size.width) / 2.0000f + 64.0000f);
    [activtyView.status setText:@"Importing schema. Please wait."];
    [[self view] addSubview:activtyView];
    
    [sender setEnabled:NO];
    
    [[[self navigationItem] leftBarButtonItem] setEnabled:NO];
    [[self navigationItem] setHidesBackButton:YES animated:YES];
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
    
    NSURL *applicationFileUrlWithExtention = [NSURL uniqueUrlForDocumentWithName:[[self textFieldReportName] text]
                                                                   withExtension:MTDocumentExtentionMobleApplicationDocumentArchive];

    MTDatabaseConnection *dbDetails = [MTDatabaseConnection databaseConnectionFactoryEmpty:[self databaseType]];
    [dbDetails setServer:                  blockServer];
    [dbDetails setDatabase:                blockDatabase];
    [dbDetails setPort:                    blockPort];
    
    __weak MTActivityIndicator *weakActivtyView = activtyView;
    
    __block UIBackgroundTaskIdentifier bgTask = [self requestBackgroundTask];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    [dbDetails testConnection:^(BOOL success, NSError *error) {
        if (success) {
            
            MAReportDocument *doc = [[MAReportDocument alloc] initWithFileURL:applicationFileUrlWithExtention];
            [self setDocToSave:doc];
            __weak __block MAReportDocument *weakdoc1 = doc;
            __weak MTDatabaseConnection *weakConnection = dbDetails;
            [weakdoc1 open:^(BOOL success) {
                
                NSString *name = [NSString stringWithString:[doc name]];
                if (success) {
                    __weak __block MAReportDocument *weakdoc = weakdoc1;
                    [weakdoc addConnection:weakConnection status:^(NSString *readStatus, CGFloat progress) {
                        [weakActivtyView.status setText:readStatus];
                        progressView.progress = progress;
                    } completion:^(BOOL success, NSError *error) {
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                            dispatch_sync(dispatch_get_main_queue(), ^{
                                
                                if (success) {
                                    
                                    [self.docToSave close:^(BOOL success, NSError *error) {
                                        
                                        [blockSender setEnabled:YES];
                                        [[blockSelf delegate] viewControllerDidFinish: blockSelf];
                                        
                                        UILocalNotification *notification = [[UILocalNotification alloc] init];
                                        NSString *reportIsReady = NSLocalizedString(@"Your report '%@' is ready.", @"Your report '%@' is ready.");
                                        NSString *body = [NSString stringWithFormat:reportIsReady, name];
                                        [notification setAlertBody:body];
                                        [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
                                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
                                            UIApplication *app = [UIApplication sharedApplication];
                                            NSTimeInterval time = app.backgroundTimeRemaining > 7.0 ? 5.0 : app.backgroundTimeRemaining - 0.1;
                                            NSNumber *bgTaskWrapper = [NSNumber numberWithUnsignedInteger:bgTask];
                                            [NSTimer scheduledTimerWithTimeInterval:time target:self selector:@selector(handoffBackground:) userInfo:bgTaskWrapper repeats:NO];
                                        });
                                        
                                    }];
                                } else {
                                    [self.docToSave closeAndDelete:^(BOOL success, NSError *error) {
                                        [blockSender setEnabled:YES];
                                        [[[blockSelf navigationItem] backBarButtonItem] setEnabled:YES];
                                        [[[blockSelf navigationItem] leftBarButtonItem] setEnabled:YES];
                                        [[blockSelf navigationItem] setHidesBackButton:NO animated:YES];
                                        [[blockSelf navigationItem] setRightBarButtonItem:[self holderButton] animated:YES];
                                        if (error != nil) {
                                            UILocalNotification *notification = [[UILocalNotification alloc] init];
                                            NSString *localizedErrorString = NSLocalizedString(@"Error: %@. Please try again.", @"Error: %@. Please try again.");
                                            NSString *body = [NSString stringWithFormat:localizedErrorString, error.localizedDescription];
                                            [notification setAlertBody:body];
                                            [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
                                        }
                                        
                                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
                                            UIApplication *app = [UIApplication sharedApplication];
                                            NSTimeInterval time = app.backgroundTimeRemaining > 7.0 ? 5.0 : app.backgroundTimeRemaining - 0.1;
                                            NSNumber *bgTaskWrapper = [NSNumber numberWithUnsignedInteger:bgTask];
                                            [NSTimer scheduledTimerWithTimeInterval:time target:self selector:@selector(handoffBackground:) userInfo:bgTaskWrapper repeats:NO];
                                        });
                                        
                                    }];
                                }
                                [activtyView removeFromSuperview];
                                [progressView removeFromSuperview];
                                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                            });
                        });
                        
                    }];
                } else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [blockSender setEnabled:YES];
                        [[blockSelf delegate] viewControllerDidFinish: blockSelf];
                        [activtyView removeFromSuperview];
                        [progressView removeFromSuperview];
                    });
                }
            }];
        } else {
            [blockSender setEnabled:YES];
            [[[blockSelf navigationItem] backBarButtonItem] setEnabled:YES];
            [[blockSelf navigationItem] setRightBarButtonItem:[self holderButton] animated:YES];
            [activtyView removeFromSuperview];
        }
    }];
}

- (UIBackgroundTaskIdentifier)requestBackgroundTask {
    UIApplication *app = [UIApplication sharedApplication];
    __block UIBackgroundTaskIdentifier bgTask = [app beginBackgroundTaskWithExpirationHandler:^{
        [app endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];
    return bgTask;
}

- (void)handoffBackground:(NSNumber *)bgTask {
    [[UIApplication sharedApplication] endBackgroundTask:[bgTask unsignedIntegerValue]];
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
