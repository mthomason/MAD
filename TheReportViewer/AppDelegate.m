//
//  AppDelegate.m
//  TheReportViewer
//
//  Created by Michael Thomason on 1/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "NSFileManager+Common.h"

@implementation AppDelegate

@synthesize window = _window;

- (void)dealloc {
    [_window release];
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    NSLog(@"applicationDocumentsDirectory: %@", [NSFileManager applicationDocumentsDirectory]);
    
    NSLog(@"contentsOfDocumentsDirectory: %@", [NSFileManager contentsOfDocumentsDirectory]);
    
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application {
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}

- (void)applicationWillTerminate:(UIApplication *)application {
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}

- (void)openReport:(NSURL *)url {
    UIManagedDocument *document = [[[UIManagedDocument alloc] initWithFileURL:url] autorelease];
    if ([[NSFileManager defaultManager] fileExistsAtPath:[url path]]) {
        [document openWithCompletionHandler:^(BOOL success) {
            //if (success) [self documentIsReady];
            if (!success) NSLog(@"couldn’t open document at %@", url);
        }]; } else {
            [document saveToURL:url forSaveOperation:UIDocumentSaveForCreating
              completionHandler:^(BOOL success) {
                  //if (success) [self documentIsReady];
                  if (!success) NSLog(@"couldn’t create document at %@", url);
              }];
        }
    // can’t do anything with the document yet (do it in do
}

- (NSURL *)createAndOpenNewDocumentNamed:(NSString *)name withPathExtention:(NSString *)extention {
    NSURL *result = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    result = [result URLByAppendingPathComponent: name];
    result = [result URLByAppendingPathExtension: extention];
    return result;
}

@end