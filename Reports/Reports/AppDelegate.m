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
#import "MADAppConfiguration.h"
#import "MADConstants.h"

#import "MADNavigationController.h"

#import "MADOpenFileViewController.h"

#import <MADFileManager/MADFilesController.h>
#import <MADFileManager/MADFileUtilities.h>


#import "MADUpgradeManager.h"

#import "UIAlertController+Constructors.h"
#import "UIViewController+Designer.h"
#import "UITabBarController+Shared.h"
#import "MTVerificationController.h"

#import "MADQueryViewController.h"
#import "UIColor+EverydayApps.h"

#import "MADToolboxNavigationController.h"
#import "MADNavigationController.h"
#import "MADTransparentPresentationController.h"
#import "MADNavigationBarFixedSize.h"


//#import <MADFeedback/MADFeedbackFrustration.h>

#if MAD_DESIGNER
NSString *s = @"";
#endif

const char * MADQueueAppDelegate = "com.everydayapps.mad.designer.appdelegate";

const NSInteger MADTagAlertViewNewDocument = 3838;
const BOOL MADStateRestorationSupportEnabled = NO;  //If there is a chance it will be enabled,
                                                    //  load window in willFinishLaunchingWithOptions
                                                    //  otherwise load window in didFinishLaunchingWithOptions

@interface AppDelegate()
    <UIDocumentInteractionControllerDelegate>

@property (nonatomic, strong, readwrite) MADAppConfiguration *appConfiguration;
@property (readonly) MADNavigationController *navigationController;
@property (readonly) MADOpenFileViewController *openFileViewController;
@property (nonatomic, strong) dispatch_queue_t appDelegateQueue;

@end

@implementation AppDelegate

/*static const unsigned char keyEncryption[] = {
    0x19, 0xdf, 0x8a, 0xc1, 0x0a, 0x25, 0x38, 0x57,
    0x06, 0x77, 0x6d, 0xd6, 0xbb, 0x5b, 0xd3, 0x21,
    0xdb, 0x46, 0xa5, 0xfd, 0x1e, 0xbe, 0x91, 0x69,
    0x8c, 0x0a, 0x18, 0x2b, 0xfb, 0x3f, 0x34, 0x06
};*/

#pragma mark - Initialization

- (instancetype)init {

    if (self = [super init]) {
        dispatch_queue_t appDelegateQueue = dispatch_queue_create(MADQueueAppDelegate, DISPATCH_QUEUE_SERIAL);
        self.appDelegateQueue = appDelegateQueue;
    }
    
    return self;
}

- (void)dealloc {
    [self removeObservers];
}

#pragma mark - Application Lifecycle

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    return YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    [AppDelegate registerForNotifications:application];

    [self addObservers];
    
    [self initalizeAppearance];
    MADAppConfiguration *appConfiguration = [[MADAppConfiguration alloc] init];
    [appConfiguration runHandlerOnFirstLaunch:^{
        [self getUserCloudPrefs];
    } subsquientLaunches:^{
        [self getUserCloudPrefsSubsquient];
    } everyLaunch:^{
        [MADUpgradeManager installSamples];
        dispatch_async(self.appDelegateQueue, ^{
           dispatch_sync(dispatch_get_main_queue(), ^{
               [[MTVerificationController sharedInstance] resetReceipt];
           });
        });
    }];
    self.appConfiguration = appConfiguration;

    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [MTVerificationController sharedInstance];
    });
    
    dispatch_async(self.appDelegateQueue, ^{
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
    //[[MADAppConfiguration mainInstance] cleanupBeforeTerminate];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    
    NSURL *documentsDirectory = [MADAppConfiguration mainInstance].filesController.documentDirectory;
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
    return success;
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

#pragma mark - Notifications

- (void)addObservers {
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleNotificationKeyValueStoreDidChange:)
                                                 name: NSUbiquitousKeyValueStoreDidChangeExternallyNotification
                                               object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleNotificationUbiquityIdentityDidChange:)
                                                 name: NSUbiquityIdentityDidChangeNotification
                                               object: nil];
}

- (void)removeObservers {
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: NSUbiquitousKeyValueStoreDidChangeExternallyNotification
                                                  object: nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: NSUbiquityIdentityDidChangeNotification
                                                  object: nil];
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
        [self getUserCloudPrefs];
    }];
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        [self.openFileViewController presentViewController:signedOutController animated:YES completion:nil];
    }];

}

- (void)handleNotificationKeyValueStoreDidChange:(NSNotification *)notification {

}

#pragma mark - Convenience

- (void)getUserCloudPrefs {

    dispatch_async(self.appDelegateQueue, ^{

        MADAppStorageState storageState = [MADAppConfiguration mainInstance].storageState;
        if (storageState.cloudAvailable) {
            
            if (storageState.storageOption == MADAppStorageCloud) {
                
                void (^activityIndicatorStart)() = ^ {
                    [self.openFileViewController setRightBarButtonItemActivityIndicatorVisible:YES animated:YES];
                };
                void (^activityIndicatorStop)() = ^ {
                    [self.openFileViewController setRightBarButtonItemActivityIndicatorVisible:NO animated:YES];
                };
                
                void (^handleLongRunningCloudLookup)() = ^ {
                    [[NSOperationQueue mainQueue] addOperationWithBlock:activityIndicatorStart];
                };
                
                MADBlockCompletionFileStorageLocation completion = ^(BOOL cloudAvailable, NSURL *documents, NSURL *data) {
                    [MADAppConfiguration mainInstance].storageOption = cloudAvailable ? MADAppStorageCloud : MADAppStorageLocal;
                    [self configureFilesController: NO storageOptionChangeHandler: nil];
                    [[NSOperationQueue mainQueue] addOperationWithBlock:activityIndicatorStop];
                    
                };
                
                [MADFilesController getFileStorageLocationsForUbiquityIdentifier:MADUbiquityIdentifier
                                                             groupIdentifier:MADIdentifierGroup
                                                                       delay:handleLongRunningCloudLookup
                                                                  completion:completion];
                
                
            } else if (storageState.storageOption == MADAppStorageLocal ||
                       storageState.storageOption == MADAppStorageNotSet) {
                
                void (^handleOptionCloud)() = ^ {
                    [MADAppConfiguration mainInstance].storageOption = MADAppStorageCloud;
                    [self configureFilesController: NO storageOptionChangeHandler:^{
                        [MADFileUtilities migrateLocalFiles: MADIdentifierGroup
                                                    toCloud: MADUbiquityIdentifier
                                                  extension: MADFileExtentionMobleApplicationDocument];
                    }];
                    
                };
                void (^handleOptionLocal)() = ^ {
                    [MADAppConfiguration mainInstance].storageOption = MADAppStorageLocal;
                    [self configureFilesController: NO storageOptionChangeHandler: nil];
                };
                UIAlertController *prompt = [UIAlertController promotStorageOptionLocal:handleOptionLocal
                                                                                  cloud:handleOptionCloud];
                [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
                    [self.openFileViewController presentViewController:prompt animated:YES completion:nil];
                }];
            }
        } else {
            if (storageState.storageOption == MADAppStorageCloud) {
                [MADAppConfiguration mainInstance].storageOption = MADAppStorageNotSet;
            }
            [self configureFilesController: NO storageOptionChangeHandler: nil];
        }
    });
}

- (void)getUserCloudPrefsSubsquient {

    MADAppStorageState storageState = [MADAppConfiguration mainInstance].storageState;
    if (storageState.accountDidChange) {
        
        switch (storageState.storageOption) {
            case MADAppStorageCloud: {
                
                UIAlertController *signedOutController = [UIAlertController promotCloudSignOut:^(UIAlertAction *action) {
                    [MADAppConfiguration mainInstance].storageOption = MADAppStorageNotSet;
                    [self getUserCloudPrefs];
                }];
                [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
                    [self.openFileViewController presentViewController:signedOutController animated:YES completion:nil];
                }];
                
                break;
            }
            case MADAppStorageLocal:
            case MADAppStorageNotSet:
            default:
                [self getUserCloudPrefs];
                break;
        }
        
        
    } else {
        if (storageState.storageOption == MADAppStorageNotSet) {
            [self getUserCloudPrefs];
        } else {
            [self configureFilesController: NO storageOptionChangeHandler: nil];
        }
    }

}

- (void)configureFilesController:(BOOL)accountChanged storageOptionChangeHandler:(void (^)(void))storageOptionChangeHandler {
    
    if (accountChanged || [MADAppConfiguration mainInstance].filesController == nil) {
        if (![MADAppConfiguration mainInstance].filesController) {
            MADFilesController *filesController = [[MADAppConfiguration mainInstance] filesControllerForCurrentConfigurationWithPathExtension:MADFileExtentionMobleApplicationDocument
                                                                                                                              firstQueryHandler:storageOptionChangeHandler];
            [MADAppConfiguration mainInstance].filesController = filesController;
            self.openFileViewController.filesController = [MADAppConfiguration mainInstance].filesController;
            
            [[MADAppConfiguration mainInstance].filesController startSearching];
            
        } else if (accountChanged) {
            [MADAppConfiguration mainInstance].filesController.fileCoordinator = [[MADAppConfiguration mainInstance] listsCoordinatorForCurrentConfigurationWithPathExtension:MADFileExtentionMobleApplicationDocument
                                                                                                                                                                firstQueryHandler:storageOptionChangeHandler];
        }
    }
    
}

- (MADNavigationController *)navigationController {
    return (MADNavigationController *)[UIApplication sharedApplication].windows.firstObject.rootViewController;
}

- (MADOpenFileViewController *)openFileViewController {
    return (MADOpenFileViewController *)self.navigationController.topViewController;
}

- (NSString *)ubiquityIdentifier {
    return MADUbiquityIdentifier;
}

+ (void)registerForNotifications:(UIApplication *)application {
    if ([UIApplication instancesRespondToSelector:@selector(registerUserNotificationSettings:)]){
        UIUserNotificationSettings *notificationSettings = [UIUserNotificationSettings settingsForTypes: UIUserNotificationTypeAlert|UIUserNotificationTypeBadge|UIUserNotificationTypeSound
                                                                                             categories: nil];
        [application registerUserNotificationSettings:notificationSettings];
    }
}

@end
