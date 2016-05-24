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

#import <UIKit/UIApplication.h>
#import <QuickLook/QLPreviewController.h>
#import <Foundation/NSString.h>

#import <MAD/MADConstants.h>

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
    <UIApplicationDelegate, UIDocumentInteractionControllerDelegate>

    @property (readonly) MADDesignerFileExplorerViewController *openFileViewController;
    @property (nonatomic, strong, readwrite) dispatch_queue_t appDelegateQueueSerial;
    @property (nonatomic, strong, readwrite) NSUserDefaults *applicationUserDefaults;

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
    NSString *version = CFBundleGetValueForInfoDictionaryKey(CFBundleGetMainBundle(), kCFBundleVersionKey);
    return version;
}

- (NSString *)revisionNumber {
    NSString *version = CFBundleGetValueForInfoDictionaryKey(CFBundleGetMainBundle(), MADKeyRevision);
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

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    return YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:MADAppConfigurationApplicationGroupsPrimary];
    
    NSDictionary *defaultsToRegister = [[NSDictionary alloc] initWithObjectsAndKeys:
                                        @NO, MADUpgradeInstalledChinook,
                                        @NO, MADUpgradeInstalledSamples,
                                        @NO, MADAppConfigurationUserDefaultsSamplesInstalled, nil];
    
    [defaults registerDefaults:defaultsToRegister];
    self.applicationUserDefaults = defaults;
    
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
    
    [self initalizeAppearance];
    
    MADOperationQueue *operationQueueBackground = [[MADOperationQueue alloc] init];
    NSOperation *getUserCloudPreferences = [[NSInvocationOperation alloc] initWithTarget: self.openFileViewController
                                                                                selector: @selector(getUserCloudPrefs)
                                                                                  object: NULL];
    
    MADInstallOperationSampleDatabase *sampleDatabase = [[MADInstallOperationSampleDatabase alloc] init];
    
    MADInstallOperationSampleDocument *sampleDocumentMusic;
    sampleDocumentMusic = [[MADInstallOperationSampleDocument alloc] initWithFilename: MADIdentifierFileLondon
                                                                        fileExtension: MADFileExtentionMobleApplicationDocument
                                                                      groupIdentifier: MADIdentifierGroup
                                                                          installFlag: MADUpgradeInstalledSamplesLondon];
    
    MADInstallOperationSampleDocument *sampleDatabaseLondon;
    sampleDatabaseLondon = [[MADInstallOperationSampleDocument alloc] initWithFilename: MADIdentifierFileMusic
                                                                         fileExtension: MADFileExtentionMobleApplicationDocument
                                                                       groupIdentifier: MADIdentifierGroup
                                                                           installFlag: MADUpgradeInstalledSamplesMusic];
    
    NSOperation *resetReceipt = [[NSInvocationOperation alloc] initWithTarget: [MTVerificationController sharedInstance]
                                                                     selector: @selector(resetReceipt)
                                                                       object: NULL];

    NSArray *addSampleData = [[NSArray alloc] initWithObjects: getUserCloudPreferences,
                                                               sampleDatabase,
                                                               sampleDocumentMusic,
                                                               sampleDatabaseLondon,
                                                               resetReceipt, nil];

    [operationQueueBackground addOperations:addSampleData waitUntilFinished:NO];

    self.operationQueueBackground = operationQueueBackground;
    
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [MTVerificationController sharedInstance];
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

    //Make tab bar buttons white
    UIColor *madColor4 = [MADColorEverydayApps newColorAnalogous4];
    

    UITabBarItem *tabBarItemAppearance =                [UITabBarItem appearance];
    UIBarButtonItem *barButtonItem =                    [UIBarButtonItem appearance];
    UINavigationBar *navigationBarAppearance =          [UINavigationBar appearance];
    
    UINavigationBar *navigationBarQLPreviewAppearance = [UINavigationBar appearanceWhenContainedIn:[QLPreviewController class], nil];
    UINavigationBar *navigationBarViewController =      [UINavigationBar appearanceWhenContainedIn:[UIViewController class], nil];
    UINavigationBar *navigationBarNavigationBar =       [UINavigationBar appearanceWhenContainedIn:[UINavigationController class], nil];
    UIBarButtonItem *barButtonItemToolbar =             [UIBarButtonItem appearanceWhenContainedIn:[UIToolbar class], nil];
    UISegmentedControl *segmentedControl =              [UISegmentedControl appearanceWhenContainedIn:[UINavigationBar class], nil];
    
    #ifndef MADWATCHKIT
        [UINavigationBar appearanceWhenContainedIn:[MADNavigationController class], nil].barTintColor               = [MADColorEverydayApps newColorBlue];
    #endif
    

    navigationBarQLPreviewAppearance.barTintColor   = madColor4;
    
    UIColor *whiteColor = [MADColorEverydayApps newColorWhite];
    navigationBarViewController.tintColor           = whiteColor;
    navigationBarNavigationBar.tintColor            = whiteColor;
    barButtonItemToolbar.tintColor                  = whiteColor;
    barButtonItem.tintColor                         = whiteColor;
    segmentedControl.tintColor                      = whiteColor;

    id titleTextAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
                                                    whiteColor, NSForegroundColorAttributeName, nil];
    [tabBarItemAppearance setTitleTextAttributes: titleTextAttributes
                                        forState: UIControlStateNormal];
    navigationBarAppearance.titleTextAttributes = titleTextAttributes;

    UIColor *redColor = [MADColorEverydayApps newColorRed];
    navigationBarQLPreviewAppearance.tintColor = redColor;
    
    #ifndef MADWATCHKIT
        [UINavigationBar appearanceWhenContainedIn:[MADNavigationController class], nil].tintColor = whiteColor;
    #endif
    
    UIColor *orangeColor = [MADColorEverydayApps newColorOrange];
    UILabel *labelInTableCell = [UILabel appearanceWhenContainedIn:[UITableViewCell class], nil];
    labelInTableCell.highlightedTextColor       = orangeColor;

    UILabel *labelInCollectionCell = [UILabel appearanceWhenContainedIn:[UICollectionViewCell class], nil];
    labelInCollectionCell.highlightedTextColor  = orangeColor;
    
    UIImageView *imageInCollectionViewCell = [UIImageView appearanceWhenContainedIn:[UICollectionViewCell class], nil];
    imageInCollectionViewCell.tintColor         = orangeColor;
    
}

- (void)handleNotificationUbiquityIdentityDidChange:(NSNotification *)notification {
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
    
        UINavigationController * __weak navController = (UINavigationController *)[UIApplication sharedApplication].windows.firstObject.rootViewController;
        [navController popToRootViewControllerAnimated:YES];
        
        UIAlertController *signedOutController = [UIAlertController newAlertControlerNotifyCloudSignOut:^(UIAlertAction *action) {
            [self.openFileViewController getUserCloudPrefs];
        }];

        [self.openFileViewController presentViewController:signedOutController animated:YES completion:nil];
    }];

}

- (void)handleNotificationKeyValueStoreDidChange:(NSNotification *)notification {

}

#pragma mark - Convenience

- (UIViewController *)openFileViewController {
    UIViewController * viewController = ((UINavigationController *)[UIApplication sharedApplication].windows.firstObject.rootViewController).topViewController;

    return viewController;
}

- (BOOL)isSampleInstalled {
    return [self.applicationUserDefaults boolForKey:MADAppConfigurationUserDefaultsSamplesInstalled];
}

- (void)installedSample {
    [self.applicationUserDefaults setBool:YES forKey:MADAppConfigurationUserDefaultsSamplesInstalled];
}

- (NSString *)bundleDisplayName {
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:MTBundleDisplayName];
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
