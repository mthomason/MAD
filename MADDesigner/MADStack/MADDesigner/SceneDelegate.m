//
//  SceneDelegate.m
//  MAD Designer
//
//  Created by Michael on 10/1/25.
//  Copyright © 2025 Everyday Apps LLC. All rights reserved.
//

#import "SceneDelegate.h"
#import "MADTabBarController.h"
#import "MADNavigationController.h"
#import "MADExplorerController.h"
#import "madlog.h"

@implementation SceneDelegate

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session
	  options:(UISceneConnectionOptions *)connectionOptions {
	if (connectionOptions.URLContexts.count > 0) {
		[self handleOpenURLContexts:connectionOptions.URLContexts];
	}
}

- (void)scene:(UIScene *)scene openURLContexts:(NSSet<UIOpenURLContext *> *)URLContexts {
	[self handleOpenURLContexts:URLContexts];
}

#pragma mark - Private

- (void)handleOpenURLContexts:(NSSet<UIOpenURLContext *> *)URLContexts {
	NSURL *url = URLContexts.allObjects.firstObject.URL;
	if (!url.isFileURL) return;
	
	MADNavigationController *navController = (MADNavigationController *)self.window.rootViewController;
	
	// This block contains the logic to open the new document.
	// It will be executed either immediately or after the current document is closed.
	void (^openDocumentBlock)(void) = ^{
		if ([navController.topViewController isKindOfClass:[MADExplorerController class]]) {
			MADExplorerController *filesController = (MADExplorerController *)navController.topViewController;
			[filesController openDocumentAtURL:url completion:nil];
		} else {
			os_log_error(GetDesignerLog(), "Could not find MADExplorerController to open document.");
		}
	};
	
	// Check if a document is already open by looking for the MADTabBarController.
	if ([navController.topViewController isKindOfClass:[MADTabBarController class]]) {
		// If a document is open, call `done:completion:` to close it.
		// The `openDocumentBlock` is passed as the completion handler to ensure
		// it only runs after the dismissal animation is complete.
		[navController done:self completion:^{
			dispatch_async(dispatch_get_main_queue(), openDocumentBlock);
		}];
	} else {
		// If no document is open, execute the block immediately.
		dispatch_async(dispatch_get_main_queue(), openDocumentBlock);
	}
}

@end
