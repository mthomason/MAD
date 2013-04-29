//
//  AppDelegate.m
//  Reports
//
//  Created by Michael Thomason on 1/2/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate()

@end

@implementation AppDelegate

void uncaughtExceptionHandler(NSException *exception);
void uncaughtExceptionHandler(NSException *exception) {
    NSLog(@"%@", exception);
}

- (void)dealloc {
    [_window release];
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    //NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
    return YES;
}
			
- (void)applicationWillResignActive:(UIApplication *)application { }

- (void)applicationDidEnterBackground:(UIApplication *)application { }

- (void)applicationWillEnterForeground:(UIApplication *)application { }

- (void)applicationDidBecomeActive:(UIApplication *)application { }

- (void)applicationWillTerminate:(UIApplication *)application {
    MTReportDocument *documentReport = [[[MTActiveDocument sharedDocument] activeDocument] retain];
    [documentReport save:nil];
    [documentReport release];
}

- (NSUInteger)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window {
    static NSNumber *isPad;
    if (!isPad) {
        isPad = @([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad);
    }
    return   [isPad boolValue] ? UIInterfaceOrientationMaskAll : UIInterfaceOrientationMaskAllButUpsideDown;
}

#pragma mark - Actions

+ (NSString *)storyboardName {
    NSString *storyboardName = [UIDevice isPad] ? MTStoryboardReportDesignerPad : MTStoryboardReportDesigner;
    return storyboardName;
}

@end
