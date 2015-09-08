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
#import "MTApplicationInstance.h"
#import "MADConstants.h"

#import "MADNavigationController.h"

#import "MADOpenFileViewController.h"

#import "MADFilesController.h"
#import "MADFileUtilities.h"

#import "MADUpgradeManager.h"

#import "UIAlertController+Constructors.h"
#import "UIViewController+Designer.h"
#import "UITabBarController+Shared.h"
#import "MTVerificationController.h"

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

+ (MTApplicationInstance *)app {
    return [MTApplicationInstance mainInstance];
}

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
    //MADUncaughtExceptionHandlerInstaller();
    
    [AppDelegate registerForNotifications:application];

    [self addObservers];
    
    [[MTApplicationInstance mainInstance] initalizeAppearance];
    [[MTApplicationInstance mainInstance] runHandlerOnFirstLaunch:^{
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
    
    [MADFeedbackFrustration sharedInstance];
    
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [MTVerificationController sharedInstance];
    });
    
    dispatch_async(self.appDelegateQueue, ^{
        [MTApplicationInstance deleteCoreDataCache];
    });
    
}

- (void)applicationWillResignActive:(UIApplication *)application { }

- (void)applicationDidEnterBackground:(UIApplication *)application { }

- (void)applicationWillEnterForeground:(UIApplication *)application {
    [[NSUbiquitousKeyValueStore defaultStore] synchronize];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Fix me... close open applications by calling delegate method from openFileViewController.
    //[[MTApplicationInstance mainInstance] cleanupBeforeTerminate];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    
    NSURL *documentsDirectory = [MTApplicationInstance mainInstance].filesController.documentDirectory;
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
    
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    
    [defaultCenter addObserver: self
                      selector: @selector(handleNotificationKeyValueStoreDidChange:)
                          name: NSUbiquitousKeyValueStoreDidChangeExternallyNotification
                        object: nil];
    
    [defaultCenter addObserver: self
                      selector: @selector(handleNotificationUbiquityIdentityDidChange:)
                          name: NSUbiquityIdentityDidChangeNotification
                        object: nil];

}

- (void)removeObservers {
    
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    
    [defaultCenter removeObserver: self
                             name: NSUbiquitousKeyValueStoreDidChangeExternallyNotification
                           object: nil];
    
    [defaultCenter removeObserver: self
                             name: NSUbiquityIdentityDidChangeNotification
                           object: nil];
    
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

        MADAppStorageState storageState = [MTApplicationInstance mainInstance].storageState;
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
                    [MTApplicationInstance mainInstance].storageOption = cloudAvailable ? MADAppStorageCloud : MADAppStorageLocal;
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
                    [MTApplicationInstance mainInstance].storageOption = MADAppStorageCloud;
                    [self configureFilesController: NO storageOptionChangeHandler:^{
                        [MADFileUtilities migrateLocalFiles: MADIdentifierGroup
                                                    toCloud: MADUbiquityIdentifier
                                                  extension: MADFileExtentionMobleApplicationDocument];
                    }];
                    
                };
                void (^handleOptionLocal)() = ^ {
                    [MTApplicationInstance mainInstance].storageOption = MADAppStorageLocal;
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
                [MTApplicationInstance mainInstance].storageOption = MADAppStorageNotSet;
            }
            [self configureFilesController: NO storageOptionChangeHandler: nil];
        }
    });
}

- (void)getUserCloudPrefsSubsquient {

    MADAppStorageState storageState = [MTApplicationInstance mainInstance].storageState;
    if (storageState.accountDidChange) {
        
        switch (storageState.storageOption) {
            case MADAppStorageCloud: {
                
                UIAlertController *signedOutController = [UIAlertController promotCloudSignOut:^(UIAlertAction *action) {
                    [MTApplicationInstance mainInstance].storageOption = MADAppStorageNotSet;
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
    
    if (accountChanged || [MTApplicationInstance mainInstance].filesController == nil) {
        if (![MTApplicationInstance mainInstance].filesController) {
            MADFilesController *filesController = [[MTApplicationInstance mainInstance] filesControllerForCurrentConfigurationWithPathExtension:MADFileExtentionMobleApplicationDocument
                                                                                                                              firstQueryHandler:storageOptionChangeHandler];
            [MTApplicationInstance mainInstance].filesController = filesController;
            self.openFileViewController.filesController = [MTApplicationInstance mainInstance].filesController;
            
            [[MTApplicationInstance mainInstance].filesController startSearching];
            
        } else if (accountChanged) {
            [MTApplicationInstance mainInstance].filesController.fileCoordinator = [[MTApplicationInstance mainInstance] listsCoordinatorForCurrentConfigurationWithPathExtension:MADFileExtentionMobleApplicationDocument
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
