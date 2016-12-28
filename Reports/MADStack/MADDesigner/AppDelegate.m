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
#import "Constants.h"

#import <MADDataStructures/MADVectorBool.h>

@class MADTransparentPresentationController;
@class MFMailComposeViewController;
@class MADFileExplorerViewController;

static NSString * const MADAppConfigurationApplicationGroupsPrimary        = @"group.everydayapps.mad.primary";
static NSString * const MADIdentifierFileLondon                            = @"London";
static NSString * const MADIdentifierFileMusic                             = @"Music";
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

    @property (nonatomic, strong, readwrite) dispatch_queue_t appDelegateQueueSerial;

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
    MADVectorBool *vectorBool = [[MADVectorBool alloc] init];
    [vectorBool addTrue];
    [vectorBool addTrue];
    [vectorBool addFalse];
    [vectorBool addTrue];
    [vectorBool addTrue];
    [vectorBool addFalse];
    [vectorBool addTrue];
    [vectorBool addTrue];
    [vectorBool addFalse];
    [vectorBool addTrue];
    [vectorBool addTrue];
    [vectorBool addFalse];
    [vectorBool addTrue];
    [vectorBool addTrue];
    [vectorBool addFalse];
    [vectorBool enumerateBools:^(NSUInteger inx, BOOL valid, BOOL *stop) {
        NSLog(@"Valid %@\n", valid ? @"YES" : @"NO");
    }];*/
//    [vectorBool enum]
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
    if ([UIApplication instancesRespondToSelector:@selector(registerUserNotificationSettings:)]){
        id notification = [UIUserNotificationSettings settingsForTypes: MADUserNotificationType()
                                                            categories: nil];
        [application registerUserNotificationSettings:notification];
    }
    
   
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application { }

- (void)applicationWillResignActive:(UIApplication *)application { }

- (void)applicationDidEnterBackground:(UIApplication *)application { }

- (void)applicationWillEnterForeground:(UIApplication *)application {
    [[NSUbiquitousKeyValueStore defaultStore] synchronize];
}

- (void)applicationWillTerminate:(UIApplication *)application {
// FIXME: ... close open applications by calling delegate method from openFileViewController.
    //[self.appConfiguration cleanupBeforeTerminate];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
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

#pragma mark - Convenience

- (NSString *)bundleDisplayName {
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:MTBundleDisplayName];
}

- (id)debugQuickLookObject {
    NSMutableString *debug = [[NSMutableString alloc] init];
    NSString *classname = NSStringFromClass([self class]);
    id uppercaseClassname = [classname uppercaseString];
    [debug appendFormat:@"--%@--\n", uppercaseClassname];
    return debug;
}

@end
