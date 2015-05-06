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
#import <CoreData/CoreData.h>
#import "MADConstants.h"

#import "MADFilesController.h"
#import "MADListCoordinator.h"

#import "MADFileUtilities.h"

#import "MTApplicationInstance.h"
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
#import "NSError+Constructors.h"

#if MAD_DESIGNER == 1 || MAD_TEST == 1
NSString * const MADUbiquityIdentifier                                  = @"iCloud.com.everydayapps.mad.designer";
#elif MAD_VIEWER == 1
NSString * const MADUbiquityIdentifier                                  = @"iCloud.com.everydayapps.mad.viewer";
#endif

const NSInteger MADTagAlertViewNewDocument = 3838;
const BOOL MADStateRestorationSupportEnabled = NO;  //If there is a chance it will be enabled,
                                                    //  load window in willFinishLaunchingWithOptions
                                                    //  otherwise load window in didFinishLaunchingWithOptions
@interface AppDelegate()
    <UIDocumentInteractionControllerDelegate,
        MADCloudManagerProtocolAppDetails>

@property (nonatomic, strong) UIStoryboard *storyboard;
@property (nonatomic, strong) UIApplication *application;

@property (nonatomic, strong) MTNavigationController *navigationController;
@property (nonatomic, strong) MADOpenFileViewController *openFileViewController;

@property (nonatomic, strong) MADFilesController *listsController;

@end

@implementation AppDelegate

#if DEBUG

//static void uncaughtExceptionHandler(NSException *exception);
//static void uncaughtExceptionHandler(NSException *exception) {
//    MTLogStatic(@"%@", exception);
//}

#endif

+ (UIWindow *)window {
    return [UIApplication sharedApplication].keyWindow;
}

- (void)dealloc {
    
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];

    [defaultCenter removeObserver: [MACloudManager sharedManager]
                             name: NSUbiquityIdentityDidChangeNotification
                           object: nil];
    
    [defaultCenter removeObserver:self
                             name:MADNotificationFileManagerDidUpdateFileLocations object:nil];
    
    [defaultCenter removeObserver: self
                             name: MADNotificationCloudStateUpdated
                           object: nil];
    
    [defaultCenter removeObserver: self
                             name: MADNotificationUbiquitousContainerFetchingWillBegin
                           object: nil];
    
    [defaultCenter removeObserver: self
                             name: MADNotificationUbiquitousContainerFetchingDidEnd
                           object: nil];
    
    [defaultCenter removeObserver: self
                             name: NSUbiquitousKeyValueStoreDidChangeExternallyNotification
                           object: nil];

}

#pragma mark - Application Lifecycle

- (void)loadAndDisplayWindow {
    
    [MTApplicationInstance mainInstance];

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

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    if (MADStateRestorationSupportEnabled) {
        [self loadAndDisplayWindow];
    }
    self.application = application;
    return YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
 
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    
    [defaultCenter addObserver: self
                      selector: @selector(handleNotificationFileManagerDidUpdateFileLocations:)
                          name: MADNotificationFileManagerDidUpdateFileLocations
                        object: nil];
    
    [defaultCenter addObserver: self
                      selector: @selector(keyValueStoreDidChange:)
                          name: NSUbiquitousKeyValueStoreDidChangeExternallyNotification
                        object: nil];
    
    [defaultCenter addObserver: [MACloudManager sharedManager]
                      selector: @selector(handleNotificationUbiquityIdentityDidChange:)
                          name: NSUbiquityIdentityDidChangeNotification
                        object: nil];
    
    [defaultCenter addObserver: self
                      selector: @selector(handleNotificationUpdateCloudEnabled:)
                          name: MADNotificationCloudStateUpdated
                        object: nil];
    
    [defaultCenter addObserver: self
                      selector: @selector(handleNotificationWillBeginFetchingUbiquitousContainer:)
                          name: MADNotificationUbiquitousContainerFetchingWillBegin
                        object: nil];
    
    [defaultCenter addObserver: self
                      selector: @selector(handleNotificationDidEndFetchingUbiquitousContainer:)
                          name: MADNotificationUbiquitousContainerFetchingDidEnd
                        object: nil];
    
    if ([UIApplication instancesRespondToSelector:@selector(registerUserNotificationSettings:)]){
        UIUserNotificationSettings *notificationSettings = [UIUserNotificationSettings settingsForTypes: UIUserNotificationTypeAlert|UIUserNotificationTypeBadge|UIUserNotificationTypeSound
                                                                                             categories: nil];
        [application registerUserNotificationSettings:notificationSettings];
    }
    
    if (MADStateRestorationSupportEnabled == NO) {
        [self loadAndDisplayWindow];
    }
    
#if DEBUG
    //NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
#endif
    
    [[NSUbiquitousKeyValueStore defaultStore] synchronize];

    [[MTApplicationInstance mainInstance] initalizeAppearance];

    //[MTStoreKitController sharedObject];
    [MACloudManager sharedManager].delegateApplication = self;
    return YES;
}

- (NSString *)ubiquityIdentifier {
    return MADUbiquityIdentifier;
}

+ (void)deleteCoreDataCache {
    dispatch_queue_t dipatchQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    dispatch_async(dipatchQueue, ^{
        dispatch_sync(dispatch_get_main_queue(), ^{
            dispatch_queue_t dipatchQueueBg = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
            dispatch_async(dipatchQueueBg, ^{
                
                [NSFetchedResultsController deleteCacheWithName: NSFetchedResultsCacheName];
                [NSFetchedResultsController deleteCacheWithName: NSFetchedResultsCacheTables];
                [NSFetchedResultsController deleteCacheWithName: NSFetchedResultsCacheLinks];
                [NSFetchedResultsController deleteCacheWithName: NSFetchedResultsCacheGroups];
                [NSFetchedResultsController deleteCacheWithName: NSFetchedResultsCachePredicates];
            });
        });
    });
}

/*
 *  handles MADNotificationFileManagerDidUpdateFileLocations
 */

- (void)handleNotificationFileManagerDidUpdateFileLocations:(NSNotification *)notification {
    if (notification.object == nil) {
        [self.openFileViewController reloadData];
    } else {
        
        [self.openFileViewController reloadDataCloudWithInserts:notification.object[MADNotificationFileManagerDidUpdateFileLocationsKeyInserted]
                                                        updates:notification.object[MADNotificationFileManagerDidUpdateFileLocationsKeyUpdated]
                                                        deletes:notification.object[MADNotificationFileManagerDidUpdateFileLocationsKeyRemoved]];

    }
}

/*
 *  handles MADNotificationUbiquitousContainerFetchingWillBegin
 */

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
    [self.openFileViewController reloadData];
}

- (void)displayActivityIndictor:(id)sender {
    [self.openFileViewController setRightBarButtonItemActivityIndicatorVisible:YES
                                                                      animated:YES];
}

- (void)hideActivityIndictor:(id)sender {
    [self.openFileViewController setRightBarButtonItemActivityIndicatorVisible:NO
                                                                      animated:YES];
}

- (void)handleNotificationUpdateCloudEnabled:(NSNotification *)notification {

    [self.openFileViewController reloadData];
    
    NSAssert(false, @"Not implemented: %s %@", __PRETTY_FUNCTION__, notification);
    
}

- (UIViewController *)viewControllerWithrestorationIdentifier:(NSString *)restorationIdentifier childViewControllers:(NSArray *)viewControllers {
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

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [AppDelegate deleteCoreDataCache];
    [[MACloudManager sharedManager] setFileExtention:MADFileExtentionMobleApplicationDocument];
    [[MACloudManager sharedManager] activateWithGroupID:MADIdentifierGroup];
}

- (void)applicationWillResignActive:(UIApplication *)application { }

- (void)applicationDidEnterBackground:(UIApplication *)application { }

- (void)applicationWillEnterForeground:(UIApplication *)application {
    [[NSUbiquitousKeyValueStore defaultStore] synchronize];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    MADocument *documentReport = [[MTApplicationInstance mainInstance] openDocument];
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
    if ([[MTApplicationInstance mainInstance].user addDocument:url error:&error]) {
        
        result = YES;
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle: @"New Document"
                                                                       message: @"Added document."
                                                                preferredStyle: UIAlertControllerStyleAlert];
        
        UIAlertAction *ok = [UIAlertAction actionWithTitle: @"Continue"
                                                     style: UIAlertActionStyleDefault
                                                   handler: nil];
        [alert addAction:ok];
        
        __weak AppDelegate *weakself = self;
        [self.openFileViewController presentViewController:alert animated:YES completion:^{
                [weakself.openFileViewController reloadData];
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
        save = [MTApplicationInstance mainInstance].reportState != UIDocumentStateClosed;
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
    [userDefaults setObject:[MTApplicationInstance mainInstance].fileManager.openUrl.path.lastPathComponent
                     forKey:@"MADStateRestorationOpenFileWithExtension"];
    [userDefaults synchronize];
    
}


- (void)application:(UIApplication *)application didDecodeRestorableStateWithCoder:(NSCoder *)coder { }

#pragma mark - Key Value Store Notifications

- (void)keyValueStoreDidChange:(NSNotification *)notification {
    //MTLog(@"%@", notification);
}

#pragma mark - Document Interaction Controller Delegate

- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller {
    return self.window.rootViewController;
}

- (void)documentInteractionControllerDidEndPreview:(UIDocumentInteractionController *)controller {
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtURL:controller.URL error:&error];
}

#pragma mark - User Storage Preferences

- (void)setupUserStoragePreferences {
    MADAppStorageState storageState = [MTApplicationInstance mainInstance].storageState;
    
    /*
     Check to see if the account has changed since the last time the method was called. If it has, let the
     user know that their documents have changed. If they've already chosen local storage (i.e. not iCloud),
     don't notify them since there's no impact.
     */
    if (storageState.accountDidChange) {
        [self notifyUserOfAccountChange:storageState];
        
        // Return early. State resolution will take place after the user acknowledges the change.
        return;
    }
    
    [self resolveStateForUserStorageState:storageState];
}

- (void)resolveStateForUserStorageState:(MADAppStorageState)storageState {
    if (storageState.cloudAvailable) {
        if (storageState.storageOption == MADAppStorageNotSet || (storageState.storageOption == MADAppStorageLocal && storageState.accountDidChange)) {
            // iCloud is available, but we need to ask the user what they prefer.
            [self promptUserForStorageOption];
        }
        else {
            /*
             The user has already selected a specific storage option. Set up the lists controller to use that
             storage option.
             */
            [self configureFilesViewController: storageState.accountDidChange
                    storageOptionChangeHandler: nil];
        }
    }
    else {
        /*
         iCloud is not available, so we'll reset the storage option and configure the lists controller. The
         next time that the user signs in with an iCloud account, he or she can change provide their desired
         storage option.
         */
        if (storageState.storageOption != MADAppStorageNotSet) {
            [MTApplicationInstance mainInstance].storageOption = MADAppStorageNotSet;
        }
        
        [self configureFilesViewController: storageState.accountDidChange
                storageOptionChangeHandler: nil];
    }
}

#pragma mark - Convenience

- (void)configureFilesViewController:(BOOL)accountChanged storageOptionChangeHandler:(void (^)(void))storageOptionChangeHandler {
    if (self.listsController != nil && !accountChanged) {
        // The current controller is correct. There is no need to reconfigure it.
        return;
    }
    
    if (!self.listsController) {
        // There is currently no lists controller. Configure an appropriate one for the current configuration.
        self.listsController = [[MTApplicationInstance mainInstance] listsControllerForCurrentConfigurationWithPathExtension:MADFileExtentionMobleApplicationDocument
                                                                                                           firstQueryHandler:storageOptionChangeHandler];
        
        // Ensure that this controller is passed along to the `AAPLListDocumentsViewController`.
#warning Do this by delegate....
//        self.openFileViewController.listsController = self.listsController;
        
        [self.listsController startSearching];
    }
    else if (accountChanged) {
        // A lists controller is configured; however, it needs to have its coordinator updated based on the account change.
        self.listsController.listCoordinator = [[MTApplicationInstance mainInstance] listsCoordinatorForCurrentConfigurationWithPathExtension:MADFileExtentionMobleApplicationDocument
                                                                                                                            firstQueryHandler:storageOptionChangeHandler];
    }
}

#pragma mark - Alerts

- (void)notifyUserOfAccountChange:(MADAppStorageState)storageState {
    
    NSString *title = NSLocalizedString(@"iCloud Sign Out", nil);
    NSString *message = NSLocalizedString(@"You have signed out of the iCloud account previously used to store documents. Sign back in to access those documents.", nil);
    NSString *okActionTitle = NSLocalizedString(@"OK", nil);
    
    UIAlertController *signedOutController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *action = [UIAlertAction actionWithTitle:okActionTitle style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [self resolveStateForUserStorageState:storageState];
    }];
    [signedOutController addAction:action];
    
    [self.openFileViewController presentViewController:signedOutController animated:YES completion:nil];
}

- (void)promptUserForStorageOption {
    NSString *title = NSLocalizedString(@"Choose Storage Option", nil);
    NSString *message = NSLocalizedString(@"Do you want to store documents in iCloud or only on this device?", nil);
    NSString *localOnlyActionTitle = NSLocalizedString(@"Local Only", nil);
    NSString *cloudActionTitle = NSLocalizedString(@"iCloud", nil);
    
    UIAlertController *storageController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *localOption = [UIAlertAction actionWithTitle:localOnlyActionTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [MTApplicationInstance mainInstance].storageOption = MADAppStorageLocal;
        
        [self configureFilesViewController:YES storageOptionChangeHandler:nil];
    }];
    [storageController addAction:localOption];
    
    UIAlertAction *cloudOption = [UIAlertAction actionWithTitle:cloudActionTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [MTApplicationInstance mainInstance].storageOption = MADAppStorageCloud;
        
        [self configureFilesViewController:YES storageOptionChangeHandler:^{
            [MADFileUtilities migrateLocalListsToCloud:MADIdentifierGroup];
        }];
    }];
    [storageController addAction:cloudOption];
    
    [self.openFileViewController presentViewController:storageController animated:YES completion:nil];
}

@end
