//
//  MADConnectionViewController.m
//  Reports
//
//  Created by Michael Thomason on 1/13/12.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADConnectionViewController.h"
#import "MADViewControllerStandardProtocol.h"

#import <UIKit/UIAccessibility.h>
#import <UIKit/UINavigationController.h>
#import <UIKit/UINavigationBar.h>
#import <UIKit/UIAlertController.h>
#import <UIKit/UIActivityIndicatorView.h>
#import <UIKit/UILocalNotification.h>

#import <MADCocoaExtensions/MADAlertController.h>
#import <MADCocoaExtensions/UIColor+EverydayApps.h>

#import <MADExplorer/MADSaveFileProtocol.h>

#import <MAD/MADDocumentProtocol.h>
#import <MAD/MADDatabaseProtocol.h>
#import <MAD/MADConstants.h>
#import <MAD/MADocument.h>
#import <MAD/MTDatabase.h>
#import <MAD/MADDatabaseConnection.h>
#import <MAD/MADErrorContainer.h>
#import <MAD/MTKeyChain.h>
#import <MAD/MADDataTable.h>
#import <MAD/MTQueryTest.h>
#import <MAD/MADCredential.h>
#import <MAD/MADProgress.h>
#import <MAD/MADNotificationProgress.h>

#import <MADFileManager/MADFileUtilities.h>

#import "MADOperationObserver.h"
#import "MADOperationQueue.h"

#import "MADKeyChainOperationGet.h"
#import "MADPromptOperationCredentials.h"
#import "MADPromptOperationPassword.h"

#import "MADOperationConditionMissingResultString.h"
#import "MADOperationConditionHasResultString.h"

#import "MADLabelTitle.h"

#import "MADProgressView.h"
#import "MADGetCredentialsOperation.h"

#import "MADOperationDatabaseTestConnection.h"

#import "MADOperationCreateDocument.h"

#import "UIApplication+Extras.h"

typedef void (^MADBlockAlertDidFinish)(UIAlertAction *);
typedef void (^MADBlockCompletionStatus)(BOOL);

static NSString * const MADConnectionViewControllerDefaultPrompt = @"Each report requires a database connection.";
static NSString * const MADConnectionViewControllerDefaultTitle = @"Database Settings";

@interface MADConnectionViewController()
    <MADOperationObserver, MADocumentDelegate, MADDatabaseProtocol>

    @property (nonatomic, weak) IBOutlet UITableViewCell *tableViewCellDocumentName;
    @property (nonatomic, weak) IBOutlet UITableViewCell *tableViewCellHost;
    @property (nonatomic, weak) IBOutlet UITableViewCell *tableViewCellPort;
    @property (nonatomic, weak) IBOutlet UITableViewCell *tableViewCellDatabase;

    @property (nonatomic, weak) IBOutletCollection(UITableViewCell) NSArray *tableViewCells;

    @property (nonatomic, weak) IBOutlet UITextField *textFieldHost;
    @property (nonatomic, weak) IBOutlet UITextField *textFieldPort;
    @property (nonatomic, weak) IBOutlet UITextField *textFieldDatabase;
    @property (nonatomic, weak) IBOutlet UITextField *textFieldReportName;

    @property (nonatomic, strong) MADProgressView *progressView;

    @property (nonatomic, strong) MADOperationQueue *credentialQueue;
    @property (nonatomic, strong) MADGetCredentialsOperation *getCredentialsOperation;

@end

@implementation MADConnectionViewController

+ (void)initialize {
    [super initialize];
    
    if (self != [MADConnectionViewController self]) {
        @autoreleasepool {
            UIProgressView <UIAppearance> *appearanceProxyProgressView;
            NSArray <Class <UIAppearanceContainer>> *classes;
            classes = [[NSArray alloc] initWithObjects: self, nil];
            appearanceProxyProgressView = [UIProgressView appearanceWhenContainedInInstancesOfClasses:classes];
            appearanceProxyProgressView.tintColor = [UIColor whiteColor];
            appearanceProxyProgressView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            appearanceProxyProgressView.progressTintColor = [MADColorEverydayApps newColorAnalogous4];
            appearanceProxyProgressView.trackTintColor = [UIColor grayColor];
        }
    }
}

- (void)dealloc { }

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        MADProgressView *progressView;
        progressView = [MADProgressView newProgressView:MADProgressViewTypeConnection];
        self.progressView = progressView;
    }
    return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    MADOperationQueue *credentialQueue = [[MADOperationQueue alloc] init];
    self.credentialQueue = credentialQueue;
    
    
    NSString *prompt = NSLocalizedString(MADConnectionViewControllerDefaultPrompt,
                                         MADConnectionViewControllerDefaultPrompt);
    self.navigationItem.prompt = prompt;
    
    NSString *title = NSLocalizedString(MADConnectionViewControllerDefaultTitle,
                                        MADConnectionViewControllerDefaultTitle);
    self.title = title;
    
    self.clearsSelectionOnViewWillAppear = YES;
    
    self.navigationItem.hidesBackButton = NO;
    self.navigationItem.leftItemsSupplementBackButton = YES;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

    self.textFieldReportName.clearButtonMode = UITextFieldViewModeAlways;
    
    MADLabelTitle *titleView = [[MADLabelTitle alloc] initWithFrame:CGRectZero];
    NSString *databaseSettings = @"Database Settings";
    titleView.text = NSLocalizedString(databaseSettings, databaseSettings);
    self.navigationItem.titleView = titleView;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    CGRect frameProgress, frameTable;
    frameProgress = self.progressView.frame;
    frameTable = self.tableView.frame;;
    
    self.progressView.frame = CGRectMake(frameProgress.origin.x, frameProgress.origin.y,
                                         frameTable.size.width, frameProgress.size.height);
    [self.tableView addSubview:self.progressView];
    
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
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
    MADProgress *progress;
    progress = sender.userInfo[MADNotificationProgressKey];
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        self.progressView.progress = progress.progress;
        self.navigationItem.prompt = progress.message.copy;
    }];
}

#pragma mark - MADOperationObserver

- (void)operationDidStart:(MADOperation *)operation { }

- (void)operation:(MADOperation *)operation didProduceOperation:(NSOperation *)newOperation { }

- (void)operationDidFinish:(MADOperation *)operation errors:(NSArray *)errors {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        [self removeObserverFromObjectForProgress:operation];
        [self.delegate viewControllerDidFinish: self];
        self.navigationItem.prompt = NSLocalizedString(MADConnectionViewControllerDefaultPrompt,
                                                       MADConnectionViewControllerDefaultPrompt);
        [self enableTextFields];
    }];
}

#pragma mark - Actions

- (void)cancel:(id)sender {
    [self.delegate viewControllerDidCancel:self];
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    
    UIViewController *viewControllerFrom, *viewControllerTo;
    viewControllerFrom = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    viewControllerTo = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
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
    UIProgressView *progressView;
    progressView = [[UIProgressView alloc] initWithProgressViewStyle: UIProgressViewStyleDefault];
    progressView.frame = CGRectMake(progressView.frame.origin.x, progressView.frame.origin.y,
                                    width, progressView.frame.size.height);
    progressView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    progressView.progressTintColor = [MADColorEverydayApps newColorAnalogous4];
    progressView.trackTintColor = [UIColor grayColor];
    return progressView;
}

- (MADCredential *)getCredentialsForDatabaseConnection:(MADDatabaseConnection *)databaseConnection {
    
    // Operation: Get credentials.
    // ---------------------------------------------------
    MADGetCredentialsOperation *getCredentialsOperation;
    getCredentialsOperation = [[MADGetCredentialsOperation alloc] initWithDatabaseConnection: databaseConnection
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
    
    UIActivityIndicatorView *activityIndicator;
    activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
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
    
    MADDatabaseConnection *databaseConnection;
    databaseConnection= [MADDatabaseConnection newDatabaseConnectionWithType: self.databaseType host: self.textFieldHost.text
                                                                    database: self.textFieldDatabase.text port: self.textFieldPort.text.integerValue];
    
    MADOperationCreateDocument *createDocument;
    createDocument = [[MADOperationCreateDocument alloc] initWithFilename: self.textFieldReportName.text
                                                       documentsDirectory: saveFileDelegate.documentDirectory
                                                       databaseConnection: databaseConnection
                                                           viewController: self];
    [createDocument addObserver:self];
    [self addObserverToObjectForProgress:createDocument];
    [self.credentialQueue addOperation:createDocument];

}

#pragma mark - MADDatabaseProtocol

- (void)resetAfterConnectionString:(NSString *)connectionString failedTest:(NSArray *)errors {
    [self resetForm];
    [self displayErrors:errors forConnectionString:connectionString];

}

- (void)displayErrors:(NSArray <__kindof NSError *> *)errors forConnectionString:(NSString *)connectionString {
    [MADConnectionViewController viewController: self displayErrors: errors completion: ^(BOOL success) {
        [MTKeyChain deleteKey:connectionString];
    }];
}

- (void)resetForm {
    [self enableNavigation];
    [self enableTextFields];
    self.navigationItem.rightBarButtonItem.enabled = YES;
    self.progressView.progress = 0.0000f;
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

+ (void)viewController:(id)viewController
         displayErrors:(NSArray <__kindof NSError *> *)errors
            completion:(void (^)(BOOL))completion {

    MADBlockAlertDidFinish handleAlertDidFinish;
    UIAlertController *alert;
    NSRange range;
    NSError *error;
    NSString *localizedDescription, *localizedFailureReason;
    NSArray <__kindof NSError *> *remaningErrors;
    
    error = errors.lastObject;
    
    range = NSMakeRange(0, errors.count > 0 ? errors.count - 1 : 0);
    remaningErrors = [errors subarrayWithRange:range];

    handleAlertDidFinish = ^(UIAlertAction *action) {

        if (remaningErrors.count > 0) {
            
            MADBlockCompletionStatus alertCompleted = ^(BOOL success) { completion(YES); };
            [MADConnectionViewController viewController:viewController
                                          displayErrors:remaningErrors
                                             completion:alertCompleted];
        } else {
            completion(YES);
        }
        
    };
    
    localizedDescription = error.localizedDescription.copy;
    localizedFailureReason = error.localizedFailureReason.copy;

    alert = [MADAlertController newAlertControllerErrorDisplayErrorWithTitle: localizedDescription
                                                                     message: localizedFailureReason
                                                               andCompletion: handleAlertDidFinish];

    [viewController presentViewController:alert animated:YES completion:nil];

}

+ (void)showLocalNotificationCreatedReportWithName:(NSString *)name {
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    NSString *reportIsReady = NSLocalizedString(@"Created report '%@.'",
                                                @"Created report '%@.'");
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
