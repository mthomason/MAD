//
//  AppDelegate.m
//  Reports
//
//  Created by Michael Thomason on 1/2/12.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif


#import "MADViewerAppDelegate.h"

#import <Foundation/NSString.h>

#import <MADCocoaExtensions/MADAlertController.h>

#import "MADNavigationController.h"
#import "Constants.h"

#import "MTVerificationController.h"
#import "MADQueryViewController.h"

#import "MADExplorerController.h"

//@class MADTransparentPresentationController;

NSString * const MADAppConfigurationApplicationGroupsPrimary        = @"group.everydayapps.mad.primary";
NSString * const MADIDUser                                          = @"MADIDUser";

const CFStringRef MADKeyRevision = CFSTR("MADRevision");

#if MAD_DESIGNER
NSString *s = @"";
#endif

NSString * const MADUbiquityIdentifier                                  = @"iCloud.com.everydayapps.mad.designer";
NSString * const MADIdentifierGroup                                     = @"group.everydayapps.mad";

const char * MADQueueAppDelegate = "com.everydayapps.mad.designer.appdelegate";

@interface MADViewerAppDelegate()
    <UIDocumentInteractionControllerDelegate>

@property (readonly) MADNavigationController *navigationController;
@property (readonly) MADExplorerController *openFileViewController;
@property (nonatomic, strong, readwrite) dispatch_queue_t appDelegateQueueSerial;
@property (nonatomic, strong, readwrite) dispatch_queue_t appDelegateQueueBackground;
@property (nonatomic, strong, readwrite) NSUserDefaults *applicationUserDefaults;

@end

@implementation MADViewerAppDelegate

#pragma mark - MADApplicationProtocol

+ (NSString *)ubiquityIdentifier { return MADUbiquityIdentifier; }

+ (NSString *)groupIdentifier { return MADIdentifierGroup; }

- (NSString *)name {
    NSString *trademark = self.trademark;
    NSString *appName = self.applicationNameSufixPart;
    NSString *name = [NSString stringWithFormat:@"%@ %@", trademark, appName];
    return name;
}

- (NSString *)localizedName {
    NSString *trademark = self.trademark;
    NSString *appName = self.localizedApplicationNameSufixPart;
    NSString *name = [NSString stringWithFormat:@"%@ %@", trademark, appName];
    return name;
}

- (NSString *)applicationIdentifier {
    return @"666001433";
}

- (NSString *)applicationBundleIdentifier {
    return @"com.everydayapps.mad.designer";
}

- (NSString *)trademark {
    return @"MAD";
}

+ (NSString *)ApplicationNameSufixPart {
    return @"Designer";
}

- (NSString *)applicationNameSufixPart {
    return [MADViewerAppDelegate ApplicationNameSufixPart];
}

- (NSString *)localizedApplicationNameSufixPart {
    return NSLocalizedString([self applicationNameSufixPart], [self applicationNameSufixPart]);
}

- (NSString *)versionNumber {
    NSString *version = CFBundleGetValueForInfoDictionaryKey(CFBundleGetMainBundle(), kCFBundleVersionKey);
    return version;
}

- (NSString *)revisionNumber {
    NSString *version = CFBundleGetValueForInfoDictionaryKey(CFBundleGetMainBundle(), MADKeyRevision);
    return version;
}

+ (NSString *)bundleDisplayName { 
	<#code#>
}


+ (NSString *)bundleVersion { 
	<#code#>
}


- (NSString *)groupIdentifier { 
	<#code#>
}


+ (NSString *)humanReadableCopyright { 
	<#code#>
}


- (NSString *)ubiquityIdentifier { 
	return [MADViewerAppDelegate ubiquityIdentifier];
}


#pragma mark - Initialization

- (instancetype)init {
    if (self = [super init]) {
        dispatch_queue_t appDelegateQueueSerial = dispatch_queue_create(MADQueueAppDelegate, DISPATCH_QUEUE_SERIAL);
        self.appDelegateQueueSerial = appDelegateQueueSerial;

        dispatch_queue_t appDelegateQueueBackground = dispatch_queue_create(MADQueueAppDelegate, DISPATCH_QUEUE_SERIAL);
        self.appDelegateQueueBackground = appDelegateQueueBackground;
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: NSUbiquitousKeyValueStoreDidChangeExternallyNotification
                                                  object: nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: NSUbiquityIdentityDidChangeNotification
                                                  object: nil];
}

#pragma mark - Application Lifecycle

- (BOOL)application:(UIApplication *)application
                                    willFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    return YES;
}

- (BOOL)application:(UIApplication *)application
                                    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:MADAppConfigurationApplicationGroupsPrimary];
    self.applicationUserDefaults = defaults;
    
    if ([UIApplication instancesRespondToSelector:@selector(registerUserNotificationSettings:)]){
        UIUserNotificationSettings *notification;
        notification = [UIUserNotificationSettings settingsForTypes: UIUserNotificationTypeAlert |
                                                                     UIUserNotificationTypeBadge |
                                                                     UIUserNotificationTypeSound
                                                                 categories: nil];
        [application registerUserNotificationSettings:notification];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleNotificationKeyValueStoreDidChange:)
                                                 name: NSUbiquitousKeyValueStoreDidChangeExternallyNotification
                                               object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleNotificationUbiquityIdentityDidChange:)
                                                 name: NSUbiquityIdentityDidChangeNotification
                                               object: nil];
    
    
    NSOperationQueue *operationQueueBackground;
    NSOperation *resetReceipt;
    
    operationQueueBackground = [[NSOperationQueue alloc] init];
    operationQueueBackground.underlyingQueue = self.appDelegateQueueBackground;
    //Guess app delegate
    // can leak, but
    // this should be
    // removed from
    // underlying queue
    // at dealloc
    
    MTVerificationController *verificationController;
    verificationController = [MTVerificationController sharedInstance];
    resetReceipt = [[NSInvocationOperation alloc] initWithTarget: verificationController
                                                        selector: @selector(resetReceipt)
                                                          object: NULL];
    
    [operationQueueBackground addOperation:resetReceipt];

    return YES;
}

- (void)runOperations {

}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [MTVerificationController sharedInstance];
    });
    
    dispatch_async(self.appDelegateQueueSerial, ^{
        [MADQueryViewController deleteCoreDataCache];
    });
    
}

- (void)applicationWillResignActive:(UIApplication *)application { }

- (void)applicationDidEnterBackground:(UIApplication *)application { }

- (void)applicationWillEnterForeground:(UIApplication *)application {
    [[NSUbiquitousKeyValueStore defaultStore] synchronize];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Fix me... close open applications by calling delegate method from openFileViewController.
    //[self.appConfiguration cleanupBeforeTerminate];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
/*
    NSURL *documentsDirectory = self.appConfiguration.filesController.documentDirectory;
    NSURL *destination = [documentsDirectory URLByAppendingPathComponent:url.lastPathComponent];
    NSError *error = nil;
    
    BOOL success = [[NSFileManager defaultManager] moveItemAtURL:url toURL:destination error:&error];
    
    if (success) {
        
        UIAlertController *alert = success ? [UIAlertController newAlertControllerAddedDocument] : [MADAlertController newAlertControllerError:error];
        [self.openFileViewController presentViewController:alert animated:YES completion:^{
            [self.openFileViewController.collectionView reloadData];
        }];
        
    } else {
        
        UIAlertController *alert = [UIAlertController newAlertControllerError:error];
        [self.openFileViewController presentViewController:alert animated:YES completion:^{
            [self.openFileViewController.collectionView reloadData];
        }];
        
    }
    return success;*/
    // FIXME: Open a fucking file, YO!!!
    return NO;
}

- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window {
    return window.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPhone ?
        UIInterfaceOrientationMaskAllButUpsideDown :
        UIInterfaceOrientationMaskAll;
}

- (void)displayActivityIndictor:(id)sender {
    //[self.openFileViewController setRightBarButtonItemActivityIndicatorVisible:YES animated:YES];
}

- (void)hideActivityIndictor:(id)sender {
    //[self.openFileViewController setRightBarButtonItemActivityIndicatorVisible:NO animated:YES];
}

- (BOOL)application:(UIApplication *)application shouldSaveApplicationState:(NSCoder *)coder {
    return NO;
}

- (BOOL)application:(UIApplication *)application shouldRestoreApplicationState:(NSCoder *)coder {
    return NO;
}

#pragma mark - Document Interaction Controller Delegate

- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller {
    return self.window.rootViewController;
}

- (void)documentInteractionControllerDidEndPreview:(UIDocumentInteractionController *)controller {
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtURL:controller.URL error:&error];
}

- (void)handleNotificationUbiquityIdentityDidChange:(NSNotification *)notification {
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)handleNotificationKeyValueStoreDidChange:(NSNotification *)notification {

}

#pragma mark - Convenience

- (MADNavigationController *)navigationController {
    return (MADNavigationController *)[UIApplication sharedApplication].windows.firstObject.rootViewController;
}

- (MADExplorerController *)openFileViewController {
    return (MADExplorerController *)self.navigationController.topViewController;
}

- (NSString *)bundleDisplayName {
	return  [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
}


- (BOOL)isFirstLaunch {
    BOOL firstLaunch = [self.applicationUserDefaults stringForKey:MADIDUser] == nil;
    if (firstLaunch) {
        dispatch_async(self.appDelegateQueueSerial, ^{
            NSUUID *uuid = [NSUUID UUID];
            [self.applicationUserDefaults setObject:uuid.UUIDString forKey:MADIDUser];
            [self.applicationUserDefaults synchronize];
        });
    }
    return firstLaunch;
}

- (void)runHandlerOnFirstLaunch:(void (^)(void))firstLaunchHandler
             subsquientLaunches:(void (^)(void))subsequentLaunch
                    everyLaunch:(void (^)(void))everyLaunch {
    if (self.isFirstLaunch) {
        firstLaunchHandler();
    } else {
        subsequentLaunch();
    }
    everyLaunch();
}

@end
