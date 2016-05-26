//
//  AppDelegate.m
//  Reports
//
//  Created by Michael Thomason on 1/2/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif


#import "AppDelegate.h"
#import <QuickLook/QLPreviewController.h>
#import <Foundation/NSString.h>

#import <MAD/MADConstants.h>
#import "NSUserDefaults+MADDesigner.h"

#import <MADCocoaExtensions/UIColor+EverydayApps.h>
#import <MADCocoaExtensions/UIAlertController+Constructors.h>

#import "MADOperationQueue.h"
#import "MADDesignerFileExplorerViewController.h"

#import "Constants.h"

#import "MADNavigationController.h"

#import "MADUpgradeManager.h"

#import "MTVerificationController.h"

#import "MADQueryViewController.h"

#import "MADInstallOperationSampleDatabase.h"
#import "MADInstallOperationSampleDocument.h"

#import <MAD/madlib.h>
#import <MAD/madmath.h>

@class MADTransparentPresentationController;
@class MFMailComposeViewController;

static NSString * const MADAppConfigurationApplicationGroupsPrimary        = @"group.everydayapps.mad.primary";
static NSString * const MADIdentifierFileLondon                            = @"London";
static NSString * const MADIdentifierFileMusic                             = @"Music";
static NSString * const MADAppConfigurationUserDefaultsSamplesInstalled    = @"MADAppConfigurationUserDefaultsSamplesInstalled";
static NSString * const MTBundleDisplayName                                = @"CFBundleDisplayName";
static NSString * const MADIDUser                                          = @"MADIDUser";

const CFStringRef MADKeyRevision = CFSTR("MADRevision");

#if MAD_DESIGNER
    NSString *s = @"";
#endif

const char * MADQueueAppDelegate = "com.everydayapps.mad.designer.appdelegate";

static inline UIUserNotificationType MADUserNotificationType();
static inline UIUserNotificationType MADUserNotificationType() {
    return (UIUserNotificationType)(UIUserNotificationTypeAlert |
                                    UIUserNotificationTypeBadge |
                                    UIUserNotificationTypeSound);
}

@interface AppDelegate()
    <UIDocumentInteractionControllerDelegate>

    @property (readonly) MADDesignerFileExplorerViewController *openFileViewController;
    @property (nonatomic, strong, readwrite) dispatch_queue_t appDelegateQueueSerial;

    @property (nonatomic, strong, readwrite) MADOperationQueue *operationQueueBackground;

@end

@implementation AppDelegate

#pragma mark - MADApplicationProtocol

- (NSString *)ubiquityIdentifier {
    return MADUbiquityIdentifier;
}

- (NSString *)groupIdentifier {
    return MADIdentifierGroup;
}

- (NSString *)name {
    NSString *trademark = [self trademark];
    NSString *appName = [self applicationNameSufixPart];
    NSString *name = [[NSString alloc] initWithFormat:@"%@ %@", trademark, appName];
    return name;
}

- (NSString *)localizedName {
    NSString *trademark = [self trademark];
    NSString *appName = [self localizedApplicationNameSufixPart];
    NSString *name = [[NSString alloc] initWithFormat:@"%@ %@", trademark, appName];
    return name;
}

- (NSString *)applicationIdentifier {
    return @"666001433";
}

- (NSString *)applicationBundleIdentifier {
    return @"com.everydayapps.mad.designer";
}

+ (NSString *)Trademark {
    return @"MAD";
}

- (NSString *)trademark {
    return [AppDelegate Trademark];
}

+ (NSString *)ApplicationNameSufixPart {
    return @"Designer";
}

- (NSString *)applicationNameSufixPart {
    return [AppDelegate ApplicationNameSufixPart];
}

- (NSString *)localizedApplicationNameSufixPart {
    return NSLocalizedString([self applicationNameSufixPart], [self applicationNameSufixPart]);
}

- (NSString *)versionNumber {
    NSString *version = CFBundleGetValueForInfoDictionaryKey(CFBundleGetMainBundle(),
                                                             kCFBundleVersionKey);
    return version;
}

- (NSString *)revisionNumber {
    NSString *version = CFBundleGetValueForInfoDictionaryKey(CFBundleGetMainBundle(),
                                                             MADKeyRevision);
    return version;
}

- (dispatch_queue_t)appDelegateQueueSerial {
    return !_appDelegateQueueSerial ?
        (_appDelegateQueueSerial = dispatch_queue_create(MADQueueAppDelegate,
                                                         DISPATCH_QUEUE_SERIAL)) :
        _appDelegateQueueSerial;
}

#pragma mark - Initialization

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
/*
    srand((unsigned)time(NULL));
    char *cr;
    int i=0, r;

    NSDate *methodStart, *methodFinish;
    NSTimeInterval executionTime;

    for (i=0; i<9000; i++) {
        r = abs(rand())%INT32_MAX;
        cr = tes1(r);
    }
    for (i=0; i<9000; i++) {
        r = abs(rand())%INT32_MAX;
        cr = tes2(r);
    }



    r = abs(rand())%INT32_MAX;
    methodStart = [NSDate date];
    
    for (i=0; i<90000000; i++) {
        cr = tes2(r);
    }
    
    
    methodFinish = [NSDate date];
    executionTime = [methodFinish timeIntervalSinceDate:methodStart];
    NSLog(@"executionTime = %f", executionTime);


    i=0;
    r = abs(rand())%INT32_MAX;
    methodStart = [NSDate date];
    
    for (i=0; i<90000000; i++) {
        cr = tes1(r);
    }
    
    
    methodFinish = [NSDate date];
    executionTime = [methodFinish timeIntervalSinceDate:methodStart];
    NSLog(@"executionTime = %f", executionTime);

    //NSUInteger i = UINT64_MAX;
    NSLog(@"%llu", UINT64_MAX);

*/
    NSUserDefaults *defaults;
    NSDictionary *defaultsToRegister;

    defaults = [NSUserDefaults newUserDefaultsMADDesigner];
    defaultsToRegister = [[NSDictionary alloc] initWithObjectsAndKeys:
                                    @NO, MADUpgradeInstalledChinook,
                                    @NO, MADUpgradeInstalledSamples,
                                    @NO, MADAppConfigurationUserDefaultsSamplesInstalled, nil];
    
    [defaults registerDefaults:defaultsToRegister];

    if ([UIApplication instancesRespondToSelector:@selector(registerUserNotificationSettings:)]){
        id notification = [UIUserNotificationSettings settingsForTypes: MADUserNotificationType()
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
    
    MADOperationQueue *operationQueueBackground;
    operationQueueBackground = [[MADOperationQueue alloc] init];
    
    NSOperation *getUserCloudPreferences;
    MADInstallOperationSampleDatabase *sampleDatabase;
    MADInstallOperationSampleDocument *sampleDocumentMusic;
    MADInstallOperationSampleDocument *sampleDatabaseLondon;
    NSOperation *resetReceipt;
    
    getUserCloudPreferences = [[NSInvocationOperation alloc] initWithTarget: self.openFileViewController
                                                                   selector: @selector(getUserCloudPrefs)
                                                                     object: NULL];
    
    sampleDatabase = [[MADInstallOperationSampleDatabase alloc] init];
    
    sampleDocumentMusic = [[MADInstallOperationSampleDocument alloc] initWithFilename: MADIdentifierFileLondon
                                                                        fileExtension: MADFileExtentionMobleApplicationDocument
                                                                      groupIdentifier: MADIdentifierGroup
                                                                          installFlag: MADUpgradeInstalledSamplesLondon];
    
    sampleDatabaseLondon = [[MADInstallOperationSampleDocument alloc] initWithFilename: MADIdentifierFileMusic
                                                                         fileExtension: MADFileExtentionMobleApplicationDocument
                                                                       groupIdentifier: MADIdentifierGroup
                                                                           installFlag: MADUpgradeInstalledSamplesMusic];
    
    resetReceipt = [[NSInvocationOperation alloc] initWithTarget: [MTVerificationController sharedInstance]
                                                        selector: @selector(resetReceipt)
                                                          object: NULL];
    
    [operationQueueBackground addOperation:getUserCloudPreferences];
    [operationQueueBackground addOperation:sampleDatabase];
    [operationQueueBackground addOperation:sampleDocumentMusic];
    [operationQueueBackground addOperation:sampleDatabaseLondon];
    [operationQueueBackground addOperation:resetReceipt];
    
    self.operationQueueBackground = operationQueueBackground;
    
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        @autoreleasepool {
            [MTVerificationController sharedInstance];
            [MADQueryViewController deleteCoreDataCache];
        }
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

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
/*
    NSURL *documentsDirectory = self.appConfiguration.filesController.documentDirectory;
    NSURL *destination = [documentsDirectory URLByAppendingPathComponent:url.lastPathComponent];
    NSError *error = nil;
    
    BOOL success = [[NSFileManager defaultManager] moveItemAtURL:url
                                                           toURL:destination error:&error];
    
    if (success) {
        
        UIAlertController *alert = success ? [UIAlertController newAlertControllerAddedDocument] :
                                             [UIAlertController newAlertControllerError:error];
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

- (UIInterfaceOrientationMask)application:(UIApplication *)application
  supportedInterfaceOrientationsForWindow:(UIWindow *)window {
    return window.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPhone ?
        UIInterfaceOrientationMaskAllButUpsideDown :
        UIInterfaceOrientationMaskAll;
}

- (BOOL)application:(UIApplication *)application shouldSaveApplicationState:(NSCoder *)coder {
    return NO;
}

- (BOOL)application:(UIApplication *)application shouldRestoreApplicationState:(NSCoder *)coder {
    return NO;
}

#pragma mark - Document Interaction Controller Delegate

- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller {
    UIWindow *window = self.window;
    UIViewController *rootViewController = window.rootViewController;
    return rootViewController;
}

- (void)documentInteractionControllerDidEndPreview:(UIDocumentInteractionController *)controller {
    NSError *error = nil;
    NSURL *itemToRemove = controller.URL;
    if (itemToRemove)
        [[NSFileManager defaultManager] removeItemAtURL:itemToRemove error:&error];
}

- (void)handleNotificationUbiquityIdentityDidChange:(NSNotification *)notification {
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
    
        UINavigationController *navController;
        navController = (UINavigationController *)[UIApplication sharedApplication].windows.firstObject.rootViewController;
        [navController popToRootViewControllerAnimated:YES];
        
        UIAlertController *signedOutController;
        signedOutController = [UIAlertController newAlertControlerNotifyCloudSignOut:^(UIAlertAction *action) {
            [self.openFileViewController getUserCloudPrefs];
        }];

        [self.openFileViewController presentViewController:signedOutController
                                                  animated:YES completion:nil];
    }];

}

- (void)handleNotificationKeyValueStoreDidChange:(NSNotification *)notification {

}

#pragma mark - Convenience

- (UIViewController *)openFileViewController {
    UIViewController *viewController;
    viewController = ((UINavigationController *)[UIApplication sharedApplication].windows.firstObject.rootViewController).topViewController;
    return viewController;
}

- (BOOL)isSampleInstalled {
    NSUserDefaults *userDefaults = [NSUserDefaults newUserDefaultsMADDesigner];
    BOOL result = [userDefaults boolForKey:MADAppConfigurationUserDefaultsSamplesInstalled];
    return result;
}

- (void)installedSample {
    NSUserDefaults *userDefaults = [NSUserDefaults newUserDefaultsMADDesigner];
    [userDefaults setBool:YES forKey:MADAppConfigurationUserDefaultsSamplesInstalled];
}

- (NSString *)bundleDisplayName {
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:MTBundleDisplayName];
}


- (BOOL)isFirstLaunch {
    NSUserDefaults *userDefaults = [NSUserDefaults newUserDefaultsMADDesigner];
    BOOL firstLaunch = [userDefaults stringForKey:MADIDUser] == nil;
    if (firstLaunch) {
        dispatch_async(self.appDelegateQueueSerial, ^{
            @autoreleasepool {
                NSUserDefaults *userDefaultsBackground;
                NSUUID *uuid = [NSUUID UUID];
                userDefaultsBackground = [NSUserDefaults newUserDefaultsMADDesigner];
                [userDefaultsBackground setObject:uuid.UUIDString forKey:MADIDUser];
                [userDefaultsBackground synchronize];
            }
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
