//
//  MADConnectionViewController.m
//  Reports
//
//  Created by Michael Thomason on 1/13/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTConnectionViewController.h"
#import <MAD/MADConstants.h>

#import <MADCocoaExtensions/UIColor+EverydayApps.h>
#import <MAD/MADocument.h>
#import <MAD/MTDatabase.h>
#import <MAD/MTDatabaseConnection.h>
#import <MAD/MADErrorContainer.h>

#import "MADOperationObserver.h"
#import "MADOperationQueue.h"

#import <MAD/MTKeyChain.h>
#import <MAD/MTDataTable+Factory.h>
#import <MAD/MTQueryTest.h>
#import <MAD/MADCredential.h>

#import <MAD/MADProgress.h>
#import <MAD/MADNotificationProgress.h>

#import <MADFileManager/MADFileUtilities.h>

#import "MADNavigationBarTitleView.h"
#import "MADKeyChainOperationGet.h"
#import "MADPromptOperationCredentials.h"
#import "MADPromptOperationPassword.h"

#import "MADOperationConditionMissingResultString.h"
#import "MADOperationConditionHasResultString.h"

#import "UIApplication+Extras.h"

#import "MADGetCredentialsOperation.h"

#import "MADDatabaseOperationTestConnection.h"

#import "MADCreateDocumentOperation.h"

static NSString * const MADConnectionViewControllerDefaultPrompt = @"Each report requires a database connection.";
static NSString * const MADConnectionViewControllerDefaultTitle = @"Database Settings";

@interface MADConnectionViewController()
    <MADOperationObserver, MADocumentDelegate, MTDatabaseProtocol>

    @property (nonatomic, weak) IBOutlet UITableViewCell *tableViewCellDocumentName;
    @property (nonatomic, weak) IBOutlet UITableViewCell *tableViewCellHost;
    @property (nonatomic, weak) IBOutlet UITableViewCell *tableViewCellPort;
    @property (nonatomic, weak) IBOutlet UITableViewCell *tableViewCellDatabase;

    @property (nonatomic, weak) IBOutletCollection(UITableViewCell) NSArray *tableViewCells;

    @property (nonatomic, weak) IBOutlet UITextField *textFieldHost;
    @property (nonatomic, weak) IBOutlet UITextField *textFieldPort;
    @property (nonatomic, weak) IBOutlet UITextField *textFieldDatabase;
    @property (nonatomic, weak) IBOutlet UITextField *textFieldReportName;

    @property (nonatomic, strong) UIProgressView *progressView;

    @property (nonatomic, strong) MADOperationQueue *credentialQueue;
    @property (nonatomic, strong) MADGetCredentialsOperation *getCredentialsOperation;

@end

@implementation MADConnectionViewController

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    MADOperationQueue *credentialQueue = [[MADOperationQueue alloc] init];
    self.credentialQueue = credentialQueue;
    
    UIProgressView *progressView = [MADConnectionViewController progressViewWithWidth:self.tableView.frame.size.width];
    [self.tableView addSubview:progressView];
    self.progressView = progressView;
    
    NSString *prompt = NSLocalizedString(MADConnectionViewControllerDefaultPrompt, MADConnectionViewControllerDefaultPrompt);
    self.navigationItem.prompt = prompt;
    
    NSString *title = NSLocalizedString(MADConnectionViewControllerDefaultTitle, MADConnectionViewControllerDefaultTitle);
    self.title = title;
    
    self.clearsSelectionOnViewWillAppear = YES;
    
    self.navigationItem.hidesBackButton = NO;
    self.navigationItem.leftItemsSupplementBackButton = YES;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

    self.textFieldReportName.clearButtonMode = UITextFieldViewModeAlways;
    
    MADNavigationBarTitleView *titleView = [[MADNavigationBarTitleView alloc] initWithFrame:CGRectZero];
    titleView.text = NSLocalizedString(@"Database Settings", @"Database Settings");
    self.navigationItem.titleView = titleView;
}

#pragma mark - Post Report Notifications

- (void)addObserverToObjectForProgress:(id)obj {
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(objectDidUpdateProgress:)
                                                 name: MADNotificationProgressIdentifier
                                               object: obj];
}

- (void)removeObserverFromObjectForProgress:(id)obj {
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: MADNotificationProgressIdentifier
                                                  object: obj];
}

#pragma mark - Progress Notifications

- (void)objectDidUpdateProgress:(NSNotification *)sender {
    MADProgress *progress = sender.userInfo[MADNotificationProgressKey];
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        self.progressView.progress = progress.progress;
        NSString *message = progress.message.copy;
        self.navigationItem.prompt = message;
    }];
}

#pragma mark - MADOperationObserver

- (void)operationDidStart:(MADOperation *)operation { }

- (void)operation:(MADOperation *)operation didProduceOperation:(NSOperation *)newOperation { }

- (void)operationDidFinish:(MADOperation *)operation errors:(NSArray *)errors {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        [self removeObserverFromObjectForProgress:operation];
        [self.delegate viewControllerDidFinish: self];
        self.navigationItem.prompt = NSLocalizedString(MADConnectionViewControllerDefaultPrompt, MADConnectionViewControllerDefaultPrompt);
        [self enableTextFields];
    }];
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

- (void)removeKeyboard {
    [self.textFieldHost resignFirstResponder];
    [self.textFieldPort resignFirstResponder];
    [self.textFieldDatabase resignFirstResponder];
    [self.textFieldReportName resignFirstResponder];
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
    progressView.progressTintColor = [MADColorEverydayApps newColorAnalogous4];
    progressView.trackTintColor = [UIColor grayColor];
    return progressView;
}

- (MADCredential *)getCredentialsForDatabaseConnection:(MTDatabaseConnection *)databaseConnection {
    
    // Operation: Get credentials.
    // ---------------------------------------------------
    MADGetCredentialsOperation *getCredentialsOperation = [[MADGetCredentialsOperation alloc] initWithDatabaseConnection: databaseConnection
                                                                                                          viewController: self];
    [getCredentialsOperation addObserver:self];
    
    [self.credentialQueue addOperation: getCredentialsOperation];

    self.getCredentialsOperation = getCredentialsOperation;
    return nil;
}

- (void)disableUserInteractionWithMessage:(NSString *)message {
    [self removeKeyboard];
    [self disableTextFields];
    
    self.navigationItem.prompt = message;
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    [self disableNavigation];
    
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [activityIndicator startAnimating];
    activityIndicator.hidden = NO;
    activityIndicator.hidesWhenStopped = NO;
    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithCustomView:activityIndicator];
    barButtonItem.isAccessibilityElement = NO;
    [self.navigationItem setRightBarButtonItem:barButtonItem animated:YES];
}

- (IBAction)save:(id)sender {
    NSAssert(sender != nil, @"%s Sender is nil.", __PRETTY_FUNCTION__);
    
    NSString *message = NSLocalizedString(@"Importing schema.", @"Importing schema.");
    [self disableUserInteractionWithMessage:message];
    
    
    id <MADSaveFileProtocol> saveFileDelegate = self.saveFileDelegate;
    
    MTDatabaseConnection *databaseConnection = [MTDatabaseConnection newDatabaseConnectionWithType: self.databaseType host: self.textFieldHost.text
                                                                                          database: self.textFieldDatabase.text port: self.textFieldPort.text.integerValue];
    
    MADCreateDocumentOperation *createDocument = [[MADCreateDocumentOperation alloc] initWithFilename: self.textFieldReportName.text documentsDirectory: saveFileDelegate.documentDirectory
                                                                                   databaseConnection: databaseConnection viewController:self];
    [createDocument addObserver:self];
    [self addObserverToObjectForProgress:createDocument];
    [self.credentialQueue addOperation:createDocument];

}

#pragma mark - MTDatabaseProtocol

- (void)resetAfterConnectionString:(NSString *)connectionString failedTest:(NSArray *)errors {
    [self resetForm];
    [self displayErrors:errors forConnectionString:connectionString];

}

- (void)displayErrors:(NSArray *)errors forConnectionString:(NSString *)connectionString {
    [MADConnectionViewController viewController: self displayErrors: errors completion: ^(BOOL success) {
        [[MTKeyChain sharedObject] deleteKey:connectionString];
    }];
}

- (void)resetForm {
    [self enableNavigation];
    [self enableTextFields];
    self.navigationItem.rightBarButtonItem.enabled = YES;
    self.progressView.progress = 0.0000f;
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

+ (void)viewController:(id)viewController displayErrors:(NSArray *)errors completion:(void (^)(BOOL))completion {
    
    NSError *error = errors.lastObject;

    [UIAlertController alertControllerWithTitle: error.localizedDescription message: error.localizedFailureReason
                                 preferredStyle: UIAlertControllerStyleAlert];
    
    NSRange range = NSMakeRange(0, errors.count > 0 ? errors.count - 1 : 0);
    NSArray *remaningErrors = [errors subarrayWithRange:range];
    
    UIAlertController *alert = [UIAlertController errorDisplayErrorWithTitle:error.localizedDescription message:error.localizedFailureReason
                                                               andCompletion:^(UIAlertAction *action) {
        if (remaningErrors.count > 0) {
            [MADConnectionViewController viewController:viewController displayErrors:remaningErrors completion:^(BOOL success) {
                completion(YES);
            }];
        } else {
            completion(YES);
        }
    }];

    [viewController presentViewController:alert animated:YES completion:nil];

}

+ (void)showLocalNotificationCreatedReportWithName:(NSString *)name {
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    NSString *reportIsReady = NSLocalizedString(@"Created report '%@.'", @"Created report '%@.'");
    NSString *body = [NSString stringWithFormat:reportIsReady, name];
    notification.alertBody = body;
    [[UIApplication sharedApplication] presentLocalNotificationNow: notification];

}

- (void)showErrorLog:(MADErrorContainer *)errorContainer {
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
}

- (void)enableNavigation {
    self.navigationItem.leftBarButtonItem.enabled = YES;
    self.navigationItem.leftBarButtonItem.enabled = YES;
    [self.navigationItem setHidesBackButton:NO animated:YES];
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
