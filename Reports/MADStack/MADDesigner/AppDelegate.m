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

#import "MADNavigationController.h"

#import "MADUpgradeManager.h"

#import "UIViewController+Designer.h"
#import "UITabBarController+Shared.h"
#import "MTVerificationController.h"

#import "MADQueryViewController.h"

#import "MADToolboxNavigationController.h"
#import "MADNavigationController.h"
#import "MADTransparentPresentationController.h"
#import "MADNavigationBarFixedSize.h"

#import "MADOperationInstallSampleDatabase.h"
#import "MADOperationInstallSampleDocument.h"

#import "MADDesignerFileExplorerViewController.h"

NSString * const MADAppConfigurationApplicationGroupsPrimary        = @"group.everydayapps.mad.primary";
NSString * const MADIdentifierFileLondon                            = @"London";
NSString * const MADIdentifierFileMusic                             = @"Music";
NSString * const MADAppConfigurationUserDefaultsSamplesInstalled    = @"MADAppConfigurationUserDefaultsSamplesInstalled";
NSString * const MTBundleDisplayName                                = @"CFBundleDisplayName";

NSString * const MADIDUser                                          = @"MADIDUser";

const CFStringRef MADKeyRevision = CFSTR("MADRevision");

//#import <MADFeedback/MADFeedbackFrustration.h>

#if MAD_DESIGNER
NSString *s = @"";
#endif

#if MAD_DESIGNER || MADWATCHKIT
NSString * const MADUbiquityIdentifier                                  = @"iCloud.com.everydayapps.mad.designer";
#elif MAD_VIEWER
NSString * const MADUbiquityIdentifier                                  = @"iCloud.com.everydayapps.mad.viewer";
#endif

NSString * const MADIdentifierGroup                                 = @"group.everydayapps.mad";

const char * MADQueueAppDelegate = "com.everydayapps.mad.designer.appdelegate";

const NSInteger MADTagAlertViewNewDocument = 3838;
const BOOL MADStateRestorationSupportEnabled = NO;  //If there is a chance it will be enabled,
                                                    //  load window in willFinishLaunchingWithOptions
                                                    //  otherwise load window in didFinishLaunchingWithOptions

@interface AppDelegate()
    <UIDocumentInteractionControllerDelegate>

@property (nonatomic, strong, readwrite) MADAppConfiguration *appConfiguration;
@property (readonly) MADNavigationController *navigationController;
@property (readonly) MADDesignerFileExplorerViewController *openFileViewController;
@property (nonatomic, strong) dispatch_queue_t appDelegateQueueSerial;
@property (nonatomic, strong) dispatch_queue_t appDelegateQueueBackground;
@property (nonatomic, strong, readwrite) NSUserDefaults *applicationUserDefaults;

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
    NSString *name = [NSString stringWithFormat:@"%@ %@", trademark, appName];
    return name;
}

- (NSString *)localizedName {
    NSString *trademark = [self trademark];
    NSString *appName = [self localizedApplicationNameSufixPart];
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

- (NSString *)applicationNameSufixPart {
    return @"Designer";
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

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    return YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:MADAppConfigurationApplicationGroupsPrimary];
    NSNumber *defaultSamplesInstalled = @(NO);
    NSNumber *defaultReportsInstalled = @(NO);
    NSNumber *defaultChinookInstalled = @(NO);
    NSDictionary *defaultsToRegister = @{MADUpgradeInstalledChinook: defaultChinookInstalled,
                                         MADUpgradeInstalledSamples : defaultReportsInstalled,
                                         MADAppConfigurationUserDefaultsSamplesInstalled : defaultSamplesInstalled,
                                         };
    [defaults registerDefaults:defaultsToRegister];
    self.applicationUserDefaults = defaults;
    
    if ([UIApplication instancesRespondToSelector:@selector(registerUserNotificationSettings:)]){
        UIUserNotificationSettings *notificationSettings = [UIUserNotificationSettings settingsForTypes: UIUserNotificationTypeAlert|UIUserNotificationTypeBadge|UIUserNotificationTypeSound
                                                                                             categories: nil];
        [application registerUserNotificationSettings:notificationSettings];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleNotificationKeyValueStoreDidChange:)
                                                 name: NSUbiquitousKeyValueStoreDidChangeExternallyNotification
                                               object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleNotificationUbiquityIdentityDidChange:)
                                                 name: NSUbiquityIdentityDidChangeNotification
                                               object: nil];
    
    [self initalizeAppearance];
    
    NSOperationQueue *operationQueueBackground = [[NSOperationQueue alloc] init];
    operationQueueBackground.underlyingQueue = self.appDelegateQueueBackground;
    
    NSOperation *getUserCloudPreferences = [[NSInvocationOperation alloc] initWithTarget:self.openFileViewController selector:@selector(getUserCloudPrefs) object:NULL];

    MADOperationInstallSampleDatabase *sampleDatabase = [[MADOperationInstallSampleDatabase alloc] init];
    MADOperationInstallSampleDocument *sampleDocumentMusic = [[MADOperationInstallSampleDocument alloc] initWithFilename:MADIdentifierFileLondon
                                                                                                           fileExtension:MADFileExtentionMobleApplicationDocument
                                                                                                         groupIdentifier:MADIdentifierGroup
                                                                                                             installFlag:MADUpgradeInstalledSamplesLondon];
    MADOperationInstallSampleDocument *sampleDatabaseLondon = [[MADOperationInstallSampleDocument alloc] initWithFilename:MADIdentifierFileMusic
                                                                                                            fileExtension:MADFileExtentionMobleApplicationDocument
                                                                                                          groupIdentifier:MADIdentifierGroup
                                                                                                              installFlag:MADUpgradeInstalledSamplesMusic];
    
    NSOperation *resetReceipt = [[NSInvocationOperation alloc] initWithTarget: [MTVerificationController sharedInstance]
                                                                     selector: @selector(resetReceipt) object: NULL];
    NSArray *addSampleData = @[getUserCloudPreferences, sampleDatabase, sampleDocumentMusic, sampleDatabaseLondon, resetReceipt];
    [operationQueueBackground addOperations:addSampleData waitUntilFinished:NO];

    return YES;
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
        
        UIAlertController *alert = success ? [UIAlertController addedDocument] : [UIAlertController error:error];
        [self.openFileViewController presentViewController:alert animated:YES completion:^{
            [self.openFileViewController.collectionView reloadData];
        }];
        
    } else {
        
        UIAlertController *alert = [UIAlertController error:error];
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
    [self.openFileViewController setRightBarButtonItemActivityIndicatorVisible:YES animated:YES];
}

- (void)hideActivityIndictor:(id)sender {
    [self.openFileViewController setRightBarButtonItemActivityIndicatorVisible:NO animated:YES];
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

- (void)initalizeAppearance {
    UIColor *tintColorWhite = [UIColor tintColorWhite];
    NSDictionary *titleTextAttributes = @{ NSForegroundColorAttributeName : tintColorWhite};
    [[UITabBarItem appearance] setTitleTextAttributes: titleTextAttributes forState: UIControlStateNormal];    //Make tab bar buttons white
    
#ifndef MADWATCHKIT
    [UINavigationBar appearanceWhenContainedIn:[MADNavigationController class], nil].barTintColor               = [UIColor tintColorBlue];
    [UINavigationBar appearanceWhenContainedIn:[MADToolboxNavigationController class], nil].barTintColor        = [UIColor clearColor];
    [UINavigationBar appearanceWhenContainedIn:[MADTransparentPresentationController class], nil].barTintColor  = [UIColor clearColor];
#endif
    
    [UINavigationBar appearanceWhenContainedIn:[QLPreviewController class], nil].barTintColor                       = [UIColor tintColorAnalogous4];
    [UINavigationBar appearanceWhenContainedIn:[MFMailComposeViewController class], nil].barTintColor               = [UIColor tintColorAnalogous4];
    
#ifndef MADWATCHKIT
    [UINavigationBar appearanceWhenContainedIn:[MADNavigationController class], nil].tintColor                   = tintColorWhite;
#endif
    
    [UINavigationBar appearanceWhenContainedIn:[UIViewController class], nil].tintColor                             = tintColorWhite;
    [UINavigationBar appearanceWhenContainedIn:[UINavigationController class], nil].tintColor                       = tintColorWhite;
    [UINavigationBar appearanceWhenContainedIn:[QLPreviewController class], nil].tintColor                          = [UIColor tintColorRed];
    [UINavigationBar appearanceWhenContainedIn:[MFMailComposeViewController class], nil].tintColor                  = [UIColor tintColorRed];
    [UIBarButtonItem appearanceWhenContainedIn:[UIToolbar class], nil].tintColor                                    = tintColorWhite;
    [UIBarButtonItem appearance].tintColor                                                                          = tintColorWhite;
    [UILabel appearanceWhenContainedIn:[UITableViewCell class], nil].highlightedTextColor                           = [UIColor edaOrange];
    [UILabel appearanceWhenContainedIn:[UICollectionViewCell class], nil].highlightedTextColor                      = [UIColor edaOrange];
    [UIImageView appearanceWhenContainedIn:[UICollectionViewCell class], nil].tintColor                             = [UIColor edaOrange];
    [UISegmentedControl appearanceWhenContainedIn:[UINavigationBar class], nil].tintColor                           = tintColorWhite;
    
}

- (void)handleNotificationUbiquityIdentityDidChange:(NSNotification *)notification {
    [self.navigationController popToRootViewControllerAnimated:YES];
    
    
    UIAlertController *signedOutController = [UIAlertController promotCloudSignOut:^(UIAlertAction *action) {
        [self.openFileViewController getUserCloudPrefs];
    }];
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        [self.openFileViewController presentViewController:signedOutController animated:YES completion:nil];
    }];

}

- (void)handleNotificationKeyValueStoreDidChange:(NSNotification *)notification {

}

#pragma mark - Convenience

- (MADNavigationController *)navigationController {
    return (MADNavigationController *)[UIApplication sharedApplication].windows.firstObject.rootViewController;
}

- (MADDesignerFileExplorerViewController *)openFileViewController {
    return (MADDesignerFileExplorerViewController *)self.navigationController.topViewController;
}

- (BOOL)sampleInstalled {
    return [[self applicationUserDefaults] boolForKey:MADAppConfigurationUserDefaultsSamplesInstalled];
}

- (void)installedSample {
    NSUserDefaults *userDefaults = [self applicationUserDefaults];
    [userDefaults setBool:YES forKey:MADAppConfigurationUserDefaultsSamplesInstalled];
}

- (NSString *)bundleDisplayName {
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:MTBundleDisplayName];
}


- (BOOL)isFirstLaunch {
    NSUserDefaults *userDefaults = [self applicationUserDefaults];
    BOOL firstLaunch = [userDefaults stringForKey:MADIDUser] == nil;
    if (firstLaunch) {
        dispatch_async(self.appDelegateQueueSerial, ^{
            NSUUID *uuid = [NSUUID UUID];
            [userDefaults setObject:uuid.UUIDString forKey:MADIDUser];
            [userDefaults synchronize];
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
