//
//  AppDelegate.m
//  Reports
//
//  Created by Michael Thomason on 1/2/12.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif


#import "AppDelegate.h"
#import "MADPngImageTransformer.h"
#import "MADExplorerController.h"
#import "MADTabBarController.h"
#import "MADViewerController.h"
#import "MADNavigationController.h"
#import "Constants.h"
#import <MADFoundation/madlog.h>

#import <MAD/MADConstants.h>
#import <MADFoundation/MADURLFactory.h>
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
	NSString *_versionNumber;
	NSString *_revisionNumber;
	NSString *_bundleDisplayName;
}

#pragma mark - MADApplicationProtocol

+ (NSString *)groupIdentifier {
#if DEBUG
	return @"group.everydayapps.mad.local";
#else
	return @"group.everydayapps.mad";
#endif
}

// The app is scene-based; the AppDelegate's window is never set.  The UI-test
// hooks reach the window through the first connected scene instead.
- (UIWindow *)firstSceneWindow {
	for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
		if ([scene.delegate conformsToProtocol:@protocol(UIWindowSceneDelegate)]) {
			UIWindow *window = ((id<UIWindowSceneDelegate>)scene.delegate).window;
			if (window != nil) return window;
		}
	}
	return nil;
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
	NSString *name = [[NSString alloc] initWithFormat:@"%@ %@", [self trademark], self.localizedApplicationNameSufixPart];
	return name;
}

- (NSString *)localizedName {
	NSString *localizedName = [[NSString alloc] initWithFormat:@"%@ %@", [self trademark], self.localizedApplicationNameSufixPart];
	return localizedName;
}

- (NSString *)applicationIdentifier { return @"666001433"; }

- (NSString *)applicationBundleIdentifier { return @"com.everydayapps.mad.designer"; }

- (NSString *)trademark { return @"MAD"; }

- (NSString *)applicationNameSufixPart { return @"Designer"; }

- (NSString *)localizedApplicationNameSufixPart {
	return NSLocalizedString([self applicationNameSufixPart], [self applicationNameSufixPart]);
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
		dispatch_queue_t queue = dispatch_queue_create(MADQueueAppDelegate, DISPATCH_QUEUE_SERIAL);
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

	[NSValueTransformer setValueTransformer:[[MADPngImageTransformer alloc] init]
									forName:NSStringFromClass([MADPngImageTransformer class])];
	
	[[UNUserNotificationCenter currentNotificationCenter] requestAuthorizationWithOptions:(UNAuthorizationOptionAlert | UNAuthorizationOptionSound | UNAuthorizationOptionBadge)
						  completionHandler:^(BOOL granted, NSError * _Nullable __unused error) {
		if (granted) {
			dispatch_async(dispatch_get_main_queue(), ^{
				[application registerForRemoteNotifications];
			});
		}
	}];

#if DEBUG
	// UI-test hook: "-UITestOpenSample London" opens the named sample from the app
	// group's documents the way the explorer's own open does, and
	// "-UITestSelectTab Designer" selects a tab of the opened document.  Debug
	// builds only.
	NSArray *arguments = NSProcessInfo.processInfo.arguments;
	NSUInteger sampleIndex = [arguments indexOfObject:@"-UITestOpenSample"];
	if (sampleIndex != NSNotFound && arguments.count > sampleIndex + 1) {
		NSString *sampleName = arguments[sampleIndex + 1];
		// The window's root controller is not set for several seconds after a fresh
		// launch, so poll until it exists rather than racing a fixed delay.
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			__block NSUInteger attempts = 0;
			__block void (^tryOpen)(void);
			tryOpen = ^{
				// !: nil passed to callee that requires a non-null 1st parameter
				UINavigationController *navController = (UINavigationController *)[self firstSceneWindow].rootViewController;
				if (navController == nil && attempts++ < 30) {
					dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), tryOpen);	// !: Capturing 'tryOpen' strongly in this block is likely to lead to a retain cycle
					return;
				}
				NSLog(@"[UITestHook] open '%@': root=%@ top=%@", sampleName,
					  NSStringFromClass([self firstSceneWindow].rootViewController.class),
					  NSStringFromClass(navController.topViewController.class));	// !: Implicit conversion from nullable pointer 'Class _Nullable' to non-nullable pointer type 'Class _Nonnull'
				NSURL *directory = [MADURLFactory newURLLocalDocumentsDirectoryForGroupIdentifier:[AppDelegate groupIdentifier]];
				NSURL *url = [[directory URLByAppendingPathComponent:sampleName]
							  URLByAppendingPathExtension:MADFileExtentionMobleApplicationDocument];
				[self application:application OpenURL:url options:@{}];
			};
			tryOpen();
		});
	}
	NSUInteger tabIndex = [arguments indexOfObject:@"-UITestSelectTab"];
	if (tabIndex != NSNotFound && arguments.count > tabIndex + 1) {
		NSString *tabName = arguments[tabIndex + 1];
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(9.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			UINavigationController *navController = (UINavigationController *)[self firstSceneWindow].rootViewController;
			if ([navController.topViewController isKindOfClass:[MADTabBarController class]]) {
				MADTabBarController *tabBarController = (MADTabBarController *)navController.topViewController;
				if ([tabName isEqualToString:@"Designer"]) tabBarController.selectedIndex = 1;
				else if ([tabName isEqualToString:@"Viewer"]) tabBarController.selectedIndex = 2;
				else tabBarController.selectedIndex = 0;
			}
		});
	}
	// UI-test hook: "-UITestRefresh" selects the Viewer tab and taps its refresh
	// button, so a refresh can be driven headlessly.  Debug builds only.
	if ([arguments containsObject:@"-UITestRefresh"]) {
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			__block NSUInteger attempts = 0;
			__block void (^tryRefresh)(void);
			tryRefresh = ^{
				UINavigationController *navController = (UINavigationController *)[self firstSceneWindow].rootViewController;
				NSLog(@"[UITestHook] refresh attempt %lu: top=%@", (unsigned long)attempts,
					  NSStringFromClass(navController.topViewController.class));
				if ([navController.topViewController isKindOfClass:[MADTabBarController class]]) {
					MADTabBarController *tabBarController = (MADTabBarController *)navController.topViewController;
					tabBarController.selectedIndex = 2;
					UIViewController *viewerNav = tabBarController.viewControllers[2];
					if ([viewerNav isKindOfClass:[UINavigationController class]]) {
						UIViewController *top = ((UINavigationController *)viewerNav).topViewController;
						if ([top isKindOfClass:[MADViewerController class]]) {
							NSLog(@"[UITestHook] firing refresh:");
							[(MADViewerController *)top refresh:nil];
							return;
						}
					}
				}
				if (attempts++ < 90) {
					dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), tryRefresh);	// !: Capturing 'tryRefresh' strongly in this block is likely to lead to a retain cycle
				}
			};
			tryRefresh();
		});
	}
#endif
	return YES;
}


- (void)applicationDidBecomeActive:(UIApplication *)application { }

- (void)applicationWillResignActive:(UIApplication *)application { }

- (void)applicationDidEnterBackground:(UIApplication *)application { }

- (void)applicationWillEnterForeground:(UIApplication *)application { }

- (void)applicationWillTerminate:(UIApplication *)application {
	// FIXME: ... close open applications by calling delegate method from openFileViewController.
	//[self.appConfiguration cleanupBeforeTerminate];
}

- (BOOL)application:(UIApplication *)application OpenURL:(NSURL *)url
			options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
	if (!url.isFileURL) return NO;
	
	UINavigationController *navController = (UINavigationController *)[self firstSceneWindow].rootViewController;
	if ([navController.topViewController isKindOfClass:[MADExplorerController class]]) {
		MADExplorerController *filesController = (MADExplorerController *)navController.topViewController;
		[filesController openDocumentAtURL:url completion:nil];
	} else if ([navController.topViewController isKindOfClass:[MADTabBarController class]]) {
		MADTabBarController *tabBarController = (MADTabBarController *)navController.topViewController;
		if ([tabBarController.navigationController respondsToSelector:@selector(done:)]) {
			[((MADNavigationController *)tabBarController.navigationController) done:self];
		}
	}
	
	return YES;
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
