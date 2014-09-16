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

#import "MTNavigationController.h"
#import "MADQueryViewController.h"
#import "MADDesignerViewController.h"
#import "MADViewerController.h"
#import "MTQueryBuilderContainerController.h"

#import "MADFileManager.h"
#import "MTUser.h"

#import "MTReportDesigner.h"
#import "MTReportViewer.h"
#import "MTQueryDesigner.h"
#import "MADocument.h"

#import "RptqDocument.h"
#import "RptqDatabase.h"
#import "RptqQuery.h"

#import "MADOpenFileViewController.h"
#import "UIManagedDocument+FileOperations.h"
#import "evp.h"
#import "VerifyStoreReceipt.h"
#import "MACloudManager.h"
#import "MTStoreKitController.h"
#import "MTLog.h"

#import "UIApplication+Extras.h"
#import "UIDevice+Hack.h"
#import "NSURL+Document.h"
#import "RptqDocument+Extras.h"
#import "UIColor+EverydayApps.h"

#import "MADUpgradeManager.h"


const NSInteger MATagNewDocument = 3838;

@interface AppDelegate()

@property (nonatomic, strong) MTApplicationInstance *applicationInstance;
@property (nonatomic, strong) UIStoryboard *storyboard;
@property (nonatomic, strong) UIApplication *application;

@property (nonatomic, strong) UIFontDescriptor *mainFontDescriptor;
@property (nonatomic, strong) UIFontDescriptor *detailFontDescriptor;

@end

@implementation AppDelegate

void uncaughtExceptionHandler(NSException *exception);
void uncaughtExceptionHandler(NSException *exception) {
    MTLogStatic(@"%@", exception);
}

+ (MTApplicationInstance *)app {
    UIApplication *sharedApplication = [UIApplication sharedApplication];
    return [(AppDelegate *)sharedApplication.delegate applicationInstance];
}

+ (UIWindow *)window {
    return [[UIApplication sharedApplication] windows][0];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: NSUbiquitousKeyValueStoreDidChangeExternallyNotification
                                                  object: nil];
}

#pragma mark - Application Lifecycle

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    UIWindow *window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    UIStoryboard *storyBoard = [MTApplicationInstance storyboard];
    id initViewController = [storyBoard instantiateInitialViewController];
    window.rootViewController = initViewController;
    [window makeKeyAndVisible];
    self.window = window;
    self.storyboard = storyBoard;
    self.application = application;
    
    return YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    MTApplicationInstance *appInstance = [[MTApplicationInstance alloc] init];
    self.applicationInstance = appInstance;

    [self initalizeICloudKvs];
    [self.applicationInstance initalizeAppearance];
    [self.applicationInstance deleteCoreDataCache];

    [MTStoreKitController sharedObject];
    [MACloudManager sharedManager];
    return YES;
}


- (UIViewController *)viewControllerWithrestorationIdentifier:(NSString *)restorationIdentifier childViewControllers:(NSArray *)viewControllers {
    id result = nil;
    for (UIViewController *controller in viewControllers) {
        if ([controller.restorationIdentifier isEqualToString:restorationIdentifier]) {
            result = controller;
        } else {
            result = [self viewControllerWithrestorationIdentifier:restorationIdentifier
                                              childViewControllers:controller.childViewControllers];
        }
        if (result != nil) {
            break;
        }
    }
    return result;
}

- (void)applicationDidBecomeActive:(UIApplication *)application { }

- (void)applicationWillResignActive:(UIApplication *)application { }

- (void)applicationDidEnterBackground:(UIApplication *)application { }

- (void)applicationWillEnterForeground:(UIApplication *)application {
    [[NSUbiquitousKeyValueStore defaultStore] synchronize];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    MADocument *documentReport = [self.applicationInstance currentdocappinst];
    [documentReport quickSave];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {

    BOOL result;
    NSError *error = nil;
    if ([self.applicationInstance.user addDocument:url error:&error]) {
        result = YES;
        UIAlertView *alertView = [[UIAlertView alloc]  initWithTitle: @"New Document"
                                                             message: @"Added document."
                                                            delegate: nil
                                                   cancelButtonTitle: @"Continue"
                                                   otherButtonTitles: nil];
        alertView.tag = MATagNewDocument;
        alertView.delegate = self;
        [alertView show];
    } else {
        result = NO;
        [error presentErrorToUser];
    }
    return result;
}

- (NSUInteger)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window {
    return [UIDevice isPad] ? UIInterfaceOrientationMaskAll : UIInterfaceOrientationMaskAllButUpsideDown;
}

+ (UIViewController *)viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents
                                                            coder:(NSCoder *)coder {
    return nil;
}

#pragma mark -- State Restoration protocol adopted by UIApplication delegate --

- (UIViewController *)application:(UIApplication *)application viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents
                            coder:(NSCoder *)coder {
    
    self.application = application;
    if (self.storyboard == nil) {
        UIStoryboard *storyBoard = [MTApplicationInstance storyboard];
        self.storyboard = storyBoard;
    }
    
    if ([self.applicationInstance openDocument] == nil) {
        [application extendStateRestoration];
        
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSString *filename = [userDefaults objectForKey:@"MADStateRestorationOpenFileWithExtension"];
        if (filename.length > 0) {
            for (NSURL *url in [self.applicationInstance.user hasMadDocuments]) {
                if ([url.path.lastPathComponent caseInsensitiveCompare:filename] == NSOrderedSame) {
                    
                    [self.applicationInstance openReport: url
                                   withCompletionHandler: ^(BOOL success) {
                                       [application completeStateRestoration];
                                   }];
                    break;
                }
            }
        }
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
    BOOL save = self.applicationInstance.reportState != UIDocumentStateClosed;
    if (save == NO) {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults setObject: nil
                         forKey: @"MADStateRestorationOpenFileWithExtension"];
        [userDefaults synchronize];
    }
    return save;
}
- (BOOL)application:(UIApplication *)application shouldRestoreApplicationState:(NSCoder *)coder {
    return NO;
}

- (void)application:(UIApplication *)application willEncodeRestorableStateWithCoder:(NSCoder *)coder {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:self.applicationInstance.openFiles.openUrl.path.lastPathComponent
                     forKey:@"MADStateRestorationOpenFileWithExtension"];
    [userDefaults synchronize];
    
}


- (void)application:(UIApplication *)application didDecodeRestorableStateWithCoder:(NSCoder *)coder { }



/*
- (void)registerDefaultsFromSettingsBundle {
    dispatch_queue_t dipatchQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(dipatchQueue, ^{

        NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
        [standardUserDefaults synchronize];
        
        NSString *pathSettingsBundle = [[NSBundle mainBundle] pathForResource:@"Settings" ofType:@"bundle"];
        NSAssert(pathSettingsBundle, @"Could not find Settings.bundle");
        NSString *pathRootPlist = [pathSettingsBundle stringByAppendingPathComponent:@"Root.plist"];
        
        
        NSDictionary *rootPlistSettings = [NSDictionary dictionaryWithContentsOfFile:pathRootPlist];
        NSArray *preferences = [rootPlistSettings objectForKey:@"PreferenceSpecifiers"];
        NSMutableDictionary *defaultsToRegister = [[NSMutableDictionary alloc] initWithCapacity:[preferences count]];
        
        for (NSDictionary *prefSpecification in preferences)  {
            NSString *key = [prefSpecification objectForKey:@"Key"];
            if (key) {
                
                id currentObject = [standardUserDefaults objectForKey:key];
                if (currentObject == nil) {

                    id objectToSet = [prefSpecification objectForKey:@"DefaultValue"];
                    [defaultsToRegister setObject:objectToSet forKey:key];
                }
            }
        }
        
        [standardUserDefaults registerDefaults:defaultsToRegister];
        [standardUserDefaults synchronize];
    });
}
*/

#pragma mark - Key Value Store Notifications

- (void)keyValueStoreDidChange:(NSNotification *)notification {
    //MTLog(@"%@", notification);
}

#pragma mark - Document Interaction Controller Delegate

- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller {
    return [[self window] rootViewController];
}

- (void)documentInteractionControllerDidEndPreview:(UIDocumentInteractionController *)controller {
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtURL:[controller URL] error:&error];
}

#pragma mark - iCloud Shit

NSString * const MTICloudUbiquityToken  = @"com.everydayapps.mad.icloud.ubiquityIdentityToken";
NSString * const MTICloudUserEnabled    = @"com.everydayapps.mad.icloud.userenabled";
NSString * const MTICloudUserPrefsSet   = @"com.everydayapps.mad.icloud.userprefsset";

- (void)storeCurrentUbiquityToken:(id)currentToken {
    // Write the ubquity identity token to NSUserDefaults if it exists.
    // Otherwise, remove the key.
    
    if (currentToken) {
        NSData *newTokenData = [NSKeyedArchiver archivedDataWithRootObject:currentToken];
        [[NSUserDefaults standardUserDefaults] setObject:newTokenData forKey:MTICloudUbiquityToken];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:MTICloudUbiquityToken];
    }
}

- (void)alertView:(UIAlertView*)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if ([alertView tag] == MATagNewDocument) {
        MADOpenFileViewController *openDocumentViewController = (MADOpenFileViewController *)[(UINavigationController *)[[self window] rootViewController] visibleViewController];
        if (openDocumentViewController != nil &&
            [openDocumentViewController respondsToSelector:@selector(reloadData)]) {
            [openDocumentViewController reloadData];
        }
    }
}

#pragma mark - Sigh...

- (UIFont *)mainFont {
    [self initFonts];
    return [UIFont fontWithDescriptor:[self mainFontDescriptor] size:18.0000f];
}

- (UIFont *)detailFont {
    [self initFonts];
    return [UIFont fontWithDescriptor:[self detailFontDescriptor] size:12.0000f];
}

- (void)initFonts {

    __weak AppDelegate *weakself = self;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{

        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"MTCellSkinner"];
        UIFont *detailFont = [[cell detailTextLabel] font];
        UIFontDescriptor *detailFontDescriptor = [detailFont fontDescriptor];
        [weakself setDetailFontDescriptor:detailFontDescriptor];
        
        UIFont *mainFont = [[cell textLabel] font];
        UIFontDescriptor *mainFontDescriptor = [mainFont fontDescriptor];
        [weakself setMainFontDescriptor:mainFontDescriptor];
    });
}

- (void)initalizeICloudKvs {
    //Setup iCloud KVS
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter addObserver: self
                      selector: @selector(keyValueStoreDidChange:)
                          name: NSUbiquitousKeyValueStoreDidChangeExternallyNotification
                        object: nil];
    
    NSUbiquitousKeyValueStore *defaultStore = [NSUbiquitousKeyValueStore defaultStore];
    [defaultStore synchronize];
}

@end
