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
#import <CoreData/CoreData.h>
#import "MADConstants.h"

#import "MTNavigationController.h"
#import "MADQueryViewController.h"
#import "MADDesignerViewController.h"
#import "MADViewerController.h"
#import "MTQueryBuilderContainerController.h"

#import "MADFileManager.h"
#import "MTUser.h"

#import "MADocument.h"

#import "MADOpenFileViewController.h"

#import "MACloudManager.h"
#import "MTLog.h"

#import "UIDevice+Hack.h"

#import "MADFilesController.h"
#import "MADFileUtilities.h"

#import "MADUpgradeManager.h"

#import "UIAlertController+Constructors.h"
#import "NSError+Constructors.h"
#import "NSString+Encryption.h"

#if MAD_DESIGNER
NSString *s = @"";
#endif

const char * MADQueueAppDelegate = "com.everydayapps.mad.designer.appdelegate";

const NSInteger MADTagAlertViewNewDocument = 3838;
const BOOL MADStateRestorationSupportEnabled = NO;  //If there is a chance it will be enabled,
                                                    //  load window in willFinishLaunchingWithOptions
                                                    //  otherwise load window in didFinishLaunchingWithOptions

@interface AppDelegate()
    <UIDocumentInteractionControllerDelegate,
        MADCloudManagerProtocolAppDetails>

@property (nonatomic, strong) MTApplicationInstance *applicationInstance;
@property (nonatomic, strong) UIStoryboard *storyboard;
@property (nonatomic, strong) UIApplication *application;

@property (nonatomic, strong) MTNavigationController *navigationController;
@property (nonatomic, strong) MADOpenFileViewController *openFileViewController;

/*!
 * @return A private, local queue used to ensure serialized access to Cloud containers during application
 * startup.
 */
@property (nonatomic, strong) dispatch_queue_t appDelegateQueue;

@end

@implementation AppDelegate

/*static const unsigned char keyEncryption[] = {
    0x19, 0xdf, 0x8a, 0xc1, 0x0a, 0x25, 0x38, 0x57,
    0x06, 0x77, 0x6d, 0xd6, 0xbb, 0x5b, 0xd3, 0x21,
    0xdb, 0x46, 0xa5, 0xfd, 0x1e, 0xbe, 0x91, 0x69,
    0x8c, 0x0a, 0x18, 0x2b, 0xfb, 0x3f, 0x34, 0x06
};*/

#if DEBUG

    static void uncaughtExceptionHandler(NSException *exception);
    static void uncaughtExceptionHandler(NSException *exception) {
        MTLogStatic(@"%@", exception);
    }

#endif

+ (MTApplicationInstance *)app {
    return ((AppDelegate *)[UIApplication sharedApplication].delegate).applicationInstance;
}

+ (UIWindow *)window {
    return [UIApplication sharedApplication].keyWindow;
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
    
    if (MADStateRestorationSupportEnabled) {
        [self loadAndDisplayWindow];
    }
    
    self.application = application;
    return YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [AppDelegate registerForNotifications:application];

     [self addObservers];
    
    if (MADStateRestorationSupportEnabled == NO) {
        [self loadAndDisplayWindow];
    }
    
    #if DEBUG
        NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
    #endif

    MADUpgradeManager *upgradeManager = [[MADUpgradeManager alloc] init];
    dispatch_async(self.appDelegateQueue, ^{
        [upgradeManager performUpgradeIfRequired:^(BOOL success, NSError *error, BOOL upgradePerfomrmed) { }];
    });
    
    [[NSUbiquitousKeyValueStore defaultStore] synchronize];
    
    [self.applicationInstance initalizeAppearance];
    
    [MACloudManager sharedManager].delegateApplication = self;

    [[MTApplicationInstance mainInstance] runHandlerOnFirstLaunch:^{
        
        [self getUserCloudPrefs];

    } subsquientLaunches:^{
        [self getUserCloudPrefsSubsquient];
    }];
    
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    
    dispatch_async(self.appDelegateQueue, ^{
        [MTApplicationInstance deleteCoreDataCache];
    });
    
    [[MACloudManager sharedManager] setGroupId:MADIdentifierGroup];
    
}

- (void)applicationWillResignActive:(UIApplication *)application { }

- (void)applicationDidEnterBackground:(UIApplication *)application { }

- (void)applicationWillEnterForeground:(UIApplication *)application {
    [[NSUbiquitousKeyValueStore defaultStore] synchronize];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    MADocument *documentReport = self.applicationInstance.openDocument;
    if (documentReport != nil) {
        [documentReport saveToURL: documentReport.fileURL
                 forSaveOperation: UIDocumentSaveForOverwriting
                completionHandler: nil];
    }
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    
    BOOL result;
    NSError *error = nil;
    if ([self.applicationInstance.user addDocument:url error:&error]) {
        
        result = YES;
        
        UIAlertController *alert = [UIAlertController addedDocument];
        [self.openFileViewController presentViewController:alert animated:YES completion:^{
            [self.openFileViewController.collectionView reloadData];
        }];
        
    } else {
        
        result = NO;
        [NSError presentError: error
             onViewController: self.openFileViewController
                   completion: NULL];
        
    }
    return result;
}

- (NSUInteger)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window {
    return window.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPhone ?
    UIInterfaceOrientationMaskAllButUpsideDown :
    UIInterfaceOrientationMaskAll;
}

- (void)displayActivityIndictor:(id)sender {
    [self.openFileViewController setRightBarButtonItemActivityIndicatorVisible:YES
                                                                      animated:YES];
}

- (void)hideActivityIndictor:(id)sender {
    [self.openFileViewController setRightBarButtonItemActivityIndicatorVisible:NO
                                                                      animated:YES];
}

- (UIViewController *)viewControllerWithrestorationIdentifier:(NSString *)restorationIdentifier
                                         childViewControllers:(NSArray *)viewControllers {
    id result = nil;
    for (UIViewController *controller in viewControllers) {
        if ([controller.restorationIdentifier isEqualToString:restorationIdentifier]) {
            result = controller;
        } else {
            result = [self viewControllerWithrestorationIdentifier: restorationIdentifier
                                              childViewControllers: controller.childViewControllers];
        }
        if (result != nil) {
            break;
        }
    }
    return result;
}

+ (UIViewController *)viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents
                                                            coder:(NSCoder *)coder {
    return nil;
}

#pragma mark -- State Restoration protocol adopted by UIApplication delegate --

- (UIViewController *)application:(UIApplication *)application viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents
                            coder:(NSCoder *)coder {
    
    // FIXME: Currently not implemented... working
    
    self.application = application;
    if (self.storyboard == nil) {
        NSString *storyboardName = [MTApplicationInstance storyboardName];
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:storyboardName bundle:nil];
        self.storyboard = storyboard;
    }
    
    UIViewController *vc = nil;
    if ([identifierComponents.lastObject isEqualToString:@"MADIdentifierRestorationRootNavigationController"]) {
        vc = self.window.rootViewController;

    } else if ([identifierComponents.lastObject isEqualToString:@"MADIdentifierRestorationMainTabBarController"]) {
        vc = (UITabBarController *)[self.storyboard instantiateViewControllerWithIdentifier:@"MADIdentifierStoryboardMainTabBarController"];
        vc.restorationIdentifier = [identifierComponents lastObject];
    
    } else if ([identifierComponents.lastObject isEqualToString:@"MADIdentifierRestorationOpenFileViewController"]) {
        vc = (UITabBarController *)[self.storyboard instantiateViewControllerWithIdentifier:@"MADIdentifierStoryboardOpenFileViewController"];
        vc.restorationIdentifier = [identifierComponents lastObject];
        vc.restorationClass = [MADOpenFileViewController class];
    
    } else if ([identifierComponents.lastObject isEqualToString:@"MADIdentifierRestorationQueryNavigationController"]) {
        vc = (UITabBarController *)[self.storyboard instantiateViewControllerWithIdentifier:@"MADIdentifierStoryboardQueryNavigationController"];
        vc.restorationIdentifier = [identifierComponents lastObject];
        vc.restorationClass = [MTNavigationController class];
    
    } else if ([identifierComponents.lastObject isEqualToString:@"MADIdentifierRestorationQueryNavigationController"]) {
        vc = (UITabBarController *)[self.storyboard instantiateViewControllerWithIdentifier:@"MADIdentifierStoryboardQueryViewController"];
        vc.restorationIdentifier = [identifierComponents lastObject];
        vc.restorationClass = [MADQueryViewController class];
    
    } else if ([identifierComponents.lastObject isEqualToString:@"MADIdentifierRestorationQueryContainerController"]) {
        vc = (UITabBarController *)[self.storyboard instantiateViewControllerWithIdentifier:@"MADIdentifierStoryboardQueryContainerController"];
        vc.restorationIdentifier = [identifierComponents lastObject];
        vc.restorationClass = [MTQueryBuilderContainerController class];
    
    } else if ([identifierComponents.lastObject isEqualToString:@"MADIdentifierRestorationViewerNavigationController"]) {
        vc = (UITabBarController *)[self.storyboard instantiateViewControllerWithIdentifier:@"MADIdentifierStoryboardViewerNavigationController"];
        vc.restorationIdentifier = [identifierComponents lastObject];
        vc.restorationClass = [MTNavigationController class];
    
    } else if ([identifierComponents.lastObject isEqualToString:@"MADIdentifierRestorationViewerViewController"]) {
        vc = (UITabBarController *)[self.storyboard instantiateViewControllerWithIdentifier:@"MADIdentifierStoryboardViewerViewController"];
        vc.restorationIdentifier = [identifierComponents lastObject];
        vc.restorationClass = [MADViewerController class];
    
    } else if ([identifierComponents.lastObject isEqualToString:@"MADIdentifierRestorationDesignerNavigationController"]) {
        vc = (UITabBarController *)[self.storyboard instantiateViewControllerWithIdentifier:@"MADIdentifierStoryboardDesignerNavigationController"];
        vc.restorationIdentifier = [identifierComponents lastObject];
        vc.restorationClass = [MTNavigationController class];
    
    } else if ([identifierComponents.lastObject isEqualToString:@"MADIdentifierRestorationDesignerViewController"]) {
        vc = (UITabBarController *)[self.storyboard instantiateViewControllerWithIdentifier:@"MADIdentifierStoryboardDesignerViewController"];
        vc.restorationIdentifier = [identifierComponents lastObject];
        vc.restorationClass = [MADDesignerViewController class];
    }

    return vc;
}

- (BOOL)application:(UIApplication *)application shouldSaveApplicationState:(NSCoder *)coder {
    BOOL save = MADStateRestorationSupportEnabled;
    if (save) {
        save = self.applicationInstance.reportState != UIDocumentStateClosed;
        if (save == NO) {
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            [userDefaults setObject: nil
                             forKey: @"MADStateRestorationOpenFileWithExtension"];
            [userDefaults synchronize];
        }
    }
    return save;
}

- (BOOL)application:(UIApplication *)application shouldRestoreApplicationState:(NSCoder *)coder {
    return MADStateRestorationSupportEnabled;
}

- (void)application:(UIApplication *)application willEncodeRestorableStateWithCoder:(NSCoder *)coder {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:self.applicationInstance.fileManager.openUrl.path.lastPathComponent
                     forKey:@"MADStateRestorationOpenFileWithExtension"];
    [userDefaults synchronize];
    
}

- (void)application:(UIApplication *)application didDecodeRestorableStateWithCoder:(NSCoder *)coder { }

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
    
    [defaultCenter addObserver: self
                      selector: @selector(handleNotificationWillBeginFetchingUbiquitousContainer:)
                          name: MADNotificationUbiquitousContainerFetchingWillBegin
                        object: nil];
    
    [defaultCenter addObserver: self
                      selector: @selector(handleNotificationDidEndFetchingUbiquitousContainer:)
                          name: MADNotificationUbiquitousContainerFetchingDidEnd
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
    
    [defaultCenter removeObserver: self
                             name: MADNotificationUbiquitousContainerFetchingWillBegin
                           object: nil];
    
    [defaultCenter removeObserver: self
                             name: MADNotificationUbiquitousContainerFetchingDidEnd
                           object: nil];
    
}

- (void)handleNotificationWillBeginFetchingUbiquitousContainer:(NSNotification *)notification {
    // FIXME: Start timer, and display activity indictor if it takes too long
    //  to bring back a ubiquitous container.
    
    [NSTimer timerWithTimeInterval: 0.5000f
                            target: self
                          selector: @selector(displayActivityIndictor:)
                          userInfo: nil
                           repeats: NO];
}

- (void)handleNotificationDidEndFetchingUbiquitousContainer:(NSNotification *)notification {
    // FIXME: Remove activity indictor for ubiquitous container.
    [self hideActivityIndictor:nil];
    //[self.openFileViewController reloadData];
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

- (void)handleNotificationUpdateCloudEnabled:(NSNotification *)notification {
    NSAssert(false, @"Not implemented: %s %@", __PRETTY_FUNCTION__, notification);
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
                    [self configureListsController: NO storageOptionChangeHandler: nil];
                    [[NSOperationQueue mainQueue] addOperationWithBlock:activityIndicatorStop];
                    
                };
                
                [MACloudManager getFileStorageLocationsForUbiquityIdentifier:MADUbiquityIdentifier
                                                             groupIdentifier:MADIdentifierGroup
                                                                       delay:handleLongRunningCloudLookup
                                                                  completion:completion];
                
                
            } else if (storageState.storageOption == MADAppStorageLocal ||
                       storageState.storageOption == MADAppStorageNotSet) {
                
                void (^handleOptionCloud)() = ^ {
                    [MTApplicationInstance mainInstance].storageOption = MADAppStorageCloud;
                    [self configureListsController: NO storageOptionChangeHandler:^{
                        [MADFileUtilities migrateLocalFiles: MADIdentifierGroup
                                                    toCloud: MADUbiquityIdentifier
                                                  extension: MADFileExtentionMobleApplicationDocument];
                    }];
                    
                };
                void (^handleOptionLocal)() = ^ {
                    [MTApplicationInstance mainInstance].storageOption = MADAppStorageLocal;
                    [self configureListsController: NO storageOptionChangeHandler: nil];
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
            [self configureListsController: NO storageOptionChangeHandler: nil];
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
            [self configureListsController: NO storageOptionChangeHandler: nil];
        }
    }

}

- (void)configureListsController:(BOOL)accountChanged storageOptionChangeHandler:(void (^)(void))storageOptionChangeHandler {
    if ([MTApplicationInstance mainInstance].filesController != nil && !accountChanged) {
        // The current controller is correct. There is no need to reconfigure it.
        return;
    }
    
    if (![MTApplicationInstance mainInstance].filesController) {
        // There is currently no lists controller. Configure an appropriate one for the current configuration.
        MADFilesController *filesController = [[MTApplicationInstance mainInstance] listsControllerForCurrentConfigurationWithPathExtension:MADFileExtentionMobleApplicationDocument
                                                                                                                          firstQueryHandler:storageOptionChangeHandler];
        [MTApplicationInstance mainInstance].filesController = filesController;
        
        // Ensure that this controller is passed along to the `AAPLListDocumentsViewController`.
        self.openFileViewController.filesController = [MTApplicationInstance mainInstance].filesController;
        
        [[MTApplicationInstance mainInstance].filesController startSearching];
        
    } else if (accountChanged) {
        // A lists controller is configured; however, it needs to have its coordinator updated based on the account change.
        [MTApplicationInstance mainInstance].filesController.listCoordinator = [[MTApplicationInstance mainInstance] listsCoordinatorForCurrentConfigurationWithPathExtension:MADFileExtentionMobleApplicationDocument
                                                                                                                                                            firstQueryHandler:storageOptionChangeHandler];
    }
}

- (void)loadAndDisplayWindow {
    
    MTApplicationInstance *appInstance = [[MTApplicationInstance alloc] init];
    self.applicationInstance = appInstance;

    [MADUpgradeManager installSamples];
    
    UIWindow *window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    NSString *storyboardName = [MTApplicationInstance storyboardName];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:storyboardName bundle:nil];
    id initViewController = [storyboard instantiateInitialViewController];
    
    NSAssert([initViewController isKindOfClass:@class([MTNavigationController class])] == NO, @"%s Can't find MTNavigationController.", __PRETTY_FUNCTION__);
    
    window.rootViewController = initViewController;
    self.navigationController = initViewController;
    
    NSAssert([self.navigationController.topViewController isKindOfClass:@class([MADOpenFileViewController class])] == NO, @"%s Can't find MADOpenFileViewController.", __PRETTY_FUNCTION__);
    
    self.openFileViewController = (MADOpenFileViewController *)self.navigationController.topViewController;
    [window makeKeyAndVisible];
    
    
    self.window = window;
    self.storyboard = storyboard;
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
