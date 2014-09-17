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
#import "MADocument.h"
#import "UIDevice+Hack.h"
#import "MTDatabaseSqlServer.h"
#import "NSURL+Document.h"
#import "NSError+Constructors.h"
#import "NSError+UserInterface.h"
#import "MTActivityIndicator.h"
#import "UIColor+EverydayApps.h"
#import "UIApplication+Extras.h"
#import "MTErrorContainer.h"

NSString * const MTConnectionViewControllerDefaultPrompt = @"Set connection settings.";
NSString * const MTConnectionViewControllerDefaultTitle = @"Database Location";

@interface MTConnectionViewController()

@property (nonatomic, assign) BOOL activitySpinnerVisable;
@property (nonatomic, strong) UIBarButtonItem *holderButton;
@property (nonatomic, strong) MADocument *docToSave;

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
        self.navigationItem.prompt = NSLocalizedString(MTConnectionViewControllerDefaultPrompt, MTConnectionViewControllerDefaultPrompt);
    }
    self.title = NSLocalizedString(MTConnectionViewControllerDefaultTitle, MTConnectionViewControllerDefaultTitle);
    [self setClearsSelectionOnViewWillAppear: YES];
    
    [self.navigationItem setHidesBackButton:NO];
    [self.navigationItem setLeftItemsSupplementBackButton: YES];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    
    self.textFieldReportName.clearButtonMode = UITextFieldViewModeAlways;
}

#pragma mark - Actions

- (void)cancel:(id)sender {
    [self.delegate viewControllerDidCancel:self];
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    
    
    UIViewController *viewControllerFrom = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *viewControllerTo = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    [transitionContext containerView].backgroundColor = [UIColor clearColor];
    [[transitionContext containerView] setOpaque:NO];
    [[viewControllerTo view] setBounds:[[viewControllerFrom view] bounds]];
    [viewControllerTo view].backgroundColor = [UIColor clearColor];
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

- (void)disableTextFields {
    self.textFieldHost.enabled = NO;
    self.textFieldPort.enabled = NO;
    self.textFieldDatabase.enabled = NO;
    self.textFieldReportName.enabled = NO;
}

- (void)enableTextFields {
    self.textFieldHost.enabled = YES;
    self.textFieldPort.enabled = YES;
    self.textFieldDatabase.enabled = YES;
    self.textFieldReportName.enabled = YES;
}


- (IBAction)save:(id)sender {
    
    [self.textFieldHost resignFirstResponder];
    [self.textFieldPort resignFirstResponder];
    [self.textFieldDatabase resignFirstResponder];
    [self.textFieldReportName resignFirstResponder];

    [self disableTextFields];
    
    UIProgressView *progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    [progressView setFrame:CGRectMake(progressView.frame.origin.x, progressView.frame.origin.y, self.tableView.frame.size.width, progressView.frame.size.height)];
    progressView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    progressView.progressTintColor = [UIColor tintColorAnalogous4];
    progressView.trackTintColor = [UIColor grayColor];
    [self.tableView addSubview:progressView];
    
    self.navigationItem.prompt = @"Importing schema.";
    
    [sender setEnabled:NO];
    
    [self disableNavigation];
    
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [activityIndicator startAnimating];
    [activityIndicator setHidden:NO];
    [activityIndicator setHidesWhenStopped:NO];
    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithCustomView:activityIndicator];
    [self.navigationItem setRightBarButtonItem:barButtonItem animated:YES];
    
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
    
    NSURL *applicationFileUrlWithExtention = [NSURL uniqueUrlForDocumentWithName:self.textFieldReportName.text
                                                                   withExtension:MTDocumentExtentionMobleApplicationDocument];

    MTDatabaseConnection *dbDetails = [MTDatabaseConnection databaseConnectionFactoryEmpty:[self databaseType]];
    [dbDetails setServer:                  blockServer];
    [dbDetails setDatabase:                blockDatabase];
    [dbDetails setPort:                    blockPort];
    
    
    __block UIBackgroundTaskIdentifier bgTask = [[UIApplication sharedApplication] requestBackgroundTask];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    [dbDetails testConnection:^(BOOL success, NSError *error) {
        if (success) {
            
            MADocument *doc = [[MADocument alloc] initWithFileURL:applicationFileUrlWithExtention];
            [self setDocToSave:doc];
            __weak __block MADocument *weakdoc1 = doc;
            __weak MTDatabaseConnection *weakConnection = dbDetails;
            
            [weakdoc1 saveToURL: weakdoc1.fileURL forSaveOperation: UIDocumentSaveForCreating
          completionHandler:^(BOOL success) {
              
              //if (success) {
              //    [weakdoc1 openWithCompletionHandler:^(BOOL success) {

                      

                      
                      NSString *name = [NSString stringWithString:[doc name]];
                      if (success) {
                          __weak __block MADocument *weakdoc = weakdoc1;
                          [weakdoc addConnection:weakConnection status:^(NSString *readStatus, CGFloat progress) {
                              self.navigationItem.prompt = readStatus;
                              progressView.progress = progress;
                          } completion:^(BOOL success, MTErrorContainer *errorContainer) {
                                      
                                      if (success) {
                                          [self.docToSave saveToURL:self.docToSave.fileURL forSaveOperation:UIDocumentSaveForOverwriting completionHandler:^(BOOL success) {
                                              if (success) {
                                                  [self.docToSave closeWithCompletionHandler:^(BOOL success) {
                                                      [blockSender setEnabled:YES];
                                                      [[blockSelf delegate] viewControllerDidFinish: blockSelf];
                                                      
                                                      UILocalNotification *notification = [[UILocalNotification alloc] init];
                                                      NSString *reportIsReady = NSLocalizedString(@"Created report '%@.'", @"Created report '%@.'");
                                                      NSString *body = [NSString stringWithFormat:reportIsReady, name];
                                                      [notification setAlertBody:body];
                                                      [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
                                                      
                                                      [self enableTextFields];
                                                      self.navigationItem.prompt = NSLocalizedString(MTConnectionViewControllerDefaultPrompt, MTConnectionViewControllerDefaultPrompt);
                                                      
                                                      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
                                                          UIApplication *app = [UIApplication sharedApplication];
                                                          NSTimeInterval time = app.backgroundTimeRemaining > 7.0 ? 5.0 : app.backgroundTimeRemaining - 0.1;
                                                          NSNumber *bgTaskWrapper = @(bgTask);
                                                          [NSTimer scheduledTimerWithTimeInterval:time target:[UIApplication sharedApplication] selector:@selector(handoffBackground:) userInfo:bgTaskWrapper repeats:NO];
                                                      });
                                                      
                                                  }];
                                              }
                                          }];
                                      } else {
                                          dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                              dispatch_sync(dispatch_get_main_queue(), ^{

                                          [self.docToSave closeAndDelete:^(BOOL success, NSError *error) {
                                              [blockSender setEnabled:YES];
                                              [self enableNavigation];
                                              
                                              if (error != nil) {
                                                  UILocalNotification *notification = [[UILocalNotification alloc] init];
                                                  NSString *localizedErrorString = NSLocalizedString(@"Error: %@. Please try again.", @"Error: %@. Please try again.");
                                                  NSString *body = [NSString stringWithFormat:localizedErrorString, error.localizedDescription];
                                                  [notification setAlertBody:body];
                                                  [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
                                              }
                                              
                                              [self enableTextFields];
                                              self.navigationItem.prompt = NSLocalizedString(MTConnectionViewControllerDefaultPrompt, MTConnectionViewControllerDefaultPrompt);
                                              
                                              dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
                                                  UIApplication *app = [UIApplication sharedApplication];
                                                  NSTimeInterval time = app.backgroundTimeRemaining > 7.0 ? 5.0 : app.backgroundTimeRemaining - 0.1;
                                                  NSNumber *bgTaskWrapper = @(bgTask);
                                                  
                                                  [NSTimer scheduledTimerWithTimeInterval:time target:[UIApplication sharedApplication] selector:@selector(handoffBackground:) userInfo:bgTaskWrapper repeats:NO];
                                              });
                                          }];
                                              });
                                          });
                                      }
                                      
                                      if (errorContainer && [errorContainer count] > 0) {
                                          NSString *errorText = [errorContainer errorLogCompact];
                                          UIAlertView *alertView = [[UIAlertView alloc] initWithTitle: @"Issues Encounterd"
                                                                                              message: errorText
                                                                                             delegate: nil
                                                                                    cancelButtonTitle: @"Continue"
                                                                                    otherButtonTitles: nil];
                                          [alertView show];
                                      }
                                      
                                      [progressView removeFromSuperview];
                                      [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                              
                          }];
                      } else {
                          dispatch_async(dispatch_get_main_queue(), ^{
                              [blockSender setEnabled:YES];
                              [blockSelf enableNavigation];
                              [[blockSelf delegate] viewControllerDidFinish: blockSelf];
                              [progressView removeFromSuperview];
                          });
                      }

                      
                      
                      
             //     }];
             // }
              
            }];
        } else {
            [blockSender setEnabled:YES];
            [blockSelf enableNavigation];
            [progressView removeFromSuperview];
        }
    }];

}

- (void)disableNavigation {
    [[self.navigationItem leftBarButtonItem] setEnabled:NO];
    [self.navigationItem setHidesBackButton:YES animated:YES];
    [[self.navigationItem backBarButtonItem] setEnabled:NO];
    [self setHolderButton: [self.navigationItem rightBarButtonItem]];
}

- (void)enableNavigation {
    [[self.navigationItem backBarButtonItem] setEnabled:YES];
    [[self.navigationItem leftBarButtonItem] setEnabled:YES];
    [self.navigationItem setHidesBackButton:NO animated:YES];
    [self.navigationItem setRightBarButtonItem:[self holderButton] animated:YES];
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
    [tableView deselectRowAtIndexPath: indexPath animated: NO];
}

@end
