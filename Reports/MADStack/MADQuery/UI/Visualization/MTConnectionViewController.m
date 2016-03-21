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

#import <MAD/MADocument.h>
#import <MAD/MTDatabase.h>
#import <MAD/MTDatabaseConnection.h>
#import <MAD/MTErrorContainer.h>

#import <MAD/MTKeyChain.h>
#import <MAD/MTDataTable+Factory.h>
#import <MAD/MTQueryTest.h>
#import <MAD/MADCredential.h>

#import <MADFileManager/MADFileUtilities.h>
#import "MADOperationQueue.h"
#import "MADBarButtonItem.h"
#import "MADNavigationBarTitleView.h"
//#import "MADKeyChainGetCredentials.h"
//#import "MADKeyChainSaveCredentials.h"
#import "MADKeyChainOperationGet.h"
#import "MADPromptOperationCredentials.h"
#import "MADPromptOperationPassword.h"

#import "MADOperationConditionMissingResultString.h"
#import "MADOperationConditionHasResultString.h"

#import <MADCocoaExtensions/UIColor+EverydayApps.h>
#import "UIApplication+Extras.h"

#import "MADGetCredentialsOperation.h"

static NSString * const MADConnectionViewControllerDefaultPrompt = @"Each report requires a database connection.";
static NSString * const MADConnectionViewControllerDefaultTitle = @"Database Settings";

@interface MADConnectionViewController()
    <MADocumentDelegate, MTDatabaseProtocol>

    @property (nonatomic, weak) IBOutlet UITableViewCell *tableViewCellDocumentName;
    @property (nonatomic, weak) IBOutlet UITableViewCell *tableViewCellHost;
    @property (nonatomic, weak) IBOutlet UITableViewCell *tableViewCellPort;
    @property (nonatomic, weak) IBOutlet UITableViewCell *tableViewCellDatabase;

    @property (nonatomic, weak) IBOutletCollection(UITableViewCell) NSArray *tableViewCells;

    @property (nonatomic, weak) IBOutlet UITextField *textFieldHost;
    @property (nonatomic, weak) IBOutlet UITextField *textFieldPort;
    @property (nonatomic, weak) IBOutlet UITextField *textFieldDatabase;
    @property (nonatomic, weak) IBOutlet UITextField *textFieldReportName;

    @property (nonatomic, strong) UIBarButtonItem *holderButton;
    @property (nonatomic, strong) UIProgressView *progressView;

    @property (nonatomic, strong) MADocument *docToSave;
    @property (nonatomic, strong) MTDatabaseConnection *databaseConnection;

    @property (nonatomic, strong) MTDatabase *databaseTest;
    @property (nonatomic, strong) MTDataTable *datatableTest;   // Holds datatable since used
                                                                //  in static function

@end

@implementation MADConnectionViewController

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIProgressView *progressView = [MADConnectionViewController progressViewWithWidth:self.tableView.frame.size.width];
    [self.tableView addSubview:progressView];
    self.progressView = progressView;
    
    self.navigationItem.prompt = NSLocalizedString(MADConnectionViewControllerDefaultPrompt, MADConnectionViewControllerDefaultPrompt);
    self.title = NSLocalizedString(MADConnectionViewControllerDefaultTitle, MADConnectionViewControllerDefaultTitle);
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

- (MADCredential *)getCredentialsForKey:(NSString *)key {

    MADOperationQueue *credentialQueue = [[MADOperationQueue alloc] init];
    //credentialQueue.maxConcurrentOperationCount = 2;
    
    //NSString *keyUsername = [MTKeyChain keyForUsernameWithMainKey: key];
    //NSString *keyPassword = [MTKeyChain keyForPasswordWithMainKey: key];

    // Operation: Read username.
    // -------------------------
    
    MADGetCredentialsOperation *getCredentialsOperation = [[MADGetCredentialsOperation alloc] initWithKey:key viewController:self];
    [credentialQueue addOperation:getCredentialsOperation];
    //[credentialQueue waitUntilAllOperationsAreFinished];
    
    /*
    MADKeyChainOperationGet *getUsername = [[MADKeyChainOperationGet alloc] initWithKey:keyUsername];
    getUsername.readOperationType = username;

    
    // Operation: Prompt for username if condition is met.
    // ---------------------------------------------------
    MADPromptOperationCredentials *promptCredntials = [[MADPromptOperationCredentials alloc] initWithViewController:self];
    [promptCredntials addDependency:getUsername];
    
    // Condition: Username is missing.
    // ---------------------------------------------------
    MADOperationConditionMissingResultString *conditionReadUsernameFailed = [[MADOperationConditionMissingResultString alloc] initWithKey:keyUsername];
    [promptCredntials addCondition:conditionReadUsernameFailed];
    
    // Operation: Read password
    // ---------------------------------------------------
    MADKeyChainOperationGet *getPassword = [[MADKeyChainOperationGet alloc] initWithKey:keyPassword];
    [getPassword addDependency:getUsername];

    // Condition: Username is found.
    // ---------------------------------------------------
    MADOperationConditionHasResultString *conditionReadUsername = [[MADOperationConditionHasResultString alloc] initWithKey:keyUsername];
    [getPassword addCondition:conditionReadUsername];

    // Condition: Password is missing.
    // ---------------------------------------------------
    MADOperationConditionMissingResultString *conditionReadPasswordFailed = [[MADOperationConditionMissingResultString alloc] initWithKey:keyPassword];

    // Operation: Prompt password
    // ---------------------------------------------------
    MADPromptOperationPassword *promptPassword = [[MADPromptOperationPassword alloc] initWithViewController:self];
    [promptPassword addDependency:getUsername];
    [promptPassword addDependency:getPassword];
    [promptPassword addCondition:conditionReadUsername];
    [promptPassword addCondition:conditionReadPasswordFailed];
    
    */
    
    /*
    
    getPassword.readOperationType = password;
    [promptCredntials addDependency:getPassword];
    
    MADPromptOperationPassword *promptPassword = [[MADPromptOperationPassword alloc] initWithViewController:self];
    [promptPassword addDependency:getUsername];
    [promptPassword addDependency:getPassword];
    [promptPassword addDependency:promptCredntials];

    [credentialQueue addOperation:getUsername];
    [credentialQueue addOperation:getPassword];
    [credentialQueue addOperation:promptCredntials];
    [credentialQueue addOperation:promptPassword];
    
    
    */
    //MADKeyChainGetCredentials *cg = [[MADKeyChainGetCredentials alloc] initWithKey:key viewController:self];
    //MADKeyChainSaveCredentials *cs = [[MADKeyChainSaveCredentials alloc] initWithKey:key viewController:self];
    
    //[cs addDependency:cg];
    //[credentialQueue addOperation:cg];
    //[credentialQueue addOperation:cs];

    
    //[credentialQueue waitUntilAllOperationsAreFinished];
    
    //MADCredential *credentials = [[MADCredential alloc] initWithUsername:getUsername.result andPassword:getPassword.result];
    //return credentials;
    
    return nil;
}

- (IBAction)save:(id)sender {
    
    [self removeKeyboard];
    [self disableTextFields];
    
    self.navigationItem.prompt = @"Importing schema.";
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    [self disableNavigation];
    
    MADBarButtonItem *barButtonItem = [[MADBarButtonItem alloc] initWithBarButtonSystemItem: MADBarButtonSystemItemActivity
                                                                                     target: nil
                                                                                     action: nil];
    [self.navigationItem setRightBarButtonItem:barButtonItem animated:YES];
    
    NSAssert(sender != nil, @"%s Sender is nil.", __PRETTY_FUNCTION__);
    
    NSString *filename = [self.textFieldReportName.text stringByAppendingPathExtension:MADFileExtentionMobleApplicationDocument];
    NSURL *desiredUrl = [self.saveFileDelegate.documentDirectory URLByAppendingPathComponent: filename isDirectory:NO];
    NSURL *uniqueURL = [MADFileUtilities uniqueURLForURL: desiredUrl];
    

    //Create MADocument File and Remove Cache
    MADocument *doc = [[MADocument alloc] initWithFileURL: uniqueURL];
    doc.documentDelegate = self;
    [doc removeGuts];
    self.docToSave = doc;
    
    
    //Create a database connection
    MTDatabaseConnection *databaseConnection = [MTDatabaseConnection databaseConnectionFactoryWithType:self.databaseType
                                                                                                  host:self.textFieldHost.text
                                                                                              database:self.textFieldDatabase.text
                                                                                                  port:self.textFieldPort.text.integerValue];
    self.databaseConnection = databaseConnection;
    
    
    [self getCredentialsForKey: databaseConnection.connectionString];

    
    
    
    /*
    
    
    
    //Mark the start of a background task
    __block UIBackgroundTaskIdentifier bgTask = [[UIApplication sharedApplication] requestBackgroundTask];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible: YES];

    //Test the connection
    NSArray *errors = NULL;
    bool success = [self testConnection:databaseConnection withErrors:&errors];

    if (success) {
        
        MADConnectionViewController * __weak weakself = self;
        MADocument *document = self.docToSave;
        [document addConnection:self.databaseConnection status:^(NSString *readStatus, float progress) {
            
            MADConnectionViewController *strongself = weakself;
            strongself.navigationItem.prompt = readStatus;
            strongself.progressView.progress = progress;
            
        } completion:^(BOOL addConnectionSuccess, MTErrorContainer *errorContainer) {
            
            __strong MADConnectionViewController *strongself = weakself;
            NSNumber *backgroundTask = @(bgTask);
            
            if (addConnectionSuccess) {
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        
                        [strongself saveAndCloseNewDocumentWithName: strongself.docToSave.fileURL.lastPathComponent
                                                  andBackgroundTask: backgroundTask];
                        
                    });
                });
                
                
            } else {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        
                        [strongself closeAndDeleteWithErrors:errorContainer
                                            connectionString:strongself.databaseConnection.connectionString
                                           andBackgroundTask:backgroundTask];
                        
                    });
                });
            }
            
        }];
        
    } else {
        [self resetAfterConnectionString: self.databaseConnection.connectionString
                              failedTest: errors];
    }
    
    errors = NULL;
 
    
    
    
    */
}

- (bool)testConnection:(MTDatabaseConnection *)connection withErrors:(NSArray * __autoreleasing *)errors {
    
    MTQuery *queryTest = [[MTQueryTest alloc] initWithObject: connection];
    NSNumber *typeKey = @(MTDataTableTypeOfTable);
    NSNumber *type = @(MTDataTableTypeVirtual);
    NSNumber *objectIdKey = @(MTDataTableObjectId);
    NSNumber *objectIdV =  @(connection.hash);
    NSDictionary *parameters = @{typeKey : type, objectIdKey : objectIdV};
    MTDataTable *datatable = [MTDataTable dataTableFactory:parameters];
    
    self.datatableTest = datatable;
    
    MTDatabase *db = [MTDatabase databaseFactory:connection];
    db.delegate = self;
    queryTest.database = db;
    self.databaseTest = db;
    
    NSError * __autoreleasing error = NULL;
    bool success = [queryTest.database executeQuery:queryTest withError:&error];
    if (!success && errors == NULL) {
        *errors = error ? [queryTest.database.errors arrayByAddingObject:error] : [NSArray arrayWithArray:queryTest.database.errors];
    }
    return success;
}

#pragma mark - MTDatabaseProtocol

- (MADCredential *)getCredentialsForDatabase:(MTDatabase *)database andKey:(NSString *)key {
    /*
    NSOperationQueue *credentialQueue = [[NSOperationQueue alloc] init];
    credentialQueue.maxConcurrentOperationCount = 1;
    
    MADKeyChainGetCredentials *cg = [[MADKeyChainGetCredentials alloc] initWithKey:key viewController:self];
    MADKeyChainSaveCredentials *cs = [[MADKeyChainSaveCredentials alloc] initWithKey:key viewController:self];
    
    [cs addDependency:cg];
    [credentialQueue addOperation:cg];
    [credentialQueue addOperation:cs];
    [credentialQueue waitUntilAllOperationsAreFinished];
    MADCredential *credentials = cg.credential.copy;
    */
    MADCredential *credentials = nil;
    return credentials;
}

- (MTDataTable *)dataTableForQuery:(MTQuery *)query {
    return [self datatableTest];
}

- (void)resetAfterConnectionString:(NSString *)connectionString
                        failedTest:(NSArray *)errors {
    [self resetForm];
    [self displayErrors:errors forConnectionString:connectionString];

}

- (void)displayErrors:(NSArray *)errors
  forConnectionString:(NSString *)connectionString {
    [MADConnectionViewController viewController: self
                                 displayErrors: errors
                                    completion: ^(BOOL success) {
                                        [[MTKeyChain sharedObject] deleteKey:connectionString];
                                    }];
}

- (void)closeAndDeleteWithErrors:(MTErrorContainer *)errorContainer
                connectionString:(NSString *)connectionString
               andBackgroundTask:(NSNumber *)backgroundTask {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_sync(dispatch_get_main_queue(), ^{
            
            [self showErrorLog:errorContainer];
            [self resetForm];
            [[MTKeyChain sharedObject] deleteKey:connectionString];
            
            [self.docToSave closeAndDelete:^(BOOL success, NSError *error) {
                
                self.navigationItem.rightBarButtonItem.enabled = YES;
                [self enableNavigation];
                
                if (error != nil) {
                    UILocalNotification *notification = [[UILocalNotification alloc] init];
                    NSString *localizedErrorString = NSLocalizedString(@"Error: %@. Please try again.", @"Error: %@. Please try again.");
                    notification.alertBody = [NSString stringWithFormat:localizedErrorString, error.localizedDescription];
                    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
                }
                
                [self enableTextFields];
                self.navigationItem.prompt = NSLocalizedString(MADConnectionViewControllerDefaultPrompt, MADConnectionViewControllerDefaultPrompt);
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
                    
                    [[UIApplication sharedApplication] handoffBackground:backgroundTask];
                    
                });
            }];
            
        });
    });
}

- (void)saveAndCloseNewDocumentWithName:(NSString *)name
                      andBackgroundTask:(NSNumber *)backgroundTask {
    [self saveCloseAndExitWithCompletion:^(BOOL success, NSError *error) {
        [self resetForm];
        [MADConnectionViewController showLocalNotificationCreatedReportWithName:name];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            [[UIApplication sharedApplication] handoffBackground:backgroundTask];
        });
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

    [UIAlertController alertControllerWithTitle: error.localizedDescription
                                                                   message: error.localizedFailureReason
                                                            preferredStyle: UIAlertControllerStyleAlert];
    
    NSRange range = NSMakeRange(0, errors.count > 0 ? errors.count - 1 : 0);
    NSArray *remaningErrors = [errors subarrayWithRange:range];
    UIAlertController *alert = [UIAlertController errorDisplayErrorWithTitle:error.localizedDescription
                                                                     message:error.localizedFailureReason
                                                               andCompletion:^(UIAlertAction *action) {
                                                                   if (remaningErrors.count > 0) {
                                                                       [MADConnectionViewController viewController:viewController
                                                                                                    displayErrors:remaningErrors
                                                                                                       completion:^(BOOL success) {
                                                                                                           completion(YES);
                                                                                                       }];
                                                                   } else {
                                                                       completion(YES);
                                                                   }
                                                               }];

    [viewController presentViewController:alert animated:YES completion:nil];

}

- (void)saveCloseAndExitWithCompletion:(void (^)(BOOL, NSError *))completion {
    MADConnectionViewController * __weak weakself = self;
    
    [self.docToSave saveToURL: self.docToSave.fileURL
             forSaveOperation: UIDocumentSaveForCreating
            completionHandler: ^(BOOL success) {
                
                MADConnectionViewController *strongself = weakself;
                MADConnectionViewController * __weak weakself1 = strongself;
                
                if (success) {
                    [weakself1.docToSave closeWithCompletionHandler:^(BOOL successClose) {
                        
                        MADConnectionViewController *strongself1 = weakself1;
                        
                        [strongself1 finishDocument];
                        completion(successClose, nil);
                        
                    }];
                }
            }];
}

- (void)finishDocument {
    [self.delegate viewControllerDidFinish: self];
    self.navigationItem.prompt = NSLocalizedString(MADConnectionViewControllerDefaultPrompt, MADConnectionViewControllerDefaultPrompt);
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
