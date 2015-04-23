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
#import "MADConstants.h"
#import "MTDatabaseConnection.h"
#import "MADocument.h"
#import "UIDevice+Hack.h"
#import "MTDatabaseSqlServer.h"
#import "NSURL+Document.h"
#import "NSError+Constructors.h"
#import "NSError+Constructors.h"
#import "MTActivityIndicator.h"
#import "UIColor+EverydayApps.h"
#import "UIApplication+Extras.h"
#import "MTErrorContainer.h"
#import "MACloudManager.h"
#import "MADBarButtonItem.h"
#import "MADNavigationBarTitleView.h"
#import "MTKeyChain.h"

NSString * const MTConnectionViewControllerDefaultPrompt = @"Each report requires a database connection.";
NSString * const MTConnectionViewControllerDefaultTitle = @"Database Settings";

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
    self.navigationItem.prompt = NSLocalizedString(MTConnectionViewControllerDefaultPrompt, MTConnectionViewControllerDefaultPrompt);
    self.title = NSLocalizedString(MTConnectionViewControllerDefaultTitle, MTConnectionViewControllerDefaultTitle);
    [self setClearsSelectionOnViewWillAppear: YES];
    
    self.navigationItem.hidesBackButton = NO;
    self.navigationItem.leftItemsSupplementBackButton = YES;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

    self.textFieldReportName.clearButtonMode = UITextFieldViewModeAlways;
    
    MADNavigationBarTitleView *titleView = [[MADNavigationBarTitleView alloc] initWithFrame:CGRectZero];
    titleView.text = NSLocalizedString(@"Database Settings", @"Database Settings");
    self.navigationItem.titleView = titleView;
}

#pragma mark - Actions

- (void)cancel:(id)sender {
    [self.delegate viewControllerDidCancel:self];
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    
    
    UIViewController *viewControllerFrom = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *viewControllerTo = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    transitionContext.containerView.backgroundColor = [UIColor clearColor];
    [transitionContext.containerView setOpaque:NO];
    viewControllerTo.view.bounds = viewControllerFrom.view.bounds;
    viewControllerTo.view.backgroundColor = [UIColor clearColor];
    [transitionContext.containerView addSubview:viewControllerTo.view];
    viewControllerTo.view.bounds = transitionContext.containerView.bounds;
    viewControllerTo.view.center = transitionContext.containerView.center;
    viewControllerTo.view.alpha = 0.0000f;
    
    [UIView animateWithDuration:0.4000f animations:^{
        viewControllerTo.view.alpha = 1.0000f;
        [transitionContext.containerView addSubview:viewControllerTo.view];
    } completion:^(BOOL finished) {
        [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
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

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
                                                                  presentingController:(UIViewController *)presenting
                                                                      sourceController:(UIViewController *)source {
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

+ (UIProgressView *)progressViewWithWidth:(CGFloat)width {
    UIProgressView *progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    progressView.frame = CGRectMake(progressView.frame.origin.x, progressView.frame.origin.y, width, progressView.frame.size.height);
    progressView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    progressView.progressTintColor = [UIColor tintColorAnalogous4];
    progressView.trackTintColor = [UIColor grayColor];
    return progressView;
}

- (IBAction)save:(id)sender {
    
    [self.textFieldHost resignFirstResponder];
    [self.textFieldPort resignFirstResponder];
    [self.textFieldDatabase resignFirstResponder];
    [self.textFieldReportName resignFirstResponder];

    [self disableTextFields];
    
    UIProgressView *progressView = [MTConnectionViewController progressViewWithWidth:self.tableView.frame.size.width];
    [self.tableView addSubview:progressView];
    
    self.navigationItem.prompt = @"Importing schema.";
    
    [sender setEnabled:NO];
    
    [self disableNavigation];
    
    MADBarButtonItem *barButtonItem = [[MADBarButtonItem alloc] initWithBarButtonSystemItem: MADBarButtonSystemItemActivity
                                                                                     target: nil
                                                                                     action: nil];
    [self.navigationItem setRightBarButtonItem:barButtonItem animated:YES];
    
    UITextField *textFieldServer    = self.textFieldHost;
    UITextField *textFieldDatabae   = self.textFieldDatabase;
    UITextField *textFieldPort      = self.textFieldPort;
    
    NSString *blockServer   = [[NSString alloc] initWithString: textFieldServer.text];
    NSString *blockDatabase = [[NSString alloc] initWithString: textFieldDatabae.text];
    
    NSString *textPortText  = textFieldPort.text;
    NSString *textPort      = textPortText.length > 0 ? textPortText : @"0";   // FIXME: A very poor guess.
    NSInteger blockPort     = textPort.integerValue;
    
    __weak UIBarButtonItem *blockSender = sender;
    NSAssert(blockSender == nil, @"%s Sender is nil.", __PRETTY_FUNCTION__);
    
    NSURL *applicationFileUrlWithExtention = [[MACloudManager sharedManager] uniqueUrlForDocumentWithName: self.textFieldReportName.text
                                                                                            withExtension: MADFileExtentionMobleApplicationDocument
                                                                                              inContainer: MACloudManagerSectionLocal];
    
    MTDatabaseConnection *dbDetails = [MTDatabaseConnection databaseConnectionFactoryEmpty:self.databaseType];
    dbDetails.server = blockServer;
    dbDetails.database = blockDatabase;
    dbDetails.port = blockPort;
    
    
    __block UIBackgroundTaskIdentifier bgTask = [[UIApplication sharedApplication] requestBackgroundTask];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    __weak MTConnectionViewController *weakself = self;
    
    [dbDetails testConnection:^(BOOL success, NSError *error, NSArray *errors) { //Not always removing credentsals when connection fails.
        
        __strong MTConnectionViewController *strongself = weakself;
        if (success) {
            
            MADocument *doc = [[MADocument alloc] initWithFileURL:applicationFileUrlWithExtention];
            strongself.docToSave = doc;
            
            __weak __block MADocument *weakdoc1 = doc;
            __weak MTDatabaseConnection *weakConnection = dbDetails;
            __weak MTConnectionViewController *weakself2 = strongself;
            
            [weakdoc1 saveToURL: weakdoc1.fileURL
               forSaveOperation: UIDocumentSaveForCreating
              completionHandler:^(BOOL success) {
                  
                  __strong MTConnectionViewController *strongself2 = weakself2;
                  __weak MTConnectionViewController *weakself3 = strongself2;
                  
                  if (success) {
                      
                      NSString *name = [NSString stringWithString:doc.fileName];
                      __weak __block MADocument *weakdoc = weakdoc1;
                      @synchronized(weakself) {
                          [weakdoc addConnection:weakConnection status:^(NSString *readStatus, CGFloat progress) {
                              
                              weakself3.navigationItem.prompt = readStatus;
                              progressView.progress = progress;
                              
                          } completion:^(BOOL success, MTErrorContainer *errorContainer) {
                              
                              if (success) {
                                  
                                  __strong MTConnectionViewController *strongself3 = weakself3;
                                  __weak MTConnectionViewController *weakself4 = strongself3;
                                  
                                  [weakself4 saveCloseAndExitWithCompletion:^(BOOL success, NSError *error) {
                                      
                                      blockSender.enabled = YES;
                                      [MTConnectionViewController showLocalNotificationCreatedReportWithName:name];
                                      
                                      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
                                          
                                          NSNumber *bgTaskWrapper = @(bgTask);
                                          [[UIApplication sharedApplication] handoffBackground:bgTaskWrapper];
                                          
                                      });
                                      
                                  }];
                                  

                              } else {
                                  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                      dispatch_sync(dispatch_get_main_queue(), ^{
                                          
                                          [self.docToSave closeAndDelete:^(BOOL success, NSError *error) {
                                              
                                              blockSender.enabled = YES;
                                              
                                              [self enableNavigation];
                                              
                                              if (error != nil) {
                                                  UILocalNotification *notification = [[UILocalNotification alloc] init];
                                                  NSString *localizedErrorString = NSLocalizedString(@"Error: %@. Please try again.", @"Error: %@. Please try again.");
                                                  notification.alertBody = [NSString stringWithFormat:localizedErrorString, error.localizedDescription];
                                                  [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
                                              }
                                              
                                              [self enableTextFields];
                                              self.navigationItem.prompt = NSLocalizedString(MTConnectionViewControllerDefaultPrompt, MTConnectionViewControllerDefaultPrompt);
                                              
                                              dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
                                                  
                                                  NSNumber *bgTaskWrapper = @(bgTask);
                                                  [[UIApplication sharedApplication] handoffBackground:bgTaskWrapper];

                                              });
                                          }];
                                      });
                                  });
                              }
                              
                              [self showErrorLog:errorContainer];
                              
                              [progressView removeFromSuperview];
                              [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                              
                          }];
                      }
                  } else {
                      
                      dispatch_async(dispatch_get_main_queue(), ^{
                          blockSender.enabled = YES;
                          [weakself3 enableNavigation];
                          [weakself3.delegate viewControllerDidFinish: weakself3];
                          [progressView removeFromSuperview];
                      });
                      
                  }
                  
              }];
        } else {
            
            NSString *key = [NSString stringWithString: dbDetails.connectionString];
            [MTConnectionViewController viewController: strongself
                                         displayErrors: errors
                                            completion: ^(BOOL success) {
                [[MTKeyChain sharedObject] deleteKey:key];
            }];
            
            blockSender.enabled = YES;
            [strongself enableNavigation];
            [progressView removeFromSuperview];
        }
    }];
}

+ (void)viewController:(id)viewController displayErrors:(NSArray *)errors completion:(void (^)(BOOL))completion {
    
    NSString *continueButtonTitle = NSLocalizedString(@"Continue", @"Continue");
    NSError *error = errors.lastObject;

    UIAlertController *alert = [UIAlertController alertControllerWithTitle: error.localizedDescription
                                                                   message: error.localizedFailureReason
                                                            preferredStyle: UIAlertControllerStyleAlert];
    
    NSRange range = NSMakeRange(0, errors.count > 0 ? errors.count - 1 : 0);
    NSArray *remaningErrors = [errors subarrayWithRange:range];
    UIAlertAction *ok = [UIAlertAction actionWithTitle: continueButtonTitle
                                                 style: UIAlertActionStyleDefault
                                               handler:^(UIAlertAction *action) {
                                                   if (remaningErrors.count > 0) {
                                                       [MTConnectionViewController viewController:viewController
                                                                                    displayErrors:remaningErrors
                                                                                       completion:^(BOOL success) {
                                                                                           completion(YES);
                                                                                       }];
                                                   } else {
                                                       completion(YES);
                                                   }
                                               }];
    [alert addAction:ok];
    [viewController presentViewController:alert animated:YES completion:^{
        
    }];

}

- (void)saveCloseAndExitWithCompletion:(void (^)(BOOL, NSError *))completion {
    __weak MTConnectionViewController *weakself = self;
    
    [self.docToSave saveToURL: self.docToSave.fileURL
             forSaveOperation: UIDocumentSaveForOverwriting
            completionHandler: ^(BOOL success) {
                
                __strong MTConnectionViewController *strongself = weakself;
                __weak MTConnectionViewController *weakself1 = strongself;
                
                if (success) {
                    [weakself1.docToSave closeWithCompletionHandler:^(BOOL success) {
                        
                        __strong MTConnectionViewController *strongself1 = weakself1;
                        
                        [strongself1 finishDocument];
                        completion(success, nil);
                        
                    }];
                }
            }];
}

- (void)finishDocument {
    [self.delegate viewControllerDidFinish: self];
    self.navigationItem.prompt = NSLocalizedString(MTConnectionViewControllerDefaultPrompt, MTConnectionViewControllerDefaultPrompt);
    [self enableTextFields];
}

+ (void)showLocalNotificationCreatedReportWithName:(NSString *)name {
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    NSString *reportIsReady = NSLocalizedString(@"Created report '%@.'", @"Created report '%@.'");
    NSString *body = [NSString stringWithFormat:reportIsReady, name];
    notification.alertBody = body;
    [[UIApplication sharedApplication] presentLocalNotificationNow: notification];

}

- (void)showErrorLog:(MTErrorContainer *)errorContainer {
    if (errorContainer && [errorContainer count] > 0) {
        NSString *errorText = [errorContainer errorLogCompact];
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle: @"Issues Encounterd"
                                                                       message: errorText
                                                                preferredStyle: UIAlertControllerStyleAlert];
        
        UIAlertAction *ok = [UIAlertAction actionWithTitle: @"Continue"
                                                     style: UIAlertActionStyleDefault
                                                   handler: nil];
        [alert addAction:ok];
        [self presentViewController:alert
                           animated:YES
                         completion:nil];
    }

}

- (void)disableNavigation {
    self.navigationItem.leftBarButtonItem.enabled = NO;
    self.navigationItem.backBarButtonItem.enabled = NO;
    [self.navigationItem setHidesBackButton:YES animated:YES];
    self.holderButton = self.navigationItem.rightBarButtonItem;
}

- (void)enableNavigation {
    self.navigationItem.leftBarButtonItem.enabled = YES;
    self.navigationItem.leftBarButtonItem.enabled = YES;
    [self.navigationItem setHidesBackButton:NO animated:YES];
    [self.navigationItem setRightBarButtonItem:self.holderButton animated:YES];
}

- (IBAction)documentNameDidEndOnExit:(id)sender { }

- (IBAction)schemaDidEndOnExit:(id)sender { }

- (IBAction)usernameDidEndOnExit:(id)sender { }

- (IBAction)hostDidEndOnExit:(id)sender {
    if ([self.textFieldPort canBecomeFirstResponder]) {
        [self.textFieldPort becomeFirstResponder];
    }
}

- (IBAction)portDidEndOnExit:(id)sender {
    [self.textFieldPort resignFirstResponder];
}

- (IBAction)canceled:(id)sender {
    [self.delegate viewControllerDidCancel:self];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath: indexPath animated: NO];
}

@end
