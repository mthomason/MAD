//
//  AppDelegate.m
//  Reports
//
//  Created by Michael Thomason on 1/2/12.
//  Copyright © 2020 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif


#import "AppDelegate.h"
#import "MADPngImageTransformer.h"
#import "Constants.h"
#import "madlog.h"

#import <MAD/MADConstants.h>
#import <MADDataStructures/MADVectorBool.h>

#import <Foundation/NSString.h>
#import <UserNotifications/UNUserNotificationCenter.h>
#import <QuickLook/QLPreviewController.h>
#import <CoreFoundation/CFBundle.h>

static NSString * const MADAppConfigurationApplicationGroupsPrimary		= @"group.everydayapps.mad.primary";
static NSString * const MADIDUser										= @"MADIDUser";

const CFStringRef MADKeyRevision = CFSTR("MADRevision");

#if MAD_DESIGNER
	NSString *s = @"";
#endif

const char * MADQueueAppDelegate = "com.everydayapps.mad.designer.appdelegate";

@interface AppDelegate() <UIDocumentInteractionControllerDelegate>
@property (nonatomic, strong, readwrite) dispatch_queue_t appDelegateQueueSerial;
@end

@implementation AppDelegate {
	NSString *_ubiquityIdentifier;
	NSString *_groupIdentifier;
	NSString *_name;
	NSString *_localizedName;
	NSString *_applicationNameSufixPart;
	NSString *_applicationIdentifier;
	NSString *_applicationBundleIdentifier;
	NSString *_localizedApplicationNameSufixPart;
	NSString *_versionNumber;
	NSString *_revisionNumber;
	NSString *_bundleDisplayName;
}

#pragma mark - MADApplicationProtocol

+ (NSString *)groupIdentifier {
	return @"group.everydayapps.mad";
}

+ (NSString *)ubiquityIdentifier {
	return ((NSDictionary *)[[NSBundle mainBundle] infoDictionary][@"NSUbiquitousContainers"]).allKeys[0];
}

+ (NSString *)bundleGitCommitCount {
	NSString *path = [[NSBundle mainBundle] pathForResource:@"MADMeta" ofType:@"plist"];
	NSDictionary *metaDictionary = [NSDictionary dictionaryWithContentsOfFile:path];
	return metaDictionary[@"MADGitCommitCount"];
}

+ (NSString *)bundleVersionShortString {
	NSString *path = [[NSBundle mainBundle] pathForResource:@"MADMeta" ofType:@"plist"];
	NSDictionary *metaDictionary = [NSDictionary dictionaryWithContentsOfFile:path];
	return metaDictionary[@"CFBundleShortVersionString"];
}

+ (NSString *)bundleVersion {
	return [[NSBundle mainBundle] infoDictionary][@"CFBundleVersion"];
}

+ (NSString *)bundleRevisionNumber {
	NSString *path = [[NSBundle mainBundle] pathForResource:@"MADMeta" ofType:@"plist"];
	NSDictionary *metaDictionary = [NSDictionary dictionaryWithContentsOfFile:path];
	return metaDictionary[@"MADRevision"];
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
		_localizedName = [[NSString alloc] initWithFormat:@"%@ %@", [self trademark], self.localizedApplicationNameSufixPart];
	}
	return _name;
}

- (NSString *)localizedName {
	if (!_localizedName) {
		_localizedName = [[NSString alloc] initWithFormat:@"%@ %@", [self trademark], self.localizedApplicationNameSufixPart];
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
	return @"MAD";
}

- (NSString *)applicationNameSufixPart {
	if (!_applicationNameSufixPart)  _applicationNameSufixPart = @"Designer";
	return _applicationNameSufixPart;
}

- (NSString *)localizedApplicationNameSufixPart {
	if (!_localizedApplicationNameSufixPart) {
		_localizedApplicationNameSufixPart = NSLocalizedString([self applicationNameSufixPart], [self applicationNameSufixPart]);
	}
	return _localizedApplicationNameSufixPart;
}

- (NSString *)versionNumber {
	if (!_versionNumber) {
		CFStringRef cversion = CFBundleGetValueForInfoDictionaryKey(CFBundleGetMainBundle(), kCFBundleVersionKey);
		_versionNumber = (__bridge NSString *)cversion;
		
	}
	return _versionNumber;
}

- (NSString *)revisionNumber {
	return [AppDelegate bundleRevisionNumber];
}

- (dispatch_queue_t)appDelegateQueueSerial {
	if (!_appDelegateQueueSerial) {
		dispatch_queue_t queue;
		queue = dispatch_queue_create(MADQueueAppDelegate, DISPATCH_QUEUE_SERIAL);
		_appDelegateQueueSerial = queue;
	}
	return _appDelegateQueueSerial;
}

#pragma mark - Application Lifecycle

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	return YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	
	
	[[NSBundle mainBundle] load];

	[NSValueTransformer setValueTransformer:[[MADPngImageTransformer alloc] init] forName:NSStringFromClass([MADPngImageTransformer class])];
	
	[[UNUserNotificationCenter currentNotificationCenter] requestAuthorizationWithOptions:(UNAuthorizationOptionAlert | UNAuthorizationOptionSound | UNAuthorizationOptionBadge)
						  completionHandler:^(BOOL granted, NSError * _Nullable error) {
		if (granted) {
			dispatch_async(dispatch_get_main_queue(), ^{
				[application registerForRemoteNotifications];
			});
		}
	}];
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

- (BOOL)application:(UIApplication *)application OpenURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
	return NO;
}

- (UIInterfaceOrientationMask)application:(UIApplication *)application
  supportedInterfaceOrientationsForWindow:(UIWindow *)window {
	return window.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPhone ? UIInterfaceOrientationMaskAllButUpsideDown : UIInterfaceOrientationMaskAll;
}

- (BOOL)application:(UIApplication *)application shouldSaveApplicationState:(NSCoder *)coder {
	return NO;
}

- (BOOL)application:(UIApplication *)application shouldSaveSecureApplicationState:(nonnull NSCoder *)coder {
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
	NSURL *itemToRemove = controller.URL;
	if (!itemToRemove) return;
	
	NSError *error = nil;
	BOOL removed = [[NSFileManager defaultManager] removeItemAtURL:itemToRemove error:&error];
	if (!removed && error != nil) {
		os_log_error(GetDesignerLog(), "%s: Error removing item: %@", __PRETTY_FUNCTION__, error);
	}
}

#pragma mark - Convenience

- (NSString *)bundleDisplayName {
	if (!_bundleDisplayName) {
		_bundleDisplayName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
	}
	return _bundleDisplayName;
}

- (id)debugQuickLookObject {
	return [NSString stringWithFormat:@"--%@--\n", [NSStringFromClass([self class]) uppercaseString]];
}

@end
