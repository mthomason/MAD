//
//  AppDelegate.m
//  Reports
//
//  Created by Michael Thomason on 1/2/12.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
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
#import <os/log.h>

static NSString * const MADAppConfigurationApplicationGroupsPrimary        = @"group.everydayapps.mad.primary";
static NSString * const MADIdentifierFileLondon                            = @"London";
static NSString * const MADIdentifierFileMusic                             = @"Music";
static NSString * const MADIDUser                                          = @"MADIDUser";

const CFStringRef MADKeyRevision = CFSTR("MADRevision");

#if MAD_DESIGNER
    NSString *s = @"";
#endif

const char * MADQueueAppDelegate = "com.everydayapps.mad.designer.appdelegate";

static inline UIUserNotificationType MADUserNotificationType(void);

@interface AppDelegate()
    <UIDocumentInteractionControllerDelegate>

    @property (nonatomic, strong, readwrite) dispatch_queue_t appDelegateQueueSerial;

@end

@implementation AppDelegate {
    NSString *_ubiquityIdentifier;
    NSString *_groupIdentifier;
    NSString *_name;
    NSString *_localizedName;
    NSString *_trademark;
    NSString *_applicationNameSufixPart;
    NSString *_applicationIdentifier;
    NSString *_applicationBundleIdentifier;
    NSString *_localizedApplicationNameSufixPart;
    NSString *_versionNumber;
    NSString *_revisionNumber;
    NSString *_bundleDisplayName;
}

#pragma mark - MADApplicationProtocol

//@"group.everydayapps.mad"
+ (NSString *)groupIdentifier {
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"MAD Designer" withExtension:@"entitlements"];
    NSAssert(url != nil, @"We need a URL.");
    return [NSDictionary dictionaryWithContentsOfURL:url][@"com.apple.security.application-groups"][0];
}

//@"iCloud.com.everydayapps.mad.designer"
+ (NSString *)ubiquityIdentifier {
    return ((NSDictionary *)[[NSBundle mainBundle] infoDictionary][@"NSUbiquitousContainers"]).allKeys[0];
}

+ (NSString *)bundleVersion {
    return [[NSBundle mainBundle] infoDictionary][@"CFBundleVersion"];
}

+ (NSString *)bundleRevisionNumber {
    return [[NSBundle mainBundle] infoDictionary][@"MADRevision"];
}

+ (NSString *)humanReadableCopyright {
    return [[NSBundle mainBundle] infoDictionary][@"NSHumanReadableCopyright"];
}

+ (NSString *)bundleDisplayName {
    return [[NSBundle mainBundle] infoDictionary][@"CFBundleDisplayName"];
}

- (NSString *)ubiquityIdentifier {
    if (!_ubiquityIdentifier) {
        _ubiquityIdentifier = [AppDelegate ubiquityIdentifier];
    }
    return _ubiquityIdentifier;
}

- (NSString *)groupIdentifier {
    if (!_groupIdentifier) {
        _groupIdentifier = [AppDelegate groupIdentifier];
    }
    return _groupIdentifier;
}

- (NSString *)name {
    if (!_name) {
        id tm = self.trademark, sx = self.applicationNameSufixPart;
        _name = [[NSString alloc] initWithFormat:@"%@ %@", tm, sx];
    }
    return _name;
}

- (NSString *)localizedName {
    if (!_localizedName) {
        id tm = self.trademark, sx = self.localizedApplicationNameSufixPart;
        _localizedName = [[NSString alloc] initWithFormat:@"%@ %@", tm, sx];
    }
    return _localizedName;
}

- (NSString *)applicationIdentifier {
    if (!_applicationIdentifier) _applicationIdentifier = @"666001433";
    return _applicationIdentifier;
}

- (NSString *)applicationBundleIdentifier {
    if (!_applicationBundleIdentifier) _applicationBundleIdentifier = @"com.everydayapps.mad.designer";
    return _applicationBundleIdentifier;
}

- (NSString *)trademark {
    if (!_trademark) _trademark = @"MAD";
    return _trademark;
}

- (NSString *)applicationNameSufixPart {
    if (!_applicationNameSufixPart)  _applicationNameSufixPart = @"Designer";
    return _applicationNameSufixPart;
}

- (NSString *)localizedApplicationNameSufixPart {
    if (!_localizedApplicationNameSufixPart) {
        _localizedApplicationNameSufixPart = NSLocalizedString([self applicationNameSufixPart],
                                                               [self applicationNameSufixPart]);
    }
    return _localizedApplicationNameSufixPart;
}

- (NSString *)versionNumber {
    if (!_versionNumber) {
        CFStringRef cversion;
        cversion = CFBundleGetValueForInfoDictionaryKey(CFBundleGetMainBundle(),
                                                        kCFBundleVersionKey);
        _versionNumber = (__bridge NSString *)cversion;

    }
    return _versionNumber;
}

- (NSString *)revisionNumber {
    if (!_revisionNumber) {
        CFStringRef version = CFBundleGetValueForInfoDictionaryKey(CFBundleGetMainBundle(),
                                                                   MADKeyRevision);
        _revisionNumber = (__bridge NSString *)version;
    }
    return _revisionNumber;
}

- (dispatch_queue_t)appDelegateQueueSerial {
    if (!_appDelegateQueueSerial) {
        dispatch_queue_t queue;
        queue = dispatch_queue_create(MADQueueAppDelegate, DISPATCH_QUEUE_SERIAL);
        _appDelegateQueueSerial = queue;
    }
    return _appDelegateQueueSerial;
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
    [[NSBundle mainBundle] load];

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
        //NSLog(@"Valid %@\n", valid ? @"YES" : @"NO");
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
    //NSLog(@"executionTime = %f", executionTime);


    i=0;
    r = abs(rand())%INT32_MAX;
    methodStart = [NSDate date];
    
    for (i=0; i<90000000; i++) {
        cr = tes1(r);
    }
    
    
    methodFinish = [NSDate date];
    executionTime = [methodFinish timeIntervalSinceDate:methodStart];
    //NSLog(@"executionTime = %f", executionTime);

    //NSUInteger i = UINT64_MAX;
    //NSLog(@"%llu", UINT64_MAX);

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
    if (!_bundleDisplayName) {
        NSString *result;
        result = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
        _bundleDisplayName = result.copy;
    }
    return _bundleDisplayName;
}

- (id)debugQuickLookObject {
    NSMutableString *debug = [[NSMutableString alloc] init];
    NSString *classname = NSStringFromClass([self class]);
    id uppercaseClassname = [classname uppercaseString];
    [debug appendFormat:@"--%@--\n", uppercaseClassname];
    return debug;
}

@end

static inline UIUserNotificationType MADUserNotificationType() {
    return (UIUserNotificationType)(UIUserNotificationTypeAlert |
                                    UIUserNotificationTypeBadge |
                                    UIUserNotificationTypeSound);
}
